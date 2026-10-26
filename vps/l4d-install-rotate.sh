#!/usr/bin/env bash
# Compiles and loads the campaign rotation plugin (l4d/scripting/l4d_campaign_rotate.sp) in the L4D1 server.
# Run as root. Only loads it live when the server is empty (no restart either way).
set -euo pipefail
SM=/home/tf2/l4d/left4dead/addons/sourcemod
install -o tf2 -g tf2 -m 644 /root/l4d_campaign_rotate.sp $SM/scripting/l4d_campaign_rotate.sp
sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_campaign_rotate.sp -o ../plugins/l4d_campaign_rotate.smx 2>&1 | tail -n 8"
ls -la $SM/plugins/l4d_campaign_rotate.smx
sudo -u tf2 screen -S l4d -X stuff "sm plugins reload l4d_campaign_rotate;l4d_rotate_delay 5$(printf '\r')"
sleep 2
sudo -u tf2 screen -S l4d -X hardcopy -h /home/tf2/l4d-console.txt; grep -i "rotat" /home/tf2/l4d-console.txt | tail -n 3
