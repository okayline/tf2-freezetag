#!/usr/bin/env bash
# Bans a player by name on every RUNNING L4D server. The Steam ID is looked up in the game logs and is never printed.
#   ban-player.sh <exact player name>
# A server that is off is skipped (it says so): run it again after that server is started.
# To undo: console command  sm_unban STEAM_ID  (the ID is in the server's cfg/banned_user.cfg).
set -euo pipefail
NAME=${1:?give the player name}
ID=$(grep -rhaF "\"$NAME<" /home/tf2/l4d/left4dead/logs /home/tf2/l4d-b/left4dead/logs /home/tf2/l4d-c/left4dead/logs 2>/dev/null \
     | grep -o 'STEAM_[0-9]:[0-9]:[0-9]*' | tail -n 1 || true)
[ -n "$ID" ] || { echo "No player named $NAME found in the logs (use the exact name)."; exit 1; }
for pair in l4d:l4d l4db:l4db l4dc:l4dc; do
  svc=${pair%%:*}; scr=${pair##*:}
  if systemctl is-active --quiet "$svc"; then
    sudo -u tf2 screen -S "$scr" -X stuff "sm_addban 0 $ID \"Team killing\"$(printf '\r')"
    echo "$svc: ban sent"
  else
    echo "$svc: server is off, not applied"
  fi
done
