"""Write a flushed batch as Markdown to GCS and return the GCS URI."""

from __future__ import annotations

import datetime
import hashlib
import os
import uuid

from google.cloud import storage


def _storage_client() -> storage.Client:
    emulator_host = os.environ.get("STORAGE_EMULATOR_HOST", "")
    if emulator_host:
        # google-cloud-storage respects STORAGE_EMULATOR_HOST automatically,
        # but we also set the API endpoint for older SDK versions.
        return storage.Client(
            client_options={"api_endpoint": emulator_host},
        )
    return storage.Client()


def write_batch(
    content: str,
    guild_id: int,
    guild_name: str,
    channel_id: int,
    channel_name: str,
    bucket_name: str,
) -> tuple[str, str]:
    """
    Upload *content* to GCS.

    Returns:
        (gcs_uri, sha256hex)
    """
    client = _storage_client()
    bucket = client.bucket(bucket_name)

    date_str = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    batch_id = uuid.uuid4().hex[:8]
    blob_name = f"discord/{guild_id}/{channel_id}/{date_str}_{batch_id}.md"

    encoded = content.encode("utf-8")
    sha256 = hashlib.sha256(encoded).hexdigest()

    blob = bucket.blob(blob_name)
    blob.upload_from_string(
        encoded,
        content_type="text/markdown",
    )

    gcs_uri = f"gs://{bucket_name}/{blob_name}"
    return gcs_uri, sha256
