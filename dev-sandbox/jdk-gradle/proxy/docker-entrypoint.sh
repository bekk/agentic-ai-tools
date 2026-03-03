#!/bin/sh
set -e
# Allow squid user to write to stdout/stderr for Docker log collection
chmod o+w /dev/stdout /dev/stderr 2>/dev/null || true
exec "$@"
