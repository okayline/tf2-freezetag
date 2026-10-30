#!/usr/bin/env bash
# Installs WeeChat (always connected to the BBS's IRC server, running inside tmux as the "weechat" service) and two ways in:
#   - Glowing Bear, WeeChat's web page, at irc.88x31.app (WeeChat's relay on 127.0.0.1:9001; vps/Caddyfile)
#   - the real terminal WeeChat in the browser at irc.88x31.app/term (ttyd attaches to the tmux session; Caddy asks for a
#     login first: user "kura", the same password as the relay)
# Replaces The Lounge: removes it if it is still installed (its old settings and logs are kept once in /root/thelounge-old.tgz).
# Run as root, from the repo's vps folder or anywhere. The password is read from /root/weechat-pass (repo secret LOUNGE_PASS,
# put there by vps-tools' run action; never printed). Re-running updates Glowing Bear and re-applies the settings below; every
# other WeeChat setting you change in the app is kept. Restarts weechat and ttyd (not a game server).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
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
apt-get install -y -qq weechat-curses weechat-headless weechat-core tmux >/dev/null
echo "weechat $(weechat --version 2>/dev/null | head -n 1), $(tmux -V)"
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
# ipv6 off: with it on (the default), WeeChat refuses the IPv4 address 127.0.0.1 and the relay never listens
CMDS="/set relay.network.ipv6 off;/set relay.network.bind_address \"127.0.0.1\";/set relay.network.password \"$P\""
CMDS="$CMDS;/set relay.network.websocket_allowed_origins \"^https://irc.88x31.app$\";/relay add weechat 9001"
CMDS="$CMDS;/server add 88x31 127.0.0.1/6667 -notls;/set $S.tls off;/set $S.nicks \"$NICK\";/set $S.username \"$USERNAME\""
CMDS="$CMDS;/set $S.realname \"$REALNAME\";/set $S.autoconnect on;/set $S.autojoin \"$CHANNELS\";/save;/quit"
systemctl stop weechat >/dev/null 2>&1 || true
# a one-off WeeChat on the same folder applies the settings and saves them (the service must be stopped: one WeeChat per folder)
sudo -u weechat timeout 60 weechat-headless --dir $D --run-command "$CMDS" >/dev/null 2>&1 || true
echo "relay: $(grep -c '^weechat = 9001' $D/relay.conf 2>/dev/null) port 9001, password $(grep -q '^password = "..*"' $D/relay.conf 2>/dev/null && echo set || echo MISSING) (not shown)"
echo "server: $(grep -c "^88x31\.addresses = \"127.0.0.1/6667\"" $D/irc.conf 2>/dev/null) 88x31 at 127.0.0.1/6667, nick $(grep -o '^88x31\.nicks = "[^"]*"' $D/irc.conf 2>/dev/null | cut -d'"' -f2)"

echo "== terminal WeeChat (tmux) =="
# tmux: no prefix key (WeeChat uses Ctrl-B and other keys itself), no status bar, the window follows the newest client's size
cat > /etc/weechat-tmux.conf <<'CONF'
set -g prefix None
unbind-key C-b
set -g status off
set -g window-size latest
set -g escape-time 0
set -g default-terminal "tmux-256color"
set -sa terminal-features ",xterm-256color:RGB"
CONF
cat > /etc/systemd/system/weechat.service <<UNIT
[Unit]
Description=WeeChat in tmux (IRC client; relay for Glowing Bear; terminal for ttyd)
After=network-online.target sbbs.service

[Service]
Type=forking
User=weechat
Environment=LANG=C.UTF-8
ExecStart=$(command -v tmux) -u -f /etc/weechat-tmux.conf -L weechat new-session -d -s weechat $(command -v weechat) --dir $D
ExecStop=-$(command -v tmux) -L weechat kill-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

echo "== web terminal (ttyd) =="
# ttyd is not in Debian 13: the release binary, pinned and checked against its published SHA-256
TV=1.7.7; TSUM=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55
if [ "$(ttyd --version 2>/dev/null | awk '{print $3}' | cut -d- -f1)" != "$TV" ]; then
  curl -fsSL -m 120 -o /tmp/ttyd.new "https://github.com/tsl0922/ttyd/releases/download/$TV/ttyd.x86_64" \
    && echo "$TSUM  /tmp/ttyd.new" | sha256sum -c - >/dev/null && install -m 755 /tmp/ttyd.new /usr/local/bin/ttyd; rm -f /tmp/ttyd.new
fi
echo "ttyd $(ttyd --version 2>/dev/null)"
# the terminal's look: ttyd's own page with a starfield behind a see-through terminal (vps/ttyd-space.html). The stock page is
# read from a throwaway ttyd (so it matches this ttyd version and the /term base path), then patched. Without it, plain ttyd.
TOPTS=""
if [ -s "$HERE/ttyd-space.html" ]; then
  ttyd -i /tmp/ttyd-stock.sock -b /term true >/dev/null 2>&1 & TP=$!
  sleep 2
  if curl -fsS --compressed -m 15 --unix-socket /tmp/ttyd-stock.sock http://localhost/term/ -o /tmp/ttyd-stock.html 2>/dev/null && grep -q "</head>" /tmp/ttyd-stock.html; then
    python3 - "$HERE/ttyd-space.html" <<'PYX'
import sys
s = open("/tmp/ttyd-stock.html", encoding="utf-8").read()
css = open(sys.argv[1], encoding="utf-8").read()
open("/etc/ttyd-index.html", "w", encoding="utf-8").write(s.replace("</head>", css + "</head>", 1))
PYX
    chmod 644 /etc/ttyd-index.html
    TOPTS="-I /etc/ttyd-index.html -t allowTransparency=true -t 'theme={\"background\":\"rgba(0,0,0,0.28)\"}'"
    echo "ttyd page: starfield"
  else echo "ttyd page: could not read the stock page, plain look"; fi
  kill $TP 2>/dev/null || true; rm -f /tmp/ttyd-stock.sock /tmp/ttyd-stock.html
fi
# ttyd listens on a socket only Caddy (group caddy) can reach, never on a port: nothing else on the VPS can type into WeeChat
cat > /etc/systemd/system/ttyd.service <<UNIT
[Unit]
Description=ttyd (WeeChat in the browser: irc.88x31.app/term; Caddy asks for the login)
After=weechat.service
Wants=weechat.service

[Service]
User=weechat
Group=caddy
UMask=0007
RuntimeDirectory=ttyd
RuntimeDirectoryMode=0750
Environment=LANG=C.UTF-8
ExecStart=/usr/local/bin/ttyd -i /run/ttyd/ttyd.sock -b /term -W -O $TOPTS -t fontSize=15 -t cursorBlink=true -t titleFixed=WeeChat $(command -v tmux) -u -L weechat attach -t weechat
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
# the /term part of the site, with its login (a bcrypt hash of /root/weechat-pass; this file stays on the server). The Caddyfile
# imports it; without the file /term does not exist, so it can never be open without a login.
mkdir -p /etc/caddy/irc-term
H=$(caddy hash-password --plaintext "$(cat /root/weechat-pass)")
cat > /etc/caddy/irc-term/term.caddy <<SNIP
redir /term /term/
handle /term/* {
	basicauth {
		kura $H
	}
	reverse_proxy unix//run/ttyd/ttyd.sock
}
SNIP
chown root:caddy /etc/caddy/irc-term/term.caddy; chmod 640 /etc/caddy/irc-term/term.caddy

systemctl daemon-reload
systemctl enable weechat ttyd >/dev/null 2>&1
systemctl start weechat
sleep 3
systemctl restart ttyd
if caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1; then systemctl reload caddy && echo "caddy: reloaded"; else echo "caddy: config did not validate, not reloaded"; fi
echo "weechat: $(systemctl is-active weechat), relay listening: $(ss -ltnH '( sport = :9001 )' | wc -l), ttyd: $(systemctl is-active ttyd)"
