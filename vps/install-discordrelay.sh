#!/usr/bin/env bash
# RETIRED (Oct 29, 2026): replaced by AuraBot on IRC (vps/aurabot.py). Stopped and disabled on the VPS;
# re-running this would turn it back on.
# Installs the chat relay plugin sp-discordrelay (log-ical) on the TF2 server, plus the three things it needs:
#   ripext (REST extension), SteamWorks (extension), SMJansson (JSON extension, needed by discord-api),
#   discord-api (plugin, Cruze03/sourcemod-discord).
# Everything is downloaded and checked in /root/relay-stage first. If any piece is missing the script stops
# and changes nothing on the game server. It does NOT restart the server and does NOT touch any settings.
# Run as root. Re-running is safe. Optional argument: the game folder (default: the TF2 server's tf folder).
#
# After the server restarts once, the plugin writes <game folder>/cfg/sourcemod/discordrelay.cfg.
# The webhook link (and later the bot token) are typed in there by the server owner, never stored in the repo.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
T=${1:-/home/tf2/server/tf}   # the game folder; the L4D1 server is /home/tf2/l4d/left4dead
S=/root/relay-stage
rm -rf "$S"; mkdir -p "$S"; cd "$S"

pick() {  # pick OWNER/REPO REGEX [PREFER] -> prints the URL of the matching release asset (PREFER wins if several match)
  curl -fsSL -H 'User-Agent: 88x31-installer' "https://api.github.com/repos/$1/releases/latest" | python3 -c '
import sys, json, re
d = json.load(sys.stdin)
names = [a["name"] for a in d.get("assets", [])]
sys.stderr.write("  assets of %s: %s\n" % (sys.argv[3], ", ".join(names)))
ok = [a for a in d.get("assets", []) if re.search(sys.argv[1], a["name"]) and not re.search(r"64|x86_64|windows|mac|win", a["name"], re.I)]
pref = [a for a in ok if sys.argv[2] and re.search(sys.argv[2], a["name"])]
for a in (pref or ok)[:1]:
    print(a["browser_download_url"])
' "$2" "${3:-}" "$1"
}

fetch_zip() {  # fetch_zip NAME URL
  echo "  $1: $2"
  curl -fsSL "$2" -o "$1.pkg"
  mkdir -p "$1"
  python3 - "$1" <<'PY'
import sys, zipfile, tarfile, io
n = sys.argv[1]
p = n + ".pkg"
if zipfile.is_zipfile(p):
    zipfile.ZipFile(p).extractall(n)
else:
    tarfile.open(p).extractall(n)
PY
}

echo "== finding downloads =="
RIP=$(pick ErikMinekus/sm-ripext 'linux' || true)
STW=$(pick hexa-core-eu/SteamWorks 'linux' || true)
SMJ=$(pick srcdslab/sm-ext-SMJansson 'ubuntu' 'sm-1\.12' || true)
[ -n "$RIP" ] || { echo "STOP: no ripext Linux download found. Nothing changed."; exit 1; }
[ -n "$STW" ] || { echo "STOP: no SteamWorks Linux download found. Nothing changed."; exit 1; }
[ -n "$SMJ" ] || { echo "STOP: no SMJansson Linux download found. Nothing changed."; exit 1; }
fetch_zip ripext "$RIP"
fetch_zip steamworks "$STW"
fetch_zip smjansson "$SMJ"

echo "  discord-api: source archive of Cruze03/sourcemod-discord"
curl -fsSL https://codeload.github.com/Cruze03/sourcemod-discord/tar.gz/HEAD -o discord.tgz
mkdir discord && tar xzf discord.tgz -C discord --strip-components=1
DAPI=$(find discord -name 'discord_api.smx' | head -1)
[ -n "$DAPI" ] || { echo "STOP: discord_api.smx is not in that repo. Nothing changed."; exit 1; }

echo "  discordrelay.smx: from log-ical/sp-discordrelay"
curl -fsSL https://raw.githubusercontent.com/log-ical/sp-discordrelay/master/plugins/discordrelay.smx -o discordrelay.smx

RIPEXT=$(find ripext -name '*.ext.so' ! -path '*/x64/*' | head -1)
STWEXT=$(find steamworks -name 'SteamWorks.ext.so' ! -path '*/x64/*' | head -1)
SMJEXT=$(find smjansson -name 'smjansson.ext.so' ! -path '*/x64/*' | head -1)
[ -n "$SMJEXT" ] || { echo "STOP: no smjansson.ext.so inside the SMJansson package. Nothing changed."; exit 1; }
[ -n "$RIPEXT" ] || { echo "STOP: no .ext.so inside the ripext package. Nothing changed."; exit 1; }
[ -n "$STWEXT" ] || { echo "STOP: no SteamWorks.ext.so inside the SteamWorks package. Nothing changed."; exit 1; }
# the TF2 server here is 32-bit (srcds_linux), so both extensions must be 32-bit too
for x in "$RIPEXT" "$STWEXT" "$SMJEXT"; do
  file "$x" | grep -q '32-bit' || { echo "STOP: $x is not a 32-bit build. Nothing changed."; exit 1; }
done
echo "  32-bit builds: $RIPEXT, $STWEXT, $SMJEXT"

echo "== installing =="
EXT=$T/addons/sourcemod/extensions; PLG=$T/addons/sourcemod/plugins
install -o tf2 -g tf2 -m 755 "$RIPEXT" "$EXT/$(basename "$RIPEXT")"
install -o tf2 -g tf2 -m 755 "$STWEXT" "$EXT/SteamWorks.ext.so"
install -o tf2 -g tf2 -m 755 "$SMJEXT" "$EXT/smjansson.ext.so"
for a in ripext steamworks smjansson; do   # autoload files, if the packages have them
  find "$a" -name '*.autoload' -exec sh -c 'install -o tf2 -g tf2 -m 644 "$1" "$2/$(basename "$1")"' _ {} "$EXT" \;
done
install -o tf2 -g tf2 -m 644 "$DAPI" "$PLG/discord_api.smx"
install -o tf2 -g tf2 -m 644 discordrelay.smx "$PLG/discordrelay.smx"
ls -l "$EXT" | grep -i -E 'rip|steamworks|jansson' | awk '{print $5, $NF}'
ls -l "$PLG" | grep -i discord | awk '{print $5, $NF}'
echo "Installed. The game server was not restarted; restart it to load them."
