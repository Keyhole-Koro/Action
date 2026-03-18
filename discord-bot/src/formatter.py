"""Discord messages → Markdown formatter."""

from __future__ import annotations

import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import discord


def message_to_line(msg: "discord.Message") -> str:
    ts = msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
    author = str(msg.author)
    content = msg.content.replace("\n", "  \n")
    return f"**[{ts}] {author}**: {content}"


def messages_to_markdown(
    messages: list["discord.Message"],
    guild_name: str,
    channel_name: str,
) -> str:
    if not messages:
        return ""

    first_ts = messages[0].created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
    last_ts = messages[-1].created_at.strftime("%Y-%m-%dT%H:%M:%SZ")

    lines = [
        f"# Discord Chat Log",
        f"",
        f"- **Guild**: {guild_name}",
        f"- **Channel**: #{channel_name}",
        f"- **Period**: {first_ts} – {last_ts}",
        f"- **Messages**: {len(messages)}",
        f"",
        f"---",
        f"",
    ]
    for msg in messages:
        lines.append(message_to_line(msg))
    return "\n".join(lines) + "\n"
