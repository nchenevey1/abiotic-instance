# Abiotic Factor Dedicated Server on Oracle Cloud (ARM64)

This project allows you to run an **Abiotic Factor** dedicated server on an Oracle Cloud "Always Free" Ampere A1 instance (ARM64).

# Server Setup

## Prerequisites
- **Oracle Cloud Account** with an Ampere A1 Compute Instance (4 OCPUs, 24GB RAM recommended).
- **System Tools** (Git, Docker).

### System Setup (Oracle Linux)
Run these commands on your instance to install the necessary tools:
```bash
# Install Git
sudo dnf install -y git

# Install Docker
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start Docker and enable it on boot
sudo systemctl start docker
sudo systemctl enable docker

# (Optional) Allow running docker without sudo
sudo usermod -aG docker $USER
# You will need to logout and log back in for this to take effect
```

## Installation

### 1. Clone the Files
SSH into your Oracle Cloud instance:
```bash
git clone <your-repo-url> abiotic-server
cd abiotic-server
```

### 2. Configure the Server
Edit `docker-compose.yml`:
```bash
nano docker-compose.yml
```
- **SERVER_PASSWORD**: Change to a secure password.
- **SERVER_NAME**: Name your server.
- **WORLD_SAVE_NAME**: Name of your save file.

### 3. Configure Firewall
You must allow traffic on UDP ports 7777 and 27015 in the **Oracle Cloud Console** -> **Networking** -> **Security** -> **Security Lists**.

### 4. Start the Server
```bash
docker-compose up --build -d
```
*Note: The first start will take 5-10 minutes to download the game files.*

## Directory Structure
- `data/`: Contains world saves.
- `server/`: Game files.
- `backups/`: Auto-generated backups.
- `steam/`: Steam logs/cache.

---

# Discord Bot Setup (Optional)

A helper bot to Start/Stop/Restart the server and view logs from Discord.
*Note: The bot runs in its own container but controls the server via the Docker socket.*

## Bot Installation

### 1. Configure Bot
Navigate to `bot_files/` and create your config:
```bash
cd bot_files
nano .env
```
- **DISCORD_TOKEN**: Your bot token.
- **ALLOWED_USER_IDS**: Comma-separated Discord User IDs (for security).
- **SERVER_DIR**: Set this to the **full path** of your project on the host (e.g., `/home/opc/abiotic-server`).

### 2. Build & Run Bot
* Return to the main directory and run the bot.
* **Crucial**: You must mount the current directory using `$(pwd)` so the bot sees the exact same path as the host.

```bash
# Go back to project root
cd ..

# Build the bot image
docker build -t abiotic-bot ./bot_files

# Run the bot
docker run -d --name abiotic-bot \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):$(pwd) \
  --env-file ./bot_files/.env \
  abiotic-bot
```

## Bot Commands
- `/up`: Start the server
- `/down`: Stop the server
- `/restart`: Restart the server
- `/status`: Check container status
- `/logs`: View recent server logs

## Manual Control
If you need to control the server or bot without Discord:

### Server Control
- **Start**: `docker-compose up -d`
- **Stop**: `docker-compose down`
- **Restart**: `docker-compose restart`
- **Logs**: `docker-compose logs -f`

### Bot Control
- **Start**: `docker start abiotic-bot`
- **Stop**: `docker stop abiotic-bot`
- **Logs**: `docker logs -f abiotic-bot`
