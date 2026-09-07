# P2 developer handoff — revision 2

Task e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14,
ветка codex/system-layout-sync, план revision 2, strategy tdd-strategy-p2.md.
Автор: GPT Admin / developer. Исходный Git HEAD не изменён.

## Реализация

Production InputOperations выполняет обе команды через внешнюю InputEnvironment.
Тестовый адаптер моделирует внешние состояния текста/фокуса/источников, не
внутренние helpers. Native MacInputEnvironment реализует эту границу через TIS
и AX. AppDelegate вызывает тот же production coordinator асинхронно.

Ручная команда читает текущий TIS ID и рабочую пару, явно выбирает другую сторону,
проверяет наличие/результат. Конвертация проверяет замену и затем выбирает цель.
При чужом изменении источника выбор не повторяется. Предел подтверждения —
12 наблюдений, между ними native wait 20 ms. Повторные команды отклоняются,
Task cancellation и смена контекста отменяют оставшиеся эффекты.

Native capture хранит только временные PID, AX window/element, generation,
значение/выделение; release удаляет snapshot. Новые клавиши/мышь/активации
инвалидируют поколение, но не переключают раскладку. AX messaging timeout
ограничен 0.1 секунды на вызов. Записывается selectedText конкретного элемента,
проверяется полный ожидаемый value, курсор переводится в конец замены только
в том же контексте. Неподдерживаемые поля завершаются явно, без clipboard fallback.
Текст не журналируется и не отправляется наружу. Системные настройки не меняются.

## Debugging и TDD

Изначальная поверхность сохраняла прежнюю последовательность замены без выбора
целевого источника. Сначала baseline replacement GREEN. Затем behavioural RED:
12 тестов, 19 assertion failures при корректной компиляции. После минимального
production fix те же 12 тестов прошли; также прошли 7 conversion tests.
Дополнительно до final evidence добавлены 5 negative/race тестов без ослабления
первых assertions: внешний источник во время замены, потеря фокуса в ожидании,
отказ системы, отсутствующий контекст/источник, неподтверждённый выбор.
Final GREEN — 24 tests, 0 failures.

tdd_status:
- applied: yes, production coordinator behavior.
- baseline: evidence/p2-baseline.txt.
- failing_test_first: evidence/p2-red.txt, evidence/p2-red-sha256.txt.
- fix_commit_or_diff: evidence/p2-fix.diff.
- green_evidence: evidence/p2-green.txt, evidence/p2-final.txt.
- final source/test revision: evidence/p2-final-sha256.txt.
- coverage_note: внешние границы изолированы; это не native integration test.

Команды: `. /tmp/langconvert-swift/env.sh; swift test --sdk
/tmp/langconvert-swift/sysroot`; Swift frontend parse двух native файлов.
Core RED/GREEN фактически выполнен; macOS typecheck/link/runtime отсутствуют.

## Остаточные проверки

Native API/actor compatibility, AX readback/caret, event delivery и TIS фактическое
переключение необходимо проверить на macOS. Проверка фокуса и внешний вызов не
атомарны; гарантировать отсутствие любого микроскопического race только по
Linux tests нельзя. Final QA/release readiness не объявляются успешными.
Следующий gate — отдельный TDD evidence, затем scoped QA/reviewer/security;
macOS acceptance остаётся обязательной до закрытия всей задачи.

## Repair по независимому reviewer

Finding: Task cancellation во время ожидания могла привести к side-effectful
replacementState до проверки отмены (native verifier может завершать caret).
Regression testCancellationStopsVerificationSideEffects действительно упал:
evidence/p2-cancel-red.txt, 1 failure. Исправление: cancellation guard до
replacementState; native contextIsCurrent также проверяет Task cancellation.
Затем добавлены тесты двух команд во время незавершённого переключения и
потери фокуса во время подтверждения источника. Final suite: 27 tests, 0 failures.
Исторические 24/25 test результаты выше не являются текущими final hashes.

Дополнительная защита native adapter: AX observer focused element/window
на время snapshot; unsupported subscriptions дают отказ capture. Временные
keyboard/mouse monitors учитывают timestamp, чтобы поздняя доставка исходного
hotkey не отменяла новую операцию. Observer source снимается при release/deinit.
Последний статус также доступен через tooltip значка; интерфейс не захватывает
фокус для сообщения об ошибке. Native build/runtime по-прежнему pending.

## Repair R2: manual context

Независимое review выявило зависимость ручного переключения от AX поддержки
редактирования/уведомлений. Добавлен отдельный captureSwitchContext:
frontmost PID, optional window, generation/time; строгий capture конвертации
сохранён. Источник выбирается один раз до первого await, далее только readback.
Regression сначала дал 2 behavioral assertion failures
(evidence/p2-manual-context-red.txt), после исправления 28 tests PASS
(evidence/p2-final.txt). Native syntax parse PASS, native typecheck не выполнен.
