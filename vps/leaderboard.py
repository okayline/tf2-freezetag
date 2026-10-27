#!/usr/bin/env python3
"""Leaderboard for a game server's welcome screen (motd.txt), built from the server's game logs.
  l4d: "Most Zombies Killed in the Past N Days"  (common infected killed by human players)
  tf2: "Most Freezes in the Past N Days"          (Freeze Tag turns a kill into a freeze: kills of the other team)
  l4dvs: "Most Damage in the Past N Days"         (second L4D server, versus: damage to the enemy team by humans of both teams,
                                                   from the "[88x31dmg]" lines the l4d_damagelog plugin writes into the game log)
Only human players are counted (never bots), by Steam account so a name change does not split a score. Only
player names are shown, never Steam IDs or addresses. The line <!--LEADERBOARD--> in the template is replaced
with the top players and the result is written to OUTPUT.

Players listed in the ignore file (one Steam ID per line; kept on the VPS, not in the repo) are left out.
STEAM_0:y:z, STEAM_1:y:z and [U:1:w] are the same kind of account, so they are compared as y:z.

Usage: leaderboard.py GAME LOG_DIR TEMPLATE OUTPUT [DAYS] [TOP] [IGNORE_FILE]
"""
import glob, html, os, re, sys
from datetime import datetime, timedelta

MARK = "<!--LEADERBOARD-->"
STAMP = re.compile(r'(\d\d)/(\d\d)/(\d{4}) - (\d\d):(\d\d):(\d\d)')
ID = r'(?P<id>STEAM_[0-9]:[0-9]:[0-9]+|\[U:1:[0-9]+\])'

GAMES = {
    # (log file pattern, line pattern, title, text a line must contain, counts a number from the line)
    # l4d: (DEATH)"Name<userid><STEAM_1:x:y><Survivor>..." killed "infected<...
    "l4d": ("L*.log",
            re.compile(r'"(?P<name>.+?)<\d+><' + ID + r'><[^>]*>.*?" killed "infected<'),
            "Most Zombies Killed in the Past %s", '" killed "', False),
    # tf2: "Name<userid><[U:1:w]><Red>" killed "Other<userid><...><Blue>" with "weapon"
    "tf2": ("l*.log",
            re.compile(r'"(?P<name>.+?)<\d+><' + ID + r'><(?P<team>Red|Blue)>" killed "[^"]*<\d+><[^>]*><(?P<vteam>Red|Blue)>"'),
            "Most Freezes in the Past %s", '" killed "', False),
    # l4dvs: [88x31dmg] <STEAM_1:0:12345> 250 "Name"   (damage since the plugin's last line for that player)
    "l4dvs": ("L*.log",
              re.compile(r'\[88x31dmg\] <' + ID + r'> (?P<n>\d+) "(?P<name>.*)"\s*$'),
              "Most Damage in the Past %s", "[88x31dmg]", True),
}


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


def count_kills(game, log_dir, since, ignored=frozenset()):
    """{account: [count, latest name]} for log lines newer than `since` (a datetime)."""
    pattern, rx, _, marker, weighted = GAMES[game]
    totals = {}
    for path in glob.glob(os.path.join(log_dir, pattern)):
        try:
            if datetime.fromtimestamp(os.path.getmtime(path)) < since:
                continue   # nothing in this file can be newer than the window
            lines = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        with lines:
            for line in lines:
                if marker not in line:
                    continue
                m = rx.search(line)
                t = STAMP.search(line)
                if not m or not t:
                    continue
                who = account(m.group("id"))
                if who in ignored:
                    continue
                if game == "tf2" and m.group("team") == m.group("vteam"):
                    continue   # not a freeze of the other team
                mo, d, y, hh, mi, ss = map(int, t.groups())
                if datetime(y, mo, d, hh, mi, ss) < since:
                    continue
                entry = totals.setdefault(who, [0, m.group("name")])
                entry[0] += int(m.group("n")) if weighted else 1
                entry[1] = m.group("name")   # lines are in time order per file; keep the newest name seen
    return totals


def board_html(game, totals, days, top):
    span = "%d Day%s" % (days, "" if days == 1 else "s")
    ranked = sorted(totals.values(), key=lambda e: (-e[0], e[1].lower()))[:top]
    if ranked:
        rows = "<br>".join("%d. %s &ndash; %s" % (i + 1, html.escape(name.strip()[:24]), format(n, ","))
                           for i, (n, name) in enumerate(ranked))
    else:
        rows = "Nobody yet. Be the first!"
    return '<p class="board"><b>%s</b><br>%s</p>' % (GAMES[game][2] % span, rows)


def main():
    if len(sys.argv) < 5 or sys.argv[1] not in GAMES:
        sys.exit(__doc__)
    game, log_dir, template, output = sys.argv[1:5]
    days = int(sys.argv[5]) if len(sys.argv) > 5 else 5
    top = int(sys.argv[6]) if len(sys.argv) > 6 else 3
    ignore = sys.argv[7] if len(sys.argv) > 7 else os.path.join(os.path.dirname(template), "ignore.txt")
    since = datetime.now() - timedelta(days=days)
    page = open(template, encoding="utf-8").read()
    totals = count_kills(game, log_dir, since, read_ignored(ignore))
    page = page.replace(MARK, board_html(game, totals, days, top))
    tmp = output + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(page)
    os.replace(tmp, output)   # never leaves a half-written welcome screen


if __name__ == "__main__":
    main()
