#!/usr/bin/env bash
# Root half of the uninstaller. Charging thresholds stay as they were last set;
# change them in System Settings > Power Management if needed.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then echo "uninstall-service.sh must run as root" >&2; exit 1; fi
systemctl disable --now battery-mode.service 2>/dev/null || true
rm -f /etc/systemd/system/battery-mode.service /etc/battery-mode.conf /usr/local/bin/battery-mode-daemon
rm -rf /var/lib/battery-mode
systemctl daemon-reload
echo "battery-mode service removed"
