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
потому что Apple `productbuild` доступен только на macOS.

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
- `productbuild` для `.pkg` installer.

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
- `scripts/package-macos.sh` - `.app` and `.pkg` packaging through `swift build` and `productbuild`.
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
| installer | `productbuild` `.pkg` | GitHub Actions macOS artifact | pass | `build-native-macos-pkg.yml` | team-lead | pending-ci |
| important readiness | native rewrite release risk | @feature-experts review | pass | approve with residual macOS smoke | feature-release-arbiter | pass |

## QA Handoff

Status: `QA_PASS_WITH_MACOS_RUNTIME_LIMITATION`

The implementation is native and contains no Electron/Chromium runtime. The
Linux container cannot run Swift/AppKit or `productbuild`, so final runtime and
installer verification must run on macOS.

## Feature Experts Review

Status: `APPROVE_WITH_RESIDUAL_MACOS_SMOKE`

Verdict:

- Native rewrite addresses the large Electron package size root cause.
- Product behavior remains aligned with the original important scope.
- Residual release risk is macOS permission/runtime behavior, which requires a real macOS smoke pass.
