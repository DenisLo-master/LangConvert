# Current TDD evidence — R2 repaired

2026-09-07 13:20 UTC. **TDD_EVIDENCE_APPROVED, scope core P2/R1/R2.**
Source manifest `evidence/p2-final-sha256.txt` SHA-256 `33123b38bfa9d41d0eadc2d264d36118b3c382ba6e7f1477c00d5fbe0ff91f36`;
все восемь source/test/doc hashes проверены независимо и совпали.
R2 RED: `p2-manual-context-red.txt`, 1 compiled test, 2 behavioral failures
(noContext вместо switched, EN вместо RU). Current public coordinator вызывает
captureSwitchContext только для manual; conversion сохраняет captureContext.
Независимый GREEN 13:20:04 UTC: 21 operations + 7 conversion = 28 tests pass,
exit 0; команда после `. /tmp/langconvert-swift/env.sh` —
`swift test --sdk /tmp/langconvert-swift/sysroot`.
Regression одновременно подтверждает manual success, conversion отказ при
недоступном editable context и отсутствие изменения текста. R1 cancellation
regression также проходит. public_interface_check/coupling_check: pass.
Native adapter только прочитан; native build/runtime evidence pending.
Ниже неизменённая история предыдущих проходов; текущий verdict выше её заменяет.

---

# TDD evidence refresh — R1 cancellation repair

2026-09-07 13:18 UTC. Verified standalone activation повторена: compatible.
Current source binding: `evidence/p2-final-sha256.txt`; все 8 hashes проверены OK.
Core InputOperations `74074876…`; native adapter `9f1fc5ba…`; tests `86cb170d…`.

**Current verdict: TDD_EVIDENCE_APPROVED, scope core R1 repair и прежние core cases.**
RED `evidence/p2-cancel-red.txt`: один cancellation test, один поведенческий
failure — verifier продолжал работу после отмены. Current code добавляет guard
до replacementState (InputOperations.swift:48), native contextIsCurrent также
проверяет Task.isCancelled (MacInputEnvironment.swift:117).
Test вызывает public async command и наблюдает внешнюю verification boundary,
не private state. Independent GREEN 13:18:21: 27 XCTest, 0 failures, exit 0.
Команда: после `. /tmp/langconvert-swift/env.sh` —
`swift test --sdk /tmp/langconvert-swift/sysroot`.
Добавлены проверки отмены, overlap во время manual switch и focus loss при
source confirmation. public_interface_check/coupling_check: pass.
Предыдущий R1 снимается в пределах проверенного пути; native runtime не доказан.

Новый review finding по чрезмерно строгому manual capture не входит в этот
repair GREEN; требует отдельного RED/GREEN. Наличие 27 passing tests не означает
полной AC coverage. До итоговой готовности обязательны native build/runtime.

Ниже сохранён первоначальный проход как историческое evidence; его hashes,
counts и verdict относятся к прежним bytes, актуальное binding указано выше.

---

# TDD evidence — P2 core

2026-09-07. Developer Team / TDD expert. Отдельный проход после handoff,
до scoped QA. Task hash `e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`.
Входы: phase-plan revision 2, tdd-strategy-p2.md, p2-implementation.md,
production InputOperations, external TestInputEnvironment, evidence/p2-*.

**`TDD_EVIDENCE_APPROVED` только для production core P2.**
`checked_phase: P2 core`; `public_interface_check: pass`;
`coupling_check: pass`; `coverage_check: pass для выполненных core сценариев`.
Native adapter и полная AC01–18 integration остаются непроверенными;
по revision 2 их обязательный gate перенесён в финальный проход P3.
Допустим отдельный scoped core QA, не окончательная приёмка приложения.

## Проверенное evidence

- Baseline `p2-baseline.txt`, 13:00:09 UTC: 1 test pass, production replacement.
- RED `p2-red.txt`: 12 tests, 19 behavioral assertion failures, включая
  фактическую EN вместо ожидаемой RU при правильном `привет`; compiler работает.
- RED source snapshot в /tmp сверён с `p2-red-sha256.txt`: `9b23bb27…` совпадает.
- `p2-fix.diff` добавляет реальные проверки и выбор поверх заранее разрешённой
  production seam. Первый GREEN `p2-green.txt`: 12 operations + 7 conversion pass.
- Final `p2-final.txt`, 13:05:22: 17 operations + 7 conversion, 0 failures.
- Независимый повтор 13:06:42: `swift test --sdk /tmp/langconvert-swift/sysroot`
  после `. /tmp/langconvert-swift/env.sh`, exit 0, все 24 tests pass.
- `sha256sum -c evidence/p2-final-sha256.txt`: все 7 файлов OK, включая native
  файлы; совпадение hash native не означает их исполнения.

До/после RED tests проверены независимо: удаление только пяти последних
добавленных методов и восстановление исходного завершающего whitespace в
прочитанном тексте даёт точный RED hash `b4f4071b…`. Исходные assertions и
внешняя тестовая среда не ослаблены. Final test hash `add4cb14…` связан с
сохранённым final manifest. Дополнительные пять тестов — regression enhancement
после GREEN, не заявленный новый RED. Product core hash `194cbc98…`.

Тесты вызывают публичные команды production InputOperations. Fake моделирует
внешние текст/фокус/источники/отказы; проверки включают итоговые текст и источник,
не только вызовы. Internal mocks, копии production алгоритма и private assertions
не обнаружены. Необоснованных изменений тестов ради GREEN не выявлено.

## Покрытие и остаточные риски

Проверены fresh source, выбор целевой раскладки, already active/no direction,
отсутствующий источник, неподтверждённая замена/выбор, system refusal, partial
result, потеря контекста до/после замены и во время ожидания, external source
change, ограниченное ожидание, перекрёстная повторная команда и последующая
штатная команда. Прежние семь conversion tests проходят без регрессии.

Не доказаны реальная доставка событий, AX focus/selection/value/caret,
TIS variant IDs, macOS actor compatibility и интерфейсные сообщения.
Расширение core покрытия желательно для Task.cancel, switch→convert и
convert→convert overlap, реально двух документов и transient away/back.
Текущая fake использует boolean context и один text; она не доказывает
generation native adapter. Смешанный/обратный ввод покрыт converter отдельно,
а не каждым end-to-end coordinator сценарием.

Scope approval подтверждает выполненный core RED/GREEN; не объявляет полную
матрицу выполненной. Финальный readiness остаётся blocked без macOS. Этот отчёт
не выдаёт QA/reviewer verdict, не меняет plan и native production.
