#!/usr/bin/env python3
pairs = [
    ("`", "ё"), ("q", "й"), ("w", "ц"), ("e", "у"), ("r", "к"), ("t", "е"),
    ("y", "н"), ("u", "г"), ("i", "ш"), ("o", "щ"), ("p", "з"), ("[", "х"),
    ("]", "ъ"), ("a", "ф"), ("s", "ы"), ("d", "в"), ("f", "а"), ("g", "п"),
    ("h", "р"), ("j", "о"), ("k", "л"), ("l", "д"), (";", "ж"), ("'", "э"),
    ("z", "я"), ("x", "ч"), ("c", "с"), ("v", "м"), ("b", "и"), ("n", "т"),
    ("m", "ь"), (",", "б"), (".", "ю"), ("/", "."),
    ("~", "Ё"), ("Q", "Й"), ("W", "Ц"), ("E", "У"), ("R", "К"), ("T", "Е"),
    ("Y", "Н"), ("U", "Г"), ("I", "Ш"), ("O", "Щ"), ("P", "З"), ("{", "Х"),
    ("}", "Ъ"), ("A", "Ф"), ("S", "Ы"), ("D", "В"), ("F", "А"), ("G", "П"),
    ("H", "Р"), ("J", "О"), ("K", "Л"), ("L", "Д"), (":", "Ж"), ('"', "Э"),
    ("Z", "Я"), ("X", "Ч"), ("C", "С"), ("V", "М"), ("B", "И"), ("N", "Т"),
    ("M", "Ь"), ("<", "Б"), (">", "Ю"), ("?", ","), ("@", '"'), ("#", "№"),
    ("$", ";"), ("^", ":"), ("&", "?"),
]

en_to_ru = dict(pairs)
ru_to_en = {ru: en for en, ru in pairs}


def convert(value):
    result = []
    chars = list(value)

    for index, char in enumerate(chars):
        forward = en_to_ru.get(char)
        reverse = ru_to_en.get(char)

        if forward and not reverse:
            result.append(forward)
        elif reverse and not forward:
            result.append(reverse)
        elif forward and reverse:
            result.append(reverse if preferred_direction(index, chars) == "reverse" else forward)
        else:
            result.append(char)

    return "".join(result)


def preferred_direction(index, chars):
    for distance in range(1, max(len(chars), 1)):
        before = index - distance
        after = index + distance

        if before >= 0:
            direction = unambiguous_direction(chars[before])
            if direction:
                return direction

        if after < len(chars):
            direction = unambiguous_direction(chars[after])
            if direction:
                return direction

    return "forward"


def unambiguous_direction(char):
    has_forward = char in en_to_ru
    has_reverse = char in ru_to_en

    if has_forward and not has_reverse:
        return "forward"
    if has_reverse and not has_forward:
        return "reverse"
    return None


cases = {
    "fyfkbp ыныеуь": "анализ system",
    "руддщ ghbdtn": "hello привет",
    "yflj d jgbcfybb cltkfnm frwbtyn": "надо в описании сделать акциент",
    ",b,kbjntrf": "библиотека",
    "текст,": "ntrcn?",
}

for source, expected in cases.items():
    actual = convert(source)
    if actual != expected:
        raise SystemExit(f"{source!r}: expected {expected!r}, got {actual!r}")

print("layout converter tests passed")
