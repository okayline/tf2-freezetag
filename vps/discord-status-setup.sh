#!/usr/bin/env bash
# Installs the Discord status poster on the VPS: vps/discord-status.py plus a systemd timer that runs it
# every minute for the TF2 and L4D1 servers (each edits one Discord message through a webhook).
# Run as root. Re-running is safe.
#
# The webhook links are NOT in the repo. Put each one on the VPS, on one line, in:
#   /home/tf2/discord/tf2.url   (the TF2 channel's webhook)
#   /home/tf2/discord/l4d.url   (the L4D1 channel's webhook)
#   /home/tf2/discord/l4db.url and l4dc.url   (the Versus server's and the ViNtaGe Edition server's channels; the discord-urls-install action writes them from GitHub secrets)
# The RCON passwords are read from each server's own server.cfg.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

D=/home/tf2/discord
mkdir -p "$D"
install -o tf2 -g tf2 -m 755 /root/discord-status.py "$D/discord-status.py"
chown tf2:tf2 "$D"
chmod 700 "$D"

PY="/usr/bin/python3 $D/discord-status.py"
cat > /etc/systemd/system/discord-status.service <<EOF
[Unit]
Description=Post game server status to Discord

[Service]
Type=oneshot
User=tf2
ExecStart=-$PY "88x31 Freeze Tag (TF2)" 27015 /home/tf2/server/tf/cfg/server.cfg $D/tf2.url $D/tf2.msg
ExecStart=-$PY "88x31 Left 4 Dead" 27016 /home/tf2/l4d/left4dead/cfg/server.cfg $D/l4d.url $D/l4d.msg
ExecStart=-$PY "88x31 L4D Versus" 27017 /home/tf2/l4d-b/left4dead/cfg/server.cfg $D/l4db.url $D/l4db.msg
ExecStart=-$PY "88x31 L4D ViNtaGe Edition" 27018 /home/tf2/l4d-c/left4dead/cfg/server.cfg $D/l4dc.url $D/l4dc.msg
EOF

cat > /etc/systemd/system/discord-status.timer <<EOF
[Unit]
Description=Post game server status to Discord every minute

[Timer]
OnBootSec=30
OnUnitActiveSec=60
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now discord-status.timer >/dev/null 2>&1
for f in tf2.url l4d.url l4db.url l4dc.url; do
  [ -s "$D/$f" ] && echo "$f: found" || echo "$f: NOT there yet"
done
systemctl is-active discord-status.timer
