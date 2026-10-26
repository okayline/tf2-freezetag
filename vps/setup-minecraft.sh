#!/usr/bin/env bash
# Installs a Minecraft Java server (Paper) with Geyser + Floodgate so Bedrock players can join too.
# Service "mc", Java 25565/tcp, Bedrock 19132/udp (RakNet) + 19132/tcp signaling + 19133/udp (NetherNet, needed from Oct 27 2026). Memory capped so TF2/L4D stay smooth.
# Safe to re-run: updates Paper/Geyser/Floodgate jars, keeps the world and settings. Does NOT start/restart it.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }
U=tf2; D=/home/$U/mc; UA="88x31-mc-setup (ryan)"
mkdir -p "$D/plugins"

echo "== Paper (latest stable) =="
VJ=$(curl -fsS -A "$UA" https://fill.papermc.io/v3/projects/paper)
VER=$(printf '%s' "$VJ" | python3 -c 'import json,sys;d=json.load(sys.stdin)["versions"];v=[x for g in d.values() for x in g if all(c.isdigit() or c=="." for c in x)];print(v[0])')
BJ=$(curl -fsS -A "$UA" "https://fill.papermc.io/v3/projects/paper/versions/$VER/builds/latest")
URL=$(printf '%s' "$BJ" | python3 -c 'import json,sys;print(json.load(sys.stdin)["downloads"]["server:default"]["url"])')
JAVA=$(curl -fsS -A "$UA" "https://fill.papermc.io/v3/projects/paper/versions/$VER" | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"]["java"]["version"]["minimum"])' 2>/dev/null || echo 21)
echo "Paper $VER, needs Java $JAVA"
curl -fsSL -A "$UA" -o "$D/paper.jar.new" "$URL" && mv "$D/paper.jar.new" "$D/paper.jar"

echo "== Java $JAVA =="
if ! java -version 2>&1 | grep -qE "version \"($JAVA|2[1-9]|3[0-9])"; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "openjdk-$JAVA-jre-headless" >/dev/null || {
    echo "openjdk-$JAVA not in apt, using Adoptium"; apt-get install -y -qq wget gpg apt-transport-https >/dev/null
    wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor --yes -o /usr/share/keyrings/adoptium.gpg
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release; echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/adoptium.list
    apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "temurin-$JAVA-jre" >/dev/null; }
fi
java -version 2>&1 | head -1

echo "== Geyser + Floodgate =="
for p in geyser floodgate; do
  curl -fsSL -A "$UA" -o "$D/plugins/$p.jar" "https://download.geysermc.org/v2/projects/$p/versions/latest/builds/latest/downloads/spigot" && echo "$p ok"
done

cd "$D"
echo "eula=true" > eula.txt
if [ ! -f server.properties ]; then
cat > server.properties <<P
motd=\u00a7d~*~88x31 cLuB~*~\u00a7r mInEcRaFt VaNiLLa
server-port=25565
max-players=10
view-distance=7
simulation-distance=5
difficulty=normal
white-list=true
enforce-whitelist=true
online-mode=true
spawn-protection=0
sync-chunk-writes=false
pause-when-empty-seconds=-1
network-compression-threshold=256
P
fi
# Geyser: Bedrock on 19132/udp, Floodgate auth so Bedrock players need no Java account
mkdir -p plugins/Geyser-Spigot
[ -f plugins/Geyser-Spigot/config.yml ] || cat > plugins/Geyser-Spigot/config.yml <<G
bedrock:
  port: 19132
  motd1: "88x31 cLuB"
  motd2: "mInEcRaFt"
remote:
  auth-type: floodgate
G
chown -R $U:$U "$D"

cat > /etc/systemd/system/mc.service <<UNIT
[Unit]
Description=Minecraft (Paper + Geyser)
After=network-online.target
[Service]
User=$U
WorkingDirectory=$D
ExecStart=/usr/bin/screen -DmS mc /usr/bin/java -Xms512M -Xmx1536M -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -DgeyserTransport=both -DgeyserWebrtcPort=19133 -jar paper.jar --nogui
ExecStop=/usr/bin/screen -S mc -X stuff "stop\$(printf '\\r')"
TimeoutStopSec=60
KillSignal=SIGCONT
Restart=on-failure
RestartSec=15
MemoryMax=1900M
CPUWeight=25
Nice=5
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable mc >/dev/null 2>&1
if command -v ufw >/dev/null && ufw status | grep -q active; then ufw allow 25565/tcp >/dev/null; ufw allow 19132/udp >/dev/null; ufw allow 19132/tcp >/dev/null; ufw allow 19133/udp >/dev/null; echo "ports opened"; fi
echo "Done. Start with: systemctl start mc"
