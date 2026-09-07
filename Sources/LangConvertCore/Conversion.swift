public final class LayoutConverter {
    private let enToRu: [Character: Character]
    private let ruToEn: [Character: Character]

    public init() {
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

    public var fallbackMaps: LayoutConversionMaps {
        LayoutConversionMaps(forward: enToRu, reverse: ruToEn)
    }

    public func conversion(_ text: String, using maps: LayoutConversionMaps) -> ConversionResult {
        let converted = convert(text, using: maps)
        for character in text.reversed() {
            guard !character.isWhitespace, !character.isNumber,
                  let direction = unambiguousDirection(for: character, using: maps)
            else { continue }
            let mapped = direction == .forward ? maps.forward[character] : maps.reverse[character]
            guard let mapped, mapped != character, !mapped.isWhitespace, !mapped.isNumber,
                  let mappedDirection = unambiguousDirection(for: mapped, using: maps),
                  mappedDirection != direction
            else { continue }
            let target = direction == .forward ? maps.forwardTargetID : maps.reverseTargetID
            return ConversionResult(text: converted, targetSourceID: target)
        }
        return ConversionResult(text: converted, targetSourceID: nil)
    }

    public func convert(_ text: String, using maps: LayoutConversionMaps) -> String {
        let characters = Array(text)
        return String(characters.enumerated().map { index, character in
            let forward = maps.forward[character]
            let reverse = maps.reverse[character]

            switch (forward, reverse) {
            case let (forward?, nil):
                return forward
            case let (nil, reverse?):
                return reverse
            case let (forward?, reverse?):
                return preferredDirection(at: index, in: characters, using: maps) == .reverse ? reverse : forward
            case (nil, nil):
                return character
            }
        })
    }

    private func preferredDirection(
        at index: Int,
        in characters: [Character],
        using maps: LayoutConversionMaps
    ) -> LayoutConversionDirection {
        for distance in 1..<max(characters.count, 1) {
            if index - distance >= 0,
               let direction = unambiguousDirection(for: characters[index - distance], using: maps)
            {
                return direction
            }

            if index + distance < characters.count,
               let direction = unambiguousDirection(for: characters[index + distance], using: maps)
            {
                return direction
            }
        }

        return .forward
    }

    private func unambiguousDirection(
        for character: Character,
        using maps: LayoutConversionMaps
    ) -> LayoutConversionDirection? {
        let hasForward = maps.forward[character] != nil
        let hasReverse = maps.reverse[character] != nil

        if hasForward && !hasReverse {
            return .forward
        }

        if hasReverse && !hasForward {
            return .reverse
        }

        return nil
    }
}

public struct ConversionResult: Equatable {
    public let text: String
    public let targetSourceID: String?
}

public struct LayoutConversionMaps {
    public let forward: [Character: Character]
    public let reverse: [Character: Character]
    public let forwardTargetID: String?
    public let reverseTargetID: String?

    public init(forward: [Character: Character], reverse: [Character: Character],
                forwardTargetID: String? = nil, reverseTargetID: String? = nil) {
        self.forward = forward
        self.reverse = reverse
        self.forwardTargetID = forwardTargetID
        self.reverseTargetID = reverseTargetID
    }
}

private enum LayoutConversionDirection {
    case forward
    case reverse
}
