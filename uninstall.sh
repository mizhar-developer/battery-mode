#!/usr/bin/env bash
# Removes the widget (current user) and the background service (system-wide).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$here/plasmoid/metadata.json")
if [ "$(id -u)" -eq 0 ]; then echo "Run uninstall.sh as your normal desktop user, not as root." >&2; exit 1; fi

kpackagetool6 -t Plasma/Applet -r "$id" 2>/dev/null || true
if command -v pkexec >/dev/null && [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    pkexec "$here/daemon/uninstall-service.sh"
else
    sudo "$here/daemon/uninstall-service.sh"
fi
echo "Battery Mode removed. Log out and back in if the icon lingers in the tray."
