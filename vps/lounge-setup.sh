#!/usr/bin/env bash
# Installs The Lounge (web IRC client for the phone) as the "thelounge" service on 127.0.0.1:9000. Run as root.
# Version 4.4.3 from npm: 4.5 needs Node 22 (Debian has 20, which Uptime Kuma also uses) and a build step.
# Settings: vps/thelounge-config.js, copied to /etc/thelounge/config.js on every run. Web page: irc.88x31.app (vps/Caddyfile).
# Usage: lounge-setup.sh [NAME]   with NAME, also makes that login; its password is read from /root/lounge-pass
# (repo secret LOUNGE_PASS, put there by vps-tools; never printed). Re-running keeps logins and history.
# Starts it the first time; after a settings change: systemctl restart thelounge
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
V=4.4.3; H=/etc/thelounge
export DEBIAN_FRONTEND=noninteractive
[ "$(thelounge --version 2>/dev/null | tail -n 1)" = "v$V" ] || npm install -g --omit dev --no-audit --no-fund "thelounge@$V" >/dev/null 2>&1
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
systemctl is-active -q thelounge || systemctl start thelounge
echo "thelounge: $(systemctl is-active thelounge)"
