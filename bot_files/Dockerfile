FROM python:3.11-slim

# Install Docker CLI and Docker Compose
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    curl -L "https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies directly
RUN pip install discord.py

COPY bot.py .

CMD ["python", "bot.py"]
