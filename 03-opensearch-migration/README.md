# OpenSearch: кейс 3 (диплом)

Локальный стенд под [03-opensearch-migration](../03-opensearch-migration/README-ru.md): два сценария — **замена нод** и **remote reindex** между двумя кластерами.

## Требования

- Windows с **Docker Desktop**
- **curl** в `PATH` (есть в Windows 10+)

## Важно про порты

Сценарии **1** и **2** оба используют хост-порты **9201** и **9202** для разных целей. **Не поднимайте оба compose одновременно.** Меню: пункты 3 и 4 останавливают соответствующий сценарий (`docker-compose down -v`).

| Сценарий | 9200 | 9201 | 9202 | 9203 | 9204 | Dashboards |
|----------|------|------|------|------|------|------------|
| 1 — замена нод | nginx → кластер | old-node-1 | old-node-2 | new-1 | new-2 | 5601 |
| 2 — reindex | — | Source API | Dest API | — | — | 5602, 5603 |

## Запуск

```bat
start-diploma.bat
```

или `menu.bat` из этой папки.

### Сценарий 1 (порядок)

1. `setup-cluster.bat` — сброс nginx на **старые** ноды, подъём old-node-1/2 + proxy + Dashboards, индекс `test-index`, 10 документов.
2. `migrate-nodes.bat` — отключение аллокации, старт new-node-1/2, exclude старых имён, включение аллокации.
3. При необходимости `check-status.bat` — шарды и health.
4. `remove-old-nodes.bat` — nginx только на **новые** ноды, остановка старых контейнеров, проверка.

Конфиги nginx: `nginx-old.conf` (по умолчанию копируется в `nginx.conf`), после миграции — `nginx-new.conf`.

### Сценарий 2 (порядок)

1. `setup-clusters.bat` — два кластера, индекс на Source с данными, пустой индекс с тем же телом на Destination (`index-definition.json`).
2. `reindex-data.bat` — `_reindex` на **9202** с `remote.host` = `http://source-node-1:9200` (имя контейнера в сети compose).
3. `verify-reindex.bat` — сравнение `_count` и пример документа.

На нодах **destination** задано `reindex.remote.whitelist=source-node-1:9200,source-node-2:9200` (см. `docker-compose.yml`).

## Версия образов

Зафиксировано **OpenSearch / Dashboards 2.17.0** для предсказуемости. При необходимости поменяйте тег в обоих `docker-compose.yml`.

## Соответствие кейсу

- Сценарий 1: ребалансировка, exclude по имени ноды, перенос шардов, вывод старых нод — проверка через `_cat/shards`, `_cluster/health`.
- Сценарий 2: два кластера 2+2 ноды, whitelist для remote, создание индекса на приёмнике, `_reindex`, совпадение количества документов.
