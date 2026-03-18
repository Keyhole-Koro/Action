"""In-memory message buffer, partitioned by (guild_id, channel_id)."""

from __future__ import annotations

import threading
from collections import defaultdict
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import discord

ChannelKey = tuple[int, int]  # (guild_id, channel_id)


class MessageBuffer:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._buckets: dict[ChannelKey, list["discord.Message"]] = defaultdict(list)

    def add(self, message: "discord.Message") -> None:
        if message.guild is None:
            return  # Guild channels only; ignore DMs
        key: ChannelKey = (message.guild.id, message.channel.id)
        with self._lock:
            self._buckets[key].append(message)

    def flush(self) -> dict[ChannelKey, list["discord.Message"]]:
        """Atomically drain and return all buffered messages."""
        with self._lock:
            flushed = dict(self._buckets)
            self._buckets = defaultdict(list)
        return flushed
