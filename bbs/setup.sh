#!/usr/bin/env bash
# Installs the 88x31 BBS: Synchronet (built from source) with NetHack as a door game.
# Service "sbbs". Telnet on port 23, browser terminal on port 8023. Mail and FTP are off.
# Takes a while (Synchronet builds from source on one core). Safe to re-run: rebuilds and keeps the BBS data.
# Does NOT start/restart it.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
U=bbs; D=/sbbs; NAME="~*~88x31~*~ BbS"

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
setk('BBS','TelnetPort','23'); setk('BBS','RLoginPort','513'); setk('BBS','RLoginInterface','127.0.0.1'); setk('BBS','SSHPort','0'); setk('BBS','LastNode','10')   # 10 people at once
setk('Mail','AutoStart','false'); setk('FTP','AutoStart','false')
setk('Web','Port','8023'); setk('Web','Options','NO_CGI | NO_HOST_LOOKUP')   # no ALLOW_TLS: Caddy owns 443
setk('UNIX','User','bbs'); setk('UNIX','Group','bbs')
open(f,'w').write(t)
PY
sed -i -E "s/^(\s*name\s*=).*/\1 $NAME/" $D/ctrl/main.ini
# 10 nodes: node folders 1-10 (new ones copy node1's settings) and their [node_dir] lines in main.ini
for n in $(seq 2 10); do
  [ -d $D/node$n ] || { mkdir -p $D/node$n; for c in node.ini terminal.ini client.ini; do [ -f $D/node1/$c ] && cp $D/node1/$c $D/node$n/; done; }
done
python3 - $D/ctrl/main.ini <<'PY5'
import re,sys
f=sys.argv[1];t=open(f).read()
m=re.search(r'(?ms)^\[node_dir\][^\n]*\n(.*?)(?=^\[|\Z)',t)
open(f,'w').write(t[:m.start(1)]+''.join('\t%d=../node%d/\n'%(n,n) for n in range(1,11))+'\n'+t[m.end(1):])
PY5
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

# no Bulletins screen at logon: BullsEye stays in the programs menu, but is no longer a logon event (event 1 -> 0)
python3 - $X <<'PY4'
import re,sys
f=sys.argv[1];t=open(f).read()
open(f,'w').write(re.sub(r'(?ms)(^\[prog:[^\]]*BULLSEYE\][^\[]*?^\s*event\s*=\s*)1\b',r'\g<1>0',t))
PY4
# web page: full-width layout, big terminal (no sidebar on the home page)
sed -i -E 's/^(\s*layout_full_width\s*=).*/\1true/' $D/ctrl/modopts.ini
# Guest logon: no "please enter your full name" / e-mail questions (logon.js skips a prompt whose option is false)
for k in guest_name guest_email; do
  if grep -qE "^\s*$k\s*=" $D/ctrl/modopts.ini; then sed -i -E "s/^(\s*$k\s*=).*/\1false/" $D/ctrl/modopts.ini
  else sed -i -E "/^\[logon\]/a\    $k=false" $D/ctrl/modopts.ini; fi
done
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
<script>/* not signed in: the browser gets a BBS user with a rolled name, and a key kept in this browser finds the same user next time */
try{var K='bbs88x31key',st=new XMLHttpRequest();st.open('GET','./api/passkey.ssjs?action=status',false);st.send();
 if(!JSON.parse(st.responseText).signedIn){var k='';try{k=localStorage.getItem(K)||'';}catch(e){}
  var an=new XMLHttpRequest();an.open('POST','./api/passkey.ssjs?action=anon',false);an.setRequestHeader('content-type','application/json');an.send(JSON.stringify({key:k}));
  var aj=JSON.parse(an.responseText);if(aj.key){try{localStorage.setItem(K,aj.key);}catch(e){}}}}catch(e){}</script>
<script>try{var x=new XMLHttpRequest();x.open('GET','./api/passkey.ssjs?action=token',false);x.send();var j=JSON.parse(x.responseText);if(j.token)window.PKTOKEN=j.token;}catch(e){}
/* signed in: type the one-time code at the BBS "Login:" prompt, once */
(function(){ if(!window.PKTOKEN||!window.WebSocket)return; var W=window.WebSocket;
 function P(u,p){ var ws=p!==undefined?new W(u,p):new W(u), sent=false, buf='';
  function see(t){ if(sent)return; buf=(buf+t).slice(-300); if(/Login: ?/.test(buf)){ sent=true; var c=window.PKTOKEN+'\r', a=new Uint8Array(c.length); for(var i=0;i<c.length;i++)a[i]=c.charCodeAt(i); setTimeout(function(){ try{ws.send(a);}catch(e){} },150); } }
  ws.addEventListener('message',function(ev){ var d=ev.data; if(typeof d==='string')see(d); else if(d instanceof ArrayBuffer)see(String.fromCharCode.apply(null,new Uint8Array(d))); else if(d&&d.arrayBuffer)d.arrayBuffer().then(function(b){see(String.fromCharCode.apply(null,new Uint8Array(b)));}); });
  return ws; }
 P.prototype=W.prototype; P.CONNECTING=0; P.OPEN=1; P.CLOSING=2; P.CLOSED=3; window.WebSocket=P; })();</script>
<!-- end bigterm -->
X
  sed -i '/<!-- fTelnet -->/r /tmp/bigterm.html' "$H"
  rm -f /tmp/bigterm.html
fi
# web terminal (fTelnet) served from our own site, not embed-v2.ftelnet.ca: the script, its css, keyboard css and fonts are
# copied once into webv4/root/ftelnet; the home page points at our copy. Re-run with FTELNET_REFRESH=1 to download a new copy.
FTV=2026-01-16; FTU=https://embed-v2.ftelnet.ca/ftelnet; FD=$D/webv4/root/ftelnet; FJS=ftelnet.norip.noxfer.min.js
if [ ! -s $FD/$FJS ] || [ "${FTELNET_REFRESH:-}" = 1 ]; then
  mkdir -p $FD/fonts $FD/keyboard
  curl -fsSL -m 60 -o $FD/$FJS "$FTU/$FJS?v=$FTV"
  curl -fsSL -m 30 -o $FD/ftelnet.css "$FTU/ftelnet.css" || true
  for s in 960 800 720 640 560 480 360 320; do curl -fsSL -m 30 -o $FD/keyboard/keyboard-$s.min.css "$FTU/keyboard/keyboard-$s.min.css" || true; done
  for u in $(cat $FD/ftelnet.css $FD/keyboard/*.css 2>/dev/null | grep -o 'url([^)]*)' | sed -E "s/url\(['\"]?//; s/['\"]?\)$//" | grep -v '^data:' | sort -u); do
    mkdir -p "$FD/$(dirname "$u")"; curl -fsSL -m 30 -o "$FD/$u" "$FTU/$u" || true; done
  for f in $(grep -o "_FontNames=\[[^]]*\]" $FD/$FJS | grep -o "'[^']*'" | tr -d "'"); do
    [ -s $FD/fonts/$f.png ] || curl -fsSL -m 30 -o $FD/fonts/$f.png "$FTU/fonts/$f.png" || true; done
  curl -fsSL -m 30 -o $FD/proxy-servers.json https://embed-v2.ftelnet.ca/proxy-servers.json || true
  sed -i -e "s#//embed-v2.ftelnet.ca/ftelnet/fonts/#/ftelnet/fonts/#g" -e "s#//embed-v2.ftelnet.ca/proxy-servers.json#/ftelnet/proxy-servers.json#g" $FD/$FJS
  echo "fTelnet copied: $(ls $FD/fonts | wc -l) fonts"
fi
[ -n "$H" ] && sed -i "s#<?xjs write(get_url()); ?>#/ftelnet/$FJS?v=$FTV-nocursor#" "$H"   # -nocursor: browsers fetch the patched copy, not an old saved one
# no terminal cursor: the blink timer only ever hides it, so Synchronet's spinning cursor is the only one
sed -i 's#case BlinkState.Show:this.onshow.trigger();break;#case BlinkState.Show:this.onhide.trigger();break;#' $FD/$FJS
grep -q 'case BlinkState.Show:this.onhide.trigger()' $FD/$FJS && echo "terminal cursor off" || echo "terminal cursor: patch did not fit"
# hide the Dark/Light switch in the top bar (every page) with the site's own custom.css
CSSD=$(find $D/webv4 -maxdepth 2 -type d -name css 2>/dev/null | head -1)
if [ -n "$CSSD" ] && ! grep -qs 'dark-switch' $CSSD/custom.css; then echo '.dark-switch{display:none !important}' >> $CSSD/custom.css; fi
# all-black page around the terminal (every page): top bar, page and footer are black like the terminal; the terminal keeps its thin border
if [ -n "$CSSD" ] && ! grep -qs 'allblack' $CSSD/custom.css; then
  echo '/* allblack */ html,body,.navbar,.navbar-default,.navbar-inverse,footer,.container,.container-fluid{background-color:#000 !important} .navbar-default,.navbar-inverse{border-color:#000 !important}' >> $CSSD/custom.css
fi
# top of the page: one row of plain text links (every page, flattened, no dropdowns) instead of the menu bar.
# The user name, Link passkey and Log out are on the Stuff page.
NB=$D/webv4/components/navbar.xjs
if [ -f $NB ]; then [ -f $D/webv4-navbar.xjs.bak ] || cp $NB $D/webv4-navbar.xjs.bak
cat > $NB <<'NAV'
<?xjs
	// 88x31: three text links instead of the menu bar: Home, Forum, Stuff (made by bbs/setup.sh; do not edit)
?>
<div id="toplinks">
	<a href="<? write(settings.brand_link || './'); ?>"><b><? write(settings.brand || system.name); ?></b></a>
	<a href="./">Home</a> <a href="./?page=001-forum.xjs">Forum</a> <a href="./?page=900-stuff.xjs">Stuff</a>
</div>
<script>
function pkSignIn(el){
 var b=function(s){return Uint8Array.from(atob(s.replace(/-/g,'+').replace(/_/g,'/')),function(c){return c.charCodeAt(0);});};
 var e=function(x){return btoa(String.fromCharCode.apply(null,new Uint8Array(x))).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');};
 var label=el.textContent; el.textContent='...';
 (async function(){ try{
  if(!window.PublicKeyCredential) throw 'This browser has no passkeys.';
  var o=await (await fetch('./api/passkey.ssjs?action=options',{cache:'no-store'})).json(); if(o.error) throw o.error;
  var c=await navigator.credentials.get({publicKey:{challenge:b(o.challenge),rpId:o.rpId,userVerification:o.userVerification||'preferred',timeout:o.timeout}});
  var cred={id:c.id,type:c.type,response:{clientDataJSON:e(c.response.clientDataJSON),authenticatorData:e(c.response.authenticatorData),signature:e(c.response.signature),userHandle:c.response.userHandle?e(c.response.userHandle):null}};
  var r=await (await fetch('./api/passkey.ssjs?action=login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({credential:cred})})).json();
  if(r.error) throw r.error; location.reload();
 }catch(x){ el.textContent=label; el.title=(x&&x.message)?x.message:String(x); } })();
 return false;
}
</script>
NAV
rm -f $NB.ssjs; fi
# "Stuff" page: who you are logged in as, Link passkey and Log out (signed-in users), then every other page (all but Home
# and Forum) as text links. Log out goes back to this browser's own account (the one its key finds); a new one is made only if
# that one is gone.
cat > $D/webv4/pages/900-stuff.xjs <<'STUFF'
<!--Stuff-->
<?xjs
	// 88x31: links to every page except Home, Forum and this one (made by bbs/setup.sh; do not edit)
	function stuff(arr, path) {
		arr.forEach(function (e) {
			if (e.type == 'list') { stuff(e.list, (path || '') + e.title + '/'); return; }
			var p = (path || '') + e.page;
			if (/^(000-home|001-forum|900-stuff)\./.test(p)) return;
			write('<p><a href="./?page=' + p + '"' + (e.type == 'link' ? ' target="_blank"' : '') + '>' + e.title + '</a></p>');
		});
	}
?>
<?xjs if (user.number > 0 && user.alias !== settings.guest) { ?>
<p>You are logged in as <a href="./?page=000-mail.xjs"><? write(user.alias); ?> <span class="badge scanned" title="Unread mail" id="badge-unread-mail"></span></a></p>
<p><a href="#" id="nav-pklink" style="display:none" onclick="return pkSignIn(this)">Link passkey</a></p>
<p><a href="#" id="button-logout">Log out</a></p>
<script>(function(){ var l=document.getElementById('nav-pklink');
 fetch('./api/passkey.ssjs?action=status',{cache:'no-store'}).then(function(r){return r.json();}).then(function(j){ if(j.signedIn&&!j.linked) l.style.display=''; }).catch(function(){}); })();</script>
<?xjs } ?>
<div id="stufflist"><?xjs stuff(getPageList(settings.web_pages)); ?></div>
STUFF
rm -f $D/webv4/pages/900-stuff.xjs.ssjs
if [ -n "$CSSD" ] && ! grep -qs 'toplinks' $CSSD/custom.css; then
  echo '/* toplinks */ body{padding-top:12px !important} #toplinks{padding:0 15px 10px} #toplinks a{color:#8cf;margin-right:14px}' >> $CSSD/custom.css
fi
# page text in the terminal's DOS font: "Web437 IBM VGA 8x16" from the Ultimate Oldschool PC Font Pack by VileR (int10h.org),
# CC BY-SA 4.0; the font and its LICENSE.TXT are kept together in webv4/root/fonts
WF=$D/webv4/root/fonts
if [ ! -s $WF/Web437_IBM_VGA_8x16.woff ]; then
  mkdir -p $WF; curl -fsSL -m 60 -o /tmp/fontpack.zip https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_web.zip \
    && unzip -o -j -q /tmp/fontpack.zip 'woff - Web (webfonts)/Web437_IBM_VGA_8x16.woff' LICENSE.TXT -d $WF; rm -f /tmp/fontpack.zip
fi
if [ -n "$CSSD" ] && ! grep -qs 'dosfont' $CSSD/custom.css; then
  echo "/* dosfont: Web437 IBM VGA 8x16, VileR (int10h.org), CC BY-SA 4.0, see /fonts/LICENSE.TXT */ @font-face{font-family:'IBM VGA';src:url('../fonts/Web437_IBM_VGA_8x16.woff') format('woff')} html,body,body *{font-family:'IBM VGA',monospace !important;font-size:16px} body{-webkit-font-smoothing:none}" >> $CSSD/custom.css
fi
# version number in the footer, next to the year
# BBS web version: bump it on every release (pushed change to the site)
BBS_VERSION=0.16
# the version is real footer text (selectable), written into the footer component; the old CSS version rule is removed
[ -n "$CSSD" ] && touch $CSSD/custom.css && sed -i '/^footer p.*::after/d' $CSSD/custom.css
FT=$D/webv4/components/footer.xjs
[ -f $FT ] && echo "<p>&copy; <?xjs write(system.name + \", \" + strftime(\"%Y\")); ?> &middot; v$BBS_VERSION</p>" > $FT && rm -f $D/webv4/components/footer.xjs.ssjs
# phones: no Sidebar button and no sliding sidebar panel (desktop keeps the sidebar)
if [ -n "$CSSD" ] && ! grep -qs 'offcanvas' $CSSD/custom.css; then echo '@media (max-width:767px){#sidebar,[data-toggle="offcanvas"]{display:none !important}}' >> $CSSD/custom.css; fi
# take the Recent Visitors block out of the sidebar (files kept in $D/webv4-sidebar-removed)
mkdir -p $D/webv4-sidebar-removed
for f in $D/webv4/sidebar/002-recent-visitors.xjs*; do [ -e "$f" ] && mv "$f" $D/webv4-sidebar-removed/; done
# replace the stock "mybbs" names: internet address, QWK ID, IRC bot channel
sed -i -E 's/^(\s*addr\s*=\s*)mybbs\.com/\1bbs.88x31.app/' $D/ctrl/msgs.ini
sed -i -E 's/^(\s*qwk_id\s*=).*/\1BBS88X31/' $D/ctrl/main.ini
[ -f $D/ctrl/ircbot.ini ] && sed -i -E 's/^(\s*channels\s*=\s*)#MyBBS/\1#88x31/' $D/ctrl/ircbot.ini
# one place for the name rolling (two words like the games, word lists from scoundrel.exe src/names.js); the new-user script
# (mods/newuser_prompts.js) and the web page's automatic account (api/passkey.ssjs, action anon) both load it
mkdir -p $D/mods
cat > $D/mods/rollname.js <<'JS3'
// 88x31: rolls a free two-word name like the games, or null (made by bbs/setup.sh; do not edit)
var A = ["Quiet", "Amber", "Early", "Gentle", "Bright", "Sleepy", "Golden", "Misty", "Rosy", "Brisk", "Hushed", "Warm", "Pale", "Slow", "Steady", "Wandering", "Soft", "Silver", "Crisp", "Drowsy", "Humble", "Eager", "Lucky", "Patient", "Little", "Cheerful", "Faint", "Glowing", "Distant", "Tender", "Rested", "Windy", "Dewy", "Calm", "Merry", "Shy", "Nimble", "Sunny", "Mellow", "Dappled"];
var N = ["Heron", "Lantern", "Sparrow", "Kettle", "Meadow", "Thistle", "Harbor", "Wren", "Compass", "Fern", "Moth", "Orchard", "Ferry", "Pebble", "Robin", "Willow", "Teapot", "Comet", "Lark", "Cedar", "Beacon", "Marmot", "Otter", "Clover", "Ember", "Finch", "Tide", "Bramble", "Lamp", "Poppy", "Swallow", "Sundial", "Quill", "Hedgehog", "Trellis", "Rooster", "Weathervane", "Kingfisher", "Pigeon", "Lighthouse"];
function rollName() {
	for (var i = 0; i < 200; i++) {
		var n = A[random(A.length)] + ' ' + N[random(N.length)];
		if (n.length <= 16 && system.check_name(n) && !system.matchuser(n)) return n;
	}
	return null;
}
JS3
# passkey sign-in for the web site: api/passkey.ssjs talks to the shared Accounts service (dungeon-items) with the
# key in ctrl/secrets/accounts-key (put there by vps-tools from the ACCOUNTS_KEY secret). Game name "bbs", player = BBS user number.
APID=$(dirname "$(ls $D/webv4/*/api/auth.ssjs 2>/dev/null | head -1)")
if [ -d "$APID" ]; then cat > "$APID/passkey.ssjs" <<'JS'
// Passkey sign-in for the 88x31 BBS web site, through the shared Accounts service (dungeon-items).
//   GET  ?action=options                  passkey login options (a challenge from Accounts)
//   POST ?action=anon   {key}             no Login on the web: the browser key finds its BBS user, or makes one with a rolled name
//   POST ?action=login  {credential}     signs in the BBS user linked to that account; if nobody is linked yet: links the
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
// a visitor's long-lived key (32 hex characters, kept in their browser) finds their BBS user again: data/anon/<md5 of the key> holds the user number
function bindKey(k, n) {
	if (!/^[0-9a-f]{32}$/.test(k)) return;
	mkpath(system.data_dir + 'anon');
	var f = new File(system.data_dir + 'anon/' + md5_calc(k, true));
	if (f.open('w')) { f.write(String(n)); f.close(); }
}
function userForKey(k) {
	if (!/^[0-9a-f]{32}$/.test(k)) return null;
	var f = new File(system.data_dir + 'anon/' + md5_calc(k, true));
	if (!f.exists || !f.open('r')) return null;
	var n = parseInt(f.read(), 10); f.close();
	if (!(n >= 1 && n <= system.lastuser)) return null;
	var u = new User(n);
	return (u.settings & USER_DELETED) ? null : u;
}

(function () {
	var q = http_request.query || {};
	var action = q.action ? q.action[0] : '';
	if (action == 'options') return reply(call('passkeyLoginOptions', [{ origin: ORIGIN, ip: ipOf() }]));
	if (action == 'status') {
		if (!is_user()) return reply({ signedIn: false });
		var st = call('accountOf', [GAME, user.number]);
		return reply({ signedIn: true, linked: !!(st && st.accountId), name: user.alias });
	}
	if (action == 'token') {
		// a one-time code for the web terminal: good for 60 seconds, once (mods/login.js reads it)
		if (!is_user()) return reply({ error: 'Not signed in.' });
		var tok = 'pk' + md5_calc(String(Math.random()) + time() + user.number + randomString(16), true).substr(0, 20);   // 22 chars: the Login: prompt takes 25
		mkpath(system.data_dir + 'pktok');
		var tf = new File(system.data_dir + 'pktok/' + tok);
		if (!tf.open('w')) return reply({ error: 'Could not make a code.' });
		tf.write(user.number + ' ' + (time() + 60)); tf.close();
		return reply({ token: tok, name: user.alias });
	}
	if (action == 'anon' && http_request.method == 'POST') {
		// a visitor who is not signed in: their browser key finds their BBS user again; with no key (or an unknown one) they get a
		// new BBS user with a rolled name, like the games, and a new key to keep in the browser. Signs them in on the site.
		var ak = '';
		try { ak = String(JSON.parse(http_request.post_data).key || ''); } catch (e) {}
		var au = userForKey(ak);
		if (!au) {
			load(system.mods_dir + 'rollname.js');
			var an = rollName();
			if (!an) return reply({ error: "Couldn't pick a name. Try again." });
			au = system.new_user(an);
			if (typeof au !== 'object' || !au.number) return reply({ error: "Couldn't make a BBS user. Try again." });
			au.security.password = randomString(16).replace(/[^A-Za-z0-9]/g, 'x');   // nobody can log in with just the name
			au.name = an; au.handle = an; au.location = 'Unknown'; au.birthdate = '1970-01-01';
			au.netmail = an.replace(/ /g, '_') + '@bbs.88x31.app';
			au.settings &= ~((1 << 14) | (1 << 16));   // no "search all groups" questions at logon
			ak = md5_calc(String(Math.random()) + time() + au.number + randomString(16), true);   // 32 hex characters
			bindKey(ak, au.number);
		}
		destroySession(http_request.cookie.synchronet || {});
		setCookie(au, randomString(512));
		return reply({ ok: true, key: ak, name: au.alias });
	}
	if (action != 'login' || http_request.method != 'POST') return reply({ error: 'Unknown action.' });

	// a passkey sign-in never changes which BBS user this browser's own key finds (Log out goes back to that one)
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
		if (l && l.linked) { return reply({ ok: true, linked: true, name: user.alias }); }
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
python3 - $D/exec/login.js $D/mods/login.js <<'PY3'
import sys
src=open(sys.argv[1]).read()
k=src.find("str=console.getstr(")
e=src.find(");",k)+2 if k>=0 else -1
hook="""
		// 88x31: the web page types a one-time code (from api/passkey.ssjs) at this prompt; a good one (60 seconds,
		// once) logs in the user it was made for.
		if (/^pk[0-9a-f]{20}$/i.test(String(str))) {
			var _ok = (function (tok) {
				var f = new File(system.data_dir + 'pktok/' + tok);
				if (!f.exists || !f.open('r')) return false;
				var t = f.read().split(' '); f.close(); f.remove();
				var n = parseInt(t[0], 10), exp = parseInt(t[1], 10);
				if (!(n > 0) || time() > exp) return false;
				var u = new User(n);
				// no new-user questions for passkey users: fill the fields the stock logon.js asks about when they are blank
					if (!u.name) u.name = u.alias;
					if (!u.handle) u.handle = u.alias;
					if (!u.location) u.location = 'Unknown';
					if (!u.birthdate) u.birthdate = '1970-01-01';
					if (!u.netmail) u.netmail = u.alias.replace(/ /g, '_') + '@bbs.88x31.app';
					u.settings &= ~((1 << 14) | (1 << 16));   // ASK_NSCAN, ASK_SSCAN: no "search all groups" questions at logon
					return bbs.login(u.alias, '', u.security.password);
			})(String(str).toLowerCase());
			if (_ok) { bbs.logon(); exit(); }
			continue;
		}
"""
if k<0: sys.exit("login.js: getstr not found")
open(sys.argv[2],"w").write("// 88x31: stock exec/login.js plus a one-time code check (made by bbs/setup.sh; do not edit)\n"+src[:e]+hook+src[e:])
PY3
find $D/data/pktok -type f -mmin +5 -delete 2>/dev/null || true
# new users (typing "New"): a rolled two-word name like the games (word lists from scoundrel.exe src/names.js) instead of being
# asked for one; the terminal questions stay, every other question is filled in. main.ini already points at newuser_prompts.
cat > $D/mods/newuser_prompts.js <<'JS2'
// 88x31: a new user gets a rolled two-word name (like the games) instead of being asked for one (made by bbs/setup.sh; do not edit)
var prompts = bbs.mods.prompts || load(bbs.mods.prompts = {}, "user_info_prompts.js", "new user registration");
var options = load("modopts.js", "newuser_prompts", {});
load(system.mods_dir + "rollname.js");
if (options.lang)
	prompts.get_lang();
// terminal setup without questions: the same as answering Yes to "Use automatic terminal type detection?"
require("sbbsdefs.js", "USER_AUTOTERM");
if (console.autoterm) {
	user.settings |= USER_AUTOTERM;
	user.settings |= console.autoterm;
}
prompts.get_terminal(user, { autoterm: false, backspace: false, mouse: false, charset: false });
var name = rollName();
if (!name) {
	log(LOG_ERR, "New user: could not roll a name");
	exit(1);
}
user.alias = name;
user.name = name;
user.handle = name;
user.location = 'Unknown';
user.birthdate = '1970-01-01';
user.netmail = name.replace(/ /g, '_') + '@bbs.88x31.app';
user.settings &= ~((1 << 14) | (1 << 16));   // ASK_NSCAN, ASK_SSCAN: no "search all groups" questions at logon
console.print("\r\nYour name here is \1h" + name + "\1n.\r\n");
JS2
chown -R $U:$U $D
# the web site (browser terminal) needs a Guest account
(cd $D/exec && sudo -u $U env SBBSCTRL=$D/ctrl ./jsexec -n makeguest.js 2>&1 | tail -n 1) || true
# Guest: no "search all groups" questions at logon either (same two flags as the passkey login)
echo 'var u = new User(system.matchuser("Guest")); if (u.number) u.settings &= ~((1 << 14) | (1 << 16));' > /tmp/guestfix.js && chmod 644 /tmp/guestfix.js
(cd $D/exec && sudo -u $U env SBBSCTRL=$D/ctrl ./jsexec -n /tmp/guestfix.js 2>&1 | tail -n 1) || true
rm -f /tmp/guestfix.js
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
