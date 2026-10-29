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
setk('BBS','TelnetPort','23'); setk('BBS','RLoginPort','513'); setk('BBS','RLoginInterface','127.0.0.1'); setk('BBS','SSHPort','0')
setk('Mail','AutoStart','false'); setk('FTP','AutoStart','false')
setk('Web','Port','8023'); setk('Web','Options','NO_CGI | NO_HOST_LOOKUP')   # no ALLOW_TLS: Caddy owns 443
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

# web page: full-width layout, big terminal (no sidebar on the home page)
sed -i -E 's/^(\s*layout_full_width\s*=).*/\1true/' $D/ctrl/modopts.ini
# dark mode on for everyone (the switch itself is hidden below)
if grep -qE '^\s*darkmode_on\s*=' $D/ctrl/modopts.ini; then sed -i -E 's/^(\s*darkmode_on\s*=).*/\1true/' $D/ctrl/modopts.ini
else sed -i -E '/^\[web\]/a\    darkmode_on=true' $D/ctrl/modopts.ini; fi
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
#fTelnetContainer,#fTelnetContainer *{overflow:hidden !important;overscroll-behavior:contain}
#ftelnet-connect{display:none !important}
.fTelnetFocusWarning{display:none !important}
</style>
<script>/* no sounds on this page: the web terminal's beeps (idle warnings, bells) are muted */
(function(){try{HTMLMediaElement.prototype.play=function(){return Promise.resolve();};}catch(e){}
 var N=function(){return{createOscillator:function(){return{connect:function(){},start:function(){},stop:function(){},frequency:{value:0}};},createGain:function(){return{connect:function(){},gain:{value:0}};},destination:{},resume:function(){return Promise.resolve();},close:function(){return Promise.resolve();}};};
 try{window.AudioContext=N;window.webkitAudioContext=N;}catch(e){}})();</script>
<script>window.addEventListener('load',function(){setTimeout(function(){var b=document.getElementById('ftelnet-connect');if(b)b.click();},500);});</script>
<div id="pkbar" style="text-align:right;margin:0 0 6px;font-size:13px;display:none"><a href="#" id="pklogin" style="color:#8cf">Sign in with passkey</a> <span id="pkmsg" style="color:#aaa"></span></div>
<script>
(function(){
 var bar=document.getElementById('pkbar'),a=document.getElementById('pklogin'),msg=document.getElementById('pkmsg');
 if(!window.PublicKeyCredential||!bar)return;
 fetch('./api/auth.ssjs').then(function(r){return r.json();}).then(function(j){bar.style.display='block'; if(j.authenticated)a.textContent='Link a passkey to this account';}).catch(function(){bar.style.display='block';});
 var b=function(s){return Uint8Array.from(atob(s.replace(/-/g,'+').replace(/_/g,'/')),function(c){return c.charCodeAt(0);});};
 var e=function(x){return btoa(String.fromCharCode.apply(null,new Uint8Array(x))).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');};
 a.addEventListener('click',async function(ev){
  ev.preventDefault(); msg.textContent='...';
  try{
   var o=await (await fetch('./api/passkey.ssjs?action=options',{cache:'no-store'})).json(); if(o.error)throw o.error;
   var c=await navigator.credentials.get({publicKey:{challenge:b(o.challenge),rpId:o.rpId,userVerification:o.userVerification||'preferred',timeout:o.timeout}});
   var cred={id:c.id,type:c.type,response:{clientDataJSON:e(c.response.clientDataJSON),authenticatorData:e(c.response.authenticatorData),signature:e(c.response.signature),userHandle:c.response.userHandle?e(c.response.userHandle):null}};
   var r=await (await fetch('./api/passkey.ssjs?action=login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({credential:cred})})).json();
   if(r.error)throw r.error;
   msg.textContent=(r.linked?'Linked as ':'Signed in as ')+r.name; setTimeout(function(){location.reload();},800);
  }catch(x){ msg.textContent=(x&&x.message)?x.message:String(x); }
 });
})();
</script>
<script>try{var x=new XMLHttpRequest();x.open('GET','./api/passkey.ssjs?action=token',false);x.send();var j=JSON.parse(x.responseText);if(j.token)window.PKTOKEN=j.token;}catch(e){}</script>
<!-- end bigterm -->
X
  sed -i '/<!-- fTelnet -->/r /tmp/bigterm.html' "$H"
  rm -f /tmp/bigterm.html
fi
# hide the Dark/Light switch in the top bar (every page) with the site's own custom.css
CSSD=$(find $D/webv4 -maxdepth 2 -type d -name css 2>/dev/null | head -1)
if [ -n "$CSSD" ] && ! grep -qs 'dark-switch' $CSSD/custom.css; then echo '.dark-switch{display:none !important}' >> $CSSD/custom.css; fi
# version number in the footer, next to the year
if [ -n "$CSSD" ] && ! grep -qs 'v0.1' $CSSD/custom.css; then echo 'footer p::after{content:" \00b7  v0.1"}' >> $CSSD/custom.css; fi
# phones: no Sidebar button and no sliding sidebar panel (desktop keeps the sidebar)
if [ -n "$CSSD" ] && ! grep -qs 'offcanvas' $CSSD/custom.css; then echo '@media (max-width:767px){#sidebar,[data-toggle="offcanvas"]{display:none !important}}' >> $CSSD/custom.css; fi
# take the Recent Visitors block out of the sidebar (files kept in $D/webv4-sidebar-removed)
mkdir -p $D/webv4-sidebar-removed
for f in $D/webv4/sidebar/002-recent-visitors.xjs*; do [ -e "$f" ] && mv "$f" $D/webv4-sidebar-removed/; done
# replace the stock "mybbs" names: internet address, QWK ID, IRC bot channel
sed -i -E 's/^(\s*addr\s*=\s*)mybbs\.com/\1bbs.88x31.app/' $D/ctrl/msgs.ini
sed -i -E 's/^(\s*qwk_id\s*=).*/\1BBS88X31/' $D/ctrl/main.ini
[ -f $D/ctrl/ircbot.ini ] && sed -i -E 's/^(\s*channels\s*=\s*)#MyBBS/\1#88x31/' $D/ctrl/ircbot.ini
# passkey sign-in for the web site: api/passkey.ssjs talks to the shared Accounts service (dungeon-items) with the
# key in ctrl/secrets/accounts-key (put there by vps-tools from the ACCOUNTS_KEY secret). Game name "bbs", player = BBS user number.
APID=$(dirname "$(ls $D/webv4/*/api/auth.ssjs 2>/dev/null | head -1)")
if [ -d "$APID" ]; then cat > "$APID/passkey.ssjs" <<'JS'
// Passkey sign-in for the 88x31 BBS web site, through the shared Accounts service (dungeon-items).
//   GET  ?action=options                  passkey login options (a challenge from Accounts)
//   POST ?action=login  {credential}      signs in the BBS user linked to that account; if nobody is linked yet: links the
//                                         signed-in user, or (nobody signed in) makes a new BBS user with a random name.
var settings = load('modopts.js', 'web') || { web_directory: '../webv4' };
load(settings.web_directory + '/lib/init.js');
load(settings.web_lib + 'auth.js');
load('http.js');
var ACC = 'https://dungeon-items.ddddungeon.workers.dev/rpc/accounts/';
var ORIGIN = 'https://bbs.88x31.app', GAME = 'bbs';

function reply(o) {
	var s = JSON.stringify(o);
	http_reply.header['Content-Type'] = 'application/json';
	http_reply.header['Cache-Control'] = 'no-store';
	write(s);
}
function key() {
	var f = new File(system.ctrl_dir + 'secrets/accounts-key');
	if (!f.open('r')) return '';
	var k = f.read(); f.close();
	return k.replace(/\s+$/, '');
}
function call(method, args) {
	var r = new HTTPRequest(undefined, undefined, { 'x-accounts-key': key() }, 15);
	var body = r.Post(ACC + method, JSON.stringify(args), undefined, undefined, 'application/json');
	try { return JSON.parse(body); } catch (e) { return { error: 'Accounts are unavailable right now. Try again in a moment.' }; }
}
var W1 = ['Quiet', 'Amber', 'Silver', 'Wandering', 'Hidden', 'Lucky', 'Clever', 'Brave', 'Velvet', 'Neon', 'Mossy', 'Copper'];
var W2 = ['Fox', 'Owl', 'Lantern', 'Comet', 'Moth', 'Raven', 'Pilgrim', 'Otter', 'Signal', 'Ghost', 'Heron', 'Ember'];
function freshName() {
	for (var i = 0; i < 60; i++) {
		var n = W1[random(W1.length)] + W2[random(W2.length)] + (i >= 10 ? String(random(1000)) : '');
		if (system.matchuser(n) < 1) return n;
	}
	return null;
}
function ipOf() {
	var h = http_request.header || {};
	var x = h['x-forwarded-for'] || h['X-Forwarded-For'] || http_request.remote_ip || 'unknown';
	return String(x).split(',')[0].replace(/\s/g, '');
}

(function () {
	var q = http_request.query || {};
	var action = q.action ? q.action[0] : '';
	if (action == 'options') return reply(call('passkeyLoginOptions', [{ origin: ORIGIN, ip: ipOf() }]));
	if (action == 'token') {
		// a one-time code for the web terminal: good for 60 seconds, once (mods/login.js reads it)
		if (!is_user()) return reply({ error: 'Not signed in.' });
		var tok = 'pk' + randomString(32).replace(/[^A-Za-z0-9]/g, 'x');
		mkpath(system.data_dir + 'pktok');
		var tf = new File(system.data_dir + 'pktok/' + tok);
		if (!tf.open('w')) return reply({ error: 'Could not make a code.' });
		tf.write(user.number + ' ' + (time() + 60)); tf.close();
		return reply({ token: tok });
	}
	if (action != 'login' || http_request.method != 'POST') return reply({ error: 'Unknown action.' });

	var cred;
	try { cred = JSON.parse(http_request.post_data).credential; } catch (e) { return reply({ error: 'Bad request.' }); }
	var r = call('passkeyLogin', [{ origin: ORIGIN, credential: cred, ip: ipOf() }]);
	if (!r || r.error || !r.accountId) return reply({ error: (r && r.error) || "That passkey didn't work." });

	var p = call('playerFor', [r.accountId, GAME]);
	if (p && p.playerId && p.playerId >= 1 && p.playerId <= system.lastuser) {
		var usr = new User(p.playerId);
		if (usr.settings & USER_DELETED) return reply({ error: 'That BBS user is gone.' });
		destroySession(http_request.cookie.synchronet || {});
		setCookie(usr, randomString(512));
		return reply({ ok: true, name: usr.alias });
	}
	if (is_user()) {
		var l = call('link', [r.accountId, GAME, user.number]);
		if (l && l.linked) return reply({ ok: true, linked: true, name: user.alias });
		return reply({ error: 'That passkey is already linked to another BBS user.' });
	}
	// nobody linked and nobody signed in: make a new BBS user for this account (like the games make a new player)
	var name = freshName();
	if (!name) return reply({ error: "Couldn't pick a name. Try again." });
	var nu = system.new_user(name);
	if (typeof nu !== 'object' || !nu.number) return reply({ error: "Couldn't make a BBS user. Try again." });
	nu.security.password = randomString(16).replace(/[^A-Za-z0-9]/g, 'x');   // nobody can log in with just the name
	var nl = call('link', [r.accountId, GAME, nu.number]);
	if (!(nl && nl.linked)) { nu.settings |= USER_DELETED; return reply({ error: "Couldn't link the new BBS user. Try again." }); }
	destroySession(http_request.cookie.synchronet || {});
	setCookie(nu, randomString(512));
	return reply({ ok: true, created: true, name: nu.alias });
})();
JS
fi
# web terminal auto-login: mods/login.js turns a one-time code (sent as the RLogin name) into that user, then runs the stock login
mkdir -p $D/mods $D/data/pktok
cat > $D/mods/login.js <<'JS'
// 88x31: the web terminal connects by RLogin with a one-time code from api/passkey.ssjs as the name.
// A good code (60 seconds, once) logs that user in; anything else goes on to the stock login.
(function () {
	var s = String(bbs.rlogin_name || '');
	if (!/^pk[A-Za-z0-9]{20,64}$/.test(s)) return;
	var f = new File(system.data_dir + 'pktok/' + s);
	if (!f.exists || !f.open('r')) return;
	var t = f.read().split(' '); f.close(); f.remove();
	var n = parseInt(t[0], 10), exp = parseInt(t[1], 10);
	if (!(n > 0) || time() > exp) return;
	var u = new User(n);
	if (bbs.login(u.alias, '', u.security.password)) exit();
})();
load(system.exec_dir + 'login.js');
JS
find $D/data/pktok -type f -mmin +5 -delete 2>/dev/null || true
# the home page's terminal uses RLogin with the code when you're signed in on the site
if [ -n "$H" ]; then python3 - "$H" <<'PY2'
import sys
p=sys.argv[1]; s=open(p).read()
k="var fTelnet = new fTelnetClient("
if 'PKTOKEN' not in s.split(k)[0][-600:] and k in s:
    s=s.replace(k,"if(window.PKTOKEN){Options.ConnectionType='rlogin';Options.ProxyHostname=location.hostname;Options.ProxyPort=wsp;Options.ProxyPortSecure=wssp;Options.Hostname='127.0.0.1';Options.Port=513;Options.RLoginClientUsername=window.PKTOKEN;Options.RLoginServerUsername=window.PKTOKEN;Options.RLoginTerminalType='ansi-bbs';}\n\t\t\t\t"+k,1)
open(p,'w').write(s)
PY2
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
