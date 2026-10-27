#!/usr/bin/env python3
"""L4D1 leaderboard for the welcome screen: the players who killed the most common infected ("zombies")
in the past N days. Reads the server's game logs (cfg "log on"), counts kills by humans only, and writes
the welcome screen (motd.txt) from a template, replacing the line <!--LEADERBOARD--> with the top players.
Only player names are shown, never Steam IDs or addresses. Players are counted by Steam ID, so a name change
does not split a score. Bots (survivors and infected) are never counted.

Usage: l4d-leaderboard.py LOG_DIR TEMPLATE OUTPUT [DAYS] [TOP]
"""
import glob, html, os, re, sys, time
from datetime import datetime, timedelta

MARK = "<!--LEADERBOARD-->"
STAMP = re.compile(r'(\d\d)/(\d\d)/(\d{4}) - (\d\d):(\d\d):(\d\d)')
# (DEATH)"Name<userid><STEAM_1:x:y><Survivor>..." killed "infected<...
KILL = re.compile(r'"(.+?)<\d+><(STEAM_[0-9:]+)><[^>]*>.*?" killed "infected<')


def count_kills(log_dir, since):
    """{steam id: [kills, latest name]} for log lines newer than `since` (a datetime)."""
    totals = {}
    for path in glob.glob(os.path.join(log_dir, "L*.log")):
        try:
            if datetime.fromtimestamp(os.path.getmtime(path)) < since:
                continue   # nothing in this file can be newer than the window
            lines = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        with lines:
            for line in lines:
                if '" killed "infected<' not in line:
                    continue
                m = KILL.search(line)
                t = STAMP.search(line)
                if not m or not t:
                    continue
                mo, d, y, hh, mi, ss = map(int, t.groups())
                if datetime(y, mo, d, hh, mi, ss) < since:
                    continue
                entry = totals.setdefault(m.group(2), [0, m.group(1)])
                entry[0] += 1
                entry[1] = m.group(1)   # lines are in time order per file; keep the newest name seen
    return totals


def board_html(totals, days, top):
    title = "Most Zombies Killed in the Past %d Day%s" % (days, "" if days == 1 else "s")
    ranked = sorted(totals.values(), key=lambda e: (-e[0], e[1].lower()))[:top]
    if ranked:
        rows = "<br>".join("%d. %s &ndash; %s" % (i + 1, html.escape(name.strip()[:24]), format(kills, ","))
                           for i, (kills, name) in enumerate(ranked))
    else:
        rows = "No kills yet. Be the first!"
    return '<p class="board"><b>%s</b><br>%s</p>' % (title, rows)


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    log_dir, template, output = sys.argv[1:4]
    days = int(sys.argv[4]) if len(sys.argv) > 4 else 5
    top = int(sys.argv[5]) if len(sys.argv) > 5 else 3
    since = datetime.now() - timedelta(days=days)
    page = open(template, encoding="utf-8").read()
    page = page.replace(MARK, board_html(count_kills(log_dir, since), days, top))
    tmp = output + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(page)
    os.replace(tmp, output)   # never leaves a half-written welcome screen


if __name__ == "__main__":
    main()
