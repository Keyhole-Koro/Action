#!/usr/bin/env bash
set -euo pipefail

: "${PUBSUB_EMULATOR_HOST:?PUBSUB_EMULATOR_HOST is required}"
: "${PUBSUB_PROJECT_ID:?PUBSUB_PROJECT_ID is required}"
: "${ORGANIZE_PUSH_ENDPOINT:?ORGANIZE_PUSH_ENDPOINT is required}"

PUBSUB_BASE_URL="http://${PUBSUB_EMULATOR_HOST}/v1"

http_status() {
  perl -MIO::Socket::INET -e '
my ($url, $method, $body) = @ARGV;
$body = defined($body) ? $body : "";
$url =~ m{^http://([^/:]+):(\d+)(/.*)$} or die "invalid URL\n";
my ($host, $port, $path) = ($1, $2, $3);
my $sock = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Proto => "tcp", Timeout => 5)
  or do { print "000\n"; exit 0; };
my $req = "$method $path HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n";
if (length $body) {
  $req .= "Content-Type: application/json\r\nContent-Length: " . length($body) . "\r\n";
}
$req .= "\r\n$body";
print $sock $req;
my $line = <$sock>;
if (defined $line && $line =~ m{^HTTP/\S+\s+(\d{3})}) {
  print "$1\n";
} else {
  print "000\n";
}
' "$@"
}

TOPIC="mind-events"
DLQ_TOPIC="mind-events-dlq"
SUBSCRIPTIONS=(
  "sub-ingest"
  "sub-a0"
  "sub-a1"
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
  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/topics/${topic}" GET)" = "200" ]; then
    printf 'Topic already exists: %s\n' "${topic}"
    return 0
  fi

  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/topics/${topic}" PUT '{}')" != "200" ]; then
    printf 'Failed to create topic: %s\n' "${topic}" >&2
    exit 1
  fi
  printf 'Created topic: %s\n' "${topic}"
}

create_push_subscription() {
  local subscription="$1"
  local filter
  filter="$(subscription_filter "${subscription}")"

  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" GET)" = "200" ]; then
    if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" DELETE)" != "200" ]; then
      printf 'Failed to delete subscription: %s\n' "${subscription}" >&2
      exit 1
    fi
    printf 'Recreated subscription: %s\n' "${subscription}"
  fi

  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" PUT "{
      \"topic\": \"projects/${PUBSUB_PROJECT_ID}/topics/${TOPIC}\",
      \"pushConfig\": {
        \"pushEndpoint\": \"${ORGANIZE_PUSH_ENDPOINT}\"
      },
      \"ackDeadlineSeconds\": 30,
      \"filter\": ${filter}
    }")" != "200" ]; then
    printf 'Failed to create subscription: %s\n' "${subscription}" >&2
    exit 1
  fi
  printf 'Created subscription: %s\n' "${subscription}"
}

subscription_filter() {
  local subscription="$1"
  case "${subscription}" in
    "sub-ingest")
      printf '%s' '"attributes.type = \"organize.ingest.received\""'
      ;;
    "sub-a0")
      printf '%s' '"attributes.type = \"media.received\""'
      ;;
    "sub-a1")
      printf '%s' '"attributes.type = \"input.received\" OR attributes.type = \"atom.reissued\""'
      ;;
    "sub-topic-resolver")
      printf '%s' '"attributes.type = \"atom.created\""'
      ;;
    "sub-a2")
      printf '%s' '"attributes.type = \"topic.resolved\""'
      ;;
    "sub-a3b")
      printf '%s' '"attributes.type = \"draft.updated\" OR attributes.type = \"topic.schema_updated\""'
      ;;
    "sub-a6")
      printf '%s' '"attributes.type = \"bundle.described\""'
      ;;
    "sub-a3")
      printf '%s' '"attributes.type = \"bundle.created\""'
      ;;
    "sub-a4")
      printf '%s' '"attributes.type = \"outline.updated\" OR attributes.type = \"topic.node_changed\""'
      ;;
    "sub-a7")
      printf '%s' '"attributes.type = \"node.rollup_requested\" OR attributes.type = \"node.rollup.updated\""'
      ;;
    "sub-a5")
      printf '%s' '"attributes.type = \"topic.metrics.updated\""'
      ;;
    *)
      printf 'Unknown subscription: %s\n' "${subscription}" >&2
      exit 1
      ;;
  esac
}



create_push_subscription_to_endpoint() {
  local topic="$1"
  local subscription="$2"
  local endpoint="$3"

  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" GET)" = "200" ]; then
    if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" DELETE)" != "200" ]; then
      printf 'Failed to delete subscription: %s\n' "${subscription}" >&2
      exit 1
    fi
  fi

  if [ "$(http_status "${PUBSUB_BASE_URL}/projects/${PUBSUB_PROJECT_ID}/subscriptions/${subscription}" PUT "{
      \"topic\": \"projects/${PUBSUB_PROJECT_ID}/topics/${topic}\",
      \"pushConfig\": {
        \"pushEndpoint\": \"${endpoint}\"
      },
      \"ackDeadlineSeconds\": 30
    }")" != "200" ]; then
    printf 'Failed to create push subscription: %s\n' "${subscription}" >&2
    exit 1
  fi
  printf 'Created push subscription: %s -> %s\n' "${subscription}" "${endpoint}"
}

create_topic "${TOPIC}"
create_topic "${DLQ_TOPIC}"

for subscription in "${SUBSCRIPTIONS[@]}"; do
  create_push_subscription "${subscription}"
done


DISCORD_MESSAGE_TOPIC="discord-message-received"
DISCORD_MESSAGE_SUBSCRIPTION="sub-discord-message-received"
create_topic "${DISCORD_MESSAGE_TOPIC}"
create_push_subscription_to_endpoint "${DISCORD_MESSAGE_TOPIC}" "${DISCORD_MESSAGE_SUBSCRIPTION}" "${ORGANIZE_PUSH_ENDPOINT}"

printf 'Pub/Sub bootstrap finished for project %s\n' "${PUBSUB_PROJECT_ID}"
