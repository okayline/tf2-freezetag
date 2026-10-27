#!/usr/bin/env bash
# Installs the L4D1 welcome-screen leaderboard: vps/l4d-leaderboard.py plus a systemd timer that rebuilds
# the L4D motd.txt every 5 minutes from the template (l4d/motd/motd.txt), with the top players by common
# infected killed in the past N days (names only). Run as root. Re-running is safe.
# Arg 1: days in the window (default 5). Arg 2: how many players to show (default 3).
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

DAYS="${1:-5}"; TOP="${2:-3}"
printf '%s' "$DAYS$TOP" | grep -Eq '^[0-9]+$' || { echo "Days and top must be numbers."; exit 1; }
G=/home/tf2/l4d/left4dead
D=/home/tf2/l4d-leaderboard
[ -d "$G/logs" ] || { echo "no $G/logs (is L4D installed, and the log turned on with l4d-log-on?)"; exit 1; }
mkdir -p "$D"
install -o tf2 -g tf2 -m 755 /root/l4d-leaderboard.py "$D/l4d-leaderboard.py"
install -o tf2 -g tf2 -m 644 /root/l4d-motd-template.html "$D/template.html"
chown tf2:tf2 "$D"

cat > /etc/systemd/system/l4d-leaderboard.service <<UNIT
[Unit]
Description=Rebuild the L4D welcome screen with the leaderboard

[Service]
Type=oneshot
User=tf2
ExecStart=/usr/bin/python3 $D/l4d-leaderboard.py $G/logs $D/template.html $G/motd.txt $DAYS $TOP
Nice=10
UNIT
cat > /etc/systemd/system/l4d-leaderboard.timer <<UNIT
[Unit]
Description=Rebuild the L4D leaderboard every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now l4d-leaderboard.timer >/dev/null 2>&1
systemctl start l4d-leaderboard.service
echo "timer: $(systemctl is-active l4d-leaderboard.timer); last run: $(systemctl show -p Result --value l4d-leaderboard.service)"
grep -o 'class="board">.*</p>' "$G/motd.txt" | sed 's/<br>/ | /g; s/<[^>]*>//g'
