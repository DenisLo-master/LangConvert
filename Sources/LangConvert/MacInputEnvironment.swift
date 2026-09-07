import AppKit
import ApplicationServices
import LangConvertCore

/// Ephemeral operation context only. It never restores a window's input source.
@MainActor final class MacInputEnvironment: InputEnvironment {
    private final class FocusWatch {
        weak var environment: MacInputEnvironment?
        let context: String
        init(environment: MacInputEnvironment, context: String) {
            self.environment = environment
            self.context = context
        }
    }

    private struct Snapshot {
        let pid: pid_t
        let element: AXUIElement
        let window: AXUIElement
        let generation: UInt64
        let capturedAt: TimeInterval
        let observer: AXObserver
        let watch: FocusWatch
        var originalValue: String?
        var range: CFRange?
        var expectedValue: String?
        var insertedLength: Int?
    }

    private struct SwitchSnapshot {
        let pid: pid_t
        let window: AXUIElement?
        let generation: UInt64
        let capturedAt: TimeInterval
    }

    private var switchSnapshots: [String: SwitchSnapshot] = [:]
    private var snapshots: [String: Snapshot] = [:]
    private var generation: UInt64 = 0
    private var activationObserver: NSObjectProtocol?
    private var eventMonitors: [Any] = []
    private let converter = LayoutConverter()

    init() {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.1)
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            let pid = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.snapshots.values.contains(where: { $0.pid != pid }) ||
                      self.switchSnapshots.values.contains(where: { $0.pid != pid }) else { return }
                self.generation &+= 1
            }
        }
        let events: NSEvent.EventTypeMask = [.keyDown, .leftMouseDown, .rightMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] event in
            let timestamp = event.timestamp
            Task { @MainActor in self?.invalidateContexts(after: timestamp) }
        }) { eventMonitors.append(monitor) }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: events, handler: { [weak self] event in
            let timestamp = event.timestamp
            Task { @MainActor in self?.invalidateContexts(after: timestamp) }
            return event
        }) { eventMonitors.append(monitor) }
    }

    deinit {
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        snapshots.values.forEach {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource($0.observer), .commonModes)
        }
    }

    var conversionMaps: LayoutConversionMaps {
        KeyboardLayoutProvider.conversionMaps(fallbackMaps: converter.fallbackMaps) ?? converter.fallbackMaps
    }
    var pairIDs: [String] { KeyboardLayoutProvider.pairIdentifiers }
    var availableSourceIDs: Set<String> { KeyboardLayoutProvider.availableIdentifiers }
    var currentSourceID: String? { KeyboardLayoutProvider.currentIdentifier }
    func selectSource(_ identifier: String) -> Bool { KeyboardLayoutProvider.select(identifier: identifier) }
    func waitForSystem() async { try? await Task.sleep(nanoseconds: 20_000_000) }

    // Switching a source does not require an editable Accessibility element.
    // The coordinator issues its only selection before its first suspension;
    // subsequent asynchronous work only confirms the source, never retries it.
    func captureSwitchContext() -> String? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let window = axElement(AXUIElementCreateApplication(pid), kAXFocusedWindowAttribute)
        let id = UUID().uuidString
        switchSnapshots[id] = SwitchSnapshot(pid: pid, window: window, generation: generation,
                                              capturedAt: ProcessInfo.processInfo.systemUptime)
        return id
    }

    func captureContext() -> String? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let app = AXUIElementCreateApplication(pid)
        guard let element = axElement(app, kAXFocusedUIElementAttribute),
              let window = axElement(app, kAXFocusedWindowAttribute) else { return nil }
        let id = UUID().uuidString
        let watch = FocusWatch(environment: self, context: id)
        var observer: AXObserver?
        guard AXObserverCreate(pid, { _, _, _, refcon in
            guard let refcon else { return }
            let watch = Unmanaged<FocusWatch>.fromOpaque(refcon).takeUnretainedValue()
            Task { @MainActor in
                guard let environment = watch.environment,
                      environment.snapshots[watch.context] != nil else { return }
                environment.generation &+= 1
            }
        }, &observer) == .success, let observer else { return nil }
        let refcon = Unmanaged.passUnretained(watch).toOpaque()
        guard AXObserverAddNotification(observer, app, kAXFocusedUIElementChangedNotification as CFString, refcon) == .success,
              AXObserverAddNotification(observer, app, kAXFocusedWindowChangedNotification as CFString, refcon) == .success
        else { return nil }
        snapshots[id] = Snapshot(pid: pid, element: element, window: window,
                                 generation: generation, capturedAt: ProcessInfo.processInfo.systemUptime,
                                 observer: observer, watch: watch)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        return id
    }

    func releaseContext(_ context: String) {
        switchSnapshots.removeValue(forKey: context)
        guard let snapshot = snapshots.removeValue(forKey: context) else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(snapshot.observer), .commonModes)
    }

    private func invalidateContexts(after eventTimestamp: TimeInterval) {
        // The invoking shortcut can be delivered to a monitor after capture.
        guard snapshots.values.contains(where: { eventTimestamp > $0.capturedAt }) ||
              switchSnapshots.values.contains(where: { eventTimestamp > $0.capturedAt }) else { return }
        generation &+= 1
    }

    func contextIsCurrent(_ context: String) -> Bool {
        if let snapshot = switchSnapshots[context] {
            guard !Task.isCancelled, snapshot.generation == generation,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == snapshot.pid else { return false }
            let window = axElement(AXUIElementCreateApplication(snapshot.pid), kAXFocusedWindowAttribute)
            switch (snapshot.window, window) {
            case (nil, nil): return true
            case let (original?, current?): return CFEqual(original, current)
            default: return false
            }
        }
        guard !Task.isCancelled, let snapshot = snapshots[context], snapshot.generation == generation,
              NSWorkspace.shared.frontmostApplication?.processIdentifier == snapshot.pid else { return false }
        let app = AXUIElementCreateApplication(snapshot.pid)
        guard let element = axElement(app, kAXFocusedUIElementAttribute),
              let window = axElement(app, kAXFocusedWindowAttribute) else { return false }
        return CFEqual(element, snapshot.element) && CFEqual(window, snapshot.window)
    }

    func selectedText(in context: String) -> String? {
        guard contextIsCurrent(context), var snapshot = snapshots[context],
              let value = attribute(snapshot.element, kAXValueAttribute) as? String,
              let range = selectedRange(snapshot.element), range.length > 0 else { return nil }
        if let ranges = attribute(snapshot.element, kAXSelectedTextRangesAttribute) as? [Any], ranges.count > 1 {
            return nil
        }
        let string = value as NSString
        guard range.location >= 0, range.location <= string.length,
              range.length <= string.length - range.location else { return nil }
        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(snapshot.element, kAXSelectedTextAttribute as CFString, &settable) == .success,
              settable.boolValue else { return nil }
        let selected = string.substring(with: NSRange(location: range.location, length: range.length))
        guard let reported = attribute(snapshot.element, kAXSelectedTextAttribute) as? String,
              reported == selected else { return nil }
        snapshot.originalValue = value
        snapshot.range = range
        snapshots[context] = snapshot
        return selected
    }

    func replaceSelection(with text: String, in context: String) -> Bool {
        guard contextIsCurrent(context), var snapshot = snapshots[context],
              let original = snapshot.originalValue, let range = snapshot.range,
              let current = attribute(snapshot.element, kAXValueAttribute) as? String, current == original,
              let currentRange = selectedRange(snapshot.element), sameRange(currentRange, range) else { return false }
        snapshot.expectedValue = (original as NSString).replacingCharacters(
            in: NSRange(location: range.location, length: range.length), with: text
        )
        snapshot.insertedLength = (text as NSString).length
        snapshots[context] = snapshot
        guard contextIsCurrent(context) else { return false }
        return AXUIElementSetAttributeValue(snapshot.element, kAXSelectedTextAttribute as CFString, text as CFString) == .success
    }

    func replacementState(in context: String) -> ReplacementState {
        guard let snapshot = snapshots[context], let expected = snapshot.expectedValue,
              let actual = attribute(snapshot.element, kAXValueAttribute) as? String else { return .failed }
        if actual == expected {
            // Do not move the caret in a context the user has already left.
            guard contextIsCurrent(context) else { return .confirmed }
            guard let range = snapshot.range, let length = snapshot.insertedLength,
                  let currentRange = selectedRange(snapshot.element) else { return .failed }
            let end = range.location + length
            if currentRange.location == end && currentRange.length == 0 { return .confirmed }
            let replacementRange = CFRange(location: range.location, length: length)
            guard sameRange(currentRange, replacementRange) || sameRange(currentRange, range) else { return .failed }
            var caret = CFRange(location: end, length: 0)
            guard let value = AXValueCreate(.cfRange, &caret), contextIsCurrent(context),
                  AXUIElementSetAttributeValue(snapshot.element, kAXSelectedTextRangeAttribute as CFString, value) == .success,
                  let verified = selectedRange(snapshot.element), sameRange(verified, caret) else { return .failed }
            return .confirmed
        }
        return actual == snapshot.originalValue ? .pending : .failed
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func axElement(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func selectedRange(_ element: AXUIElement) -> CFRange? {
        guard let value = attribute(element, kAXSelectedTextRangeAttribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cfRange else { return nil }
        var range = CFRange()
        return AXValueGetValue(axValue, .cfRange, &range) ? range : nil
    }

    private func sameRange(_ lhs: CFRange, _ rhs: CFRange) -> Bool {
        lhs.location == rhs.location && lhs.length == rhs.length
    }
}
