#!/usr/bin/env bash
# Installs restic + rclone and a nightly encrypted backup to pCloud (restic repo at rclone remote "pcloud:" folder Backups/vps-backup).
# Run as root. Re-running is safe. Needs /root/pcloud-token (JSON from `rclone authorize "pcloud"`), optional /root/pcloud-host,
# and /root/restic-password. The workflow action "backup" (job install) puts those three files there. Nothing here is printed.
# Backs up configs, logs, plugins, maps (with .nav files), Minecraft world, service files, SSH/firewall settings and the small tools.
# NOT the rest of the TF2/L4D game installs (steamcmd re-downloads them).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
for f in /root/pcloud-token /root/restic-password; do [ -s "$f" ] || { echo "missing $f"; exit 1; }; done

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq restic rclone >/dev/null
echo "restic: $(restic version | head -1)"; echo "rclone: $(rclone version | head -1)"

HOST=api.pcloud.com; [ -s /root/pcloud-host ] && HOST=$(tr -cd 'a-z0-9.' < /root/pcloud-host)
mkdir -p /root/.config/rclone; umask 077
cat > /root/.config/rclone/rclone.conf <<CONF
[pcloud]
type = pcloud
token = $(tr -d '\n' < /root/pcloud-token)
hostname = $HOST
CONF
chmod 600 /root/.config/rclone/rclone.conf /root/restic-password

cat > /usr/local/bin/vps-backup <<'SH'
#!/usr/bin/env bash
# Nightly backup to pCloud with restic. "vps-backup" runs it; "vps-backup status" lists snapshots.
export RESTIC_REPOSITORY=rclone:pcloud:Backups/vps-backup RESTIC_PASSWORD_FILE=/root/restic-password
if [ "${1:-}" = keep ]; then restic tag --add keep "${2:-latest}" 2>&1 | tail -n 3; restic snapshots --tag keep --compact | tail -n 6; exit 0; fi   # "keep": tag a snapshot (default: the newest) so cleanup never deletes it
if [ "${1:-}" = status ]; then restic snapshots --compact | tail -n 15; restic stats --mode raw-data 2>&1 | tail -n 3; exit 0; fi
restic cat config >/dev/null 2>&1 || restic init
P=()
for d in /home/tf2/discord /home/tf2/uptime-kuma/data /home/tf2/mc /home/tf2/leaderboard-ignore.txt /home/tf2/stats-app /home/tf2/*.txt /home/tf2/leaderboard-* /home/tf2/l4d-leaderboard /home/tf2/logweb /home/tf2/navgen.log \
         /home/tf2/server/tf/cfg /home/tf2/server/tf/addons/sourcemod/{configs,data,plugins,logs,extensions,gamedata} /home/tf2/server/tf/maps /home/tf2/server/tf/logs /home/tf2/server/tf/custom \
         /home/tf2/l4d/left4dead/{cfg,logs,addons/sourcemod/{configs,data,plugins,extensions,gamedata}} \
         /home/tf2/l4d-b/left4dead/{cfg,logs,addons/sourcemod/{configs,data,plugins,extensions,gamedata}} \
         /home/tf2/l4d-c/left4dead/{cfg,logs,addons/sourcemod/{configs,data,plugins,extensions,gamedata}} \
         /etc/systemd/system /etc/caddy /etc/ssh /root/.ssh /etc/ufw /etc/iptables /var/spool/cron /root/tf2-gslt /var/www/stats /etc/l4d-story /opt/story; do
  [ -e "$d" ] && P+=("$d")
done
restic backup --one-file-system --exclude '*.jar' --exclude '/home/tf2/mc/cache' --exclude '/home/tf2/mc/logs' --exclude '*/world-old' --exclude '*.console.txt' "${P[@]}" || exit 1
restic forget --keep-tag keep --keep-daily 7 --keep-weekly 4 --keep-monthly 3 >/dev/null
[ "$(date +%u)" = 7 ] && restic prune --max-unused 5% >/dev/null 2>&1
exit 0
SH
chmod 755 /usr/local/bin/vps-backup

cat > /etc/systemd/system/vps-backup.service <<UNIT
[Unit]
Description=Encrypted backup to pCloud
After=network-online.target

[Service]
Type=oneshot
Environment=HOME=/root
ExecStart=/usr/local/bin/vps-backup
Nice=15
IOSchedulingClass=idle
UNIT
cat > /etc/systemd/system/vps-backup.timer <<UNIT
[Unit]
Description=Nightly backup to pCloud

[Timer]
OnCalendar=*-*-* 12:30:00
RandomizedDelaySec=10min
Persistent=true

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now vps-backup.timer >/dev/null 2>&1
echo "timer: $(systemctl is-active vps-backup.timer) (next: $(systemctl list-timers vps-backup.timer --no-legend | awk '{print $1,$2}'))"
echo "Checking pCloud login..."; rclone lsd pcloud: 2>&1 | head -n 5 && echo "pCloud login OK"
