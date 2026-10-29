#!/usr/bin/env bash
# The one way to set up or update an L4D server. Run as root on the VPS from the copy of this l4d/ folder.
#   deploy.sh <classic|versus|vintage> [clean]
# - Reads l4d/servers/<name>.conf (name, port, mode, map order, extras) and l4d/base/* (shared files).
# - "clean" first deletes the server's addons folder and SourceMod settings, so MetaMod, SourceMod and
#   l4dtoolz are installed fresh. Game files, logs, motd and admins_simple.ini are kept.
# - Never starts the server. The server must be stopped.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
KEY=${1:-}; CLEAN=${2:-}
case "$KEY" in classic|versus|vintage) ;; *) echo "usage: deploy.sh classic|versus|vintage [clean]"; exit 1;; esac
# shellcheck disable=SC1090
. "$HERE/servers/$KEY.conf"

OWNER_ID=STEAM_0:1:21624068
ROOT=/home/tf2/$DIR
G=$ROOT/left4dead
SM=$G/addons/sourcemod
CFG=$G/cfg
as_tf2() { sudo -u tf2 bash -euo pipefail -c "$1"; }

[ -d "$G" ] || { echo "No game in $ROOT."; exit 1; }
if systemctl is-active --quiet "$SERVICE"; then echo "$SERVICE is running. Stop it first."; exit 1; fi

echo "== $KEY ($NAME) =="
if [ "$CLEAN" = clean ]; then
  echo "-- clean: removing addons and SourceMod settings (admins_simple.ini is kept)"
  [ -f "$SM/configs/admins_simple.ini" ] && cp "$SM/configs/admins_simple.ini" /root/l4d-admins-$KEY.ini
  rm -rf "$G/addons" "$CFG/sourcemod"
fi

echo "-- MetaMod + SourceMod"
if [ ! -d "$SM" ]; then
  as_tf2 "cd '$G'
    mm=\$(curl -fsSL https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux)
    sm=\$(curl -fsSL https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux)
    curl -fsSL \"https://mms.alliedmods.net/mmsdrop/1.12/\$mm\" | tar xz
    curl -fsSL \"https://sm.alliedmods.net/smdrop/1.12/\$sm\" | tar xz
    printf '\"Plugin\"\n{\n\t\"file\"\t\"../left4dead/addons/metamod/bin/server\"\n}\n' > addons/metamod.vdf"
fi

echo "-- l4dtoolz (lets the server hold 5 players)"
if [ ! -f "$G/addons/l4dtoolz/l4dtoolz_mm.so" ]; then
  T=$(mktemp -d)
  curl -fsSL https://github.com/accelerator74/l4dtoolz/releases/download/2.2.0/l4dtoolz-l4d-linux-ef2a8df.tar.gz -o "$T/t.tgz"
  tar -xzf "$T/t.tgz" -C "$T"
  A=$(find "$T" -type d -name addons | head -1)
  [ -n "$A" ] || { echo "no addons folder in the l4dtoolz archive"; exit 1; }
  cp -rn "$A"/. "$G/addons/"
  rm -rf "$T"
fi
[ -f "$G/addons/l4dtoolz/l4dtoolz_mm.so" ] || { echo "l4dtoolz_mm.so not found"; exit 1; }
MP=$G/addons/metamod/metaplugins.ini
grep -q '^addons/l4dtoolz/l4dtoolz_mm' "$MP" 2>/dev/null || echo "addons/l4dtoolz/l4dtoolz_mm" >> "$MP"

echo "-- admins"
A=$SM/configs/admins_simple.ini
[ -f /root/l4d-admins-$KEY.ini ] && mv -f /root/l4d-admins-$KEY.ini "$A"
grep -qF "\"$OWNER_ID\"" "$A" 2>/dev/null || printf '"%s" "z"\n' "$OWNER_ID" >> "$A"

echo "-- plugins"
WANT=$(grep -vE '^\s*(#|$)' "$HERE/base/plugins.txt")
[ "$DAMAGELOG" = 1 ] && WANT="$WANT"$'\n'l4d_damagelog
[ "$REVERSE_FF" = 1 ] && WANT="$WANT"$'\n'l4d_reverse_ff
mkdir -p "$SM/plugins/disabled" "$SM/scripting" "$SM/translations"
for sp in "$HERE"/scripting/*.sp; do
  n=$(basename "$sp" .sp)
  echo "$WANT" | grep -qx "$n" && install -o tf2 -g tf2 -m 644 "$sp" "$SM/scripting/$n.sp"
done
if [ "$REVERSE_FF" = 1 ]; then   # third-party plugin, downloaded from its author
  as_tf2 "cd '$SM'
    RAW=https://raw.githubusercontent.com/Mystik-Spiral/l4d_reverse_ff/main
    curl -fsSL \$RAW/l4d_reverse_ff.sp -o scripting/l4d_reverse_ff.sp
    curl -fsSL \$RAW/l4d_reverse_ff.phrases.txt -o translations/l4d_reverse_ff.phrases.txt"
fi
# everything in plugins/ that is not wanted goes to plugins/disabled/
for f in "$SM"/plugins/*.smx; do
  n=$(basename "$f" .smx)
  echo "$WANT" | grep -qx "$n" || mv -f "$f" "$SM/plugins/disabled/"
done
# our plugins are compiled here, from the source in the repo
FAIL=0
for n in $(echo "$WANT" | grep '^l4d_'); do
  if as_tf2 "cd '$SM/scripting' && ./spcomp $n.sp -o ../plugins/$n.smx 2>&1 | grep -iE 'error|Code size'"; then :; fi
  [ -f "$SM/plugins/$n.smx" ] || { echo "!! $n did not compile"; FAIL=1; }
done
# stock plugins that are wanted but sit in disabled/
for n in $(echo "$WANT" | grep -v '^l4d_'); do
  [ -f "$SM/plugins/$n.smx" ] || { [ -f "$SM/plugins/disabled/$n.smx" ] && mv "$SM/plugins/disabled/$n.smx" "$SM/plugins/"; }
done
[ "$FAIL" = 0 ] || { echo "Stopping: fix the compile errors above."; exit 1; }

echo "-- settings"
MAPLIST=adminmenu_maplist.ini; [ "$MODE" = versus ] && MAPLIST=adminmenu_maplist_versus.ini
install -o tf2 -g tf2 -m 644 "$HERE/base/$MAPLIST" "$SM/configs/adminmenu_maplist.ini"
# rcon password: keep the old one unless it is missing or the old default
OLD=$(sed -n 's/^rcon_password "\(.*\)".*/\1/p' "$CFG/server.cfg" 2>/dev/null | head -n 1 || true)
if [ -z "$OLD" ] || [ "$OLD" = Space123 ]; then OLD=$(openssl rand -hex 12); echo "(new rcon password made, not shown)"; fi
{
  cat "$HERE/base/server.cfg"
  echo "rcon_password \"$OLD\""
  echo "hostname \"$NAME\""
  echo "mp_gamemode $MODE"
  echo "l4d_rotate_order \"$ORDER\""
  [ -n "$DIFFICULTY" ] && echo "z_difficulty $DIFFICULTY"
} > "$CFG/server.cfg"
chown tf2:tf2 "$CFG/server.cfg"
if [ "$REVERSE_FF" = 1 ]; then   # the plugin adds every setting we leave out, with its default
  mkdir -p "$CFG/sourcemod"; install -m 644 "$HERE/base/reverse_ff.cfg" "$CFG/sourcemod/l4d2_reverse_ff.cfg"
fi
chown -R tf2:tf2 "$G/addons" "$CFG/sourcemod" 2>/dev/null || true

echo "-- service"
cat > "/etc/systemd/system/$SERVICE.service" <<UNIT
[Unit]
Description=Left 4 Dead server ($KEY)
After=network-online.target
Wants=network-online.target

[Service]
User=tf2
WorkingDirectory=$ROOT
ExecStart=/usr/bin/screen -DmS $SCREEN $ROOT/srcds_run -game left4dead -console -port $PORT +maxplayers 8 +mp_gamemode $MODE +map $START_MAP +hostname "$NAME"
Restart=on-failure
RestartSec=10
# keep it from starving TF2 on this small VPS
MemoryMax=$MEMORY
CPUWeight=50

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable "$SERVICE" >/dev/null 2>&1

echo "== done: $KEY. Plugins: $(echo "$WANT" | tr '\n' ' ')"
echo "Not started. Start it only when the owner says so (run: systemctl start <service>)."
