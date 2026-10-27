#!/usr/bin/env bash
# Sets up a second Left 4 Dead (1) server "l4db" next to the first one: its own folder /home/tf2/l4d-b, its own
# service (screen "l4db"), game port 27017, starting in versus. It is a copy of the first server, so it has the same
# SourceMod, plugins, admins and settings (the admin menu can switch it between co-op and versus).
# The big read-only game files (4 MB and up) are hard links to the first server's files, so they take no extra disk.
# Everything small is a real copy, and logs are left out, so the two servers never write to the same file.
# Run as root. Does NOT start the server and does not touch the first one. Safe to re-run: an existing copy is kept
# and only the service file is rewritten.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SRC=/home/tf2/l4d
DST=/home/tf2/l4d-b
PORT=27017
NAME="${L4DB_HOSTNAME:-~*~88x31~*~ L4D VeRsUs SeRveR}"
START_MAP=l4d_vs_hospital01_apartment
UNIT_SRC=/etc/systemd/system/l4d.service
UNIT=/etc/systemd/system/l4db.service

[ -d "$SRC/left4dead" ] || { echo "No $SRC yet. Run l4d-setup first."; exit 1; }
[ -f "$UNIT_SRC" ] || { echo "No $UNIT_SRC."; exit 1; }

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
  printf 'hostname "%s"\nmp_gamemode versus\n' "$NAME" >> "$C"
  chown tf2:tf2 "$C"
  echo "df after:"; df -h /home | tail -n 1
fi

echo "== systemd service =="
sed -E \
  -e 's#/home/tf2/l4d([/ "]|$)#/home/tf2/l4d-b\1#g' \
  -e 's/-DmS l4d /-DmS l4db /' \
  -e "s/-port [0-9]+/-port $PORT/" \
  -e 's/ \+mp_gamemode [a-z]+//' \
  -e "s/ \+map [^ ]+/ +mp_gamemode versus +map $START_MAP/" \
  -e "s#\+hostname .*\$#+hostname \"$NAME\"#" \
  -e 's/^Description=.*/Description=Left 4 Dead server B/' \
  -e 's/^MemoryMax=.*/MemoryMax=1200M/' \
  "$UNIT_SRC" > "$UNIT"
systemctl daemon-reload
systemctl enable l4db >/dev/null 2>&1
grep -E '^(ExecStart|WorkingDirectory|MemoryMax)=' "$UNIT" | cut -c1-300
echo "Done. Not started: run l4db-start (it refuses if less than 900 MB of memory is free; tf2-pause frees about 700 MB). Game port $PORT/udp."
