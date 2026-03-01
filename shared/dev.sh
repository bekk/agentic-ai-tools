# Sourced — not standalone. Caller must set SCRIPT_DIR and CONTAINER.

SHARED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/shared"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

ENV_FILE_ARG=""
[ -f "$ENV_FILE" ] && ENV_FILE_ARG="--env-file $ENV_FILE"

if ! docker ps --format '{{.Names}}' | grep -q "^dev-proxy$"; then
  echo "[$CONTAINER] Starting shared proxy..."
  docker-compose -f "$SHARED_DIR/compose-proxy.yaml" up -d
  echo "[$CONTAINER] Proxy ready."
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[$CONTAINER] Starting persistent container..."
  docker-compose $ENV_FILE_ARG -f "$COMPOSE_FILE" run \
    --service-ports -d --name "$CONTAINER" dev sleep infinity > /dev/null
  echo "[$CONTAINER] Container ready."
fi

if [ $# -eq 0 ]; then
  docker exec -it "$CONTAINER" bash
else
  docker exec -it "$CONTAINER" bash -c "$*"
fi
