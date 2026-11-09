#!/usr/bin/env bash
# Installs the Battery Mode widget for the current user and the background
# service system-wide (asks for the administrator password once).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$here/plasmoid/metadata.json")

if [ "$(id -u)" -eq 0 ]; then echo "Run install.sh as your normal desktop user, not as root." >&2; exit 1; fi
command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not found: is KDE Plasma 6 installed?" >&2; exit 1; }

if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$id"; then
    kpackagetool6 -t Plasma/Applet -u "$here/plasmoid"
else
    kpackagetool6 -t Plasma/Applet -i "$here/plasmoid"
fi

if command -v pkexec >/dev/null && [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    pkexec "$here/daemon/install-service.sh" "$USER"
else
    sudo "$here/daemon/install-service.sh" "$USER"
fi

cat <<MSG

Done. If the widget is not in your system tray yet: right-click the tray,
choose "Configure System Tray...", open "Entries" and set "Battery Mode" to Shown.
MSG
