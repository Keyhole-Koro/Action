#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Running compose preflight checks in %s\n' "$ROOT_DIR"

rendered_config="$(cd "$ROOT_DIR" && docker compose --profile full config)"

organize_env_block="$(printf '%s\n' "$rendered_config" | awk '
  /^  organize:$/ { in_org=1; next }
  in_org && /^  [a-z0-9-]+:$/ { exit }
  in_org { print }
')"

if [[ -z "$organize_env_block" ]]; then
  printf 'ERROR: failed to resolve organize service from docker compose config\n' >&2
  exit 1
fi

if printf '%s\n' "$organize_env_block" | grep -q 'VERTEX_USE_REAL_API: "true"'; then
  if ! printf '%s\n' "$organize_env_block" | grep -q 'GEMINI_API_KEY:'; then
    printf 'ERROR: organize has VERTEX_USE_REAL_API=true but GEMINI_API_KEY is missing in effective compose config\n' >&2
    exit 1
  fi

  if printf '%s\n' "$organize_env_block" | grep -q 'GEMINI_API_KEY: ""'; then
    printf 'ERROR: organize has VERTEX_USE_REAL_API=true but GEMINI_API_KEY is empty\n' >&2
    printf 'Hint: export GEMINI_API_KEY=your-api-key before docker compose up\n' >&2
    exit 1
  fi
fi

printf 'compose preflight: OK\n'
