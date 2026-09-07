# Current security review — repair refresh

2026-09-07 13:20 UTC. Binding: проверенный p2-final-sha256 manifest текущего
TDD report. **Full security/native readiness blocked по отсутствию runtime;
source review не выявил открытых подтверждённых уязвимостей.**
S1/R1 cancellation устранён, подтверждён regression. R2 исправлен отдельным
manual snapshot без чтения текста; это не обход Accessibility guard в entrypoint
и не ослабление строгой проверки editable AX conversion.

Проверены обновлённые release двух видов snapshot, weak observer ownership,
отсутствие логирования text и clipboard/network side effects. 28 core tests
pass не доказывают поведение secure fields или native callback lifetime.
Native typecheck, отказ разрешения, чужой context и actual AX readback остаются
обязательными проверками. Owner coordinator/macOS QA, критерий 0 записей чужому
окну и 0 ложных успехов. Readiness 🟡 6/10; final launch approval не выдан.
Ниже история предыдущих source findings; S1 и R2 не остаются открытыми bugs.

---

# Security review refresh — cancellation repair

2026-09-07 13:18 UTC. Binding: evidence/p2-final-sha256.txt, все hashes сверены.
**Current verdict: blocked только для full native/security readiness.**
Source-only review: новых доказанных уязвимостей не обнаружено; S1/R1 закрыт
core regression RED/GREEN и Task.cancel guard в native contextIsCurrent.
27-test независимый GREEN подтверждает core, не macOS API безопасность.

R2 из review.md — избыточное ограничение доступности manual команды, а не
обход разрешений или утечка. При repair не переносить ослабленные manual
requirements на conversion: snapshot element/value/range и проверки перед
записью должны сохраняться. Проверка чужого контекста остаётся обязательной.

Source data handling по текущему diff остаётся локальным: нет clipboard
использования, сети или пользовательского текста в логах; snapshot временный,
focus observer освобождается с context. AX callbacks и refcon lifetime,
secure fields, focus/range race и actor/native compilation требуют реального
macOS исполнения. Security readiness 🟡 6/10; validation owner coordinator,
0 writes в чужой context и 0 ложных успехов. Full pass не выдан.

Ниже первоначальный security report для истории; его S1 устранён repair,
остальные native evidence gaps остаются действующими.

---

# Security feature review — AX conversion and source switching

2026-09-07. Security Feature Reviewer, отдельный read-only отчёт coordinator.
Объект: текущая native/core реализация Task system-layout-sync, plan rev2;
точные revision/source hashes в review.md этого прохода. Cross-engine не заявлен.

**Verdict: blocked для полной native readiness; source review — существенной
новой уязвимости утечки/удалённого выполнения не выявлено.** Security readiness
6/10 🟡, severity summary medium (local input integrity, missing native evidence).
Рекомендация: продолжать исправление и native validation, не финальный запуск;
decision rating 70/100. Консенсус несколькими экспертами не заявляется.

## Данные, разрешения, границы

- Читаются selected text и полный AX value исходного поля, PID/window/element,
  range и input source IDs. Snapshot хранит original/expected value в памяти
  только на время операции (`MacInputEnvironment.swift:16`–27, 124–155).
- Accessibility guard находится на обеих пользовательских командах
  (`main.swift:544`–551). Отказ не обходит системное разрешение. Новые разрешения,
  сеть, загрузки, webhooks, аккаунты, платежи и shell с пользовательским текстом
  не добавлены; web-классы IDOR/XSS/CSRF/SSRF здесь неприменимы.
- Изменяется selectedText конкретного AX element после проверки старых value и
  range (`MacInputEnvironment.swift:146`–157), затем caret. Нет blind clipboard
  fallback; clipboard не затрагивается. Размер range проверяется до substring.
- Source ID проверяется среди доступных системных источников; внешние строки
  не используются для файловых путей или команд. Source switching не хранит
  per-window history.
- releaseContext удаляет snapshot/runloop source (`104`–107); core defer
  срабатывает и на ранних выходах. FocusWatch держит environment weak; в просмотре
  не обнаружено явного retain cycle, постоянно удерживающего пользовательский текст.
- Event callbacks сохраняют timestamp/поколение, не characters. Пользовательский
  текст не логируется; добавление подробного текстового audit log не требуется
  и увеличило бы риск. Status/tooltip не содержат сам текст выделения.

## Findings и обязательные проверки

S1 / medium, integrity: cancellation-path R1 из review.md допускает caret
mutation после Task.cancel, поскольку verifier имеет side effect. Нет evidence
удалённой эксплуатации или privilege escalation; это локальная целостность
пользовательского ввода. Owner developer, P1: guard/разделение verification и
mutation, regression RED/GREEN; не публиковать до affected review.

S2 / evidence gap: macOS native typecheck, разрешения AX, secure/unsupported
fields, межоконные race и notifications не выполнены. Нельзя утверждать, что
реальные парольные/чувствительные поля доступны или недоступны по одной модели.
Проверить корректный отказ unsupported поля без записи, отсутствие мутаций
другого окна при смене фокуса, очистку snapshot при отказе/timeout/cancel.
Owner coordinator macOS QA; validation: 0 writes чужому контексту, 0 ложных
успехов, 0 оставленного snapshot после завершения.

Полный value поля временно читается для readback, что шире одного выделения.
Это предусмотрено approved plan; scope разрешён, но privacy описание должно
оставаться точным: память процесса, никакой отправки и журналирования.

## Side effects

Положительно: исчезает копирование текста в общий clipboard, уменьшается
случайное раскрытие через clipboard managers. Цена: требуется AX value/readback,
часть редакторов станет unsupported. Риск: временный full-field текст и
адресные записи требуют правильных focus/selection guards. Меры: ограниченная
жизнь snapshot, нет текстовых логов, native negative matrix. Публикация,
системные настройки и secrets в этом review не менялись.
