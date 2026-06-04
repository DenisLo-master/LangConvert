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
    return "".join(en_to_ru.get(char) or ru_to_en.get(char) or char for char in value)


cases = {
    "fyfkbp ыныеуь": "анализ system",
    "руддщ ghbdtn": "hello привет",
}

for source, expected in cases.items():
    actual = convert(source)
    if actual != expected:
        raise SystemExit(f"{source!r}: expected {expected!r}, got {actual!r}")

print("layout converter tests passed")
