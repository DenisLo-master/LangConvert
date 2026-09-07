# TDD evidence — P1

2026-09-07. Developer Team / TDD expert, отдельный контекст от developer.
Проверены [strategy](tdd-strategy.md), [handoff](p1-implementation.md), actual
production core, Swift tests, diff Package.swift/main.swift и evidence P1.
Task SHA-256: `e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`.
Strategy SHA-256: `49d36f5d6761567dd6ea13b6e630337fb6cca108862f1c907074afdc9b65575a`.
Code base HEAD: `1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55`; implementation —
рабочее дерево, привязано к `evidence/p1-final-sha256.txt`, все четыре hash совпали.

## Вердикт и границы

**Core-only: `TDD_EVIDENCE_APPROVED`. Полная P1: `TDD_BLOCKED`.**

Проверенный RED → GREEN реального Swift core принят. Не подтверждены native
Provider, macOS typecheck/link и фактические системные источники. Эти части
входят в P1 AC12/14/18; нельзя объявить всю P1 принятой только по Linux core.
Данный scoped verdict не делит утверждённый план и не разрешает обходить
его dependencies. Полная QA фазы не начинается до закрытия обязательного evidence.

| Поле | Проверенный результат |
| --- | --- |
| checked_phase | P1, core conversion; native integration отдельно blocked |
| red_evidence | `evidence/p1-red.txt`: 7 tests, 12 assertion failures из-за nil target при правильном тексте; не compile failure |
| green_evidence | `evidence/p1-green.txt`: обновлённый run 10:36:47 UTC, 7 tests, 0 failures; независимый повтор предыдущей версии 10:35:57 UTC также exit 0, 7 tests, 0 failures |
| public_interface_check | pass: `LayoutConverter.convert` и `conversion`, результат text/targetSourceID, заданные карты |
| coupling_check | pass: тесты импортируют production module; нет копии алгоритма, private assertions или internal mocks |
| coverage_check | pass для основных core behaviors; blocked для full P1 native binding/реальных пар |
| required_fixes | Получить native evidence перед полной приёмкой P1; кодовые нарушения TDD sequence не обнаружены |

## Последовательность и идентичность

Baseline `p1-baseline.txt`: один XCTest с пятью прежними примерами прошёл
в 10:32:27. RED — 10:33:24, GREEN — 10:34:33. Проверен сохранённый RED source
`/tmp/langconvert-swift/p1-red-Conversion.swift`: hash совпадает с
`p1-red-sha256.txt` (`cf278217…`). Он возвращает production converted text и nil
цель, как заранее разрешено strategy для наблюдаемого старого поведения.
`p1-fix.diff` меняет только определение цели поверх этого seam.

На первом GREEN test hash совпадал с RED (`4732da54…`). После review добавлена
одна assertion для `привет q` при noRussian maps; новый test hash
`ff0ba9a78c640a5027400bc1866f8c35e264270190f05de86730161d63f05209`.
Независимо проверено: удаление только этой строки из прочитанного текста
в памяти даёт точный исходный RED hash. Исходные 12 failing assertions
не изменены и не ослаблены; production bytes прежние. Новый GREEN подтверждён
обновлённым логом 10:36:47, 7 tests, 0 failures. Дополнительная assertion —
усиление regression coverage после GREEN, не новый заявленный RED.
Final core hash `6791ae11…`; Package.swift, main.swift и tests также сверены
через `sha256sum -c evidence/p1-final-sha256.txt`, все OK. Доказательств отдельного
refactor до GREEN нет; handoff описывает последовательное устранение failing
cases, а не объявление промежуточного неуспеха завершённым GREEN.

Независимо выполнено в проекте:

```sh
. /tmp/langconvert-swift/env.sh
swift test --sdk /tmp/langconvert-swift/sysroot
```

Exit 0, семь реальных XCTest. Предупреждение SDKSettings.json не мешало
исполнению. Baseline запускался фильтром существующего тестового метода вместо
предложенного имени suite ConversionBaselineTests; это не ослабило проверку:
виден непустой run с пятью прежними примерами. RED/GREEN выполняют ту же
production поверхность. Старый Python test не использован как evidence Swift.

## Покрытие и остающиеся ограничения

- AC04/05: текст и target обеих сторон; AC07/08: последняя цель, в том числе
  против большинства; AC06: окончания цифрами, пробелами, пунктуацией.
- AC09: пустое/неопределённое содержимое, emoji, нейтральные и неизменённые
  mappings; AC14: nil при отсутствии доступного target ID в данных core.
- AC18: искусственная другая пара проверяет преобразование и явные IDs;
  это не наблюдение реально установленной пары на macOS.
- AC12/14: native Provider связывает fallback EN→RU по primaryLanguage и
  другую пару по её сторонам. Swift core получает уже подготовленные IDs,
  поэтому тесты не доказывают правильность Provider при реальном порядке
  источников, вариантах EN/RU, неполной паре и более двух источниках.
- Синтаксический parse main.swift не проверяет разрешение типов, импорт
  LangConvertCore на macOS или TIS runtime. Нужны macOS build и проверки
  реальных источников в пределах P1 перед full-phase approval.
- Дополнительное покрытие после review: `привет q` с noRussian maps даёт nil;
  последнее определимое направление без ID не подменяется более ранней
  доступной EN. Обнаруженный пробел этого случая закрыт.
- Остаточное усиление: прямые text assertions для всех mixed/trailing cases
  улучшат preservation, сейчас часть случаев проверяет только target.

Применение target к системе после замены, отмена по фокусу и подтверждение
замены относятся к P2 и не проверялись. Никакого QA/reviewer verdict или
изменения статуса плана этим отчётом не создано.
