#!/usr/bin/env bash
# Installs the log web page (vps/logweb.py) as service "logweb" on port 80. Run as root.
# Arg 1: "salt:sha256hex" password hash (the password itself is never sent here). Re-running is safe.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
D=/home/tf2/logweb
mkdir -p $D
install -o tf2 -g tf2 -m 755 /root/logweb.py $D/logweb.py
if [ -n "${1:-}" ]; then printf '%s\n' "$1" > $D/pass.hash; chown tf2:tf2 $D/pass.hash; chmod 600 $D/pass.hash; fi
[ -s $D/pass.hash ] || { echo "no password hash yet"; exit 1; }
cat > /etc/systemd/system/logweb.service <<EOF
[Unit]
Description=88x31 log web page
After=network.target

[Service]
User=tf2
ExecStart=/usr/bin/python3 $D/logweb.py 80 $D/pass.hash
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=5
MemoryMax=150M
CPUWeight=20

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable logweb >/dev/null 2>&1
systemctl restart logweb
if command -v ufw >/dev/null && ufw status | grep -q active; then ufw allow 80/tcp >/dev/null; echo "ufw: 80/tcp allowed"; fi
sleep 2
systemctl is-active logweb
curl -s -o /dev/null -w "local test: HTTP %{http_code} (401 = asks for password, good)\n" http://127.0.0.1/ || true
