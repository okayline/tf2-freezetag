#!/usr/bin/env bash
# Installs WeeChat (always connected to the BBS's IRC server, running inside tmux as the "weechat" service) and its ways in:
#   - Weave, WeeChat's web page, at irc.88x31.app (WeeChat's API relay on 127.0.0.1:9002 at /api; vps/Caddyfile)
#     The older relay (127.0.0.1:9001 at /weechat) stays for phone apps like WeeChat Android.
# Replaces The Lounge: removes it if it is still installed (its old settings and logs are kept once in /root/thelounge-old.tgz).
# Run as root, from the repo's vps folder or anywhere. The password is read from /root/weechat-pass (repo secret LOUNGE_PASS,
# put there by vps-tools' run action; never printed). Re-running reinstalls Weave and re-applies the settings below; every
# other WeeChat setting you change in the app is kept. Restarts weechat (not a game server). From a root shell, tmux -L weechat attach shows the real WeeChat.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
D=/var/lib/weechat; WWW=/var/www/weave
# the identity and channels (the same ones The Lounge used)
NICK=okay; USERNAME=kurako; REALNAME=kura
CHANNELS="#88x31,#ops,#tf2-freezetag,#l4d-classic,#l4d-vs,#l4d-vintage"
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

echo "== Weave (web page) =="
# Weave (github.com/rnocx/Weave): three static files, pinned to a reviewed commit and checked against their SHA-256. To update:
# read the new version's weave.js for outside requests, then change WV and the three sums. It talks to WeeChat's API relay
# (127.0.0.1:9002, /api on the site). Its file uploads go to outside services, so they are switched off here (uploadBackend
# 'off'), and Caddy's header only lets the page talk to this site (vps/Caddyfile), so links' images are not loaded either.
WV=b42e7bd10582c5563a7c3578e31e301dbb258a02
WSUMS="715f881de25fe51bd4c90cb7df884e47dd123a28b66ebd140af55d1fec97baf9  index.html
768e36547b2b21984398ed44cd732ec42563d4603450e4c382a00a504633fba0  weave.js
5936e79a3c0c2aa2f510ecb302062127d50820bbda75a6e4503f47c44ee67729  weave.css"
T=$(mktemp -d)
for f in index.html weave.js weave.css; do curl -fsSL -m 60 -o "$T/$f" "https://raw.githubusercontent.com/rnocx/Weave/$WV/$f" || true; done
if (cd "$T" && echo "$WSUMS" | sha256sum -c - >/dev/null 2>&1); then
  sed -i "s|uploadBackend: 'jirafeau',|uploadBackend: 'off',|; s|uploadUrl: 'https://files.interdo.me/',|uploadUrl: '',|" "$T/weave.js"
  grep -q "uploadBackend: 'off'," "$T/weave.js" && echo "weave: uploads off" || echo "weave: WARNING uploads setting not found"
  # no light/dark button in the sidebar (the theme is still chosen in Weave's settings)
  sed -i 's|<button class="icon-btn" id="btnTheme" type="button" title="Toggle theme"></button>|<button class="icon-btn" id="btnTheme" type="button" title="Toggle theme" hidden></button>|' "$T/index.html"
  grep -q 'id="btnTheme" type="button" title="Toggle theme" hidden' "$T/index.html" && echo "weave: theme button hidden" || echo "weave: WARNING theme button not found"
  rm -rf $WWW; mkdir -p $(dirname $WWW); mv "$T" $WWW; chmod -R a+rX $WWW; echo "weave: $WWW (${WV:0:7})"
else rm -rf "$T"; echo "weave: download failed or files changed, kept what was there"; fi
# Glowing Bear (replaced by Weave)
[ -d /var/www/glowing-bear ] && rm -rf /var/www/glowing-bear && echo "glowing bear: removed"

echo "== settings =="
[ -s /root/weechat-pass ] || { echo "no /root/weechat-pass (repo secret LOUNGE_PASS): run this through vps-tools' run action"; exit 1; }
# the password goes inside a quoted /set value, in a list of commands split on ";": escape \ " and ;
P=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[;]/\\&/g' /root/weechat-pass)
S="irc.server.88x31"
# ipv6 off: with it on (the default), WeeChat refuses the IPv4 address 127.0.0.1 and the relay never listens
CMDS="/set relay.network.ipv6 off;/set relay.network.bind_address \"127.0.0.1\";/set relay.network.password \"$P\""
CMDS="$CMDS;/set relay.network.websocket_allowed_origins \"^https://irc.88x31.app$\";/relay add weechat 9001;/relay add api 9002"
CMDS="$CMDS;/server add 88x31 127.0.0.1/6667 -notls;/set $S.tls off;/set $S.nicks \"$NICK\";/set $S.username \"$USERNAME\""
CMDS="$CMDS;/set $S.realname \"$REALNAME\";/set $S.autoconnect on;/set $S.autojoin \"$CHANNELS\""
# history: after a restart each buffer gets back its last 1000 logged lines (WeeChat's default is 20)
CMDS="$CMDS;/set logger.look.backlog 1000"
# AuraBot login on every connect: the password (repo secret AURABOT_PASS, in /root/aurabot-pass) goes into WeeChat's secure data,
# never into a setting. AuraBot only takes a login from someone in one of its channels, so the login waits 5 seconds for autojoin.
if [ -s /root/aurabot-pass ]; then
  A=$(sed -e 's/[;]/\\&/g' /root/aurabot-pass)
  # WeeChat fills in ${...} in startup commands, which would save the password itself in irc.conf; so a placeholder is set
  # here and swapped for the reference ${sec.data.aurabot} in irc.conf below, once this one-off WeeChat has quit
  CMDS="$CMDS;/secure set aurabot $A;/set $S.command \"/wait 5 /msg AuraBot login AURABOT-SECURE-REF\""
else echo "no /root/aurabot-pass (repo secret AURABOT_PASS): AuraBot auto-login left as it was"; fi
# #ops is admins only, and AuraBot needs @ there to keep it so. When AuraBot (re)joins #ops from the VPS itself (host
# bbs.88x31.app, so not someone outside using its name), WeeChat gives it @ back. Placeholders as above: swapped below.
CMDS="$CMDS;/trigger addreplace aurabot_op signal *,irc_in2_join \"OPS-NICK == AuraBot && OPS-HOST =* *@bbs.88x31.app && OPS-CHAN == #ops\" \"\" \"/quote -server 88x31 MODE #ops +o AuraBot\""
CMDS="$CMDS;/save;/quit"
systemctl stop weechat >/dev/null 2>&1 || true
# a one-off WeeChat on the same folder applies the settings and saves them (the service must be stopped: one WeeChat per folder)
sudo -u weechat timeout 60 weechat-headless --dir $D --run-command "$CMDS" >/dev/null 2>&1 || true
echo "relay: $(grep -c '^weechat = 9001' $D/relay.conf 2>/dev/null) port 9001, api relay: $(grep -c '^api = 9002' $D/relay.conf 2>/dev/null) port 9002, password $(grep -q '^password = "..*"' $D/relay.conf 2>/dev/null && echo set || echo MISSING) (not shown)"
echo "server: $(grep -c "^88x31\.addresses = \"127.0.0.1/6667\"" $D/irc.conf 2>/dev/null) 88x31 at 127.0.0.1/6667, nick $(grep -o '^88x31\.nicks = "[^"]*"' $D/irc.conf 2>/dev/null | cut -d'"' -f2)"
sed -i 's|AURABOT-SECURE-REF|${sec.data.aurabot}|' $D/irc.conf 2>/dev/null || true
sed -i 's|OPS-NICK|${nick}|; s|OPS-HOST|${host}|; s|OPS-CHAN|${channel}|' $D/trigger.conf 2>/dev/null || true
echo "#ops op-back trigger: $(grep -c '^aurabot_op\.conditions = "${nick} == AuraBot && ${host} =\* \*@bbs.88x31.app && ${channel} == #ops"' $D/trigger.conf 2>/dev/null)"
echo "auraBot auto-login: $(grep -c '^88x31\.command = "/wait 5 /msg AuraBot login ${sec.data.aurabot}"' $D/irc.conf 2>/dev/null), secure data: $(grep -c '^aurabot = ' $D/sec.conf 2>/dev/null) (not shown), backlog: $(grep -o '^backlog = [0-9]*' $D/logger.conf 2>/dev/null | cut -d' ' -f3)"

echo "== scripts =="
# WeeChat scripts from weechat.org's script library, loaded at start (autoload). Add a file name to the list to add a script.
SCRIPTS="colorize_nicks.py"
install -d -o weechat -g weechat $D/python/autoload
for f in $SCRIPTS; do
  curl -fsSL -m 30 -o $D/python/$f https://weechat.org/files/scripts/$f && ln -sf ../$f $D/python/autoload/$f && echo "script: $f" || echo "script: $f could not be downloaded, kept as is"
done
chown -R weechat:weechat $D/python

echo "== terminal WeeChat (tmux) =="
# tmux (WeeChat needs a terminal; root can attach to it): no prefix key (WeeChat uses Ctrl-B and other keys itself), no status bar, the window follows the newest client's size
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
Description=WeeChat in tmux (IRC client; relays for Weave and phone apps; tmux for a root shell)
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

echo "== web terminal (ttyd, removed) =="
# irc.88x31.app/term is gone: Weave is the web page. Takes ttyd and its login file off the server if they are still there.
if [ -e /etc/systemd/system/ttyd.service ] || [ -e /usr/local/bin/ttyd ] || [ -d /etc/caddy/irc-term ]; then
  systemctl disable --now ttyd >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/ttyd.service /usr/local/bin/ttyd /etc/ttyd-index.html
  rm -rf /etc/caddy/irc-term
  echo "ttyd: removed"
else echo "ttyd: not installed"; fi

systemctl daemon-reload
systemctl enable weechat >/dev/null 2>&1
systemctl start weechat
sleep 3
if caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1; then systemctl reload caddy && echo "caddy: reloaded"; else echo "caddy: config did not validate, not reloaded"; fi
echo "weechat: $(systemctl is-active weechat), relay listening: $(ss -ltnH '( sport = :9001 )' | wc -l), api relay listening: $(ss -ltnH '( sport = :9002 )' | wc -l)"
