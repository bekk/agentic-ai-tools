#!/bin/sh
set -e
# Allow squid user to write to stdout/stderr for Docker log collection
chmod o+w /dev/stdout /dev/stderr 2>/dev/null || true
# Remove stale PID file left by a previous crash
rm -f /var/run/squid.pid
exec "$@"
