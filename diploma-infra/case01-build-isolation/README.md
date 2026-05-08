# Кейс 1 — изоляция сборки

Соответствует [01-build-isolation/README-ru.md](../../01-build-isolation/README-ru.md).

## Что здесь

| Файл | Назначение |
|------|------------|
| `app/` | Минимальный Go HTTP-сервис (`pong`), аналогичный по идее [docker-gs-ping](https://github.com/docker/docker-gs-ping) |
| `Dockerfile` | Многостадийная сборка; `GOPROXY` задаётся build-arg |
| `.gitlab-ci.yml` | Стадии `build` и `push` в Nexus |

## Порядок на стенде

1. **Nexus** — создайте репозитории:
   - Docker **hosted** (для push образов проекта);
   - Docker **proxy** (зеркало Docker Hub / других registry);
   - **Go (proxy)** для модулей Go.

2. **Runner (ВМ build)** — установите Docker. В `/etc/docker/daemon.json` добавьте зеркало на Nexus Docker Proxy, например:

   ```json
   {
     "registry-mirrors": ["http://NEXUS_IP:ПОРТ_DOCKER_PROXY"],
     "insecure-registries": ["http://NEXUS_IP:ПОРТ_DOCKER_HOSTED"]
   }
   ```

   Перезапустите Docker. Порт и HTTP/HTTPS зависят от того, как настроен Nexus (часто отдельные порты для docker proxy и hosted).

3. **GitLab** — создайте проект, залейте содержимое каталога `case01-build-isolation` **как корень репозитория** (или положите эти файлы в корень вашего проекта).

4. **CI/CD variables** — задайте переменные из шапки `.gitlab-ci.yml`.

5. **Проверка изоляции** — отключите интернет на ВМ `build` (или заблокируйте исходящий трафик), убедитесь, что базовые слои и `go mod` тянутся через Nexus, пайплайн зелёный.

## Локальная проверка (на вашем ПК)

Из каталога `case01-build-isolation`:

```bash
docker build -t diploma-ping:local .
docker run --rm -p 8080:8080 diploma-ping:local
curl localhost:8080
```

Ожидается ответ `pong`.
