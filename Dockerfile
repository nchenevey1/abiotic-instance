FROM tsxcloud/steamcmd-wine-ntsync:10.12-arm64-box

# Install dependencies for SteamCMD (Linux)
RUN apt-get update && \
    apt-get install -y curl tar ca-certificates lib32gcc-s1 && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user if missing
RUN id -u steam >/dev/null 2>&1 || useradd -m -d /home/steam -s /bin/bash steam

# Setup directories
RUN mkdir -p /home/steam/abiotic /home/steam/steamcmd && chown -R steam:steam /home/steam

# Install Linux SteamCMD
WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chown -R steam:steam /home/steam/steamcmd

USER steam
WORKDIR /home/steam

ENV SERVER_DIR=/home/steam/abiotic
ENV STEAMCMD_DIR=/home/steam/steamcmd

COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

ENTRYPOINT ["/home/steam/entrypoint.sh"]
