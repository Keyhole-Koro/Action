"""Direct Firestore writer for individual Discord messages."""
from __future__ import annotations
import logging
import discord
from google.cloud import firestore

log = logging.getLogger(__name__)
_client: firestore.Client | None = None


def _get_client(project_id: str) -> firestore.Client:
    global _client
    if _client is None:
        _client = firestore.Client(project=project_id)
    return _client


def _channel_type(channel) -> str:
    if isinstance(channel, discord.Thread):
        return "thread"
    return "text"


def save_message(message: discord.Message, workspace_id: str, project_id: str) -> None:
    """Write a single Discord message directly to Firestore."""
    channel = message.channel

    if isinstance(channel, discord.Thread):
        thread_id = str(channel.id)
        thread_name = channel.name
        parent = channel.parent
        channel_id = str(parent.id) if parent else None
        channel_name = parent.name if parent else None
    else:
        thread_id = None
        thread_name = None
        channel_id = str(channel.id)
        channel_name = getattr(channel, "name", str(channel.id))

    cat = getattr(channel, "category", None)
    if cat is None and hasattr(channel, "parent"):
        cat = getattr(channel.parent, "category", None)

    doc = {
        "message_id": str(message.id),
        "workspace_id": workspace_id,
        "guild_id": str(message.guild.id),
        "guild_name": message.guild.name,
        "category_id": str(cat.id) if cat else None,
        "category_name": cat.name if cat else None,
        "channel_id": channel_id,
        "channel_name": channel_name,
        "thread_id": thread_id,
        "thread_name": thread_name,
        "channel_type": _channel_type(channel),
        "author_id": str(message.author.id),
        "author_name": str(message.author),
        "content": message.content,
        "timestamp": message.created_at.isoformat(),
        "created_at": firestore.SERVER_TIMESTAMP,
    }

    _get_client(project_id).collection(
        f"workspaces/{workspace_id}/discord_messages"
    ).document(str(message.id)).set(doc)

    log.debug("stored message_id=%s channel=%s", message.id, channel_name or thread_name)