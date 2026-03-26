#!/bin/bash
set -e

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  cat > "$OPENCODE_CONFIG" <<'EOF'
{
  "model": "anthropic/claude-sonnet-4-6"
}
EOF
  echo "[ai-dev] Created default opencode config."
fi

jq '.providers.ollama = { "baseUrl": "http://ollama:11434" }' \
  "$OPENCODE_CONFIG" > /tmp/opencode.tmp && mv /tmp/opencode.tmp "$OPENCODE_CONFIG"

exec "$@"
