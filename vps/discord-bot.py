#!/usr/bin/env python3
"""88x31 Discord control bot: slash commands for the TF2 and L4D servers, plus its own posts.

Runs on the VPS as user tf2 (service "discord-bot", see discord-bot-setup.sh). Needs python3-discord (discord.py).
- Token: /home/tf2/discord/bot.token (never in the repo).
- Only people with the role ROLE can use any command, and only in the channels in CHANNELS.
- Servers are controlled through RCON on 127.0.0.1 (password read from each server.cfg) and
  `sudo systemctl ...` for start/stop/restart (sudoers lines written by the setup script).
- Posts are written like /me actions, in italics: *Ryan restarted cLaSSiC*.
- Never posts RCON passwords, IP addresses or Steam IDs."""
import asyncio
import datetime
import glob
import importlib.util
import os
import re
import shutil
import subprocess
import time

import discord
from discord import app_commands

ROLE = "teal"
D = "/home/tf2/discord"
CHANNELS = {"l4d-classic", "l4d-vintage", "l4d-vs", "tf2-freezetag"}
ALERT_CHANNEL = "tf2-freezetag"          # low memory / disk warnings and the nightly backup result

# key: label, game, service, rcon port, server.cfg, log folder, channel for its up/down posts
SERVERS = {
    "tf2":  dict(label="TF2 Freeze Tag", game="tf2", service="tf2", port=27015,
                 cfg="/home/tf2/server/tf/cfg/server.cfg", logs="/home/tf2/server/tf/logs", channel="tf2-freezetag"),
    "l4d":  dict(label="cLaSSiC", game="l4d", service="l4d", port=27016,
                 cfg="/home/tf2/l4d/left4dead/cfg/server.cfg", logs="/home/tf2/l4d/left4dead/logs", channel="l4d-classic"),
    "l4db": dict(label="VeRsUs", game="l4d", service="l4db", port=27017, vs=True,
                 cfg="/home/tf2/l4d-b/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-b/left4dead/logs", channel="l4d-vs"),
    "l4dc": dict(label="ViNtaGe", game="l4d", service="l4dc", port=27018,
                 cfg="/home/tf2/l4d-c/left4dead/cfg/server.cfg", logs="/home/tf2/l4d-c/left4dead/logs", channel="l4d-vintage"),
}
SERVER_CHOICES = [app_commands.Choice(name=s["label"], value=k) for k, s in SERVERS.items()]
CAMPAIGNS = {"No Mercy": "hospital01_apartment", "Crash Course": "garage01_alleys", "Death Toll": "smalltown01_caves",
             "Dead Air": "airport01_greenhouse", "Blood Harvest": "farm01_hilltop", "The Sacrifice": "river01_docks"}
DIFFICULTIES = ["Easy", "Normal", "Hard", "Impossible"]

# RCON helpers come from the status poster (same folder on the VPS).
_spec = importlib.util.spec_from_file_location("ds", os.path.join(D, "discord-status.py"))
ds = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ds)


def rcon(key, command):
    s = SERVERS[key]
    pw = ds.read_password(s["cfg"])
    if not pw:
        raise PermissionError("no rcon_password")
    return ds.rcon(s["port"], pw, command)


def players(key):
    """[(userid, name)] of humans, parsed from `status`; plus the status info."""
    text = rcon(key, "status")
    info = ds.parse(text)
    out = []
    for m in re.finditer(r'^#\s*(\d+)(?:\s+\d+)?\s+"(.*)"\s+(\[U:\S+\]|STEAM_\S+|BOT)', text, re.M):
        if m.group(3) != "BOT":
            out.append((m.group(1), m.group(2)))
    return out, info


def is_active(service):
    return subprocess.run(["systemctl", "is-active", "--quiet", service]).returncode == 0


def sudo(*args):
    r = subprocess.run(["sudo", "-n", "/usr/bin/systemctl", *args], capture_output=True, text=True, timeout=60)
    return r.returncode == 0, (r.stderr or r.stdout).strip()[-200:]


def mem_free_mb():
    for line in open("/proc/meminfo"):
        if line.startswith("MemAvailable"):
            return int(line.split()[1]) // 1024
    return 0


def esc(s):
    return re.sub(r"([\\*_`~|>@#\[\]()])", r"\\\1", s)[:40]


def me(user, text):
    return "*%s %s*" % (esc(user.display_name), text)


def safe_text(s, n=150):
    return re.sub(r'[;"\\\r\n]', " ", s)[:n].strip()


def clean_log(line):
    """One game-log line made readable: '19:46:10 text', no IPs or Steam IDs, names as "Name (Team)"."""
    m = re.match(r"L (\d+/\d+/\d+) - (\d+:\d+:\d+):\s*(.*)", line)
    if m:
        line = "%s %s" % (m.group(2), m.group(3))
    id_part = r"(?:STEAM_[0-9:]+|\[U:\d:\d+\]|BOT|Console)"
    line = re.sub(r"<\d+><%s><([^<>]*)>" % id_part, lambda g: " (%s)" % g.group(1) if g.group(1) else "", line)
    line = re.sub(r"<\d+><%s>" % id_part, "", line)
    line = re.sub(r"STEAM_\d:\d:\d+", "(id)", line)
    line = re.sub(r"\[U:\d:\d+\]", "(id)", line)
    line = re.sub(r"\d{1,3}(\.\d{1,3}){3}(:\d+)?", "(ip)", line)
    return line.replace("`", "'")


# log lines nobody wants to read: RCON checks, log file markers, bots stuck on the map, server settings and map loading
NOISE = re.compile(r'rcon from|Log file (started|closed)|path_goal|\bstuck\b|\bunstuck\b'
                   r'|server cvars (start|end)|^\S+ "[^"]+" = "[^"]*"\s*$|^L \d+/\d+/\d+ - \d+:\d+:\d+: "[^"]+" = "[^"]*"\s*$'
                   r'|NAV_MOB_ONLY|Computing Flow Distances|Preventing spawning')


class Bot(discord.Client):
    def __init__(self):
        super().__init__(intents=discord.Intents.default())
        self.tree = app_commands.CommandTree(self)
        self.state = {}        # key -> consecutive failures / last known up
        self.last_alert = {}
        self.last_backup = None

    async def setup_hook(self):
        self.loop.create_task(self.watch())

    async def on_ready(self):
        for g in self.guilds:
            self.tree.copy_global_to(guild=g)
            await self.tree.sync(guild=g)
        print("ready as", self.user, "in", [g.name for g in self.guilds], flush=True)

    def channel(self, name):
        for c in self.get_all_channels():
            if c.name == name and hasattr(c, "send"):
                return c
        return None

    async def say(self, channel_name, text):
        c = self.channel(channel_name)
        if c:
            await c.send(text, allowed_mentions=discord.AllowedMentions.none())

    async def watch(self):
        """Every 30 s: server up/down changes, low memory/disk, finished backups."""
        await self.wait_until_ready()
        while not self.is_closed():
            try:
                for key, s in SERVERS.items():
                    up = True
                    try:
                        await asyncio.to_thread(rcon, key, "status")
                    except Exception:
                        up = False
                    st = self.state.setdefault(key, {"up": None, "fails": 0})
                    st["fails"] = 0 if up else st["fails"] + 1
                    if up and st["up"] is False:
                        await self.say(s["channel"], "*%s is back online*" % s["label"])
                    if st["up"] is None:
                        st["up"] = up
                    elif up:
                        st["up"] = True
                    elif st["fails"] >= 3 and st["up"]:        # 90 s of silence, so restarts don't spam
                        st["up"] = False
                        why = "stopped" if not is_active(s["service"]) else "not answering"
                        await self.say(s["channel"], "*%s went offline (%s)*" % (s["label"], why))
                now = time.time()
                du = shutil.disk_usage("/")
                if mem_free_mb() < 300 and now - self.last_alert.get("mem", 0) > 6 * 3600:
                    self.last_alert["mem"] = now
                    await self.say(ALERT_CHANNEL, "*the VPS is low on memory (%d MB free)*" % mem_free_mb())
                if du.used / du.total > 0.90 and now - self.last_alert.get("disk", 0) > 6 * 3600:
                    self.last_alert["disk"] = now
                    await self.say(ALERT_CHANNEL, "*the VPS disk is %d%% full*" % (100 * du.used / du.total))
                out = subprocess.run(["systemctl", "show", "vps-backup.service", "-p", "Result", "-p", "ExecMainExitTimestamp"],
                                     capture_output=True, text=True).stdout
                kv = dict(l.split("=", 1) for l in out.splitlines() if "=" in l)
                stamp = kv.get("ExecMainExitTimestamp", "")
                if stamp and stamp != self.last_backup:
                    first = self.last_backup is None
                    self.last_backup = stamp
                    if not first:
                        await self.say(ALERT_CHANNEL, "*the backup finished: %s*" % ("ok" if kv.get("Result") == "success" else "FAILED (%s)" % kv.get("Result")))
            except Exception as e:
                print("watch error:", type(e).__name__, e, flush=True)
            await asyncio.sleep(30)


bot = Bot()
tree = bot.tree


@tree.error
async def on_error(interaction, error):
    if isinstance(error, app_commands.CheckFailure):
        msg = "Not allowed here (needs the %s role, in a game channel)." % ROLE
    else:
        msg = "Something went wrong: %s" % type(error).__name__
        print("command error:", repr(error), flush=True)
    if interaction.response.is_done():
        await interaction.followup.send(msg, ephemeral=True)
    else:
        await interaction.response.send_message(msg, ephemeral=True)


def allowed():
    async def check(interaction):
        ch = getattr(interaction.channel, "name", "")
        roles = [r.name.lower() for r in getattr(interaction.user, "roles", [])]
        return ch in CHANNELS and ROLE in roles
    return app_commands.check(check)


class Confirm(discord.ui.View):
    def __init__(self, user):
        super().__init__(timeout=30)
        self.user, self.ok = user, False

    async def interaction_check(self, interaction):
        return interaction.user.id == self.user.id

    @discord.ui.button(label="Confirm", style=discord.ButtonStyle.danger)
    async def yes(self, interaction, button):
        self.ok = True
        await interaction.response.edit_message(content="Confirmed.", view=None)
        self.stop()

    @discord.ui.button(label="Cancel", style=discord.ButtonStyle.secondary)
    async def no(self, interaction, button):
        await interaction.response.edit_message(content="Cancelled.", view=None)
        self.stop()


async def confirm(interaction, question):
    view = Confirm(interaction.user)
    await interaction.response.send_message(question, view=view, ephemeral=True)
    await view.wait()
    return view.ok


async def player_choices(interaction, current):
    key = getattr(interaction.namespace, "server", None)
    if key not in SERVERS:
        return []
    try:
        names = [n for _, n in (await asyncio.to_thread(players, key))[0]]
    except Exception:
        return []
    return [app_commands.Choice(name=n[:90], value=n[:90]) for n in names if current.lower() in n.lower()][:25]


S = app_commands.describe(server="Which server")
S = app_commands.choices(server=SERVER_CHOICES)


def server_cmd(name, desc):
    def deco(fn):
        fn = S(fn)
        fn = allowed()(fn)
        return tree.command(name=name, description=desc)(fn)
    return deco


@tree.command(name="status", description="Every server: online, map, players")
@allowed()
async def status(interaction: discord.Interaction):
    await interaction.response.defer()
    lines = []
    for key, s in SERVERS.items():
        try:
            _, info = await asyncio.to_thread(players, key)
            bots = ", %s bots" % info["bots"] if info["bots"] else ""
            lines.append("**%s**: online, `%s`, %s players%s" % (s["label"], info["map"], info["humans"], bots))
        except Exception:
            lines.append("**%s**: %s" % (s["label"], "stopped" if not is_active(s["service"]) else "not answering"))
    await interaction.followup.send("\n".join(lines))


@server_cmd("players", "Who is on a server")
async def players_cmd(interaction: discord.Interaction, server: str):
    await interaction.response.defer()
    try:
        names, info = await asyncio.to_thread(players, server)
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"])
    body = "\n".join("\u2022 " + esc(n) for _, n in names) or "nobody"
    await interaction.followup.send("**%s**, `%s`\n%s" % (SERVERS[server]["label"], info["map"], body))


@server_cmd("map", "Change the map")
@app_commands.describe(map="TF2 map name, like cp_gravelpit_snowy (for L4D use /campaign)")
async def map_cmd(interaction: discord.Interaction, server: str, map: str):
    if SERVERS[server]["game"] != "tf2":   # L4D map names differ between co-op and versus: /campaign picks the right one
        return await interaction.response.send_message("For L4D servers use /campaign.", ephemeral=True)
    if not re.fullmatch(r"[A-Za-z0-9_]{1,64}", map):
        return await interaction.response.send_message("That isn't a valid map name.", ephemeral=True)
    await interaction.response.defer()
    try:
        await asyncio.to_thread(rcon, server, "changelevel " + map)
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"])
    await interaction.followup.send(me(interaction.user, "changed %s to `%s`" % (SERVERS[server]["label"], map)))


@server_cmd("say", "Send a message to everyone in the game")
async def say_cmd(interaction: discord.Interaction, server: str, message: str):
    await interaction.response.defer(ephemeral=True)
    text = safe_text(message)
    try:
        await asyncio.to_thread(rcon, server, 'say "[Discord] %s: %s"' % (safe_text(interaction.user.display_name, 24), text))
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"], ephemeral=True)
    await interaction.followup.send("Sent.", ephemeral=True)
    await interaction.channel.send(me(interaction.user, "told %s: %s" % (SERVERS[server]["label"], esc(text))),
                                   allowed_mentions=discord.AllowedMentions.none())


@server_cmd("kick", "Kick a player")
@app_commands.describe(player="Pick from the live player list", reason="Shown to the player")
@app_commands.autocomplete(player=player_choices)
async def kick_cmd(interaction: discord.Interaction, server: str, player: str, reason: str = "kicked by an admin"):
    await interaction.response.defer(ephemeral=True)
    try:
        names, _ = await asyncio.to_thread(players, server)
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"], ephemeral=True)
    hits = [uid for uid, n in names if n == player]
    if len(hits) != 1:
        return await interaction.followup.send("Couldn't find exactly one player named that right now.", ephemeral=True)
    await asyncio.to_thread(rcon, server, 'kickid %s "%s"' % (hits[0], safe_text(reason, 80)))
    await interaction.followup.send("Done.", ephemeral=True)
    await interaction.channel.send(me(interaction.user, "kicked %s from %s" % (esc(player), SERVERS[server]["label"])),
                                   allowed_mentions=discord.AllowedMentions.none())


async def service_action(interaction, server, verb, past, question=None):
    s = SERVERS[server]
    if question and not await confirm(interaction, question % s["label"]):
        return
    if question:
        await interaction.followup.send("Working...", ephemeral=True)
    else:
        await interaction.response.defer(ephemeral=True)
    if verb in ("start", "enable") and mem_free_mb() < 900:
        return await interaction.followup.send("Only %d MB of memory is free, not starting (pause something first)." % mem_free_mb(), ephemeral=True)
    args = {"start": ["start"], "stop": ["stop"], "restart": ["restart"], "pause": ["disable", "--now"], "enable": ["enable", "--now"]}[verb]
    ok, err = await asyncio.to_thread(sudo, *args, s["service"])
    if not ok:
        return await interaction.followup.send("Didn't work: %s" % err, ephemeral=True)
    await interaction.followup.send("Done.", ephemeral=True)
    await interaction.channel.send(me(interaction.user, "%s %s" % (past, s["label"])), allowed_mentions=discord.AllowedMentions.none())


@server_cmd("start", "Start a server")
async def start_cmd(interaction: discord.Interaction, server: str):
    await service_action(interaction, server, "start", "started")


@server_cmd("stop", "Stop a server (it starts again on a VPS reboot)")
async def stop_cmd(interaction: discord.Interaction, server: str):
    await service_action(interaction, server, "stop", "stopped", "Stop %s?")


@server_cmd("restart", "Restart a server")
async def restart_cmd(interaction: discord.Interaction, server: str):
    await service_action(interaction, server, "restart", "restarted", "Restart %s? Players will be dropped.")


@server_cmd("pause", "Stop a server and keep it off after reboots")
async def pause_cmd(interaction: discord.Interaction, server: str):
    await service_action(interaction, server, "pause", "paused", "Pause %s? It stays off until /resume.")


@server_cmd("resume", "Undo /pause: start the server and turn it back on for reboots")
async def resume_cmd(interaction: discord.Interaction, server: str):
    await service_action(interaction, server, "enable", "resumed")


@server_cmd("restartround", "Restart the round (TF2) or the chapter (L4D)")
async def restartround_cmd(interaction: discord.Interaction, server: str):
    await interaction.response.defer()
    try:
        if SERVERS[server]["game"] == "tf2":
            await asyncio.to_thread(rcon, server, "mp_restartgame 1")
        else:
            _, info = await asyncio.to_thread(players, server)
            await asyncio.to_thread(rcon, server, "changelevel " + info["map"])
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"])
    await interaction.followup.send(me(interaction.user, "restarted the round on %s" % SERVERS[server]["label"]))


@tree.command(name="scramble", description="Scramble the teams (TF2)")
@allowed()
async def scramble_cmd(interaction: discord.Interaction):
    await interaction.response.defer()
    try:
        await asyncio.to_thread(rcon, "tf2", "mp_scrambleteams 1")
    except Exception:
        return await interaction.followup.send("TF2 isn't answering.")
    await interaction.followup.send(me(interaction.user, "scrambled the teams on TF2"))


@tree.command(name="difficulty", description="Set an L4D server's difficulty (saved for restarts)")
@allowed()
@app_commands.choices(server=[c for c in SERVER_CHOICES if c.value != "tf2"],
                      level=[app_commands.Choice(name=d, value=d) for d in DIFFICULTIES])
async def difficulty_cmd(interaction: discord.Interaction, server: str, level: str):
    await interaction.response.defer()
    if server == "tf2" or level not in DIFFICULTIES:
        return await interaction.followup.send("L4D servers only.")
    cfg = SERVERS[server]["cfg"]
    try:
        lines = [l for l in open(cfg, encoding="utf-8").read().splitlines() if not re.match(r"\s*z_difficulty\b", l)]
        lines.append('z_difficulty "%s"' % level)
        with open(cfg, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        await asyncio.to_thread(rcon, server, "z_difficulty " + level)
    except Exception as e:
        return await interaction.followup.send("Didn't work (%s)." % type(e).__name__)
    await interaction.followup.send(me(interaction.user, "set %s to %s (from the next map)" % (SERVERS[server]["label"], level)))


@tree.command(name="campaign", description="Start an L4D campaign from chapter 1")
@allowed()
@app_commands.choices(server=[c for c in SERVER_CHOICES if c.value != "tf2"],
                      campaign=[app_commands.Choice(name=n, value=n) for n in CAMPAIGNS])
async def campaign_cmd(interaction: discord.Interaction, server: str, campaign: str):
    if server == "tf2" or campaign not in CAMPAIGNS:
        return await interaction.response.send_message("L4D servers only.", ephemeral=True)
    await interaction.response.defer()
    prefix = "l4d_vs_" if SERVERS[server].get("vs") else "l4d_"
    try:
        await asyncio.to_thread(rcon, server, "changelevel " + prefix + CAMPAIGNS[campaign])
    except Exception:
        return await interaction.followup.send("%s isn't answering." % SERVERS[server]["label"])
    await interaction.followup.send(me(interaction.user, "started %s on %s" % (campaign, SERVERS[server]["label"])))


@tree.command(name="bots", description="Set the number of TF2 bots (0 = none)")
@allowed()
@app_commands.describe(count="0 to 24")
async def bots_cmd(interaction: discord.Interaction, count: app_commands.Range[int, 0, 24]):
    await interaction.response.defer()
    try:
        await asyncio.to_thread(rcon, "tf2", "tf_bot_quota %d" % count)
        if count == 0:
            await asyncio.to_thread(rcon, "tf2", "tf_bot_kick all")
    except Exception:
        return await interaction.followup.send("TF2 isn't answering.")
    await interaction.followup.send(me(interaction.user, "set TF2 bots to %d (until the next restart)" % count))


@server_cmd("logs", "Last lines of a server's log (IPs and Steam IDs removed)")
@app_commands.describe(lines="How many lines, up to 25", filter="Only lines containing this")
async def logs_cmd(interaction: discord.Interaction, server: str, lines: app_commands.Range[int, 1, 25] = 15, filter: str = ""):
    files = sorted(glob.glob(SERVERS[server]["logs"] + "/[Ll]*.log"), key=os.path.getmtime)
    if not files:
        return await interaction.response.send_message("No log file yet.", ephemeral=True)
    f = filter.lower()[:40]
    rows = []
    for path in reversed(files[-6:]):                                 # newest file first, back a few files if it is quiet
        part = []
        for raw in open(path, encoding="utf-8", errors="replace"):
            for l in re.split(r"(?=L \d+/\d+/\d+ - )", raw):      # some lines hold several records
                l = l.strip()
                if l and not NOISE.search(l) and f in l.lower():
                    part.append(clean_log(l))
        rows = part + rows
        if len(rows) >= lines:
            break
    rows = rows[-lines:]
    text = "\n".join(r[:180] for r in rows) or "(nothing yet: no game activity in the recent logs)"
    await interaction.response.send_message("```\n%s\n```" % text[-1800:], ephemeral=True)


@tree.command(name="health", description="Memory, disk, load and which servers are running")
@allowed()
async def health_cmd(interaction: discord.Interaction):
    du = shutil.disk_usage("/")
    load = open("/proc/loadavg").read().split()[:3]
    up = float(open("/proc/uptime").read().split()[0]) / 86400
    run = ", ".join("%s %s" % (s["label"], "on" if is_active(s["service"]) else "off") for s in SERVERS.values())
    await interaction.response.send_message(
        "Memory free: %d MB\nDisk: %d GB free of %d GB\nLoad: %s\nVPS up %.1f days\n%s"
        % (mem_free_mb(), du.free // 2**30, du.total // 2**30, " ".join(load), up, run))


backup = app_commands.Group(name="backup", description="The nightly pCloud backup")


@backup.command(name="now", description="Run the backup now")
@allowed()
async def backup_now(interaction: discord.Interaction):
    ok, err = await asyncio.to_thread(sudo, "start", "--no-block", "vps-backup.service")
    if not ok:
        return await interaction.response.send_message("Didn't work: %s" % err, ephemeral=True)
    await interaction.response.send_message(me(interaction.user, "started a backup (I'll post when it finishes)"))


@backup.command(name="status", description="Latest backups")
@allowed()
async def backup_status(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    r = await asyncio.to_thread(subprocess.run, ["sudo", "-n", "/usr/local/bin/vps-backup", "status"], capture_output=True, text=True, timeout=120)
    await interaction.followup.send("```\n%s\n```" % (r.stdout or r.stderr)[-1800:], ephemeral=True)


tree.add_command(backup)

if __name__ == "__main__":
    bot.run(open(os.path.join(D, "bot.token")).read().strip())
