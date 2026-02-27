#!/bin/bash
set -e

# ── Bootstrap Gradle cache on first run (unrestricted network) ─────────────
BOOTSTRAP_SENTINEL="/root/.gradle/.bootstrapped"

if [ ! -f "$BOOTSTRAP_SENTINEL" ]; then
  echo "[dev] First run: bootstrapping Gradle cache (full network access)..."
  # Find first Gradle project in /repos and run dependency resolution
  GRADLE_PROJECT=$(find /repos -maxdepth 2 -name "gradlew" -print -quit 2>/dev/null)
  if [ -n "$GRADLE_PROJECT" ]; then
    PROJECT_DIR=$(dirname "$GRADLE_PROJECT")
    echo "[dev] Found Gradle project at $PROJECT_DIR"
    (cd "$PROJECT_DIR" && ./gradlew dependencies --no-daemon --quiet 2>/dev/null || true)
    (cd "$PROJECT_DIR" && ./gradlew testClasses --no-daemon --quiet 2>/dev/null || true)
  else
    echo "[dev] No ./gradlew found in /repos yet — skipping Gradle bootstrap."
    echo "[dev] After cloning a project, delete /root/.gradle/.bootstrapped and restart."
  fi
  touch "$BOOTSTRAP_SENTINEL"
  echo "[dev] Bootstrap complete."
fi

# ── Network restriction via iptables ───────────────────────────────────────
echo "[dev] Applying network restrictions (GitHub + Anthropic only)..."

iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

for host in github.com api.github.com objects.githubusercontent.com \
            codeload.github.com uploads.github.com; do
  for ip in $(getent ahosts "$host" 2>/dev/null | awk '{print $1}' | sort -u); do
    iptables -A OUTPUT -d "$ip" -j ACCEPT
  done
done

for host in api.anthropic.com claude.ai statsig.anthropic.com; do
  for ip in $(getent ahosts "$host" 2>/dev/null | awk '{print $1}' | sort -u); do
    iptables -A OUTPUT -d "$ip" -j ACCEPT
  done
done

iptables -A OUTPUT -j DROP
echo "[dev] Network restricted."

exec "$@"
