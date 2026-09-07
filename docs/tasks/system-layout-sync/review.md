# Current independent review — repairs closed

2026-09-07 13:20 UTC. Task/plan rev2 прежние; source manifest
`evidence/p2-final-sha256.txt` независимо сверён (8/8 OK), точный hash в
свежем tdd-evidence-p2.md. Independent from implementation author; same provider.

**Verdict: blocked для полного native/final approval. Scoped source review:
approve; открытых подтверждённых code findings этого прохода нет.**
R1 cancellation закрыт guard до verifier и native cancellation guard с реальным
RED/GREEN. R2 manual AX overrestriction закрыт отдельным captureSwitchContext:
`InputOperations.swift:69`, `MacInputEnvironment.swift:89`–96. Strict conversion
capture сохранён (98–123). Native manual identity проверяет PID/optional window,
поколение и отмену (139–149), release удаляет оба вида snapshot (126–129).

Regression R2: compiled RED 2 failures, GREEN; независимый full run 28 pass.
Manual select единственный до первой suspension, повторного выбора после wait
нет. Ослабление editable требований manual не перешло на text replacement.
Timestamp и AX focus observers присутствуют; их native runtime надёжность по
этому просмотру не заявляется. Публичные сообщения и README не обещают устранить
системное восстановление; pending macOS/installer раскрыты.

Остаточные gaps: macOS typecheck/link, реальные AX callbacks/caret/range,
unsupported fields и системная пара. Они являются missing evidence, не новым
доказанным regression. После native проверки требуется свежий финальный review.
Ниже сохранены исторические request_changes; R1 и R2 теперь closed.

---

# Independent review refresh — R1 repaired, R2 found

2026-09-07 13:18 UTC. Standalone compatible; Task/plan rev2 unchanged.
Binding: evidence/p2-final-sha256.txt, 8 hashes OK. Native adapter `9f1fc5ba…`,
core `74074876…`, main `6f6688f3…`. Independent context, same OpenAI provider;
cross-engine не требовался. Source и 27-test GREEN проверены самостоятельно.

**Current verdict: request_changes (R2). R1 закрыт проверенным repair.**
Cancellation guard до verifier и native Task.cancel guard устраняют исходный
R1; реальный RED и свежий GREEN подтверждены отдельным TDD evidence.

## R2 — ручное переключение зависит от возможностей текстового AX capture

Priority P1 / medium. `InputOperations.swift:69` вызывает общий captureContext
для switchSource. `MacInputEnvironment.swift:79`–80 требует focused UI element
и window; строки 94–96 требуют успех обеих AX focus notification registration.
Отсутствие любой возможности возвращает noContext ещё до TIS чтения/выбора.

Сценарий: обычное окно/поле с доступными системными EN/RU, но без поддержки
одного AX notification или focused text element. Ручная команда не переключает
раскладку, хотя text replacement не запрошен. Task AC01/02/17 не ограничивает
manual switch поддержкой редактируемого поля; unsupported-field отказ относится
к конвертации. Это доказанный по коду дополнительный failure path, конкретные
macOS приложения и распространённость требуют runtime проверки.

Minimal repair: разделить lightweight manual context и strict conversion
capture. Manual использует frontmost PID и доступную window identity без
обязательного editable element/обеих AX notification capabilities; conversion
сохраняет строгие проверки. Не ослаблять отмену и не добавлять отложенных retries:
manual select один раз до первого await, дальнейшее ожидание только подтверждает.
Неугадываемое отсутствие самого контекста по-прежнему должно дать отказ.

Required regression: external environment отвергает conversion capture, но
предоставляет manual context; switch выбирает вторую фактическую раскладку,
conversion безопасно отказывает. Получить RED/GREEN и native validation.
Owner developer/architect; текущий reviewer код не менял.

Native build/typecheck/runtime остаются blocked, даже после закрытия R2.
Новых подтверждённых security exploits в этом code pass не найдено.

Ниже исходный review сохранён как история; R1 request_changes superseded repair,
его прежние hashes не являются текущим approval.

---

# Local independent review — P1/P2

2026-09-07. Developer Team / reviewer, independent context from implementation
coordinator. Same provider OpenAI; cross-engine не требовался и не заявляется.
Repo /workspace/LangConvert, branch codex/system-layout-sync, base
1fe815c1fa43b9e8a7c554c37bd2b37b13e0fa55 → рабочее дерево. Task hash
`e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`, plan rev2.
Прочитаны approved Task, plan, source diff, README, собственные scoped QA/TDD
reports; все новые core/native/test файлы включены в обзор, хотя git diff --stat
не показывает untracked файлы. Implementation checks: 24 Swift core tests pass;
macOS typecheck/link/runtime pending.

Snapshot: InputOperations `194cbc98…`; MacInputEnvironment
`d12b837504e7a3d232a14edf143e8ea0a0e14d521d22d866be08c3302fd3933d`;
main.swift `6f6688f33fef5015742edc74c3c2dfe5310fd53dfed03513e53b04a69bfaab36`.

**Verdict: request_changes.** Один конкретный lifecycle gap ниже; полный
native/final approval также blocked отсутствием macOS evidence.

## R1 — cancellation перед verifier с побочным действием

Priority P1 / medium. `Sources/LangConvertCore/InputOperations.swift:46`
вызывает replacementState сразу после async ожидания, прежде проверки
Task.isCancelled. `Sources/LangConvert/MacInputEnvironment.swift:172`–175
показывает, что replacementState не является чистым чтением: меняет selection
на caret. Его contextIsCurrent (116) не проверяет Task cancellation.

Сценарий: replacement pending → waitForSystem → Task отменён → следующий
replacementState видит ожидаемый value и ещё действительный focus → двигает
caret несмотря на отмену. Последующий select уже откажет по isCurrent, но
предшествующий побочный эффект произошёл. Это вывод по коду, не macOS reproduction;
AppDelegate сейчас не предоставляет отдельной кнопки cancel, но production
coordinator заявляет поддержку Task cancellation и используется как async API.

Требуется: cancellation check до side-effectful подтверждения либо отделение
чистого readback от guarded caret action. Сохранить точный результат уже
завершённой замены. Добавить regression test: отмена во время pending ожидания
не вызывает дальнейшей selection mutation; выполнить RED/GREEN.

## Остальные замечания и доказательства

- Timestamp filter игнорирует invoking key; AX focus observer добавлен для
  same-app transitions. Это устраняет отсутствие наблюдения в прежнем snapshot,
  но delivery ordering и поддержка уведомлений конкретными приложениями ещё
  не проверены. Эти прежние diagnostics не объявляются текущими доказанными bugs.
- `MacInputEnvironment.swift:116` проверяет identity/generation, не отдельное
  изменение selection/value в том же поле. Перед заменой value/range проверены,
  но programmatic изменения после неё требуют native regression.
- Source selection explicit; source IDs связаны с парой; собственной памяти
  раскладки нет. Busy и bounded attempts разумны, tests идут через production.
- README исправляет правило выбора пары, описывает AX поддержку, partial result,
  tooltip и pending macOS. Не обещает устранить системное восстановление.
- Modifier-only ремонт/новый индикатор/CI/pkg не включены; unrelated code changes
  не обнаружены. Новый tooltip служит уже необходимой обратной связи.

После R1 повторить затронутый TDD evidence/QA/reviewer. Для окончательного
approve обязательны реальные macOS build и AC01–18 с AX/TIS. Текущий отчёт
не заменяет final architect/security gates и не разрешает публикацию.
