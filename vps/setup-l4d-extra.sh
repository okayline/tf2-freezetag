#!/usr/bin/env bash
# Sets up one more Left 4 Dead (1) server next to the first one, as a copy of it: its own folder /home/tf2/l4d-LETTER,
# its own service "l4dLETTER" (screen "l4dLETTER") and game port. Same SourceMod, plugins, admins and settings as the first.
# The big read-only game files (4 MB and up) are hard links to the first server's files, so they take no extra disk; everything
# small is a real copy and logs are left out, so the servers never write to the same file. Does NOT start the server and does
# not touch any other server. Safe to re-run: an existing copy is kept and only the service file is rewritten.
#   usage: setup-l4d-extra.sh LETTER PORT MODE START_MAP "SERVER NAME"      (example: c 27018 coop l4d_hospital01_apartment "~*~88x31~*~ L4D cLaSSiC 2")
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
[ $# -eq 5 ] || { sed -n '9p' "$0"; exit 1; }
LETTER=$1; PORT=$2; MODE=$3; START_MAP=$4; NAME=$5
printf '%s' "$LETTER" | grep -Eq '^[c-z]$' || { echo "LETTER must be one lowercase letter from c to z (a and b are taken)."; exit 1; }
printf '%s' "$PORT" | grep -Eq '^270[0-9]{2}$' || { echo "PORT must look like 27018."; exit 1; }
[ "$MODE" = coop ] || [ "$MODE" = versus ] || { echo "MODE must be coop or versus."; exit 1; }
printf '%s' "$START_MAP" | grep -Eq '^l4d_[a-z0-9_]+$' || { echo "START_MAP must look like l4d_hospital01_apartment."; exit 1; }
printf '%s' "$NAME" | grep -Eq '^[A-Za-z0-9 ~*._-]{3,60}$' || { echo "NAME may only use letters, digits, space and ~ * . _ -"; exit 1; }

SRC=/home/tf2/l4d
DST=/home/tf2/l4d-$LETTER
SVC=l4d$LETTER
UNIT_SRC=/etc/systemd/system/l4d.service
UNIT=/etc/systemd/system/$SVC.service

[ -d "$SRC/left4dead" ] || { echo "No $SRC yet. Run l4d-setup first."; exit 1; }
[ -f "$UNIT_SRC" ] || { echo "No $UNIT_SRC."; exit 1; }
if ss -lun | grep -q ":$PORT "; then
  [ -d "$DST/left4dead" ] || { echo "Port $PORT is already in use."; exit 1; }
fi

if [ -d "$DST/left4dead" ]; then
  echo "== $DST already exists, keeping it =="
else
  FREE=$(df --output=avail -BG /home | tail -n 1 | tr -dc '0-9')
  echo "free disk: ${FREE} GB"
  [ "$FREE" -ge 4 ] || { echo "Less than 4 GB free, stopping."; exit 1; }
  command -v rsync >/dev/null || { apt-get update -qq >/dev/null 2>&1; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq rsync >/dev/null; }
  echo "== copying the game (big files linked, small files copied) =="
  EX=(--exclude='/left4dead/logs/' --exclude='/left4dead/addons/sourcemod/logs/' --exclude='/off/' --exclude='*.log' --exclude='*.dem')
  mkdir -p "$DST"
  rsync -a --min-size=4M --link-dest="$SRC/" "${EX[@]}" "$SRC/" "$DST/"
  rsync -a --max-size=4M "${EX[@]}" "$SRC/" "$DST/"
  mkdir -p "$DST/left4dead/logs" "$DST/left4dead/addons/sourcemod/logs"
  chown -R tf2:tf2 "$DST"
  G=$DST/left4dead
  # the Discord chat relay and its webhook belong to the first server only
  rm -f "$G/addons/sourcemod/plugins/discordrelay.smx" "$G/addons/sourcemod/plugins/discord_api.smx" "$G/cfg/sourcemod/discordrelay.cfg"
  C=$G/cfg/server.cfg
  touch "$C"
  sed -i '/^hostname /d; /^mp_gamemode /d' "$C"
  printf 'hostname "%s"\nmp_gamemode %s\n' "$NAME" "$MODE" >> "$C"
  chown tf2:tf2 "$C"
  # the welcome screen is a copy of the first server's: give it this server's name
  [ -f "$G/motd.txt" ] && sed -i "s|<h2>[^<]*</h2>|<h2>$NAME</h2>|; s|<!--LEADERBOARD-->||" "$G/motd.txt"
  echo "df after:"; df -h /home | tail -n 1
fi

echo "== systemd service =="
sed -E \
  -e "s#/home/tf2/l4d([/ \"]|\$)#/home/tf2/l4d-$LETTER\\1#g" \
  -e "s/-DmS l4d /-DmS $SVC /" \
  -e "s/-port [0-9]+/-port $PORT/" \
  -e 's/ \+mp_gamemode [a-z]+//' \
  -e "s/ \+map [^ ]+/ +mp_gamemode $MODE +map $START_MAP/" \
  -e "s#\+hostname .*\$#+hostname \"$NAME\"#" \
  -e "s/^Description=.*/Description=Left 4 Dead server $LETTER/" \
  -e 's/^MemoryMax=.*/MemoryMax=1200M/' \
  "$UNIT_SRC" > "$UNIT"
systemctl daemon-reload
systemctl enable "$SVC" >/dev/null 2>&1
grep -E '^(ExecStart|WorkingDirectory|MemoryMax)=' "$UNIT" | cut -c1-300
echo "Done. Not started: run $SVC-start (it refuses if less than 900 MB of memory is free). Game port $PORT/udp."
