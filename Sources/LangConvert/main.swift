import AppKit
import ApplicationServices
import Carbon
import Carbon.HIToolbox
import Darwin
import Foundation

struct HotKey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var display: String

    static let modifierOnlyKeyCode = UInt32.max

    var isModifierOnly: Bool {
        keyCode == Self.modifierOnlyKeyCode
    }
}

struct AppSettings: Codable {
    var convertHotKey: HotKey
    var switchLocaleHotKey: HotKey
    var launchAtLogin: Bool

    static let defaults = AppSettings(
        convertHotKey: HotKey(
            keyCode: 37,
            modifiers: UInt32(cmdKey | shiftKey),
            display: "Cmd + Shift + L"
        ),
        switchLocaleHotKey: HotKey(
            keyCode: 49,
            modifiers: UInt32(cmdKey | shiftKey),
            display: "Cmd + Shift + Space"
        ),
        launchAtLogin: false
    )
}

final class SettingsStore {
    private let url: URL
    private(set) var settings: AppSettings

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LangConvert", isDirectory: true)
        self.url = directory.appendingPathComponent("settings.json")

        if
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            self.settings = decoded
        } else {
            self.settings = .defaults
        }
    }

    func update(_ next: AppSettings) {
        settings = next
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(next) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

final class LayoutConverter {
    private let enToRu: [Character: Character]
    private let ruToEn: [Character: Character]

    init() {
        let pairs: [(Character, Character)] = [
            ("`", "ё"), ("q", "й"), ("w", "ц"), ("e", "у"), ("r", "к"), ("t", "е"),
            ("y", "н"), ("u", "г"), ("i", "ш"), ("o", "щ"), ("p", "з"), ("[", "х"),
            ("]", "ъ"), ("a", "ф"), ("s", "ы"), ("d", "в"), ("f", "а"), ("g", "п"),
            ("h", "р"), ("j", "о"), ("k", "л"), ("l", "д"), (";", "ж"), ("'", "э"),
            ("z", "я"), ("x", "ч"), ("c", "с"), ("v", "м"), ("b", "и"), ("n", "т"),
            ("m", "ь"), (",", "б"), (".", "ю"), ("/", "."),
            ("~", "Ё"), ("Q", "Й"), ("W", "Ц"), ("E", "У"), ("R", "К"), ("T", "Е"),
            ("Y", "Н"), ("U", "Г"), ("I", "Ш"), ("O", "Щ"), ("P", "З"), ("{", "Х"),
            ("}", "Ъ"), ("A", "Ф"), ("S", "Ы"), ("D", "В"), ("F", "А"), ("G", "П"),
            ("H", "Р"), ("J", "О"), ("K", "Л"), ("L", "Д"), (":", "Ж"), ("\"", "Э"),
            ("Z", "Я"), ("X", "Ч"), ("C", "С"), ("V", "М"), ("B", "И"), ("N", "Т"),
            ("M", "Ь"), ("<", "Б"), (">", "Ю"), ("?", ","), ("@", "\""), ("#", "№"),
            ("$", ";"), ("^", ":"), ("&", "?")
        ]

        self.enToRu = Dictionary(uniqueKeysWithValues: pairs)
        self.ruToEn = Dictionary(uniqueKeysWithValues: pairs.map { ($0.1, $0.0) })
    }

    func convert(_ text: String) -> String {
        if let systemMap = KeyboardLayoutProvider.conversionMap() {
            return String(text.map { systemMap[$0] ?? $0 })
        }

        return String(text.map { character in
            enToRu[character] ?? ruToEn[character] ?? character
        })
    }
}

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestPrompt() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}

struct KeyboardLayoutInfo {
    let name: String
    let identifier: String
}

enum KeyboardLayoutProvider {
    private struct LayoutSource {
        let source: TISInputSource
        let info: KeyboardLayoutInfo
        let layoutData: CFData
    }

    static func enabledLayouts() -> [KeyboardLayoutInfo] {
        enabledKeyboardSources().map(\.info)
    }

    static func conversionMap() -> [Character: Character]? {
        let sources = Array(enabledKeyboardSources().prefix(2))
        guard sources.count == 2 else { return nil }

        var result: [Character: Character] = [:]
        let first = characterMap(for: sources[0])
        let second = characterMap(for: sources[1])

        for (key, firstCharacter) in first {
            guard let secondCharacter = second[key], firstCharacter != secondCharacter else { continue }
            result[firstCharacter] = secondCharacter
            result[secondCharacter] = firstCharacter
        }

        return result.isEmpty ? nil : result
    }

    private static func enabledKeyboardSources() -> [LayoutSource] {
        let properties: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsEnabled as String: true
        ]
        guard let sources = TISCopyInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return sources.compactMap { source in
            guard let name = property(source, kTISPropertyLocalizedName),
                  let identifier = property(source, kTISPropertyInputSourceID),
                  let layoutData = dataProperty(source, kTISPropertyUnicodeKeyLayoutData)
            else {
                return nil
            }
            return LayoutSource(
                source: source,
                info: KeyboardLayoutInfo(name: name, identifier: identifier),
                layoutData: layoutData
            )
        }
    }

    private static func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let value = TISGetInputSourceProperty(source, key) else { return nil }
        return unsafeBitCast(value, to: CFString.self) as String
    }

    private static func dataProperty(_ source: TISInputSource, _ key: CFString) -> CFData? {
        guard let value = TISGetInputSourceProperty(source, key) else { return nil }
        return unsafeBitCast(value, to: CFData.self)
    }

    private static func characterMap(for source: LayoutSource) -> [String: Character] {
        guard let bytes = CFDataGetBytePtr(source.layoutData) else { return [:] }
        let keyboardLayout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        let keyboardType = UInt32(LMGetKbdType())
        let modifiers: [UInt32] = [
            0,
            UInt32(shiftKey),
            UInt32(optionKey),
            UInt32(shiftKey | optionKey)
        ]
        var result: [String: Character] = [:]

        for keyCode in UInt16(0)..<UInt16(128) {
            for modifier in modifiers {
                guard let character = character(
                    keyboardLayout: keyboardLayout,
                    keyboardType: keyboardType,
                    keyCode: keyCode,
                    modifiers: modifier
                ) else {
                    continue
                }
                result["\(keyCode):\(modifier)"] = character
            }
        }

        return result
    }

    private static func character(
        keyboardLayout: UnsafePointer<UCKeyboardLayout>,
        keyboardType: UInt32,
        keyCode: UInt16,
        modifiers: UInt32
    ) -> Character? {
        var deadKeyState: UInt32 = 0
        var length: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 8)
        let status = chars.withUnsafeMutableBufferPointer { buffer in
            UCKeyTranslate(
                keyboardLayout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                modifiers >> 8,
                keyboardType,
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                UInt32(buffer.count),
                &length,
                buffer.baseAddress
            )
        }
        guard status == noErr, length == 1 else { return nil }
        let value = String(utf16CodeUnits: chars, count: Int(length))
        guard value.count == 1, let character = value.first, !character.isWhitespace else { return nil }
        return character
    }
}

final class KeyboardAutomation {
    private let converter = LayoutConverter()

    func convertSelection() -> String {
        guard AccessibilityPermission.requestPrompt() else {
            return "Разрешите Accessibility доступ для LangConvert."
        }

        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        postKey(keyCode: 8, flags: .maskCommand)
        Thread.sleep(forTimeInterval: 0.16)

        guard let selected = pasteboard.string(forType: .string), !selected.isEmpty else {
            restore(previous)
            return "Не удалось получить выделенный текст."
        }

        let converted = converter.convert(selected)
        pasteboard.clearContents()
        pasteboard.setString(converted, forType: .string)
        postKey(keyCode: 9, flags: .maskCommand)
        Thread.sleep(forTimeInterval: 0.2)
        restore(previous)
        return "Текст сконвертирован."
    }

    func switchLocale() -> String {
        guard AccessibilityPermission.requestPrompt() else {
            return "Разрешите Accessibility доступ для LangConvert."
        }

        postKey(keyCode: 49, flags: .maskControl)
        return "Запрошено переключение локали."
    }

    private func postKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private func restore(_ value: String?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let value {
            pasteboard.setString(value, forType: .string)
        }
    }
}

final class LoginItemManager {
    private let label = "app.langconvert.desktop.login"

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func setEnabled(_ enabled: Bool) -> Bool {
        if enabled {
            return install()
        }

        _ = runLaunchctl(["bootout", "gui/\(getuid())", launchAgentURL.path])
        try? FileManager.default.removeItem(at: launchAgentURL)
        return true
    }

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    private func install() -> Bool {
        guard Bundle.main.bundlePath.hasSuffix(".app") else {
            return false
        }

        try? FileManager.default.createDirectory(
            at: launchAgentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let appPath = xmlEscaped(Bundle.main.bundlePath)
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>/usr/bin/open</string>
            <string>-a</string>
            <string>\(appPath)</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
        """

        do {
            try plist.write(to: launchAgentURL, atomically: true, encoding: .utf8)
            _ = runLaunchctl(["bootout", "gui/\(getuid())", launchAgentURL.path])
            return runLaunchctl(["bootstrap", "gui/\(getuid())", launchAgentURL.path])
        } catch {
            return false
        }
    }

    private func runLaunchctl(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

final class GlobalHotKeyManager {
    private var refs: [EventHotKeyRef?] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var modifierOnlyActions: [UInt32: (hotKey: HotKey, action: () -> Void)] = [:]
    private var modifierOnlyArmed: [UInt32: Bool] = [:]
    private var flagsChangedMonitors: [Any] = []

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                manager.actions[hotKeyID.id]?()
                return noErr
            },
            1,
            &spec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )
    }

    func register(convert: HotKey, switchLocale: HotKey, onConvert: @escaping () -> Void, onSwitchLocale: @escaping () -> Void) {
        unregisterAll()
        register(id: 1, hotKey: convert, action: onConvert)
        register(id: 2, hotKey: switchLocale, action: onSwitchLocale)
        installFlagsChangedMonitorsIfNeeded()
    }

    func suspend() {
        unregisterAll()
    }

    private func register(id: UInt32, hotKey: HotKey, action: @escaping () -> Void) {
        if hotKey.isModifierOnly {
            modifierOnlyActions[id] = (hotKey, action)
            modifierOnlyArmed[id] = false
            return
        }

        var ref: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: OSType(0x4C434356), id: id)
        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr {
            refs.append(ref)
            actions[id] = action
        }
    }

    private func installFlagsChangedMonitorsIfNeeded() {
        guard !modifierOnlyActions.isEmpty, flagsChangedMonitors.isEmpty else { return }
        let handler: (NSEvent) -> Void = { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        if let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler) {
            flagsChangedMonitors.append(globalMonitor)
        }
        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        } {
            flagsChangedMonitors.append(localMonitor)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        for (id, registration) in modifierOnlyActions {
            if modifiers == registration.hotKey.modifiers {
                if modifierOnlyArmed[id] != true {
                    modifierOnlyArmed[id] = true
                    registration.action()
                }
            } else {
                modifierOnlyArmed[id] = false
            }
        }
    }

    private func unregisterAll() {
        refs.forEach { ref in
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        refs.removeAll()
        actions.removeAll()
        modifierOnlyActions.removeAll()
        modifierOnlyArmed.removeAll()
        flagsChangedMonitors.forEach { NSEvent.removeMonitor($0) }
        flagsChangedMonitors.removeAll()
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        return result
    }
}

final class HotKeyRecorderField: NSTextField {
    var onRecord: ((HotKey) -> Void)?
    private var keyMonitor: Any?
    private var modifierSequence: UInt32 = 0

    override var acceptsFirstResponder: Bool { true }
    override var needsPanelToBecomeKey: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        if didBecome {
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            installKeyMonitor()
        }
        return didBecome
    }

    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign {
            layer?.borderWidth = 0
            layer?.borderColor = nil
            removeKeyMonitor()
        }
        return didResign
    }

    deinit {
        removeKeyMonitor()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        record(event)
    }

    override func keyDown(with event: NSEvent) {
        _ = record(event)
    }

    override func flagsChanged(with event: NSEvent) {
        _ = recordModifierOnly(event)
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self, self.window?.firstResponder === self else { return event }
            switch event.type {
            case .keyDown:
                return self.record(event) ? nil : event
            case .flagsChanged:
                return self.recordModifierOnly(event) ? nil : event
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func record(_ event: NSEvent) -> Bool {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return false }

        let hotKey = HotKey(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            display: displayString(for: event, modifiers: modifiers)
        )
        stringValue = hotKey.display
        onRecord?(hotKey)
        return true
    }

    private func recordModifierOnly(_ event: NSEvent) -> Bool {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        if modifiers == 0 {
            modifierSequence = 0
            return false
        }

        let isAddingModifier = modifiers & ~modifierSequence != 0
        guard isAddingModifier else { return true }
        modifierSequence = modifiers

        let hotKey = HotKey(
            keyCode: HotKey.modifierOnlyKeyCode,
            modifiers: modifiers,
            display: displayString(modifiers: modifiers)
        )
        stringValue = hotKey.display
        onRecord?(hotKey)
        return true
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        return result
    }

    private func displayString(for event: NSEvent, modifiers: UInt32) -> String {
        var parts = displayParts(modifiers: modifiers)
        parts.append(keyName(event))
        return parts.joined(separator: " + ")
    }

    private func displayString(modifiers: UInt32) -> String {
        displayParts(modifiers: modifiers).joined(separator: " + ")
    }

    private func displayParts(modifiers: UInt32) -> [String] {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("Ctrl") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        return parts
    }

    private func keyName(_ event: NSEvent) -> String {
        if event.keyCode == 49 { return "Space" }
        return event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
    }
}

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let store: SettingsStore
    private let loginItems: LoginItemManager
    private let onChange: () -> Void
    private let onEditingActive: (Bool) -> Void
    private let statusLabel = NSTextField(labelWithString: "")
    private let accessibilityNotice = NSStackView()
    private let accessibilityMessage = NSTextField(labelWithString: "")
    private let accessibilityButton = NSButton(title: "Разрешить доступ", target: nil, action: nil)
    private let layoutsNotice = NSStackView()
    private let layoutsMessage = NSTextField(labelWithString: "")

    init(
        store: SettingsStore,
        loginItems: LoginItemManager,
        onChange: @escaping () -> Void,
        onEditingActive: @escaping (Bool) -> Void
    ) {
        self.store = store
        self.loginItems = loginItems
        self.onChange = onChange
        self.onEditingActive = onEditingActive

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LangConvert Settings"
        window.center()
        super.init(window: window)
        window.delegate = self
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStatus(_ text: String) {
        statusLabel.stringValue = text
        refreshAccessibilityNotice()
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "LangConvert")
        title.font = .boldSystemFont(ofSize: 24)

        let convertField = makeHotKeyField(value: store.settings.convertHotKey.display)
        convertField.onRecord = { [weak self] hotKey in
            guard let self else { return }
            var settings = store.settings
            settings.convertHotKey = hotKey
            store.update(settings)
            onChange()
            setStatus("Горячая клавиша конвертации сохранена.")
        }

        let switchField = makeHotKeyField(value: store.settings.switchLocaleHotKey.display)
        switchField.onRecord = { [weak self] hotKey in
            guard let self else { return }
            var settings = store.settings
            settings.switchLocaleHotKey = hotKey
            store.update(settings)
            onChange()
            setStatus("Горячая клавиша переключения локали сохранена.")
        }

        let launchCheckbox = NSButton(checkboxWithTitle: "Автозапуск приложения с загрузкой системы", target: nil, action: nil)
        launchCheckbox.state = loginItems.isEnabled ? .on : .off
        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunchAtLogin(_:))

        configureAccessibilityNotice()
        configureLayoutsNotice()

        statusLabel.stringValue = "Для конвертации выделенного текста разрешите Accessibility доступ."
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(accessibilityNotice)
        stack.addArrangedSubview(layoutsNotice)
        stack.addArrangedSubview(labeled("Конвертация выделенного текста", field: convertField))
        stack.addArrangedSubview(labeled("Переключение локали", field: switchField))
        stack.addArrangedSubview(launchCheckbox)
        stack.addArrangedSubview(statusLabel)

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24)
        ])
        refreshAccessibilityNotice()
        refreshLayoutsNotice()
    }

    override func showWindow(_ sender: Any?) {
        refreshAccessibilityNotice()
        refreshLayoutsNotice()
        onEditingActive(true)
        super.showWindow(sender)
    }

    func windowWillClose(_ notification: Notification) {
        onEditingActive(false)
    }

    func windowDidResignKey(_ notification: Notification) {
        onEditingActive(false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        onEditingActive(true)
    }

    private func configureAccessibilityNotice() {
        accessibilityNotice.orientation = .horizontal
        accessibilityNotice.alignment = .centerY
        accessibilityNotice.spacing = 12
        accessibilityNotice.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        accessibilityNotice.wantsLayer = true
        accessibilityNotice.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        accessibilityNotice.layer?.cornerRadius = 8

        accessibilityMessage.stringValue = "Для первого запуска разрешите Accessibility доступ, иначе горячие клавиши не смогут заменить выделенный текст."
        accessibilityMessage.lineBreakMode = .byWordWrapping
        accessibilityMessage.maximumNumberOfLines = 3

        accessibilityButton.target = self
        accessibilityButton.action = #selector(requestAccessibilityPermission)

        accessibilityNotice.addArrangedSubview(accessibilityMessage)
        accessibilityNotice.addArrangedSubview(accessibilityButton)
        accessibilityMessage.setContentHuggingPriority(.defaultLow, for: .horizontal)
        accessibilityButton.setContentHuggingPriority(.required, for: .horizontal)
        accessibilityNotice.widthAnchor.constraint(equalToConstant: 472).isActive = true
    }

    private func configureLayoutsNotice() {
        layoutsNotice.orientation = .horizontal
        layoutsNotice.alignment = .centerY
        layoutsNotice.spacing = 12
        layoutsNotice.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        layoutsNotice.wantsLayer = true
        layoutsNotice.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layoutsNotice.layer?.cornerRadius = 8

        layoutsMessage.lineBreakMode = .byWordWrapping
        layoutsMessage.maximumNumberOfLines = 4
        layoutsNotice.addArrangedSubview(layoutsMessage)
        layoutsMessage.setContentHuggingPriority(.defaultLow, for: .horizontal)
        layoutsNotice.widthAnchor.constraint(equalToConstant: 472).isActive = true
    }

    private func refreshAccessibilityNotice() {
        accessibilityNotice.isHidden = AccessibilityPermission.isTrusted
    }

    private func refreshLayoutsNotice() {
        let layouts = KeyboardLayoutProvider.enabledLayouts()
        let names = layouts.map(\.name)

        if names.count >= 2 {
            layoutsMessage.stringValue = "Системные раскладки: \(names.prefix(2).joined(separator: " ↔ ")). Конвертация работает между двумя добавленными раскладками; оставьте в системе только нужную пару."
        } else if names.count == 1 {
            layoutsMessage.stringValue = "Системная раскладка: \(names[0]). Добавьте вторую раскладку в macOS Keyboard/Input Sources, чтобы конвертация работала между двумя локалями."
        } else {
            layoutsMessage.stringValue = "Добавьте две раскладки в macOS Keyboard/Input Sources. LangConvert конвертирует выделенный текст между этой парой системных локалей."
        }
    }

    @objc private func requestAccessibilityPermission() {
        if AccessibilityPermission.requestPrompt() {
            setStatus("Accessibility доступ уже выдан.")
        } else {
            setStatus("Выдайте LangConvert Accessibility доступ в системных настройках.")
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        let enabled = sender.state == .on
        let ok = loginItems.setEnabled(enabled)
        var settings = store.settings
        settings.launchAtLogin = ok && enabled
        store.update(settings)
        sender.state = settings.launchAtLogin ? .on : .off
        setStatus(ok ? "Настройка автозапуска обновлена." : "Автозапуск доступен только из .app bundle.")
    }

    private func makeHotKeyField(value: String) -> HotKeyRecorderField {
        let field = HotKeyRecorderField(string: value)
        field.isEditable = false
        field.isSelectable = false
        field.focusRingType = .default
        field.isBezeled = true
        field.drawsBackground = true
        field.wantsLayer = true
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 240).isActive = true
        return field
    }

    private func labeled(_ title: String, field: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = .boldSystemFont(ofSize: 13)
        let row = NSStackView(views: [label, field])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 16
        label.widthAnchor.constraint(equalToConstant: 210).isActive = true
        return row
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private let automation = KeyboardAutomation()
    private let loginItems = LoginItemManager()
    private let hotKeys = GlobalHotKeyManager()
    private var statusItem: NSStatusItem?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        registerHotKeys()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "LangConvert")
        item.button?.title = item.button?.image == nil ? "K" : ""

        let menu = NSMenu()
        menu.addItem(menuItem("Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func menuItem(_ title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func registerHotKeys() {
        hotKeys.register(
            convert: store.settings.convertHotKey,
            switchLocale: store.settings.switchLocaleHotKey,
            onConvert: { [weak self] in self?.convertSelection() },
            onSwitchLocale: { [weak self] in self?.switchLocale() }
        )
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(
                store: store,
                loginItems: loginItems,
                onChange: { [weak self] in
                    self?.registerHotKeys()
                },
                onEditingActive: { [weak self] isActive in
                    if isActive {
                        self?.hotKeys.suspend()
                    } else {
                        self?.registerHotKeys()
                    }
                }
            )
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.showWindow(nil)
    }

    @objc private func convertSelection() {
        let message = automation.convertSelection()
        settingsWindow?.setStatus(message)
    }

    @objc private func switchLocale() {
        let message = automation.switchLocale()
        settingsWindow?.setStatus(message)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
