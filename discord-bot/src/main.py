"""Discord Bot - writes each message directly to Firestore. No buffering, no flush."""
from __future__ import annotations
import logging
import os
import discord
from message_store import save_message

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)


def _require(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        raise RuntimeError(f"Required env var not set: {name}")
    return val


TOKEN = _require("DISCORD_BOT_TOKEN")
GUILD_IDS = {int(g) for g in _require("DISCORD_GUILD_IDS").split(",") if g.strip()}
PROJECT_ID = _require("GOOGLE_CLOUD_PROJECT")
WORKSPACE_ID = os.environ.get("WORKSPACE_ID", "default")

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)


@client.event
async def on_ready() -> None:
    log.info("Discord bot ready. user=%s guilds=%s", client.user, list(GUILD_IDS))


@client.event
async def on_message(message: discord.Message) -> None:
    if message.author.bot:
        return
    if message.guild is None or message.guild.id not in GUILD_IDS:
        return
    if not message.content.strip():
        return
    try:
        save_message(message, WORKSPACE_ID, PROJECT_ID)
        log.info(
            "stored message guild=%s channel=%s author=%s",
            message.guild.name,
            getattr(message.channel, "name", message.channel.id),
            message.author,
        )
    except Exception:
        log.exception("Failed to store message id=%s", message.id)


if __name__ == "__main__":
    client.run(TOKEN)