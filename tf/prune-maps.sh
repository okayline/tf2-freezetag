#!/usr/bin/env bash
# Removes TF2 maps nobody plays. Run on the VPS:  prune-maps.sh dry   (only shows what would go)   or   prune-maps.sh go
# KEEPS: every map named in the server's mapcycle.txt and mapcycle_tactical.txt, and every map that has a .nav file (bots need it).
# Removed maps can be put back with the install-maps action (it downloads them from fastdl.serveme.tf) or from the backup.
set -euo pipefail
MODE=${1:-dry}
cd /home/tf2/server/tf/maps
KEEP=$(mktemp); DEL=$(mktemp)
cat ../cfg/mapcycle.txt ../cfg/mapcycle_tactical.txt 2>/dev/null | tr -d '\r' | sed 's#//.*##' | awk 'NF{print $1}' | sort -u > "$KEEP"
k=0; d=0; bytes=0
for f in *.bsp; do
  n=${f%.bsp}
  if grep -qx "$n" "$KEEP" || [ -f "$n.nav" ]; then k=$((k+1))
  else echo "$n" >> "$DEL"; d=$((d+1)); bytes=$((bytes+$(stat -c%s "$f"))); fi
done
echo "maps now: $((k+d)) | keeping: $k | to remove: $d ($((bytes/1048576)) MB)"
echo "keeping: $(grep -xFf "$KEEP" <(ls *.bsp | sed 's/\.bsp$//') | tr '\n' ' ')$(for f in *.nav; do n=${f%.nav}; grep -qx "$n" "$KEEP" || printf '%s ' "$n"; done 2>/dev/null)"
if [ "$MODE" = go ]; then
  while read -r n; do rm -f "$n.bsp" "$n.nav" "$n.bsp.bz2"; done < "$DEL"
  echo "removed $d maps"; df -h / | tail -n 1
else
  echo "(dry run: nothing removed. Run again with 'go' to remove.)"
fi
rm -f "$KEEP" "$DEL"
