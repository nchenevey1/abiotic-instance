#!/usr/bin/env bash
set -euo pipefail

ulimit -n 1048576 || true

# ---- Box64 safer defaults ----
export BOX64_DYNAREC_BIGBLOCK=1
export BOX64_DYNAREC_SAFEFLAGS=0
export BOX64_DYNAREC_STRONGMEM=0
export BOX64_DYNAREC_FASTROUND=0
export BOX64_DYNAREC_FASTNAN=0
export BOX64_DYNAREC_X87DOUBLE=1

# ---- Wine paths & prefix ----
export WINE_FOR_SERVER="/usr/local/bin/wine"
export WINEPREFIX="/home/steam/.wine"
export WINEARCH="win64"
mkdir -p "$WINEPREFIX"

INSTALL_DIR="${SERVER_DIR:-/home/steam/abiotic}"
STEAMCMD_DIR="${STEAMCMD_DIR:-/home/steam/steamcmd}"
BACKUP_DIR="/backups"

mkdir -p "$INSTALL_DIR" "$STEAMCMD_DIR" "$BACKUP_DIR"

echo "Using WINE_FOR_SERVER=$WINE_FOR_SERVER"
echo "WINEPREFIX=$WINEPREFIX  WINEARCH=$WINEARCH"

# ---- Behavior toggles ----
UPDATE_ON_START="${UPDATE_ON_START:-0}"
VALIDATE="${VALIDATE:-0}"
BACKUP_ON_START="${BACKUP_ON_START:-0}"
BACKUP_KEEP="${BACKUP_KEEP:-7}"

# ---- Launch params ----
PORT="${PORT:-7777}"
QUERY_PORT="${QUERY_PORT:-27015}"
MAX_PLAYERS="${MAX_PLAYERS:-6}"
SERVER_NAME="${SERVER_NAME:-\"Abiotic Factor Server\"}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"
WORLD_SAVE_NAME="${WORLD_SAVE_NAME:-}"
SANDBOX_INI_PATH="${SANDBOX_INI_PATH:-}"

# ---------------- helpers ----------------
do_update() {
  echo "Running SteamCMD (Windows) update..."

  # Convert Linux path to Wine Z: drive path
  # e.g., /home/steam/abiotic -> Z:\home\steam\abiotic
  local win_install_dir="Z:${INSTALL_DIR//\//\\}"
  
  local args=( +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir "$win_install_dir" +app_update 2857200 )
  [ "$VALIDATE" = "1" ] && args+=( validate )
  args+=( +quit )

  # up to 3 attempts
  for attempt in 1 2 3; do
    echo "Update attempt #$attempt..."
    set +e
    
    # Run Windows SteamCMD via Wine
    "$WINE_FOR_SERVER" "$STEAMCMD_DIR/steamcmd.exe" "${args[@]}" 2>&1 | tee /tmp/steamcmd_attempt.log

    local rc=${PIPESTATUS[0]}
    set -e

    if [ $rc -eq 0 ]; then
       echo "SteamCMD update succeeded."
       return 0
    fi

    echo "Update failed (rc=$rc). Retrying in 5s..."
    sleep 5
  done

  echo "SteamCMD update failed after retries."
  exit 1
}

timestamp() { date -u +"%Y%m%d-%H%M%S"; }

do_backup() {
  # Back up worlds & server config; exclude logs
  local exe root stamp out world
  exe="$(find "$INSTALL_DIR" -type f -name 'AbioticFactorServer-Win64-Shipping.exe' | head -n1 || true)"
  root="$(dirname "$exe")/../.." || true
  root="$(readlink -f "$root" || echo "$INSTALL_DIR")"
  world="${WORLD_SAVE_NAME:-World}"
  stamp="$(timestamp)"
  out="${BACKUP_DIR}/abiotic-${world}-${stamp}.tgz"

  echo "Creating backup: $out"
  tar -C "$root" -czf "$out" \
      --exclude="*.log" \
      Saved/SaveGames/Server \
      Saved/Config/WindowsServer 2>/dev/null || true

  # rotate
  ls -1t "$BACKUP_DIR"/abiotic-*.tgz 2>/dev/null | tail -n +$((BACKUP_KEEP+1)) | xargs -r rm -f
  echo "Backup complete."
}

launch_server() {
  local server_exe
  server_exe="$(find "$INSTALL_DIR" -type f -name 'AbioticFactorServer-Win64-Shipping.exe' | head -n1 || true)"
  if [ -z "$server_exe" ]; then
    echo "ERROR: Server exe not found in $INSTALL_DIR"
    exit 1
  fi

  local bin dir saved_path extra
  bin="$(dirname "$server_exe")"
  dir="$(readlink -f "$bin/../..")"
  saved_path="$dir/Saved"
  [ -L "$saved_path" ] && rm -f "$saved_path"   # ensure real dir, not symlink
  mkdir -p "$saved_path"

  extra="-log -newconsole -useperfthreads -MaxServerPlayers=${MAX_PLAYERS} -PORT=${PORT} -QueryPort=${QUERY_PORT}"
  [ -n "$SERVER_PASSWORD" ]  && extra="$extra -ServerPassword=${SERVER_PASSWORD}"
  [ -n "$SERVER_NAME" ]      && extra="$extra -SteamServerName=${SERVER_NAME}"
  [ -n "$WORLD_SAVE_NAME" ]  && extra="$extra -WorldSaveName=${WORLD_SAVE_NAME}"
  [ -n "$SANDBOX_INI_PATH" ] && extra="$extra -SandboxIniPath=${SANDBOX_INI_PATH}"

  echo "Server exe : $server_exe"
  echo "Server root: $dir"
  echo "Saved path : $saved_path"
  echo "Launching with ports: game=$PORT, query=$QUERY_PORT"

  exec "$WINE_FOR_SERVER" "$server_exe" $extra
}

# ---------------- arg parsing ----------------
MODE="${1:-run}"     # run | --update-only | --backup-only
case "$MODE" in
  --update-only)
    do_update
    exit 0
    ;;
  --backup-only)
    do_backup
    exit 0
    ;;
  run|*)
    [ "$UPDATE_ON_START" = "1" ] && do_update
    [ "$BACKUP_ON_START" = "1" ] && do_backup
    launch_server
    ;;
esac
