// Drugwar in the 88x31 BBS: the same game, bank, prices and board as dw.88x31.app.
// The game runs on Drugwar's server (rules, prices and dice); this door only draws it and sends the moves.
// Who you are: a Drugwar bank (an 8-digit code) made for this BBS user the first time and kept in
// data/drugwar/<user number>.code. VISIT BANK, CODE shows it, and can switch to another bank (one from the web site).
// Every request sends the BBS user number with the shared accounts key, so the server counts its limits (new banks,
// runs, moves) for each BBS user instead of for the BBS's one internet address.
// (made by bbs/setup.sh from the repo's bbs/xtrn/drugwar.js; do not edit here)
load('sbbsdefs.js');
load('http.js');

var SITE = 'https://dw.88x31.app';
var DIR = system.data_dir + 'drugwar/';
var DRUGS = ['COCAINE', 'HEROINE', 'ACID', 'WEED', 'SPEED', 'LUDES'];
var PLACES = ['BRONX', 'GHETTO', 'CENTRAL PARK', 'MANHATTEN', 'CONEY ISLAND', 'BROOKLYN'];
var ASK = {
	gun: function (p) { return 'WILL YOU BUY A ' + p.gun + ' FOR 400 DOLLARS?'; },
	weed: function () { return "THERE'S SOME WEED HERE THAT SMELLS LIKE GOOD STUFF!! WILL YOU SMOKE IT?"; },
	coat: function () { return 'WILL YOU BUY A NEW TRENCHCOAT WITH MORE POCKETS FOR 200 BUCKS?'; },
	doc: function () { return 'WILL YOU PAY 1000 DOLLARS FOR A DOCTOR TO SEW YOU UP?'; }
};
var UNREACHABLE = "CAN'T REACH THE STREET. TRY AGAIN LATER.";

// ---------- the server ----------
function key() {
	var f = new File(system.ctrl_dir + 'secrets/accounts-key');
	if (!f.open('r')) return '';
	var k = f.read(); f.close();
	return k.replace(/\s+$/, '');
}
var KEY = key();
function headers() { return { 'x-accounts-key': KEY, 'x-bbs-user': String(user.number) }; }
function parse(r, b) {
	var j; try { j = JSON.parse(b); } catch (e) { j = { error: UNREACHABLE }; }
	if (!j || typeof j !== 'object') j = { error: UNREACHABLE };
	j._code = r.response_code;
	return j;
}
function get(path) {
	var r = new HTTPRequest(undefined, undefined, headers(), 20), b;
	try { b = r.Get(SITE + path); } catch (e) { return { error: UNREACHABLE }; }
	return parse(r, b);
}
function post(path, body) {
	var r = new HTTPRequest(undefined, undefined, headers(), 20), b;
	try { b = r.Post(SITE + path, JSON.stringify(body), undefined, undefined, 'application/json'); } catch (e) { return { error: UNREACHABLE }; }
	return parse(r, b);
}

// this BBS user's bank code: kept from last time, or a new bank
function codeFile() { return new File(DIR + user.number + '.code'); }
function saveCode(c) { mkpath(DIR); var f = codeFile(); if (f.open('w')) { f.write(c); f.close(); } }
var CODE = null, NAME = '';
function loadBank() {
	var f = codeFile(), c = '';
	if (f.exists && f.open('r')) { c = f.read().replace(/\s+$/, ''); f.close(); }
	var r = c ? get('/api/bank?code=' + c) : null;
	if (!r || r._code == 404) {   // no code yet, or the bank is gone: a new one
		r = post('/api/bank/new', {});
		if (r.error) return r;
		saveCode(r.code);
	}
	if (r.error) return r;
	CODE = r.code; NAME = r.name || '';
	return r;
}

// ---------- drawing ----------
function fmt(n) { n = String(Math.round(n)); var neg = n.charAt(0) === '-'; if (neg) n = n.slice(1); while (/\d{4}/.test(n)) n = n.replace(/(\d)(\d{3})(?!\d)/, '$1,$2'); return (neg ? '-' : '') + n; }
function pad(s, n) { s = String(s); while (s.length < n) s += ' '; return s; }
function lpad(s, n) { s = String(s); while (s.length < n) s = ' ' + s; return s; }
function k(c) { return '\1h\1w[' + c + ']\1n'; }   // a key, bright, in brackets (so a tap can press it)
function wrap(text, w) {
	var out = [];
	String(text).split('\n').forEach(function (para) {
		if (!para) { out.push(''); return; }
		var line = '';
		para.split(' ').forEach(function (word) {
			if (!line) line = word;
			else if (line.length + 1 + word.length <= w) line += ' ' + word;
			else { out.push(line); line = word; }
		});
		out.push(line);
	});
	return out;
}

var g = null, V = 0;   // the run as the server last sent it, and the bank balance
function take(r) { if (r.run) g = r.run; if (r.balance != null) V = r.balance; }

// the whole screen: header, money, prices and coat, what happened, then the bottom prompt lines
function draw(said, bottom) {
	console.clear();
	console.print(' \1h\1yDRUGWAR v2.00\1n  //  \1h\1w' + (NAME || 'NO NAME').toUpperCase() + '\1n  //  DAY ' + Math.min(g.move, 30) + ' OF 30  //  \1h\1c' + PLACES[g.loc] + '\1n\r\n');
	console.print('\1n\1b' + Array(81).join('\xc4') + '\1n\r\n\r\n');
	console.print('  CASH \1h\1w$' + pad(fmt(g.cash), 9) + '\1n  DEBT \1h\1w$' + pad(fmt(g.debt), 9) + '\1n  BANK \1h\1w$' + pad(fmt(V), 9) + '\1n  GUNS \1h\1w' + pad(g.guns, 4) + '\1n  DAMMAGE \1h\1w' + g.damage + '\1n\r\n\r\n');
	console.print('  ' + pad('DRUG', 15) + lpad('BUY AT', 7) + lpad('SELLS FOR', 14) + lpad('IN COAT', 13) + '\r\n');
	for (var i = 0; i < 6; i++)
		console.print('  ' + k(i + 1) + ' ' + pad(DRUGS[i], 11) + lpad('$' + fmt(g.prices[i]), 7) + lpad('$' + fmt(g.sell[i]), 14) + lpad(g.st[i], 13) + '\r\n');
	console.print(lpad('', 37) + 'COAT ' + g.coat + '   FREE ' + g.free + '\r\n\r\n');
	var lines = [];
	(said || []).forEach(function (m) { lines = lines.concat(wrap(m, 76)); });
	lines.slice(-6).forEach(function (l) { console.print('  \1h\1y' + l + '\1n\r\n'); });
	if (lines.length) console.print('\r\n');
	(bottom || []).forEach(function (l, j) { console.print('  ' + l + (j < bottom.length - 1 ? '\r\n' : '')); });
}
var MENU = k('B') + 'UY   ' + k('S') + 'ELL   ' + k('J') + 'ET   ' + k('L') + 'OAN SHARK   ' + k('V') + 'ISIT BANK   ' + k('Q') + 'UIT';
var BACK = k('Q') + ' BACK';

function getkey() { return console.getkey(K_UPPER | K_NOCRLF); }
// a number typed at the bottom of the screen; null if left blank
function askNum(said, lines) {
	draw(said, lines.concat(['HOW MUCH? ']));
	var s = console.getstr(9, K_NUMBER | K_NOCRLF);
	if (!s) return null;
	var n = parseInt(s, 10);
	return n > 0 ? n : null;
}
function yesNo(said, text) {
	var t = wrap(text, 76);
	t[t.length - 1] += '   ' + k('Y') + 'ES   ' + k('N') + 'O';
	for (;;) { draw(said, t); var c = getkey(); if (c === 'Y') return true; if (c === 'N' || c === '\x1b') return false; }
}

// ---------- moves ----------
var said = [];   // the lines shown above the prompt: what the last move did, the news
function act(a, extra) {
	var body = { code: CODE, ver: g.ver, a: a };
	for (var x in extra || {}) body[x] = extra[x];
	var r = post('/api/run/act', body);
	if (r.error) {
		said = [r.error.toUpperCase()];
		var again = get('/api/run?code=' + CODE); if (again.run) take(again);
		return false;
	}
	take(r);
	said = r.msgs || [];
	return true;
}
// answer whatever the server is waiting on (a question, or the cops)
function settle() {
	while (g.pending && !g.over) {
		var p = g.pending;
		if (p.type !== 'chase') { var yes = yesNo(said, ASK[p.type](p)); act('answer', { yes: yes }); continue; }
		draw(said, ['PIGS ' + (p.d + 1) + '     GUNS ' + g.guns + '     DAMMAGE ' + g.damage + '          ' + k('R') + 'UN   ' + k('F') + 'IGHT']);
		var c = getkey();
		if (c === 'R') act('run'); else if (c === 'F') act('fight');
	}
}
function pickDrug(head, have) {   // 0-5, or -1 to go back
	for (;;) {
		draw(said, [head + '   ' + k('1') + '-' + k('6') + '   ' + BACK]);
		var c = getkey();
		if (c === 'Q' || c === '\x1b') return -1;
		if (c >= '1' && c <= '6' && (!have || g.st[Number(c) - 1] > 0)) return Number(c) - 1;
	}
}

function dealLine(d, i) { return k(i + 1) + ' ' + (d.mine ? '*' : '') + d.units + ' ' + DRUGS[d.drug] + ' $' + fmt(d.price); }
function buyDeal() {
	var r = get('/api/deals?city=' + g.loc + '&code=' + CODE);
	if (r.error) { said = [r.error.toUpperCase()]; return; }
	if (!r.deals.length) { said = ['NO DEALS HERE.']; return; }
	var lines = ['PLAYER DEALS'], row = '';
	r.deals.forEach(function (d, i) { row += pad(dealLine(d, i), 40); if (i % 2) { lines.push(row); row = ''; } });
	if (row) lines.push(row);
	lines.push(BACK);
	for (;;) {
		draw(said, lines);
		var c = getkey();
		if (c === 'Q' || c === '\x1b') return;
		var d = r.deals[Number(c) - 1];
		if (c >= '1' && c <= '9' && d) {
			if (d.mine) return;
			var max = Math.min(Math.floor(g.cash / d.price), g.free, d.units);
			var n = askNum(said, ['BUY ' + DRUGS[d.drug] + ' AT $' + fmt(d.price), 'YOU CAN BUY: ' + max]);
			if (!n || n > max) return;
			if (!act('buydeal', { id: d.id, units: n })) said = ['TOO LATE.'];
			return;
		}
	}
}
function buy() {
	draw(said, ['WHAT TO BUY?   ' + k('1') + '-' + k('6') + '   ' + k('D') + 'EALS FROM PLAYERS   ' + BACK]);
	var c = getkey();
	if (c === 'D') return buyDeal();
	if (!(c >= '1' && c <= '6')) return;
	var i = Number(c) - 1, afford = Math.floor(g.cash / g.prices[i]);
	var n = askNum(said, ['BUY ' + DRUGS[i] + ' AT $' + fmt(g.prices[i]), 'YOU CAN AFFORD: ' + afford + '     YOU CAN HOLD: ' + g.free]);
	if (!n || n > afford || n > g.free) return;
	act('buy', { drug: i, n: n });
}
function postDeal() {
	var i = pickDrug('DEAL WHICH?', true); if (i < 0) return;
	var n = askNum(said, ['DEAL ' + DRUGS[i], 'YOU HAVE: ' + g.st[i] + '     (UP TO 100)']);
	if (!n || n > g.st[i] || n > 100) return;
	var pr = askNum(said, ['DEAL ' + n + ' ' + DRUGS[i], 'PRICE EACH?']);
	if (!pr) return;
	if (!act('post', { drug: i, units: n, price: pr })) said = ['NO DEAL.'];
}
function sell() {
	draw(said, ['WHAT TO SELL?   ' + k('1') + '-' + k('6') + '   ' + k('D') + ' POST A DEAL   ' + BACK]);
	var c = getkey();
	if (c === 'D') return postDeal();
	if (!(c >= '1' && c <= '6')) return;
	var i = Number(c) - 1;
	var n = askNum(said, ['SELL ' + DRUGS[i] + ' FOR $' + fmt(g.sell[i]), 'YOU HAVE: ' + g.st[i]]);
	if (!n || n > g.st[i]) return;
	act('sell', { drug: i, n: n });
}
function jet() {
	var a = '', b = '';
	for (var i = 0; i < 6; i++) { var t = pad(k(i + 1) + ' ' + PLACES[i], 26); if (i < 3) a += t; else b += t; }
	draw(said, ['WHERE TO, DUDE?', a, b, k('Q') + ' OOPS... STAY!']);
	var c = getkey();
	if (!(c >= '1' && c <= '6')) return;
	if (!act('jet', { to: Number(c) - 1 })) return;
	if (!g.over) { said = said.concat(g.news || []); settle(); }
}
function loanShark() {
	if (g.loc !== 0) { said = ['THE LOAN SHARK ONLY DEALS IN THE BRONX.']; return; }
	draw(said, ['LOAN SHARK...   ' + k('R') + 'EPAY   ' + k('B') + 'ORROW   ' + BACK]);
	var c = getkey();
	if (c !== 'R' && c !== 'B') return;
	var n = askNum(said, ['YOU OWE: $' + fmt(g.debt) + '     CASH: $' + fmt(g.cash)]);
	if (!n) return;
	if (c === 'R') { if (n > g.cash || n > g.debt) return; act('loan', { kind: 'repay', n: n }); }
	else { if (n > 5000) { said = ["YOU THINK HE'S CRAZY, MAN?!"]; return; } act('loan', { kind: 'borrow', n: n }); }
}
function board() {
	var r = get('/api/board');
	if (r.error) { said = [r.error.toUpperCase()]; return; }
	if (!r.board.length) { said = ["NOBODY IS ON TODAY'S BOARD YET."]; return; }
	said = ["TODAY'S BEST:"];
	var row = '';
	r.board.forEach(function (e, i) { row += pad(lpad(i + 1, 2) + ' ' + pad(e.name.toUpperCase(), 18) + ' $' + fmt(e.money), 38); if (i % 2) { said.push(row); row = ''; } });
	if (row) said.push(row);
}
function bank() {   // returns true if the bank changed (another code), so the run is loaded again
	if (g.loc !== 0) { said = ['THE BANK IS IN THE BRONX.']; return false; }
	act('collect');
	for (;;) {
		draw(said, [' BANK    ' + k('D') + 'EPOSIT   ' + k('W') + 'ITHDRAW   ' + k('C') + 'ODE   ' + k('N') + 'AME   ' + k('B') + 'OARD   ' + BACK]);
		var c = getkey();
		if (c === 'Q' || c === '\x1b') return false;
		if (c === 'B') { board(); continue; }
		if (c === 'N') { var r = post('/api/name', { code: CODE }); if (r.name) { NAME = r.name; said = ['YOU ARE NOW: ' + NAME.toUpperCase()]; } else said = [(r.error || UNREACHABLE).toUpperCase()]; continue; }
		if (c === 'C') {
			said = ['YOUR BANK CODE: ' + CODE];
			if (!yesNo(said, 'USE ANOTHER CODE?')) continue;
			draw(said, ['ENTER THE CODE: ']);
			var s = console.getstr(8, K_NUMBER | K_NOCRLF);
			if (!s) continue;
			var b = get('/api/bank?code=' + s);
			if (!b.code) { said = ['NO SUCH BANK.']; continue; }
			saveCode(b.code); CODE = b.code; NAME = b.name || ''; said = [];
			return true;
		}
		if (c === 'D' || c === 'W') {
			var n = askNum(said, ['BALANCE: $' + fmt(V) + '     CASH: $' + fmt(g.cash)]);
			if (n === null) continue;
			if (c === 'D') { if (n > g.cash) continue; act('bank', { kind: 'deposit', n: n }); }
			else { if (n > V) continue; act('bank', { kind: 'withdraw', n: n }); }
		}
	}
}

// ---------- a game ----------
function loadRun() {   // this bank's live run, or a new one. false if the street can't be reached.
	var r = get('/api/run?code=' + CODE), fresh = false;
	if (r.error) { said = [r.error.toUpperCase()]; return false; }
	if (!r.run) { r = post('/api/run/start', { code: CODE }); fresh = true; if (r.error) { said = [r.error.toUpperCase()]; return false; } }
	take(r);
	said = (fresh ? r.msgs || [] : []).concat(g.news || []);
	return true;
}
function game() {   // true to play again
	if (!loadRun()) { console.clear(); console.print('\r\n  \1h\1r' + said.join(' ') + '\1n\r\n\r\n'); console.pause(); return false; }
	settle();
	while (!g.over) {
		draw(said, [MENU]);
		var c = getkey(); said = [];
		if (c === 'Q' || c === '\x1b') return false;   // the run stays live on the server: come back to it
		if (c === 'B') buy();
		else if (c === 'S') sell();
		else if (c === 'J') jet();
		else if (c === 'L') loanShark();
		else if (c === 'V') { if (bank() && !loadRun()) return false; }
		settle();
	}
	console.clear();
	console.print('\r\n  \1h\1yGAME OVER!\1n\r\n\r\n');
	said.forEach(function (m) { wrap(m, 76).forEach(function (l) { console.print('  ' + l + '\r\n'); }); });
	console.print('\r\n  YOUR SCORE (ON A SCALE OF 1 TO 100) = \1h\1w' + g.score + '\1n\r\n\r\n');
	console.print('  CASH $' + fmt(g.cash) + '     BANK $' + fmt(V) + '     DEBT $' + fmt(g.debt) + '\r\n\r\n');
	console.print('  PLAY AGAIN?   ' + k('Y') + 'ES   ' + k('N') + 'O');
	for (;;) { var a = getkey(); if (a === 'Y') return true; if (a === 'N' || a === 'Q' || a === '\x1b') return false; }
}

console.clear();
console.print('\r\n  \1h\1yJ.M.\'S DRUGWAR\1n\r\n  VERSION 2.00\r\n\r\n  JUST SAY NO.\r\n\r\n  ...\r\n');
var b0 = loadBank();
if (b0.error) { console.print('\r\n  \1h\1r' + b0.error.toUpperCase() + '\1n\r\n\r\n'); console.pause(); }
else {
	console.print('\r\n  ' + k('P') + 'LAY');
	console.getkey(K_NOCRLF);   // any key starts; [P] gives a tap something to press
	while (game()) {}
}
console.clear();
