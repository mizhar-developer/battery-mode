#!/usr/bin/env bash
# Root half of the installer: puts the daemon and its systemd unit in place.
# Usage (as root): install-service.sh <desktop-user>
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
owner=${1:-}
if [ "$(id -u)" -ne 0 ]; then echo "install-service.sh must run as root" >&2; exit 1; fi
if [ -z "$owner" ] || ! id "$owner" >/dev/null 2>&1; then echo "usage: $0 <desktop-user>" >&2; exit 1; fi

install -m 755 "$here/battery-mode-daemon" /usr/local/bin/battery-mode-daemon
install -m 644 "$here/battery-mode.service" /etc/systemd/system/battery-mode.service
printf 'BATTERY_MODE_OWNER=%s\n' "$owner" > /etc/battery-mode.conf
install -d -m 755 /var/lib/battery-mode
[ -e /var/lib/battery-mode/mode ] || printf 'off' > /var/lib/battery-mode/mode
chown "$owner" /var/lib/battery-mode/mode
chmod 664 /var/lib/battery-mode/mode

systemctl daemon-reload
systemctl enable battery-mode.service >/dev/null
systemctl restart battery-mode.service
echo "battery-mode service installed and running (mode file writable by $owner)"
