// scoundrel.exe in the 88x31 BBS: today's daily deck, the same run, deck and leaderboard as scoundrel.88x31.app.
// The game itself runs on scoundrel.exe's server; this door only draws it and sends the keys.
// Who you are: the BBS user's 88x31 account (the shared Accounts service in dungeon-items, game name "bbs"). The first time,
// the door asks scoundrel.exe for that account's player (POST /api/bbs-enter with the accounts key) and keeps its login
// token in data/scoundrel/<user number>.tok. A BBS user with no account yet gets one, linked to them.
// (made by bbs/setup.sh from the repo's bbs/xtrn/scoundrel.js; do not edit here)
load('sbbsdefs.js');
load('http.js');

var SITE = 'https://scoundrel.88x31.app';
var ACC = 'https://dungeon-items.ddddungeon.workers.dev/rpc/accounts/';
var TOKDIR = system.data_dir + 'scoundrel/';
var RANKS = { 11: 'J', 12: 'Q', 13: 'K', 14: 'A' };
var KIND = { monster: 'DEMON', weapon: 'BLADE', potion: 'HEALTH' };

function key() {
	var f = new File(system.ctrl_dir + 'secrets/accounts-key');
	if (!f.open('r')) return '';
	var k = f.read(); f.close();
	return k.replace(/\s+$/, '');
}
function post(url, body, headers) {
	var r = new HTTPRequest(undefined, undefined, headers || {}, 20);
	var b = r.Post(url, JSON.stringify(body), undefined, undefined, 'application/json');
	var j; try { j = JSON.parse(b); } catch (e) { j = { error: 'The game is unavailable right now. Try again in a moment.' }; }
	j._code = r.response_code;
	return j;
}
function get(url, headers) {
	var r = new HTTPRequest(undefined, undefined, headers || {}, 20);
	var b = r.Get(url);
	var j; try { j = JSON.parse(b); } catch (e) { j = { error: 'The game is unavailable right now. Try again in a moment.' }; }
	j._code = r.response_code;
	return j;
}
function accounts(method, args) { return post(ACC + method, args, { 'x-accounts-key': key() }); }

// this BBS user's scoundrel.exe login token: kept from last time, or got from the account
function tokenFile() { return new File(TOKDIR + user.number + '.tok'); }
function token(fresh) {
	var f = tokenFile();
	if (!fresh && f.exists && f.open('r')) { var t = f.read().replace(/\s+$/, ''); f.close(); if (t) return t; }
	var a = accounts('accountOf', ['bbs', user.number]);
	if (a.error) return { error: a.error };
	var id = a.accountId;
	if (!id) {
		var c = accounts('createAccount', []);
		if (!c.accountId) return { error: c.error || "Couldn't make your account. Try again." };
		var l = accounts('link', [c.accountId, 'bbs', user.number]);
		if (!l.linked) return { error: "Couldn't link your account. Try again." };
		id = c.accountId;
	}
	var e = post(SITE + '/api/bbs-enter', { accountId: id }, { 'x-accounts-key': key() });
	if (!e.token) return { error: e.error || "Couldn't sign you in to scoundrel.exe." };
	mkpath(TOKDIR);
	if (f.open('w')) { f.write(e.token); f.close(); }
	return e.token;
}
var TOKEN = null;
function api(path, body) {
	for (var tries = 0; tries < 2; tries++) {
		if (!TOKEN || tries) { TOKEN = token(tries > 0); if (typeof TOKEN !== 'string') return TOKEN; }
		var h = { cookie: 'sx=' + TOKEN };
		var r = body ? post(SITE + path, body, h) : get(SITE + path, h);
		if (r._code != 401) return r;   // 401: the token no longer finds the player, so get a fresh one once
	}
	return r;
}

// ---------- drawing ----------
function rank(c) { return RANKS[c.rank] || String(c.rank); }
function pad(s, n) { s = String(s); while (s.length < n) s += ' '; return s.substr(0, n); }
function lpad(s, n) { s = String(s); while (s.length < n) s = ' ' + s; return s; }
function color(c) { return c.kind === 'monster' ? '\1h\1r' : c.kind === 'weapon' ? '\1h\1c' : '\1h\1g'; }
function bar(v, max, w) { var n = Math.max(0, Math.round(v / max * w)), s = ''; for (var i = 0; i < w; i++) s += i < n ? '\xdb' : '\xb0'; return s; }

// what taking this card would do, from the run view (the server checks the real move)
function preview(v, c, bare) {
	if (c.kind === 'potion') return v.potionUsedThisRoom ? 'WASTED' : '+' + Math.min(c.rank, v.maxHealth - v.health) + ' HP';
	if (c.kind === 'weapon') return 'EQUIP';
	var armed = !bare && v.weapon && (v.weaponCeiling == null || c.rank < v.weaponCeiling);
	return (armed ? 'blade -' + Math.max(0, c.rank - v.weapon.card.rank) : 'bare -' + c.rank);
}

function header(name, info, screen) {
	console.clear();
	console.print('\1h\1ySCOUNDREL.EXE\1n  //  \1h\1w' + (name || 'GUEST') + '\1n  //  ' + screen + '  \1h\1k//  DECK #' + info.number + '\1n\r\n');
	console.print('\1n\1b' + Array(81).join('\xc4') + '\1n\r\n');
}

function drawRun(st, msg, bare) {
	var v = st.run.view;
	header(st.name, st, 'ROOM ' + v.turn);
	console.print('\r\n  \1h\1wHP\1n ' + lpad(v.health, 2) + '/' + v.maxHealth + '  \1h\1g' + bar(v.health, v.maxHealth, 20) + '\1n');
	console.print('     \1h\1wBLADE\1n ' + (v.weapon ? '\1h\1c' + rank(v.weapon.card) + '\1n ' + (v.weaponCeiling == null ? 'hits anything' : v.weaponCeiling <= 2 ? 'dull' : 'hits up to ' + (RANKS[v.weaponCeiling - 1] || (v.weaponCeiling - 1))) : 'none') + '\r\n');
	console.print('  \1h\1wIN DECK\1n ' + v.deckCount + ':  ' + v.deckMonsters + ' demons / ' + v.deckWeapons + ' blades / ' + v.deckPotions + ' health\r\n\r\n');
	var rows = ['', '', '', '', '', ''];
	for (var s = 0; s < 4; s++) {
		var i = v.slots[s], c = i == null ? null : v.room[i], col = c ? color(c) : '';
		var gap = '      ';
		if (!c) { for (var r = 0; r < 6; r++) rows[r] += pad('', 11) + gap; continue; }
		rows[0] += '\1h\1w   [' + (s + 1) + ']     \1n' + gap;
		rows[1] += col + '\xda\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xbf\1n' + gap;
		rows[2] += col + '\xb3 ' + pad(rank(c), 8) + '\xb3\1n' + gap;
		rows[3] += col + '\xb3 ' + pad(KIND[c.kind], 8) + '\xb3\1n' + gap;
		rows[4] += col + '\xc0\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xc4\xd9\1n' + gap;
		rows[5] += '\1n ' + pad(preview(v, c, bare), 10) + gap;
	}
	for (var r = 0; r < 6; r++) console.print('  ' + rows[r] + '\r\n');
	console.print('\r\n  ' + (msg || '') + '\1n\r\n\r\n');
	if (bare) console.print('  \1h\1y[1-4] FIGHT BARE-HANDED\1n   \1h\1w[B]\1n back\r\n');
	else console.print('  \1h\1w[1-4]\1n TAKE   \1h\1w[B]\1nARE HANDS   ' + (v.canSkip ? '\1h\1w[S]\1nKIP ROOM   ' : '') + '\1h\1w[Q]\1nUIT\r\n');
}

// one line for what a move did
function said(events) {
	var out = [];
	(events || []).forEach(function (e) {
		if (e.type === 'fight') out.push(e.armed ? 'Slew ' + rank(e.card) + ' with the blade (-' + e.damage + ')' : 'Fought ' + rank(e.card) + ' bare-handed (-' + e.damage + ')');
		else if (e.type === 'heal') out.push('Healed ' + e.amount);
		else if (e.type === 'potion_wasted') out.push('Health wasted (one a room)');
		else if (e.type === 'equip') out.push('Picked up a blade: ' + rank(e.card));
		else if (e.type === 'skip') out.push('Skipped the room');
	});
	return out.join('.  ');
}

function board(st) {
	var b = api('/api/leaderboard?day=' + st.day);
	header(st.name, st, 'BOARD');
	if (b.error) { console.print('\r\n  \1h\1r' + b.error + '\1n\r\n'); }
	else {
		console.print('\r\n  ' + b.played + ' played today, ' + b.won + ' cleared the deck\r\n\r\n');
		(b.top || []).slice(0, 15).forEach(function (r) {
			console.print('  ' + lpad(r.rank, 3) + '.  ' + pad(r.name, 18) + lpad(r.score, 5) + '   ' + (r.status === 'won' ? '\1h\1gcleared\1n' : '\1h\1rdied\1n') + '\r\n');
		});
		if (b.you) console.print('\r\n  \1h\1wYOU\1n  #' + b.you.rank + '  score ' + b.you.score + '\r\n');
	}
	console.print('\r\n  \1h\1w[B]\1nACK');   // any key goes back; [B] gives a tap something to press
	console.getkey(K_NOCRLF);
}

function endScreen(st) {
	var r = st.run;
	header(st.name, st, r.status === 'won' ? 'CLEARED' : 'DELETED');
	console.print('\r\n  ' + (r.status === 'won' ? '\1h\1gYou cleared the deck.' : '\1h\1rThe dungeon got you.') + '\1n\r\n');
	console.print('\r\n  \1h\1wSCORE\1n ' + r.score + '\r\n');
	if (r.marks) console.print('\r\n  ' + [].concat(r.marks).join('').replace(/[^\x20-\x7e]/g, function (ch) { return { '\u21b7': '>', '⚔': 'x', '‼': '!', '♥': '+', '·': '.' }[ch] || '?'; }) + '\r\n');
	console.print('\r\n  Come back tomorrow for a new deck.\r\n\r\n  \1h\1w[B]\1nOARD   \1h\1w[Q]\1nUIT');
	for (;;) { var k = console.getkey(K_UPPER | K_NOCRLF); if (k === 'B') { board(st); return endScreen(st); } if (k === 'Q' || k === '\x1b') return; }
}

function play() {
	console.clear();
	console.print('\1h\1yscoundrel.exe\1n  dealing...\r\n');
	var st = api('/api/today');
	if (st.error) { console.print('\r\n  \1h\1r' + st.error + '\1n\r\n'); console.pause(); return; }
	var name = st.name;
	if (!st.run && st.unfinished) st.run = st.unfinished;   // a run started just before midnight can still be finished
	if (!st.run) {
		header(name, st, 'TITLE');
		console.print('\r\n  A daily dungeon in a deck of cards. Everyone plays the same deck today.\r\n');
		console.print('  Demons hurt you, blades fight for you, health heals you. Clear the deck to win.\r\n\r\n');
		console.print('  \1h\1w[P]\1nLAY   \1h\1w[B]\1nOARD   \1h\1w[Q]\1nUIT');
		for (;;) {
			var k = console.getkey(K_UPPER | K_NOCRLF);
			if (k === 'Q' || k === '\x1b') return;
			if (k === 'B') { board(st); return play(); }
			if (k === 'P' || k === '\r') break;
		}
		var s = api('/api/start', {});
		if (s.error) { console.print('\r\n\r\n  \1h\1r' + s.error + '\1n\r\n'); console.pause(); return; }
		st.run = s.run; st.name = name = s.name || name;
	}
	var msg = '', bare = false;
	while (st.run.status === 'playing') {
		drawRun(st, msg, bare);
		var k = console.getkey(K_UPPER | K_NOCRLF);
		if (k === 'Q' || k === '\x1b') { if (bare) { bare = false; continue; } return; }
		if (k === 'B') { bare = !bare; msg = ''; continue; }
		var action = null, v = st.run.view;
		if (k === 'S' && !bare) action = { type: 'skip' };
		if (k >= '1' && k <= '4') {
			var i = v.slots[Number(k) - 1];
			if (i == null) continue;
			var c = v.room[i];
			if (bare && c.kind !== 'monster') { msg = '\1h\1yOnly demons can be fought bare-handed.'; continue; }
			// a demon the blade can't hit is fought bare-handed
			var canBlade = v.legal.some(function (a) { return a.type === 'take' && a.card === i && !a.bare; });
			action = { type: 'take', card: i };
			if (bare || (c.kind === 'monster' && !canBlade)) action.bare = true;
		}
		if (!action) continue;
		var r = api('/api/move', { day: st.run.day, n: st.run.n, action: action });
		if (r.error) { msg = '\1h\1r' + r.error; if (r._code == 409) { var t = api('/api/today'); if (t.run) st.run = t.run; } continue; }
		msg = said(r.events); bare = false;
		st.run = r;
	}
	endScreen(st);
}

play();
console.clear();
