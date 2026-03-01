#!/bin/bash
set -e

# ── Opencode default config ─────────────────────────────────────────────────
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  cat > "$OPENCODE_CONFIG" <<'EOF'
{
  "model": "anthropic/claude-sonnet-4-6"
}
EOF
  echo "[opencode-dev] Created default opencode config."
fi

exec "$@"
