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
printf "%b     Android & Termux Native Distribution%b\n" "${C_DIM}" "${C_RESET}"
printf "%b              Maintained by tsaQB%b\n\n" "${C_PURPLE}" "${C_RESET}"

# 1. Architecture Check
printf "%b[1/6]%b %b🔍 Checking CPU architecture...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    printf "      %b❌ Unsupported architecture: %s (ARM64 required)%b\n\n" "${C_RED}" "$ARCH" "${C_RESET}" >&2
    exit 1
fi
printf "      %b✔ Compatible CPU: %s (ARM64)%b\n\n" "${C_GREEN}" "$ARCH" "${C_RESET}"

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
printf "      %b✔ Required tools ready (curl, tar, jq)%b\n\n" "${C_GREEN}" "${C_RESET}"

# 3. Directory Setup
printf "%b[3/6]%b %b📁 Preparing workspace directories...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
mkdir -p "${BIN_DIR}" "${AUTH_DIR}" "${LOG_DIR}" "${STATIC_DIR}"

WAS_RUNNING=0
if pgrep -f "${BIN_PATH}" >/dev/null 2>&1; then
    WAS_RUNNING=1
    printf "      %b🛑 Stopping active daemon before upgrade...%b\n" "${C_YELLOW}" "${C_RESET}"
    pkill -f "${BIN_PATH}" || true
    sleep 1
fi
printf "      %b✔ Workspace ready at ~/.cliproxyapi%b\n\n" "${C_GREEN}" "${C_RESET}"

# 4. Fetch Latest Release
printf "%b[4/6]%b %b🌐 Fetching release from GitHub...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
LATEST_TAG=$(curl -sL https://api.github.com/repos/tsaQB/cliproxyapi-android/releases/latest | jq -r '.tag_name // empty' 2>/dev/null || true)
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v7.3.17"
fi
printf "      %b• Release version: %b%s%b\n" "${C_DIM}" "${C_WHITE}" "$LATEST_TAG" "${C_RESET}"

TAR_URL="https://github.com/tsaQB/cliproxyapi-android/releases/latest/download/cliproxyapi-android-arm64.tar.gz"
TMP_TAR="${PREFIX_DIR}/tmp/cpa-android-arm64.tar.gz"
TMP_EXTRACT="${PREFIX_DIR}/tmp/cpa_extracted_termux"
mkdir -p "$(dirname "$TMP_TAR")" "$TMP_EXTRACT"

printf "      %b⬇ Downloading Android Bionic bundle...%b\n" "${C_DIM}" "${C_RESET}"
if ! curl -f -sSL "$TAR_URL" -o "$TMP_TAR"; then
    printf "      %b❌ Failed to download release package. Please check network connection.%b\n\n" "${C_RED}" "${C_RESET}" >&2
    rm -rf "$TMP_TAR" "$TMP_EXTRACT"
    exit 1
fi

tar -xzf "$TMP_TAR" -C "$TMP_EXTRACT"
mv -f "$TMP_EXTRACT/cli-proxy-api" "${BIN_PATH}"
mv -f "$TMP_EXTRACT/management.html" "${DASHBOARD_FILE}"
rm -rf "$TMP_TAR" "$TMP_EXTRACT"

chmod 755 "${BIN_PATH}"
chmod 644 "${DASHBOARD_FILE}"
printf "      %b✔ Android NDK binary & WebUI deployed%b\n\n" "${C_GREEN}" "${C_RESET}"

# 5. Configuration Setup
printf "%b[5/6]%b %b⚙️  Configuring service profile...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
if [ -f "${CONFIG_FILE}" ]; then
    printf "      %b✔ Existing configuration preserved: ~/.cliproxyapi/config.yaml%b\n\n" "${C_GREEN}" "${C_RESET}"
    RANDOM_KEY=$(grep -E '^[[:space:]]*-[[:space:]]*"?[a-zA-Z0-9]+' "${CONFIG_FILE}" 2>/dev/null | head -n 1 | tr -d ' "-' || echo "configured")
    ADMIN_KEY=$(grep -E '^[[:space:]]*secret-key:[[:space:]]*' "${CONFIG_FILE}" 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d '"' || echo "admin123")
else
    RANDOM_KEY=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
    ADMIN_KEY="admin123"
    cat << EOF > "${CONFIG_FILE}"
# CLIProxyAPI Configuration for Android / Termux
host: "0.0.0.0"
port: 8317

api-keys:
  - "${RANDOM_KEY}"

remote-management:
  allow-remote: true
  secret-key: "${ADMIN_KEY}"
  disable-control-panel: false
  panel-github-repository: "https://github.com/router-for-me/Cli-Proxy-API-Management-Center"

auth-dir: "${AUTH_DIR}"
log-level: "info"
logging-to-file: true
logs-max-total-size-mb: 25
usage-statistics-enabled: true

routing:
  strategy: "round-robin"

# Prevent false 429 rate limit triggers from Google Antigravity sensor
antigravity:
  sensitive-words:
    - Nous
    - Research

# Model alias mappings for Hermes tool calling compatibility
oauth-model-alias:
  antigravity:
    - name: "gemini-3.8-flash-high"
      alias: "gemini-3.8-flash"
      fork: true
    - name: "gemini-3.8-flash-high"
      alias: "gemini-3.8-flash-customtools"
      fork: true
EOF
    chmod 600 "${CONFIG_FILE}"
    printf "      %b✔ Config created (Secret: %b%s%b)%b\n\n" "${C_GREEN}" "${C_YELLOW}" "${ADMIN_KEY}" "${C_GREEN}" "${C_RESET}"
fi

# 6. Wrapper Installation
printf "%b[6/6]%b %b🔗 Installing CLI command launcher...%b\n" "${C_CYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
cat << EOF > "${WRAPPER_PATH}"
#!${PREFIX_DIR}/bin/bash
BASE_DIR="\${HOME}/.cliproxyapi"
BIN="\${BASE_DIR}/bin/cli-proxy-api"
CONFIG="\${BASE_DIR}/config.yaml"
LOG_FILE="\${BASE_DIR}/logs/service.log"
export MANAGEMENT_STATIC_PATH="\${BASE_DIR}/static"
export GODEBUG=netdns=cgo

start_daemon() {
  if pgrep -f "\$BIN" >/dev/null 2>&1; then
    echo "⚠️  CLIProxyAPI is already running (PID: \$(pgrep -f "\$BIN" | head -n 1))."
    return 0
  fi
  echo "🚀 Starting CLIProxyAPI background daemon..."
  setsid "\$BIN" -config "\$CONFIG" < /dev/null > "\$LOG_FILE" 2>&1 &
  sleep 1
  if pgrep -f "\$BIN" >/dev/null 2>&1; then
    echo "✅ CLIProxyAPI is running!"
    echo "🔗 Endpoint : http://127.0.0.1:8317"
    echo "🌐 Dashboard: http://127.0.0.1:8317/management.html"
  else
    echo "❌ Failed to start. Check logs: \$LOG_FILE"
    return 1
  fi
}

stop_daemon() {
  if pgrep -f "\$BIN" >/dev/null 2>&1; then
    pkill -f "\$BIN"
    echo "🛑 CLIProxyAPI daemon stopped."
  else
    echo "ℹ️  CLIProxyAPI is not running."
  fi
}

case "\$1" in
  start)
    start_daemon
    ;;
  stop)
    stop_daemon
    ;;
  restart)
    stop_daemon
    sleep 1
    start_daemon
    ;;
  status)
    if pgrep -f "\$BIN" >/dev/null 2>&1; then
      PID=\$(pgrep -f "\$BIN" | head -n 1)
      echo "🟢 CLIProxyAPI is running (PID: \$PID)"
      echo "🔗 Server URL : http://127.0.0.1:8317"
      echo "🌐 Dashboard  : http://127.0.0.1:8317/management.html"
    else
      echo "🔴 CLIProxyAPI is not running."
    fi
    ;;
  logs|log)
    tail -n 50 -f "\$LOG_FILE"
    ;;
  update|upgrade)
    echo "🌐 Checking for latest release on GitHub..."
    TMP_DIR="${PREFIX_DIR}/tmp"
    TMP_TAR="\${TMP_DIR}/cpa_update.tar.gz"
    TMP_EXT="\${TMP_DIR}/cpa_update_ext"
    LATEST_TAG=\$(curl -sL https://api.github.com/repos/tsaQB/cliproxyapi-android/releases/latest | jq -r '.tag_name // empty' 2>/dev/null || true)
    if [ -z "\$LATEST_TAG" ]; then
      LATEST_TAG=\$(curl -sL https://api.github.com/repos/tsaQB/cliproxyapi-android/releases/latest | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)
    fi
    if [ -z "\$LATEST_TAG" ]; then
      LATEST_TAG="latest"
    fi
    echo "⬇ Downloading release \${LATEST_TAG}..."
    TAR_URL="https://github.com/tsaQB/cliproxyapi-android/releases/latest/download/cliproxyapi-android-arm64.tar.gz"
    rm -rf "\$TMP_TAR" "\$TMP_EXT"
    mkdir -p "\$TMP_EXT"
    if ! curl -f -sSL "\$TAR_URL" -o "\$TMP_TAR"; then
      echo "❌ Download failed. Check your network or GitHub rate limits."
      rm -rf "\$TMP_TAR" "\$TMP_EXT"
      exit 1
    fi

    WAS_RUNNING=0
    if pgrep -f "\$BIN" >/dev/null 2>&1; then
      WAS_RUNNING=1
      echo "🛑 Temporarily stopping active daemon for upgrade..."
      stop_daemon
      sleep 1
    fi

    tar -xzf "\$TMP_TAR" -C "\$TMP_EXT"
    mv -f "\$TMP_EXT/cli-proxy-api" "\${BIN}"
    mv -f "\$TMP_EXT/management.html" "\${BASE_DIR}/static/management.html"
    chmod 755 "\${BIN}"
    chmod 644 "\${BASE_DIR}/static/management.html"
    rm -rf "\$TMP_TAR" "\$TMP_EXT"

    echo "✅ CLIProxyAPI updated successfully to \${LATEST_TAG}!"
    if [ "\$WAS_RUNNING" -eq 1 ]; then
      start_daemon
    fi
    ;;
  run)
    shift
    exec "\$BIN" -config "\$CONFIG" "\$@"
    ;;
  *)
    if [ "\$#" -eq 0 ]; then
      echo "CLIProxyAPI Management Commands:"
      echo "  cliproxyapi start      - Launch service in background"
      echo "  cliproxyapi stop       - Stop background service"
      echo "  cliproxyapi restart    - Restart service daemon"
      echo "  cliproxyapi status     - View daemon running status"
      echo "  cliproxyapi logs       - Follow real-time service logs"
      echo "  cliproxyapi update     - Upgrade binary & WebUI to latest release"
      echo "  cliproxyapi run        - Run in foreground console"
      echo "  cliproxyapi <options>  - Pass flags directly (e.g. -h, -antigravity-login)"
      exit 0
    fi
    exec "\$BIN" -config "\$CONFIG" "\$@"
    ;;
esac
EOF
chmod 755 "${WRAPPER_PATH}"
printf "      %b✔ Command 'cliproxyapi' registered in PATH%b\n\n" "${C_GREEN}" "${C_RESET}"

# Restart daemon if it was running before upgrade
if [ "$WAS_RUNNING" -eq 1 ]; then
    printf "      %b🔄 Resuming CLIProxyAPI background daemon...%b\n" "${C_CYAN}" "${C_RESET}"
    setsid "${BIN_PATH}" -config "${CONFIG_FILE}" < /dev/null > "${LOG_DIR}/service.log" 2>&1 &
    sleep 1
    if pgrep -f "${BIN_PATH}" >/dev/null 2>&1; then
        printf "      %b✔ Service daemon resumed successfully%b\n\n" "${C_GREEN}" "${C_RESET}"
    fi
fi

# Final Summary Card
printf "%b────────────────────────────────────────────────────%b\n" "${C_GREEN}" "${C_RESET}"
printf "  %b🎉 Installation Complete!%b\n" "${C_BOLD}" "${C_RESET}"
printf "%b────────────────────────────────────────────────────%b\n\n" "${C_GREEN}" "${C_RESET}"

printf "  %b• WebUI Dashboard%b : %bhttp://127.0.0.1:8317/management.html%b\n" "${C_BOLD}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
printf "  %b• Default Secret%b  : %b%s%b\n" "${C_BOLD}" "${C_RESET}" "${C_YELLOW}" "${ADMIN_KEY}" "${C_RESET}"
printf "  %b• Client API Key%b  : %b%s%b\n" "${C_BOLD}" "${C_RESET}" "${C_WHITE}" "${RANDOM_KEY}" "${C_RESET}"
printf "  %b• Configuration%b   : %b~/.cliproxyapi/config.yaml%b\n\n" "${C_BOLD}" "${C_RESET}" "${C_DIM}" "${C_RESET}"

printf "  %bQuick Start Commands:%b\n" "${C_BOLD}" "${C_RESET}"
printf "    %b$ cliproxyapi start%b   Start service in background\n" "${C_CYAN}" "${C_RESET}"
printf "    %b$ cliproxyapi status%b  Check server status\n" "${C_CYAN}" "${C_RESET}"
printf "    %b$ cliproxyapi logs%b    Stream live logs\n" "${C_CYAN}" "${C_RESET}"
printf "    %b$ cliproxyapi update%b  Upgrade to latest release\n" "${C_CYAN}" "${C_RESET}"
printf "    %b$ cliproxyapi stop%b    Stop background daemon\n\n" "${C_CYAN}" "${C_RESET}"
printf "%b────────────────────────────────────────────────────%b\n\n" "${C_GREEN}" "${C_RESET}"
