# TDD strategy: system-layout-sync

Дата: 2026-09-07. Исполнитель: Developer Team, TDD expert.
Pipeline: `product-dev-standard`. Scope: отдельный strategy gate до developer.
Входы: [Phase Plan revision 1](phase-plan.yml), `ARCHITECT_PHASE_APPROVED`;
[acceptance](tdd-acceptance.md), `TDD_ACCEPTANCE_TESTS_READY`;
[approval и среда](execution-evidence.md).
Task SHA-256: `e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`.
Phase Plan SHA-256: `0fc97969ba2493296af87575ff2a611a92e9ce34b7b9597747fa92b8531391db`.
Acceptance SHA-256: `3b0fc93c00e4ebb5d5375a63307d04b359f32c9daa9d456c14333949ec0578a1`.
Исходный code HEAD: `1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55`.

## Verdict

**P1: `TDD_PHASE_READY`. P2: `TDD_PHASE_BLOCKED` (macOS).**
Повторная проверка 2026-09-07: Swift 5.10.1 установлен временно в
`/tmp/langconvert-swift`. TDD expert самостоятельно повторил в каталоге probe:

```sh
. /tmp/langconvert-swift/env.sh
swift test --sdk /tmp/langconvert-swift/sysroot
```

Exit 0, XCTest выполнил 1 тест, 0 failures. Предупреждение SDKSettings.json
не помешало компиляции и исполнению. Это evidence доступности runner, **не
product RED/GREEN**. Старые записи отсутствия Swift и blocker в плане отражают
предыдущую проверку; технический scope плана сохранён. Статусы плана обновляет
владелец, настоящий отчёт их не редактирует.

Coordinator уточнил поверхность P1 в пределах approved extraction: production
LayoutConverter/Maps выделяются в LangConvertCore, core test target работает
на Linux, macOS executable условно объявлен в manifest через `#if os(macOS)`.
Такой способ исполняет реальную логику и не требует AppKit на Linux. Изменение
направления всё ещё требует настоящего RED → GREEN, это не исключение TDD.
Сначала минимальное выделение с прежним текстовым поведением и result
text/targetSourceID, где targetSourceID пока nil, baseline регрессии; затем behavioral RED
на требуемой цели и только после него исправление. Не выбирать правильную
цель до записи RED. Python не заменяет Swift; отсутствие API/runner не RED.

Уточнённые public entry points P1: `converter.convert(text, using: maps)`
сохраняет String, `converter.conversion(text, using: maps)` возвращает text и
targetSourceID. Maps содержат идентичности целей forward/reverse. Provider
связывает EN/RU fallback по языковой ориентации, не порядку списка; проверка
core не подтверждает нативную часть Provider без последующей macOS-сборки.

Ниже приведены требования будущих product runs. Подготовка production test
surface и первый RED входят в работу developer P1 после этого verdict.

## P1 — преобразование и целевая сторона пары

- `applicability: required`; `verdict: TDD_PHASE_READY`.
- Acceptance: AC04–09, AC12, AC14, AC18.
- Public surface: производственный результат преобразования текста с заданными
  картами и идентичностями сторон; проверяются итоговый текст и optional цель.
- RED: `ghbdtn` даёт `привет`, но текущее поведение не предоставляет требуемую
  цель RU. Требуется исполнимый тест через производственную поверхность, который
  падает именно на отсутствии/неверности цели, сохраняя успешную проверку текста.
  Отсутствующий символ API, невозможность импорта AppKit или отсутствие runner
  не засчитываются как поведенческий RED. Минимальная подготовка поверхности
  должна сохранить старое поведение до изменения направления.
- GREEN: тот же тест проходит; дополнительно обе стороны пары, AC06–09,
  пунктуация, произвольная не-EN/RU пара, изменённый порядок source IDs и
  неоднозначная/отсутствующая fallback-связь. Существующие пять EN/RU примеров
  проверяются непосредственно в Swift, без переноса production алгоритма в тест.
- Required commands: после `. /tmp/langconvert-swift/env.sh` baseline —
  `swift test --sdk /tmp/langconvert-swift/sysroot --filter ConversionBaselineTests`;
  RED/GREEN — `swift test --sdk /tmp/langconvert-swift/sysroot --filter ConversionAcceptanceTests`;
  итоговая core регрессия — `swift test --sdk /tmp/langconvert-swift/sysroot`.
  Suite предстоит создать; необходимо проверить ненулевое число выполненных
  тестов, не принимать пустой filtered run за успех. На macOS позже `swift build`
  для подтверждения интеграции executable, Linux core GREEN его не заменяет.
- Forbidden coupling: копия алгоритма на Python/Swift, assertions private
  direction state, вызовы private helpers, жёсткая привязка к порядку внутреннего
  обхода; допустимы входные таблицы и внешне наблюдаемые результаты.

## P2 — команда, замена и системный результат

- `applicability: required`; `verdict: TDD_PHASE_BLOCKED`; dependency P1.
- Acceptance: AC01–05, AC10–18.
- Public surface: пользовательские команды переключения/конвертации и наблюдаемые
  текст, активный источник, сообщения, отказ/частичный результат/отмена.
- Первый RED: исходная EN, выделено `ghbdtn`; после подтверждённой замены на
  `привет` источник должен стать RU. Старое поведение меняет текст и оставляет EN.
  Зафиксировать дефект до изменения выбора источника. Отдельно закрепить ручную
  команду при переназначенном Control + Space и свежем системном состоянии.
- GREEN: та же проверка проходит; добавить уже активную цель, источник вне пары,
  исчезновение цели, неподтверждённую замену, отказ доступа, частичный результат,
  все точки отмены по фокусу и повторные команды. Успех оценивается по результату,
  а не только по факту вызова выбора или отправки события.
- Required commands RED/GREEN: на подготовленной Swift-поверхности
  `swift test --filter InputOperationAcceptanceTests`, затем `swift test` и
  `swift build` на macOS. Suite предстоит создать по плану. Реальные TIS/AX
  проверки AC01–18 выполняются отдельно в интерактивной macOS-сессии;
  текущего готового runner для них нет, команда не выдумывается.
- Допустимая изоляция: только внешние системные границы ввода, фокуса и текста
  для управляемых отказов/задержек. Internal helpers не мокать; приватные flags,
  очереди и счётчики не считать пользовательским результатом. Изолированные
  проверки не заменяют реальную macOS-проверку фокуса и AX.

## P3 — документация и итоговая проверка

`verdict: TDD_NOT_APPLICABLE_APPROVED`, `applicability: not-applicable` — только
для нового RED документационной части P3. Фаза не добавляет поведение; его RED
принадлежит P1/P2. Это не освобождение от TDD evidence предыдущих фаз, QA,
review, macOS acceptance или dependency P1/P2.

`first_red_test: not-applicable — documentation-only change`.
`required_commands.red: not-applicable`.
`required_commands.green`: `git diff --check`,
`python3 scripts/test-layout-converter.py`, `bash -n scripts/package-macos.sh`,
`swift build`, `swift test`; плюс актуальная macOS acceptance матрица и проверка
соответствия README реальному поведению. Недоступные команды остаются pending.

## Минимальное снятие blocker

**P1 env blocker снят** фактическим выполнением Swift XCTest probe.
Разрешён developer handoff только P1 с подготовкой поверхности, baseline и
обязательным поведенческим RED до фикса. Product tests пока не выполнялись;
TDD evidence, QA и macOS build не объявляются пройденными.

Для **P2** требуется выполненная P1 и доступная macOS-среда с Swift, где можно
получить RED/GREEN производственных команд; для runtime evidence нужна
интерактивная сессия с разрешениями, источниками и полями ввода. Доступная
сборка pkg без этих проверок недостаточна для закрытия полного evidence.

Если такая среда недоступна, нельзя молча заменить RED чтением кода, Python
или обещанием тестов позже. Вернуть coordinator организационный blocker;
не переписывать утверждённый контракт и не объявлять downstream gates пройденными.

Открытые продуктовые вопросы: нет. Остаточный технический риск: возможность
надёжного AX readback и отмены в конкретных редакторах доказывается исполнением,
не данным strategy. Отчёт не меняет Phase Plan, код или статусы QA/reviewer.
