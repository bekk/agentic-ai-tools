#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"
PROJECT="jdk-gradle"

echo "This will:"
echo "  - Remove containers: ai-dev, dev-proxy, ollama-proxy"
echo "  - Remove volumes:    repos, gradle-cache, gh-auth, claude-auth, opencode-config"
echo "  - Rebuild images from scratch (--no-cache)"
echo ""
read -rp "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo ""
echo "[reset] Removing dev container..."
docker rm -f ai-dev 2>/dev/null || true

echo "[reset] Stopping compose services..."
docker-compose -f "$COMPOSE_FILE" down

echo "[reset] Removing volumes..."
for vol in repos gradle-cache gh-auth claude-auth opencode-config; do
  docker volume rm "${PROJECT}_${vol}" 2>/dev/null && echo "  removed ${PROJECT}_${vol}" || echo "  skipped ${PROJECT}_${vol} (not found)"
done

echo "[reset] Rebuilding images..."
docker-compose -f "$COMPOSE_FILE" build --no-cache

echo ""
echo "[reset] Done. Run ./dev.sh to start fresh."
