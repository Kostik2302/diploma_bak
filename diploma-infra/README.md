# Диплом: изолированная инфраструктура (кейсы 1–4)

Модульные артефакты для воспроизведения [кейсов Inview Club](https://github.com/inview-club/devops-cases) в вашем стенде.

## Стенд (Hyper-V)

В корне репозитория лежат каталоги виртуальных машин:

| Каталог | Роль |
|---------|------|
| [../gitlab](../gitlab) | GitLab |
| [../build](../build) | GitLab Runner (сборка) |
| [../nexus](../nexus) | Sonatype Nexus Repository |

Диски ВМ в `.gitignore`, в Git попадают только конфиги и этот код.

## Содержимое

- [case01-build-isolation](case01-build-isolation) — Dockerfile, CI: сборка без внешнего интернета (через Nexus proxy), публикация в Docker Hosted.
- [case02-image-cleanup](case02-image-cleanup) — дополнения CI: очистка образов по расписанию / API Nexus.
- [case03-opensearch-migration](case03-opensearch-migration) — заготовки под миграцию (отдельный стенд OpenSearch).
- [case04-opensearch-hot-warm](case04-opensearch-hot-warm) — hot–warm + ISM (отдельный стенд).

Начните с `case01-build-isolation/README.md`.
