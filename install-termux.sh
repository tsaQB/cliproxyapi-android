#!/bin/sh
# ==============================================================================
# CLIProxyAPI for Android (Termux Native Non-Root)
# High-Performance AI Gateway · Distribution by tsaQB/cliproxyapi-android
# ==============================================================================
set -eu

# Color palette
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_PURPLE="\033[1;35m"
C_WHITE="\033[1;37m"

PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
BASE_DIR="${HOME}/.cliproxyapi"
BIN_DIR="${BASE_DIR}/bin"
AUTH_DIR="${BASE_DIR}/auths"
LOG_DIR="${BASE_DIR}/logs"
STATIC_DIR="${BASE_DIR}/static"
CONFIG_FILE="${BASE_DIR}/config.yaml"
BIN_PATH="${BIN_DIR}/cli-proxy-api"
WRAPPER_PATH="${PREFIX_DIR}/bin/cliproxyapi"
DASHBOARD_FILE="${STATIC_DIR}/management.html"

clear 2>/dev/null || true

printf "%b" "${C_CYAN}"
cat << 'EOF'
  ____ _     ___ ____                      _    ____ ___ 
 / ___| |   |_ _|  _ \ _ __ _____  ___   _/ \  |  _ \_ _|
| |   | |    | || |_) | '__/ _ \ \/ / | | / _ \ | |_) | | 
| |___| |___ | ||  __/| | | (_) >  <| |_| / ___ \|  __/| | 
 \____|_____|___|_|   |_|  \___/_/\_\\__, /_/   \_\_|  |___|
                                     |___/                  
EOF
printf "%b" "${C_RESET}"
printf "%b        Android & Termux Native Distribution%b\n" "${C_DIM}" "${C_RESET}"
printf "%b                 Maintained by tsaQB%b\n\n" "${C_PURPLE}" "${C_RESET}"

# 1. Architecture Check
printf "%b[1/6]%b %b🔍 Checking CPU architecture...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    printf "      %b❌ Error: Unsupported architecture '%s'. Only ARM64 (aarch64) is supported.%b\n\n" "${C_RED}" "$ARCH" "${C_RESET}" >&2
    exit 1
fi
printf "      %b✔ Compatible CPU detected: %s (ARM64)%b\n\n" "${C_GREEN}" "$ARCH" "${C_RESET}"

# 2. Dependency Check
printf "%b[2/6]%b %b📦 Verifying system packages...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
need_pkg=""
command -v curl >/dev/null 2>&1 || need_pkg="$need_pkg curl"
command -v tar >/dev/null 2>&1 || need_pkg="$need_pkg tar"
command -v jq >/dev/null 2>&1 || need_pkg="$need_pkg jq"

if [ -n "$need_pkg" ]; then
    printf "      %b⚡ Installing missing dependencies:%s...%b\n" "${C_YELLOW}" "$need_pkg" "${C_RESET}"
    pkg update -y >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    pkg install -y $need_pkg
fi
printf "      %b✔ All required tools are available (curl, tar, jq)%b\n\n" "${C_GREEN}" "${C_RESET}"

# 3. Directory Setup
printf "%b[3/6]%b %b📁 Preparing workspace directories...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
mkdir -p "${BIN_DIR}" "${AUTH_DIR}" "${LOG_DIR}" "${STATIC_DIR}"

if pgrep -f "${BIN_PATH}" >/dev/null 2>&1; then
    printf "      %b🛑 Stopping active CLIProxyAPI daemon before upgrade...%b\n" "${C_YELLOW}" "${C_RESET}"
    pkill -f "${BIN_PATH}" || true
    sleep 1
fi
printf "      %b✔ Base directory ready at: %s%b\n\n" "${C_GREEN}" "${BASE_DIR}" "${C_RESET}"

# 4. Fetch Latest Release
printf "%b[4/6]%b %b🌐 Fetching latest release from GitHub...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
LATEST_TAG=$(curl -sL https://api.github.com/repos/tsaQB/cliproxyapi-android/releases/latest | jq -r '.tag_name // empty' 2>/dev/null || true)
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v7.3.17"
fi
printf "      %b✔ Release version: %b%s%b\n" "${C_GREEN}" "${C_WHITE}" "$LATEST_TAG" "${C_RESET}"

TAR_URL="https://github.com/tsaQB/cliproxyapi-android/releases/latest/download/cliproxyapi-android-arm64.tar.gz"
TMP_TAR="${PREFIX_DIR}/tmp/cpa-android-arm64.tar.gz"
TMP_EXTRACT="${PREFIX_DIR}/tmp/cpa_extracted_termux"
mkdir -p "$(dirname "$TMP_TAR")" "$TMP_EXTRACT"

printf "      %b⬇ Downloading Android Bionic bundle...%b\n" "${C_DIM}" "${C_RESET}"
if ! curl -L --progress-bar "$TAR_URL" -o "$TMP_TAR"; then
    printf "      %b⚠️  Primary tarball download failed, falling back to zip archive...%b\n" "${C_YELLOW}" "${C_RESET}"
    ZIP_FALLBACK="https://github.com/tsaQB/cliproxyapi-android/releases/latest/download/cliproxyapi-magisk.zip"
    TMP_ZIP="${PREFIX_DIR}/tmp/cpa-magisk-fallback.zip"
    curl -L --progress-bar "$ZIP_FALLBACK" -o "$TMP_ZIP"
    unzip -o -q "$TMP_ZIP" bin/cli-proxy-api static/management.html -d "$TMP_EXTRACT"
    mv -f "$TMP_EXTRACT/bin/cli-proxy-api" "${BIN_PATH}"
    mv -f "$TMP_EXTRACT/static/management.html" "${DASHBOARD_FILE}"
    rm -rf "$TMP_ZIP" "$TMP_EXTRACT"
else
    tar -xzf "$TMP_TAR" -C "$TMP_EXTRACT"
    mv -f "$TMP_EXTRACT/cli-proxy-api" "${BIN_PATH}"
    mv -f "$TMP_EXTRACT/management.html" "${DASHBOARD_FILE}"
    rm -rf "$TMP_TAR" "$TMP_EXTRACT"
fi

chmod 755 "${BIN_PATH}"
chmod 644 "${DASHBOARD_FILE}"
printf "      %b✔ Native Android NDK binary & WebUI dashboard deployed%b\n\n" "${C_GREEN}" "${C_RESET}"

# 5. Configuration Setup
printf "%b[5/6]%b %b⚙️ Configuring service profile...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
if [ -f "${CONFIG_FILE}" ]; then
    printf "      %bℹ️  Existing config detected. Backed up to config.yaml.bak%b\n" "${C_YELLOW}" "${C_RESET}"
    cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak"
fi

RANDOM_KEY=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')

cat << EOF > "${CONFIG_FILE}"
# CLIProxyAPI Configuration for Android / Termux
host: "0.0.0.0"
port: 8317

api-keys:
  - "${RANDOM_KEY}"

remote-management:
  allow-remote: true
  secret-key: "admin123"
  disable-control-panel: false
  panel-github-repository: "https://github.com/router-for-me/Cli-Proxy-API-Management-Center"

auth-dir: "${AUTH_DIR}"
log-level: "info"
logging-to-file: true
logs-max-total-size-mb: 25
usage-statistics-enabled: true

routing:
  strategy: "round-robin"
EOF
chmod 600 "${CONFIG_FILE}"
printf "      %b✔ Secure configuration created with secret: %badmin123%b\n\n" "${C_GREEN}" "${C_WHITE}" "${C_RESET}"

# 6. Wrapper Installation
printf "%b[6/6]%b %b🔗 Installing CLI command launcher...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
cat << 'EOF' > "${WRAPPER_PATH}"
#!/data/data/com.termux/files/usr/bin/bash
BASE_DIR="${HOME}/.cliproxyapi"
BIN="${BASE_DIR}/bin/cli-proxy-api"
CONFIG="${BASE_DIR}/config.yaml"
LOG_FILE="${BASE_DIR}/logs/service.log"
export MANAGEMENT_STATIC_PATH="${BASE_DIR}/static"
export GODEBUG=netdns=cgo

case "$1" in
  start)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      echo "⚠️  CLIProxyAPI is already running (PID: $(pgrep -f "$BIN" | head -n 1))."
      exit 0
    fi
    echo "🚀 Starting CLIProxyAPI background daemon..."
    setsid "$BIN" -config "$CONFIG" < /dev/null > "$LOG_FILE" 2>&1 &
    sleep 1
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      echo "✅ CLIProxyAPI is running!"
      echo "🔗 Endpoint : http://127.0.0.1:8317"
      echo "🌐 Dashboard: http://127.0.0.1:8317/management.html"
    else
      echo "❌ Failed to start. Check logs: $LOG_FILE"
    fi
    ;;
  stop)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      pkill -f "$BIN"
      echo "🛑 CLIProxyAPI daemon stopped."
    else
      echo "ℹ️  CLIProxyAPI is not running."
    fi
    ;;
  restart)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      pkill -f "$BIN"
      sleep 1
    fi
    setsid "$BIN" -config "$CONFIG" < /dev/null > "$LOG_FILE" 2>&1 &
    sleep 1
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      echo "🔄 CLIProxyAPI restarted successfully."
      echo "🌐 Dashboard: http://127.0.0.1:8317/management.html"
    else
      echo "❌ Failed to restart. Check logs: $LOG_FILE"
    fi
    ;;
  status)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      PID=$(pgrep -f "$BIN" | head -n 1)
      echo "🟢 CLIProxyAPI is running (PID: $PID)"
      echo "🔗 Server URL : http://127.0.0.1:8317"
      echo "🌐 Dashboard  : http://127.0.0.1:8317/management.html"
    else
      echo "🔴 CLIProxyAPI is not running."
    fi
    ;;
  logs|log)
    tail -n 50 -f "$LOG_FILE"
    ;;
  run)
    shift
    exec "$BIN" -config "$CONFIG" "$@"
    ;;
  *)
    if [ "$#" -eq 0 ]; then
      echo "CLIProxyAPI Management Commands:"
      echo "  cliproxyapi start      - Launch service in background"
      echo "  cliproxyapi stop       - Stop background service"
      echo "  cliproxyapi restart    - Restart service daemon"
      echo "  cliproxyapi status     - View daemon running status"
      echo "  cliproxyapi logs       - Follow real-time service logs"
      echo "  cliproxyapi run        - Run in foreground console"
      echo "  cliproxyapi <options>  - Pass flags directly (e.g. -h, -antigravity-login)"
      exit 0
    fi
    exec "$BIN" -config "$CONFIG" "$@"
    ;;
esac
EOF
chmod 755 "${WRAPPER_PATH}"
printf "      %b✔ Command 'cliproxyapi' registered in %s%b\n\n" "${C_GREEN}" "${WRAPPER_PATH}" "${C_RESET}"

# Final Banner
printf "%b╭─────────────────────────────────────────────────────────────╮%b\n" "${C_GREEN}" "${C_RESET}"
printf "%b│%b               %b🎉 Installation Complete!%b                  %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b├─────────────────────────────────────────────────────────────┤%b\n" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  • %bWebUI Dashboard%b : %bhttp://127.0.0.1:8317/management.html%b   %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_CYAN}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  • %bDefault Secret%b  : %badmin123%b                               %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_YELLOW}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  • %bClient API Key%b  : %b%s%b  %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_WHITE}" "${RANDOM_KEY}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  • %bConfig Path%b     : %b~/.cliproxyapi/config.yaml%b             %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_DIM}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  • %bData Folder%b     : %b~/.cliproxyapi/%b                       %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_DIM}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b├─────────────────────────────────────────────────────────────┤%b\n" "${C_GREEN}" "${C_RESET}"
printf "%b│%b  %bQuick Start Commands:%b                                      %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b    $ %bcliproxyapi start%b      Start service in background      %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_CYAN}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b    $ %bcliproxyapi status%b     Check server status & port       %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_CYAN}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b    $ %bcliproxyapi logs%b       Stream live service logs         %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_CYAN}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b│%b    $ %bcliproxyapi stop%b       Stop background daemon           %b│%b\n" "${C_GREEN}" "${C_RESET}" "${C_CYAN}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
printf "%b╰─────────────────────────────────────────────────────────────╯%b\n\n" "${C_GREEN}" "${C_RESET}"
