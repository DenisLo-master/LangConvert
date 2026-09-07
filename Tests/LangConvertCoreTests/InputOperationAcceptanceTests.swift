import XCTest
import LangConvertCore

@MainActor final class TestInputEnvironment: InputEnvironment {
    var validContext = true
    var source: String? = "en"
    var sources: Set<String> = ["en", "ru"]
    var pairIDs = ["en", "ru"]
    var text = "ghbdtn"
    var allowReplacement = true
    var state = ReplacementState.confirmed
    var allowSelect = true
    var applySelect = true
    var selectionRequests: [String] = []
    var onVerify: (() -> Void)?
    var onReplace: (() -> Void)?
    var onWait: (() async -> Void)?
    var switchContextAvailable: Bool?
    var contextAvailable = true
    var released = false
    var conversionMaps: LayoutConversionMaps {
        let maps = LayoutConverter().fallbackMaps
        return LayoutConversionMaps(forward: maps.forward, reverse: maps.reverse,
                                    forwardTargetID: "ru", reverseTargetID: "en")
    }
    var availableSourceIDs: Set<String> { sources }
    var currentSourceID: String? { source }
    func captureSwitchContext() -> String? { (switchContextAvailable ?? contextAvailable) ? "window" : nil }
    func captureContext() -> String? { contextAvailable ? "document" : nil }
    func contextIsCurrent(_ context: String) -> Bool { validContext }
    func releaseContext(_ context: String) { released = true }
    func selectedText(in context: String) -> String? { text }
    func replaceSelection(with text: String, in context: String) -> Bool {
        guard allowReplacement else { return false }
        self.text = text
        onReplace?()
        return true
    }
    func replacementState(in context: String) -> ReplacementState { onVerify?(); return state }
    func selectSource(_ identifier: String) -> Bool {
        selectionRequests.append(identifier)
        if allowSelect && applySelect { source = identifier }
        return allowSelect
    }
    func waitForSystem() async { await onWait?() }
}

final class InputOperationAcceptanceTests: XCTestCase {
    @MainActor func testBaselineReplacement() async {
        let env = TestInputEnvironment()
        _ = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(env.text, "привет")
        XCTAssertTrue(env.released)
    }

    @MainActor func testConvertsAndSelectsResultSource() async {
        let env = TestInputEnvironment()
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(env.text, "привет")
        XCTAssertEqual(env.source, "ru")
        XCTAssertEqual(result, .convertedAndSwitched)
    }

    @MainActor func testManualReadsCurrentSystemSourceEveryTime() async {
        let env = TestInputEnvironment()
        let operations = InputOperations(environment: env)
        env.source = "ru"
        let first = await operations.switchSource()
        XCTAssertEqual(first, .switched)
        XCTAssertEqual(env.source, "en")
        env.source = "ru" // External system change, independent of our previous action.
        _ = await operations.switchSource()
        XCTAssertEqual(env.source, "en")
    }

    @MainActor func testOutsidePairAndIncompletePairDoNotGuess() async {
        let env = TestInputEnvironment()
        env.source = "fr"
        let outside = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(outside, .sourceUnavailable)
        XCTAssertEqual(env.source, "fr")
        env.source = "en"
        env.sources = ["en"]
        let missing = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(missing, .sourceUnavailable)
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testAlreadyActiveAndNeutralTextDoNotToggle() async {
        let env = TestInputEnvironment()
        env.source = "ru"
        let operations = InputOperations(environment: env)
        let converted = await operations.convertSelection()
        XCTAssertEqual(converted, .convertedAndSwitched)
        XCTAssertTrue(env.selectionRequests.isEmpty)
        env.text = "123 "
        let neutral = await operations.convertSelection()
        XCTAssertEqual(neutral, .converted)
        XCTAssertEqual(env.source, "ru")
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testUnconfirmedReplacementNeverSwitches() async {
        let env = TestInputEnvironment()
        env.state = .pending
        let pending = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(pending, .replacementUnconfirmed)
        XCTAssertEqual(env.source, "en")
        XCTAssertTrue(env.selectionRequests.isEmpty)
        env.state = .failed
        let failed = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(failed, .replacementUnconfirmed)
    }

    @MainActor func testFailureAndNoSelectionNeverSwitch() async {
        let env = TestInputEnvironment()
        env.allowReplacement = false
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .replacementUnconfirmed)
        XCTAssertEqual(env.text, "ghbdtn")
        env.text = ""
        let empty = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(empty, .noSelection)
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testFocusLossBeforeReplacementCancels() async {
        let env = TestInputEnvironment()
        env.validContext = false
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .contextChanged)
        XCTAssertEqual(env.text, "ghbdtn")
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testFocusLossAfterConfirmedReplacementIsPartial() async {
        let env = TestInputEnvironment()
        env.onReplace = { env.validContext = false }
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .convertedSourceUnconfirmed)
        XCTAssertEqual(env.text, "привет")
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testSourceFailureAfterReplacementIsPartial() async {
        let env = TestInputEnvironment()
        env.onReplace = { env.sources = ["en"] }
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .convertedSourceUnconfirmed)
        XCTAssertEqual(env.text, "привет")
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testSelectRequestIsNotConfirmationAndIsNotRetried() async {
        let env = TestInputEnvironment()
        env.applySelect = false
        env.onWait = { env.source = "fr" }
        let result = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(result, .switchUnconfirmed)
        XCTAssertEqual(env.source, "fr")
        XCTAssertEqual(env.selectionRequests, ["ru"])
    }

    @MainActor func testConcurrentActionRejectedAndLaterActionAllowed() async {
        let env = TestInputEnvironment()
        env.state = .pending
        let operations = InputOperations(environment: env)
        var nested: InputOperationResult?
        env.onWait = {
            nested = await operations.switchSource()
            env.state = .confirmed
        }
        let result = await operations.convertSelection()
        XCTAssertEqual(nested, .busy)
        XCTAssertEqual(result, .convertedAndSwitched)
        env.onWait = nil
        let next = await operations.switchSource()
        XCTAssertEqual(next, .switched)
        XCTAssertEqual(env.source, "en")
    }

    @MainActor func testExternalSourceChangeDuringReplacementWins() async {
        let env = TestInputEnvironment()
        env.onReplace = { env.source = "fr" }
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .convertedSourceUnconfirmed)
        XCTAssertEqual(env.source, "fr")
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testLateConfirmationAndFocusLossWhileWaiting() async {
        let env = TestInputEnvironment()
        env.state = .pending
        env.onWait = { env.validContext = false }
        let result = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(result, .replacementUnconfirmed)
        XCTAssertTrue(env.released)
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testSystemRefusalNeverReportsSuccess() async {
        let env = TestInputEnvironment()
        env.allowSelect = false
        let manual = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(manual, .switchUnconfirmed)
        XCTAssertEqual(env.source, "en")
        let converted = await InputOperations(environment: env).convertSelection()
        XCTAssertEqual(converted, .convertedSourceUnconfirmed)
        XCTAssertEqual(env.text, "привет")
    }

    @MainActor func testMissingContextAndMissingCurrentSource() async {
        let env = TestInputEnvironment()
        env.contextAvailable = false
        let operations = InputOperations(environment: env)
        let missing = await operations.convertSelection()
        XCTAssertEqual(missing, .noContext)
        env.contextAvailable = true
        env.source = nil
        let unknown = await operations.switchSource()
        XCTAssertEqual(unknown, .sourceUnavailable)
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testSourceNeverConfirmedTerminatesWithoutRetry() async {
        let env = TestInputEnvironment()
        env.applySelect = false
        let result = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(result, .switchUnconfirmed)
        XCTAssertEqual(env.source, "en")
        XCTAssertEqual(env.selectionRequests, ["ru"])
    }

    @MainActor func testCancellationStopsVerificationSideEffects() async {
        let env = TestInputEnvironment()
        env.state = .pending
        var verifiedAfterCancellation = false
        env.onVerify = { if Task.isCancelled { verifiedAfterCancellation = true } }
        env.onWait = {
            withUnsafeCurrentTask { $0?.cancel() }
            env.state = .confirmed
        }
        let operations = InputOperations(environment: env)
        let task = Task { @MainActor in await operations.convertSelection() }
        _ = await task.value
        XCTAssertFalse(verifiedAfterCancellation)
        XCTAssertTrue(env.selectionRequests.isEmpty)
    }

    @MainActor func testPendingSwitchRejectsBothCommands() async {
        let env = TestInputEnvironment()
        env.applySelect = false
        let operations = InputOperations(environment: env)
        var conversion: InputOperationResult?
        var switching: InputOperationResult?
        env.onWait = {
            conversion = await operations.convertSelection()
            switching = await operations.switchSource()
            env.source = "ru"
        }
        let result = await operations.switchSource()
        XCTAssertEqual(conversion, .busy)
        XCTAssertEqual(switching, .busy)
        XCTAssertEqual(result, .switched)
        XCTAssertEqual(env.text, "ghbdtn")
        XCTAssertEqual(env.selectionRequests, ["ru"])
    }

    @MainActor func testFocusLossDuringSourceConfirmationDoesNotRetry() async {
        let env = TestInputEnvironment()
        env.applySelect = false
        env.onWait = { env.validContext = false; env.source = "ru" }
        let result = await InputOperations(environment: env).switchSource()
        XCTAssertEqual(result, .switchUnconfirmed)
        XCTAssertEqual(env.selectionRequests, ["ru"])
        XCTAssertTrue(env.released)
    }
    @MainActor func testManualSwitchDoesNotRequireEditableConversionContext() async {
        let env = TestInputEnvironment()
        env.contextAvailable = false
        env.switchContextAvailable = true
        let operations = InputOperations(environment: env)
        let conversion = await operations.convertSelection()
        XCTAssertEqual(conversion, .noContext)
        XCTAssertTrue(env.selectionRequests.isEmpty)
        let switching = await operations.switchSource()
        XCTAssertEqual(switching, .switched)
        XCTAssertEqual(env.source, "ru")
        XCTAssertEqual(env.text, "ghbdtn")
    }

}
