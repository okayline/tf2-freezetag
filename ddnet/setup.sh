#!/usr/bin/env bash
# Installs or updates the DDNet (DDRace) server in /home/tf2/ddnet and the "ddnet" service (UDP 8303).
# Run as root:  curl -fsSL https://raw.githubusercontent.com/okayline/tf2-freezetag/main/ddnet/setup.sh | bash
# Safe to re-run: updates DDNet to the newest release and copies ddnet/autoexec_server.cfg from the repo.
# Does NOT start or restart the server.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
U=tf2; D=/home/$U/ddnet; RAW=https://raw.githubusercontent.com/okayline/tf2-freezetag/${REF:-main}/ddnet   # REF=<commit> skips GitHub's few-minute cache
VER=$(curl -fsS https://ddnet.org/downloads/ | grep -oE 'DDNet-[0-9.]+-linux_x86_64\.tar\.xz' | sort -uV | tail -1)
[ -n "$VER" ] || { echo "Could not find the DDNet download."; exit 1; }
echo "== $VER =="
T=$(mktemp -d); curl -fsSL -o "$T/dd.tar.xz" "https://ddnet.org/downloads/$VER"
tar -xJf "$T/dd.tar.xz" -C "$T"; mkdir -p "$D/logs"
cp -a "$T"/DDNet-*/. "$D"/; rm -rf "$T"
# DDNet reads data/autoexec_server.cfg (its own default lives there), so ours replaces it
curl -fsSL -o "$D/data/autoexec_server.cfg" "$RAW/autoexec_server.cfg"; rm -f "$D/autoexec_server.cfg"
chown -R $U:$U "$D"
cat > /etc/systemd/system/ddnet.service <<UNIT
[Unit]
Description=DDNet (DDRace) server
After=network-online.target

[Service]
User=$U
WorkingDirectory=$D
ExecStart=$D/DDNet-Server
Restart=on-failure
RestartSec=15
Nice=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
if command -v ufw >/dev/null && ufw status | grep -q active; then ufw allow 8303/udp >/dev/null; echo "port opened"; fi
echo "installed: $(ls "$D" | grep -c .) files, maps: $(ls "$D/data/maps" 2>/dev/null | tr '\n' ' ')"
echo "Not started. Start with: systemctl enable --now ddnet"
