#!/usr/bin/env bash
# Installs the public stats page (vps/stats.py): a systemd timer rebuilds /var/www/stats/index.html every 5 minutes
# from the game logs (and a live RCON look at each server). Caddy serves that folder as stats.88x31.app (vps/Caddyfile).
# Run as root. Re-running is safe. Needs /root/stats.py and /root/discord-status.py (stats.py borrows its RCON code).
# Players in /home/tf2/leaderboard-ignore.txt are left out, like on the leaderboards.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

A=/home/tf2/stats-app
W=/var/www/stats
mkdir -p $A $W
install -o tf2 -g tf2 -m 755 /root/stats.py $A/stats.py
install -o tf2 -g tf2 -m 755 /root/discord-status.py $A/discord-status.py
chown tf2:tf2 $A $W
chmod 755 $W /var/www

cat > /etc/systemd/system/stats.service <<UNIT
[Unit]
Description=Rebuild the public stats page

[Service]
Type=oneshot
User=tf2
ExecStart=/usr/bin/python3 -I $A/stats.py $W/index.html /home/tf2/leaderboard-ignore.txt 7
Nice=15
UNIT
cat > /etc/systemd/system/stats.timer <<UNIT
[Unit]
Description=Rebuild the public stats page every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now stats.timer >/dev/null 2>&1
systemctl start stats.service || true
sleep 3
ls -la $W/index.html
systemctl is-active stats.timer
