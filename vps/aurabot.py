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
  An IRC operator (/oper, which needs the BBS system password and a connection from the VPS itself) needs no login:
  joining one of AuraBot's channels (or their first command) makes AuraBot check WHOIS, and an operator who shares
  a channel is logged in by that, and gets @ wherever AuraBot has it.
  A login also survives AuraBot restarting (see Admin).
- Background jobs (taken over from the Discord bot, in a thread of their own, every 30 seconds; see Watcher):
  in-game announcements every 65 minutes (announcements-<server>.txt), playtime for !seen, server offline/back
  posts, low memory/disk warnings, the nightly backup result, and the Sunday weekly stats (leaderboard.py).
- Each server channel's topic shows the server's status (map, who is playing), like the Discord status message did.
- Start/stop/restart/pause/resume use AuraBot's sudo rules (/etc/sudoers.d/aurabot, from aurabot-setup.sh).
  Kicks, bans and playtime go in the Discord bot's old database (/home/tf2/discord/bot.db), kept for its history.
Python standard library only."""
import hmac
import json
import glob
import datetime
import importlib.util
import queue
import random
import threading
import os
import re
import shutil
import socket
import sqlite3
import subprocess
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
# admin: key -> label, game, service, RCON port, server.cfg (for the RCON password), log folder
ADMIN = {
    "tf2":     dict(label="TF2 Freeze Tag", game="tf2", service="tf2", port=27015, cfg="/home/tf2/server/tf/cfg/server.cfg", logs="/home/tf2/server/tf/logs"),
    "classic": dict(label="cLaSSiC", game="l4d", service="l4d", port=27016, cfg="/home/tf2/l4d/left4dead/cfg/server.cfg", logs="/home/tf2/l4d/left4dead/logs"),
    "vs":      dict(label="VeRsUs", game="l4d", service="l4db", vs=True, port=27017, cfg="/home/tf2/l4d-b/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-b/left4dead/logs"),
    "vintage": dict(label="ViNtaGe", game="l4d", service="l4dc", port=27018, cfg="/home/tf2/l4d-c/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-c/left4dead/logs"),
}
ALIASES = {"freezetag": "tf2", "l4d": "classic", "l4d-classic": "classic", "l4db": "vs", "versus": "vs", "l4d-vs": "vs",
           "l4dc": "vintage", "l4d-vintage": "vintage"}
PASS_FILE = os.path.join(HERE, "admin-pass")
LOGINS_FILE = os.path.join(HERE, "logins.json")   # who is logged in, with their connection's sign-on time (no passwords)
DB = "/home/tf2/discord/bot.db"   # the Discord bot's log of kicks/bans and playtime; shared, so both bots see one history
CAMPAIGNS = {"nomercy": ("No Mercy", "hospital01_apartment"), "crashcourse": ("Crash Course", "garage01_alleys"),
             "deathtoll": ("Death Toll", "smalltown01_caves"), "deadair": ("Dead Air", "airport01_greenhouse"),
             "bloodharvest": ("Blood Harvest", "farm01_hilltop"), "sacrifice": ("The Sacrifice", "river01_docks")}
DIFFICULTIES = ["Easy", "Normal", "Hard", "Impossible"]
AD_EVERY = 65 * 60                     # seconds between in-game chat announcements per server
ALERT_CHANNEL = "#tf2-freezetag"       # low memory / disk warnings and the nightly backup result (same as on Discord)
LB_IGNORE = "/home/tf2/leaderboard-ignore.txt"
LB_KIND = {"tf2": "tf2", "classic": "l4d", "vs": "l4dvs", "vintage": "l4d"}
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
    "!start / !stop / !restart <server>  the server itself (stop and restart ask for !yes)",
    "!pause <server>  stop it and keep it off after reboots (asks for !yes); !resume <server> undoes it",
    "!campaign <server> <name>  L4D from chapter 1: nomercy, crashcourse, deathtoll, deadair, bloodharvest, sacrifice",
    "!difficulty <server> <easy|normal|hard|impossible>  L4D, this game only",
    "!bots <0-24>  TF2 bots (0 = none, until the next restart)",
    "!scramble  scramble the TF2 teams",
    "!health  memory, disk, load, which servers are on",
    "!history  the last 10 kicks and bans (Discord and IRC)",
    "!seen <server> <name>  last seen and total playtime",
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
        self.ops = {}                         # channel -> nicknames with @ in it (lowercase)

    def connect(self, chans):
        self.sock = socket.create_connection(IRC, timeout=10)
        self.sock.settimeout(0.2)
        self.buf, self.ready, self.members, self.ops = b"", False, {}, {}
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

    def is_op(self, chan, nick=NICK):
        return nick.lower() in self.ops.get(chan.lower(), set())

    def shares(self, nick):
        n = nick.lower()
        return any(n in m for m in self.members.values())

    def track(self, prefix, cmd, args):
        """Keep self.members up to date; returns the nicknames that just stopped sharing a channel with us."""
        who = prefix.split("!")[0].lower()
        gone = []
        if cmd == "353" and len(args) >= 4:                       # NAMES reply
            self.members.setdefault(args[2].lower(), set()).update(n.lstrip("@+").lower() for n in args[3].split())
            self.ops.setdefault(args[2].lower(), set()).update(n[1:].lower() for n in args[3].split() if n.startswith("@"))
        elif cmd == "MODE" and len(args) >= 3 and args[0].startswith("#"):   # +o/-o (simple: one mode letter per target)
            add, targets = True, args[2:]
            for ch in args[1]:
                if ch in "+-":
                    add = ch == "+"
                elif ch == "o" and targets:
                    (self.ops.setdefault(args[0].lower(), set()).add if add else self.ops.setdefault(args[0].lower(), set()).discard)(targets.pop(0).lower())
                elif ch in "vbklIe" and targets and (add or ch != "l"):
                    targets.pop(0)
        elif cmd == "JOIN" and args:
            for c in args[0].split(","):
                self.members.setdefault(c.lower(), set()).add(who)
        elif cmd == "PART" and args:
            self.members.get(args[0].lower(), set()).discard(who)
            self.ops.get(args[0].lower(), set()).discard(who)
            gone.append(who)
        elif cmd == "KICK" and len(args) >= 2:
            self.members.get(args[0].lower(), set()).discard(args[1].lower())
            self.ops.get(args[0].lower(), set()).discard(args[1].lower())
            gone.append(args[1].lower())
        elif cmd == "QUIT":
            for m in list(self.members.values()) + list(self.ops.values()):
                m.discard(who)
            gone.append(who)
        elif cmd == "NICK" and args:
            for m in list(self.members.values()) + list(self.ops.values()):
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


def sudo(*args):
    """Only the exact systemctl commands allowed for the tf2 user in /etc/sudoers.d/discord-bot."""
    r = subprocess.run(["sudo", "-n", "/usr/bin/systemctl", *args], capture_output=True, text=True, timeout=60)
    return r.returncode == 0, (r.stderr or r.stdout).strip()[-200:]


def is_active(service):
    return subprocess.run(["systemctl", "is-active", "--quiet", service]).returncode == 0


def mem_free_mb():
    for line in open("/proc/meminfo"):
        if line.startswith("MemAvailable"):
            return int(line.split()[1]) // 1024
    return 0


def db():
    return sqlite3.connect(DB, timeout=10)


def log_action(key, by, what, target, reason=""):
    """Into the Discord bot's moderation log, so !history and /history show the same list."""
    try:
        with db() as c:
            c.execute("INSERT INTO actions VALUES (?,?,?,?,?,?)", (int(time.time()), DB_KEY[key], by + " (IRC)", what, target, reason))
    except Exception as e:
        print("AuraBot: db error %s" % type(e).__name__, flush=True)


DB_KEY = {"tf2": "tf2", "classic": "l4d", "vs": "l4db", "vintage": "l4dc"}   # the Discord bot's names for the servers


def ago(ts):
    s = int(time.time() - ts)
    for n, unit in ((86400, "day"), (3600, "hour"), (60, "minute")):
        if s >= n:
            return "%d %s%s ago" % (s // n, unit, "s" if s // n != 1 else "")
    return "just now"


class Admin:
    """Logins: nickname -> the IRC server's sign-on time of that connection (from WHOIS). Kept in LOGINS_FILE, so a
    login survives AuraBot restarting: on (re)connect it asks WHOIS again and only keeps a login whose connection has
    the same sign-on time (the same connection, not someone who took the nickname in between)."""
    def __init__(self, irc):
        self.irc, self.logged_in, self.last_try, self.pending_ban = irc, set(), {}, {}
        self.signon = {}                       # nickname -> sign-on time, for the logged-in ones (and those being checked)
        self.checking = {}                     # nickname -> saved sign-on time, waiting for its WHOIS answer
        self.asking = {}                       # nickname -> [command waiting, is an IRC operator?] while WHOIS answers

    def save(self):
        try:
            with open(LOGINS_FILE + ".tmp", "w") as f:
                json.dump({n: self.signon[n] for n in self.logged_in if n in self.signon}, f)
            os.replace(LOGINS_FILE + ".tmp", LOGINS_FILE)
        except OSError as e:
            print("AuraBot: could not save logins (%s)" % type(e).__name__, flush=True)

    def restore(self):
        """On connecting: forget the old connection's logins and load the saved ones to check."""
        self.logged_in, self.signon = set(), {}
        try:
            self.checking = {n: int(s) for n, s in json.load(open(LOGINS_FILE)).items()}
        except (OSError, ValueError):
            self.checking = {}

    def check_saved(self):
        """Once welcomed and joined (after 001): ask WHOIS for each saved login; whois_reply decides."""
        for n in self.checking:
            self.irc.raw("WHOIS " + n)

    def whois_reply(self, cmd, args):
        """317: me nick idle signon :text ; 401/318: no such nick / end of WHOIS."""
        if cmd == "317" and len(args) >= 4 and args[3].isdigit():
            n, s = args[1].lower(), int(args[3])
            if n in self.checking:
                if self.checking.pop(n) == s and self.irc.shares(n):
                    self.logged_in.add(n)
                    self.signon[n] = s
                    print("AuraBot: %s still logged in (same connection)" % n, flush=True)
                self.save()
            elif n in self.logged_in and n not in self.signon:
                self.signon[n] = s             # a fresh login: remember its connection
                self.save()
        elif cmd in ("401", "318") and len(args) >= 2 and args[1].lower() in self.checking:
            self.checking.pop(args[1].lower())  # gone, or no sign-on time: that login is over
            self.save()
        if cmd == "313" and len(args) >= 3 and "Operator" in args[-1] and args[1].lower() in self.asking:
            self.asking[args[1].lower()][1] = True          # "is an IRC operator"
        elif cmd in ("318", "401") and len(args) >= 2 and args[1].lower() in self.asking:
            nick = args[1]
            text, oper = self.asking.pop(nick.lower())
            if oper and self.irc.shares(nick):
                # an IRC operator (/oper needs the BBS system password, from the VPS itself): logged in without a password
                self.logged_in.add(nick.lower())
                self.signon.pop(nick.lower(), None)
                self.irc.raw("WHOIS " + nick)
                print("AuraBot: %s logged in (IRC operator)" % nick.lower(), flush=True)
                if text:
                    self.handle(nick, text)
            elif text:
                self.irc.tell(nick, "Log in first: login <password> (IRC operators are logged in by themselves)")

    def check_oper(self, nick):
        """Someone joined one of our channels: if they are an IRC operator, log them in (no command, no message)."""
        n = nick.lower()
        if n != NICK.lower() and n not in self.logged_in and n not in self.asking:
            self.asking[n] = [None, False]
            self.irc.raw("WHOIS " + nick)

    def forget(self, nicks):
        changed = False
        for n in nicks:
            if n in self.logged_in:
                self.logged_in.discard(n)
                self.signon.pop(n, None)
                changed = True
                print("AuraBot: %s logged out (left, quit or renamed)" % n, flush=True)
            self.pending_ban.pop(n, None)
        if changed:
            self.save()

    def handle(self, nick, text):
        n, text = nick.lower(), text.strip()
        word = text.split(" ", 1)[0].lower()
        if word == "login":
            return self.login(nick, text[6:])
        if n not in self.logged_in:
            if text.startswith("!") and n not in self.asking:
                self.asking[n] = [text, False]                  # is this an IRC operator? WHOIS says (313)
                self.irc.raw("WHOIS " + nick)
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
            self.signon.pop(n, None)
            self.irc.raw("WHOIS " + nick)          # its sign-on time, so the login survives an AuraBot restart
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
        self.forget([nick.lower()])
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
        log_action(k, nick, "kick", hit[1], "kicked by an admin")
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
        def do():
            rcon(k, 'sm_ban #%s 0 "banned by an admin"' % hit[0])
            log_action(k, nick, "ban", hit[1], "banned by an admin")
            print("AuraBot: ban on %s" % k, flush=True)
            self.irc.tell(nick, "Banned %s from %s." % (hit[1], ADMIN[k]["label"]))
        self.ask(nick, "Permanently ban %s from %s?" % (hit[1], ADMIN[k]["label"]), do)

    def ask(self, nick, question, do):
        self.pending_ban[nick.lower()] = (do, time.time())
        self.irc.tell(nick, question + " Type !yes within 30 seconds.")

    def c_yes(self, nick, rest):
        p = self.pending_ban.pop(nick.lower(), None)
        if not p or time.time() - p[1] > 30:
            return self.irc.tell(nick, "Nothing waiting for a yes.")
        p[0]()

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


    # ----- the server itself (systemctl through the sudo rules) -----
    def service(self, nick, rest, verb, past, question=None):
        k = self.server(nick, rest.split(" ")[0])
        if not k:
            return
        s = ADMIN[k]

        def do():
            if verb in ("start", "enable") and mem_free_mb() < 900:
                return self.irc.tell(nick, "Only %d MB of memory is free, not starting (pause something first)." % mem_free_mb())
            args = {"start": ["start"], "stop": ["stop"], "restart": ["restart"], "pause": ["disable", "--now"],
                    "enable": ["enable", "--now"]}[verb]
            self.irc.tell(nick, "Working...")
            ok, err = sudo(*args, s["service"])
            print("AuraBot: %s %s: %s" % (verb, k, "ok" if ok else "failed"), flush=True)
            self.irc.tell(nick, "%s %s." % (past.capitalize(), s["label"]) if ok else "Didn't work: %s" % err)
        if question:
            self.ask(nick, question % s["label"], do)
        else:
            do()

    def c_start(self, nick, rest):
        self.service(nick, rest, "start", "started")

    def c_stop(self, nick, rest):
        self.service(nick, rest, "stop", "stopped", "Stop %s? (It starts again on a VPS reboot.)")

    def c_restart(self, nick, rest):
        self.service(nick, rest, "restart", "restarted", "Restart %s? Players will be dropped.")

    def c_pause(self, nick, rest):
        self.service(nick, rest, "pause", "paused", "Pause %s? It stays off, even after reboots, until !resume.")

    def c_resume(self, nick, rest):
        self.service(nick, rest, "enable", "resumed")

    # ----- game settings -----
    def c_campaign(self, nick, rest):
        word, _, name = rest.partition(" ")
        k = self.server(nick, word)
        if not k:
            return
        key = re.sub(r"[^a-z]", "", name.lower())
        c = CAMPAIGNS.get(key[3:] if key.startswith("the") else key)
        if ADMIN[k]["game"] != "l4d" or not c:
            return self.irc.tell(nick, "!campaign <classic|vs|vintage> <" + "|".join(CAMPAIGNS) + ">")
        rcon(k, "changelevel " + ("l4d_vs_" if ADMIN[k].get("vs") else "l4d_") + c[1])
        self.irc.tell(nick, "Starting %s on %s." % (c[0], ADMIN[k]["label"]))

    def c_difficulty(self, nick, rest):
        word, _, level = rest.partition(" ")
        k = self.server(nick, word)
        if not k:
            return
        level = level.strip().capitalize()
        if ADMIN[k]["game"] != "l4d" or level not in DIFFICULTIES:
            return self.irc.tell(nick, "!difficulty <classic|vs|vintage> <easy|normal|hard|impossible>")
        rcon(k, "z_difficulty " + level)
        self.irc.tell(nick, "%s is on %s (this game only)." % (ADMIN[k]["label"], level))

    def c_bots(self, nick, rest):
        n = rest.split(" ")[-1]
        if not n.isdigit() or int(n) > 24:
            return self.irc.tell(nick, "!bots <0-24>")
        rcon("tf2", "tf_bot_quota %d" % int(n))
        if int(n) == 0:
            rcon("tf2", "tf_bot_kick all")
        self.irc.tell(nick, "TF2 bots set to %d (until the next restart)." % int(n))

    def c_scramble(self, nick, rest):
        rcon("tf2", "mp_scrambleteams 1")
        self.irc.tell(nick, "Scrambled the TF2 teams.")

    # ----- looking things up -----
    def c_health(self, nick, rest):
        du = shutil.disk_usage("/")
        load = " ".join(open("/proc/loadavg").read().split()[:3])
        up = float(open("/proc/uptime").read().split()[0]) / 86400
        self.irc.tell(nick, "Memory free: %d MB · Disk: %d GB free of %d GB · Load: %s · VPS up %.1f days"
                      % (mem_free_mb(), du.free // 2**30, du.total // 2**30, load, up))
        self.irc.tell(nick, ", ".join("%s %s" % (s["label"], "on" if is_active(s["service"]) else "off") for s in ADMIN.values()))

    def c_history(self, nick, rest):
        with db() as c:
            rows = c.execute("SELECT at, server, by, what, target FROM actions ORDER BY at DESC LIMIT 10").fetchall()
        names = {v: ADMIN[k]["label"] for k, v in DB_KEY.items()}
        for at, sv, by, what, target in rows or []:
            self.irc.tell(nick, "%s: %s %s %s on %s" % (ago(at), by, what, target, names.get(sv, sv)))
        if not rows:
            self.irc.tell(nick, "Nothing logged yet.")

    def c_seen(self, nick, rest):
        word, _, name = rest.partition(" ")
        k = self.server(nick, word)
        if not k:
            return
        if not name.strip():
            return self.irc.tell(nick, "!seen <server> <part of a name>")
        with db() as c:
            rows = c.execute("SELECT name, seconds, last_seen FROM playtime WHERE server=? AND name LIKE ? ORDER BY last_seen DESC LIMIT 5",
                             (DB_KEY[k], "%" + name.strip().replace("%", "").replace("_", "") + "%")).fetchall()
        for n, sec, ls in rows:
            self.irc.tell(nick, "%s: last seen %s, %.1f hours total" % (n, ago(ls), sec / 3600))
        if not rows:
            self.irc.tell(nick, "Nobody by that name on %s yet." % ADMIN[k]["label"])


# ---------- background jobs (were the Discord bot's) ----------
CHAN = {"tf2": "#tf2-freezetag", "classic": "#l4d-classic", "vs": "#l4d-vs", "vintage": "#l4d-vintage"}


def record_players(key, names, seconds, sample):
    now = int(time.time())
    with db() as c:
        for n in names:
            c.execute("INSERT INTO playtime VALUES (?,?,?,?) ON CONFLICT(server,name) DO UPDATE SET seconds=seconds+?, last_seen=?",
                      (DB_KEY[key], n, seconds, now, seconds, now))
        if sample:
            c.execute("INSERT INTO samples VALUES (?,?,?)", (now, DB_KEY[key], len(names)))


class Watcher(threading.Thread):
    """Every 30 s: who is on (playtime), announcements, server up/down, memory/disk, backups, the weekly post.
    Runs in its own thread so slow servers never hold up the feeds; posts go through self.out to the main loop."""
    def __init__(self):
        super().__init__(daemon=True)
        self.out = queue.Queue()
        self.state, self.last_sample, self.last_ad, self.last_line, self.last_alert = {}, {}, {}, {}, {}
        self.last_backup = None

    def say(self, chan, text):
        self.out.put(("say", chan, text))

    def topic(self, key, names, info):
        """The channel topic: the server's status (map, players), like the Discord status message was."""
        s = ADMIN[key]
        if names is None:
            text = "%s · offline" % s["label"]
        else:
            who = ", ".join(n for _, n in names[:6]) + (" +%d" % (len(names) - 6) if len(names) > 6 else "")
            text = "%s · %s · %s" % (s["label"], info.get("map") or "?",
                                     ("%d playing: %s" % (len(names), who)) if names else "nobody on")
        self.out.put(("topic", CHAN[key], text[:300]))

    def advert(self, key, humans):
        """One random line from announcements-<server>.txt into that server's chat every 65 minutes, only while someone is on."""
        now = time.time()
        last = self.last_ad.setdefault(key, now)    # first sight: start the clock, not right after a restart
        if humans == 0 or now - last < AD_EVERY:
            return
        try:
            lines = [l.strip() for l in open(os.path.join(HERE, "announcements-%s.txt" % DB_KEY[key]), encoding="utf-8")
                     if l.strip() and not l.startswith("//")]
        except OSError:
            return
        if lines:
            pick = random.choice([l for l in lines if l != self.last_line.get(key)] or lines)
            self.last_line[key], self.last_ad[key] = pick, now
            rcon(key, 'say "[88x31] %s"' % safe_text(pick, 200))

    def weekly(self, now):
        """Sunday 18:00+ (VPS time): each server's 7-day totals, once a week (a marker file keeps it to one post)."""
        t = datetime.datetime.fromtimestamp(now)
        if t.weekday() != 6 or t.hour < 18:
            return
        week = t.strftime("%G-W%V")
        marker = os.path.join(HERE, "weekly-posted.txt")
        try:
            done = open(marker).read().split()
        except OSError:
            done = []
        for key, s in ADMIN.items():
            if "%s:%s" % (week, key) in done:
                continue
            try:
                spec = importlib.util.spec_from_file_location("lb", os.path.join(HERE, "leaderboard.py"))
                lb = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(lb)
                rows, people = lb.week_summary(LB_KIND[key], s["logs"], LB_IGNORE)
            except Exception as e:
                print("AuraBot: weekly error %s %s" % (key, type(e).__name__), flush=True)
                continue
            done.append("%s:%s" % (week, key))
            with open(marker, "w") as f:
                f.write("\n".join(done[-40:]))
            if people:
                self.say(CHAN[key], "%s%s, this past week%s (%d players)" % (B, s["label"], B, people))
                for n, v in rows:
                    self.say(CHAN[key], "%s: %s%s%s" % (n, B, format(v, ","), B))

    def tick(self):
        for key, s in ADMIN.items():
            try:
                names, info = players(key)
                up = True
            except Exception:
                names, info, up = None, {}, False
            if names is not None:
                now = time.time()
                sample = now - self.last_sample.get(key, 0) >= 300
                try:
                    record_players(key, [n for _, n in names], 30, sample)
                    if sample:
                        self.last_sample[key] = now
                except Exception as e:
                    print("AuraBot: db error %s" % type(e).__name__, flush=True)
                try:
                    self.advert(key, len(names))
                except Exception as e:
                    print("AuraBot: announcement error %s" % type(e).__name__, flush=True)
            st = self.state.setdefault(key, {"up": None, "fails": 0})
            st["fails"] = 0 if up else st["fails"] + 1
            if up or st["fails"] >= 3:
                self.topic(key, names, info)
            if up and st["up"] is False:
                self.say(CHAN[key], I + "%s is back online" % s["label"] + I)
            if st["up"] is None:
                st["up"] = up
            elif up:
                st["up"] = True
            elif st["fails"] >= 3 and st["up"]:           # 90 s of silence, so restarts don't spam
                st["up"] = False
                why = "stopped" if not is_active(s["service"]) else "not answering"
                self.say(CHAN[key], I + "%s went offline (%s)" % (s["label"], why) + I)
        now = time.time()
        du = shutil.disk_usage("/")
        if mem_free_mb() < 300 and now - self.last_alert.get("mem", 0) > 6 * 3600:
            self.last_alert["mem"] = now
            self.say(ALERT_CHANNEL, I + "the VPS is low on memory (%d MB free)" % mem_free_mb() + I)
        if du.used / du.total > 0.90 and now - self.last_alert.get("disk", 0) > 6 * 3600:
            self.last_alert["disk"] = now
            self.say(ALERT_CHANNEL, I + "the VPS disk is %d%% full" % (100 * du.used / du.total) + I)
        self.weekly(now)
        out = subprocess.run(["systemctl", "show", "vps-backup.service", "-p", "Result", "-p", "ExecMainExitTimestamp"],
                             capture_output=True, text=True).stdout
        kv = dict(l.split("=", 1) for l in out.splitlines() if "=" in l)
        stamp = kv.get("ExecMainExitTimestamp", "")
        if stamp and stamp != self.last_backup:
            first = self.last_backup is None
            self.last_backup = stamp
            if not first:
                self.say(ALERT_CHANNEL, I + "the backup finished: %s" % ("ok" if kv.get("Result") == "success" else "FAILED (%s)" % kv.get("Result")) + I)

    def run(self):
        while True:
            try:
                self.tick()
            except Exception as e:
                print("AuraBot: watch error %s" % type(e).__name__, flush=True)
            time.sleep(30)


class Topics:
    """Keeps each server channel's topic set to the server's status. Setting a topic needs @ in the channel:
    AuraBot gets it by being first into the channel after the IRC server restarts (it reconnects within seconds),
    or from an op (/op AuraBot); alone in a channel without @, it leaves and rejoins to get it. Otherwise it tells a
    logged-in admin once. With it, logged-in admins get @ too."""
    def __init__(self, irc, admin):
        self.irc, self.admin = irc, admin
        self.reset()

    def reset(self):
        self.want, self.have, self.sent, self.asked = {}, {}, {}, set()

    def seen(self, prefix, cmd, args):
        if cmd == "332" and len(args) >= 3:                       # topic on join
            self.have[args[1].lower()] = args[2]
        elif cmd == "TOPIC" and len(args) >= 2:
            self.have[args[0].lower()] = args[1]

    def sync(self):
        now = time.time()
        for chan, text in self.want.items():
            if not self.irc.is_op(chan):
                if self.irc.members.get(chan, set()) <= {NICK.lower()} and now - self.sent.get("cycle" + chan, 0) > 120:
                    self.irc.raw("PART %s" % chan)    # alone without @: leave and come back, the first one in gets @
                    self.irc.raw("JOIN %s" % chan)
                    self.sent["cycle" + chan] = now
                    continue
                if chan not in self.asked:
                    for n in self.admin.logged_in:
                        if n in self.irc.members.get(chan, set()):
                            self.irc.tell(n, "I need @ in %s to keep its topic up to date: /op %s there." % (chan, NICK))
                            self.asked.add(chan)
                continue
            if self.have.get(chan) != text and now - self.sent.get(chan, 0) > 20:
                self.irc.raw("TOPIC %s :%s" % (chan, text))
                self.sent[chan] = now
            for n in self.admin.logged_in:                        # admins in the channel get @ too
                if n in self.irc.members.get(chan, set()) and not self.irc.is_op(chan, n) and now - self.sent.get(chan + n, 0) > 60:
                    self.irc.raw("MODE %s +o %s" % (chan, n))
                    self.sent[chan + n] = now


def main():
    global ADMIN_DS
    spec = importlib.util.spec_from_file_location("ds", os.path.join(HERE, "discord-status.py"))
    ADMIN_DS = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ADMIN_DS)
    feeds = [Feed(*s) for s in SERVERS]
    watcher = Watcher()
    watcher.start()
    irc = Irc()
    admin = Admin(irc)
    topics = Topics(irc, admin)
    last_report, posted = time.time(), 0
    while True:
        try:
            irc.connect([fd.chan for fd in feeds])
            admin.restore()
            topics.reset()
            print("AuraBot: connected", flush=True)
            while True:
                for fd in feeds:
                    for item in fd.poll():
                        lines = card_lines(item) if isinstance(item, dict) else [ircify(item)]
                        for l in lines:
                            irc.say(fd.chan, l)
                            posted += 1
                while not watcher.out.empty():               # the background jobs' posts and wanted topics
                    kind, chan, text = watcher.out.get()
                    if kind == "say":
                        irc.say(chan, text)
                    else:
                        topics.want[chan.lower()] = text
                topics.sync()
                if len(irc.queue) > 60:                     # far behind: drop the oldest
                    dropped = len(irc.queue) - 40
                    irc.queue = irc.queue[dropped:]
                    print("AuraBot: dropped %d queued lines (busy)" % dropped, flush=True)
                for prefix, cmd, args in irc.pump():
                    admin.forget(irc.track(prefix, cmd, args))
                    admin.whois_reply(cmd, args)
                    topics.seen(prefix, cmd, args)
                    if cmd == "JOIN" and "!" in prefix:          # an IRC operator joining is logged in (and gets @)
                        admin.check_oper(prefix.split("!")[0])
                    if cmd == "001":                        # Irc.pump has just sent JOIN; WHOIS answers come after the NAMES
                        admin.check_saved()
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
            print("AuraBot: %s; reconnecting in 3 s" % e, flush=True)
            try:
                irc.sock.close()
            except Exception:
                pass
            irc.queue, irc.urgent = [], []
            time.sleep(3)                    # back quickly: the first one into an empty channel gets its @


if __name__ == "__main__":
    sys.exit(main())
