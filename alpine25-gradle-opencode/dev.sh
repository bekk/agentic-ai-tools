#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="opencode-dev"
PROXY_CONTAINER="opencode-proxy"

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

# Ensure proxy is running
if ! docker ps --format '{{.Names}}' | grep -q "^${PROXY_CONTAINER}$"; then
  echo "[opencode-dev] Starting proxy container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" up -d proxy
  echo "[opencode-dev] Proxy ready."
fi

# Start persistent dev container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[opencode-dev] Starting persistent container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[opencode-dev] Container ready."
fi

# Open a shell (or run a command if arguments are given)
if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
