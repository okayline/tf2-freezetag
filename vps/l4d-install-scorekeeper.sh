#!/usr/bin/env bash
# Compiles and loads the score keeper plugin (l4d/scripting/l4d_scorekeeper.sp) in the L4D1 server. Run as root.
# Loads only this one plugin, live: no restart, and the other plugins and the players are not touched.
# If the plugin does not compile, nothing is loaded.
set -euo pipefail
SM=/home/tf2/l4d/left4dead/addons/sourcemod
install -o tf2 -g tf2 -m 644 /root/l4d_scorekeeper.sp $SM/scripting/l4d_scorekeeper.sp
sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_scorekeeper.sp -o ../plugins/l4d_scorekeeper.smx 2>&1 | tail -n 12"
ls -la $SM/plugins/l4d_scorekeeper.smx
sudo -u tf2 screen -S l4d -X stuff "sm plugins load l4d_scorekeeper$(printf '\r')"
sleep 2
sudo -u tf2 screen -S l4d -X hardcopy -h /home/tf2/l4d-console.txt
grep -iE "scorekeeper|score keeper|error" /home/tf2/l4d-console.txt | tail -n 6
