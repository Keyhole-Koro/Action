#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/ActionAct/frontend"

bash "$ROOT_DIR/scripts/sync-frontend-env.sh" >/dev/null
cd "$FRONTEND_DIR"
exec "$@"
