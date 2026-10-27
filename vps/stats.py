#!/usr/bin/env python3
"""Public stats page for all the game servers: one static HTML file built from the servers' game logs
(and, when reachable, a live look at each server over RCON on this machine).

Usage: stats.py OUTPUT [IGNORE_FILE] [DAYS] [LOGROOT]
  OUTPUT       where to write the page (written to a temp file first, then renamed)
  IGNORE_FILE  Steam IDs to leave out (one per line; kept on the VPS, never in the repo). Default /home/tf2/leaderboard-ignore.txt
  DAYS         how many days back to count (default 7)
  LOGROOT      folder that holds the servers (default /home/tf2); only used for testing with sample logs

Only human players are counted (never bots), by Steam account so a name change does not split a score.
The page shows player names only: never Steam IDs, addresses or chat. Times are Hawaii time (server clock minus 18 hours).
Python standard library only."""
import glob, html, importlib.util, os, re, sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta

SERVER_HOURS_AHEAD = 18   # the server clock is 18 hours ahead of Hawaii

TABS = [("cl", "cLaSSiC"), ("vs", "VeRsUs"), ("vg", "ViNtaGe"), ("tf", "TF2")]   # tab ids and labels, in SERVERS order

# name, kind, folder under LOGROOT (relative), log pattern, rcon port, server.cfg (relative)
SERVERS = [
    ("L4D cLaSSiC",           "l4d",   "l4d/left4dead",   "L*.log", 27016, "l4d/left4dead/cfg/server.cfg"),
    ("L4D VeRsUs SeRveR",     "l4dvs", "l4d-b/left4dead", "L*.log", 27017, "l4d-b/left4dead/cfg/server.cfg"),
    ("L4D ViNtaGe Edition",   "l4d",   "l4d-c/left4dead", "L*.log", 27018, "l4d-c/left4dead/cfg/server.cfg"),
    ("TF2 Freeze Tag",        "tf2",   "server/tf",       "l*.log", 27015, "server/tf/cfg/server.cfg"),
]

STAMP = re.compile(r'(\d\d)/(\d\d)/(\d{4}) - (\d\d):(\d\d):(\d\d)')
ID = r'(?P<id>STEAM_[0-9]:[0-9]:[0-9]+|\[U:1:[0-9]+\])'
WHO = re.compile(r'"(?P<name>.+?)<(?P<uid>\d+)><' + ID + r'><(?P<team>[^>]*)>')
TFKILL = re.compile(r'"(?P<name>.+?)<\d+><' + ID + r'><(?P<team>Red|Blue)>" killed "[^"]*<\d+><[^>]*><(?P<vteam>Red|Blue)>"')
KILL = re.compile(r'"(?P<name>.+?)<\d+><' + ID + r'><[^>]*>.*?" killed "(?P<victim>[A-Za-z ]+?)<')
SPECIALS = {"smoker", "boomer", "hunter", "tank", "witch"}
DMG = re.compile(r'\[88x31dmg\] <' + ID + r'> (?P<n>\d+) "(?P<name>.*)"\s*$')
MAPNAME = re.compile(r'(?:Started map|Loading map) "(?P<map>[^"]+)"')
CAMPAIGNS = [("hospital", "No Mercy"), ("smalltown", "Death Toll"), ("airport", "Dead Air"), ("farm", "Blood Harvest"),
             ("garage", "Crash Course"), ("river", "The Sacrifice")]
FINALE = re.compile(r'(?:hospital05_rooftop|smalltown05_houseboat|airport05_launch|farm05_cornfield|garage02_lots|river03_port)')


def account(steam_id):
    """STEAM_0:1:123, STEAM_1:1:123 and [U:1:247] are the same account: compare 1:123."""
    steam_id = steam_id.strip()
    m = re.fullmatch(r'\[U:1:(\d+)\]', steam_id)
    if m:
        w = int(m.group(1))
        return "%d:%d" % (w % 2, w // 2)
    return steam_id.split(":", 1)[-1]


def read_ignored(path):
    try:
        with open(path, encoding="utf-8") as f:
            return {account(l) for l in f if l.strip().upper().startswith("STEAM_")}
    except OSError:
        return set()


def now_hawaii():
    return datetime.now() - timedelta(hours=SERVER_HOURS_AHEAD)


def when(line):
    m = STAMP.search(line)
    if not m:
        return None
    mo, d, y, hh, mi, ss = map(int, m.groups())
    try:
        return datetime(y, mo, d, hh, mi, ss) - timedelta(hours=SERVER_HOURS_AHEAD)   # Hawaii time
    except ValueError:
        return None


def campaign_of(mapname):
    for key, label in CAMPAIGNS:
        if key in mapname:
            return label
    return None


class Stats:
    def __init__(self):
        self.players = {}                 # account -> latest name
        self.kills = Counter()            # common infected
        self.special_kills = Counter()
        self.damage = Counter()
        self.minutes = Counter()          # time present, per account
        self.sessions = 0
        self.tanks = 0
        self.witches = 0
        self.ff_hits = 0
        self.incaps = 0
        self.finales = 0
        self.maps = Counter()
        self.campaigns = Counter()
        self.by_hour = Counter()          # distinct players seen per Hawaii hour, summed over days
        self.by_day = defaultdict(set)    # date -> accounts
        self.longest = 0                  # longest single stay on one map, minutes
        self.freezes = Counter()          # tf2
        self.last_seen = None
        self.files = 0


def scan(kind, folder, pattern, since, ignored):
    s = Stats()
    for path in sorted(glob.glob(os.path.join(folder, "logs", pattern))):
        try:
            if datetime.fromtimestamp(os.path.getmtime(path)) < since + timedelta(hours=SERVER_HOURS_AHEAD):
                continue   # nothing in this file can be newer than the window
            f = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        first, last = {}, {}
        hours_seen = set()
        with f:
            s.files += 1
            for line in f:
                t = when(line)
                if t is None or t < since:
                    continue
                if s.last_seen is None or t > s.last_seen:
                    s.last_seen = t
                mm = MAPNAME.search(line)
                if mm:
                    s.maps[mm.group("map")] += 1
                    c = campaign_of(mm.group("map"))
                    if c:
                        s.campaigns[c] += 1
                    continue
                if "World triggered" in line and ("final_" in line or "finale" in line.lower()):
                    s.finales += 1
                d = DMG.search(line)
                if d:
                    a = account(d.group("id"))
                    if a not in ignored:
                        s.damage[a] += int(d.group("n"))
                        s.players[a] = d.group("name")
                    continue
                w = WHO.search(line)
                if not w or "BOT" in w.group("id"):
                    continue
                a = account(w.group("id"))
                if a in ignored:
                    continue
                s.players[a] = w.group("name")
                first.setdefault(a, t)
                last[a] = t
                key = (a, t.date(), t.hour)
                if key not in hours_seen:
                    hours_seen.add(key)
                    s.by_hour[t.hour] += 1
                    s.by_day[t.date()].add(a)
                if "entered the game" in line:
                    s.sessions += 1
                k = TFKILL.search(line) if kind == "tf2" else KILL.search(line)
                if k:
                    if kind == "tf2":
                        if k.group("team") != k.group("vteam"):
                            s.freezes[a] += 1
                        continue
                    victim = k.group("victim").strip().lower()
                    if victim == "infected":
                        s.kills[a] += 1
                    elif victim in SPECIALS:
                        s.special_kills[a] += 1
                        if victim == "tank":
                            s.tanks += 1
                        if victim == "witch":
                            s.witches += 1
                elif "incapacitated" in line:
                    s.incaps += 1
                elif " attacked " in line and "<Survivor>" in line:
                    s.ff_hits += 1
        for a in first:
            m = int((last[a] - first[a]).total_seconds() // 60)
            s.minutes[a] += m
            s.longest = max(s.longest, m)
    return s


def live(root, name, port, cfg):
    """(state, map, humans, max) from RCON on this machine; ("unknown", ...) when it can't be read."""
    try:
        spec = importlib.util.spec_from_file_location("dstatus", os.path.join(os.path.dirname(os.path.abspath(__file__)), "discord-status.py"))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        pw = mod.read_password(os.path.join(root, cfg))
        if not pw:
            return ("unknown", None, None, None)
        info = mod.parse(mod.rcon(port, pw, "status"))
        return ("online", info["map"], info["humans"], info["max"])
    except ConnectionRefusedError:
        return ("offline", None, None, None)
    except Exception:
        return ("unknown", None, None, None)


# ---------- page ----------

def esc(x):
    return html.escape(str(x))


def fmt(n):
    return format(int(n), ",")


def hm(minutes):
    h, m = divmod(int(minutes), 60)
    return "%dh %02dm" % (h, m) if h else "%dm" % m


def top(counter, players, n=10, unit=""):
    ranked = sorted(counter.items(), key=lambda kv: (-kv[1], players.get(kv[0], "").lower()))[:n]
    if not ranked:
        return '<p class="none">Nobody yet. Be the first!</p>'
    biggest = ranked[0][1] or 1
    rows = []
    for i, (a, v) in enumerate(ranked):
        shown = hm(v) if unit == "time" else fmt(v)
        rows.append('<li><span class="rk">%d</span><span class="nm">%s</span><span class="bar" style="--w:%d%%"></span>'
                    '<span class="vl">%s</span></li>' % (i + 1, esc(players.get(a, "?").strip()[:24]), max(4, round(100 * v / biggest)), shown))
    return '<ol class="rows">%s</ol>' % "".join(rows)


def hour_chart(by_hour):
    biggest = max(by_hour.values(), default=0) or 1
    cols = []
    for h in range(24):
        v = by_hour.get(h, 0)
        label = "%d%s" % ((h % 12) or 12, "a" if h < 12 else "p")
        cols.append('<div class="col" title="%s: %d player-hours"><i style="height:%d%%"></i><b>%s</b></div>'
                    % (label, v, round(100 * v / biggest) if v else 0, label if h % 3 == 0 else ""))
    return '<div class="chart">%s</div>' % "".join(cols)


def day_chart(by_day, days):
    today = now_hawaii().date()
    keys = [today - timedelta(days=i) for i in range(days - 1, -1, -1)]
    biggest = max((len(by_day.get(k, ())) for k in keys), default=0) or 1
    cols = []
    for k in keys:
        v = len(by_day.get(k, ()))
        cols.append('<div class="col" title="%s: %d players"><i style="height:%d%%"></i><b>%s</b></div>'
                    % (k.strftime("%b %d"), v, round(100 * v / biggest) if v else 0, k.strftime("%a")[:2]))
    return '<div class="chart">%s</div>' % "".join(cols)


def pie_list(counter, n=6):
    if not counter:
        return '<p class="none">Nothing yet.</p>'
    total = sum(counter.values())
    rows = "".join('<li><span class="nm">%s</span><span class="bar" style="--w:%d%%"></span><span class="vl">%d%%</span></li>'
                   % (esc(k), max(4, round(100 * v / total)), round(100 * v / total)) for k, v in counter.most_common(n))
    return '<ol class="rows">%s</ol>' % rows


def tile(label, value, sub=""):
    return '<div class="tile"><b>%s</b><span>%s</span>%s</div>' % (esc(value), esc(label), "<small>%s</small>" % esc(sub) if sub else "")


def server_section(name, kind, s, state, days):
    st, mp, humans, mx = state
    badge = {"online": '<span class="badge on">Online</span>', "offline": '<span class="badge off">Offline</span>'}.get(st, '<span class="badge">Unknown</span>')
    now = ""
    if st == "online":
        now = '<div class="now">Right now: <b>%s</b> players on <code>%s</code></div>' % (esc("%s/%s" % (humans, mx) if humans is not None else "?"), esc(mp or "?"))
    uniq = len(s.minutes)
    tiles = [tile("players this week", fmt(uniq)), tile("hours played", fmt(sum(s.minutes.values()) / 60))]
    boards = []
    if kind == "l4d":
        tiles += [tile("zombies killed", fmt(sum(s.kills.values()))), tile("special infected", fmt(sum(s.special_kills.values())), "%d Tanks, %d Witches" % (s.tanks, s.witches)),
                  tile("finales reached", fmt(s.finales)), tile("friendly fire hits", fmt(s.ff_hits)), tile("incapacitations", fmt(s.incaps))]
        boards = [("Most zombies killed", top(s.kills, s.players)), ("Most special infected killed", top(s.special_kills, s.players)),
                  ("Most time played", top(s.minutes, s.players, unit="time"))]
    elif kind == "l4dvs":
        tiles += [tile("damage dealt", fmt(sum(s.damage.values()))), tile("special infected killed", fmt(sum(s.special_kills.values())), "%d Tanks" % s.tanks),
                  tile("finales reached", fmt(s.finales)), tile("incapacitations", fmt(s.incaps))]
        boards = [("Most damage", top(s.damage, s.players)), ("Most time played", top(s.minutes, s.players, unit="time"))]
    else:
        tiles += [tile("freezes", fmt(sum(s.freezes.values()))), tile("maps played", fmt(sum(s.maps.values())))]
        boards = [("Most freezes", top(s.freezes, s.players)), ("Most time played", top(s.minutes, s.players, unit="time"))]
    tiles.append(tile("longest stay on one map", hm(s.longest)))
    maps = Counter({k: v for k, v in s.maps.items()})
    camp = pie_list(s.campaigns) if kind != "tf2" else pie_list(maps)
    camp_title = "Campaigns played" if kind != "tf2" else "Maps played"
    return """<section class="srv"><h2>%s %s</h2>%s<div class="tiles">%s</div>
<div class="grid">%s<div class="card"><h3>%s</h3>%s</div></div>
<div class="grid"><div class="card"><h3>When people play (Hawaii time)</h3>%s</div><div class="card"><h3>Players per day</h3>%s</div></div></section>""" % (
        esc(name), badge, now, "".join(tiles),
        "".join('<div class="card"><h3>%s</h3>%s</div>' % (esc(t), b) for t, b in boards), camp_title, camp,
        hour_chart(s.by_hour), day_chart(s.by_day, days))


CSS = """
:root{color-scheme:dark}*{box-sizing:border-box}
body{margin:0;background:#000;color:#f3e6ec;font:12px/1.5 Verdana,Arial,sans-serif}
.wrap{max-width:700px;margin:0 auto;padding:16px 14px 35px}
h1{margin:0;color:#e889b3;font-size:23px;text-align:center}.deco{text-align:center;color:#d9779f;letter-spacing:5px;margin:4px 0 16px}
h2{color:#f0a8c8;font-size:17px;margin:0 0 9px}h3{color:#e889b3;font-size:12px;margin:0 0 9px}
.sub{text-align:center;color:#a98;margin:-8px 0 18px;font-size:10px}
.srv{background:#141013;border:2px solid #c9668f;border-radius:14px;padding:14px 16px;margin:0 0 18px}
.badge{font-size:10px;border-radius:87px;padding:2px 9px;margin-left:7px;border:1px solid #777;color:#aaa;vertical-align:middle}
.badge.on{border-color:#4be09b;color:#4be09b}.badge.off{border-color:#e85d75;color:#e85d75}
.now{color:#cdeee6;margin:-4px 0 11px}code{color:#f6d4e3}
.tiles{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:9px;margin:0 0 12px}
.tile{background:#0b080a;border:1px solid #3a2330;border-radius:11px;padding:9px 11px}
.tile b{display:block;font-size:17px;color:#f6d4e3}.tile span{color:#c9a0b4;font-size:10px}.tile small{display:block;color:#8a6a7a;font-size:10px}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:11px;margin:0 0 11px}
.card{background:#0b080a;border:1px solid #3a2330;border-radius:11px;padding:11px 12px;min-width:0}
.rows{list-style:none;margin:0;padding:0}.rows li{position:relative;display:flex;gap:7px;align-items:center;padding:3px 5px;margin:2px 0;border-radius:5px;overflow:hidden}
.rows .bar{position:absolute;left:0;top:0;bottom:0;width:var(--w);background:#c9668f33;z-index:0}
.rows .rk{width:18px;color:#8a6a7a;z-index:1}.rows .nm{flex:1;z-index:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.rows .vl{z-index:1;color:#cdeee6}
.none{color:#8a6a7a;margin:0}
.chart{display:flex;align-items:flex-end;gap:3px;height:106px}.col{flex:1;height:100%;display:flex;flex-direction:column;justify-content:flex-end;align-items:center}
.col i{display:block;width:100%;background:linear-gradient(#e889b3,#a24a73);border-radius:3px 3px 0 0;min-height:1px}.col b{font-size:8px;color:#8a6a7a;height:12px;font-weight:normal}
.tabs{display:flex;flex-wrap:wrap;gap:6px;justify-content:center;margin:0 0 14px}
.tabs a{cursor:pointer;color:#f3e6ec;text-decoration:none;border:1px solid #c9668f;border-radius:99px;padding:5px 14px;background:#141013}
.tabs a.on{background:#c9668f;color:#000;font-weight:bold}
.js .panel{display:none}.js .panel.on{display:block}
@media(max-width:520px){.grid{grid-template-columns:1fr}}
footer{text-align:center;color:#8a6a7a;font-size:10px;margin-top:9px}
"""


def build(title_days, panels, updated, sample):
    """panels: list of (tab label, html). With JavaScript each is a tab; without it, all are shown one after another."""
    note = '<div class="sub"><b style="color:#ffb36b">(SAMPLE DATA, made up for the preview)</b></div>' if sample else ""
    tabs = "".join('<a href="#%s" data-t="%s">%s</a>' % (tid, tid, esc(label)) for tid, label, _ in panels)
    body = "\n".join('<div class="panel" id="%s">%s</div>' % (tid, h) for tid, _, h in panels)
    return """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="300"><title>88x31 server stats</title><style>%s</style></head><body><div class="wrap">
<h1>~*~88x31~*~ server stats</h1><div class="deco">&hearts; &#10047; &hearts; &#10047; &hearts;</div>
%s
<div class="tabs" id="tabs">%s</div>
%s
<footer>Player names only. Bots, Steam IDs, addresses and chat are never shown. Refreshes every 5 minutes.</footer></div>
<script>
(function(){var d=document.documentElement;d.className+=" js";
var ids=[].map.call(document.querySelectorAll(".panel"),function(p){return p.id});
function show(id){if(ids.indexOf(id)<0)id=ids[0];
[].forEach.call(document.querySelectorAll(".panel"),function(p){p.className="panel"+(p.id==id?" on":"")});
[].forEach.call(document.querySelectorAll("#tabs a"),function(a){a.className=a.getAttribute("data-t")==id?"on":""});
try{sessionStorage.setItem("tab",id)}catch(e){}}
[].forEach.call(document.querySelectorAll("#tabs a"),function(a){a.addEventListener("click",function(e){e.preventDefault();var t=a.getAttribute("data-t");history.replaceState(null,"","#"+t);show(t)})});
var s=null;try{s=sessionStorage.getItem("tab")}catch(e){}
show(location.hash.slice(1)||s||ids[0]);})();
</script></body></html>""" % (CSS, note, tabs, body)


def overview(all_stats):
    players = set()
    for s in all_stats:
        players |= set(s.minutes)
    tot = lambda f: sum(f(s) for s in all_stats)
    tiles = [tile("different players", fmt(len(players))), tile("hours played", fmt(tot(lambda s: sum(s.minutes.values())) / 60)),
             tile("zombies killed", fmt(tot(lambda s: sum(s.kills.values())))), tile("special infected killed", fmt(tot(lambda s: sum(s.special_kills.values())))),
             tile("Tanks defeated", fmt(tot(lambda s: s.tanks))), tile("campaign finales", fmt(tot(lambda s: s.finales)))]
    return '<section class="srv"><h2>All servers together</h2><div class="tiles">%s</div></section>' % "".join(tiles)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = sys.argv[1]
    ignore = sys.argv[2] if len(sys.argv) > 2 else "/home/tf2/leaderboard-ignore.txt"
    days = int(sys.argv[3]) if len(sys.argv) > 3 else 7
    root = sys.argv[4] if len(sys.argv) > 4 else "/home/tf2"
    sample = len(sys.argv) > 4
    ignored = read_ignored(ignore)
    since = now_hawaii() - timedelta(days=days)
    all_stats, sections = [], []
    for name, kind, folder, pattern, port, cfg in SERVERS:
        s = scan(kind, os.path.join(root, folder), pattern, since, ignored)
        st = ("unknown", None, None, None) if sample else live(root, name, port, cfg)
        if sample:
            st = ("online", "l4d_hospital01_apartment", 2, 8)
        all_stats.append(s)
        sections.append(server_section(name, kind, s, st, days))
    panels = [("all", "All servers", overview(all_stats))] + [(tid, label, h) for (tid, label), h in zip(TABS, sections)]
    page = build(days, panels, now_hawaii().strftime("%b %d, %I:%M %p"), sample)
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(page)
    os.replace(tmp, out)   # never leaves a half-written page


if __name__ == "__main__":
    main()
