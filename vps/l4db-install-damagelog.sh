#!/usr/bin/env bash
# Compiles and loads the damage log plugin (l4d/scripting/l4d_damagelog.sp) in the SECOND L4D server (/home/tf2/l4d-b,
# screen "l4db"). Run as root. No restart. Prints compiler errors if there are any.
set -euo pipefail
SM=/home/tf2/l4d-b/left4dead/addons/sourcemod
[ -d "$SM/scripting" ] || { echo "No $SM yet. Run l4db-setup first."; exit 1; }
install -o tf2 -g tf2 -m 644 /root/l4d_damagelog.sp $SM/scripting/l4d_damagelog.sp
sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_damagelog.sp -o ../plugins/l4d_damagelog.smx 2>&1 | tail -n 14"
ls -la $SM/plugins/l4d_damagelog.smx
sudo -u tf2 screen -S l4db -X stuff "sm plugins load l4d_damagelog$(printf '\r')"
sleep 3
sudo -u tf2 screen -S l4db -X hardcopy -h /home/tf2/l4db-console.txt
grep -iE "damage log|damagelog|error|fail" /home/tf2/l4db-console.txt | tail -n 6
