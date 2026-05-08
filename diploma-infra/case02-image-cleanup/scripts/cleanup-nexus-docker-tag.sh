#!/bin/sh
# Удаляет компонент Docker в Nexus 3 по имени образа и тегу (REST Components API).
# Переменные окружения:
#   NEXUS_URL            — http://nexus:8081
#   NEXUS_USER / NEXUS_PASSWORD
#   NEXUS_REPOSITORY     — имя hosted-репозитория (например docker-hosted)
#   IMAGE_NAME           — имя образа без registry (например diploma-ping)
#   CLEANUP_IMAGE_TAG    — тег, который нужно удалить

set -eu

: "${NEXUS_URL:?}"
: "${NEXUS_USER:?}"
: "${NEXUS_PASSWORD:?}"
: "${NEXUS_REPOSITORY:?}"
: "${IMAGE_NAME:?}"
: "${CLEANUP_IMAGE_TAG:?}"

auth="-u${NEXUS_USER}:${NEXUS_PASSWORD}"
list_url="${NEXUS_URL%/}/service/rest/v1/components?repository=${NEXUS_REPOSITORY}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -sfS $auth "$list_url" -o "$tmp"

id="$(jq -r --arg n "$IMAGE_NAME" --arg t "$CLEANUP_IMAGE_TAG" \
  '.items[] | select(.name == $n and .version == $t) | .id' "$tmp" | head -n1)"

if [ -z "$id" ] || [ "$id" = "null" ]; then
  echo "Компонент не найден: ${IMAGE_NAME}:${CLEANUP_IMAGE_TAG} в ${NEXUS_REPOSITORY}"
  exit 0
fi

del_url="${NEXUS_URL%/}/service/rest/v1/components/${id}"
curl -sfS $auth -X DELETE "$del_url"
echo "Удалено: ${IMAGE_NAME}:${CLEANUP_IMAGE_TAG} (id ${id})"
