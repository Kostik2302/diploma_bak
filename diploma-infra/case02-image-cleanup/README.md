# Кейс 2 — очистка образов

Соответствует [02-image-cleanup/README-ru.md](../../02-image-cleanup/README-ru.md).

## Как подключить к проекту из кейса 1

1. Скопируйте каталог `scripts/` в корень вашего GitLab-проекта (рядом с `Dockerfile` и `app/`).
2. Замените корневой `.gitlab-ci.yml` на [`.gitlab-ci.yml`](.gitlab-ci.yml) из этого каталога.
3. В GitLab добавьте переменные `NEXUS_URL`, `NEXUS_REPOSITORY` (см. комментарии в YAML).

## Расписание

**CI/CD → Schedules → New schedule**: выберите ветку, в **Variables** добавьте `CLEANUP_IMAGE_TAG` с тегом, который нужно удалить из hosted-репозитория.

Скрипт [scripts/cleanup-nexus-docker-tag.sh](scripts/cleanup-nexus-docker-tag.sh) вызывает Nexus Components API. Если формат `name`/`version` в вашем Nexus отличается, снимите ответ `GET .../components?repository=...` и подправьте `jq` в скрипте.

## Задачи Nexus по расписанию

В дополнение к GitLab Schedule настройте в Nexus **Administration → Repository → Tasks** задачи на удаление неиспользуемых слоёв и сжатие blob store (как в чекпоинте кейса). Это делается в UI Nexus, не в этом репозитории.

## Остановка Environment (опционально)

Чтобы удалять образ при остановке review-окружения, используйте пару jobs `environment: on_stop` по [документации GitLab](https://docs.gitlab.com/ee/ci/environments/#stop-an-environment). Логику вызова того же скрипта можно повторить в `stop` job.
