#!/usr/bin/env python3
"""Live game feed to Discord: chat, kills, joins and leaves, round wins, map changes.

Usage: discord-feed.py NAME RCON_PORT SERVER_CFG WEBHOOK_FILE LOG_PORT

- Listens for the server's own log lines on UDP 127.0.0.1:LOG_PORT. Every minute it tells the
  server (over RCON, password read from SERVER_CFG) to `log on` and send its log there, so a
  server restart cannot silently stop the feed. Nothing in server.cfg needs to change.
- Batches lines for a few seconds and posts them as one message to the webhook in WEBHOOK_FILE.
- Never posts or prints IP addresses or Steam IDs. Bots are shown as players, but a kill between
  two bots is skipped. Chat text is never printed to the journal, only counts.
Python standard library only; reuses the RCON and Discord helpers in discord-status.py."""
import importlib.util
import os
import re
import socket
import sys
import time

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("status", os.path.join(here, "discord-status.py"))
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)

WHO = r'"(.*?)<\d+><([^>]*)><([^>]*)>"'
RULES = [
    ("say_team", re.compile(WHO + r' say_team "(.*)"')),
    ("say", re.compile(WHO + r' say "(.*)"')),
    ("kill", re.compile(WHO + r' killed ' + WHO + r' with "([^"]*)"')),
    ("suicide", re.compile(WHO + r' committed suicide')),
    ("joined", re.compile(WHO + r' entered the game')),
    ("left", re.compile(WHO + r' disconnected')),
    ("round", re.compile(r'World triggered "Round_Win" \(winner "([^"]*)"\)')),
    ("map", re.compile(r'Started map "([^"]*)"')),
]


def esc(text, n):
    return re.sub(r"([\\*_`~|>@#\[\]()])", r"\\\1", text.replace("\n", " "))[:n]


def format_line(raw):
    """Turn one log line into a Discord line, or None to skip it."""
    text = raw.split(": ", 1)[-1] if re.match(r"\d\d/\d\d/\d{4}", raw) else raw
    for kind, rx in RULES:
        m = rx.search(text)
        if not m:
            continue
        g = m.groups()
        if kind in ("say", "say_team"):
            tag = " *(team)*" if kind == "say_team" else ""
            return "\U0001F4AC **%s**%s: %s" % (esc(g[0], 32), tag, esc(g[3], 250))
        if kind == "kill":
            if g[1] == "BOT" and g[4] == "BOT":
                return None
            return "☠️ %s killed %s (%s)" % (esc(g[0], 32), esc(g[3], 32), esc(g[6], 24))
        if kind == "suicide":
            return "☠️ %s died" % esc(g[0], 32)
        if kind == "joined":
            return "➕ %s joined" % esc(g[0], 32)
        if kind == "left":
            return "➖ %s left" % esc(g[0], 32)
        if kind == "round":
            return "\U0001F3C1 %s wins the round" % esc(g[0], 16)
        if kind == "map":
            return "\U0001F5FA️ Map: `%s`" % esc(g[0], 48).replace("\\", "")
    return None


def decode(data):
    """Log packets start with 4 bytes of 0xFF and a few header characters, then the line."""
    s = data.decode("utf-8", "replace")
    s = re.sub(r"^�{4}\S*?L ", "", s) if s.startswith("�") else s
    return s.strip("\x00\r\n ")


def flush(webhook, lines):
    if not lines:
        return 0
    extra = len(lines) - 40
    lines = lines[:40] + (["… and %d more" % extra] if extra > 0 else [])
    body = "\n".join(lines)[:1900]
    payload = {"content": body, "allowed_mentions": {"parse": []}}
    code, _ = status.call("POST", webhook, payload)
    if code == 429:
        time.sleep(3)
        code, _ = status.call("POST", webhook, payload)
    return code


def tell_server(rcon_port, cfg, log_port):
    """Each command on its own: the server may not echo an answer for a command with no output."""
    failed = []
    pw = None
    try:
        pw = status.read_password(cfg)
    except OSError:
        failed.append("read server.cfg")
    if not pw:
        return failed or ["no rcon_password"]
    for cmd in ("log on", "logaddress_add 127.0.0.1:%d" % log_port):
        try:
            status.rcon(rcon_port, pw, cmd)
        except socket.timeout:
            pass                                    # sent; the server just gave no reply to read
        except Exception as e:
            failed.append("%s: %s" % (cmd.split()[0], type(e).__name__))
    return failed


def main():
    name, rcon_port, cfg, webhook_file, log_port = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], int(sys.argv[5])
    webhook = open(webhook_file).read().strip()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("127.0.0.1", log_port))
    sock.settimeout(1)
    buf, first, last_tell, last_report = [], 0, 0, time.time()
    got = posted = unmatched = 0
    told_failed = False
    print("%s feed: listening on 127.0.0.1:%d" % (name, log_port), flush=True)
    while True:
        now = time.time()
        if now - last_tell > 60:
            failed = tell_server(rcon_port, cfg, log_port)
            if failed and not told_failed:
                print("%s feed: could not tell the server to send logs (%s)" % (name, ", ".join(failed)), flush=True)
            told_failed = bool(failed)
            last_tell = now
        try:
            data, _ = sock.recvfrom(4096)
            got += 1
            try:
                line = format_line(decode(data))
            except Exception:
                line = None
            if line:
                if not buf:
                    first = now
                buf.append(line)
            else:
                unmatched += 1
        except socket.timeout:
            pass
        if buf and (time.time() - first >= 3 or len(buf) >= 40):
            code = flush(webhook, buf)
            posted += len(buf)
            if not 200 <= code < 300:
                print("%s feed: discord answered %d" % (name, code), flush=True)
            buf = []
        if now - last_report > 300:
            print("%s feed: last 5 min: %d log lines, %d posted, %d skipped" % (name, got, posted, unmatched), flush=True)
            got = posted = unmatched = 0
            last_report = now


if __name__ == "__main__":
    sys.exit(main())
