#!/usr/bin/env bash
# Installs The Lounge (web IRC client for the phone) from its official .deb: service "thelounge" on 127.0.0.1:9000.
# Run as root. Settings: vps/thelounge-config.js, copied to /etc/thelounge/config.js before the package (which keeps ours).
# Web page: irc.88x31.app through Caddy (vps/Caddyfile). The npm package does not install here (a dependency needs a build).
# Usage: lounge-setup.sh [NAME]   with NAME, also makes that login; its password is read from /root/lounge-pass
# (repo secret LOUNGE_PASS, put there by vps-tools; never printed). Re-running keeps logins and history.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
V=4.5.2; H=/etc/thelounge
export DEBIAN_FRONTEND=noninteractive
mkdir -p $H
install -m 644 "$HERE/thelounge-config.js" $H/config.js
if [ "$(dpkg-query -W -f='${Version}' thelounge 2>/dev/null)" != "$V" ]; then
  curl -fsSL -m 120 -o /tmp/thelounge.deb "https://github.com/thelounge/thelounge/releases/download/v$V/thelounge_${V}_all.deb"
  apt-get install -y -qq -o Dpkg::Options::=--force-confold /tmp/thelounge.deb >/dev/null
  rm -f /tmp/thelounge.deb
fi
echo "thelounge $(dpkg-query -W -f='${Version}' thelounge)"
if [ -n "${1:-}" ]; then
  N=$(printf '%s' "$1" | tr -cd 'a-zA-Z0-9_-')
  if [ -f "$H/users/$N.json" ]; then echo "login $N: already there"
  elif [ -s /root/lounge-pass ]; then
    sudo -u thelounge env THELOUNGE_HOME=$H thelounge add "$N" --password "$(cat /root/lounge-pass)" --save-logs >/dev/null && echo "login $N: made (password not shown)"
  else echo "login $N: no /root/lounge-pass (add repo secret LOUNGE_PASS)"; fi
fi
systemctl enable thelounge >/dev/null 2>&1
echo "Installed. The package starts it; after a settings change: systemctl restart thelounge"
