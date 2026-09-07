# Documentation review

Owner: GPT Admin / documentation; вход: docs-request.md.
Сверены README, canonical card docs/context/input-source-operations.md,
production core, native adapter, Package.swift, acceptance Task и тесты.
Описание выбора пары исправлено на фактическую политику; описаны последнее
направление, partial/cancel, отсутствие памяти окон и clipboard, ограничение AX.
README явно отделяет локальные изменения от прежнего установщика и не обещает
подтверждённый macOS результат. Карточка содержит surfaces и last_verified.

KNOWLEDGE_SYNC_PENDING: canonical card создана, но scripts/knowledge.sh и
индексатор отсутствуют. Embeddings text-embedding-3-large, sync/verify/gate
не запускались; результат не заменён вымышленным индексом. KB docs/context;
surfaces перечислены в карточке, smoke queries — в docs-request.md.
Доступная проверка документации: git diff --check и проверка новых файлов.
