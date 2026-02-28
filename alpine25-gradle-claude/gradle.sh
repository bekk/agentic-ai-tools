#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="gradle-runner"

# Load port defaults (mirrors compose.yaml defaults)
GRADLE_PORT_1="${GRADLE_PORT_1:-8082}"
GRADLE_PORT_2="${GRADLE_PORT_2:-8083}"
if [ -f "$ENV_FILE" ]; then
  export $(grep -E '^GRADLE_PORT_' "$ENV_FILE" | xargs 2>/dev/null) 2>/dev/null || true
  GRADLE_PORT_1="${GRADLE_PORT_1:-8082}"
  GRADLE_PORT_2="${GRADLE_PORT_2:-8083}"
fi

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

# Start persistent container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[gradle] Starting persistent container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    -d --name "$CONTAINER" gradle -c "sleep infinity" > /dev/null
  echo "[gradle] Container ready (ports: $GRADLE_PORT_1, $GRADLE_PORT_2)."
else
  BOUND=$(docker port "$CONTAINER" 2>/dev/null || true)
  for PORT in "$GRADLE_PORT_1" "$GRADLE_PORT_2"; do
    if ! echo "$BOUND" | grep -q ":${PORT}$"; then
      echo "[gradle] ERROR: Port $PORT is not bound on the running container."
      echo "[gradle] Port mappings are set at creation time. To apply new config:"
      echo "[gradle]   docker rm -f $CONTAINER"
      echo "[gradle] Then re-run this script."
      exit 1
    fi
  done
fi

# Open a shell (or run a command if arguments are given)
if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" /bin/sh
else
  docker exec -it "$CONTAINER" /bin/sh -c "$*"
fi
