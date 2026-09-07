public enum ReplacementState { case pending, confirmed, failed }

public enum InputOperationResult: Equatable {
    case busy, noContext, noSelection, contextChanged
    case replacementUnconfirmed, converted, convertedAndSwitched, convertedSourceUnconfirmed
    case sourceUnavailable, switched, switchUnconfirmed
}

/// Boundary to the system, rather than a second store of the active layout.
@MainActor public protocol InputEnvironment: AnyObject {
    func captureSwitchContext() -> String?
    func captureContext() -> String?
    func contextIsCurrent(_ context: String) -> Bool
    func releaseContext(_ context: String)
    func selectedText(in context: String) -> String?
    func replaceSelection(with text: String, in context: String) -> Bool
    func replacementState(in context: String) -> ReplacementState
    var conversionMaps: LayoutConversionMaps { get }
    var pairIDs: [String] { get }
    var availableSourceIDs: Set<String> { get }
    var currentSourceID: String? { get }
    func selectSource(_ identifier: String) -> Bool
    func waitForSystem() async
}

@MainActor public final class InputOperations {
    private let environment: any InputEnvironment
    private let converter = LayoutConverter()
    private var busy = false
    private let confirmationAttempts = 12

    public init(environment: any InputEnvironment) { self.environment = environment }

    public func convertSelection() async -> InputOperationResult {
        guard !busy else { return .busy }
        busy = true
        defer { busy = false }
        guard let context = environment.captureContext() else { return .noContext }
        defer { environment.releaseContext(context) }
        guard isCurrent(context) else { return .contextChanged }
        guard let selected = environment.selectedText(in: context), !selected.isEmpty else { return .noSelection }
        let sourceBeforeReplacement = environment.currentSourceID
        let result = converter.conversion(selected, using: environment.conversionMaps)
        guard isCurrent(context) else { return .contextChanged }
        guard environment.replaceSelection(with: result.text, in: context) else { return .replacementUnconfirmed }

        for attempt in 0..<confirmationAttempts {
            // Readback may also finalize the caret in the native adapter.
            guard !Task.isCancelled else { return .replacementUnconfirmed }
            switch environment.replacementState(in: context) {
            case .confirmed:
                guard let target = result.targetSourceID else { return .converted }
                let succeeded = await select(target, in: context, expectedSource: sourceBeforeReplacement)
                return succeeded ? .convertedAndSwitched : .convertedSourceUnconfirmed
            case .failed:
                return .replacementUnconfirmed
            case .pending:
                guard isCurrent(context), attempt + 1 < confirmationAttempts else { return .replacementUnconfirmed }
                await environment.waitForSystem()
            }
        }
        return .replacementUnconfirmed
    }

    public func switchSource() async -> InputOperationResult {
        guard !busy else { return .busy }
        busy = true
        defer { busy = false }
        guard let context = environment.captureSwitchContext() else { return .noContext }
        defer { environment.releaseContext(context) }
        guard isCurrent(context) else { return .contextChanged }
        let pair = environment.pairIDs
        guard pair.count == 2, pair[0] != pair[1],
              let current = environment.currentSourceID, pair.contains(current),
              pair.allSatisfy({ environment.availableSourceIDs.contains($0) })
        else { return .sourceUnavailable }
        let target = pair[0] == current ? pair[1] : pair[0]
        return await select(target, in: context, expectedSource: current) ? .switched : .switchUnconfirmed
    }

    private func isCurrent(_ context: String) -> Bool {
        !Task.isCancelled && environment.contextIsCurrent(context)
    }

    private func select(_ target: String, in context: String, expectedSource: String?) async -> Bool {
        guard isCurrent(context), environment.availableSourceIDs.contains(target) else { return false }
        let current = environment.currentSourceID
        if current == target { return true }
        // An external change after capture wins; do not restore our earlier intent.
        guard current == expectedSource, environment.selectSource(target) else { return false }
        for attempt in 0..<confirmationAttempts {
            guard isCurrent(context), environment.availableSourceIDs.contains(target) else { return false }
            let observed = environment.currentSourceID
            if observed == target { return true }
            guard observed == current, attempt + 1 < confirmationAttempts else { return false }
            await environment.waitForSystem()
        }
        return false
    }
}
