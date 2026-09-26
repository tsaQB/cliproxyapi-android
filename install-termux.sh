#!/bin/sh
# ==============================================================================
# CLIProxyAPI Termux Installer Alias
# Delegates to the primary install.sh
# ==============================================================================
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/install.sh" ]; then
    exec "$SCRIPT_DIR/install.sh" "$@"
fi

SH_BIN=$(command -v bash 2>/dev/null || command -v sh 2>/dev/null || echo "sh")
curl -fsSL https://raw.githubusercontent.com/tsaQB/cliproxyapi-android/main/install.sh | "$SH_BIN" -s -- "$@"
exit $?
