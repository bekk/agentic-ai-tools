#!/bin/bash
set -e

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
