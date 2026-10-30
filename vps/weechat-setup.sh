#!/usr/bin/env bash
# Installs WeeChat (headless, always connected to the BBS's IRC server) as the "weechat" service, and Glowing Bear
# (WeeChat's web page) for irc.88x31.app (vps/Caddyfile). Replaces The Lounge: removes it if it is still installed
# (its old settings and logs are kept once in /root/thelounge-old.tgz). Run as root, from the repo's vps folder or anywhere.
# The relay password (what Glowing Bear asks for) is read from /root/weechat-pass (repo secret LOUNGE_PASS, put there by
# vps-tools' run action; never printed). Re-running updates Glowing Bear and re-applies the settings below; every other
# WeeChat setting you change in the app is kept. Restarts weechat (not a game server).
set -euo pipefail
D=/var/lib/weechat; WWW=/var/www/glowing-bear
# the identity and channels (the same ones The Lounge used)
NICK=okay; USERNAME=kurako; REALNAME=kura
CHANNELS="#88x31,#tf2-freezetag,#l4d-classic,#l4d-vs,#l4d-vintage"
export DEBIAN_FRONTEND=noninteractive

echo "== The Lounge (replaced) =="
if [ -d /etc/thelounge ] || systemctl list-unit-files thelounge.service >/dev/null 2>&1; then
  systemctl disable --now thelounge >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/thelounge.service; systemctl daemon-reload
  [ -d /etc/thelounge ] && [ ! -e /root/thelounge-old.tgz ] && tar -czf /root/thelounge-old.tgz -C /etc thelounge && echo "old settings and logs kept in /root/thelounge-old.tgz"
  rm -rf /etc/thelounge /root/lounge-pass
  npm uninstall -g thelounge >/dev/null 2>&1 || true
  id thelounge >/dev/null 2>&1 && userdel thelounge
  echo "the lounge: removed"
else echo "the lounge: not installed"; fi

echo "== WeeChat =="
apt-get install -y -qq weechat-headless weechat-core >/dev/null
echo "weechat $(weechat-headless --version 2>/dev/null | head -n 1)"
id weechat >/dev/null 2>&1 || useradd -r -m -d $D -s /usr/sbin/nologin weechat
mkdir -p $D; chown weechat:weechat $D; chmod 700 $D

echo "== Glowing Bear (web page) =="
T=$(mktemp -d); curl -fsSL -m 120 https://github.com/glowing-bear/glowing-bear/archive/refs/heads/gh-pages.tar.gz | tar -xz -C "$T" --strip-components 1
[ -f "$T/index.html" ] && { rm -rf $WWW; mkdir -p $(dirname $WWW); mv "$T" $WWW; chmod -R a+rX $WWW; echo "glowing bear: $WWW"; } || { rm -rf "$T"; echo "glowing bear: download failed, kept the old one"; }

echo "== settings =="
[ -s /root/weechat-pass ] || { echo "no /root/weechat-pass (repo secret LOUNGE_PASS): run this through vps-tools' run action"; exit 1; }
# the password goes inside a quoted /set value, in a list of commands split on ";": escape \ " and ;
P=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[;]/\\&/g' /root/weechat-pass)
S="irc.server.88x31"
CMDS="/set relay.network.bind_address \"127.0.0.1\";/set relay.network.password \"$P\""
CMDS="$CMDS;/set relay.network.websocket_allowed_origins \"^https://irc.88x31.app$\";/relay add weechat 9001"
CMDS="$CMDS;/server add 88x31 127.0.0.1/6667 -notls;/set $S.tls off;/set $S.nicks \"$NICK\";/set $S.username \"$USERNAME\""
CMDS="$CMDS;/set $S.realname \"$REALNAME\";/set $S.autoconnect on;/set $S.autojoin \"$CHANNELS\";/save;/quit"
systemctl stop weechat >/dev/null 2>&1 || true
# a one-off WeeChat on the same folder applies the settings and saves them (the service must be stopped: one WeeChat per folder)
sudo -u weechat timeout 60 weechat-headless --dir $D --run-command "$CMDS" >/dev/null 2>&1 || true
echo "relay: $(grep -c '^weechat = 9001' $D/relay.conf 2>/dev/null) port 9001, password $(grep -q '^password = "..*"' $D/relay.conf 2>/dev/null && echo set || echo MISSING) (not shown)"
echo "server: $(grep -c "^88x31\.addresses = \"127.0.0.1/6667\"" $D/irc.conf 2>/dev/null) 88x31 at 127.0.0.1/6667, nick $(grep -o '^88x31\.nicks = "[^"]*"' $D/irc.conf 2>/dev/null | cut -d'"' -f2)"

cat > /etc/systemd/system/weechat.service <<UNIT
[Unit]
Description=WeeChat (headless IRC client, relay for Glowing Bear)
After=network-online.target sbbs.service

[Service]
User=weechat
ExecStart=$(command -v weechat-headless) --dir $D
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable weechat >/dev/null 2>&1
systemctl start weechat
sleep 3
echo "weechat: $(systemctl is-active weechat), relay listening: $(ss -ltnH '( sport = :9001 )' | wc -l)"
