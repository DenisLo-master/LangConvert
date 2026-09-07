# Current scoped QA — R1/R2 repair verified

2026-09-07 13:20 UTC. Вход: свежий TDD_EVIDENCE_APPROVED в tdd-evidence-p2.md.
**Core QA pass; полная native QA blocked.** Source binding и manifest hash
указаны в свежем TDD report. Независимый Swift full run: 28 tests, 0 failures.
Проверены отдельная manual capture capability, сохранённый strict conversion
отказ, cancellation до verifier, manual overlap и focus loss при readback.
R1/R2 исходные failures устранены; регрессии старых core tests не обнаружены.

Native lightweight SwitchSnapshot хранит PID/optional window/generation/time,
не читает текст. Единственный select происходит до первого await; после него
только наблюдение. Поэтому отсутствие editable AX notification capabilities
не запрещает manual, но и не разрешает delayed повторный select. Strict
conversion capture и проверка перед записью сохранены.

Остаются macOS build/TIS/AX, программные selection/focus changes, actual
observer delivery и реальные два документа. Они не считаются выполненными
по fake. Readiness 🟡 7/10 для ограниченного продвижения к native validation.
Ниже история; прежний открытый R2 и counts superseded этим проходом.

---

# Scoped QA refresh — cancellation repair

2026-09-07 13:18 UTC. Вход: свежий tdd-evidence-p2.md core approval.
**Current scoped core verdict: pass по 27 выполненным tests; final QA blocked.**
Source binding: evidence/p2-final-sha256.txt, hashes независимо сверены.
Новый независимый full run 13:18:21 — 20 operations + 7 conversion, 0 failures.
R1 cancellation regression проходит; guard расположен до side-effectful
verification. Дополнительно проверены обе команды во время pending manual
switch и отсутствие retry при потере focus во время подтверждения source.

Test suite по-прежнему моделирует одинаковый context capability для manual и
conversion. Отсутствует кейс «editable AX capture недоступен, ручной TIS switch
доступен»; текущая native реализация его чрезмерно ограничивает (review R2).
Этот неподтверждённый адаптер не получает scoped QA pass. Перед final нужны
repair R2, affected evidence/review и macOS matrix. Readiness остаётся 🟡 7/10.

Ниже прежний QA проход, сохранён как история. Перечень незакрытых пробелов
Task.cancel/manual overlap в нём частично superseded текущими тестами выше.

---

# Scoped QA — production core P1/P2

2026-09-07. Исполнитель: QA Reliability Reviewer в отдельном проходе после
`tdd-evidence-p2.md`, core `TDD_EVIDENCE_APPROVED`. Native runtime исключён
из этого verdict; полная QA приложения и final readiness не закрываются.
Task: `e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`.

**Core QA: pass для выполненных сценариев, статус 🟡, readiness 7/10.**
Reliability risk: medium для core; native/final risk unknown до macOS.
Рекомендация: продолжать review и native validation, не объявлять релиз готовым.
Рейтинг такого ограниченного продолжения: 75/100; итоговый consensus не оценивается
одним reviewer. Owner оставшихся проверок: coordinator/developer macOS, P1.

## Что проверено

После отдельной проверки TDD evidence прочитаны public команды, return paths,
busy/defer, cancellation/source checks и внешняя test environment. Использован
свежий независимый full core run 13:06:42 UTC: 24 XCTest, 0 failures.
Повторять неизменный suite только ради нового этапа не требовалось.

Основные findings:

- Обе команды проверяют актуальный source/context, не восстанавливают собственную
  память раскладки. После внешней смены не повторяют выбор.
- Конвертация различает подтверждённый текст и неподтверждённый источник;
  failed/pending replacement не запускает source change.
- У источника уже равного цели нет обратного перехода. Вне ручной пары нет
  угадывания. Источник исчезает — получаем partial либо failure.
- Busy защищает async reentrancy, defer освобождает captured context и busy
  на ранних выходах. Тест подтверждает отказ перекрёстной команде и новый
  допустимый вызов после завершения.
- Циклы подтверждения ограничены числом попыток; реальная длительность зависит
  от внешней среды, bounded native AX calls отдельно не исполнены.

Исследуемые core hashes: Conversion.swift `6791ae11…`, InputOperations.swift
`194cbc98…`, conversion tests `ff0ba9a7…`, operation tests `add4cb14…`.
Native files после этого snapshot меняются владельцем; данный QA не связывает
approval с их новыми bytes и не подтверждает macOS сборку.

## Пробелы coverage

Текущие tests используют одно text поле и validContext Bool. Они показывают
решение coordinator по сигналам среды, но не доказательство фактической
сохранности второго окна или корректности context generation. Остаются:

- Task.cancel во время ожидания, transient context away/back.
- Изменение selection/value внутри того же элемента.
- Полная overlap матрица convert→convert и switch→convert.
- End-to-end обратная/смешанная конвертация через coordinator; отдельно core
  converter это покрывает, integration adapter ещё нет.

Эти пробелы не превращаются в выполненные AC; до final acceptance нужна
запланированная полная матрица. Новые тесты в этом read-only проходе не создавались.

## Native diagnostic, не финальный review gate

Прочитан прежний snapshot MacInputEnvironment с hash `c01e6521…`:

1. Generation обновлялась в отдельных Task из event callbacks; invoking key
   мог быть доставлен относительно capture с другой очередностью. Это риск
   self-cancel, а не воспроизведённый macOS bug. Coordinator сообщил о новом
   timestamp filter и PID-aware activation; новая версия требует отдельной проверки.
2. В snapshot наблюдались app activation и key/mouse events, но не AX focus
   transitions. Программный переход в другой элемент и обратно между polling
   checks мог сохранить PID/window/element/generation и остаться незамеченным.
   Это доказанный пробел наблюдения; проявление требует native сценария.
   Coordinator сообщил, что добавляет AX focus observer.
3. Selection/value change в том же element после replacement требует отдельной
   проверки: identity контекста не равна неизменности пользовательского намерения.
   Caret adjustment должен учитывать такие изменения. Code-only inspection
   не доказывает корректность уведомлений конкретного редактора.
4. MainActor Task wiring и AX/TIS API сейчас только прочитаны. Linux parser
   не проверяет macOS imports/actor isolation/link; ошибки компиляции по чтению
   не утверждаются. Нужен настоящий macOS build.

Эти замечания относятся к старому snapshot и переданы владельцу. Не использовать
их как финальный verdict по уже исправленному native diff.

## Side effects и выход

Положительное влияние: меньше лишних source transitions, частичный результат
не маскируется полным успехом; core конвертация сохранилась. Ограничение:
реальные сторонние редакторы могут не поддержать AX readback/caret; необходима
понятная обратная связь и macOS regression. Clipboard fallback отсутствует по
утверждённому плану, исходный clipboard эти команды не используют.

Откат/публикация не выполнялись. Отдельные security review, independent review,
финальный architect и macOS QA остаются обязательными; этот scoped QA их не заменяет.
