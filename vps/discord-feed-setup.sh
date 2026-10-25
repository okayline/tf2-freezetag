#!/usr/bin/env bash
# Installs the live TF2 feed (chat, kills, joins and leaves, round wins, map changes) to Discord:
# vps/discord-feed.py as an always-on systemd service. Run as root. Re-running is safe.
# Needs /home/tf2/discord/discord-status.py from discord-status-setup.sh (it shares that script's helpers).
#
# The feed channel's webhook link is NOT in the repo. Put it, on one line, in:
#   /home/tf2/discord/tf2-feed.url
# The RCON password is read from the server's own server.cfg.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

D=/home/tf2/discord
[ -f "$D/discord-status.py" ] || { echo "Run discord-install first."; exit 1; }
install -o tf2 -g tf2 -m 755 /root/discord-feed.py "$D/discord-feed.py"

cat > /etc/systemd/system/discord-feed-tf2.service <<EOF
[Unit]
Description=TF2 live feed to Discord (chat, kills, joins)
After=network.target

[Service]
User=tf2
ExecStart=/usr/bin/python3 $D/discord-feed.py "88x31 Freeze Tag (TF2)" 27015 /home/tf2/server/tf/cfg/server.cfg $D/tf2-feed.url 27115
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if [ -s "$D/tf2-feed.url" ]; then
  systemctl enable discord-feed-tf2.service >/dev/null 2>&1
  systemctl restart discord-feed-tf2.service
  echo "tf2-feed.url: found, feed started"
else
  echo "tf2-feed.url: NOT there yet (feed not started)"
fi
systemctl is-active discord-feed-tf2.service || true
