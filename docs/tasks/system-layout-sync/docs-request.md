# Docs Task Request

Owner/requester: GPT Admin / Developer Team team-lead.
Reason: docs_maintenance — актуализировать описание утверждённого поведения,
не объявляя непроверенную native реализацию готовой к выпуску.
Task: system-layout-sync; repo/worktree: /workspace/LangConvert;
branch: codex/system-layout-sync; parent: main.
Approved intent: task.md, SHA256 e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14.
Implementation snapshot: evidence/p2-final-sha256.txt (рабочие файлы, не релиз).
Targets: README.md, docs/context/input-source-operations.md, macos-validation.md.
KB: docs/context этого репозитория; feature: input-source-operations.
Surfaces: Package.swift, Sources/LangConvertCore/*.swift,
Sources/LangConvert/main.swift, Sources/LangConvert/MacInputEnvironment.swift,
Tests/LangConvertCoreTests/*.swift, .github/workflows/build-native-macos-pkg.yml.
Queries: «Системная раскладка после смены фокуса»;
«Язык после конвертации последнего символа»;
«Отмена замены текста и частичный результат».
Expected sync: PENDING допустим для локального handoff; tooling knowledge.sh
в проекте отсутствует. Финальный knowledge gate не объявлять пройденным.
