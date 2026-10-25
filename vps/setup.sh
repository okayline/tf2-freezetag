#!/usr/bin/env bash
# One-time setup for a brand new Debian/Ubuntu VPS: installs steamcmd, the TF2 dedicated server,
# Metamod:Source 1.12 and SourceMod 1.12, then a systemd service called "tf2" that runs it.
# Run as root:   bash setup.sh
# Re-running is safe: it updates TF2 and leaves your files alone.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run this as root (or with sudo)."; exit 1; }

SRV_USER=tf2
SRV_HOME=/home/$SRV_USER
SRV_DIR=$SRV_HOME/server
HOSTNAME_ARG="${TF2_HOSTNAME:-88x31 Freeze Tag}"

echo "== Packages =="
dpkg --add-architecture i386
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl tar screen lib32gcc-s1 lib32stdc++6 libsdl2-2.0-0:i386 libcurl4:i386 2>/dev/null \
  || DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl tar screen lib32gcc-s1 lib32stdc++6

echo "== Server user =="
id "$SRV_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$SRV_USER"

echo "== steamcmd + TF2 (about 25 GB, takes a while) =="
sudo -u "$SRV_USER" bash -euo pipefail <<USER
mkdir -p "$SRV_HOME/steamcmd" "$SRV_DIR"
cd "$SRV_HOME/steamcmd"
[ -x steamcmd.sh ] || curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xz
./steamcmd.sh +force_install_dir "$SRV_DIR" +login anonymous +app_update 232250 validate +quit
# steamclient.so is looked up here
mkdir -p "$SRV_HOME/.steam/sdk32"
ln -sf "$SRV_HOME/steamcmd/linux32/steamclient.so" "$SRV_HOME/.steam/sdk32/steamclient.so"
USER

echo "== Metamod:Source + SourceMod 1.12 =="
sudo -u "$SRV_USER" bash -euo pipefail <<USER
cd "$SRV_DIR/tf"
mm=\$(curl -fsSL https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux)
sm=\$(curl -fsSL https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux)
curl -fsSL "https://mms.alliedmods.net/mmsdrop/1.12/\$mm" | tar xz
curl -fsSL "https://sm.alliedmods.net/smdrop/1.12/\$sm" | tar xz
echo "Installed \$mm and \$sm"
USER

echo "== systemd service =="
cat > /etc/systemd/system/tf2.service <<UNIT
[Unit]
Description=TF2 Freeze Tag server
After=network-online.target
Wants=network-online.target

[Service]
User=$SRV_USER
WorkingDirectory=$SRV_DIR
ExecStart=$SRV_DIR/srcds_run -game tf -console -port 27015 +maxplayers 24 +map cp_gravelpit_snowy +hostname "$HOSTNAME_ARG"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable tf2

echo
echo "Done. The server is installed but NOT started yet."
echo "Next: push the repo's files to $SRV_DIR/tf (the deploy does this), then: systemctl start tf2"
echo "Open UDP+TCP port 27015 in the VPS firewall if it has one."
