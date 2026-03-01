#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="claude-dev"
source "$SCRIPT_DIR/../shared/dev.sh"
