import os
import asyncio
import discord
from discord import app_commands
from discord.ext import commands
import logging

# Configuration
TOKEN = os.environ.get("DISCORD_TOKEN")
SERVER_DIR = os.environ.get("SERVER_DIR", "/abiotic") # Default to container path if mapped
COMPOSE_CMD = os.environ.get("COMPOSE", "docker-compose")
GUILD_ID = os.environ.get("GUILD_ID")

# Parse allowed user IDs safely
raw_ids = os.environ.get("ALLOWED_USER_IDS", "")
ALLOWED_USERS = set()
for x in raw_ids.split(','):
    if x.strip().isdigit():
        ALLOWED_USERS.add(int(x.strip()))

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("AbioticBot")

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

def is_authorized(interaction: discord.Interaction) -> bool:
    if not ALLOWED_USERS:
        return True # Open to everyone if no IDs defined (Caution!)
    return interaction.user.id in ALLOWED_USERS

async def run_shell(cmd: str, cwd: str = None):
    logger.info(f"Executing: {cmd} in {cwd}")
    try:
        proc = await asyncio.create_subprocess_shell(
            cmd, cwd=cwd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT
        )
        stdout, _ = await proc.communicate()
        output = stdout.decode('utf-8', errors='replace').strip()
        return proc.returncode, output
    except Exception as e:
        return 1, str(e)

@bot.event
async def on_ready():
    logger.info(f"Logged in as {bot.user} (ID: {bot.user.id})")
    try:
        if GUILD_ID:
            guild = discord.Object(id=int(GUILD_ID))
            bot.tree.copy_global_to(guild=guild)
            await bot.tree.sync(guild=guild)
            logger.info(f"Commands synced to guild {GUILD_ID}")
        else:
            await bot.tree.sync()
            logger.info("Commands synced globally")
        
        # Set activity
        await bot.change_presence(activity=discord.Activity(type=discord.ActivityType.watching, name="Abiotic Factor"))
    except Exception as e:
        logger.error(f"Sync error: {e}")

@bot.tree.command(description="Start the server")
async def up(interaction: discord.Interaction):
    if not is_authorized(interaction):
        return await interaction.response.send_message("Unauthorized", ephemeral=True)
    
    await interaction.response.defer(ephemeral=True)
    rc, out = await run_shell(f"{COMPOSE_CMD} up -d", SERVER_DIR)
    
    await interaction.followup.send(f"**Up Command** (Exit: {rc})\n```\n{out[-1900:]}\n```")

@bot.tree.command(description="Stop the server")
async def down(interaction: discord.Interaction):
    if not is_authorized(interaction):
        return await interaction.response.send_message("Unauthorized", ephemeral=True)
    
    await interaction.response.defer(ephemeral=True)
    rc, out = await run_shell(f"{COMPOSE_CMD} down", SERVER_DIR)
    await interaction.followup.send(f"**Down Command** (Exit: {rc})\n```\n{out[-1900:]}\n```")

@bot.tree.command(description="Restart the server")
async def restart(interaction: discord.Interaction):
    if not is_authorized(interaction):
        return await interaction.response.send_message("Unauthorized", ephemeral=True)

    await interaction.response.defer(ephemeral=True)
    rc, out = await run_shell(f"{COMPOSE_CMD} restart", SERVER_DIR)
    await interaction.followup.send(f"**Restart Command** (Exit: {rc})\n```\n{out[-1900:]}\n```")

@bot.tree.command(description="Check container status")
async def status(interaction: discord.Interaction):
    if not is_authorized(interaction):
        return await interaction.response.send_message("Unauthorized", ephemeral=True)

    await interaction.response.defer(ephemeral=True)
    rc, out = await run_shell(f"{COMPOSE_CMD} ps", SERVER_DIR)
    await interaction.followup.send(f"**Status**\n```\n{out[-1900:]}\n```")

@bot.tree.command(description="Get recent server logs")
async def logs(interaction: discord.Interaction, lines: int = 20):
    if not is_authorized(interaction):
        return await interaction.response.send_message("Unauthorized", ephemeral=True)

    await interaction.response.defer(ephemeral=True)
    # 'lines' constrained to avoid huge messages
    if lines > 50: lines = 50
    
    rc, out = await run_shell(f"{COMPOSE_CMD} logs --tail {lines}", SERVER_DIR)
    await interaction.followup.send(f"**Logs (Last {lines})**\n```\n{out[-1900:]}\n```")

if __name__ == "__main__":
    if not TOKEN:
        logger.error("DISCORD_TOKEN is missing")
        exit(1)
    bot.run(TOKEN)
