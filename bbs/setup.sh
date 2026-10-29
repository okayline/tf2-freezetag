#!/usr/bin/env bash
# Installs the 88x31 BBS: Synchronet (built from source) with NetHack as a door game.
# Service "sbbs". Telnet on port 23, browser terminal on port 8023. Mail and FTP are off.
# Takes a while (Synchronet builds from source on one core). Safe to re-run: rebuilds and keeps the BBS data.
# Does NOT start/restart it.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
U=bbs; D=/sbbs; NAME="88x31 BBS"

echo "== packages =="
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential git pkgconf perl python3 zip unzip \
  libncursesw5-dev libnspr4-dev libarchive-dev nethack-console >/dev/null
id $U >/dev/null 2>&1 || useradd -r -m -d $D -s /usr/sbin/nologin $U

echo "== Synchronet (build) =="
mkdir -p $D; cd $D
if [ "${SKIPBUILD:-}" != 1 ]; then
curl -fsSL -m 60 -o install-sbbs.mk https://gitlab.synchro.net/main/sbbs/-/raw/master/install/install-sbbs.mk
nice -n 10 make -f install-sbbs.mk SBBSDIR=$D SBBSUSER=$U SBBSGROUP=$U NOCAP=1 >$D/build.log 2>&1 \
  || { tail -n 30 $D/build.log; exit 1; }
tail -n 2 $D/build.log
fi

echo "== settings =="
# sbbs.ini: telnet 23, web 8023 (browser terminal), no mail/FTP, run as $U
python3 - $D/ctrl/sbbs.ini <<'PY'
import re,sys
f=sys.argv[1];t=open(f).read()
def setk(sec,key,val):
    global t
    m=re.search(r'(?ms)^\[%s\][^\n]*$(.*?)(?=^\[|\Z)'%re.escape(sec),t)
    body=m.group(1)
    if re.search(r'(?mi)^\s*%s\s*='%key,body): body=re.sub(r'(?mi)^(\s*)%s\s*=.*$'%key,r'\g<1>%s = %s'%(key,val),body,count=1)
    else: body='\n\t%s = %s'%(key,val)+body
    t=t[:m.start(1)]+body+t[m.end(1):]
setk('BBS','TelnetPort','23'); setk('BBS','RLoginPort','0'); setk('BBS','SSHPort','0')
setk('Mail','AutoStart','false'); setk('FTP','AutoStart','false')
setk('Web','Port','8023'); setk('Web','TLS_Port','0')
setk('UNIX','User','bbs'); setk('UNIX','Group','bbs')
open(f,'w').write(t)
PY
sed -i -E "s/^(\s*name\s*=).*/\1 $NAME/" $D/ctrl/main.ini
# browser terminal behind Caddy (bbs.88x31.app): over https it connects to wss on 443
grep -q '^\s*wssp\s*=' $D/ctrl/modopts.ini || sed -i -E '/^\[web\]/a\    wssp=443' $D/ctrl/modopts.ini
# system password (needed to create the sysop account): from repo secret BBS_SYSPASS, put in /root/bbs-syspass by vps-tools
if [ -s /root/bbs-syspass ]; then python3 -c 'import re,sys;p=open("/root/bbs-syspass").read().strip();f=sys.argv[1];t=open(f).read();open(f,"w").write(re.sub(r"(?m)^password=.*$",lambda m:"password="+p,t,count=1))' $D/ctrl/main.ini; echo "system password set (not shown)"; fi

# NetHack door (flag values read from this build's own headers)
H=$D/repo/src/sbbs3/sbbsdefs.h
flag() { grep -E "^#define[[:space:]]+$1[[:space:]]" $H | head -1 | sed -E 's/.*\(1 *<< *([0-9]+)\).*/$((1<<\1))/' | sed -E 's/^\$\(\((.*)\)\)$/\1/'; }
S=$(( $(flag XTRN_MULTIUSER) | $(flag XTRN_ANSI) | $(flag XTRN_NATIVE) | $(flag XTRN_STDIO) ))
X=$D/ctrl/xtrn.ini
if ! grep -qi '^\[prog:.*NETHACK\]' $X; then
  SEC=GAMES; grep -q '^\[sec:GAMES\]' $X || SEC=MAIN
  cat >> $X <<X

[prog:$SEC.NETHACK]
	name = NetHack
	cmd = /usr/games/nethack -u %a
	settings = $S
	type = 0
	event = 0
	ars =
X
  echo "NetHack door added to section $SEC (settings $S)"
fi

# web page: full-width layout, big terminal (no sidebar on the home page), Fullscreen button
sed -i -E 's/^(\s*layout_full_width\s*=).*/\1true/' $D/ctrl/modopts.ini
H=$(ls -d $D/webv4/pages/000-home.xjs 2>/dev/null || true)
if [ -n "$H" ]; then
  [ -f $D/webv4-home.xjs.bak ] && cp $D/webv4-home.xjs.bak "$H" || cp "$H" $D/webv4-home.xjs.bak
  cat > /tmp/bigterm.html <<'X'
<!-- bigterm -->
<style>
#sidebar{display:none}
body{background:#000;color:#ccc}
.col-sm-9{width:100%}
.fTelnetContainer{width:100%}
#ftwrap,#fTelnetContainer,#fTelnetContainer *{overflow:hidden !important;overscroll-behavior:contain}
#ftwrap:fullscreen{background:#000;display:flex;align-items:center;justify-content:center}
</style>
<script>
(function(){
 function pos(){
  var w=document.getElementById('ftwrap'),c=document.getElementById('fTelnetContainer'),f=w&&w.querySelector('button');
  var cv=c&&c.querySelector('canvas'); if(!f||!cv)return;
  var W=w.getBoundingClientRect(),V=cv.getBoundingClientRect();
  f.style.right=(W.right-V.right+10)+'px'; f.style.bottom=(W.bottom-V.bottom+10)+'px';
 }
 window.addEventListener('resize',pos); document.addEventListener('fullscreenchange',pos); setInterval(pos,1000);
})();
</script>
<!-- end bigterm -->
X
  sed -i '/<!-- fTelnet -->/r /tmp/bigterm.html' "$H"
  sed -i 's#<div id="fTelnetContainer" class="fTelnetContainer"></div>#<div id="ftwrap" style="position:relative"><div id="fTelnetContainer" class="fTelnetContainer"></div><button title="Fullscreen" style="position:absolute;right:12px;bottom:10px;background:none;border:none;padding:0;color:\#ddd;font-size:20px;line-height:1;opacity:.6;cursor:pointer;z-index:5" onclick="var e=document.getElementById(\x27ftwrap\x27);(e.requestFullscreen||e.webkitRequestFullscreen).call(e)">\xe2\x9b\xb6</button></div>#' "$H"
  rm -f /tmp/bigterm.html
fi
chown -R $U:$U $D
# the web site (browser terminal) needs a Guest account
(cd $D/exec && sudo -u $U env SBBSCTRL=$D/ctrl ./jsexec -n makeguest.js 2>&1 | tail -n 1) || true
chmod g+s /usr/games/nethack 2>/dev/null || true

cat > /etc/systemd/system/sbbs.service <<S
[Unit]
Description=88x31 BBS (Synchronet)
After=network-online.target

[Service]
User=$U
Group=$U
AmbientCapabilities=CAP_NET_BIND_SERVICE
WorkingDirectory=$D/ctrl
Environment=SBBSCTRL=$D/ctrl
ExecStart=$D/exec/sbbs nd
Restart=always
RestartSec=10
Nice=5
MemoryMax=300M

[Install]
WantedBy=multi-user.target
S
systemctl daemon-reload
systemctl enable sbbs >/dev/null 2>&1
command -v ufw >/dev/null && ufw status | grep -q active && { ufw allow 23/tcp >/dev/null; ufw allow 8023/tcp >/dev/null; }
echo "Installed. Start with: systemctl start sbbs   (then: telnet <host> 23, or http://<host>:8023 in a browser)"
