FROM python:3.11-slim

# Install only curl (to download binaries)
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Install Docker Client (Static Binary for ARM64)
RUN curl -fsSL https://download.docker.com/linux/static/stable/aarch64/docker-27.1.1.tgz -o docker.tgz && \
    tar xzvf docker.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm docker.tgz

# Install Docker Compose (Standalone for ARM64)
RUN curl -L "https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir discord.py

COPY bot.py .

CMD ["python", "bot.py"]