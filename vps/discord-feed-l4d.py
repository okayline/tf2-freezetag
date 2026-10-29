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
# lines from our l4d_eventlog plugin: [88x31ev] <event> <id> "name" (role) [-> <id> "name" (role)] [key=value ...]
EV_WHO = r'<([^>]*)> "([^"]*)" \(([^)]*)\)'
RULES = [
    ("ev", re.compile(r'\[88x31ev\] (\w+)(?: ' + EV_WHO + r')?(?: -> ' + EV_WHO + r')?(.*)$')),
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
GAP = 2.5          # seconds between Discord posts (about 24 a minute, under Discord's ~30)
LAST_SPAWN = {}
BOT_NAMES = {"Bill", "Francis", "Louis", "Zoey"}


def is_bot(tags):
    return "<BOT>" in tags


def format_ev(g):
    """Posts for the [88x31ev] lines the game's own log lacks (revives, heals, witch, tank, safe room...).
    Pounces, smoker grabs, incaps, deaths and spawns already come from the game's log, so those are skipped here."""
    ev, aid, a, arole, bid, b, brole, extra = g
    ah = aid not in (None, "BOT", "WORLD")          # is the first player a human
    bh = bid not in (None, "BOT", "WORLD")
    opt = dict(re.findall(r'(\w+)=(\S+)', extra or ""))
    A, B = esc(a or "", 32), esc(b or "", 32)
    if ev == "heal" and (ah or bh):
        return "\U0001FA79 %s patched up %s" % (A, "themselves" if a == b else B)
    if ev == "revive" and (ah or bh):
        return "\u2764\ufe0f %s %s %s" % (A, "pulled up" if opt.get("ledge") == "1" else "picked up", B)
    if ev == "rescue" and (ah or bh):
        return "\U0001F6AA %s rescued %s from a closet" % (A, B)
    if ev in ("vomit", "pounce", "tongue") and (ah or bh):
        emoji, verb = {"vomit": ("\U0001F92E", "puked on"), "pounce": ("\U0001F43E", "pounced on"),
                       "tongue": ("\U0001F445", "grabbed")}[ev]
        who = A if ah else "A %s" % esc(arole or a or "", 12)
        return "%s %s %s %s" % (emoji, who, verb, B)
    if ev == "witch_startled" and ah:
        return "\U0001F469 **%s startled the Witch!**" % A
    if ev == "witch_killed":
        who = A if ah else ("the team" if not a else A)
        return "\U0001F469 %s killed the Witch%s" % (who, " in one shot! \U0001F3AF" if opt.get("oneshot") == "1" else "")
    if ev == "tank_killed":
        secs = opt.get("lived", "").rstrip("s")
        took = " after %s seconds" % secs if secs.isdigit() and int(secs) >= 0 else ""
        return "\U0001F4AA **The Tank went down%s!**" % took
    if ev == "safe_room" and ah and opt.get("order") == "1":
        return "\U0001F6AA **%s** reached the safe room first" % A
    if ev == "finale_win":
        return "\U0001F681 **Rescued! The finale is won!**"
    if ev == "mission_lost":
        return "\U0001F480 Everyone went down. Mission lost."
    return None


def format_line(raw):
    text = raw.strip()
    text = re.sub(r"^L ", "", text)
    text = re.sub(r"^\d\d/\d\d/\d{4} - \d\d:\d\d:\d\d: ", "", text)
    for kind, rx in RULES:
        m = rx.search(text)
        if not m:
            continue
        g = m.groups()
        if kind == "ev":
            return format_ev(g)
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
            article = "a " if is_bot(vtags) else ""   # versus: infected played by people get no "a"
            return "\U0001F9DF %s killed %s%s%s%s (%s)%s" % (esc(killer, 32), article, big, esc(victim, 32), big, esc(weapon, 24), hs)
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
        if kind in ("pounce", "tongue"):
            return None                           # posted from the event log instead, with the infected player's name
        if kind == "revive":
            return "\u2764\ufe0f %s %s %s" % (esc(g[0], 32), g[2], esc(g[3], 32))
        if kind == "item":
            return None                           # item pickups: turned off (too many posts)
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


def tally_ev(text):
    m = RULES[0][1].search(text)
    if not m:
        return False
    ev, aid, a, arole, bid, b, brole, extra = m.groups()
    ah, bh = aid not in (None, "BOT", "WORLD"), bid not in (None, "BOT", "WORLD")
    opt = dict(re.findall(r'(\w+)=(\S+)', extra or ""))
    if ev == "heal" and ah and a != b:
        bump(a, "heal")
    elif ev == "revive" and ah:
        bump(a, "revive")
    elif ev == "rescue" and ah:
        bump(a, "rescue")
    elif ev == "pills" and ah:
        bump(a, "pills")
    elif ev == "ledge_grab" and ah:
        bump(a, "ledge")
    elif ev in ("pounce", "tongue", "vomit"):
        if bh:
            bump(b, "puked" if ev == "vomit" else "caught")
        if ah:
            bump(a, "pin")                     # versus: an infected player got someone
    elif ev == "witch_startled" and ah:
        CHAPTER.setdefault("woke", []).append(a)
    elif ev == "witch_killed":
        CHAPTER["witches"] = CHAPTER.get("witches", 0) + 1
        if opt.get("oneshot") == "1":
            CHAPTER["crowns"] = CHAPTER.get("crowns", 0) + 1
            if ah:
                bump(a, "crown")
    elif ev == "tank_killed":
        lived = opt.get("lived", "").rstrip("s")
        CHAPTER.setdefault("tanks", []).append(int(lived) if lived.lstrip("-").isdigit() else -1)
    elif ev == "safe_room" and ah:
        order = CHAPTER.setdefault("safe", [])
        if a not in order:
            order.append(a)
    return True


def tally(raw):
    text = re.sub(r"^\d\d/\d\d/\d{4} - \d\d:\d\d:\d\d: ", "", re.sub(r"^L ", "", raw.strip()))
    mp = re.search(r'Started map "([^"]*)"', text)
    if mp:
        CHAPTER["map"] = mp.group(1)
        return
    if tally_ev(text):
        return
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


CAMPS = {"hospital": "No Mercy", "garage": "Crash Course", "smalltown": "Death Toll",
         "airport": "Dead Air", "farm": "Blood Harvest", "river": "The Sacrifice"}
CHAPTER = {}        # chapter-wide facts from the event log: map, tanks (seconds lived), witches, crowns, safe-room order


def map_title(mp):
    c = re.match(r"l4d_(?:vs_)?(hospital|garage|smalltown|airport|farm|river)0?(\d+)", mp or "")
    return "%s, chapter %s" % (CAMPS[c.group(1)], c.group(2)) if c else (mp or "Chapter")


def player_score(c):
    """One number for the chapter's MVP: kills, saves and staying alive count; dying and friendly fire cost."""
    return (c.get("si", 0) * 5 + c.get("ci", 0) + c.get("hs", 0) + c.get("boss", 0) * 25 + c.get("crown", 0) * 15
            + c.get("revive", 0) * 8 + c.get("rescue", 0) * 8 + c.get("heal", 0) * 6 + c.get("pin", 0) * 4
            - c.get("dead", 0) * 10 - c.get("ff", 0) * 2)


def summary(title):
    """The end-of-chapter card: a Discord embed with highlights on top and one section per player."""
    if not STATS:
        CHAPTER.clear()
        return None
    rows = sorted(STATS.items(), key=lambda kv: -player_score(kv[1]))
    ch = dict(CHAPTER)
    lines = []
    if rows and player_score(rows[0][1]) > 0:
        lines.append("\U0001F3C6 **MVP: %s**" % esc(rows[0][0], 32))
    order = ch.get("safe", [])
    if order:
        lines.append("\U0001F6AA First into the safe room: **%s**" % esc(order[0], 32)
                     + (" (%d of %d made it)" % (len(order), len(STATS)) if len(STATS) > 1 else ""))
    for secs in ch.get("tanks", []):
        lines.append("\U0001F4AA A Tank went down" + (" after **%d seconds**" % secs if secs >= 0 else ""))
    if ch.get("witches"):
        crowns = ch.get("crowns", 0)
        lines.append("\U0001F469 %d Witch%s killed%s" % (ch["witches"], "es" if ch["witches"] > 1 else "",
                                                          " (%d in one shot! \U0001F451)" % crowns if crowns else ""))
    if ch.get("woke"):
        lines.append("\U0001F631 Witch startled by %s" % ", ".join(esc(n, 24) for n in ch["woke"][:3]))
    fields = []
    for name, c in rows[:10]:
        fight = ["%s %d" % (label, c[k]) for k, label in (("si", "\U0001F9DF specials"), ("ci", "\U0001F480 commons"),
                 ("hs", "\U0001F3AF headshots"), ("boss", "\U0001F6A8 Tanks/Witches"), ("crown", "\U0001F451 crowned"),
                 ("pin", "\U0001F43E pinned someone")) if c.get(k)]
        team = ["%s %d" % (label, c[k]) for k, label in (("revive", "\u2764\ufe0f revived"), ("rescue", "\U0001F6AA rescued"),
                ("heal", "\U0001FA79 healed"), ("pills", "\U0001F48A pills")) if c.get(k)]
        rough = ["%s %d" % (label, c[k]) for k, label in (("caught", "\U0001FAA2 got pinned"), ("puked", "\U0001F92E puked on"),
                 ("down", "\U0001FA78 downed"), ("ledge", "\U0001F9D7 ledge"), ("dead", "\u2620\ufe0f died"),
                 ("ff", "\U0001F52B hit teammates")) if c.get(k)]
        extra = []
        if c.get("items"):
            extra.append("\U0001F392 items %d" % c["items"])
        if name in order:
            extra.append("\U0001F6AA safe room #%d" % (order.index(name) + 1))
        t = SINCE.get(name)
        if t:
            mins = int((time.time() - t) // 60)
            extra.append("\u23f1\ufe0f %dh%02dm" % (mins // 60, mins % 60) if mins >= 60 else "\u23f1\ufe0f %dm" % mins)
        value = "\n".join(" · ".join(x) for x in (fight, team, rough, extra) if x) or "just arrived"
        medal = "\U0001F947 " if name == rows[0][0] and player_score(c) > 0 else ""
        fields.append({"name": (medal + name)[:250], "value": value[:1000], "inline": False})
    STATS.clear()
    CHAPTER.clear()
    embed = {"title": "\U0001F4CA %s \u2014 %s" % (title, map_title(ch.get("map"))), "color": 0xC0392B, "fields": fields}
    if lines:
        embed["description"] = "\n".join(lines)[:3900]
    return {"embeds": [embed]}


def flush(webhook, lines):
    if not lines:
        return 0
    cards = [l for l in lines if isinstance(l, dict)]
    lines = [l for l in lines if not isinstance(l, dict)]
    code = 0
    for card in cards:                         # the chapter card: an embed, posted on its own
        payload = dict(card, allowed_mentions={"parse": []})
        code, _ = status.call("POST", webhook, payload)
        if code == 429:
            time.sleep(3)
            code, _ = status.call("POST", webhook, payload)
    if not lines:
        return code
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
    last_send = 0.0
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
                stats = summary("Chapter stats") if GAME == "l4d" else None
                if stats:                        # the chapter ended (new map): post its stats
                    if not buf:
                        first = time.time()
                    buf.append(stats)
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
        # one post per event, at most one every GAP seconds (Discord allows about 30 a minute per channel).
        # When events pile up faster than that, the waiting ones go out a few together so the feed keeps up.
        if buf and time.time() - last_send >= GAP:
            take = 1 if len(buf) <= 3 else min(len(buf) // 2, 15)
            chunk, buf = buf[:take], buf[take:]
            code = flush(webhook, chunk)
            posted += len(chunk)
            last_send = time.time()
            if not 200 <= code < 300:
                print("%s feed: discord answered %d" % (name, code), flush=True)
        if time.time() - last_report > 300:
            print("%s feed: last 5 min: %d log lines, %d posted" % (name, got, posted), flush=True)
            got = posted = 0
            last_report = time.time()


if __name__ == "__main__":
    sys.exit(main())
