#!/usr/bin/env bash
set -euo pipefail

: "${PUBSUB_EMULATOR_HOST:?PUBSUB_EMULATOR_HOST is required}"
: "${PUBSUB_PROJECT_ID:?PUBSUB_PROJECT_ID is required}"
: "${ORGANIZE_PUSH_ENDPOINT:?ORGANIZE_PUSH_ENDPOINT is required}"

TOPIC="mind-events"
DLQ_TOPIC="mind-events-dlq"
SUBSCRIPTIONS=(
  "sub-topic-resolver"
  "sub-a2"
  "sub-a3b"
  "sub-a6"
  "sub-a3"
  "sub-a4"
  "sub-a7"
  "sub-a5"
)

create_topic() {
  local topic="$1"
  gcloud pubsub topics create "${topic}" --project="${PUBSUB_PROJECT_ID}" >/dev/null 2>&1 || true
}

create_push_subscription() {
  local subscription="$1"
  gcloud pubsub subscriptions create "${subscription}" \
    --project="${PUBSUB_PROJECT_ID}" \
    --topic="${TOPIC}" \
    --push-endpoint="${ORGANIZE_PUSH_ENDPOINT}" \
    --ack-deadline=30 >/dev/null 2>&1 || true
}

create_topic "${TOPIC}"
create_topic "${DLQ_TOPIC}"

for subscription in "${SUBSCRIPTIONS[@]}"; do
  create_push_subscription "${subscription}"
done

printf 'Pub/Sub bootstrap finished for project %s\n' "${PUBSUB_PROJECT_ID}"
