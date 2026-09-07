# Локальный handoff: реализация подготовлена, native проверка открыта

Owner: GPT Admin / Developer Team team-lead; 2026-09-07.
Task: system-layout-sync. Repo/worktree: /workspace/LangConvert.
Branch: codex/system-layout-sync; parent main; HEAD
1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55. Изменения находятся в рабочем дереве,
не опубликованы и не включены в build/LangConvert.pkg.

## Реализованный контракт

Ручная команда читает фактический TIS источник и выбирает другой источник
существующей пары. Конвертация после проверенной замены выбирает источник
последнего однозначно преобразованного символа. Нет собственной памяти раскладок
окон, синтетического Control + Space или повторного выбора уже активной цели.

Production ядро выделено в LangConvertCore и покрыто Swift tests. Native адаптер
выполняет адресную AX замену с проверкой контекста, readback и положения курсора.
Ручная команда использует отдельный контекст без требования редактируемого поля.
Операции сериализованы, ожидания ограничены, отмена/частичный успех различаются.
Изменены Package.swift, main.swift, README; добавлены core, native adapter,
Swift tests и документация задачи/контракта. Настройки и таблицы конвертации
сохранены. CI, системные настройки и установщик не изменены.

## Точные bindings

Утверждённая Task SHA256:
e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14.
Phase Plan owner pipeline-architect, revision 2, phase-plan.yml SHA256:
e674c19fe466f4672e84855a6498fd2060166e20ffd28f69c24e8476ce5383c6.
Точные SHA256 всех восьми production/test/README/Package файлов:
evidence/p2-final-sha256.txt; независимо сверены reviewer.

## Реальные результаты gates

- Acceptance: tdd-acceptance.md — TDD_ACCEPTANCE_TESTS_READY.
- P1 core strategy/evidence: tdd-strategy.md / tdd-evidence.md — approved
  в своём объёме; native привязка окончательно не проверена.
- P2 core strategy: tdd-strategy-p2.md — TDD_PHASE_READY.
- P2 core evidence: tdd-evidence-p2.md — TDD_EVIDENCE_APPROVED, включая
  реальные RED/GREEN R1 отмены и R2 ручного контекста.
- QA: qa-core.md — 28 tests PASS, native QA blocked.
- Review: review.md — scoped source approve, R1/R2 closed,
  full native approval blocked.
- Security: security-review.md — открытых подтверждённых source findings нет,
  полная native проверка blocked.
- Docs: docs-review.md — описание сверено; KNOWLEDGE_SYNC_PENDING.
- Final architect: полнота approved AC01–18 и scope сохранена; обязательное
  native evidence отсутствует, ARCHITECT_FINAL_APPROVED не выдан.

Независимый исполнитель QA/review/TDD evidence: hotkey_diagnostic в отдельном
контексте от автора реализации, same OpenAI provider. Cross-engine не запрошен,
не required для выбранного Standard; не объявляется выполненным. Полный Expert
Team council не required для Standard; применимые reliability/security покрытия
выполнены этим независимым проходом с указанными ограничениями. Browser/React,
visual/render evidence, legal/payments/AI/analytics — неприменимы к этому diff.

Выполнены swift test (28 pass), swift build (Linux core only), syntax parse
native Swift (не typecheck), python3 scripts/test-layout-converter.py,
bash -n scripts/package-macos.sh, git diff --check, YAML parse и проверка hashes.
Логи: evidence/p2-final.txt, p2-core-build.txt, p2-native-parse.txt,
p2-cancel-red.txt, p2-manual-context-red.txt.

## Документация и ограничения

KB: docs/context. Ранее KB отсутствовала; retrieval выполнялся через rg по
исходникам/README/планам и CI; drift политики пары README исправлен.
Создана input-source-operations.md с surfaces/last_verified. Queries и запрос
владельца — docs-request.md. Индексатор knowledge.sh отсутствует; embeddings
и knowledge gate не выполнены. Это явно PENDING, не вымышленный успешный sync.

macOS сборка/link, TIS источники, AX callbacks/selection/caret и фактическая
совместимость редакторов НЕ проверены. Linux fake не заменяет эту проверку.
Нельзя считать исправление выпущенным или подтверждённым на пользовательском Mac.
Следующий шаг: macOS QA по macos-validation.md на этих исходниках, затем repair
при failures и свежие evidence/review/security/final architect результаты.

phase_plan_status: blocked (native validation; реализация локально подготовлена).
final_gates_status: blocked.
final_rebase_status: not-performed.
deployment_status: not-ready.
branch_push_status: none.
Projection: not-supported, event none; persisted plan — phase-plan.yml,
owner pipeline-architect. Никакого Backend transition/registry не создавалось.

Откат: отменить только перечисленные файлы этой задачи вместе с зависимыми
вызовами; пользовательские настройки и чужие изменения не затрагивать.
Публикация/merge не включены в approved Task и здесь не выполнялись.
