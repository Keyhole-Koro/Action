"""Pub/Sub helpers: publish media.received, pull discord.flush_requested."""

from __future__ import annotations

import json
import os
import time
import uuid

from google.cloud import pubsub_v1


def publish_media_received(
    project_id: str,
    topic_name: str,
    workspace_id: str,
    gcs_uri: str,
    sha256: str,
) -> None:
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_name)

    trace_id = uuid.uuid4().hex
    idempotency_key = f"type:media.received/gcsUri:{gcs_uri}"

    envelope = {
        "schemaVersion": "1",
        "type": "media.received",
        "traceId": trace_id,
        "workspaceId": workspace_id,
        "idempotencyKey": idempotency_key,
        "emittedAt": _utcnow_rfc3339(),
        "payload": {
            "sourceType": "gcs_object",
            "gcsUri": gcs_uri,
            "sha256": sha256,
            "hint": {
                "contentType": "discord_chat_log",
                "mime": "text/markdown",
            },
        },
    }

    data = json.dumps(envelope).encode("utf-8")
    attributes = {
        "type": "media.received",
        "schemaVersion": "1",
        "workspaceId": workspace_id,
    }
    publisher.publish(topic_path, data=data, **attributes).result()


def pull_flush_requests(
    project_id: str,
    subscription_name: str,
    *,
    max_messages: int = 10,
    timeout: float = 2.0,
) -> list[str]:
    """
    Pull and ACK pending flush-request messages.
    Returns list of ack_ids (for caller to know something arrived).
    """
    subscriber = pubsub_v1.SubscriberClient()
    sub_path = subscriber.subscription_path(project_id, subscription_name)

    response = subscriber.pull(
        request={
            "subscription": sub_path,
            "max_messages": max_messages,
        },
        timeout=timeout,
    )

    ack_ids = [msg.ack_id for msg in response.received_messages]
    if ack_ids:
        subscriber.acknowledge(
            request={"subscription": sub_path, "ack_ids": ack_ids}
        )
    return ack_ids


def _utcnow_rfc3339() -> str:
    import datetime
    return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
