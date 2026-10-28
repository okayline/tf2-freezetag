#!/usr/bin/env bash
# Installs the Discord control bot (vps/discord-bot.py) as the systemd service "discord-bot", running as user tf2.
# Run as root. Re-running is safe (it also restarts the bot, which picks up a new script or token).
# Needs /root/discord-bot.py, /root/discord-status.py and the bot token in /home/tf2/discord/bot.token
# (the bot-install action writes it from the GitHub secret DISCORD_BOT_TOKEN; it is never printed).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

D=/home/tf2/discord
[ -s $D/bot.token ] || { echo "no $D/bot.token yet"; exit 1; }

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-discord >/dev/null
python3 -c "import discord; print('discord.py', discord.__version__)"

install -o tf2 -g tf2 -m 755 /root/discord-bot.py $D/discord-bot.py
install -o tf2 -g tf2 -m 644 /root/leaderboard.py $D/leaderboard.py
install -o tf2 -g tf2 -m 644 /root/announcements-l4d.txt /root/announcements-tf2.txt $D/
install -o tf2 -g tf2 -m 755 /root/discord-status.py $D/discord-status.py
chown tf2:tf2 $D/bot.token; chmod 600 $D/bot.token

# The bot may only do these exact things as root (nothing else, no wildcards).
{
  for s in tf2 l4d l4db l4dc; do
    for a in start stop restart "disable --now" "enable --now"; do
      echo "tf2 ALL=(root) NOPASSWD: /usr/bin/systemctl $a $s"
    done
  done
  echo "tf2 ALL=(root) NOPASSWD: /usr/bin/systemctl start --no-block vps-backup.service"
  echo "tf2 ALL=(root) NOPASSWD: /usr/local/bin/vps-backup status"
  echo "tf2 ALL=(root) NOPASSWD: /usr/local/bin/vps-backup keep, /usr/local/bin/vps-backup keep [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]"
} > /etc/sudoers.d/discord-bot.tmp
chmod 440 /etc/sudoers.d/discord-bot.tmp
visudo -cf /etc/sudoers.d/discord-bot.tmp >/dev/null || { rm -f /etc/sudoers.d/discord-bot.tmp; echo "sudoers check failed"; exit 1; }
mv /etc/sudoers.d/discord-bot.tmp /etc/sudoers.d/discord-bot

cat > /etc/systemd/system/discord-bot.service <<UNIT
[Unit]
Description=88x31 Discord control bot
After=network-online.target
Wants=network-online.target

[Service]
User=tf2
ExecStart=/usr/bin/python3 -I $D/discord-bot.py
Restart=always
RestartSec=10
MemoryMax=300M

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable discord-bot >/dev/null 2>&1
systemctl restart discord-bot
sleep 8
echo "discord-bot: $(systemctl is-active discord-bot)"
journalctl -u discord-bot -n 5 --no-pager -o cat | sed -E 's/[A-Za-z0-9_-]{24,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{20,}/(token)/g'
