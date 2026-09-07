# P1 developer handoff

2026-09-07, GPT Admin / developer. Ветка codex/system-layout-sync.
Task hash e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14.
Phase P1, исходный HEAD 1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55.
Strategy P1 TDD_PHASE_READY получен до изменения исходников; P2 не начата.

Изменены Package.swift, Sources/LangConvert/main.swift,
Sources/LangConvertCore/Conversion.swift и Tests/LangConvertCoreTests/ConversionAcceptanceTests.swift.
Production преобразование вынесено в LangConvertCore без копии алгоритма в тестах.
На macOS executable зависит от core; Linux собирает только core/tests.
Существующий вызывающий код по-прежнему получает текст; применение целевой
раскладки и безопасная замена принадлежат P2 и ещё не реализованы.

## Debugging

Подтверждённый исходный дефект: преобразование не возвращало целевой источник,
а вызывающая операция оставляла раскладку прежней. Подготовлена тестовая
поверхность result(text, targetSourceID), начальное nil сохраняет отсутствие
выбора, без изменения преобразования. Пять существующих примеров проверены
непосредственно в production Swift: baseline pass.
Затем добавлен тест, ожидающий конкретную целевую раскладку при верном тексте:
он реально падал до фикса (12 assertion failures). Это не ошибка компиляции.

Первый фикс выявил один оставшийся отказ на строке ` /, `: исходный `/`
однозначен, но результат `.` принадлежит обеим картам. Для выбора источника
теперь требуется однозначность и исходного, и преобразованного символа;
сами правила преобразования текста не изменены. Цифры, пробелы и неизменённые
символы пропускаются. Если последняя определимая цель не имеет source ID,
возвращается nil, без перехода к более раннему символу с другой целью.

## TDD evidence

- applied: yes, P1 behavior only.
- Baseline: evidence/p1-baseline.txt, 1 XCTest с пятью существующими примерами, pass.
- RED: evidence/p1-red.txt; 7 XCTest, 12 failures, production text assertions pass.
- RED hashes: evidence/p1-red-sha256.txt.
- Fix diff: evidence/p1-fix.diff, относительно сохранённой RED production поверхности.
- GREEN: evidence/p1-green.txt, 7 XCTest, 0 failures.
- Итоговые source/test hashes: evidence/p1-final-sha256.txt.

Команды в подготовленном окружении:
`. /tmp/langconvert-swift/env.sh; swift test --sdk /tmp/langconvert-swift/sysroot`
и `swift build --sdk /tmp/langconvert-swift/sysroot`: pass.
`swiftc -frontend -parse Sources/LangConvert/main.swift`: синтаксическая проверка,
не macOS typecheck/link/runtime. Python regression, bash -n и git diff --check: pass.

Покрыты определение направления, обе стороны, last-over-majority, неоднозначные
и нейтральные окончания, отсутствующая цель, другая пара, неизменённые карты.
Provider сохраняет выбор пары и связывает EN/RU fallback по языку источника,
а не порядку массива. Его native TIS выполнение на Linux не проверено.

Нужны отдельные TDD evidence и QA/reviewer. Не заявляется ни полная macOS сборка,
ни успешность AC с системным переключением/фокусом. pkg, README и CI не изменены.

Дополнительная проверка после первоначального GREEN: при `привет q` и
отсутствующем RU target результат должен остаться nil, а не выбрать EN по более
раннему символу. Добавлена одна assertion без изменения production кода;
все семь тестов повторно прошли. GREEN и final hashes обновлены.
