import LangConvertCore
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
    var language: AppLanguage

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
        launchAtLogin: false,
        language: .defaultLanguage
    )

    private enum CodingKeys: String, CodingKey {
        case convertHotKey
        case switchLocaleHotKey
        case launchAtLogin
        case language
    }

    init(convertHotKey: HotKey, switchLocaleHotKey: HotKey, launchAtLogin: Bool, language: AppLanguage) {
        self.convertHotKey = convertHotKey
        self.switchLocaleHotKey = switchLocaleHotKey
        self.launchAtLogin = launchAtLogin
        self.language = language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        convertHotKey = try container.decodeIfPresent(HotKey.self, forKey: .convertHotKey) ?? Self.defaults.convertHotKey
        switchLocaleHotKey = try container.decodeIfPresent(HotKey.self, forKey: .switchLocaleHotKey) ?? Self.defaults.switchLocaleHotKey
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .defaultLanguage
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case russian = "ru"

    var displayName: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        }
    }

    static var defaultLanguage: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init)
        return AppLanguage(rawValue: preferred ?? "") ?? .english
    }
}

enum AppMetadata {
    static let developerEmail = "flo.production.studio@gmail.com"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.7"
    }
}

enum AppText {
    static func settings(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Settings"
        case .russian: "Настройки"
        }
    }

    static func about(_ language: AppLanguage) -> String {
        switch language {
        case .english: "About LangConvert"
        case .russian: "О LangConvert"
        }
    }

    static func quit(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Quit"
        case .russian: "Выход"
        }
    }

    static func ok(_ language: AppLanguage) -> String {
        switch language {
        case .english: "OK"
        case .russian: "ОК"
        }
    }

    static func languageLabel(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Language"
        case .russian: "Язык"
        }
    }

    static func languageHint(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Used for the application interface."
        case .russian: "Используется для интерфейса приложения."
        }
    }

    static func convertHotKey(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Convert selected text"
        case .russian: "Конвертация выделенного текста"
        }
    }

    static func switchLocaleHotKey(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Switch keyboard layout"
        case .russian: "Переключение раскладки"
        }
    }

    static func launchAtLogin(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Launch app at login"
        case .russian: "Автозапуск приложения с загрузкой системы"
        }
    }

    static func accessibilityButton(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Allow access"
        case .russian: "Разрешить доступ"
        }
    }

    static func accessibilityNotice(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Allow Accessibility access on first launch, otherwise hotkeys cannot replace selected text."
        case .russian: "Для первого запуска разрешите Accessibility доступ, иначе горячие клавиши не смогут заменить выделенный текст."
        }
    }

    static func initialStatus(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Allow Accessibility access to convert selected text."
        case .russian: "Для конвертации выделенного текста разрешите Accessibility доступ."
        }
    }

    static func accessibilityRequired(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Allow Accessibility access for LangConvert."
        case .russian: "Разрешите Accessibility доступ для LangConvert."
        }
    }

    static func noSelection(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Could not read selected text."
        case .russian: "Не удалось получить выделенный текст."
        }
    }

    static func textConverted(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Text converted."
        case .russian: "Текст сконвертирован."
        }
    }

    static func convertHotKeySaved(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Convert hotkey saved."
        case .russian: "Горячая клавиша конвертации сохранена."
        }
    }

    static func switchLocaleHotKeySaved(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Layout switch hotkey saved."
        case .russian: "Горячая клавиша переключения раскладки сохранена."
        }
    }

    static func languageSaved(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Language updated."
        case .russian: "Язык интерфейса обновлен."
        }
    }

    static func accessibilityAlreadyAllowed(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Accessibility access is already allowed."
        case .russian: "Accessibility доступ уже выдан."
        }
    }

    static func accessibilityOpenSettings(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Allow LangConvert Accessibility access in System Settings."
        case .russian: "Выдайте LangConvert Accessibility доступ в системных настройках."
        }
    }

    static func launchAtLoginUpdated(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Launch at login setting updated."
        case .russian: "Настройка автозапуска обновлена."
        }
    }

    static func launchAtLoginBundleOnly(_ language: AppLanguage) -> String {
        switch language {
        case .english: "Launch at login is available only from the .app bundle."
        case .russian: "Автозапуск доступен только из .app bundle."
        }
    }

    static func layoutsNotice(_ names: [String], language: AppLanguage) -> String {
        if names.count >= 2 {
            let pair = names.prefix(2).joined(separator: " ↔ ")
            switch language {
            case .english:
                return "System layouts: \(pair). Conversion works with any pair of macOS layouts; keep the needed pair first/enabled in Keyboard/Input Sources."
            case .russian:
                return "Системные раскладки: \(pair). Конвертация работает с любой парой раскладок macOS; оставьте нужную пару первой/включенной в Keyboard/Input Sources."
            }
        }

        if names.count == 1 {
            switch language {
            case .english:
                return "System layout: \(names[0]). Add any second layout in macOS Keyboard/Input Sources to convert between that pair."
            case .russian:
                return "Системная раскладка: \(names[0]). Добавьте любую вторую раскладку в macOS Keyboard/Input Sources, чтобы конвертация работала между этой парой."
            }
        }

        switch language {
        case .english:
            return "Add any two layouts in macOS Keyboard/Input Sources. LangConvert converts selected text between that system pair."
        case .russian:
            return "Добавьте любые две раскладки в macOS Keyboard/Input Sources. LangConvert конвертирует выделенный текст между этой системной парой."
        }
    }

    static func aboutMessage(version: String, language: AppLanguage) -> String {
        switch language {
        case .english:
            return "Version: \(version)\nCreated by: \(AppMetadata.developerEmail)"
        case .russian:
            return "Версия: \(version)\nСоздано: \(AppMetadata.developerEmail)"
        }
    }
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
    let languages: [String]
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

    static func conversionMaps(fallbackMaps: LayoutConversionMaps) -> LayoutConversionMaps? {
        let enabledSources = enabledKeyboardSources()
        let sources = preferredConversionSources(from: enabledSources)
        guard sources.count == 2 else { return nil }

        if isEnglishRussianPair(sources) {
            // The fallback map always converts EN -> RU, regardless of list order.
            return LayoutConversionMaps(
                forward: fallbackMaps.forward,
                reverse: fallbackMaps.reverse,
                forwardTargetID: sources.first(where: { primaryLanguage(for: $0) == "ru" })?.info.identifier,
                reverseTargetID: sources.first(where: { primaryLanguage(for: $0) == "en" })?.info.identifier
            )
        }

        var forward: [Character: Character] = [:]
        var reverse: [Character: Character] = [:]
        let first = characterMap(for: sources[0])
        let second = characterMap(for: sources[1])

        for (key, firstCharacter) in first {
            guard let secondCharacter = second[key], firstCharacter != secondCharacter else { continue }
            forward[firstCharacter] = secondCharacter
            reverse[secondCharacter] = firstCharacter
        }

        return forward.isEmpty || reverse.isEmpty ? nil : LayoutConversionMaps(
            forward: forward, reverse: reverse,
            forwardTargetID: sources[1].info.identifier,
            reverseTargetID: sources[0].info.identifier
        )
    }

    static var pairIdentifiers: [String] {
        preferredConversionSources(from: enabledKeyboardSources()).map { $0.info.identifier }
    }

    static var currentIdentifier: String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return property(source, kTISPropertyInputSourceID)
    }

    static var availableIdentifiers: Set<String> {
        Set(selectableSources().compactMap { property($0, kTISPropertyInputSourceID) })
    }

    static func select(identifier: String) -> Bool {
        guard let source = selectableSources().first(where: {
            property($0, kTISPropertyInputSourceID) == identifier
        }) else { return false }
        return TISSelectInputSource(source) == noErr
    }

    private static func selectableSources() -> [TISInputSource] {
        let properties: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsEnabled as String: true,
            kTISPropertyInputSourceIsSelectCapable as String: true
        ]
        return TISCreateInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] ?? []
    }

    private static func enabledKeyboardSources() -> [LayoutSource] {
        let properties: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsEnabled as String: true
        ]
        guard let sourceArray = TISCreateInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return sourceArray.compactMap { source -> LayoutSource? in
            guard let name = property(source, kTISPropertyLocalizedName),
                  let identifier = property(source, kTISPropertyInputSourceID),
                  let layoutData = dataProperty(source, kTISPropertyUnicodeKeyLayoutData)
            else {
                return nil
            }
            return LayoutSource(
                source: source,
                info: KeyboardLayoutInfo(
                    name: name,
                    identifier: identifier,
                    languages: stringArrayProperty(source, kTISPropertyInputSourceLanguages)
                ),
                layoutData: layoutData
            )
        }
    }

    private static func preferredConversionSources(from sources: [LayoutSource]) -> [LayoutSource] {
        guard sources.count > 2 else { return Array(sources.prefix(2)) }

        for firstIndex in sources.indices {
            let firstLanguage = primaryLanguage(for: sources[firstIndex])

            for secondIndex in sources.indices where secondIndex > firstIndex {
                let secondLanguage = primaryLanguage(for: sources[secondIndex])

                if firstLanguage == nil || secondLanguage == nil || firstLanguage != secondLanguage {
                    return [sources[firstIndex], sources[secondIndex]]
                }
            }
        }

        return Array(sources.prefix(2))
    }

    private static func primaryLanguage(for source: LayoutSource) -> String? {
        source.info.languages.first?.split(separator: "-").first.map(String.init)
    }

    private static func isEnglishRussianPair(_ sources: [LayoutSource]) -> Bool {
        let languages = Set(sources.compactMap(primaryLanguage))
        return languages.contains("en") && languages.contains("ru")
    }

    private static func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let value = TISGetInputSourceProperty(source, key) else { return nil }
        return unsafeBitCast(value, to: CFString.self) as String
    }

    private static func stringArrayProperty(_ source: TISInputSource, _ key: CFString) -> [String] {
        guard let value = TISGetInputSourceProperty(source, key) else { return [] }
        let array = unsafeBitCast(value, to: NSArray.self)
        return array.compactMap { $0 as? String }
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
            UInt32(shiftKey)
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
        var length = 0
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
                buffer.count,
                &length,
                buffer.baseAddress
            )
        }
        guard status == noErr, length == 1 else { return nil }
        let value = String(utf16CodeUnits: chars, count: length)
        guard value.count == 1, let character = value.first, !character.isWhitespace else { return nil }
        return character
    }
}

@MainActor final class KeyboardAutomation {
    private let environment = MacInputEnvironment()
    private lazy var operations = InputOperations(environment: environment)

    func convertSelection(language: AppLanguage) async -> String {
        guard AccessibilityPermission.requestPrompt() else { return AppText.accessibilityRequired(language) }
        return message(await operations.convertSelection(), language: language)
    }

    func switchLocale(language: AppLanguage) async -> String {
        guard AccessibilityPermission.requestPrompt() else { return AppText.accessibilityRequired(language) }
        return message(await operations.switchSource(), language: language)
    }

    private func message(_ result: InputOperationResult, language: AppLanguage) -> String {
        let russian = language == .russian
        switch result {
        case .busy:
            return russian ? "Предыдущая операция ещё выполняется." : "An operation is still in progress."
        case .noContext:
            return russian ? "Не удалось определить активное поле ввода." : "Could not identify the focused input field."
        case .noSelection:
            return russian ? "Нет доступного выделения или поле не поддерживает проверяемую замену." : "No accessible selection, or this field does not support verified replacement."
        case .contextChanged:
            return russian ? "Операция отменена: фокус изменился." : "Operation cancelled: focus changed."
        case .replacementUnconfirmed:
            return russian ? "Замена текста не подтверждена. Раскладка не переключалась." : "Text replacement was not confirmed. No input source switch was requested."
        case .converted:
            return AppText.textConverted(language)
        case .convertedAndSwitched:
            return russian ? "Текст сконвертирован, целевая раскладка включена." : "Text converted; the target input source is active."
        case .convertedSourceUnconfirmed:
            return russian ? "Текст сконвертирован, но целевая раскладка не подтверждена." : "Text converted, but the target input source was not confirmed."
        case .sourceUnavailable:
            return russian ? "Текущий источник вне рабочей пары или вторая раскладка недоступна." : "The current source is outside the working pair, or the other source is unavailable."
        case .switched:
            return russian ? "Раскладка переключена." : "Input source switched."
        case .switchUnconfirmed:
            return russian ? "Переключение не подтверждено: источник или фокус изменился либо система отказала." : "Switch not confirmed: the source or focus changed, or the system declined the request."
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
    private let onLanguageChange: () -> Void
    private let onEditingActive: (Bool) -> Void
    private let statusLabel = NSTextField(labelWithString: "")
    private let accessibilityNotice = NSStackView()
    private let accessibilityMessage = NSTextField(labelWithString: "")
    private let accessibilityButton = NSButton(title: "", target: nil, action: nil)
    private let layoutsNotice = NSStackView()
    private let layoutsMessage = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "LangConvert")
    private let languageLabel = NSTextField(labelWithString: "")
    private let languageHintLabel = NSTextField(labelWithString: "")
    private let languagePopup = NSPopUpButton()
    private let convertLabel = NSTextField(labelWithString: "")
    private let switchLocaleLabel = NSTextField(labelWithString: "")
    private let launchCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    init(
        store: SettingsStore,
        loginItems: LoginItemManager,
        onChange: @escaping () -> Void,
        onLanguageChange: @escaping () -> Void,
        onEditingActive: @escaping (Bool) -> Void
    ) {
        self.store = store
        self.loginItems = loginItems
        self.onChange = onChange
        self.onLanguageChange = onLanguageChange
        self.onEditingActive = onEditingActive

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
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

        titleLabel.font = .boldSystemFont(ofSize: 24)

        configureLanguagePopup()

        let convertField = makeHotKeyField(value: store.settings.convertHotKey.display)
        convertField.onRecord = { [weak self] hotKey in
            guard let self else { return }
            var settings = store.settings
            settings.convertHotKey = hotKey
            store.update(settings)
            onChange()
            setStatus(AppText.convertHotKeySaved(store.settings.language))
        }

        let switchField = makeHotKeyField(value: store.settings.switchLocaleHotKey.display)
        switchField.onRecord = { [weak self] hotKey in
            guard let self else { return }
            var settings = store.settings
            settings.switchLocaleHotKey = hotKey
            store.update(settings)
            onChange()
            setStatus(AppText.switchLocaleHotKeySaved(store.settings.language))
        }

        launchCheckbox.state = loginItems.isEnabled ? .on : .off
        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunchAtLogin(_:))

        configureAccessibilityNotice()
        configureLayoutsNotice()

        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(accessibilityNotice)
        stack.addArrangedSubview(layoutsNotice)
        stack.addArrangedSubview(languageSection())
        stack.addArrangedSubview(labeled(label: convertLabel, field: convertField))
        stack.addArrangedSubview(labeled(label: switchLocaleLabel, field: switchField))
        stack.addArrangedSubview(launchCheckbox)
        stack.addArrangedSubview(statusLabel)

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24)
        ])
        applyLocalization(updateStatus: true)
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
        layoutsMessage.stringValue = AppText.layoutsNotice(names, language: store.settings.language)
    }

    @objc private func requestAccessibilityPermission() {
        if AccessibilityPermission.requestPrompt() {
            setStatus(AppText.accessibilityAlreadyAllowed(store.settings.language))
        } else {
            setStatus(AppText.accessibilityOpenSettings(store.settings.language))
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        let enabled = sender.state == .on
        let ok = loginItems.setEnabled(enabled)
        var settings = store.settings
        settings.launchAtLogin = ok && enabled
        store.update(settings)
        sender.state = settings.launchAtLogin ? .on : .off
        setStatus(ok ? AppText.launchAtLoginUpdated(settings.language) : AppText.launchAtLoginBundleOnly(settings.language))
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

    private func labeled(label: NSTextField, field: NSView) -> NSView {
        label.font = .boldSystemFont(ofSize: 13)
        let row = NSStackView(views: [label, field])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 16
        label.widthAnchor.constraint(equalToConstant: 210).isActive = true
        return row
    }

    private func languageSection() -> NSView {
        languageLabel.font = .boldSystemFont(ofSize: 13)
        languageHintLabel.font = .systemFont(ofSize: 12)
        languageHintLabel.textColor = .secondaryLabelColor

        let column = NSStackView(views: [languagePopup, languageHintLabel])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 4
        languagePopup.widthAnchor.constraint(equalToConstant: 240).isActive = true

        let row = NSStackView(views: [languageLabel, column])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 16
        languageLabel.widthAnchor.constraint(equalToConstant: 210).isActive = true
        return row
    }

    private func configureLanguagePopup() {
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        languagePopup.removeAllItems()
        for language in AppLanguage.allCases {
            languagePopup.addItem(withTitle: language.displayName)
            languagePopup.lastItem?.representedObject = language.rawValue
        }
        selectLanguage(store.settings.language)
    }

    private func selectLanguage(_ selectedLanguage: AppLanguage) {
        if let item = languagePopup.itemArray.first(where: { $0.representedObject as? String == selectedLanguage.rawValue }) {
            languagePopup.select(item)
        }
    }

    private func applyLocalization(updateStatus: Bool) {
        let language = store.settings.language
        window?.title = AppText.settings(language)
        languageLabel.stringValue = AppText.languageLabel(language)
        languageHintLabel.stringValue = AppText.languageHint(language)
        convertLabel.stringValue = AppText.convertHotKey(language)
        switchLocaleLabel.stringValue = AppText.switchLocaleHotKey(language)
        launchCheckbox.title = AppText.launchAtLogin(language)
        accessibilityButton.title = AppText.accessibilityButton(language)
        accessibilityMessage.stringValue = AppText.accessibilityNotice(language)
        if updateStatus || statusLabel.stringValue.isEmpty {
            statusLabel.stringValue = AppText.initialStatus(language)
        }
        refreshLayoutsNotice()
    }

    @objc private func languageChanged() {
        guard
            let rawValue = languagePopup.selectedItem?.representedObject as? String,
            let language = AppLanguage(rawValue: rawValue),
            language != store.settings.language
        else {
            return
        }

        var settings = store.settings
        settings.language = language
        store.update(settings)
        applyLocalization(updateStatus: false)
        setStatus(AppText.languageSaved(language))
        onLanguageChange()
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private let automation = KeyboardAutomation()
    private let loginItems = LoginItemManager()
    private let hotKeys = GlobalHotKeyManager()
    private var statusItem: NSStatusItem?
    private var settingsWindow: SettingsWindowController?
    private var settingsMenuItem: NSMenuItem?
    private var aboutMenuItem: NSMenuItem?
    private var quitMenuItem: NSMenuItem?

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
        let settingsItem = menuItem(AppText.settings(store.settings.language), action: #selector(openSettings), keyEquivalent: ",")
        let aboutItem = menuItem(AppText.about(store.settings.language), action: #selector(openAbout), keyEquivalent: "")
        let quitItem = menuItem(AppText.quit(store.settings.language), action: #selector(quit), keyEquivalent: "q")
        menu.addItem(settingsItem)
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        item.menu = menu
        statusItem = item
        settingsMenuItem = settingsItem
        aboutMenuItem = aboutItem
        quitMenuItem = quitItem
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
                onLanguageChange: { [weak self] in
                    self?.applyLocalization()
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

    @objc private func openAbout() {
        let language = store.settings.language
        let alert = NSAlert()
        alert.messageText = AppText.about(language)
        alert.informativeText = AppText.aboutMessage(version: AppMetadata.version, language: language)
        alert.alertStyle = .informational
        alert.addButton(withTitle: AppText.ok(language))
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func convertSelection() {
        Task { @MainActor in
            let message = await automation.convertSelection(language: store.settings.language)
            settingsWindow?.setStatus(message)
            statusItem?.button?.toolTip = message
        }
    }

    @objc private func switchLocale() {
        Task { @MainActor in
            let message = await automation.switchLocale(language: store.settings.language)
            settingsWindow?.setStatus(message)
            statusItem?.button?.toolTip = message
        }
    }

    private func applyLocalization() {
        let language = store.settings.language
        settingsMenuItem?.title = AppText.settings(language)
        aboutMenuItem?.title = AppText.about(language)
        quitMenuItem?.title = AppText.quit(language)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// AppKit starts on the main thread; keep delegate creation on MainActor.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
