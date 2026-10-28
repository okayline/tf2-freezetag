#!/usr/bin/env bash
# Installs Uptime Kuma (newest 2.x release) as the "uptime-kuma" service on 127.0.0.1:3001. Run as root. Re-running only checks the service.
# The web page is reached through Caddy (status.88x31.app in vps/Caddyfile). The first visit asks you to make the admin login.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
URL=https://github.com/louislam/uptime-kuma.git
D=/home/tf2/uptime-kuma
apt-get install -y -qq nodejs npm git >/dev/null
echo "node $(node -v), npm $(npm -v)"
if [ ! -d "$D/.git" ]; then
  TAG=$(git ls-remote --tags --refs "$URL" | sed 's|.*/||' | grep -E '^2\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
  [ -n "$TAG" ] || { echo "no 2.x release found"; exit 1; }
  echo "installing Uptime Kuma $TAG"
  sudo -u tf2 git clone -q --depth 1 --branch "$TAG" "$URL" "$D"
  sudo -u tf2 bash -c "cd '$D' && npm install --omit dev --no-audit --no-fund >/dev/null 2>&1 && npm run download-dist >/dev/null 2>&1"
fi
cat > /etc/systemd/system/uptime-kuma.service <<UNIT
[Unit]
Description=Uptime Kuma
After=network-online.target

[Service]
User=tf2
WorkingDirectory=$D
Environment=UPTIME_KUMA_HOST=127.0.0.1
Environment=UPTIME_KUMA_PORT=3001
ExecStart=/usr/bin/node server/server.js
Restart=always
MemoryMax=400M
CPUWeight=20

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now uptime-kuma >/dev/null 2>&1
sleep 8
echo "uptime-kuma: $(systemctl is-active uptime-kuma); listening on 3001: $(ss -tln | grep -c ':3001 ')"
