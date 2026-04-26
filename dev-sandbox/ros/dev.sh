#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ros-dev"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

if ! docker ps --format '{{.Names}}' | grep -q "^ros-proxy$"; then
  echo "[$CONTAINER] Starter proxy..."
  docker-compose -f "$COMPOSE_FILE" up -d proxy
fi

if ! docker ps --format '{{.Names}}' | grep -q "^ros-ollama-proxy$"; then
  echo "[$CONTAINER] Starter ollama-proxy..."
  docker-compose -f "$COMPOSE_FILE" up -d ollama-proxy
fi

docker rm -f "$CONTAINER" 2>/dev/null || true

docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
  --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null

echo "[$CONTAINER] Klar."

if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
