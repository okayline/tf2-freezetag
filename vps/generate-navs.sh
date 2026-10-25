#!/usr/bin/env bash
# Builds bot navigation meshes (.nav files) for the TF2 maps named on the command line.
# Stops the tf2 service, then for each map starts a temporary server on it, runs nav_generate,
# waits for tf/maps/<map>.nav to appear, and shuts that server down. The tf2 service is started
# again when everything is done (or if this script stops early). Progress goes to /home/tf2/navgen.log.
# Run as root. Maps that already have a .nav file on disk are skipped.
set -u
[ "$(id -u)" = 0 ] || { echo "Run this as root."; exit 1; }

SRV=/home/tf2/server
LOG=/home/tf2/navgen.log
say() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }
send() { sudo -u tf2 screen -S navgen -X stuff "$1$(printf '\r')"; }
alive() { sudo -u tf2 screen -ls 2>/dev/null | grep -q '\.navgen'; }
: > "$LOG"; chown tf2:tf2 "$LOG"
trap 'say "all done, starting the tf2 service again"; systemctl start tf2' EXIT

say "maps to do: $*"
systemctl stop tf2
sleep 3

for m in "$@"; do
  if [ -f "$SRV/tf/maps/$m.nav" ]; then say "$m: already has a nav file, skipping"; continue; fi
  say "$m: starting a temporary server"
  sudo -u tf2 screen -dmS navgen "$SRV/srcds_run" -game tf -console -port 27015 +maxplayers 24 +map "$m"
  sleep 60
  say "$m: running nav_generate"
  send "nav_generate"
  waited=0
  while [ "$waited" -lt 1500 ]; do                     # up to 25 minutes per map
    sleep 10; waited=$((waited + 10))
    [ -f "$SRV/tf/maps/$m.nav" ] && break
    alive || break
  done
  if [ -f "$SRV/tf/maps/$m.nav" ]; then
    sleep 10
    say "$m: nav file created ($(stat -c %s "$SRV/tf/maps/$m.nav") bytes) after about ${waited}s"
  else
    say "$m: NO nav file after ${waited}s. Console tail: $(sudo -u tf2 screen -S navgen -X hardcopy -h /tmp/navgen-console.txt 2>/dev/null; tail -n 8 /tmp/navgen-console.txt 2>/dev/null | tr '\n' '|' | cut -c1-500)"
  fi
  chown tf2:tf2 "$SRV/tf/maps/$m.nav" 2>/dev/null
  alive && send "quit"
  for i in 1 2 3 4 5 6; do alive || break; sleep 5; done
  alive && { pkill -f "srcds_linux.*port 27015"; sleep 3; sudo -u tf2 screen -S navgen -X quit; }
done
