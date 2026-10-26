#!/usr/bin/env python3
"""Live L4D1 feed to Discord: joins, leaves, chat, special-infected kills, survivor deaths,
friendly fire and map changes.

Usage: discord-feed-l4d.py NAME LOG_DIR WEBHOOK_FILE

Reads the server's own log files (log on / sv_logfile 1, set in server.cfg) in LOG_DIR,
following the newest file. No RCON and no restart needed. Common infected kills are skipped
(far too many). Never posts IP addresses or Steam IDs.
Python standard library only; reuses the Discord helper in discord-status.py."""
import glob
import importlib.util
import os
import re
import sys
import time

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("status", os.path.join(here, "discord-status.py"))
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)

# A player in the log: "Name<...><...>..." ; the name is everything before the first <
P = r'"([^"<]*)((?:<[^>]*>)*)"'
RULES = [
    ("tf_trig", re.compile(P + r' triggered "(domination|revenge|chargedeployed|captureblocked|killedobject|medic_death)"(?: against ' + P + r')?(.*)$')),
    ("role", re.compile(P + r' changed role to "([^"]*)"')),
    ("say_team", re.compile(P + r' say_team "(.*)"')),
    ("say", re.compile(P + r' say "(.*)"')),
    ("kill", re.compile(r'(?:\(DEATH\))?' + P + r' killed ' + P + r' with "([^"]*)"')),
    ("suicide", re.compile(P + r' committed suicide')),
    ("joined", re.compile(P + r' entered the game')),
    ("left", re.compile(P + r' disconnected')),
    ("ff", re.compile(r'^(\S[^"<>]{0,40}) attacked (\S[^"<>]{0,40})$')),
    ("map", re.compile(r'Started map "([^"]*)"')),
    ("incap", re.compile(r'\(INCAP\) ' + P + r' is incapacitated')),
    ("pounce", re.compile(r'^Hunter pounced on ([^,]{1,40}),')),
    ("tongue", re.compile(r'Tongue grab starting\.\s+Smoker:' + P + r'\.\s+Victim:' + P)),
    ("revive", re.compile(P + r' (revived|healed|rescued|defibrillated) ' + P)),
    ("item", re.compile(r'^(\S[^<>"]{0,40}) picked up item weapon_(pipe_bomb|molotov|first_aid_kit|pain_pills|autoshotgun|rifle|hunting_rifle|gascan|propanetank)\b')),
    ("spawn", re.compile(r'^(\S+) spawned as a (TANK|WITCH|HUNTER|GAS|EXPLODING|SMOKER|BOOMER)\b')),
    ("witch", re.compile(r'Witch')),
    ("cap", re.compile(r'Team "([^"]*)" triggered "pointcaptured" \(cp "\d+"\) \(cpname "([^"]*)"\)')),
    ("trigger", re.compile(r'World triggered "([^"]*)"')),
    ("score", re.compile(r'Team "([^"]*)" scored "([^"]*)" with "([^"]*)" players')),
]
ITEM = {"pipe_bomb": "a pipe bomb", "molotov": "a molotov", "first_aid_kit": "a medkit", "pain_pills": "pills",
        "autoshotgun": "an auto shotgun", "rifle": "an assault rifle", "hunting_rifle": "a hunting rifle",
        "gascan": "a gas can", "propanetank": "a propane tank"}
SPECIAL = {"TANK": "\U0001F6A8 **A TANK has spawned!**", "WITCH": "\U0001F469 A Witch is nearby",
           "HUNTER": "\U0001F43E A Hunter spawned", "GAS": "\U0001F445 A Smoker spawned", "SMOKER": "\U0001F445 A Smoker spawned",
           "EXPLODING": "\U0001F92E A Boomer spawned", "BOOMER": "\U0001F92E A Boomer spawned"}


def esc(text, n):
    return re.sub(r"([\\*_`~|>@#\[\]()])", r"\\\1", text.replace("\n", " "))[:n]


GAME = "l4d"
LAST_SPAWN = {}
BOT_NAMES = {"Bill", "Francis", "Louis", "Zoey"}


def is_bot(tags):
    return "<BOT>" in tags


def format_line(raw):
    text = raw.strip()
    text = re.sub(r"^L ", "", text)
    text = re.sub(r"^\d\d/\d\d/\d{4} - \d\d:\d\d:\d\d: ", "", text)
    for kind, rx in RULES:
        m = rx.search(text)
        if not m:
            continue
        g = m.groups()
        if kind == "tf_trig":
            who, wtags, ev, other, otags, rest = g
            if is_bot(wtags):
                return None
            if ev == "domination":
                return "\U0001F608 **%s** is DOMINATING %s" % (esc(who, 32), esc(other or "", 32))
            if ev == "revenge":
                return "\U0001F525 **%s** got REVENGE on %s" % (esc(who, 32), esc(other or "", 32))
            if ev == "chargedeployed":
                return "\u26a1 %s popped an ÜberCharge" % esc(who, 32)
            if ev == "captureblocked":
                return "\U0001F6E1 %s blocked a capture" % esc(who, 32)
            if ev == "killedobject":
                o = re.search(r'\(object "OBJ_([A-Z]+)"', rest)
                return "\U0001F4A5 %s destroyed a %s" % (esc(who, 32), (o.group(1).lower() if o else "building"))
            return None
        if kind == "role":
            return None if is_bot(g[1]) else "\U0001F504 %s switched to %s" % (esc(g[0], 32), esc(g[2].capitalize(), 16))
        if kind in ("say", "say_team") and GAME == "tf2":
            return None                           # the chat relay already posts TF2 chat
        if kind in ("say", "say_team"):
            tag = " *(team)*" if kind == "say_team" else ""
            return "\U0001F4AC **%s**%s: %s" % (esc(g[0], 32), tag, esc(g[2], 250))
        if kind == "kill":
            killer, ktags, victim, vtags, weapon = g
            killer = re.sub(r"^\(\d+\)", "", killer)
            victim = re.sub(r"^\(\d+\)", "", victim)
            world = not re.search(r"<\d+>", ktags) and "<Survivor>" not in ktags
            if world and "<Survivor>" not in vtags:
                return None                       # the map itself (trigger_hurt etc.) killed an infected
            if world and "<Survivor>" in vtags and not is_bot(vtags):
                return "\U0001F480 **%s** died (fell or hazard)" % esc(victim, 32)
            if victim == "infected":
                return None                       # common infected: skip, there are hundreds
            if "<Survivor>" in vtags and is_bot(vtags):
                return None                       # a bot survivor died: skip
            if GAME == "tf2":
                if is_bot(ktags) and is_bot(vtags):
                    return None                   # bot vs bot: skip
                cm = re.search(r'\(customkill "([^"]*)"\)', text)
                extra = {"headshot": " \U0001F3AF headshot", "backstab": " \U0001F5E1 backstab"}.get(cm.group(1), "") if cm else ""
                if killer == victim:
                    return "\U0001F480 %s killed themselves" % esc(victim, 32)
                return "\u2620\ufe0f %s killed %s (%s)%s" % (esc(killer, 32), esc(victim, 32), esc(weapon.replace("tf_projectile_", ""), 24), extra)
            if is_bot(ktags) and not ("<Survivor>" in vtags):
                return None                       # bots killing things: skip
            if "<Survivor>" in vtags:
                return "\U0001F480 **%s** was killed by %s (%s)" % (esc(victim, 32), esc(killer, 32), esc(weapon, 24))
            hs = " \U0001F3AF headshot" if text.endswith("(headshot)") else ""
            big = "**" if victim in ("Tank", "Witch") else ""
            if "<Infected>" not in vtags:          # TF2 and other games: player vs player
                return "\u2620\ufe0f %s killed %s (%s)%s" % (esc(killer, 32), esc(victim, 32), esc(weapon, 24), hs)
            return "\U0001F9DF %s killed a %s%s%s (%s)%s" % (esc(killer, 32), big, esc(victim, 32), big, esc(weapon, 24), hs)
        if kind == "suicide":
            if "<Survivor>" not in g[1] or is_bot(g[1]):
                return None                       # infected (Tank passing control etc.) or bot: skip
            return "\U0001F480 %s died" % esc(g[0], 32)
        if kind == "joined":
            return None if is_bot(g[1]) else "➕ **%s** joined" % esc(g[0], 32)
        if kind == "left":
            return None if is_bot(g[1]) else "➖ **%s** left" % esc(g[0], 32)
        if kind == "ff":
            return "\U0001F52B %s shot teammate %s" % (esc(g[0], 32), esc(g[1], 32))
        if kind == "incap":
            return None if "<Survivor>" not in g[1] or is_bot(g[1]) else "\U0001FA78 **%s** is down!" % esc(g[0], 32)
        if kind in ("pounce", "item") and g[0] in BOT_NAMES:
            return None
        if kind == "tongue" and is_bot(g[3]):
            return None
        if kind == "revive" and is_bot(g[1]):
            return None
        if kind == "pounce":
            return "\U0001F43E Hunter pounced on %s" % esc(g[0], 32)
        if kind == "tongue":
            return "\U0001F445 Smoker grabbed %s" % esc(g[2], 32)
        if kind == "revive":
            return "\u2764\ufe0f %s %s %s" % (esc(g[0], 32), g[2], esc(g[3], 32))
        if kind == "item":
            return "\U0001F392 %s picked up %s" % (esc(g[0], 32), ITEM[g[1]])
        if kind == "spawn":
            now = time.time()
            if now - LAST_SPAWN.get(g[1], 0) < 30:
                return None                       # same special again within 30s (Tank control passing): skip
            LAST_SPAWN[g[1]] = now
            return SPECIAL[g[1]]
        if kind == "witch":
            return None
        if kind == "trigger":
            ev = g[0]
            w = re.search(r'\(winner "([^"]*)"\)', text)
            if ev == "Round_Win" and w:
                return "\U0001F3C1 **%s wins the round!**" % esc(w.group(1), 16)
            if ev in ("Round_Start", "Round_Setup_Begin", "Round_Setup_End", "Round_Overtime", "Round_Length",
                      "Mini_Round_Selected", "Mini_Round_Start", "Mini_Round_End", "Mini_Round_Win", "Mini_Round_Length"):
                return None if ev != "Round_Start" else "\U0001F7E2 Round started"
            if ev.lower() in ("round_start", "round_end", "finale_start", "finale_vehicle_ready", "finale_win", "game_over", "mission_lost"):
                nice = {"round_start": "\U0001F7E2 Round started", "round_end": "\U0001F534 Round over",
                        "finale_start": "\U0001F525 **FINALE started!**", "finale_vehicle_ready": "\U0001F681 Rescue is here!",
                        "finale_win": "\U0001F3C6 **Survivors escaped!**", "game_over": "\u2620\ufe0f Game over",
                        "mission_lost": "\u2620\ufe0f **Everyone died**"}
                return nice[ev.lower()]
            return "\u2699\ufe0f %s" % esc(ev, 40)
        if kind == "cap":
            return "\U0001F6A9 %s captured %s" % (esc(g[0], 16), esc(g[1].lstrip("#"), 40))
        if kind == "score":
            if g[1] == "0":
                return None
            return "\U0001F3C1 %s scored %s (%s players)" % (esc(g[0], 16), esc(g[1], 10), esc(g[2], 4))
        if kind == "map" and GAME == "tf2":
            return None                           # the relay already posts map changes
        if kind == "map":
            c = re.match(r"l4d_(hospital|garage|smalltown|airport|farm|river)0?(\d+)", g[0])
            if c:
                camp = {"hospital": "No Mercy", "garage": "Crash Course", "smalltown": "Death Toll",
                        "airport": "Dead Air", "farm": "Blood Harvest", "river": "The Sacrifice"}[c.group(1)]
                return "\U0001F5FA\ufe0f **%s**, chapter %s" % (camp, c.group(2))
            return "\U0001F5FA️ Map: `%s`" % esc(g[0], 48).replace("\\", "")
    return None


# ---- end-of-chapter stats (L4D only): counted from the same log lines, posted when a chapter ends ----
STATS = {}          # name -> counters for this chapter
SINCE = {}          # name -> time they joined (kept across chapters, dropped when they leave)
KEYS = [("si", "\U0001F9DF specials"), ("ci", "\U0001F480 commons"), ("hs", "\U0001F3AF headshots"),
        ("boss", "\U0001F6A8 Tanks/Witches"), ("help", "\u2764\ufe0f helped"), ("ff", "\U0001F52B FF"),
        ("down", "\U0001FA78 downed"), ("dead", "\u2620\ufe0f died"), ("items", "\U0001F392 items")]


def bump(name, key):
    if name and name not in BOT_NAMES:
        STATS.setdefault(name, {}).setdefault(key, 0)
        STATS[name][key] += 1


def tally(raw):
    text = re.sub(r"^\d\d/\d\d/\d{4} - \d\d:\d\d:\d\d: ", "", re.sub(r"^L ", "", raw.strip()))
    m = re.search(r'(?:\(DEATH\))?' + P + r' killed ' + P + r' with "([^"]*)"', text)
    if m:
        killer, ktags, victim, vtags = re.sub(r"^\(\d+\)", "", m.group(1)), m.group(2), re.sub(r"^\(\d+\)", "", m.group(3)), m.group(4)
        if "<Survivor>" in vtags and not is_bot(vtags):
            bump(victim, "dead")
        if "<Survivor>" in ktags and not is_bot(ktags):
            if victim == "infected":
                bump(killer, "ci")
            elif "<Infected>" in vtags:
                bump(killer, "boss" if victim in ("Tank", "Witch") else "si")
            if "<Survivor>" not in vtags and text.endswith("(headshot)"):
                bump(killer, "hs")
        return
    for rx, key, grp, tagi in ((r'\(INCAP\) ' + P + r' is incapacitated', "down", 1, 2),
                               (P + r' (?:revived|healed|rescued|defibrillated) ' + P, "help", 1, 2)):
        m = re.search(rx, text)
        if m and not is_bot(m.group(tagi)):
            bump(m.group(grp), key)
            return
    m = re.search(r'^(\S[^"<>]{0,40}) attacked (\S[^"<>]{0,40})$', text)
    if m:
        bump(m.group(1), "ff")
        return
    m = re.search(r'^(\S[^<>"]{0,40}) picked up item weapon_(pipe_bomb|molotov|first_aid_kit|pain_pills|autoshotgun|rifle|hunting_rifle|gascan|propanetank)\b', text)
    if m:
        bump(m.group(1), "items")
        return
    m = re.search(P + r' (entered the game|disconnected)', text)
    if m and not is_bot(m.group(2)):
        if m.group(3) == "entered the game":
            SINCE.setdefault(m.group(1), time.time())
        else:
            SINCE.pop(m.group(1), None)


def summary(title):
    if not STATS:
        return None
    rows = sorted(STATS.items(), key=lambda kv: -(kv[1].get("si", 0) * 5 + kv[1].get("ci", 0)))
    out = ["\U0001F4CA **%s**" % title]
    for name, c in rows[:10]:
        bits = ["%s %d" % (label, c[k]) for k, label in KEYS if c.get(k)]
        t = SINCE.get(name)
        if t:
            mins = int((time.time() - t) // 60)
            bits.append("\u23f1\ufe0f %dh%02dm" % (mins // 60, mins % 60) if mins >= 60 else "\u23f1\ufe0f %dm" % mins)
        out.append("**%s**: %s" % (esc(name, 32), " · ".join(bits) or "no stats"))
    STATS.clear()
    return "\n".join(out)


def flush(webhook, lines):
    if not lines:
        return 0
    # collapse repeats in one batch (friendly fire spam), keep order
    seen, out = {}, []
    for l in lines:
        if l in seen:
            seen[l] += 1
        else:
            seen[l] = 1
            out.append(l)
    out = [l + (" ×%d" % seen[l] if seen[l] > 1 else "") for l in out]
    # joins first: the game logs "entered the game" after the new player's first pickups
    out = [l for l in out if l.startswith("➕")] + [l for l in out if not l.startswith("➕")]
    extra = len(out) - 40
    out = out[:40] + (["… and %d more" % extra] if extra > 0 else [])
    payload = {"content": "\n".join(out)[:1900], "allowed_mentions": {"parse": []}}
    code, _ = status.call("POST", webhook, payload)
    if code == 429:
        time.sleep(3)
        code, _ = status.call("POST", webhook, payload)
    return code


def newest(log_dir):
    files = glob.glob(os.path.join(log_dir, "[Ll]*.log"))
    return max(files, key=os.path.getmtime) if files else None


HUMANS = set()
JL = re.compile(P + r' (entered the game|disconnected)')


def track(line):
    """Keep the set of humans on the server (TF2 only), from join/leave log lines."""
    m = JL.search(line)
    if m and not is_bot(m.group(2)):
        (HUMANS.add if m.group(3) == "entered the game" else HUMANS.discard)(m.group(1))


def main():
    global GAME
    name, log_dir, webhook_file = sys.argv[1], sys.argv[2], sys.argv[3]
    GAME = sys.argv[4] if len(sys.argv) > 4 else "l4d"
    webhook = open(webhook_file).read().strip()
    path, fh, pending = None, None, ""
    buf, first, last_report = [], 0, time.time()
    got = posted = 0
    print("%s feed: following logs in %s" % (name, log_dir), flush=True)
    while True:
        cur = newest(log_dir)
        if cur and cur != path:
            if fh:
                fh.close()
            fh = open(cur, encoding="utf-8", errors="replace")
            if path is None:
                for old in fh:                   # first start: learn who is on, then only new lines
                    track(old)
            else:
                HUMANS.clear()                   # new map log: players enter again
            path, pending = cur, ""
        part = fh.readline() if fh else ""
        pending += part
        line = ""
        if pending.endswith("\n"):
            line, pending = pending, ""
        if line:
            got += 1
            try:
                track(line)
                out = format_line(line)
                if GAME == "l4d":
                    end = re.search(r'World triggered "(?i:(round_end|finale_win|mission_lost))"', line)
                    stats = summary("Chapter stats") if end else None
                    if stats:
                        if not buf:
                            first = time.time()
                        buf.append(stats)
                    tally(line)
                if GAME == "tf2" and not HUMANS and "disconnected" not in line:
                    out = None                    # only bots playing: stay quiet
            except Exception:
                out = None
            if out:
                if not buf:
                    first = time.time()
                buf.append(out)
        else:
            time.sleep(0.2)
        if buf and (time.time() - first >= 2 or len(buf) >= 60):
            code = flush(webhook, buf)
            posted += len(buf)
            if not 200 <= code < 300:
                print("%s feed: discord answered %d" % (name, code), flush=True)
            buf = []
        if time.time() - last_report > 300:
            print("%s feed: last 5 min: %d log lines, %d posted" % (name, got, posted), flush=True)
            got = posted = 0
            last_report = time.time()


if __name__ == "__main__":
    sys.exit(main())
