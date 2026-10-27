#!/usr/bin/env bash
# Compiles and loads the campaign rotation plugin (l4d/scripting/l4d_campaign_rotate.sp, with versus support) in the
# SECOND L4D server (/home/tf2/l4d-b, screen "l4db"). The first server keeps its own compiled copy. Run as root. No restart.
set -euo pipefail
SM=/home/tf2/l4d-b/left4dead/addons/sourcemod
[ -d "$SM/scripting" ] || { echo "No $SM yet. Run l4db-setup first."; exit 1; }
install -o tf2 -g tf2 -m 644 /root/l4d_campaign_rotate.sp $SM/scripting/l4d_campaign_rotate.sp
sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_campaign_rotate.sp -o ../plugins/l4d_campaign_rotate.smx 2>&1 | tail -n 12"
ls -la $SM/plugins/l4d_campaign_rotate.smx
sudo -u tf2 screen -S l4db -X stuff "sm plugins reload l4d_campaign_rotate$(printf '\r')"
sleep 3
sudo -u tf2 screen -S l4db -X hardcopy -h /home/tf2/l4db-console.txt
grep -iE "rotat|round_end|versus|error" /home/tf2/l4db-console.txt | tail -n 8
