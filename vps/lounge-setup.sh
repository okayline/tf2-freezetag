#!/usr/bin/env bash
# Installs The Lounge (web IRC client for the phone) as the "thelounge" service on 127.0.0.1:9000. Run as root.
# Settings: vps/thelounge-config.js (copied in on every run). Web page: irc.88x31.app through Caddy (vps/Caddyfile).
# Usage: lounge-setup.sh [NAME]   with NAME, also makes that login; its password is read from /root/lounge-pass
# (repo secret LOUNGE_PASS, put there by vps-tools; never printed). Re-running updates settings, keeps logins and history.
# Does NOT start or restart anything.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
H=/var/lib/thelounge
export DEBIAN_FRONTEND=noninteractive
command -v thelounge >/dev/null || npm install -g --omit dev --no-audit --no-fund thelounge >/dev/null 2>&1
echo "thelounge $(thelounge --version 2>/dev/null | tail -n 1)"
id thelounge >/dev/null 2>&1 || useradd -r -d $H -s /usr/sbin/nologin thelounge
mkdir -p $H/users
install -m 644 "$HERE/thelounge-config.js" $H/config.js
chown -R thelounge:thelounge $H
if [ -n "${1:-}" ]; then
  N=$(printf '%s' "$1" | tr -cd 'a-zA-Z0-9_-')
  if [ -f "$H/users/$N.json" ]; then echo "login $N: already there"
  elif [ -s /root/lounge-pass ]; then
    sudo -u thelounge env THELOUNGE_HOME=$H thelounge add "$N" --password "$(cat /root/lounge-pass)" --save-logs >/dev/null && echo "login $N: made (password not shown)"
  else echo "login $N: no /root/lounge-pass (add repo secret LOUNGE_PASS)"; fi
fi
cat > /etc/systemd/system/thelounge.service <<UNIT
[Unit]
Description=The Lounge (web IRC client)
After=network-online.target sbbs.service

[Service]
User=thelounge
Environment=THELOUNGE_HOME=$H
ExecStart=$(command -v thelounge) start
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable thelounge >/dev/null 2>&1
echo "Installed. Start with: systemctl start thelounge"
