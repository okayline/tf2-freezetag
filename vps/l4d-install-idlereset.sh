#!/usr/bin/env bash
# Compiles and loads the idle reset plugin (l4d/scripting/l4d_idlereset.sp) live, with no restart and without touching other plugins
# or players. Run as root. If a server's copy does not compile, nothing is loaded there.
# Arg 1: "coop" (the two co-op servers, default) or "all" (also the Versus server). Arg 2: minutes empty before the reset (default 30).
# The settings go into each server's server.cfg (only if not set yet) and are applied live.
set -euo pipefail
WHO="${1:-coop}"; MIN="${2:-30}"
printf '%s' "$MIN" | grep -Eq '^[0-9]+$' || { echo "minutes must be a number"; exit 1; }

install_one() {   # dir screen map
  local D=$1 S=$2 MAP=$3
  local SM=/home/tf2/$D/left4dead/addons/sourcemod C=/home/tf2/$D/left4dead/cfg/server.cfg
  [ -d "$SM/scripting" ] || { echo "$D: no $SM, skipped"; return; }
  echo "== $D ($S) back to $MAP after $MIN minutes empty =="
  install -o tf2 -g tf2 -m 644 /root/l4d_idlereset.sp $SM/scripting/l4d_idlereset.sp
  grep -q '^l4d_idle_minutes ' $C || echo "l4d_idle_minutes $MIN" >> $C
  grep -q '^l4d_idle_map ' $C || echo "l4d_idle_map $MAP" >> $C
  chown tf2:tf2 $C
  sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_idlereset.sp -o ../plugins/l4d_idlereset.smx 2>&1 | grep -iE 'error|warning|Code size' | head -n 8"
  [ -f $SM/plugins/l4d_idlereset.smx ] || { echo "$D: did not compile, nothing loaded"; return; }
  sudo -u tf2 screen -S $S -X stuff "sm plugins load l4d_idlereset$(printf '\r')"
  sleep 1
  sudo -u tf2 screen -S $S -X stuff "l4d_idle_minutes $MIN$(printf '\r')"
  sudo -u tf2 screen -S $S -X stuff "l4d_idle_map $MAP$(printf '\r')"
  sleep 2
  sudo -u tf2 screen -S $S -X hardcopy -h /home/tf2/$S-console.txt
  grep -iE "idle reset|error" /home/tf2/$S-console.txt | tail -n 3
}

install_one l4d   l4d  l4d_hospital01_apartment
install_one l4d-c l4dc l4d_hospital01_apartment
if [ "$WHO" = all ]; then install_one l4d-b l4db l4d_vs_hospital01_apartment; fi
