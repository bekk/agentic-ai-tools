#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="dev-runner"

# Load port defaults (mirrors compose.yaml defaults)
DEV_PORT_1="${DEV_PORT_1:-8080}"
DEV_PORT_2="${DEV_PORT_2:-8081}"
if [ -f "$ENV_FILE" ]; then
  export $(grep -E '^DEV_PORT_' "$ENV_FILE" | xargs 2>/dev/null) 2>/dev/null || true
  DEV_PORT_1="${DEV_PORT_1:-8080}"
  DEV_PORT_2="${DEV_PORT_2:-8081}"
fi

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

# Start persistent container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[dev] Starting persistent container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[dev] Container ready (ports: $DEV_PORT_1, $DEV_PORT_2)."
else
  BOUND=$(docker port "$CONTAINER" 2>/dev/null || true)
  for PORT in "$DEV_PORT_1" "$DEV_PORT_2"; do
    if ! echo "$BOUND" | grep -q "${PORT}/tcp"; then
      echo "[dev] ERROR: Port $PORT is not bound on the running container."
      echo "[dev] Port mappings are set at creation time. To apply new config:"
      echo "[dev]   docker rm -f $CONTAINER"
      echo "[dev] Then re-run this script."
      exit 1
    fi
  done
fi

# Open a shell (or run a command if arguments are given)
if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
