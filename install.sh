#!/bin/sh
# ==============================================================================
# CLIProxyAPI Termux Native Installer (Android Non-Root ARM64)
# Distribution by tsaQB/cliproxyapi-android
# ==============================================================================
set -eu

C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"

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

printf "%b====================================================%b\n" "${C_CYAN}" "${C_RESET}"
printf "%b    CLIProxyAPI Termux Native Installer (ARM64)     %b\n" "${C_CYAN}" "${C_RESET}"
printf "%b====================================================%b\n" "${C_CYAN}" "${C_RESET}"

# 1. Validasi Arsitektur CPU
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    printf "%b❌ Error: Arsitektur CPU adalah %s. Installer ini khusus untuk ARM64 (aarch64).%b\n" "${C_RED}" "$ARCH" "${C_RESET}" >&2
    exit 1
fi
printf "%b✔ Arsitektur kompatibel: %s%b\n" "${C_GREEN}" "$ARCH" "${C_RESET}"

# 2. Periksa & Pasang Dependensi
printf "%b📦 Memeriksa dependensi sistem (curl, tar, jq)...%b\n" "${C_YELLOW}" "${C_RESET}"
need_pkg=""
command -v curl >/dev/null 2>&1 || need_pkg="$need_pkg curl"
command -v tar >/dev/null 2>&1 || need_pkg="$need_pkg tar"
command -v jq >/dev/null 2>&1 || need_pkg="$need_pkg jq"

if [ -n "$need_pkg" ]; then
    printf "%bMenginstall paket yang belum ada:%s...%b\n" "${C_YELLOW}" "$need_pkg" "${C_RESET}"
    pkg update -y >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    pkg install -y $need_pkg
fi
printf "%b✔ Semua dependensi siap.%b\n" "${C_GREEN}" "${C_RESET}"

# 3. Buat Struktur Direktori
printf "%b📁 Menyiapkan struktur direktori...%b\n" "${C_YELLOW}" "${C_RESET}"
mkdir -p "${BIN_DIR}" "${AUTH_DIR}" "${LOG_DIR}" "${STATIC_DIR}"

# 4. Hentikan service lama jika sedang berjalan
if pgrep -f "${BIN_PATH}" >/dev/null 2>&1; then
    printf "%b🛑 Menghentikan proses CLIProxyAPI yang sedang aktif...%b\n" "${C_YELLOW}" "${C_RESET}"
    pkill -f "${BIN_PATH}" || true
    sleep 1
fi

# 5. Unduh Bundle Rilis Native Android (dari tsaQB/cliproxyapi-android)
printf "%b🔍 Mengambil informasi rilis terbaru dari repo tsaQB/cliproxyapi-android...%b\n" "${C_YELLOW}" "${C_RESET}"
LATEST_TAG=$(curl -sL https://api.github.com/repos/tsaQB/cliproxyapi-android/releases/latest | jq -r '.tag_name // empty' 2>/dev/null || true)
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v7.3.17"
fi

TAR_URL="https://github.com/tsaQB/cliproxyapi-android/releases/latest/download/cliproxyapi-android-arm64.tar.gz"
TMP_TAR="${PREFIX_DIR}/tmp/cpa-android-arm64.tar.gz"
TMP_EXTRACT="${PREFIX_DIR}/tmp/cpa_extracted_termux"
mkdir -p "$(dirname "$TMP_TAR")" "$TMP_EXTRACT"

printf "%b⬇ Mengunduh bundle native Android (%s)...%b\n" "${C_CYAN}" "$LATEST_TAG" "${C_RESET}"
if ! curl -L --progress-bar "$TAR_URL" -o "$TMP_TAR"; then
    printf "%b⚠️  Gagal mengunduh tarball, mencoba fallback dari zip...%b\n" "${C_YELLOW}" "${C_RESET}"
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
printf "%b✔ Binary Android Bionic (Native DNS) & Dashboard berhasil dipasang.%b\n" "${C_GREEN}" "${C_RESET}"

# 6. Konfigurasi config.yaml
if [ -f "${CONFIG_FILE}" ]; then
    printf "%bℹ️  File config.yaml lama ditemukan. Membuat backup di config.yaml.bak...%b\n" "${C_YELLOW}" "${C_RESET}"
    cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak"
fi

printf "%b⚙️  Membuat konfigurasi config.yaml (Password: admin123)...%b\n" "${C_YELLOW}" "${C_RESET}"
RANDOM_KEY=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')

cat << EOF > "${CONFIG_FILE}"
# CLIProxyAPI Configuration untuk Termux (Android Native)
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
printf "%b✔ Konfigurasi siap dengan default password: %badmin123%b\n" "${C_GREEN}" "${C_CYAN}" "${C_RESET}"

# 7. Buat Launcher Wrapper di $PREFIX/bin/cliproxyapi
printf "%b🔗 Membuat perintah CLI 'cliproxyapi'...%b\n" "${C_YELLOW}" "${C_RESET}"
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
      echo "⚠️  CLIProxyAPI sudah berjalan (PID: $(pgrep -f "$BIN" | head -n 1))."
      exit 0
    fi
    echo "🚀 Menjalankan CLIProxyAPI di background..."
    setsid "$BIN" -config "$CONFIG" < /dev/null > "$LOG_FILE" 2>&1 &
    sleep 1
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      echo "✅ CLIProxyAPI aktif!"
      echo "🔗 Endpoint : http://127.0.0.1:8317"
      echo "🌐 Dashboard: http://127.0.0.1:8317/management.html"
    else
      echo "❌ Gagal menjalankan. Periksa log: $LOG_FILE"
    fi
    ;;
  stop)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      pkill -f "$BIN"
      echo "🛑 CLIProxyAPI berhasil dimatikan."
    else
      echo "ℹ️  CLIProxyAPI tidak sedang berjalan."
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
      echo "🔄 CLIProxyAPI berhasil di-restart."
      echo "🌐 Dashboard: http://127.0.0.1:8317/management.html"
    else
      echo "❌ Gagal me-restart. Cek log: $LOG_FILE"
    fi
    ;;
  status)
    if pgrep -f "$BIN" >/dev/null 2>&1; then
      PID=$(pgrep -f "$BIN" | head -n 1)
      echo "🟢 CLIProxyAPI sedang aktif (PID: $PID)"
      echo "🔗 Server URL : http://127.0.0.1:8317"
      echo "🌐 Dashboard  : http://127.0.0.1:8317/management.html"
    else
      echo "🔴 CLIProxyAPI sedang nonaktif."
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
      echo "Perintah CLIProxyAPI Termux:"
      echo "  cliproxyapi start      - Jalankan di background"
      echo "  cliproxyapi stop       - Matikan service"
      echo "  cliproxyapi restart    - Restart service"
      echo "  cliproxyapi status     - Periksa status service"
      echo "  cliproxyapi logs       - Pantau live log"
      echo "  cliproxyapi run        - Jalankan foreground di terminal"
      echo "  cliproxyapi <options>  - Jalankan CLI bawaan (misal -h, -antigravity-login)"
      exit 0
    fi
    exec "$BIN" -config "$CONFIG" "$@"
    ;;
esac
EOF
chmod 755 "${WRAPPER_PATH}"
printf "%b✔ Wrapper berhasil dibuat di %s%b\n" "${C_GREEN}" "${WRAPPER_PATH}" "${C_RESET}"

printf "\n%b====================================================%b\n" "${C_GREEN}" "${C_RESET}"
printf "%b       🎉 INSTALASI SELESAI DENGAN SUKSES!          %b\n" "${C_GREEN}" "${C_RESET}"
printf "%b====================================================%b\n" "${C_GREEN}" "${C_RESET}"
printf "📁 Folder Data : %b%s%b\n" "${C_CYAN}" "${BASE_DIR}" "${C_RESET}"
printf "⚙️  Config File : %b%s%b\n" "${C_CYAN}" "${CONFIG_FILE}" "${C_RESET}"
printf "🌐 Dashboard   : %bhttp://127.0.0.1:8317/management.html%b\n" "${C_CYAN}" "${C_RESET}"
printf "🔑 Password    : %badmin123%b\n" "${C_YELLOW}" "${C_RESET}"
printf "🗝️  API Key     : %b%s%b\n" "${C_YELLOW}" "${RANDOM_KEY}" "${C_RESET}"
printf "\nPerintah Cepat:\n"
printf "  • %bcliproxyapi start%b    (Nyalakan)\n" "${C_CYAN}" "${C_RESET}"
printf "  • %bcliproxyapi status%b   (Cek Status)\n" "${C_CYAN}" "${C_RESET}"
printf "  • %bcliproxyapi logs%b     (Lihat Log)\n" "${C_CYAN}" "${C_RESET}"
printf "  • %bcliproxyapi stop%b     (Matikan)\n" "${C_CYAN}" "${C_RESET}"
printf "%b====================================================%b\n\n" "${C_GREEN}" "${C_RESET}"
