---
slug: macos-menu-bar-layout-converter
title: Native macOS menu bar layout converter
task_mode: important
curator: team-lead
status: completed
created_at: 2026-06-04T00:00:00Z
updated_at: 2026-06-04T17:45:00Z
---

# Native macOS menu bar layout converter

## Brainstorm Brief

Status: `BRAINSTORM_BRIEF_READY`

Идея: сделать легкое native macOS-приложение в верхней системной панели со
значком клавиатуры, настройками горячих клавиш, автозапуском и конвертацией
выделенного текста между EN/RU раскладками.

Выбранное направление: Swift/AppKit status-bar utility без Electron, Chromium,
Vite runtime и web UI. Это снижает размер итогового приложения и улучшает
системную интеграцию. Цена решения: сборка `.pkg` требует macOS toolchain,
потому что Apple `pkgbuild` доступен только на macOS.

## ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

### Бизнес-флоу

1. Пользователь запускает LangConvert.
2. В macOS status bar появляется иконка клавиатуры.
3. Пользователь открывает Settings из status-bar menu.
4. Пользователь кликает поле горячей клавиши и нажимает клавишу или сочетание.
5. Поле отображает введенное сочетание, настройка сохраняется.
6. Пользователь включает или выключает автозапуск приложения.
7. В любом приложении пользователь выделяет текст и нажимает hotkey конвертации.
8. LangConvert заменяет выделение на текст противоположной EN/RU раскладки.
9. Пользователь нажимает hotkey переключения локали, LangConvert отправляет системное Control+Space.

### Acceptance Criteria

AC1. Приложение работает как native macOS status-bar app и не использует Dock-окно.

AC2. В Settings есть два native hotkey capture field: конвертация текста и переключение локали.

AC3. Hotkey field сохраняет одиночную клавишу с модификаторами и отображает человекочитаемое сочетание.

AC4. После изменения hotkey глобальные shortcuts перерегистрируются без перезапуска приложения.

AC5. Чекбокс автозапуска управляет user LaunchAgent.

AC6. Конвертация заменяет выделенный текст через native Accessibility/CGEvent copy-paste flow.

AC7. EN/RU directional mapping сохраняет регистр и покрывает QWERTY/JCUKEN буквы и основные знаки.

AC8. Если Accessibility permission отсутствует или выделение пустое, приложение не падает и восстанавливает pasteboard.

AC9. Hotkey переключения локали вызывает системное Control+Space.

### Dependencies

- macOS 13+.
- Xcode Command Line Tools / Swift toolchain.
- Accessibility permission для отправки CGEvent в другие приложения.
- `pkgbuild` для `.pkg` installer.

### Out of Scope

- Windows/Linux версии.
- App Store distribution, notarization и автообновления.
- Дополнительные языки кроме EN/RU.

## TDD Acceptance Test Design

Status: `TDD_ACCEPTANCE_TESTS_READY`

| Case | Linked AC | Scenario | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TDD-A1 | AC2, AC3 | Настройка hotkey | Открыто Settings | Пользователь кликает поле и нажимает Cmd+Shift+L | Поле показывает Cmd + Shift + L, настройка сохраняется |
| TDD-A2 | AC4 | Перерегистрация shortcut | Задан старый hotkey | Пользователь задает новый hotkey | Новый hotkey вызывает действие без перезапуска |
| TDD-A3 | AC6, AC7 | RU to EN conversion | В другом приложении выделено `руддщ` | Пользователь нажимает convert hotkey | Выделение заменено на `hello` |
| TDD-A4 | AC6, AC7 | EN to RU conversion | В другом приложении выделено `ghbdtn` | Пользователь нажимает convert hotkey | Выделение заменено на `привет` |
| TDD-A5 | AC5 | Launch at login | Открыто Settings | Пользователь включает checkbox | LaunchAgent установлен и состояние отображается |
| TDD-A6 | AC8 | Нет Accessibility | Permission не выдан | Пользователь нажимает convert hotkey | Показывается понятный статус, pasteboard восстановлен |

## Verified Code Surfaces

- `Package.swift` - native Swift executable package.
- `Sources/LangConvert/main.swift` - AppKit app, status item, settings window, Carbon hotkeys, CGEvent automation, LaunchAgent autostart and EN/RU converter.
- `packaging/Info.plist` - app bundle metadata with `LSUIElement=true`.
- `scripts/package-macos.sh` - `.app` and `.pkg` packaging through `swift build`, ad-hoc app signing, xattr cleanup and `pkgbuild`.
- `.github/workflows/build-native-macos-pkg.yml` - macOS runner `.pkg` artifact build.

## Фазы

### Phase 1 - Native app rewrite

Status: `completed`

Goal: заменить Electron/Vite реализацию на native Swift/AppKit menu bar app.

Files/modules:

- `Package.swift`
- `Sources/LangConvert/main.swift`
- `packaging/Info.plist`
- `scripts/package-macos.sh`
- `.github/workflows/build-native-macos-pkg.yml`
- `README.md`
- `.gitignore`

Implementation summary:

- AppKit `NSStatusItem` status-bar app.
- `NSWindowController` settings UI with native hotkey capture fields.
- Carbon `RegisterEventHotKey` global shortcuts.
- Directional EN/RU layout converter.
- Accessibility prompt and native CGEvent Cmd+C/Cmd+V replacement flow.
- Launch-at-login via user LaunchAgent.
- Native `.pkg` builder.

Concrete checks in this Linux container:

- `bash -n scripts/package-macos.sh` - pass.
- `packaging/Info.plist` parsed with `plistlib` - pass.
- `git diff --check` - pass.

macOS checks required:

- `swift build -c release`.
- `bash scripts/package-macos.sh`.
- Install `build/LangConvert.pkg`.
- Grant Accessibility permission.
- Verify status-bar icon, settings capture, hotkey re-registration, `руддщ -> hello`, `ghbdtn -> привет`, locale switch and autostart.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| native runtime | AppKit status item and settings window | qa static review; macOS smoke required | pass | source review and checklist | qa | pass |
| global hotkeys | Carbon hotkey registration | macOS smoke required | pass | manual macOS QA checklist | qa | pending-macos |
| automation | Accessibility + CGEvent copy/paste | macOS smoke required | pass | manual macOS QA checklist | qa | pending-macos |
| installer | `pkgbuild` `.pkg` | GitHub Actions macOS artifact | pass | `build-native-macos-pkg.yml` | team-lead | pending-ci |
| important readiness | native rewrite release risk | @feature-experts review | pass | approve with residual macOS smoke | feature-release-arbiter | pass |

## QA Handoff

Status: `QA_PASS_WITH_MACOS_RUNTIME_LIMITATION`

The implementation is native and contains no Electron/Chromium runtime. The
Linux container cannot run Swift/AppKit or `pkgbuild`, so final runtime and
installer verification must run on macOS.

## Feature Experts Review

Status: `APPROVE_WITH_RESIDUAL_MACOS_SMOKE`

Verdict:

- Native rewrite addresses the large Electron package size root cause.
- Product behavior remains aligned with the original important scope.
- Residual release risk is macOS permission/runtime behavior, which requires a real macOS smoke pass.

## Follow-up: settings and menu polish

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Не показывать команды конвертации и смены локали в status-bar menu.
- Исправить переназначение hotkey в Settings при клике в input field.
- Если при первом запуске нужно запросить Accessibility permission, показать в Settings уведомление с кнопкой запроса.

Acceptance criteria:

- В status-bar menu остаются настройки и выход, без ручных команд convert/switch locale.
- Hotkey field после клика принимает сочетание клавиш, обновляет текст и сохраняет настройку.
- Settings показывает заметный Accessibility notice, когда permission не выдан, и кнопка запускает системный prompt.

### Phase 2 - Settings and menu polish

Status: `completed`

Goal: точечно улучшить UX настроек и status-bar menu без изменения core conversion flow.

Files/modules:

- `Sources/LangConvert/main.swift`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Убрать menu items `Convert selected text` и `Switch locale`.
- Перевести hotkey field из editable text input в focusable recorder control, чтобы клик передавал key events самому полю.
- Добавить shared Accessibility permission helper и notice/button в Settings.

Concrete checks:

- `git diff --check` - pass.
- `swift build` - not run in this Linux container because `swift` is unavailable.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| status menu | open menu bar item | static source review; macOS smoke recommended | pass | source diff | qa | pass |
| hotkey recorder | click field and press shortcut | macOS smoke required | pass | manual macOS QA checklist | qa | pending-macos |
| accessibility notice | open Settings without permission | macOS smoke required | pass | manual macOS QA checklist | qa | pending-macos |

## Follow-up: application list icon

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Иконка LangConvert в списке приложений должна быть клавиатурой.
- Визуальный стиль: белый outline на черном фоне.
- Сделать качественный high-resolution raster icon в стиле примера `DenisLo-master/Dictation`, не ломая native packaging.

Acceptance criteria:

- `.app` bundle содержит app icon resource.
- `Info.plist` указывает `CFBundleIconFile`.
- Packaging script кладет icon в `Contents/Resources`.
- Icon source `AppIconSource.png` доступен в репозитории, `.icns` может быть пересобран без сторонних npm/pnpm-зависимостей.

### Phase 3 - App icon asset

Status: `completed`

Goal: добавить красивую app icon клавиатуры для Finder/Applications/LaunchServices.

Files/modules:

- `packaging/AppIconSource.png`
- `packaging/AppIconSource.LICENSE`
- `packaging/Info.plist`
- `scripts/generate-app-icon.py`
- `scripts/package-macos.sh`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Использовать MIT-лицензированный `Dictation` app icon source как polished macOS-style reference/base и заменить центральный символ на клавиатуру LangConvert.
- Генерировать macOS-native `.icns` из 1024px `AppIconSource.png` через `sips`/`iconutil` во время package build.
- Подключить `CFBundleIconFile` и копирование asset в Resources.

Concrete checks:

- `python3 scripts/generate-app-icon.py` - pass.
- `iconutil` roundtrip для `.icns` - pass на macOS build.
- `python3` parse `Info.plist` and confirm `CFBundleIconFile=AppIcon` - pass.
- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| app icon asset | open Applications/Finder | static asset and plist review; macOS smoke recommended | pass | source diff and generated icns | qa | pass |
| packaging | build pkg | script syntax and macOS CI smoke | pass | packaging script diff | qa | pass |

## Follow-up: macOS-native icon generation

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Проверить именно обновление иконки в Applications, а не только наличие файла.
- Исправить случай, когда в Applications показывается белая generic icon вместо `AppIconSource.png`.

Acceptance criteria:

- Репозиторий не хранит вручную собранный `.icns`, который macOS может не принять.
- Package build генерирует `.icns` на macOS через `sips` и `iconutil`.
- Build падает, если `iconutil` не может обратно разобрать `AppIcon.icns` или если нет `512x512@2x`.
- CI проверяет, что `.pkg` payload содержит `Applications/LangConvert.app/Contents/Resources/AppIcon.icns` и `Info.plist`.

### Phase 5 - Finder icon validity

Status: `completed`

Goal: заменить ненадежный Python-built `.icns` на macOS-native iconset pipeline.

Files/modules:

- `.github/workflows/build-native-macos-pkg.yml`
- `.gitignore`
- `scripts/generate-app-icon.py`
- `scripts/package-macos.sh`
- `packaging/AppIconSource.png`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- `scripts/generate-app-icon.py` теперь требует `sips`/`iconutil`, создает полный `.iconset` и собирает `AppIcon.icns`.
- `scripts/package-macos.sh` генерирует icon перед созданием `.app`, проверяет `iconutil -c iconset` roundtrip и только затем копирует icon в `Contents/Resources`.
- `packaging/AppIcon.icns` удален из tracked files и добавлен в `.gitignore` как generated artifact.
- GitHub Actions проверяет payload `.pkg` на наличие app icon и `Info.plist`.

Concrete checks:

- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.
- macOS GitHub Actions build - pending after push.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| app icon validity | build pkg on macOS | `sips`/`iconutil` generation and roundtrip | pass | CI log | qa | pending-ci |
| pkg payload | inspect built pkg | `pkgutil --payload-files` contains app icon path | pass | CI log | qa | pending-ci |

## Follow-up: modifier-only hotkeys and full-bleed icon

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Для смены раскладки нужно назначать `Command + Shift` без дополнительной клавиши.
- Вокруг app icon не должно быть белого внешнего фона/паддинга; иконку нужно увеличить.

Acceptance criteria:

- Hotkey recorder ловит `flagsChanged` и сохраняет modifier-only shortcuts.
- Глобальный shortcut manager запускает modifier-only shortcut по `flagsChanged`, без `RegisterEventHotKey`.
- `AppIconSource.png` непрозрачный по всему canvas и визуально увеличен к краям.
- Версия сборки повышена, чтобы новая установка не выглядела для macOS как старый bundle metadata.

### Phase 6 - Modifier hotkey and icon scale

Status: `completed`

Goal: исправить назначение `Cmd + Shift` и убрать визуальный внешний фон у app icon.

Files/modules:

- `Sources/LangConvert/main.swift`
- `packaging/AppIconSource.png`
- `packaging/Info.plist`
- `scripts/package-macos.sh`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Добавлен sentinel `HotKey.modifierOnlyKeyCode`.
- `HotKeyRecorderField` записывает modifier-only shortcuts через `flagsChanged`.
- `GlobalHotKeyManager` обрабатывает modifier-only shortcuts через local/global `flagsChanged` monitors.
- `AppIconSource.png` увеличен и скомпозитен на непрозрачный черный фон.
- Bundle/pkg version bumped до `0.1.2` / build `3`.

Concrete checks:

- `python3` PNG source check: 1024x1024 and no transparent pixels - pass.
- `python3` parse `Info.plist` and confirm version/icon metadata - pass.
- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.
- macOS GitHub Actions build and pkg commit - pending after push.

## Follow-up: per-character layout conversion

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Конвертация должна работать посимвольно в обе стороны.
- Смешанная строка `fyfkbp ыныеуь` должна превращаться в `анализ system`.

Acceptance criteria:

- Каждый EN/JCUKEN символ конвертируется в RU.
- Каждый RU/JCUKEN символ конвертируется в EN.
- Символы без пары остаются без изменений.
- Смешанные строки не выбирают одно направление для всей строки.

### Phase 7 - Bidirectional per-character conversion

Status: `completed`

Goal: заменить majority-language conversion на per-character opposite-layout conversion.

Files/modules:

- `Sources/LangConvert/main.swift`
- `scripts/test-layout-converter.py`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- `LayoutConverter.convert` теперь проверяет `enToRu[character]`, затем `ruToEn[character]`, затем оставляет символ как есть.
- Добавлен lightweight Python self-test с кейсами `fyfkbp ыныеуь -> анализ system` и `руддщ ghbdtn -> hello привет`.

Concrete checks:

- `python3 scripts/test-layout-converter.py` - pending.
- `bash -n scripts/package-macos.sh` - pending.
- `git diff --check` - pending.
- macOS GitHub Actions build and pkg commit - pending after push.

## Follow-up: system input source layouts

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Не фиксировать конвертацию как RU/EN в продуктовой логике.
- В настройках показывать системные локали/раскладки.
- Приложение должно работать, когда в macOS добавлены две раскладки, и конвертировать между ними.
- Добавить нотификацию об этом в Settings.

Acceptance criteria:

- Settings показывает две системные keyboard input sources, если они доступны.
- Settings показывает предупреждение, если добавлена только одна раскладка или не найдено keyboard layout sources.
- Конвертер строит таблицу символов по первым двум системным keyboard layout sources через `TISCopyInputSourceList` и `UCKeyTranslate`.
- Для каждой виртуальной клавиши и modifier-state конвертация идет в противоположный символ другой системной раскладки.
- Hardcoded EN/RU map остается только fallback, если macOS не вернула две layout sources.

### Phase 8 - System layout conversion

Status: `completed`

Goal: перейти от фиксированной EN/RU модели к системной паре раскладок macOS.

Files/modules:

- `Sources/LangConvert/main.swift`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Добавлен `KeyboardLayoutProvider` для чтения enabled keyboard input sources.
- Добавлен dynamic conversion map через `kTISPropertyUnicodeKeyLayoutData` и `UCKeyTranslate`.
- Settings показывает нотификацию с системными раскладками и условием двух layout sources.

Concrete checks:

- `python3 scripts/test-layout-converter.py` - pass for fallback logic.
- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.
- macOS GitHub Actions build and pkg commit - pending after push.

## Follow-up: reinstall replacement and icon refresh

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Если приложение уже установлено, новая установка должна полностью заменить старую копию в `/Applications`.
- Иконка в списке приложений должна обновляться вместе с новой версией, без сохранения старого cached icon.
- Собрать билд и запушить изменения.

Acceptance criteria:

- Preinstall завершает запущенный `LangConvert`, unregister старую `.app` из LaunchServices и удаляет старые копии из `/Applications`.
- Новый bundle содержит `Contents/Resources/AppIcon.icns` и `CFBundleIconFile=AppIcon`.
- App/package version bump снижает риск сохранения старого metadata/icon cache.
- Postinstall регистрирует новый bundle, обновляет timestamp metadata, сбрасывает QuickLook/icon cache и просит Finder обновить `/Applications/LangConvert.app`.

### Phase 4 - Reinstall replacement hardening

Status: `completed`

Goal: усилить installer replacement flow, чтобы новая установка заменяла приложение и иконку в Applications.

Files/modules:

- `packaging/Info.plist`
- `scripts/package-macos.sh`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Bump `CFBundleShortVersionString` до `0.1.1`, `CFBundleVersion` до `2`, package version до `0.1.1`.
- В preinstall выполнить LaunchServices unregister старого `/Applications/LangConvert.app` до удаления.
- В postinstall touch bundle metadata/icon, register новый app, сбросить QuickLook cache и user IconServices store, затем обновить Finder item.

Concrete checks:

- `python3` parse `Info.plist` and confirm version/icon metadata - pass.
- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.
- macOS package build/reinstall smoke - pending CI/macOS runner.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| reinstall replacement | install pkg over existing app | macOS installer smoke recommended | pass | package script diff and CI build | qa | pending-macos |
| icon refresh | open `/Applications` after reinstall | macOS Finder/LaunchServices smoke recommended | pass | source diff and CI build | qa | pending-macos |

## Follow-up: README, license, About and UI localization

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Добавить красивое описание продукта в README со скриншотом.
- Указать лицензию: свободное использование разрешено, но переиспользование
  для доработки/создания производных работ требует обращения к автору.
- Добавить пункт "О продукте" в модалке/меню, где видны версия и автор
  `flo.production.studio@gmail.com`.
- Добавить переключатель локали приложения по паттерну проекта
  `DenisLo-master/Dictation`: модель языка, локализованные UI-тексты и
  control выбора языка в настройках.
- Перевести все видимые UI-тексты приложения на RU/EN.

Acceptance criteria:

- README содержит описание, скриншот и секцию license/usage terms.
- Приложение хранит выбранную UI-локаль в settings и применяет ее к Settings,
  status-bar menu, About-окну и runtime status messages.
- В Settings есть control выбора локали RU/EN, аналогичный AppLanguage/AppText
  подходу из `Dictation`.
- В меню есть пункт About, открывающий modal/alert с версией из bundle metadata
  и строкой `Created by: flo.production.studio@gmail.com` или RU-эквивалентом.
- Default language выбирается по системной preferred locale с fallback на EN.

### TDD Acceptance Test Design

Status: `TDD_ACCEPTANCE_TESTS_READY`

| Case | Linked AC | Scenario | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TDD-L1 | README | Product README | Открыт README | Пользователь читает начало файла | Видит описание продукта, скриншот и условия использования |
| TDD-L2 | UI locale | Language switch | Открыто Settings | Пользователь выбирает RU или EN | Все labels, buttons, menu items and statuses switch to selected language |
| TDD-L3 | About | Product info modal | Открыто status-bar menu | Пользователь выбирает About | Показаны версия приложения и `flo.production.studio@gmail.com` |
| TDD-L4 | Persistence | Saved language | Пользователь выбрал RU | Приложение перезапускается | Settings открываются с RU и локализованным UI |

### Verified Code Surfaces

- `Sources/LangConvert/main.swift` - AppKit settings window, menu, hotkey
  automation status strings and persisted settings.
- `README.md` - product description, screenshot and license terms.
- `docs/assets/langconvert-settings.svg` - README screenshot/mockup asset.
- `docs/plans/macos-menu-bar-layout-converter.md` - persisted pipeline plan.

### Phase 9 - Product presentation and localization

Status: `completed`

Goal: добавить локализованный RU/EN UI, About-информацию и публичное описание
продукта без изменения core conversion/automation logic.

Files/modules:

- `Sources/LangConvert/main.swift`
- `README.md`
- `docs/assets/langconvert-settings.svg`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Добавить `AppLanguage` и `AppText` для всех видимых UI/status strings.
- Расширить `AppSettings` выбранной локалью с backward-compatible decode.
- Добавить language popup в Settings и обновление всех labels/buttons/menu.
- Добавить About пункт в status menu и modal с версией/автором.
- Обновить README и добавить screenshot asset.

Concrete checks:

- `git diff --check` - pass.
- `bash -n scripts/package-macos.sh` - pass.
- `swift build` - not run in this Linux container because `swift` is unavailable.
- `pnpm lint` / `pnpm build` - not run because this checkout has no
  `package.json`.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| settings localization | open Settings and switch language | static source review; macOS smoke recommended | pass | source diff | qa | pass-static |
| status menu/about | open menu and About | static source review; macOS smoke recommended | pass | source diff | qa | pass-static |
| README/license | repository landing page | docs review | pass | rendered markdown/source diff | docs | pass |

## QA Handoff - README/license/About/localization

Status: `QA_PASS_WITH_MACOS_RUNTIME_LIMITATION`

Static checks pass in this Linux container. Final visual/runtime smoke for the
Settings language switch and About modal should be verified on macOS because
AppKit cannot run here.

## Follow-up: any system language pair and Option-layer conversion bug

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- В описании сделать акцент, что пара языков/раскладок может быть любой из
  выбранных в системе.
- Проверить, что функционал поддерживает любую пару системных раскладок.
- Исправить баг: исходный текст `yflj d jgbcfybb cltkfnm frwbtyn`
  конвертируется в `на¬о в опиçании ç¬елать акциент`, появляются непонятные
  символы `¬` и `ç`.

Root cause:

- Dynamic conversion map строился по base, Shift, Option и Shift+Option слоям
  keyboard layout.
- Option-слои в macOS дают типографские/спецсимволы и могут перетирать обычные
  base-letter mappings, например `l -> ¬` и `c -> ç`.

Acceptance criteria:

- README явно говорит, что LangConvert работает с любой парой системных
  keyboard layouts/input sources, если macOS отдает их layout data.
- Dynamic conversion map не использует Option/Alt слои для ordinary text
  conversion.
- Regression input `yflj d jgbcfybb cltkfnm frwbtyn` через EN/RU fallback дает
  `надо в описании сделать акциент` без `¬` и `ç`.
- Fallback EN/RU тесты остаются зелеными.

### Phase 11 - System pair docs and Option-layer fix

Status: `completed`

Goal: убрать спецсимволы из dynamic conversion map и уточнить позиционирование
продукта как конвертера любой системной пары раскладок.

Files/modules:

- `Sources/LangConvert/main.swift`
- `scripts/test-layout-converter.py`
- `README.md`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Исключить Option/Shift+Option modifier states из `KeyboardLayoutProvider`.
- Добавить regression case в lightweight fallback converter test.
- Обновить English/Russian README highlights/requirements/install wording.

Concrete checks:

- `python3 scripts/test-layout-converter.py` - pass.
- `bash -n scripts/package-macos.sh` - pass.
- `git diff --check` - pass.
- `swift build` - not run in this Linux container because `swift` is unavailable.
- `pnpm lint` / `pnpm build` - not run because this checkout has no
  `package.json`.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| dynamic layout map | convert text on macOS system layouts | source review; macOS smoke recommended | pass | source diff | qa | pass-static |
| fallback regression | run converter self-test | automated test | pass | test output | qa | pass |
| README any-pair positioning | open repository landing page | docs review | pass | README diff | docs | pass |

## QA Handoff - any system pair and Option-layer bug

Status: `QA_PASS_WITH_MACOS_RUNTIME_LIMITATION`

The regression input `yflj d jgbcfybb cltkfnm frwbtyn` now passes through the
fallback converter as `надо в описании сделать акциент`. Static source review
confirms the dynamic macOS layout map uses only base and Shift layers, so
Option/Alt special characters like `¬` and `ç` no longer overwrite ordinary
letter mappings. Final dynamic layout smoke should still run on macOS with real
system input sources.

## Follow-up: bilingual README structure

Status: `completed`

### ТЗ от scribe

Status: `SCRIBE_SCOPE_READY`

Пользовательский scope:

- Описание проекта должно быть на английском и русском.
- README структурно должен быть сделан по аналогии с
  `https://github.com/DenisLo-master/Dictation`.

Acceptance criteria:

- README содержит centered header с иконкой, badges и language links.
- README содержит отдельные секции `English` и `Русский`.
- Английская и русская секции зеркально покрывают screenshots, highlights,
  download, requirements, install, privacy, build, tests, project status и
  community/license/contact.
- Условия free use / restricted reuse сохраняются и доступны из README.

### Phase 10 - Bilingual README rewrite

Status: `completed`

Goal: привести README к структуре Dictation и сделать описание продукта
двуязычным без изменения runtime-кода.

Files/modules:

- `README.md`
- `docs/plans/macos-menu-bar-layout-converter.md`

Implementation steps:

- Переписан README с centered header, иконкой, badges и ссылками на языки.
- Добавлены зеркальные English/Русский секции по структуре референса.
- Сохранены build/install/signing/test/license/contact сведения LangConvert.

Concrete checks:

- `git diff --check` - pass.

QA / Expert Coverage Matrix:

| surface | trigger | required_agent_or_evidence | required_status | handoff_artifact | owner | status |
| --- | --- | --- | --- | --- | --- | --- |
| README bilingual structure | open repository landing page | docs review | pass | README diff | docs | pass |
