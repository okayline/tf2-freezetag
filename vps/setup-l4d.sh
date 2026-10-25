#!/usr/bin/env bash
# Installs the Left 4 Dead (1) dedicated server next to TF2, as its own systemd service "l4d" on port 27016.
# Run as root after setup.sh (it reuses the tf2 user and steamcmd). Safe to re-run: it just updates the game.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SRV_USER=tf2
SRV_HOME=/home/$SRV_USER
SRV_DIR=$SRV_HOME/l4d
HOSTNAME_ARG="${L4D_HOSTNAME:-88x31 L4D}"

echo "== L4D1 server (app 222840) =="
sudo -u "$SRV_USER" bash -euo pipefail <<USER
mkdir -p "$SRV_DIR"
cd "$SRV_HOME/steamcmd"
./steamcmd.sh +force_install_dir "$SRV_DIR" +login anonymous +app_update 222840 validate +quit
USER

echo "== systemd service =="
cat > /etc/systemd/system/l4d.service <<UNIT
[Unit]
Description=Left 4 Dead server
After=network-online.target
Wants=network-online.target

[Service]
User=$SRV_USER
WorkingDirectory=$SRV_DIR
ExecStart=/usr/bin/screen -DmS l4d $SRV_DIR/srcds_run -game left4dead -console -port 27016 +maxplayers 8 +map l4d_hospital01_apartment +hostname "$HOSTNAME_ARG"
Restart=on-failure
RestartSec=10
# keep it from starving TF2 on this small VPS
MemoryMax=1500M
CPUWeight=50

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable l4d
echo "Done. Not started yet: systemctl start l4d (game port 27016)."
