#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ai-dev"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

if ! docker ps --format '{{.Names}}' | grep -q "^dev-proxy$"; then
  echo "[$CONTAINER] Starting proxy..."
  docker-compose -f "$COMPOSE_FILE" up -d proxy
  echo "[$CONTAINER] Proxy ready."
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[$CONTAINER] Starting container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[$CONTAINER] Container ready."
fi

if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
