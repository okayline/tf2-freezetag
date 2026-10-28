#!/usr/bin/env python3
# Story facts: reads one L4D server log and prints each round as JSON, the facts a chapter is written from.
# Players appear only as their character plus their story title (story-title.py), never by name, Steam ID or IP.
#
# Use:  story-facts.py /home/tf2/l4d-b/left4dead/logs/L1028xxx.log
import json, os, re, sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from importlib.machinery import SourceFileLoader
title = SourceFileLoader("story_title", os.path.join(os.path.dirname(os.path.abspath(__file__)), "story-title.py")).load_module().title

# Map file -> in-game chapter name (L4D1 campaigns)
CHAPTERS = {
    "l4d_hospital01_apartment": "No Mercy: The Apartments", "l4d_hospital02_subway": "No Mercy: The Subway",
    "l4d_hospital03_sewers": "No Mercy: The Sewer", "l4d_hospital04_interior": "No Mercy: The Hospital",
    "l4d_hospital05_rooftop": "No Mercy: Rooftop Finale",
    "l4d_garage01_alleys": "Crash Course: The Alleys", "l4d_garage02_lots": "Crash Course: The Truck Depot Finale",
    "l4d_smalltown01_caves": "Death Toll: The Turnpike", "l4d_smalltown02_drainage": "Death Toll: The Drains",
    "l4d_smalltown03_ranchhouse": "Death Toll: The Church", "l4d_smalltown04_mainstreet": "Death Toll: The Town",
    "l4d_smalltown05_houseboat": "Death Toll: Boathouse Finale",
    "l4d_airport01_greenhouse": "Dead Air: The Greenhouse", "l4d_airport02_offices": "Dead Air: The Crane",
    "l4d_airport03_garage": "Dead Air: The Construction Site", "l4d_airport04_terminal": "Dead Air: The Terminal",
    "l4d_airport05_runway": "Dead Air: Runway Finale",
    "l4d_farm01_hilltop": "Blood Harvest: The Woods", "l4d_farm02_traintunnel": "Blood Harvest: The Tunnel",
    "l4d_farm03_bridge": "Blood Harvest: The Bridge", "l4d_farm04_barn": "Blood Harvest: The Train Station",
    "l4d_farm05_cornfield": "Blood Harvest: Farmhouse Finale",
    "l4d_river01_docks": "The Sacrifice: The Docks", "l4d_river02_barge": "The Sacrifice: The Barge",
    "l4d_river03_port": "The Sacrifice: Port Finale",
    "l4d_lighthouse": "The Last Stand: Lighthouse Finale",
}
CHAR = {"Biker": "Francis", "NamVet": "Bill", "TeenGirl": "Zoey", "Manager": "Louis"}

TIME = re.compile(r"^L \S+ - (\d\d:\d\d:\d\d): (.*)$")
PLAYER = re.compile(r'"([^"<]*)<(\d+)><(STEAM_[0-9:]+|BOT)><([^>]*)>')
KILL = re.compile(r'^(?:\(DEATH\))?"(.+?)<(?:\d+><[^>]*><)?(Survivor|Infected)><([^>]*)><[^>]*><(\d+)\+(\d+)>.*?killed "(\w+)<.*?with "([^"]+)"( \(headshot\))?')


def new_round(m, at):
    return {"map": m, "chapter": CHAPTERS.get(m, m), "start": at, "end": None, "ended": None,
            "players": {}, "kills": defaultdict(lambda: defaultdict(int)), "headshots": defaultdict(int),
            "low_health": {}, "items": defaultdict(list), "moments": []}


def main(path):
    ids, rounds, cur, mapname = {}, [], None, None   # ids: name -> Steam ID (only kept in memory)
    for line in open(path, errors="ignore"):
        t = TIME.match(line.strip())
        if not t:
            continue
        at, ev = t.groups()
        for name, _, sid, _ in PLAYER.findall(ev):
            if sid.startswith("STEAM"):
                ids[name] = sid
        m = re.match(r'Started map "([^"]+)"', ev)
        if m:
            mapname = m.group(1)
        if 'triggered "Round_Start"' in ev:
            if cur and (cur["kills"] or cur["moments"]):
                rounds.append(cur)
            cur = new_round(mapname, at)
            continue
        if cur is None:
            continue

        def who(name, side, role):
            if name not in ids:
                return None   # bots stay out of the story
            if side == "Survivor":
                c = CHAR.get(role, role)
                key = c + ", " + title(ids[name])
            else:
                key = "the " + role.title() + ", " + title(ids[name])
            cur["players"].setdefault(name, set()).add(key)
            return key

        k = KILL.match(ev)
        if k:
            name, side, role, hp, temp, victim, weapon, hs = k.groups()
            p = who(name, side, role)
            if p:
                cur["kills"][p][weapon] += 1
                if hs:
                    cur["headshots"][p] += 1
                health = int(hp) + int(temp)
                cur["low_health"][p] = min(cur["low_health"].get(p, 99999), health)
                if victim in ("witch", "tank") or "tank" in role.lower():
                    cur["moments"].append([at, p, "killed the " + victim + " with " + weapon])
            continue
        m = re.match(r'"?(.+?)<[^>]*>.*picked up item weapon_(\w+)', ev) or re.match(r"(?:\(\d\))?(\S+) picked up item weapon_(\w+)", ev)
        if m and m.group(1) in cur["players"]:
            item = m.group(2); k2 = sorted(cur["players"][m.group(1)])[0]
            if item in ("pain_pills", "first_aid_kit", "pipe_bomb", "molotov", "autoshotgun", "rifle", "hunting_rifle"):
                cur["items"][k2].append(item)
            elif item == "tank_claw":
                cur["moments"].append([at, sorted(cur["players"][m.group(1)])[0], "became the Tank"])
        m = re.match(r'"(.+?)<.*disconnected \(reason "([^"]*)"\)', ev)
        if m and m.group(1) in cur["players"]:
            why = "was removed for team attacks" if "FF" in m.group(2) or "equipo" in m.group(2) or "team" in m.group(2).lower() else "left"
            cur["moments"].append([at, sorted(cur["players"][m.group(1)])[-1], why])
        if 'triggered "Round_End"' in ev or "Scenario_Restart" in ev:
            cur["end"] = at
            cur["ended"] = "team wiped" if "Restart" in ev else "round ended"
    if cur and (cur["kills"] or cur["moments"]):
        rounds.append(cur)

    out = []
    for r in rounds:
        r["kills"] = {p: dict(w) for p, w in r["kills"].items()}
        r["headshots"] = dict(r["headshots"])
        r["items"] = dict(r["items"])
        r["players"] = sorted({k for v in r["players"].values() for k in v})
        out.append(r)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main(sys.argv[1])
