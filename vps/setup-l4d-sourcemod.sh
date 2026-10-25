#!/usr/bin/env bash
# Installs Metamod:Source + SourceMod 1.12 into the Left 4 Dead (1) server (/home/tf2/l4d/left4dead) and makes the
# owner a full admin. Run as root after setup-l4d.sh. Safe to re-run: it just updates the two packages.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SRV_USER=tf2
GAME_DIR=/home/$SRV_USER/l4d/left4dead
OWNER_ID="${L4D_ADMIN_ID:-STEAM_0:1:21624068}"

[ -d "$GAME_DIR" ] || { echo "No $GAME_DIR yet. Run l4d-setup first."; exit 1; }

echo "== Metamod:Source + SourceMod 1.12 into $GAME_DIR =="
sudo -u "$SRV_USER" bash -euo pipefail <<USER
cd "$GAME_DIR"
mm=\$(curl -fsSL https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux)
sm=\$(curl -fsSL https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux)
curl -fsSL "https://mms.alliedmods.net/mmsdrop/1.12/\$mm" | tar xz
curl -fsSL "https://sm.alliedmods.net/smdrop/1.12/\$sm" | tar xz
echo "Installed \$mm and \$sm"
# this game finds Metamod through a .vdf file in addons/
cat > addons/metamod.vdf <<VDF
"Plugin"
{
	"file"	"../left4dead/addons/metamod/bin/server"
}
VDF
f=addons/sourcemod/configs/admins_simple.ini
grep -qF '"$OWNER_ID"' \$f 2>/dev/null || printf '"%s" "z"\n' '$OWNER_ID' >> \$f
tail -n 2 \$f
USER
echo "Done. Restart the l4d service to load it."
