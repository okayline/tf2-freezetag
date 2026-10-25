#!/usr/bin/env bash
# Installs the chat relay plugin sp-discordrelay (log-ical) on the TF2 server, plus the three things it needs:
#   ripext (REST extension), SteamWorks (extension), discord-api (plugin, Cruze03/sourcemod-discord).
# Everything is downloaded and checked in /root/relay-stage first. If any piece is missing the script stops
# and changes nothing on the game server. It does NOT restart the server and does NOT touch any settings.
# Run as root. Re-running is safe.
#
# After the server restarts once, the plugin writes /home/tf2/server/tf/cfg/sourcemod/discordrelay.cfg.
# The webhook link (and later the bot token) are typed in there by the server owner, never stored in the repo.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
T=/home/tf2/server/tf
S=/root/relay-stage
rm -rf "$S"; mkdir -p "$S"; cd "$S"

pick() {  # pick OWNER/REPO REGEX -> prints the download URL of the first release asset whose name matches
  curl -fsSL -H 'User-Agent: 88x31-installer' "https://api.github.com/repos/$1/releases/latest" | python3 -c '
import sys, json, re
d = json.load(sys.stdin)
for a in d.get("assets", []):
    if re.search(sys.argv[1], a["name"]) and not re.search(r"64|x86_64|windows|mac", a["name"], re.I):
        print(a["browser_download_url"]); break
' "$2"
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
[ -n "$RIP" ] || { echo "STOP: no ripext Linux download found. Nothing changed."; exit 1; }
[ -n "$STW" ] || { echo "STOP: no SteamWorks Linux download found. Nothing changed."; exit 1; }
fetch_zip ripext "$RIP"
fetch_zip steamworks "$STW"

echo "  discord-api: source archive of Cruze03/sourcemod-discord"
curl -fsSL https://codeload.github.com/Cruze03/sourcemod-discord/tar.gz/HEAD -o discord.tgz
mkdir discord && tar xzf discord.tgz -C discord --strip-components=1
DAPI=$(find discord -name 'discord_api.smx' | head -1)
[ -n "$DAPI" ] || { echo "STOP: discord_api.smx is not in that repo. Nothing changed."; exit 1; }

echo "  discordrelay.smx: from log-ical/sp-discordrelay"
curl -fsSL https://raw.githubusercontent.com/log-ical/sp-discordrelay/master/plugins/discordrelay.smx -o discordrelay.smx

RIPEXT=$(find ripext -name '*.ext.so' | head -1)
STWEXT=$(find steamworks -name 'SteamWorks.ext.so' | head -1)
[ -n "$RIPEXT" ] || { echo "STOP: no .ext.so inside the ripext package. Nothing changed."; exit 1; }
[ -n "$STWEXT" ] || { echo "STOP: no SteamWorks.ext.so inside the SteamWorks package. Nothing changed."; exit 1; }
file "$RIPEXT" "$STWEXT" 2>/dev/null | sed 's/, BuildID.*//' || true

echo "== installing =="
EXT=$T/addons/sourcemod/extensions; PLG=$T/addons/sourcemod/plugins
install -o tf2 -g tf2 -m 755 "$RIPEXT" "$EXT/$(basename "$RIPEXT")"
install -o tf2 -g tf2 -m 755 "$STWEXT" "$EXT/SteamWorks.ext.so"
for a in ripext steamworks; do   # autoload files, if the packages have them
  find "$a" -name '*.autoload' -exec sh -c 'install -o tf2 -g tf2 -m 644 "$1" "$2/$(basename "$1")"' _ {} "$EXT" \;
done
install -o tf2 -g tf2 -m 644 "$DAPI" "$PLG/discord_api.smx"
install -o tf2 -g tf2 -m 644 discordrelay.smx "$PLG/discordrelay.smx"
ls -l "$EXT" | grep -i -E 'rip|steamworks' | awk '{print $5, $NF}'
ls -l "$PLG" | grep -i discord | awk '{print $5, $NF}'
echo "Installed. The game server was not restarted; restart it to load them."
