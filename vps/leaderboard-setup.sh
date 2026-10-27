#!/usr/bin/env bash
# Installs a welcome-screen leaderboard: vps/leaderboard.py plus a systemd timer that rebuilds the game's
# motd.txt every 5 minutes from a template, with the server's totals for the past N days (no player names; Arg 3 is no longer used).
# Run as root. Re-running is safe.
# Arg 1: l4d (zombies killed), l4dc (zombies killed, third L4D server), tf2 (freezes) or l4dvs (damage, second L4D server; needs the l4d_damagelog plugin). Arg 2: days in the window (default 5). Arg 3: players shown (default 3).
# Needs /root/leaderboard.py and /root/<game>-motd-template.html (the actions upload both).
# Players in /home/tf2/leaderboard-ignore.txt (leaderboard-ignore action) are left out.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

GAME="${1:-}"; DAYS="${2:-5}"; TOP="${3:-3}"; KIND=$GAME   # KIND = which counting rules leaderboard.py uses
case "$GAME" in
  l4d) LOGS=/home/tf2/l4d/left4dead/logs; OUT=/home/tf2/l4d/left4dead/motd.txt ;;
  tf2) LOGS=/home/tf2/server/tf/logs;     OUT=/home/tf2/server/tf/cfg/motd.txt ;;
  l4dvs) LOGS=/home/tf2/l4d-b/left4dead/logs; OUT=/home/tf2/l4d-b/left4dead/motd.txt ;;
  l4dc) LOGS=/home/tf2/l4d-c/left4dead/logs; OUT=/home/tf2/l4d-c/left4dead/motd.txt; KIND=l4d ;;
  *) echo "First argument must be l4d, l4dc, tf2 or l4dvs."; exit 1 ;;
esac
printf '%s' "$DAYS$TOP" | grep -Eq '^[0-9]+$' || { echo "Days and top must be numbers."; exit 1; }
[ -d "$LOGS" ] || { echo "no $LOGS (is the game installed, and its log turned on: l4d-log-on / tf2-log-on?)"; exit 1; }
D=/home/tf2/leaderboard-$GAME
IGN=/home/tf2/leaderboard-ignore.txt
mkdir -p "$D"
# the ignore list used to live in a per-game folder: keep what was already added
for old in /home/tf2/l4d-leaderboard/ignore.txt; do
  [ -f "$old" ] && cat "$old" >> "$IGN" && rm -f "$old"
done
touch "$IGN"; sort -u "$IGN" -o "$IGN"; chown tf2:tf2 "$IGN"; chmod 600 "$IGN"
install -o tf2 -g tf2 -m 755 /root/leaderboard.py "$D/leaderboard.py"
install -o tf2 -g tf2 -m 644 "/root/$GAME-motd-template.html" "$D/template.html"
chown tf2:tf2 "$D"

cat > "/etc/systemd/system/leaderboard-$GAME.service" <<UNIT
[Unit]
Description=Rebuild the $GAME welcome screen with the leaderboard

[Service]
Type=oneshot
User=tf2
ExecStart=/usr/bin/python3 $D/leaderboard.py $KIND $LOGS $D/template.html $OUT $DAYS $TOP $IGN
Nice=10
UNIT
cat > "/etc/systemd/system/leaderboard-$GAME.timer" <<UNIT
[Unit]
Description=Rebuild the $GAME leaderboard every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now "leaderboard-$GAME.timer" >/dev/null 2>&1
systemctl start "leaderboard-$GAME.service"
echo "$GAME timer: $(systemctl is-active leaderboard-$GAME.timer); last run: $(systemctl show -p Result --value leaderboard-$GAME.service)"
grep -o 'class="board">.*</p>' "$OUT" | sed 's/<br>/ | /g; s/<[^>]*>//g'
