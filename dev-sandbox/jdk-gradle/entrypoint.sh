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

exec "$@"
