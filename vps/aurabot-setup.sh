#!/usr/bin/env bash
# Installs AuraBot (vps/aurabot.py): the game servers' live feeds on the BBS's IRC server (#tf2-freezetag, #l4d-classic,
# #l4d-vs, #l4d-vintage), as the always-on "aurabot" service run by the tf2 user. Run as root from the repo's vps folder.
# It uses the Discord feed's code (discord-feed-l4d.py and discord-status.py, copied next to it), so both feeds match.
# Admin commands: private messages to AuraBot after "login <password>" (see aurabot.py). The Discord feeds keep running alongside. Re-running updates the files and restarts AuraBot (never a game server).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
D=/home/tf2/aurabot
install -d -o tf2 -g tf2 $D
for f in aurabot.py discord-feed-l4d.py discord-status.py; do install -o tf2 -g tf2 -m 755 "$HERE/$f" "$D/$f"; done
# the admin login password (repo secret AURABOT_PASS, put in /root/aurabot-pass by vps-tools); only the tf2 user can read it
if [ -s /root/aurabot-pass ]; then install -o tf2 -g tf2 -m 600 /root/aurabot-pass $D/admin-pass; echo "admin password: set (not shown)"
else echo "admin password: none yet (add repo secret AURABOT_PASS); admin login is off"; fi
cat > /etc/systemd/system/aurabot.service <<EOF
[Unit]
Description=AuraBot: game feeds on the BBS's IRC server
After=network.target sbbs.service

[Service]
User=tf2
ExecStart=/usr/bin/python3 $D/aurabot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable aurabot >/dev/null 2>&1
systemctl restart aurabot
sleep 3
echo "aurabot: $(systemctl is-active aurabot)"
journalctl -u aurabot -n 3 --no-pager -o cat
