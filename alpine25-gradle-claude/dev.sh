#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="dev-runner"

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

# Start persistent container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[dev] Starting persistent container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[dev] Container ready."
fi

# Open a shell (or run a command if arguments are given)
if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
