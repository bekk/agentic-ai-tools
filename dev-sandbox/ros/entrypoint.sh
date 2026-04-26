#!/bin/bash
set -e

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  echo '{}' > "$OPENCODE_CONFIG"
fi

OLLAMA_MODELS=$(curl -sf --max-time 3 "${OLLAMA_HOST}/v1/models" 2>/dev/null \
  | jq 'reduce .data[].id as $id ({}; .[$id] = {"name": $id, "tools": true})' 2>/dev/null \
  || echo '{}')

jq --argjson models "$OLLAMA_MODELS" --arg baseurl "${OLLAMA_HOST}/v1" '.provider.ollama = {
  "npm": "@ai-sdk/openai-compatible",
  "name": "Ollama (local)",
  "options": { "baseURL": $baseurl },
  "models": $models
}' "$OPENCODE_CONFIG" > /tmp/opencode.tmp && mv /tmp/opencode.tmp "$OPENCODE_CONFIG"

if [ "$OLLAMA_MODELS" != "{}" ]; then
  echo "[ros] Ollama-modeller registrert: $(echo "$OLLAMA_MODELS" | jq -r 'keys | join(", ")')"
else
  echo "[ros] Ollama ikke tilgjengelig — start Ollama på host og restart containeren."
fi

if [ -d /opt/skills ]; then
  mkdir -p /root/.claude/skills
  cp -r /opt/skills/. /root/.claude/skills/
  chmod +x /root/.claude/skills/ros/ros-generate.sh 2>/dev/null || true
fi

exec "$@"
