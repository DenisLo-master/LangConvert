# TDD strategy — P2, revised plan

2026-09-07. Developer Team / TDD expert. Pipeline `product-dev-standard`.
Входы: Phase Plan revision 2, `ARCHITECT_PHASE_APPROVED`; прежний acceptance
AC01–18; отдельный core P1 `TDD_EVIDENCE_APPROVED`. Task не менялась.
Task SHA-256: `e6119b7cfb31a928b1fe47911ea387db91c126f5294e8d1dfdf567a81cb75e14`.
Phase Plan SHA-256: `fd8cefef7218a138b5141bef40a95bf154d8329282cdce026a50f5dcd13bfe77`.

## Verdict

**`TDD_PHASE_READY`, applicability required, checked_phase P2.**

Revision 2 позволяет исполнимый RED/GREEN production coordinator на Linux;
прежнее ограничение native integration сохранено для финального evidence P3.
Это свежий strategy verdict после архитектурного пересмотра, не ретроактивное
одобрение изменений и не освобождение от macOS проверки. Developer может начать
P2 core; native adapter разрешено писать после core GREEN. Наличие адаптера и
Linux tests не означает macOS typecheck, TIS/AX корректность или готовность релиза.

## Поверхность и первый RED

Public surface: production `InputOperations` на MainActor, async команды
конвертации/переключения через внешний `InputEnvironment`. Результаты — текст,
фактически активный источник во внешней среде, видимый итог операции и отмена.
Среда предоставляет внешние context/selection/source операции по плану.

Первая подготовительная поверхность сохраняет прежнее наблюдаемое поведение:
подтверждённая замена текста без выбора целевого источника. Сначала baseline
подтверждает корректную замену `ghbdtn` → `привет` при исходной EN. Затем тест
ожидает RU после этой же команды и реально падает на оставшейся EN. Тест
исполняет production coordinator; отсутствие API, compilation failure или
assertion исключительно по mock-call count не засчитываются как RED.

После сохранения RED выполнить минимальный фикс и тот же GREEN. До core GREEN
не реализовывать параллельно целевое поведение в native adapter. Сохранять hashes
production/test и логи; дополнительные negative cases закреплять до их фиксов,
если они выявляют отсутствующее поведение. Не переписывать ожидания под результат.

## Required behaviors

| AC | Проверяемый результат на внешней границе |
| --- | --- |
| AC01/02/17 | Ручная команда читает свежий текущий источник, выбирает второй в паре; не зависит от Control + Space |
| AC03 | Без команды внешние изменения источника/контекста сохраняются, coordinator ничего не восстанавливает |
| AC04/05/10 | После подтверждённого текста выбран target P1; уже активная цель остаётся без лишнего перехода |
| AC06–09 | Интеграция с production converter сохраняет смешанный текст/окончания; nil target не вызывает выбор |
| AC11 | Нет selection, denied access, read/replace failure и неподтверждённая замена не приводят к выбору или ложному успеху |
| AC12/14/18 | Используется одна предоставленная рабочая пара; вне пары ручной отказ; неполная/неоднозначная связь не угадывается |
| AC13 | Исчезнувшая цель, отказ выбора, delayed/no confirmation: точный отказ или частичный успех; никакого blind rollback |
| AC15 | Смена контекста до замены, между заменой и выбором, во время ожидания отменяет оставшиеся действия; другой документ неизменён, фокус не возвращается |
| AC16 | Повторные convert/switch и перекрёстные команды не накладывают замены и выборы; после окончания новая команда работает |

Отдельно необходимы race cases: пользователь меняет источник при ожидании;
источник выбран, но затем пользователь выбирает другой; context сменился и
вернулся; selection/value изменились в том же поле. Позднее завершение не
переигрывает новое намерение, бесконечного ожидания нет. Если замена выполнена,
но подтверждение невозможно, итог должен отражать неопределённость, а не
утверждать неизменность текста. Проверять состояние обоих документов, а не
только cancellation flag.

## Команды и coupling

В проекте после `. /tmp/langconvert-swift/env.sh`:

- Baseline: `swift test --sdk /tmp/langconvert-swift/sysroot --filter InputOperationAcceptanceTests.testBaselineReplacement`.
- RED/GREEN: `swift test --sdk /tmp/langconvert-swift/sysroot --filter InputOperationAcceptanceTests`.
- Полная регрессия: `swift test --sdk /tmp/langconvert-swift/sysroot`.

Имена suite/method определяют тестовую поверхность, которую предстоит создать.
Непустое число выполненных тестов обязательно; новый suite не заменяет семь
прежних core tests. Runner Swift 5.10.1 уже проверен фактическими P1 runs.

Допустима управляемая внешняя среда: selection/context, доступность источников,
отказы и задержки чтения/замены/выбора. Её состояние моделирует внешнее приложение,
но не дублирует решения production coordinator. Запрещены mocks его внутренних
методов, assertions private busy flags, тестирование копии алгоритма, GREEN
только по вызову select без наблюдаемого изменения/подтверждения. Управляемое
завершение внешних async действий предпочтительнее хрупких real-time sleeps.

## Непроверенное и следующий evidence

Native adapter main.swift/MacInputEnvironment.swift, реальные AX permissions,
поле/окно/PID, TIS IDs и системное восстановление не доказаны Linux tests.
После core GREEN адаптер можно подготовить, но для полного acceptance по
revision 2 нужны macOS `swift build`, `swift test` и интерактивная матрица
AC01–18, включая несколько приложений и окна одного приложения. Native P1
binding также остаётся в этой обязательной проверке. Отсутствие macOS evidence
блокирует final readiness; его нельзя пометить пройденным по syntax parse.

Следующий обязательный gate — отдельный TDD evidence после handoff с реальным
RED/GREEN, hashes и разделением core/native; QA и review не заменяются strategy.
P3 documentation RED NA сохраняется только в прежнем ограниченном смысле.
Открытых продуктовых вопросов нет. Файлы реализации и Phase Plan не менялись.
