#!/usr/bin/env python3
"""AuraBot: the game servers' live feeds on the BBS's own IRC server (127.0.0.1:6667), one public channel per server.

Usage: aurabot.py   (no arguments; the servers are listed in SERVERS below)

- Follows each server's log files, the same way the Discord feed does: it loads discord-feed-l4d.py once per
  server (each copy keeps its own players and chapter stats) and uses its format_line, tally and summary.
  So the IRC feed shows exactly what the Discord feed shows: chat, kills, joins and leaves, map changes, chapter stats.
- Turns the Discord look into IRC's: **bold** -> bold, *italic* -> italic, `code` -> plain, \\escapes -> plain.
- Never posts IP addresses or Steam IDs (the feed code leaves them out).
- Sends at most one line a second (the server would cut off a bot that floods); answers to the admin go first.
- Admin commands: only in a private message to AuraBot, never in a channel (commands typed in a channel are ignored).
  First "login <password>" (the password is in admin-pass next to this script, from repo secret AURABOT_PASS).
  The login belongs to that nickname only while it shares a channel with AuraBot: when it quits, leaves every shared
  channel or changes nickname, it is logged out, so nobody can take over a logged-in nickname. Wrong passwords are
  slowed down (one try every 10 seconds) and written to the journal. "!help" lists the commands.
Python standard library only."""
import hmac
import glob
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
# admin: key -> label, game, RCON port, server.cfg (for the RCON password), log folder (same servers as discord-bot.py)
ADMIN = {
    "tf2":     dict(label="TF2 Freeze Tag", game="tf2", port=27015, cfg="/home/tf2/server/tf/cfg/server.cfg", logs="/home/tf2/server/tf/logs"),
    "classic": dict(label="cLaSSiC", game="l4d", port=27016, cfg="/home/tf2/l4d/left4dead/cfg/server.cfg", logs="/home/tf2/l4d/left4dead/logs"),
    "vs":      dict(label="VeRsUs", game="l4d", port=27017, cfg="/home/tf2/l4d-b/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-b/left4dead/logs"),
    "vintage": dict(label="ViNtaGe", game="l4d", port=27018, cfg="/home/tf2/l4d-c/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-c/left4dead/logs"),
}
ALIASES = {"freezetag": "tf2", "l4d": "classic", "l4d-classic": "classic", "l4db": "vs", "versus": "vs", "l4d-vs": "vs",
           "l4dc": "vintage", "l4d-vintage": "vintage"}
PASS_FILE = os.path.join(HERE, "admin-pass")
NOISE = re.compile(r'rcon from|Log file (started|closed)|path_goal|\bstuck\b|\bunstuck\b'
                   r'|server cvars (start|end)|^\S+ "[^"]+" = "[^"]*"\s*$|^L \d+/\d+/\d+ - \d+:\d+:\d+: "[^"]+" = "[^"]*"\s*$'
                   r'|NAV_MOB_ONLY|Computing Flow Distances|Preventing spawning')
HELP = [
    "AuraBot admin commands (private messages only). Servers: tf2, classic, vs, vintage",
    "!status  every server: map and players",
    "!players <server>  who is on",
    "!say <server> <message>  a message to everyone in the game",
    "!kick <server> <name>  kick a player (part of the name is enough)",
    "!ban <server> <name>  permanent ban (then !yes within 30 seconds)",
    "!map tf2 <map>  change the TF2 map",
    "!restartround <server>  restart the round (TF2) or the chapter (L4D)",
    "!logs <server> [lines] [filter]  last log lines, IPs and Steam IDs removed (up to 25)",
    "!logout",
]


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
        self.sock, self.buf, self.queue, self.urgent, self.last_send, self.ready = None, b"", [], [], 0.0, False
        self.members = {}                     # channel -> nicknames in it (lowercase), to know who shares a channel with us

    def connect(self, chans):
        self.sock = socket.create_connection(IRC, timeout=10)
        self.sock.settimeout(0.2)
        self.buf, self.ready, self.members = b"", False, {}
        self.raw("NICK " + NICK)
        self.raw("USER aurabot 0 * :AuraBot, the 88x31 game feeds")
        self.chans = chans

    def raw(self, line):
        self.sock.sendall((line[:500] + "\r\n").encode("utf-8", "replace"))

    def say(self, chan, text):
        for chunk in [text[i:i + 400] for i in range(0, len(text), 400)] or [""]:
            self.queue.append("PRIVMSG %s :%s" % (chan, chunk))

    def tell(self, nick, text):
        """A private message to one person; goes before the feed lines."""
        for chunk in [text[i:i + 400] for i in range(0, len(text), 400)] or [""]:
            self.urgent.append("PRIVMSG %s :%s" % (nick, chunk))

    def shares(self, nick):
        n = nick.lower()
        return any(n in m for m in self.members.values())

    def track(self, prefix, cmd, args):
        """Keep self.members up to date; returns the nicknames that just stopped sharing a channel with us."""
        who = prefix.split("!")[0].lower()
        gone = []
        if cmd == "353" and len(args) >= 4:                       # NAMES reply
            self.members.setdefault(args[2].lower(), set()).update(n.lstrip("@+").lower() for n in args[3].split())
        elif cmd == "JOIN" and args:
            for c in args[0].split(","):
                self.members.setdefault(c.lower(), set()).add(who)
        elif cmd == "PART" and args:
            self.members.get(args[0].lower(), set()).discard(who)
            gone.append(who)
        elif cmd == "KICK" and len(args) >= 2:
            self.members.get(args[0].lower(), set()).discard(args[1].lower())
            gone.append(args[1].lower())
        elif cmd == "QUIT":
            for m in self.members.values():
                m.discard(who)
            gone.append(who)
        elif cmd == "NICK" and args:
            for m in self.members.values():
                if who in m:
                    m.discard(who)
                    m.add(args[0].lower())
            gone.append(who)                                      # a new nickname has to log in again
        return [g for g in gone if cmd in ("QUIT", "NICK") or not self.shares(g)]

    def pump(self):
        """Read what the server sent (answer PINGs, join once welcomed); send one queued line a second.
        Returns [(prefix, command, args)] for the caller; the last arg is the text after ' :'."""
        got = []
        try:
            data = self.sock.recv(4096)
            if not data:
                raise ConnectionError("server closed the connection")
            self.buf += data
        except socket.timeout:
            pass
        while b"\n" in self.buf:
            line, _, self.buf = self.buf.partition(b"\n")
            msg = line.decode("utf-8", "replace").rstrip("\r")
            if msg.startswith("PING"):
                self.raw("PONG" + msg[4:])
                continue
            prefix = ""
            if msg.startswith(":"):
                prefix, _, msg = msg[1:].partition(" ")
            head, _, trail = msg.partition(" :")
            parts = head.split()
            if not parts:
                continue
            cmd, args = parts[0].upper(), parts[1:] + ([trail] if trail or " :" in msg else [])
            if cmd == "001":
                self.raw("JOIN " + ",".join(self.chans))
                self.ready = True
            elif cmd == "433":                                    # nickname taken: try again a bit later
                raise ConnectionError("nickname %s is taken" % NICK)
            got.append((prefix, cmd, args))
        q = self.urgent or self.queue
        if self.ready and q and time.time() - self.last_send >= 1.0:
            self.raw(q.pop(0))
            self.last_send = time.time()
        return got


# ---------- admin ----------
def rcon(key, command):
    ds = ADMIN_DS
    pw = ds.read_password(ADMIN[key]["cfg"])
    if not pw:
        raise PermissionError("no rcon_password")
    return ds.rcon(ADMIN[key]["port"], pw, command)


def players(key):
    """[(userid, name)] of humans, parsed from `status`; plus the status info."""
    text = rcon(key, "status")
    info = ADMIN_DS.parse(text)
    out = [(m.group(1), m.group(2)) for m in re.finditer(
        r'^#\s*(\d+)(?:\s+\d+)?\s+"(.*)"\s+(\[U:\S+\]|STEAM_\S+|BOT)', text, re.M) if m.group(3) != "BOT"]
    return out, info


def safe_text(s, n=150):
    return re.sub(r'[;"\\\r\n]', " ", s)[:n].strip()


def clean_log(line):
    """One game-log line made readable: '19:46:10 text', no IPs or Steam IDs (same as the Discord bot's /logs)."""
    m = re.match(r"L (\d+/\d+/\d+) - (\d+:\d+:\d+):\s*(.*)", line)
    if m:
        line = "%s %s" % (m.group(2), m.group(3))
    id_part = r"(?:STEAM_[0-9:]+|\[U:\d:\d+\]|BOT|Console)"
    line = re.sub(r"<\d+><%s><([^<>]*)>" % id_part, lambda g: " (%s)" % g.group(1) if g.group(1) else "", line)
    line = re.sub(r"<\d+><%s>" % id_part, "", line)
    line = re.sub(r"STEAM_\d:\d:\d+", "(id)", line)
    line = re.sub(r"\[U:\d:\d+\]", "(id)", line)
    return re.sub(r"\d{1,3}(\.\d{1,3}){3}(:\d+)?", "(ip)", line)


def find_player(key, part):
    """(userid, name) of the one human whose name contains part (exact name wins), else an error text."""
    names, _ = players(key)
    exact = [(u, n) for u, n in names if n.lower() == part.lower()]
    hits = exact or [(u, n) for u, n in names if part.lower() in n.lower()]
    if len(hits) == 1:
        return hits[0], None
    if not hits:
        return None, "Nobody named like %s on %s right now." % (part, ADMIN[key]["label"])
    return None, "More than one match: %s. Type more of the name." % ", ".join(n for _, n in hits[:6])


class Admin:
    def __init__(self, irc):
        self.irc, self.logged_in, self.last_try, self.pending_ban = irc, set(), {}, {}

    def forget(self, nicks):
        for n in nicks:
            if n in self.logged_in:
                self.logged_in.discard(n)
                print("AuraBot: %s logged out (left, quit or renamed)" % n, flush=True)
            self.pending_ban.pop(n, None)

    def handle(self, nick, text):
        n, text = nick.lower(), text.strip()
        word = text.split(" ", 1)[0].lower()
        if word == "login":
            return self.login(nick, text[6:])
        if n not in self.logged_in:
            if text.startswith("!"):
                self.irc.tell(nick, "Log in first: login <password>")
            return
        if not text.startswith("!"):
            return
        cmd, *rest = text[1:].split(" ", 1)
        rest = rest[0].strip() if rest else ""
        cmd = cmd.lower()
        print("AuraBot: %s used !%s" % (n, cmd), flush=True)    # the command only, never its text
        try:
            getattr(self, "c_" + cmd, self.c_unknown)(nick, rest)
        except (OSError, PermissionError) as e:
            self.irc.tell(nick, "That server isn't answering (%s)." % type(e).__name__)

    def login(self, nick, given):
        n, now = nick.lower(), time.time()
        if now - self.last_try.get(n, 0) < 10:
            return self.irc.tell(nick, "Wait 10 seconds between tries.")
        self.last_try[n] = now
        try:
            want = open(PASS_FILE).read().strip()
        except OSError:
            want = ""
        if not self.irc.shares(nick):
            return self.irc.tell(nick, "Join one of my channels first (like #tf2-freezetag), then log in.")
        if want and hmac.compare_digest(given.strip().encode(), want.encode()):
            self.logged_in.add(n)
            print("AuraBot: %s logged in" % n, flush=True)
            self.irc.tell(nick, "Logged in. You stay logged in until you quit, leave my channels or change nickname. !help for commands.")
        else:
            print("AuraBot: wrong password from %s" % n, flush=True)
            self.irc.tell(nick, "Wrong password.")

    def server(self, nick, word):
        k = ALIASES.get(word.lower(), word.lower())
        if k not in ADMIN:
            self.irc.tell(nick, "Which server? tf2, classic, vs or vintage.")
            return None
        return k

    def c_unknown(self, nick, rest):
        self.irc.tell(nick, "I don't know that one. !help for commands.")

    def c_help(self, nick, rest):
        for l in HELP:
            self.irc.tell(nick, l)

    def c_logout(self, nick, rest):
        self.logged_in.discard(nick.lower())
        self.irc.tell(nick, "Logged out.")

    def c_status(self, nick, rest):
        for k, s in ADMIN.items():
            try:
                _, info = players(k)
                bots = ", %s bots" % info["bots"] if info["bots"] else ""
                self.irc.tell(nick, "%s%s%s: %s, %s players%s" % (B, s["label"], B, info["map"], info["humans"], bots))
            except Exception:
                self.irc.tell(nick, "%s%s%s: not answering (stopped?)" % (B, s["label"], B))

    def c_players(self, nick, rest):
        k = self.server(nick, rest.split(" ")[0])
        if k:
            names, info = players(k)
            self.irc.tell(nick, "%s%s%s, %s: %s" % (B, ADMIN[k]["label"], B, info["map"], ", ".join(n for _, n in names) or "nobody"))

    def c_say(self, nick, rest):
        word, _, msg = rest.partition(" ")
        k = self.server(nick, word)
        if k and msg.strip():
            rcon(k, 'say "[IRC] %s: %s"' % (safe_text(nick, 24), safe_text(msg)))
            self.irc.tell(nick, "Sent.")

    def c_kick(self, nick, rest):
        word, _, name = rest.partition(" ")
        k = self.server(nick, word)
        if not k or not name.strip():
            return k and self.irc.tell(nick, "!kick <server> <name>")
        hit, err = find_player(k, name.strip())
        if err:
            return self.irc.tell(nick, err)
        rcon(k, 'kickid %s "kicked by an admin"' % hit[0])
        print("AuraBot: kick on %s" % k, flush=True)
        self.irc.tell(nick, "Kicked %s from %s." % (hit[1], ADMIN[k]["label"]))

    def c_ban(self, nick, rest):
        word, _, name = rest.partition(" ")
        k = self.server(nick, word)
        if not k or not name.strip():
            return k and self.irc.tell(nick, "!ban <server> <name>")
        hit, err = find_player(k, name.strip())
        if err:
            return self.irc.tell(nick, err)
        self.pending_ban[nick.lower()] = (k, hit, time.time())
        self.irc.tell(nick, "Permanently ban %s from %s? Type !yes within 30 seconds." % (hit[1], ADMIN[k]["label"]))

    def c_yes(self, nick, rest):
        p = self.pending_ban.pop(nick.lower(), None)
        if not p or time.time() - p[2] > 30:
            return self.irc.tell(nick, "Nothing waiting for a yes.")
        k, hit, _ = p
        rcon(k, 'sm_ban #%s 0 "banned by an admin"' % hit[0])
        print("AuraBot: ban on %s" % k, flush=True)
        self.irc.tell(nick, "Banned %s from %s." % (hit[1], ADMIN[k]["label"]))

    def c_map(self, nick, rest):
        word, _, mp = rest.partition(" ")
        k = self.server(nick, word)
        if not k:
            return
        if ADMIN[k]["game"] != "tf2":
            return self.irc.tell(nick, "Map changes are for TF2 only (L4D map names depend on the mode).")
        if not re.fullmatch(r"[A-Za-z0-9_]{1,64}", mp.strip()):
            return self.irc.tell(nick, "!map tf2 <map name>, like cp_gravelpit_snowy")
        rcon(k, "changelevel " + mp.strip())
        self.irc.tell(nick, "Changing %s to %s." % (ADMIN[k]["label"], mp.strip()))

    def c_restartround(self, nick, rest):
        k = self.server(nick, rest.split(" ")[0])
        if not k:
            return
        if ADMIN[k]["game"] == "tf2":
            rcon(k, "mp_restartgame 1")
        else:
            _, info = players(k)
            rcon(k, "changelevel " + info["map"])
        self.irc.tell(nick, "Restarted the round on %s." % ADMIN[k]["label"])

    def c_logs(self, nick, rest):
        parts = rest.split(" ", 2)
        k = self.server(nick, parts[0])
        if not k:
            return
        n, flt = 15, ""
        if len(parts) > 1 and parts[1].isdigit():
            n, flt = max(1, min(25, int(parts[1]))), (parts[2] if len(parts) > 2 else "")
        elif len(parts) > 1:
            flt = " ".join(parts[1:])
        flt = flt.lower()[:40]
        files = sorted(glob.glob(ADMIN[k]["logs"] + "/[Ll]*.log"), key=os.path.getmtime)
        rows = []
        for path in reversed(files[-6:]):
            part = []
            for raw in open(path, encoding="utf-8", errors="replace"):
                for l in re.split(r"(?=L \d+/\d+/\d+ - )", raw):
                    l = l.strip()
                    if l and not NOISE.search(l) and flt in l.lower():
                        part.append(clean_log(l))
            rows = part + rows
            if len(rows) >= n:
                break
        for r in rows[-n:] or ["(nothing in the recent logs)"]:
            self.irc.tell(nick, r[:300])


def main():
    global ADMIN_DS
    spec = importlib.util.spec_from_file_location("ds", os.path.join(HERE, "discord-status.py"))
    ADMIN_DS = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ADMIN_DS)
    feeds = [Feed(*s) for s in SERVERS]
    irc = Irc()
    admin = Admin(irc)
    last_report, posted = time.time(), 0
    while True:
        try:
            irc.connect([fd.chan for fd in feeds])
            admin.logged_in.clear()
            print("AuraBot: connected", flush=True)
            while True:
                for fd in feeds:
                    for item in fd.poll():
                        lines = card_lines(item) if isinstance(item, dict) else [ircify(item)]
                        for l in lines:
                            irc.say(fd.chan, l)
                            posted += 1
                if len(irc.queue) > 60:                     # far behind: drop the oldest
                    dropped = len(irc.queue) - 40
                    irc.queue = irc.queue[dropped:]
                    print("AuraBot: dropped %d queued lines (busy)" % dropped, flush=True)
                for prefix, cmd, args in irc.pump():
                    admin.forget(irc.track(prefix, cmd, args))
                    # private messages only (target is our own nickname); channel messages are never commands
                    if cmd == "PRIVMSG" and len(args) >= 2 and args[0].lower() == NICK.lower() and "!" in prefix:
                        try:
                            admin.handle(prefix.split("!")[0], args[1])
                        except Exception as e:                  # a bad command never stops the feeds
                            print("AuraBot: command failed (%s)" % type(e).__name__, flush=True)
                            irc.tell(prefix.split("!")[0], "Something went wrong with that command.")
                if time.time() - last_report > 300:
                    print("AuraBot: last 5 min: %d lines posted" % posted, flush=True)
                    posted, last_report = 0, time.time()
        except (OSError, ConnectionError) as e:
            print("AuraBot: %s; reconnecting in 15 s" % e, flush=True)
            try:
                irc.sock.close()
            except Exception:
                pass
            irc.queue, irc.urgent = [], []
            time.sleep(15)


if __name__ == "__main__":
    sys.exit(main())
