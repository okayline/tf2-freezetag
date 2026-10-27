#!/usr/bin/env bash
# Installs a brand new, untouched Left 4 Dead (1) server straight from Steam into /home/tf2/l4d-fresh, as its own service
# "l4dfresh" on port 27019. Nothing is copied from the other servers: no SourceMod, no plugins, no custom welcome screen,
# no host.txt, default settings. It is for seeing how the game's own welcome window looks. Does NOT start the server and does not
# touch any other server. Safe to re-run: it just updates the game and rewrites the service file.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SRV_HOME=/home/tf2
DST=$SRV_HOME/l4d-fresh
FREE=$(df --output=avail -BG /home | tail -n 1 | tr -dc '0-9')
echo "free disk: ${FREE} GB"
[ -d "$DST/left4dead" ] || [ "$FREE" -ge 8 ] || { echo "Less than 8 GB free, stopping."; exit 1; }
[ -d "$SRV_HOME/steamcmd" ] || { echo "No steamcmd in $SRV_HOME."; exit 1; }
if ss -lun | grep -q ":27019 "; then echo "Port 27019 is already in use."; exit 1; fi

echo "== L4D1 server (app 222840) into $DST =="
sudo -u tf2 bash -euo pipefail <<USER
mkdir -p "$DST"
cd "$SRV_HOME/steamcmd"
./steamcmd.sh +force_install_dir "$DST" +login anonymous +app_update 222840 validate +quit
USER

echo "== systemd service =="
cat > /etc/systemd/system/l4dfresh.service <<UNIT
[Unit]
Description=Left 4 Dead server (fresh, untouched)
After=network-online.target
Wants=network-online.target

[Service]
User=tf2
WorkingDirectory=$DST
ExecStart=/usr/bin/screen -DmS l4dfresh $DST/srcds_run -game left4dead -console -port 27019 +maxplayers 8 +map l4d_hospital01_apartment +hostname "L4D Stock Test"
Restart=on-failure
RestartSec=10
MemoryMax=1200M
CPUWeight=50

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
echo "df after:"; df -h /home | tail -n 1
echo "Done. Not started yet. Port 27019/udp may need opening."
