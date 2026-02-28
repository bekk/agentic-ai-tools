#!/bin/bash
set -e

COMPOSE_FILE="$(cd "$(dirname "$0")" && pwd)/compose.yaml"
CONTAINER="dev-runner"

# Start persistent container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[dev] Starting persistent container..."
  docker-compose -f "$COMPOSE_FILE" run -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[dev] Container ready."
fi

# Open a shell (or run a command if arguments are given)
if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
