#!/usr/bin/env bash
# Installs the Reverse Friendly-Fire plugin (l4d_reverse_ff by Mystik Spiral) into the L4D1 server:
# downloads its source and phrases file from the author's GitHub, compiles it with the SourceMod in the L4D1 server.
# Run as root after setup-l4d-sourcemod.sh. Safe to re-run (it updates the plugin).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SM=/home/tf2/l4d/left4dead/addons/sourcemod
RAW=https://raw.githubusercontent.com/Mystik-Spiral/l4d_reverse_ff/main
[ -x "$SM/scripting/spcomp" ] || { echo "SourceMod is not installed in the L4D1 server yet."; exit 1; }

sudo -u tf2 bash -euo pipefail <<USER
cd "$SM"
curl -fsSL "$RAW/l4d_reverse_ff.sp" -o scripting/l4d_reverse_ff.sp
curl -fsSL "$RAW/l4d_reverse_ff.phrases.txt" -o translations/l4d_reverse_ff.phrases.txt
cd scripting
./spcomp l4d_reverse_ff.sp -o ../plugins/l4d_reverse_ff.smx 2>&1 | tail -n 12
ls -la ../plugins/l4d_reverse_ff.smx
USER
echo "Done. Restart the l4d service (or change map) to load it."
