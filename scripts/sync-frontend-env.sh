#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/config/local/frontend.env"
TARGET_FILE="$ROOT_DIR/ActionAct/frontend/.env.local"

if [[ ! -f "$SOURCE_FILE" ]]; then
  printf 'ERROR: frontend env source not found: %s\n' "$SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET_FILE")"
cp "$SOURCE_FILE" "$TARGET_FILE"
printf 'Synced %s -> %s\n' "$SOURCE_FILE" "$TARGET_FILE"
