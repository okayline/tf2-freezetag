#!/usr/bin/env python3
"""Password-protected web page that shows the TF2 and L4D game logs, newest first.

Usage: logweb.py PORT PASSWORD_HASH_FILE   (listens on 127.0.0.1 only; Caddy puts it on the web)
The hash file holds "salt:sha256hex" where sha256hex = sha256(salt + password). The real password
never touches the server or the repo. Browser login: any user name, the password.
IP addresses are removed before anything is shown. Python standard library only."""
import glob
import hashlib
import hmac
import html
import base64
import os
import re
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

GAMES = {
    "tf2": ("TF2 Freeze Tag", "/home/tf2/server/tf/logs"),
    "l4d": ("L4D cLaSSiC", "/home/tf2/l4d/left4dead/logs"),
}
NOISE = re.compile(r'" stuck \(position|path_goal|rcon from|killed "infected<|picked up item weapon_(pistol|\w+_claw)|'
                   r'Director state change|SpawnMob|Pending mob|wanderers grabbed|Rescue spot|SetCharacter|changed model|'
                   r'Tongue (targeting|launching|took)|Preventing spawning|Pills visible|\[META\]|Log file (started|closed)|'
                   r'server_cvar|OnEndChangelevel|^\s+\S+\(\d+\), state|STEAM USERID validated|" connected, address')
KINDS = [
    ("chat", re.compile(r'" say(_team)? "')),
    ("join", re.compile(r'" (entered the game|disconnected)')),
    ("kill", re.compile(r'killed "|committed suicide|is incapacitated|pounced on|Tongue grab')),
    ("ff", re.compile(r'^\S.* attacked \S')),
    ("event", re.compile(r'World triggered|triggered "|Started map|scored "|spawned as a (TANK|WITCH)')),
]
IP = re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\b')
CLUTTER = re.compile(r'<setpos[^>]*>|<Area \d+>|\((attacker|victim|assister)_position "[^"]*"\)|\(position "[^"]*"\)')
STAMP = re.compile(r'^L (\d\d)/(\d\d)/(\d{4}) - (\d\d:\d\d:\d\d): ')
COLORS = {"chat": "#7ec8ff", "join": "#8be28b", "kill": "#ff8a8a", "ff": "#ffb36b", "event": "#e7c6ff", "other": "#aaa"}


def check(header, hash_file):
    try:
        salt, want = open(hash_file).read().strip().split(":", 1)
        kind, _, val = (header or "").partition(" ")
        if kind != "Basic":
            return False
        pw = base64.b64decode(val).decode("utf-8", "replace").split(":", 1)[-1]
        got = hashlib.sha256((salt + pw).encode()).hexdigest()
        return hmac.compare_digest(got, want)
    except Exception:
        return False


def classify(text):
    for k, rx in KINDS:
        if rx.search(text):
            return k
    return "other"


def read_lines(folder, files, everything):
    paths = sorted(glob.glob(os.path.join(folder, "[Ll]*.log")), key=os.path.getmtime)[-files:]
    out = []
    for p in paths:
        try:
            with open(p, encoding="utf-8", errors="replace") as f:
                for raw in f:
                    m = STAMP.match(raw)
                    if not m:
                        continue
                    text = raw[m.end():].rstrip()
                    if not everything and NOISE.search(text):
                        continue
                    text = CLUTTER.sub("", IP.sub("[ip]", text))
                    out.append(("%s-%s %s" % (m.group(1), m.group(2), m.group(4)), classify(text), text))
        except OSError:
            pass
    return out


def page(q):
    game = q.get("game", ["l4d"])[0]
    game = game if game in GAMES else "l4d"
    kind = q.get("kind", ["all"])[0]
    search = q.get("q", [""])[0][:60]
    everything = q.get("all", [""])[0] == "1"
    files = max(1, min(40, int(q.get("files", ["4"])[0] or 4))) if (q.get("files", ["4"])[0] or "4").isdigit() else 4
    title, folder = GAMES[game]
    rows = read_lines(folder, files, everything)
    if kind != "all":
        rows = [r for r in rows if r[1] == kind]
    if search:
        rows = [r for r in rows if search.lower() in r[2].lower()]
    rows = rows[-1500:][::-1]

    def link(**kw):
        p = {"game": game, "kind": kind, "q": search, "files": str(files), "all": "1" if everything else ""}
        p.update(kw)
        return "?" + "&".join("%s=%s" % (k, html.escape(v, True)) for k, v in p.items() if v)

    tabs = " ".join('<a class="tab%s" href="%s">%s</a>' % (" on" if g == game else "", link(game=g), GAMES[g][0]) for g in GAMES)
    kinds = " ".join('<a class="chip%s" href="%s" style="--c:%s">%s</a>' % (" on" if k == kind else "", link(kind=k), COLORS.get(k, "#ddd"), k)
                     for k in ["all", "chat", "join", "kill", "ff", "event", "other"])
    body = "\n".join('<div class="r"><span class="t">%s</span><span class="k" style="color:%s">%s</span><span>%s</span></div>'
                     % (t, COLORS[k], k, html.escape(x)) for t, k, x in rows) or '<p class="none">Nothing here yet.</p>'
    return """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>88x31 Logs</title><style>
:root{color-scheme:dark}body{margin:0;background:#16121c;color:#e8e2f0;font:14px/1.45 ui-monospace,Menlo,Consolas,monospace}
header{position:sticky;top:0;background:#221a2c;padding:12px 16px;border-bottom:1px solid #3a2e48}
h1{margin:0 0 8px;font:700 18px system-ui,sans-serif;color:#ff9ad5}
a{color:inherit;text-decoration:none}.tab{display:inline-block;padding:5px 12px;border-radius:8px;background:#2e2440;margin:0 4px 6px 0;font-family:system-ui}
.tab.on{background:#ff9ad5;color:#16121c;font-weight:700}.chip{display:inline-block;padding:2px 9px;border:1px solid var(--c);color:var(--c);border-radius:99px;margin:0 4px 4px 0}
.chip.on{background:var(--c);color:#16121c}form{margin-top:6px;display:flex;gap:6px;flex-wrap:wrap;align-items:center}
input[type=text]{background:#16121c;color:#fff;border:1px solid #4a3c5c;border-radius:6px;padding:5px 8px;min-width:0;flex:1 1 160px}
button{background:#ff9ad5;border:0;border-radius:6px;padding:5px 12px;font-weight:700}main{padding:8px 16px}
.r{display:flex;gap:10px;padding:2px 0;border-bottom:1px solid #221a2c;word-break:break-word}.t{color:#7d7090;white-space:nowrap}
.k{width:44px;flex:none}.none{color:#7d7090}label{font-family:system-ui;font-size:13px}small{color:#7d7090;font-family:system-ui}
</style></head><body><header><h1>~*~88x31~*~ server logs</h1>%s<div>%s</div>
<form><input type="hidden" name="game" value="%s"><input type="hidden" name="kind" value="%s">
<input type="text" name="q" placeholder="Search a name or word" value="%s">
<label><input type="checkbox" name="all" value="1" %s> show everything</label>
<label>maps back <input type="text" name="files" value="%d" style="width:3em;flex:none"></label><button>Go</button></form>
<small>%d lines, newest first. Times are server time (18 hours ahead of Hawaii).</small></header><main>%s</main></body></html>""" % (
        tabs, kinds, game, html.escape(kind, True), html.escape(search, True), "checked" if everything else "", files, len(rows), body)


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if not check(self.headers.get("Authorization"), HASH_FILE):
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="88x31 logs"')
            self.end_headers()
            return
        try:
            data = page(parse_qs(urlparse(self.path).query)).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(("error: %s" % type(e).__name__).encode())

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    HASH_FILE = sys.argv[2]
    # only reachable inside the server: Caddy (vps/Caddyfile) serves it on 80/443 as logs.88x31.app
    ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
