#!/bin/bash
set -e

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  echo '{"model": "anthropic/claude-sonnet-4-6"}' > "$OPENCODE_CONFIG"
  echo "[ai-dev] Created default opencode config."
fi

OLLAMA_MODELS=$(curl -sf --max-time 3 http://ollama:11434/v1/models 2>/dev/null \
  | jq 'reduce .data[].id as $id ({}; .[$id] = {"name": $id, "tools": true})' 2>/dev/null \
  || echo '{}')

jq --argjson models "$OLLAMA_MODELS" '.provider.ollama = {
  "npm": "@ai-sdk/openai-compatible",
  "name": "Ollama (local)",
  "options": { "baseURL": "http://ollama:11434/v1" },
  "models": $models
}' "$OPENCODE_CONFIG" > /tmp/opencode.tmp && mv /tmp/opencode.tmp "$OPENCODE_CONFIG"

if [ "$OLLAMA_MODELS" != "{}" ]; then
  echo "[ai-dev] Ollama models registered in opencode: $(echo "$OLLAMA_MODELS" | jq -r 'keys | join(", ")')"
else
  echo "[ai-dev] Ollama not reachable — no models registered. Restart ai-dev after starting Ollama."
fi

# Install Claude Code skills (copy from image into the persistent claude-auth volume)
if [ -d /usr/local/share/claude-skills ]; then
  mkdir -p /root/.claude/commands
  cp /usr/local/share/claude-skills/*.md /root/.claude/commands/ 2>/dev/null || true
fi

exec "$@"
