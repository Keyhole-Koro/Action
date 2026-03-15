#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'ERROR: required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
}

print_section() {
  local title="$1"
  printf '\n[%s]\n' "$title"
}

check_http() {
  local label="$1"
  local url="$2"
  local expected="$3"
  local method="${4:-GET}"

  local status
  status="$(curl -sS -o /tmp/action-smoke-body.$$ -w '%{http_code}' -X "$method" "$url")"

  if [[ "$status" != "$expected" ]]; then
    printf 'ERROR: %s returned %s, expected %s\n' "$label" "$status" "$expected" >&2
    printf 'Body:\n' >&2
    cat /tmp/action-smoke-body.$$ >&2
    rm -f /tmp/action-smoke-body.$$
    exit 1
  fi

  printf '%s: %s (%s)\n' "$label" "$status" "$url"
  rm -f /tmp/action-smoke-body.$$
}

require_command docker
require_command curl

print_section "Compose"
(cd "$ROOT_DIR" && docker compose ps -a)

print_section "HTTP"
check_http "frontend /" "http://localhost:3000" "200"
check_http "act-api /healthz" "http://localhost:8080/healthz" "200"
check_http "act-api /auth/session/bootstrap (no token)" "http://localhost:8080/auth/session/bootstrap" "401" "POST"
check_http "act-adk-worker /healthz" "http://localhost:8000/healthz" "200"

if (cd "$ROOT_DIR" && docker compose ps --services --filter status=running | grep -qx "firebase-emulator"); then
  check_http "firebase emulator firestore" "http://localhost:8081" "200"
fi

if (cd "$ROOT_DIR" && docker compose ps --services --filter status=running | grep -qx "organize"); then
  check_http "organize /healthz" "http://localhost:8090/healthz" "200"
fi

print_section "Logs"
(cd "$ROOT_DIR" && docker compose logs --no-color --tail=20 frontend act-api act-adk-worker)

printf '\nsmoke-test: OK\n'
