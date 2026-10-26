#!/usr/bin/env bash
# Installs l4dtoolz (accelerator74 2.2.0, L4D1 linux build) so the server can hold 5 players, plus the
# reserved-slot plugin (5th slot for admins). Never restarts. Loads live ONLY if no humans are on.
set -euo pipefail
G=/home/tf2/l4d/left4dead
SM=$G/addons/sourcemod
T=$(mktemp -d)
curl -fsSL https://github.com/accelerator74/l4dtoolz/releases/download/2.2.0/l4dtoolz-l4d-linux-ef2a8df.tar.gz -o $T/t.tgz
tar -xzf $T/t.tgz -C $T
echo "-- archive:"; (cd $T && find . -type f ! -name t.tgz | head -20)
A=$(find $T -type d -name addons | head -1)
[ -n "$A" ] || { echo "no addons folder in archive, stopping"; exit 1; }
cp -rn "$A"/. $G/addons/
chown -R tf2:tf2 $G/addons
SO=$(cd $G && find addons -name 'l4dtoolz*.so' | head -1)
echo "so: $SO"
install -o tf2 -g tf2 -m 644 /root/l4d_reserve.sp $SM/scripting/l4d_reserve.sp
sudo -u tf2 bash -c "cd $SM/scripting && ./spcomp l4d_reserve.sp -o ../plugins/l4d_reserve.smx 2>&1 | grep -iE 'error|Code size'"
C=$G/cfg/server.cfg
grep -qxF "sv_maxplayers 5" $C || echo "sv_maxplayers 5" >> $C
chown tf2:tf2 $C
con() { sudo -u tf2 screen -S l4d -X stuff "$1$(printf '\r')"; sleep 2; sudo -u tf2 screen -S l4d -X hardcopy -h /home/tf2/l4d-console.txt; }
con status
H=$(grep -E '^players' /home/tf2/l4d-console.txt | tail -1 | grep -oE '[0-9]+ humans' | grep -oE '[0-9]+' || echo 99)
echo "humans on now: $H"
if [ "$H" = "0" ]; then
  con "meta load ${SO%.so}"
  con "sv_maxplayers 5;sm plugins load l4d_reserve"
  con status
  grep -iE "l4dtoolz|plugin|reserve|max\)|error" /home/tf2/l4d-console.txt | tail -n 8
else
  echo "players are on: installed but NOT loaded. Run this again when the server is empty."
fi
rm -rf $T
