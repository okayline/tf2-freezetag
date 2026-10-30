// NANO PITCH in the 88x31 BBS: the same games as pitch.88x31.app (the numbered games and the Daily game everyone shares),
// played on its server, which deals, keeps the rules and plays the three bots. This door only draws the table and sends
// your bid or card.
// Who you are: a NANO PITCH guest player for this BBS user, no 88x31 account. The first time, the door asks the server for
// one (POST /api/bbs-enter with the accounts key) and keeps its login in data/pitch/<user number>.tok. The BBS's one shared
// Guest account (telnet) gets a new player each visit, never kept. Every request sends the BBS user number with the key, so
// the server counts its limits for each BBS user instead of for the BBS's one internet address.
// (made by bbs/setup.sh from the repo's bbs/xtrn/pitch.js; do not edit here)
load('sbbsdefs.js');
load('http.js');

var SITE = 'https://pitch.88x31.app';
var DIR = system.data_dir + 'pitch/';
var UNREACHABLE = "Can't reach the table right now. Try again in a moment.";
var GUEST = (typeof UFLAG_G !== 'undefined' && (user.security.restrictions & UFLAG_G)) || String(user.alias).toLowerCase() === 'guest';

// ---------- the server ----------
function key() {
	var f = new File(system.ctrl_dir + 'secrets/accounts-key');
	if (!f.open('r')) return '';
	var x = f.read(); f.close();
	return x.replace(/\s+$/, '');
}
var KEY = key(), TOKEN = null;
function headers() { var h = { 'x-accounts-key': KEY, 'x-bbs-user': String(user.number) }; if (TOKEN) h.cookie = 'np=' + TOKEN; return h; }
function parse(r, b) {
	var j; try { j = JSON.parse(b); } catch (e) { j = { error: UNREACHABLE }; }
	if (!j || typeof j !== 'object') j = { error: UNREACHABLE };
	j._code = r.response_code;
	return j;
}
function get(path) { var r = new HTTPRequest(undefined, undefined, headers(), 20), b; try { b = r.Get(SITE + path); } catch (e) { return { error: UNREACHABLE }; } return parse(r, b); }
function post(path, body) { var r = new HTTPRequest(undefined, undefined, headers(), 20), b; try { b = r.Post(SITE + path, JSON.stringify(body), undefined, undefined, 'application/json'); } catch (e) { return { error: UNREACHABLE }; } return parse(r, b); }

// this BBS user's login: kept from last time, or a new guest player
function signIn() {
	var f = new File(DIR + user.number + '.tok');
	if (!GUEST && f.exists && f.open('r')) { var t = f.read().replace(/\s+$/, ''); f.close(); if (t) { TOKEN = t; return true; } }
	var e = post('/api/bbs-enter', {});
	if (!e.token) return false;
	TOKEN = e.token;
	if (!GUEST) { mkpath(DIR); if (f.open('w')) { f.write(TOKEN); f.close(); } }
	return true;
}

// ---------- drawing (80 columns, 23 rows) ----------
// The table is a small + on the left: North on top, West and East in the middle, you (South) below; your hand is on the
// bottom lines. Down the right side: what just happened at the top, then the round's info.
var SUIT = ['\x05', '\x04', '\x03', '\x06']   // the old DOS (CP437) card suits: club, diamond, heart, spade
, SUIT_NAME = ['CLUBS', 'DIAMONDS', 'HEARTS', 'SPADES'];
var RANK = { 10: '10', 11: 'J', 12: 'Q', 13: 'K', 14: 'A' };
var W = 78;   // drawing width (a 1-column margin each side)
function pad(s, n) { s = String(s); while (s.length < n) s += ' '; return s.substr(0, n); }
function sp(n) { return n > 0 ? Array(n + 1).join(' ') : ''; }
function k(c) { return '\1h\1w[' + c + ']\1n'; }
function cardText(c) { var r = c % 13 + 2; return RANK[r] || String(r); }
function cardColor(c) { var s = Math.floor(c / 13); return s === 1 || s === 2 ? '\1h\1r' : '\1h\1b'; }

// a card picture, 8 wide and 4 tall: rank top left, suit bottom right. null = an empty spot; dim = can't be played.
function card(c, dim) {
	if (c == null) return ['\1n\1k\1h\xda\xc4\xc4\xc4\xc4\xc4\xc4\xbf\1n', '\1n\1k\1h\xb3      \xb3\1n', '\1n\1k\1h\xb3      \xb3\1n', '\1n\1k\1h\xc0\xc4\xc4\xc4\xc4\xc4\xc4\xd9\1n'];
	var col = dim ? '\1n\1k\1h' : cardColor(c), r = cardText(c);
	var su = SUIT[Math.floor(c / 13)];   // like a real card: rank and suit top left, suit and rank bottom right
	return [col + '\xda\xc4\xc4\xc4\xc4\xc4\xc4\xbf\1n', col + '\xb3' + pad(r + su, 6) + '\xb3\1n', col + '\xb3' + sp(6 - r.length - 1) + su + r + '\xb3\1n', col + '\xc0\xc4\xc4\xc4\xc4\xc4\xc4\xd9\1n'];
}

// one screen line made of pieces at fixed columns: [[col, text, visible width], ...]
function line(parts) {
	var out = '', at = 0;
	parts.forEach(function (p) { if (p[0] > at) { out += sp(p[0] - at); at = p[0]; } out += p[1]; at += p[2]; });
	return out;
}

function seatName(v, seat) { return seat === 0 ? 'YOU' : v.cast[seat].name.toUpperCase(); }
function bidOf(v, seat) {
	if (v.out && v.out[seat]) return 'SAT OUT';
	var b = null; (v.bids || []).forEach(function (x) { if (x.seat === seat) b = x.bid; });
	return b === null ? '' : b === 0 ? 'PASS' : 'BID ' + b;
}
function played(v, seat) { var c = null; (v.trick || []).forEach(function (p) { if (p.seat === seat) c = p.card; }); return c; }
// a seat's label: > when it's their turn, the name, their points, their bid this round. [text, visible width]
function seatLabel(v, seat) {
	var turn = v.turn === seat && v.phase !== 'done', b = bidOf(v, seat), plain = (turn ? '> ' : '') + seatName(v, seat) + '  ' + v.totals[seat] + (b ? '  ' + b : '');
	return [(turn ? '\1h\1y> ' : '') + '\1h\1w' + seatName(v, seat) + '\1n  \1h\1w' + v.totals[seat] + '\1n' + (b ? '\1n\1c  ' + b : '') + '\1n', plain.length];
}
function wrap(text, w) {
	var out = [], l = '';
	String(text).split(' ').forEach(function (word) { if (!l) l = word; else if (l.length + 1 + word.length <= w) l += ' ' + word; else { out.push(l); l = word; } });
	if (l) out.push(l);
	return out;
}

// the round's points so far, for the right side: trump and bid, High, Low and Jack, and each seat's game points.
// Card points: 10 is 10, A 4, K 3, Q 2, J 1 (the engine's gamePoints). High and Low go to whoever played that trump,
// Jack to whoever won the trick holding it (the engine's scoreHand).
var GAME_PTS = { 10: 10, 14: 4, 13: 3, 12: 2, 11: 1 };
function first(v, seat) { return seat === 0 ? 'YOU' : seatName(v, seat); }   // (full names: two bots can share a first word)
function sideInfo(v) {
	var out = [], t = v.trump, high = null, low = null, jack = null, pts = [0, 0, 0, 0];
	function cardStr(c) { return cardText(c) + SUIT[Math.floor(c / 13)]; }
	(v.tricks || []).forEach(function (tr) { tr.plays.forEach(function (p) { pts[tr.winner] += GAME_PTS[p.card % 13 + 2] || 0; if (t != null && Math.floor(p.card / 13) === t && p.card % 13 + 2 === 11) jack = { card: p.card, seat: tr.winner }; }); });
	(v.tricks || []).map(function (tr) { return tr.plays; }).concat([v.trick || []]).forEach(function (plays) {
		plays.forEach(function (p) { if (t == null || Math.floor(p.card / 13) !== t) return; if (!high || p.card > high.card) high = p; if (!low || p.card < low.card) low = p; });
	});
	function item(label, val) { return [label + ' \1h\1w' + val + '\1n', label.length + 1 + val.length]; }
	out.push(item('TRUMP', t == null ? '-' : SUIT_NAME[t]));
	out.push(item('BID', v.pitcher == null ? '-' : first(v, v.pitcher) + ' ' + v.bid));
	out.push(item('HIGH', high ? cardStr(high.card) + ' ' + first(v, high.seat) : '-'));
	out.push(item('LOW', low ? cardStr(low.card) + ' ' + first(v, low.seat) : '-'));
	out.push(item('JACK', jack ? first(v, jack.seat) : '-'));
	var g1 = 'YOU ' + pts[0] + '   ' + first(v, 1) + ' ' + pts[1], g2 = first(v, 2) + ' ' + pts[2] + '   ' + first(v, 3) + ' ' + pts[3];
	out.push(['GAME \1h\1w' + g1 + '\1n', 5 + g1.length]);
	out.push(['\1h\1w' + g2 + '\1n', g2.length]);
	return out;
}

function draw(v, bbsName, said, prompt) {
	var meta = G || {};
	// the play area is a small + on the left: West at L, North and you at MID, East at R. Names sit on the line above each
	// card, left-aligned with it. What just happened runs down the right side, right-justified, newest at the bottom.
	var L = 4, MID = 17, R = 30, rows = [];
	// the right side: what just happened at the top (newest at the bottom, older lines scroll up), then the round's info,
	// all right-justified
	var NX = 46, NR = W, SIDE = 15, info = sideInfo(v);
	var news = [];
	(said || []).forEach(function (t) { news = news.concat(wrap(t, NR - NX)); });
	news = news.slice(-(SIDE - info.length - 1));
	var side = news.map(function (t) { return ['\1h\1y' + t + '\1n', t.length]; });
	while (side.length < SIDE - info.length - 1) side.unshift(null);
	side.push(null);
	side = side.concat(info);
	function withNews(parts, i) { var t = side[i]; if (t) parts.push([NR - t[1], t[0], t[1]]); return line(parts); }
	rows.push(' \1h\1mNANO PITCH\1n  //  \1h\1w' + bbsName + '\1n  //  ' + (meta.daily ? 'DAILY #' + meta.game : 'GAME ' + meta.game) + '  //  ROUND ' + ((v.history || []).length + (v.over ? 0 : 1)) + '  //  FIRST TO ' + v.target);
	rows.push('\1n\1b' + Array(W + 2).join('\xc4') + '\1n');
	var nr = 0;   // the news line next to each table line
	var n = seatLabel(v, 2);
	rows.push(withNews([[MID, n[0], n[1]]], nr++));
	card(played(v, 2)).forEach(function (c) { rows.push(withNews([[MID, c, 8]], nr++)); });
	var w = seatLabel(v, 1), e = seatLabel(v, 3);
	rows.push(withNews([[L, w[0], w[1]], [Math.max(R, L + w[1] + 2), e[0], e[1]]], nr++));
	var cw = card(played(v, 1)), ce = card(played(v, 3));
	for (var i = 0; i < 4; i++) rows.push(withNews([[L, cw[i], 8], [R, ce[i], 8]], nr++));
	// you
	var cs = card(played(v, 0));
	for (i = 0; i < 4; i++) rows.push(withNews([[MID, cs[i], 8]], nr++));
	var s = seatLabel(v, 0);
	rows.push(withNews([[MID, s[0], s[1]]], nr++));
	// the prompt, then your hand on the bottom lines: numbers to press over the playable cards
	rows.push(prompt ? ' ' + prompt[0] : '');
	var hand = v.hand || [], gap = 3, startX = Math.floor((W - (hand.length * 8 + (hand.length - 1) * gap)) / 2);
	var keys = [], pics = [[], [], [], []];
	hand.forEach(function (c, j) {
		var ok = !v.legal || v.legal.indexOf(c) >= 0, x = startX + j * (8 + gap), pic = card(c, !ok);
		if (ok && v.phase === 'play' && v.turn === 0) keys.push([x + 2, k(j + 1), 3]);
		for (var r = 0; r < 4; r++) pics[r].push([x, pic[r], 8]);
	});
	rows.push(line(keys));
	pics.forEach(function (p) { rows.push(line(p)); });
	console.clear();
	rows.forEach(function (r, j) { console.print(' ' + r + (j < rows.length - 1 ? '\r\n' : '')); });
}

// ---------- what happened (the feed) ----------
// Worked out from the game as the server sends it, so nothing has to be remembered between moves: the last finished
// round's result, then this round's deal, bids, cards and tricks, in order. The newest lines are shown.
function full(v, seat) { return seat === 0 ? 'YOU' : seatName(v, seat); }
function said(g) {
	var v = g.view, out = [], h = v.history && v.history[v.history.length - 1];
	function cs(c) { return cardText(c) + SUIT[Math.floor(c / 13)]; }
	if (h) {
		out.push('ROUND ' + (h.no + 1) + ': ' + full(v, h.pitcher) + (h.made ? ' MADE IT.' : h.pitcher === 0 ? ' WERE SET.' : ' WAS SET.'));
		out.push('HIGH ' + full(v, h.high.seat) + '  LOW ' + full(v, h.low.seat));
		out.push((h.jack ? 'JACK ' + full(v, h.jack.seat) + '  ' : '') + (h.gameWinner == null ? 'GAME TIED' : 'GAME ' + full(v, h.gameWinner)));
	}
	if (v.over) return out;
	out.push(full(v, v.dealer) + (v.dealer === 0 ? ' DEAL.' : ' DEALS.'));
	(v.bids || []).forEach(function (b) {
		var me = b.seat === 0;
		out.push(full(v, b.seat) + (b.bid === 0 ? (me ? ' PASS.' : ' PASSES.') : b.forced ? (me ? ' ARE STUCK WITH 2.' : ' IS STUCK WITH 2.') : (me ? ' BID ' : ' BIDS ') + b.bid + '.'));
	});
	(v.tricks || []).forEach(function (t) {
		t.plays.forEach(function (p) { out.push(full(v, p.seat) + '  ' + cs(p.card)); });
		out.push(full(v, t.winner) + (t.winner === 0 ? ' TAKE IT.' : ' TOOK IT.'));
	});
	(v.trick || []).forEach(function (p) { out.push(full(v, p.seat) + '  ' + cs(p.card)); });
	return out;
}

// ---------- playing ----------
var G = null, FLASH = '';
function take(r) { if (r && r.view) G = r; }
function act(action) {
	var r = post('/api/act', { game: G.game, daily: !!G.daily, n: G.n, action: action });
	take(r);   // a refused move (another tab moved on) still sends the game as it stands
	FLASH = r.error ? String(r.error).toUpperCase() : '';
}
function getkey() { return console.getkey(K_UPPER | K_NOCRLF); }
function show(prompt) { var s = said(G); if (FLASH) s = s.concat([FLASH]); draw(G.view, system.name, s, [prompt]); }

function gameOver() {
	var v = G.view, f = G.field, line = 'YOU PLACED ' + v.place + ' OF 4';
	if (f && f.games) line += '.  THIS GAME SO FAR: ' + f.games + ' PLAYED';
	show(line + '     ' + k('N') + 'EXT GAME   ' + k('Q') + 'UIT');
	for (;;) {
		var c = getkey();
		if (c === 'Q' || c === '\x1b') return false;
		if (c === 'N') { var r = post('/api/play', {}); take(r); FLASH = r.error ? String(r.error).toUpperCase() : ''; return true; }
	}
}

function main() {
	console.clear();
	console.print('\r\n  \1h\1mNANO PITCH\1n   shuffling...\r\n');
	if (!signIn()) { console.print('\r\n  \1h\1r' + UNREACHABLE + '\1n\r\n\r\n'); console.pause(); return; }
	var r = get('/api/game');
	if (!r.view) { console.print('\r\n  \1h\1r' + (r.error || UNREACHABLE) + '\1n\r\n\r\n'); console.pause(); return; }
	G = r;
	for (;;) {
		var v = G.view;
		if (v.over) { if (!gameOver()) return; continue; }
		if (v.turn === 0 && v.phase === 'bid') {
			var opts = v.bidOptions || [], p = 'YOUR BID?  ';
			if (opts.indexOf(0) >= 0) p += ' ' + k('P') + 'ASS ';
			opts.forEach(function (b) { if (b) p += ' ' + k(b) + ' '; });
			show(p + '    ' + k('Q') + 'UIT');
			var c = getkey();
			if (c === 'Q' || c === '\x1b') return;   // the game stays on the server: come back to it
			var bid = c === 'P' ? 0 : Number(c);
			if ((c === 'P' || (c >= '2' && c <= '4')) && opts.indexOf(bid) >= 0) act({ type: 'bid', bid: bid });
			continue;
		}
		if (v.turn === 0 && v.phase === 'play') {
			show('YOUR CARD?' + '                                    ' + k('Q') + 'UIT');
			var d = getkey();
			if (d === 'Q' || d === '\x1b') return;
			var card = v.hand[Number(d) - 1];
			if (d >= '1' && d <= '9' && card != null && (!v.legal || v.legal.indexOf(card) >= 0)) act({ type: 'play', card: card });
			continue;
		}
		// not your turn (shouldn't happen: the server plays the bots up to you): ask again
		r = get('/api/game'); if (r.view) G = r; else return;
	}
}

main();
console.clear();
