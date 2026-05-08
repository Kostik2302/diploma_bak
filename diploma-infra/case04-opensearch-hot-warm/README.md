# Кейс №4 — Hot-Warm lifecycle architecture на OpenSearch

## Запуск

```bat
run-case4.bat
```

## Что демонстрирует стенд

- 1 master / cluster-manager нода: `os-master`.
- 4 data-ноды:
  - `os-hot1`, `os-hot2` с `node.attr.temp=hot`;
  - `os-warm1`, `os-warm2` с `node.attr.temp=warm`.
- Data stream: `logs`.
- Backing indices: `.ds-logs-000001`, `.ds-logs-000002`, ...
- ISM lifecycle policy: `hot -> warm -> delete`.

## Почему в новых индексах 0 документов?

Это нормально. Скрипт загружает 5000 документов один раз в первый write-index. После rollover OpenSearch создает новый write-index, но если новые документы больше не добавляются, он остается пустым. Lifecycle при этом всё равно работает: индекс может перейти из hot в warm и затем удалиться.

## Основные проверки

```http
GET _cat/nodeattrs?v
GET _data_stream/logs?pretty
GET _plugins/_ism/explain/.ds-logs-*?pretty
GET _cat/shards/.ds-logs-*?v
```

## Очистка

```bat
docker compose down -v
```
