#!/bin/bash
set -e

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  echo '{"model": "anthropic/claude-sonnet-4-6"}' > "$OPENCODE_CONFIG"
  echo "[ai-dev] Created default opencode config."
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
  echo "[ai-dev] Ollama models registered in opencode: $(echo "$OLLAMA_MODELS" | jq -r 'keys | join(", ")')"
else
  echo "[ai-dev] Ollama not reachable — no models registered. Restart ai-dev after starting Ollama."
fi

# Install skills into ~/.claude/skills/ — discovered by Claude Code, opencode, and gh copilot
if [ -d /opt/skills ]; then
  mkdir -p /root/.claude/skills
  cp -r /opt/skills/. /root/.claude/skills/
fi

exec "$@"
