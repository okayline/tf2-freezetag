#!/usr/bin/env python3
"""AuraBot: the game servers' live feeds on the BBS's own IRC server (127.0.0.1:6667), one public channel per server.

Usage: aurabot.py   (no arguments; the servers are listed in SERVERS below)

- Follows each server's log files, the same way the Discord feed does: it loads discord-feed-l4d.py once per
  server (each copy keeps its own players and chapter stats) and uses its format_line, tally and summary.
  So the IRC feed shows exactly what the Discord feed shows: chat, kills, joins and leaves, map changes, chapter stats.
- Turns the Discord look into IRC's: **bold** -> bold, *italic* -> italic, `code` -> plain, \\escapes -> plain.
- Never posts IP addresses or Steam IDs (the feed code leaves them out).
- Sends at most one line a second (the server would cut off a bot that floods).
Python standard library only. Admin commands come later (private messages, after logging in)."""
import importlib.util
import os
import re
import socket
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
IRC = ("127.0.0.1", 6667)
NICK = "AuraBot"
# channel, the server's name, its log folder, the feed's game mode
SERVERS = [
    ("#tf2-freezetag", "88x31 Freeze Tag (TF2)", "/home/tf2/server/tf/logs", "tf2"),
    ("#l4d-classic", "~*~88x31~*~ L4D cLaSSiC", "/home/tf2/l4d/left4dead/logs", "l4d"),
    ("#l4d-vs", "~*~88x31~*~ L4D VeRsUs SeRveR", "/home/tf2/l4d-b/left4dead/logs", "l4d"),
    ("#l4d-vintage", "~*~88x31~*~ L4D ViNtaGe Edition", "/home/tf2/l4d-c/left4dead/logs", "l4d"),
]
B, I = "\x02", "\x1d"   # IRC bold, italic


def load_feed(tag):
    """A fresh copy of the Discord feed's code, so each server has its own state."""
    spec = importlib.util.spec_from_file_location("feed_" + tag, os.path.join(HERE, "discord-feed-l4d.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def ircify(text):
    """Discord markdown to IRC: bold, italic, no code marks, no backslash escapes."""
    text = re.sub(r"\*\*(.+?)\*\*", lambda m: B + m.group(1) + B, text)
    text = re.sub(r"(?<![\\\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w)", lambda m: I + m.group(1) + I, text)
    text = text.replace("`", "")
    text = re.sub(r"\\(.)", r"\1", text)
    return text.replace("\r", " ")


def card_lines(card):
    """The end-of-chapter stats card (a Discord embed) as plain IRC lines."""
    out = []
    for e in card.get("embeds", []):
        if e.get("title"):
            out.append(B + ircify(e["title"]) + B)
        out += [ircify(l) for l in e.get("description", "").split("\n") if l.strip()]
        for f in e.get("fields", []):
            out.append("%s%s%s: %s" % (B, ircify(f["name"]), B, ircify(f["value"]).replace("\n", " · ")))
    return out


class Feed:
    def __init__(self, chan, name, log_dir, game):
        self.chan, self.name, self.log_dir = chan, name, log_dir
        self.f = load_feed(chan.strip("#").replace("-", "_"))
        self.f.GAME = game
        self.f.CHAT_RELAYED = False          # no chat relay on IRC: show TF2 chat here
        self.path, self.fh, self.pending = None, None, ""

    def poll(self):
        """New feed lines since last time (strings or stats cards)."""
        f, out = self.f, []
        cur = f.newest(self.log_dir)
        if cur and cur != self.path:
            if self.fh:
                self.fh.close()
            self.fh = open(cur, encoding="utf-8", errors="replace")
            if self.path is None:
                for old in self.fh:          # first start: learn who is on, then only new lines
                    f.track(old)
            else:
                f.HUMANS.clear()             # new map log: players enter again
                stats = f.summary("Chapter stats") if f.GAME == "l4d" else None
                if stats:
                    out.append(stats)
            self.path, self.pending = cur, ""
        for _ in range(200):                 # at most 200 lines a round, so one busy server cannot hold up the rest
            part = self.fh.readline() if self.fh else ""
            if not part:
                break
            self.pending += part
            if not self.pending.endswith("\n"):
                break
            line, self.pending = self.pending, ""
            try:
                f.track(line)
                o = f.format_line(line)
                if f.GAME == "l4d":
                    if re.search(r'World triggered "(?i:(round_end|finale_win|mission_lost))"', line):
                        stats = f.summary("Chapter stats")
                        if stats:
                            out.append(stats)
                    f.tally(line)
                if f.GAME == "tf2" and not f.HUMANS and "disconnected" not in line:
                    o = None                 # only bots playing: stay quiet
            except Exception:
                o = None
            if o:
                out.append(o)
        return out


class Irc:
    def __init__(self):
        self.sock, self.buf, self.queue, self.last_send, self.ready = None, b"", [], 0.0, False

    def connect(self, chans):
        self.sock = socket.create_connection(IRC, timeout=10)
        self.sock.settimeout(0.2)
        self.buf, self.ready = b"", False
        self.raw("NICK " + NICK)
        self.raw("USER aurabot 0 * :AuraBot, the 88x31 game feeds")
        self.chans = chans

    def raw(self, line):
        self.sock.sendall((line[:500] + "\r\n").encode("utf-8", "replace"))

    def say(self, chan, text):
        for chunk in [text[i:i + 400] for i in range(0, len(text), 400)] or [""]:
            self.queue.append("PRIVMSG %s :%s" % (chan, chunk))

    def pump(self):
        """Read what the server sent (answer PINGs, join once welcomed); send one queued line a second."""
        try:
            data = self.sock.recv(4096)
            if not data:
                raise ConnectionError("server closed the connection")
            self.buf += data
        except socket.timeout:
            pass
        while b"\r\n" in self.buf or b"\n" in self.buf:
            line, _, self.buf = self.buf.replace(b"\r\n", b"\n").partition(b"\n")
            msg = line.decode("utf-8", "replace")
            if msg.startswith("PING"):
                self.raw("PONG" + msg[4:])
            parts = msg.split(" ")
            if len(parts) > 1 and parts[1] == "001":
                self.raw("JOIN " + ",".join(self.chans))
                self.ready = True
            elif len(parts) > 1 and parts[1] == "433":      # nickname taken: try again a bit later
                raise ConnectionError("nickname %s is taken" % NICK)
        if self.ready and self.queue and time.time() - self.last_send >= 1.0:
            self.raw(self.queue.pop(0))
            self.last_send = time.time()


def main():
    feeds = [Feed(*s) for s in SERVERS]
    irc = Irc()
    last_report, posted = time.time(), 0
    while True:
        try:
            irc.connect([fd.chan for fd in feeds])
            print("AuraBot: connected", flush=True)
            while True:
                for fd in feeds:
                    for item in fd.poll():
                        lines = card_lines(item) if isinstance(item, dict) else [ircify(item)]
                        for l in lines:
                            irc.say(fd.chan, l)
                            posted += 1
                if len(irc.queue) > 60:                     # far behind: drop the oldest, say so once
                    dropped = len(irc.queue) - 40
                    irc.queue = irc.queue[dropped:]
                    print("AuraBot: dropped %d queued lines (busy)" % dropped, flush=True)
                irc.pump()
                if time.time() - last_report > 300:
                    print("AuraBot: last 5 min: %d lines posted" % posted, flush=True)
                    posted, last_report = 0, time.time()
        except (OSError, ConnectionError) as e:
            print("AuraBot: %s; reconnecting in 15 s" % e, flush=True)
            try:
                irc.sock.close()
            except Exception:
                pass
            irc.queue = []
            time.sleep(15)


if __name__ == "__main__":
    sys.exit(main())
