#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

frontend_dir="${FRONTEND_DIR:-./ActionAct/frontend}"
act_api_dir="${ACT_API_DIR:-./ActionAct/act-api}"
act_adk_worker_dir="${ACT_ADK_WORKER_DIR:-./ActionAct/act-adk-worker}"
organize_dir="${ORGANIZE_DIR:-./ActionOrganize}"
action_ingest_dir="${ACTION_INGEST_DIR:-./ActionIngest}"
gcs_emulator_image="${GCS_EMULATOR_IMAGE:-fsouza/fake-gcs-server:latest}"

resolve_path() {
  local input="$1"
  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s/%s\n' "$ROOT_DIR" "$input"
  fi
}

check_dir() {
  local label="$1"
  local path_value="$2"
  local required_file="${3:-}"
  local resolved
  resolved="$(resolve_path "$path_value")"

  if [[ ! -d "$resolved" ]]; then
    printf 'ERROR: %s directory not found: %s\n' "$label" "$resolved" >&2
    exit 1
  fi

  if [[ -n "$required_file" && ! -f "$resolved/$required_file" ]]; then
    printf 'WARN: %s is missing %s, service will enter compose wait mode: %s\n' "$label" "$required_file" "$resolved/$required_file" >&2
    return
  fi

  printf '%s: %s\n' "$label" "$resolved"
}

printf 'Checking compose inputs in %s\n' "$ROOT_DIR"
check_dir "FRONTEND_DIR" "$frontend_dir" "package.json"
check_dir "ACT_API_DIR" "$act_api_dir" "go.mod"
check_dir "ACT_ADK_WORKER_DIR" "$act_adk_worker_dir" "app/main.py"
check_dir "ORGANIZE_DIR" "$organize_dir" "package.json"
check_dir "ACTION_INGEST_DIR" "$action_ingest_dir" "package.json"
printf 'GCS_EMULATOR_IMAGE: %s\n' "$gcs_emulator_image"

(cd "$ROOT_DIR" && docker compose config >/dev/null)
printf 'docker compose config: OK\n'
