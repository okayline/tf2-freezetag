#!/usr/bin/env python3
"""Posts a Source game server's status to a Discord webhook: one message, edited every run.

Usage: discord-status.py NAME PORT SERVER_CFG WEBHOOK_FILE MESSAGE_FILE

- Reads rcon_password from SERVER_CFG on this machine and asks the server for `status` over
  RCON on 127.0.0.1:PORT (the server only listens there).
- The webhook link is read from WEBHOOK_FILE; the id of the Discord message it keeps editing is
  kept in MESSAGE_FILE.
- Never prints or posts the RCON password, the webhook link or players' IP addresses. Only
  human players' names are posted (bots are counted, not named).
Python standard library only."""
import datetime
import json
import re
import socket
import struct
import sys
import urllib.error
import urllib.request


def read_password(path):
    found = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.match(r'\s*rcon_password\s+"([^"]*)"', line) or re.match(r'\s*rcon_password\s+(\S+)', line)
            if m:
                found = m.group(1)
    return found or None


def packet(pid, ptype, body):
    data = struct.pack("<ii", pid, ptype) + body.encode("utf-8") + b"\0\0"
    return struct.pack("<i", len(data)) + data


def recv_exact(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("closed")
        buf += chunk
    return buf


def recv_packet(sock):
    (size,) = struct.unpack("<i", recv_exact(sock, 4))
    data = recv_exact(sock, size)
    pid, ptype = struct.unpack("<ii", data[:8])
    return pid, ptype, data[8:-2].decode("utf-8", "replace")


def rcon(port, password, command):
    with socket.create_connection(("127.0.0.1", port), timeout=5) as s:
        s.settimeout(5)
        s.sendall(packet(1, 3, password))                  # log in
        while True:
            pid, ptype, _ = recv_packet(s)
            if ptype == 2:                                  # the login answer
                if pid == -1:
                    raise PermissionError("rcon login refused")
                break
        s.sendall(packet(2, 2, command))
        s.sendall(packet(3, 0, ""))                         # empty packet: its echo marks the end of a long answer
        out = []
        while True:
            try:
                pid, ptype, body = recv_packet(s)
            except socket.timeout:
                if out:
                    break
                raise
            if pid == 3:
                break
            if pid == 2:
                out.append(body)
        return "".join(out)


def parse(text):
    info = {"map": None, "humans": None, "bots": None, "max": None, "names": []}
    m = re.search(r"^map\s*:\s*(\S+)", text, re.M)
    if m:
        info["map"] = m.group(1)
    m = re.search(r"^players\s*:\s*(\d+)\s*(?:humans?)?\s*(?:,\s*(\d+)\s*bots?)?\s*\((\d+)\s*max\)", text, re.M)
    if m:
        info["humans"] = int(m.group(1))
        info["bots"] = int(m.group(2)) if m.group(2) else None
        info["max"] = int(m.group(3))
    for m in re.finditer(r'^#\s*\d+(?:\s+\d+)?\s+"(.*)"\s+(\[U:\S+\]|STEAM_\S+|BOT)', text, re.M):
        if m.group(2) != "BOT":
            info["names"].append(m.group(1))
    return info


def clean(name):
    return re.sub(r"([\\*_`~|>@#\[\]()])", r"\\\1", name)[:32]


def build(name, state, info=None, note=""):
    colour = {"online": 0x2ECC71, "offline": 0xE74C3C, "unknown": 0xF1C40F}[state]
    lines = []
    if state == "online":
        lines.append("**Online**")
        if info["map"]:
            lines.append("Map: `%s`" % info["map"])
        if info["humans"] is not None:
            bots = ", %d bots" % info["bots"] if info["bots"] is not None else ""
            lines.append("Players: %d%s (%d max)" % (info["humans"], bots, info["max"]))
        if info["names"]:
            lines.append("")
            lines.extend("\u2022 " + clean(n) for n in info["names"][:30])
    elif state == "offline":
        lines.append("**Offline**")
    else:
        lines.append("**Can't read the status** " + note)
    embed = {
        "title": name,
        "description": "\n".join(lines),
        "color": colour,
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    return {"embeds": [embed], "allowed_mentions": {"parse": []}}


def call(method, url, payload):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(), method=method,
        headers={"Content-Type": "application/json", "User-Agent": "88x31-status/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, b""


def post(webhook, message_file, payload):
    try:
        mid = open(message_file).read().strip()
    except OSError:
        mid = ""
    if mid:
        code, _ = call("PATCH", "%s/messages/%s" % (webhook, mid), payload)
        if 200 <= code < 300:
            return code
    code, body = call("POST", webhook + "?wait=true", payload)
    if 200 <= code < 300:
        with open(message_file, "w") as f:
            f.write(json.loads(body)["id"])
    return code


def main():
    name, port, cfg, webhook_file, message_file = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5]
    try:
        webhook = open(webhook_file).read().strip()
    except OSError:
        print("%s: no webhook file yet (%s)" % (name, webhook_file))
        return 1
    state, info, note = "unknown", None, ""
    try:
        password = read_password(cfg)
        if not password:
            note = "(no rcon_password in server.cfg)"
        else:
            info = parse(rcon(port, password, "status"))
            state = "online"
    except ConnectionRefusedError:
        state = "offline"
    except PermissionError:
        note = "(rcon login refused)"
    except (OSError, ConnectionError) as e:
        note = "(%s)" % type(e).__name__
    code = post(webhook, message_file, build(name, state, info, note))
    print("%s: %s%s, discord answered %d" % (name, state, " " + note if note else "", code))
    return 0 if 200 <= code < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
