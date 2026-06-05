Codex Project Adapter

## Общая Агентская Команда

Стабильный ID общей агентской команды: `fl-product-agent-team`.

Во всех проектных инструкциях ссылка на общую агентскую команду должна идти
через ID `fl-product-agent-team`. Локальный путь ниже является только текущим
разрешением этого ID в workspace относительно корня `LangConvert`:

`../Fl-product-agent-team/SKILL.md`

Если на текущей машине доступен `fl-product-agent-team`, используй его как
внешний источник истины для Developer Team, Expert Team, product pipeline,
ролей, gates, общего поведения и визуализации runtime-ролей внешней команды.

Локальные копии команды `fl-product-agent-team`, профили ролей, общие правила,
instruction-файлы и pipeline-файлы в этом репозитории не являются источником
истины и не должны создаваться заново. В `LangConvert` остается только этот
project adapter и локальные правила проекта ниже.

`fl-product-agent-team` не является зависимостью приложения, pnpm-пакетом,
git submodule, install step, build step или CI requirement. Его наличие
требуется только для агентского workflow в среде, где он доступен.

Если `fl-product-agent-team` недоступен на машине другого разработчика, это не
должно блокировать обычную работу с репозиторием `LangConvert`: `git clone`,
установку зависимостей проекта, разработку, lint, test и build. В таком режиме
применяй только project-specific rules из этого файла.

## Жесткое Правило Доступности

1. Если доступен ID общей агентской команды `fl-product-agent-team`, используй его:
   `../Fl-product-agent-team/SKILL.md`.
2. Если `fl-product-agent-team` доступен в текущем агентском окружении, все задачи, которые требуют product pipeline, scope, планирования, разработки, review, QA, docs, handoff или экспертного анализа, обязательно выполняются через `fl-product-agent-team`.
3. Нельзя обходить доступный `fl-product-agent-team` из-за того, что локальные правила проекта уже описаны в этом файле. Локальные правила дополняют pipeline, а не заменяют его.
4. Если задача адресована Developer Team или Expert Team, но `fl-product-agent-team` недоступен, сначала явно сообщи пользователю фразу `внешние агенты не доступны`, затем продолжай работу по локальным project-specific rules из этого adapter без блокировки задачи.
5. Если `fl-product-agent-team` недоступен, обычная работа над проектом должна оставаться разблокированной. Отсутствие `fl-product-agent-team` не должно ломать install/build/test/lint, верстку, простые продуктовые правки или работу других участников проекта.
6. `fl-product-agent-team` является optional agent workflow source, а не зависимостью продукта. Не добавляй его как submodule, зависимость менеджера пакетов, install hook, build step, test step или CI requirement.

## Правила Выбора Команды `fl-product-agent-team`

1. `Developer Team` (`team_id: developer-team`) используется для разработки и Product Dev Pipeline: scope, планирование, реализация, фиксы, рефакторинг, тесты, QA, code review, docs update, handoff и подготовка результата.
2. Команды пользователя "разработай", "сделай", "реализуй", "исправь", "пофикси", "добавь", "обнови код", "запланируем", "бери в работу", "сделай scope" и смысловые аналоги про изменение продукта запускают Developer Team через pipeline, если `fl-product-agent-team` доступен. Если он недоступен, сообщи `внешние агенты не доступны` и продолжай по локальным правилам.
3. `Expert Team` (`team_id: expert-team`) используется для экспертного анализа без разработки: "анализируй", "сделай анализ", "оцени", "проведи экспертную оценку", "разбери фичу/блок/страницу/модуль/flow/документ" и смысловые аналоги.
4. Внутренние группы Expert Team:
   - `@project-experts` - анализ проекта целиком, стратегии, рынка, экономики, юридической устойчивости, операций, безопасности и системных рисков;
   - `@business-block-experts` - анализ отдельного бизнес-блока: монетизация, продажи, маркетинг, поддержка, операции, бухгалтерия, юридическая модель, аналитика или growth-блок;
   - `@feature-experts` - анализ фичи, страницы, модуля, API, пользовательского flow, релиза, UX/UI, frontend/backend реализации, performance и feature-level рисков.
5. Если пользователь просит анализ, но не указывает группу Expert Team и из контекста нельзя надежно выбрать `@project-experts`, `@business-block-experts` или `@feature-experts`, сначала задай уточняющий вопрос, какую группу вызвать. Если из контекста очевидно, выбирай группу сам и явно назови выбор. Если `fl-product-agent-team` недоступен, сообщи `внешние агенты не доступны` и продолжай анализ по локальным правилам.
6. `pipeline-support` используется только для поддерживающих ролей Product Dev Pipeline (`scribe`, `cross-engine-reviewer`) и не подменяет Developer Team или Expert Team.

## Правила Ответа

1. Отвечай всегда на русском языке.

## Правила Проекта

1. Проект использует Swift Package Manager, Swift, AppKit и macOS-only APIs
   (`AppKit`, `Carbon`, `pkgbuild`, `iconutil`).
2. Перед финальным ответом по изменению кода или документации выполняй доступные проверки.
3. Для markdown/documentation-only изменений минимум: `git diff --check`.
4. Для code changes добавляй релевантные команды проекта:
   `python3 scripts/test-layout-converter.py`, `bash -n scripts/package-macos.sh`,
   `git diff --check` и `swift build`, если в среде доступен Swift toolchain.
5. `build/LangConvert.pkg` не собирается и не обновляется вручную в Linux/Codex
   среде. Актуальный dist-пакет собирается через GitHub Actions workflow
   `.github/workflows/build-native-macos-pkg.yml` на `macos-14`.
6. Для обновления `build/LangConvert.pkg` после code changes нужно запушить
   обычный code commit в `main` или ветку `codex/**` без маркера
   `[skip pkg commit]`. Workflow выполнит `bash scripts/package-macos.sh`,
   загрузит artifact `LangConvert-native-macOS-pkg` и отдельным коммитом
   `Add built macOS pkg [skip pkg commit]` обновит `build/LangConvert.pkg`
   в той же ветке.
7. Не коммить старый `build/LangConvert.pkg` как новый dist, если локальная
   macOS-сборка не выполнялась. Если `git push` заблокирован авторизацией,
   явно сообщи, что code commit готов локально, но dist не может обновиться до
   успешного push и запуска GitHub Actions.
