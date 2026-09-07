import XCTest
import LangConvertCore

final class ConversionAcceptanceTests: XCTestCase {
    func testExistingTextConversion() {
        let converter = LayoutConverter()
        let cases = [
            "fyfkbp ыныеуь": "анализ system",
            "руддщ ghbdtn": "hello привет",
            "yflj d jgbcfybb cltkfnm frwbtyn": "надо в описании сделать акциент",
            ",b,kbjntrf": "библиотека",
            "текст,": "ntrcn?"
        ]
        for (input, expected) in cases {
            XCTAssertEqual(converter.convert(input, using: converter.fallbackMaps), expected)
        }
    }

    private func maps() -> LayoutConversionMaps {
        let fallback = LayoutConverter().fallbackMaps
        return LayoutConversionMaps(forward: fallback.forward, reverse: fallback.reverse,
                                    forwardTargetID: "ru-PC", reverseTargetID: "en-ABC")
    }

    func testTargetForBothDirections() {
        let converter = LayoutConverter()
        for (input, text, target) in [("ghbdtn", "привет", "ru-PC"),
                                      ("привет", "ghbdtn", "en-ABC")] {
            let result = converter.conversion(input, using: maps())
            XCTAssertEqual(result.text, text)
            XCTAssertEqual(result.targetSourceID, target)
        }
    }

    func testLastDirectionWinsOverMajority() {
        let converter = LayoutConverter()
        XCTAssertEqual(converter.conversion("руддщ ghbdtn", using: maps()).targetSourceID, "ru-PC")
        XCTAssertEqual(converter.conversion("ghbdtn руддщ", using: maps()).targetSourceID, "en-ABC")
        XCTAssertEqual(converter.conversion("руддщ руддщ руддщ q", using: maps()).targetSourceID, "ru-PC")
    }

    func testTrailingNeutralCharactersDoNotChangeTarget() {
        let converter = LayoutConverter()
        for input in ["ghbdtn 123 ", "ghbdtn,", "ghbdtn\n", "ghbdtn😀", "ghbdtn / "] {
            XCTAssertEqual(converter.conversion(input, using: maps()).targetSourceID, "ru-PC", input)
        }
    }

    func testNoTargetForUnresolvedTextOrSource() {
        let converter = LayoutConverter()
        for input in ["", "123 ", " /, ", "😀"] {
            XCTAssertNil(converter.conversion(input, using: maps()).targetSourceID, input)
        }
        XCTAssertNil(converter.conversion("ghbdtn", using: converter.fallbackMaps).targetSourceID)
        let noRussian = LayoutConversionMaps(forward: maps().forward, reverse: maps().reverse,
                                            reverseTargetID: "en-ABC")
        XCTAssertNil(converter.conversion("ghbdtn", using: noRussian).targetSourceID)
        XCTAssertNil(converter.conversion("привет q", using: noRussian).targetSourceID)
    }

    func testOtherPairUsesExplicitIdentifiers() {
        let converter = LayoutConverter()
        let pair = LayoutConversionMaps(forward: ["a": "ä"], reverse: ["ä": "a"],
                                        forwardTargetID: "second-layout", reverseTargetID: "first-layout")
        let result = converter.conversion("a ä", using: pair)
        XCTAssertEqual(result.text, "ä a")
        XCTAssertEqual(result.targetSourceID, "first-layout")
    }

    func testDigitsAndUnchangedMappingsCannotSetDirection() {
        let converter = LayoutConverter()
        let pair = LayoutConversionMaps(forward: ["a": "ä", "1": "!", "x": "x"],
                                        reverse: ["ä": "a", "!": "1"],
                                        forwardTargetID: "second", reverseTargetID: "first")
        XCTAssertNil(converter.conversion("1", using: pair).targetSourceID)
        XCTAssertNil(converter.conversion("!", using: pair).targetSourceID)
        XCTAssertNil(converter.conversion("x", using: pair).targetSourceID)
        XCTAssertEqual(converter.conversion("ä1x", using: pair).targetSourceID, "first")
    }
}
