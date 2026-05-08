# Кейс 3 — миграция OpenSearch

Официальное задание: [03-opensearch-migration/README-ru.md](../../03-opensearch-migration/README-ru.md).

## Готовый стенд в этом репозитории

Рабочий вариант на Docker Desktop (Windows): **[opensearch-migration-diploma](../../opensearch-migration-diploma/README.md)** — сценарий 1 (замена нод) и сценарий 2 (remote `_reindex`).

Кратко по кейсу:

- **Ввод/вывод нод:** кластер 2+ нод, индекс с данными, управление `cluster.routing.allocation.*`, перенос шардов, `_cat/shards`, затем green.
- **Remote reindex:** два кластера по 2+ ноды, `reindex.remote.whitelist` на приёмнике, индекс на источнике и приёмнике с одинаковыми settings/mappings, `_reindex`, совпадение `_count`.
