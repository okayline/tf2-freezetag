#!/usr/bin/env bash
# Installs the OpenRA Red Alert dedicated server. Service "openra", port 1234/tcp, listed on the public
# OpenRA server list. The server needs no original game files.
# Safe to re-run: fetches the latest release and updates the service. Does NOT start/restart it.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
U=tf2; D=/home/$U/openra

echo "== OpenRA Red Alert (latest release) =="
REL=$(curl -fsS -m 20 https://api.github.com/repos/OpenRA/OpenRA/releases/latest)
TAG=$(printf '%s' "$REL" | python3 -c 'import json,sys;print(json.load(sys.stdin)["tag_name"])')
URL=$(printf '%s' "$REL" | python3 -c 'import json,sys;print([a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"]=="OpenRA-Red-Alert-x86_64.AppImage"][0])')
echo "$TAG"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
curl -fsSL -m 300 -o "$T/ra.AppImage" "$URL"
chmod +x "$T/ra.AppImage"
(cd "$T" && ./ra.AppImage --appimage-extract >/dev/null)
rm -rf "$D.new"; mv "$T/squashfs-root" "$D.new"
rm -rf "$D"; mv "$D.new" "$D"
echo "$TAG" > "$D/VERSION"
chown -R $U:$U "$D"

cat > /etc/systemd/system/openra.service <<S
[Unit]
Description=OpenRA Red Alert dedicated server
After=network-online.target

[Service]
User=$U
WorkingDirectory=$D
ExecStart=$D/usr/bin/openra-ra-server Server.Name="88x31 | Red Alert | US West" Server.ListenPort=1234 Server.AdvertiseOnline=True Server.RequireAuthentication=False Server.EnableSingleplayer=False
Restart=always
RestartSec=10
Nice=5
MemoryMax=400M

[Install]
WantedBy=multi-user.target
S
systemctl daemon-reload
systemctl enable openra >/dev/null 2>&1
echo "Installed $TAG. Start with: systemctl start openra"
