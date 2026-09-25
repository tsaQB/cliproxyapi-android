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

exec curl -sL https://raw.githubusercontent.com/tsaQB/cliproxyapi-android/main/install.sh | bash "$@"
