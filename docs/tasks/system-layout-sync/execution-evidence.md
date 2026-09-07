# Подтверждение задачи и исходные проверки

Дата: 2026-09-07. Автор: GPT Admin, coordinator/team-lead.
Workspace: /workspace/LangConvert, ветка codex/system-layout-sync.
HEAD: 1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55.

Пользователь точным сообщением `approve task` подтвердил task.md:
SHA-256 e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14.
Содержание Task не менялось. Предшествующий approve task brief доступен
в текущем разговоре. Исторические статусы внутри документов не переписаны.

Выбран product-dev-standard по явному пожеланию пользователя «workflow,
стандарт»; переход к TDD acceptance разрешён. Auto не включён.
Standalone compatibility check: STANDALONE INSTRUCTION PACKAGE COMPATIBLE.
Instruction-driven GPT Admin workflow.
CCC Backend guard was not executed.
No canonical CCC transition or approval was created.

## Исходная среда и проверки

- Debian GNU/Linux 12; macOS runtime отсутствует.
- `command -v swift`: executable не найден.
- `swift build`: exit 127, `/bin/bash: line 1: swift: command not found`.
- `python3 scripts/test-layout-converter.py`: exit 0, layout converter tests passed.
- `bash -n scripts/package-macos.sh`: exit 0.
- `git diff --check`: exit 0 (новые untracked документы проверяются отдельно).
- Доступного инструмента удалённого выполнения на macOS в текущем наборе
  инструментов не найдено. Это не утверждение об отсутствии Mac у пользователя.
- Существующий GitHub workflow собирает pkg на macos-14, но не выполняет
  интерактивные проверки фокуса и Accessibility. Публикация не выполнялась.

## Контекст для архитектора

KB docs/context и scripts/knowledge.sh отсутствуют. Alternate retrieval:
`rg --files docs`, поиск `TIS|AXUIElement|convertSelection|switchLocale`
в Sources/LangConvert/main.swift. Открыты actual main.swift, Package.swift,
scripts/test-layout-converter.py, .github/workflows/build-native-macos-pkg.yml,
исторический docs/plans/macos-menu-bar-layout-converter.md.
Candidate KB cards: none. Исторический план не является текущим approval.

Проверенные технические ограничения: conversion возвращает только String;
направление и source ID сейчас не связаны; selected text изменяется через
CGEvent и таймер; текущий источник перед switch не читается. Требуется
проверяемый контракт замены/фокуса перед выбором источника.

Следующее действие: получить TDD acceptance, затем подготовить Phase Plan
и отдельный strategy verdict. Отсутствие Swift/macOS не является поведением RED
и не может выдаваться за упавший regression test.

## Результат текущего прохода

- TDD acceptance: TDD_ACCEPTANCE_TESTS_READY, independent context
  /root/hotkey_diagnostic, tdd-acceptance.md.
- Архитектурный план создан; YAML разобран парсером, все 18 AC покрыты.
  Временный YAML parser установлен только в /tmp/langconvert-plan-validation;
  зависимостей продукта не добавлено.
- TDD strategy: TDD_PHASE_BLOCKED для P1/P2; отдельный отчёт tdd-strategy.md.
  Нет исполнимого RED/GREEN production Swift. P3 имеет исключение только для
  нового RED документации, но зависит от P1/P2.
- Архитектор перенёс фактический strategy blocker в статус плана/P1;
  техническое содержание плана, к которому привязан hash strategy, не изменено.
- Developer, TDD evidence, QA, reviewer и финальный gate не запускались.
- Код, тесты, Package.swift, README, workflow и pkg не менялись.
- Проверена возможность продолжения через Linux toolchain: официально есть
  Swift для Debian 12 (https://www.swift.org/install/linux/debian/12/).
  Установка не выполнялась; свободно 4.3 GiB на разделе, macOS этим не появляется.
  Минимальный следующий шаг — предоставить исполнимый Swift runner для P1
  и повторить strategy; для P2 требуется macOS execution.

## Продолжение: Swift runner доступен

Пользователь попросил продолжить; task hash и ветка не менялись.
Swift 5.10.1 скачан по официальной ссылке Swift.org для Debian 12 и распакован
в /tmp/langconvert-swift. Недостающие Debian библиотеки/headers/linker распакованы
там же в sysroot без изменения системных пакетов и зависимостей приложения.
Команда `. /tmp/langconvert-swift/env.sh; swift test --package-path
/tmp/langconvert-swift/probe --sdk /tmp/langconvert-swift/sysroot` завершилась
exit 0: XCTest 1 test, 0 failures. Это проверка runner, не продуктовый GREEN.

Запрошен повторный strategy P1. Для P2 macOS всё ещё недоступен.
Поступившая команда auto не прошла admission: текущий sandbox danger-full-access,
а AUTO_MODE требует workspace-write. Goal не создан; продолжается прежняя
разрешённая работа, без автоматической публикации/merge.
