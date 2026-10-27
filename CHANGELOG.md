# Changelog

[TF2] Freeze Tag (patched): the Freeze Tag SourceMod plugin for a modded TF2 server, plus its server settings and the push-to-update deploy. The plugin is **Freeze Tag 1.1.4 (patched)**; the settings plugin `88x31_settings` is 1.0. There are no other version numbers, so entries are named by what changed. Newest first. Times are Hawaii time (HST).

## Second L4D server (versus), memory check, TF2 pause
**Mon Oct 26, 2026 · 7:10 PM HST**
- **Added:** the `l4db-setup` action (`vps/setup-l4d-b.sh`). It makes a second Left 4 Dead (1) server, a copy of the first in `/home/tf2/l4d-b` with its own service `l4db` (screen `l4db`), game port 27017, name "~*~88x31~*~ L4D1 VeRsUs SeRveR" (first named "L4D cLaSSiC 2"; renamed with `l4db-rename`), 8 players, starting in versus on `l4d_vs_hospital01_apartment`. Game files of 4 MB and up are hard links to the first server's (about 2 GB of extra disk instead of 8.5 GB); everything smaller is a real copy, and logs are not copied. The copy has the same SourceMod, plugins and admins, so `!tools` can switch it between co-op and versus. The Discord chat relay plugin and its settings are not copied.
- **Added:** `l4d/motd/motd-vs.txt` and the `l4db-motd` action: the second server's welcome screen, titled "~*~88x31~*~ L4D1 VeRsUs SeRveR" with the campaigns in its order (No Mercy, Blood Harvest, Death Toll, Dead Air, Crash Course, The Sacrifice). The first server's `l4d/motd/motd.txt` is unchanged.
- **Added:** the campaign order of the rotation plugin is now the `l4d_rotate_order` setting (default is the story order); `l4db-order` sets it on the second server (saved in its server.cfg, applied live, also sets the start map). `l4db-admins` compares plugins and admins of the two servers.
- **Changed:** on the second server only, Reverse Friendly-Fire is off (`l4db-rff`, box off/on): the plugin file is moved to `plugins/disabled` and unloaded live, and the "Reverse friendly fire is ON" line is removed from its welcome screen (`motd-vs.txt`). The first server still has it on.
- **Added:** `l4db-rename`, `l4db-cfg` (its server.cfg with secrets hidden, and what differs from the first server's), `l4db-log` (game log with IPs and Steam IDs removed), `l4db-rotate-install` (campaign rotation with versus support, compiled and loaded on the second server only), `net-check`, `cpu-use`.
- **Added:** `l4db-start` (refuses if less than 900 MB of memory is free), `l4db-stop`, `l4db-restart`, `l4db-console`, `l4db-command`; `mem-use` (memory per program); `tf2-pause` (stops the tf2 service and keeps it from starting at boot, nothing deleted) and `tf2-resume`.
- **Changed:** nothing on the first L4D server or on TF2. TF2 was not paused: measured memory is Minecraft 1,671 MB, TF2 698 MB, the first L4D server 134 MB (with two players on).
- **Removed:** nothing.
- **Not tested:** joining the new server from the game client or seeing it in the server browser; a full versus match; what happens after a versus finale (the campaign rotation plugin only acts in co-op, so the server may stay on the same campaign); the Discord status and live feed do not include the new server; its welcome screen is a copy of the first server's.

## Leaderboards on the welcome screens (L4D zombies, TF2 freezes)
**Mon Oct 26, 2026 · 6:50 PM HST**
- **Added:** `vps/leaderboard.py`, `vps/leaderboard-setup.sh` and the `l4d-leaderboard-install` and `tf2-leaderboard-install` actions (box: days and how many players, like `5 3`; empty = 5 3). A timer on the VPS rebuilds each game's `motd.txt` every 5 minutes from its template, with the top 3 players of the past 5 days: "Most Zombies Killed in the Past 5 Days" on L4D (common infected killed) and "Most Freezes in the Past 5 Days" on TF2 (Freeze Tag turns a kill into a freeze, so kills of the other team). It reads the game logs, counts humans only (bots, teamkills and L4D special infected are not counted), counts by Steam account so a name change does not split a score, and shows names only, never IDs or addresses.
- **Added:** the `leaderboard-ignore` action (box: a Steam ID). The list lives on the VPS in `/home/tf2/leaderboard-ignore.txt`, not in the repo, and those players are left out of both boards. `STEAM_0:`, `STEAM_1:` and `[U:1:]` forms of the same account are treated alike.
- **Changed:** `l4d/motd/motd.txt` and `tf/cfg/motd.txt` have a `<!--LEADERBOARD-->` spot (under the friendly-fire line on L4D; on TF2 under the map list, with the "No random crits" line below it). The `l4d-motd` action keeps the L4D leaderboard working if it is installed, and removes the empty spot if it is not. A TF2 deploy puts the template back, and the board returns within 5 minutes.
- **Removed:** nothing.
- **Not tested:** on the VPS (checked only on made-up log lines: ranking, bots and teamkills skipped, old kills skipped, name change, an ignored account, names with HTML). Not checked whether the game re-reads `motd.txt` for each player or only at map load, so a board can be a few minutes old. The TF2 kill-line format is the standard one, but no real TF2 kill line was read here.

## MOTD: list of server settings
**Mon Oct 26, 2026 · 6:25 PM HST**
- **Added:** one line under the map pool in the welcome screen (`motd.txt`, and the same in `motd_text.txt`): "No random crits, No damage spread, Big heads". The first two match `88x31.cfg`. Big heads is the plugin's losing-team effect after a round.
- **Removed:** nothing.
- **Not tested:** how the line looks in the game window; big heads at a real round end (not seen yet).

## Server login token: set again by setup, hidden in output
**Mon Oct 26, 2026 · 6:05 PM HST**
- **Added:** server browser tags (`chill,custom,freeze,freezetag,nocrits,nodmgspread`) and region US West (`sv_region 1`) in `88x31.cfg`.
- **Added:** the `tf2-gslt` action. It puts the server login token (repo secret `TF2_GSLT`) into the tf2 service launch line, before `+map`. It does not restart the server.
- **Changed:** `setup` now puts the login token back on its own after rewriting the tf2 service, so it is not lost.
- **Changed:** `console-view` and `show-file` print the login token as `(hidden)`, since the repo and its Actions output are public.
- **Removed:** the `mp_waitingforplayers_time 0` line from `88x31.cfg`. The server said it was an unknown command, so it did nothing. How to skip "waiting for players" is still open.
- **Not tested:** the server logging on to Steam with the token; `setup` with the token step.

## Bot paths for the arena maps; server private for testing
**Sun Oct 25, 2026 · 11:18 PM HST**
- **Added:** bot navigation files (`.nav`) for the 10 Tactical mode arena maps, made with `generate-navs` (TF2 is stopped while it runs and started again after). Without them the bots stood still in spawn, so arena rounds never got going.
- **Changed (live only, not in the repo):** `sv_password` set for testing, so the server is private until it is cleared or the server restarts (not checked whether a restart clears it). `tf_arena_use_queue 1` sent once as a test; Tactical mode sets it back to 0 on the next map.
- **Removed:** nothing.
- **Not tested:** bots moving on the arena maps.

## Tactical mode: arena rounds never started (fixed)
**Sun Oct 25, 2026 · 11:09 PM HST**
- **Fixed:** after switching to Tactical mode, the arena round never started. Freeze Tag was still on while the arena map loaded, so it changed the map for Freeze Tag (control point blocked, spawn rooms removed) and was only turned off after. The switch now turns Freeze Tag off (or on) before the map change.
- **Removed:** nothing.
- **Not tested:** fixed live by reloading the arena map; the switch itself not re-tested yet.

## VPS tools: disk-usage
**Sun Oct 25, 2026 · 11:03 PM HST**
- **Added:** the read-only `disk-usage` action (folder sizes under /home/tf2, the TF2 server's biggest folders, free space).
- **Removed:** nothing.

## Tactical mode switch (arena, first to 7)
**Sun Oct 25, 2026 · 11:02 PM HST**
- **Added:** "Tactical mode" in 88x31 Tools (`88x31_settings.sp` 1.5, also `sm_tactical`). On: Freeze Tag off, `mp_winlimit 7` (first to 7 rounds), no arena queue, and a random map from the new `tf/cfg/mapcycle_tactical.txt` (10 arena maps). Off: Freeze Tag on, normal map cycle. The mode is set again after every map load; a server restart goes back to Freeze Tag. `deploy.yml` now also sends `mapcycle_tactical.txt`.
- **Removed:** nothing.
- **Not tested:** not switched yet. Side swap at half time and a score HUD are not done yet (step 2).

## Losing team gets big heads after a round
**Sun Oct 25, 2026 · 10:48 PM HST**
- **Added:** `88x31_settings.sp` 1.4: when a round is won, everyone on the losing team gets big heads until the next round starts. Nothing happens on a stalemate. Works alongside the "Big heads" admin switch.
- **Removed:** nothing.
- **Not tested:** not seen at a real round end yet. Not checked that Freeze Tag's own round wins send the normal "round won" event.

## Big heads off by default again
**Sun Oct 25, 2026 · 10:44 PM HST**
- **Changed:** big heads start OFF again; they are only turned on from the admin menu.
- **Removed:** big heads as the default (from 10:41 PM).
- **Not tested:** not seen in game yet.

## Big heads on by default
**Sun Oct 25, 2026 · 10:41 PM HST**
- **Changed:** big heads start ON when the 88x31 Settings plugin loads (server start or update). The admin menu can still turn them off.
- **Removed:** normal-size heads as the default.
- **Not tested:** not seen after a restart yet.

## Freeze Tag: HUD text above the chat box
**Sun Oct 25, 2026 · 10:39 PM HST**
- **Changed:** the frozen-count/clock text starts at 45% down, so it is above the chat box when chat is open.
- **Removed:** the 55% position, which overlapped the open chat box.
- **Not tested:** not seen in game yet.

## Freeze Tag: HUD text a little higher
**Sun Oct 25, 2026 · 10:37 PM HST**
- **Changed:** the frozen-count/clock text starts at 55% down.
- **Removed:** the 59% position.
- **Not tested:** not seen in game yet.

## Admin menu: Big heads on/off
**Sun Oct 25, 2026 · 10:37 PM HST**
- **Added:** "Big heads: ON/OFF" in 88x31 Tools (`88x31_settings.sp` 1.3, also `sm_bigheads`). It makes everyone's head 3x bigger by setting the head size every tick; gravity and everything else stay the same. It stays on through respawns until turned off, and resets when the plugin reloads or the map changes.
- **Removed:** nothing.
- **Not tested:** not seen in game yet.

## Freeze Tag: HUD text up about two lines
**Sun Oct 25, 2026 · 10:35 PM HST**
- **Changed:** the frozen-count/clock text starts at 59% down instead of 66%, so the clock sits about where the RED line was.
- **Removed:** the 66% position.
- **Not tested:** the line height is estimated; not seen in game yet.

## Admin menu: 88x31 Tools with "Restart round"
**Sun Oct 25, 2026 · 10:31 PM HST**
- **Added:** `88x31_settings.sp` 1.2 puts an "88x31 Tools" section in the `!admin` menu with "Restart round" (also the command `sm_restartround`). It says "New round!" in chat and runs `mp_restartround 1`.
- **Removed:** nothing.
- **Not tested:** not seen in the in-game menu yet.

## Freeze Tag: HUD text lower on the left edge
**Sun Oct 25, 2026 · 10:27 PM HST**
- **Changed:** the frozen-count/clock text now starts 66% down the screen (a third of the way up from the bottom), still on the left edge.
- **Removed:** the 33% (upper third) position.
- **Not tested:** not seen in game yet.

## Freeze Tag: count-up round clock on the HUD
**Sun Oct 25, 2026 · 10:23 PM HST**
- **Added:** when a map has no round time limit (all maps in the current rotation), the HUD shows how long the round has been going (mm:ss) under the frozen counts. The clock starts when the round starts. No rules change.
- **Removed:** nothing.
- **Not tested:** not seen in game yet.

## Freeze Tag: round number taken off the HUD
**Sun Oct 25, 2026 · 10:20 PM HST**
- **Removed:** the round number ("#1", "#2"...) under the RED/BLU frozen counts, in both versions of the HUD text in `freezetag.sp` (with and without a round timer).
- **Found:** the missing time is not a bug: this server has no round time limit, and Freeze Tag only draws the timer when there is one.
- **Not tested:** not seen in game yet.

## Freeze Tag: frozen-count text is see-through
**Sun Oct 25, 2026 · 10:15 PM HST**
- **Changed:** in `freezetag.sp`, the frozen-count text's alpha went from 255 (solid) to 150 (about 60% visible).
- **Removed:** the fully solid text.
- **Not changed:** text size. SourceMod's HUD text has no size setting; each player's game decides it.
- **Not tested:** not seen in game yet.

## Freeze Tag: frozen-count text moved to the left edge
**Sun Oct 25, 2026 · 10:09 PM HST**
- **Changed:** in `freezetag.sp`, the "RED Frozen / BLU Frozen / time" text moved from 18% across, 2% down to the left edge (1% across), a third of the way down (33%), so it no longer sits under the team portraits of custom HUDs.
- **Removed:** the old top-of-screen position.
- **Not tested:** not seen in game yet; where it lands depends on each player's HUD.

## Caddy takes ports 80/443 for both web pages
**Sun Oct 25, 2026 · 10:02 PM HST**
- **Changed:** the first `map-https` run failed because the log page already used port 443. Now Caddy is the only thing on 80/443: `map.88x31.app` goes to BlueMap (real certificate), `logs.88x31.app` to the log page (self-signed, as before, for Cloudflare "Full" mode), and the bare IP on port 80 to the log page. `map-https` re-installs the log page first.
- **Removed:** the log page's own HTTPS code and self-signed certificate files, and its ports 80/443; it now only listens inside the server on 8090.
- **Not tested:** not run yet. `logs.88x31.app` through Cloudflare is not checked.

## Map web page over HTTPS: https://map.88x31.app (map-https)
**Sun Oct 25, 2026 · 9:58 PM HST**
- **Added:** Caddy (from Debian's packages) as a new dependency on the VPS, with `vps/Caddyfile`, and the `map-https` action that installs and starts it. Caddy gets a free certificate for `map.88x31.app` by itself and passes visitors to BlueMap on port 8100. `.app` names only open over HTTPS, so the plain-HTTP map could not use the name.
- **Removed:** nothing. `http://<server IP>:8100` still works, and the log page keeps port 80 (Caddy's plain-HTTP side is on 8081).
- **Not tested:** not run yet.

## L4D: map list reloads by itself after install
**Sun Oct 25, 2026 · 9:49 PM HST**
- **Changed:** `l4d-install-rotate.sh` also reloads SourceMod's Basic Commands plugin, which is what reads the admin "Change map" list. Before, a new list only showed after a manual reload or a map change.
- **Removed:** nothing.
- **Not tested:** not run since this change (the manual reload worked).

## L4D: all co-op chapters in the admin "Change map" menu
**Sun Oct 25, 2026 · 9:47 PM HST**
- **Added:** `l4d/configs/adminmenu_maplist.ini` with all 25 co-op chapters of the six campaigns; `l4d-rotate-install` now copies it into SourceMod's configs.
- **Removed:** the old admin map list on the server, which only showed 4 maps.
- **Not tested:** not seen in the in-game menu yet. Versus maps are not in the list (use the co-op/versus switch).

## L4D: player limits move from server.cfg into the admin tools plugin
**Sun Oct 25, 2026 · 9:44 PM HST**
- **Changed:** `l4d_admintools.sp` now sets the player limits for both modes (co-op 5 players, browser /4; versus 8, /8) when configs run and when the plugin loads, and re-checks every 10 seconds (timers pause while the empty server hibernates). After switching to versus, the browser still showed /4 because `server.cfg` put the co-op values back on the map load.
- **Removed:** `sv_maxplayers 5` and `sv_visiblemaxplayers 4` from the L4D `server.cfg` (the reserve install script now deletes them instead of adding them).
- **Not tested:** only on the empty, hibernating server.

## L4D: co-op / versus switch in the admin menu
**Sun Oct 25, 2026 · 9:36 PM HST**
- **Added:** "Switch to Versus" / "Switch to Co-op" in the 88x31 Tools admin menu (`l4d_admintools.sp` 1.2). It sets `mp_gamemode`, the player limits (versus: 8 players, browser /8, 8 public slots; co-op: 5, /4, 4) and loads the first map of the same campaign (No Mercy if it can't tell). In versus the 8-player limits are put back after every map load, since `server.cfg` sets the co-op ones.
- **Changed:** `l4d_campaign_rotate.sp` only moves to the next campaign in co-op. In versus the first team's rescue is just half-time.
- **Removed:** nothing.
- **Not tested:** not switched yet. A server restart goes back to co-op. What L4D1 does after a versus campaign ends is not checked.

## L4D: server name survives restarts
**Sun Oct 25, 2026 · 9:22 PM HST**
- **Fixed:** after a restart the L4D server was named just `~*~88x31~*~`: the name in the service file gets cut at the first space on its way to the server. `l4d-rename` now also writes the full name into `server.cfg`, which the server reads on every map load.
- **Removed:** any older `hostname` line in the L4D `server.cfg` (replaced by the new one).
- **Not tested:** not seen after a restart yet.

## L4D: 15 seconds after the rescue before the next campaign
**Sun Oct 25, 2026 · 9:19 PM HST**
- **Changed:** `l4d_rotate_delay` default in `l4d_campaign_rotate.sp`, and the value `l4d-install-rotate.sh` sets, from 5 to 15 seconds, so players can enjoy the escape before the next campaign loads.
- **Removed:** the 5-second wait.
- **Not tested:** not seen at a real finale yet.

## BlueMap: choose the number of render threads
**Sun Oct 25, 2026 · 8:38 PM HST**
- **Changed:** `mc-bluemap-render` takes an optional 4th number, the render thread count (default 1). Set to 2 while TF2 and L4D are stopped.
- **Removed:** the fixed 1-thread setting.
- **Not tested:** not run yet.

## Minecraft: BlueMap first render (mc-bluemap-render)
**Sun Oct 25, 2026 · 8:32 PM HST**
- **Added:** the `mc-bluemap-render` action. It accepts BlueMap's resource download in `core.conf`, sets 1 render thread, and adds a render area to each map (a square around X Z; the Nether uses the same spot divided by 8), then reloads BlueMap. Running it again replaces the area.
- **Changed:** BlueMap went from idle to rendering 1,000 blocks around -330, 73.
- **Removed:** nothing.
- **Not tested:** not run yet. The web page port (8100) is not opened in the firewall.

## L4D: server browser shows /4
**Sun Oct 25, 2026 · 8:25 PM HST**
- **Changed:** `vps/l4d-install-reserve.sh` now sets `sv_visiblemaxplayers 4` live and saves it in `server.cfg`, so the server browser shows 4 slots. The real limit stays `sv_maxplayers 5`, with the 5th slot for admins.
- **Removed:** the "/5" shown in the server browser.
- **Not tested:** not run yet. When 4 are on, the browser shows it as full; admins may need to join through Favorites, a friend, or the console.

## Minecraft: ViaBackwards (older game versions can join)
**Sun Oct 25, 2026 · 7:51 PM HST**
- **Added:** ViaVersion 5.12.2-SNAPSHOT and ViaBackwards 5.12.2-SNAPSHOT, installed with `mc-plugin-install`. ViaBackwards lets players on older Minecraft versions join; it needs ViaVersion to work. Both are development builds (the newest Modrinth has for 26.3).
- **Removed:** nothing.
- **Not tested:** both loaded at startup; nobody has joined from an older version yet.

## Minecraft: plugin installer (mc-plugin-install); CoreProtect not installed
**Sun Oct 25, 2026 · 7:46 PM HST**
- **Added:** the `mc-plugin-install` action, which installs one Paper plugin from Modrinth by name (only a build for 26.3) and restarts Minecraft.
- **Not installed:** CoreProtect. Modrinth has no build for 26.3 (the official one goes up to 26.2), so the action stopped without changing anything. (Corrected 11:27 PM: this entry first said CoreProtect was added.)
- **Removed:** nothing.

## Minecraft: BlueMap installed, not rendering (mc-bluemap-install)
**Sun Oct 25, 2026 · 7:42 PM HST**
- **Added:** the `mc-bluemap-install` action. It downloads the newest BlueMap for Paper 26.3 from Modrinth into the Minecraft plugins and restarts Minecraft. BlueMap is left idle on purpose: it does not render or start its web page until `accept-download` is set to true in `plugins/BlueMap/core.conf`, at the owner's request (rendering uses a lot of CPU).
- **Removed:** nothing.
- **Not tested:** not run yet.

## Minecraft: delete the import zip (mc-import-cleanup)
**Sun Oct 25, 2026 · 7:36 PM HST**
- **Added:** the `mc-import-cleanup` action, which deletes `/root/world2.zip` once the imported world is in place.
- **Removed:** the uploaded `world2.zip` on the VPS, at the owner's request. The old new-world stays as `world-old`.
- **Not tested:** not run yet.

## L4D feed: end-of-chapter stats in Discord
**Sun Oct 25, 2026 · 7:30 PM HST**
- **Added:** `vps/discord-feed-l4d.py` now counts, for each human player, special and common infected killed, headshots, Tanks/Witches killed, teammates helped (revived/healed/rescued), friendly fire, times downed, deaths, items picked up, and time on the server. When the map changes, or the game logs a round end, finale win or mission lost, it posts one "Chapter stats" message (top 10 players) and starts counting again. TF2 is unchanged.
- **Removed:** nothing.
- **Not tested:** only a check on sample log lines. Not seen at a real chapter end; score from the server list is not in the game log, so it is not included.

## Minecraft: bold names in Discord
**Sun Oct 25, 2026 · 7:18 PM HST**
- **Changed:** `mc-discord-format` now also sets DiscordSRV's Minecraft-to-Discord chat format to the player's name in bold, then » and the message.
- **Removed:** the bold permission-group name in front of the player name (`**%primarygroup%**`), which showed nothing on this server.
- **Not tested:** not run yet.

## Minecraft: plainer Discord messages in game (mc-discord-format)
**Sun Oct 25, 2026 · 7:15 PM HST**
- **Changed:** the new `mc-discord-format` action sets DiscordSRV's `DiscordToMinecraftChatMessageFormat` to the sender's name in their top Discord role color, then » and the message, and reloads DiscordSRV. People with no Discord role get the plain name.
- **Removed:** the `[Discord | role]` and `[Discord]` tags in front of Discord messages in Minecraft chat.
- **Not tested:** not run yet.

## Minecraft: Discord chat bridge (mc-discord-install)
**Sun Oct 25, 2026 · 7:08 PM HST**
- **Added:** the `mc-discord-install` action. It downloads the newest DiscordSRV for Paper from Modrinth into the Minecraft plugins, puts the bot token (repo secret `MC_DISCORD_TOKEN`, never printed) and the `#mc` channel ID into its config, and restarts Minecraft. The token file it uses on the VPS is deleted afterwards.
- **Removed:** nothing.
- **Not tested:** not run yet. DiscordSRV says it supports 26.x and was tested on 26.1; the server runs Paper 26.3.

## Minecraft: import an old world (mc-import)
**Sun Oct 25, 2026 · 6:54 PM HST**
- **Added:** the `mc-import` action. It checks `/root/world2.zip` is complete, stops Minecraft, renames `world` to `world-old`, unzips the zip's world (the folder with `level.dat`) into `/home/tf2/mc/world`, gives it to the `tf2` user and starts Minecraft. It stops without changing anything if the zip is missing or broken, `unzip` is missing, or `world-old` already exists.
- **Removed:** nothing. The old world is kept as `world-old`, and the zip stays in `/root`.
- **Not tested:** not run yet.

## Feed: joins show first
**Sun Oct 25, 2026 · 6:49 PM HST**
- **Changed:** in `vps/discord-feed-l4d.py` (`flush`), "joined" lines now go to the top of each Discord batch. The L4D log writes "entered the game" after a new player's first pickups, so the join showed below them. Used by both the L4D and TF2 feeds.
- **Removed:** the old order, where a join stayed wherever the log put it in the batch.
- **Not tested:** only a syntax check and a quick test of the reordering line.

## Move the L4D add-ons out (l4d-addons-off)
**Sun Oct 25, 2026 · 3:38 PM HST**
- **Added:** the `l4d-addons-off` action moves `rip.ext.so`, `SteamWorks.ext.so`, `smjansson.ext.so` and `discord_api.smx` out of the L4D server's `addons/sourcemod` folders into `/home/tf2/l4d/off/`. Nothing is deleted, and it does not restart the server.
- **Why:** players' games crash when the L4D campaign changes or when joining, and a server `segfault` showed on the VPS. These add-ons were put there for the chat relay, which never ran on L4D. The cause of the crashes is not confirmed.
- **Removed:** nothing is removed from the repo.
- **Not tested:** not run yet.

## Welcome window: lighter background
**Sun Oct 25, 2026 · 3:16 PM HST**
- **Changed:** in `tf/cfg/motd.txt` the page background went from `#45406a` to `#564f80`, and the box from `#585280` to `#6a6398` with a lighter border (`#a79bd0` to `#b8acde`), at the owner's request. The pinks are a little deeper: the title `#ffb0dd` to `#ffa0d6`, the pink map lines `#ffa3d3` to `#ff93cb`, the closing line `#ffaede` to `#ffa0d6`. Other text colors are unchanged.
- **Removed:** the three darker background shades and the three lighter pinks above.
- **Tested here:** a browser preview only; not seen in the game. Shows after the next map change.

## Snowplow taken out of the pool
**Sun Oct 25, 2026 · 3:15 PM HST**
- **Removed:** `cp_snowplow` from `mapcycle.txt` and from the map list in the welcome window (`motd.txt`, `motd_text.txt`), at the owner's request. The pool is now 9 maps. It takes effect when the map next changes. `cp_snowplow` was the map the server was on at the time, and it stays loaded until then.
- **Changed:** nothing else. Not tested yet.

## Welcome window: title on two lines
**Sun Oct 25, 2026 · 3:10 PM HST**
- **Changed:** in `tf/cfg/motd.txt` the title is now two lines: "~*~88x31 cLuB~*~" on the first, and "FrEEze tAg SeRveR:  ICEY COLD Edition!" on the second, in bold at 30 px (the first line is 19 px; it was 23 px). The words and capital letters are the same.
- **Changed (same entry):** the "Freeze Tag mod with a snowy map pool:" line is bigger (19 px, was 16 px), and one empty line under the title is gone (the empty paragraph added earlier; the gap under the title is now a 20 px margin).
- **Removed:** the single-line title and the empty paragraph under it.
- **Tested here:** a browser preview only; not seen in the game. Shows after the next map change.

## Welcome window: colors balanced for TF2's own look
**Sun Oct 25, 2026 · 3:00 PM HST**
- **Changed:** after the owner saw the welcome window in TF2 ("the colors look a little off within the TF2 colors"), `tf/cfg/motd.txt` moved from a cool blue-lavender to a softer, slightly warmer dusky plum (background, box, border and text tints), and the content sits lower, with 84 px of top padding, so it isn't crammed into the top of the board. An empty line was added under the title. The wording and the pinks are the same. This is my reading of "off": the owner did not say which colors.
- **Removed:** the cooler blue tones (`#3a3d6e`, `#4c4f86`, `#8f93d6`) and the 26 px top padding.
- **Tested here:** a browser preview at roughly TF2's window shape. Not yet seen in the game.

## Welcome window (MOTD) redesigned
**Sun Oct 25, 2026 · 2:50 PM HST**
- **Changed:** `tf/cfg/motd.txt` is now dark but soft: a dusky lavender-blue background (lighter than the first dark draft), a rounded lilac box, a medium-bright pink title, the 10 maps in two columns (CP and KOTH) alternating medium-bright pink and mint, a smaller line under the box reading "Have fun, Stay Frosty", and simple `* . ~` sparkles top and bottom, using only inline styles. The wording is the old wording, except the title no longer starts with "Welcome to": it now reads "~*~88x31 cLuB~*~ FrEEze tAg SeRveR:  ICEY COLD Edition!". The "Freeze Tag mod with a snowy map pool:" line has the same words, with "Freeze Tag" and "snowy" in bold.
- **Removed:** the words "Welcome to" at the start of the title, the old bare list and the plain `<h2>` look. An earlier draft of this change added a line about the 10-second freeze, and that line is left out. `motd_text.txt` (the plain-text version) is unchanged.
- **Tested here:** rendered in a normal browser only (preview image). TF2's built-in browser may draw it slightly differently; not checked in the game. Takes effect when the file reaches the server and a player reconnects.

## Player count log on the VPS
**Sun Oct 25, 2026 · 2:40 PM HST**
- **Added:** the status script (`discord-status.py`), which already runs every minute, now also appends a line to `/home/tf2/discord/players.log` on the VPS whenever a server's state changes: online with the map and the number of humans and bots, or offline. Lines are stamped in HST. It logs only changes, so the file stays small, and it never writes player names or IP addresses. If writing the log fails, the Discord card still posts.
- **Why:** to see how many players are on over time, for example whether they come in pairs.
- **Removed:** nothing. No size limit or cleanup was added to the log.
- **Tested here:** a check with made-up states: repeated identical states write one line, a change writes a new line, each server is tracked separately. Not tested on the VPS.

## L4D1 status card: show player names
**Sun Oct 25, 2026 · 2:34 PM HST**
- **Found:** the L4D card showed "Players: 2, 0 bots (4 max)" with no names, while the TF2 card lists them. Likely cause, not confirmed: L4D1's `status` rows may have a second number before the name, which the name pattern in `discord-status.py` didn't allow.
- **Changed:** the name pattern now accepts an optional second number. Nothing else changed; IP addresses are still never read and bots are still not named.
- **Removed:** nothing.
- **Tested here:** against two made-up status snippets (a TF2-style row and an L4D-style row with two numbers); both show the names. The real L4D1 `status` layout was not seen, so whether this fixes the real card is not checked.

## Same chat relay for the L4D1 server
**Sun Oct 25, 2026 · 2:35 PM HST**
- **Added:** `install-discordrelay.sh` takes an optional game folder (default is still the TF2 server), and the `relay-install-l4d` action runs it on `/home/tf2/l4d/left4dead`. The L4D1 server already has SourceMod. The relay plugin, SteamWorks, ripext, SMJansson and discord-api are installed into it the same way; no restart and no settings.
- **Removed:** nothing.
- **Not tested:** whether these extensions and the relay plugin load on L4D1 at all is not checked. The TF2 version of this install is confirmed working for chat, joins and leaves (seen in Discord by the owner).

## SMJansson download: file names don't say "linux"
**Sun Oct 25, 2026 · 2:45 PM HST**
- **Found:** the run stopped, changing nothing, as designed: the SMJansson release's files are named `sm-ext-SMJansson-ubuntu-24.04-sm-1.12-dev.tar.gz` and `...-sm-master.tar.gz` (plus two Windows ones), so the installer's "linux" search found none.
- **Changed:** the installer now looks for `ubuntu` and prefers the `sm-1.12` one. It still stops unless the build inside is 32-bit. It was built on Ubuntu 24.04 and your server runs Debian 13; whether it loads there is not checked.
- **Removed:** nothing.
- **Not tested:** not run yet.

## sp-discordrelay: it also needs SMJansson
**Sun Oct 25, 2026 · 2:40 PM HST**
- **Found:** after the restart the server log said `discord_api.smx` and `discordrelay.smx` could not load because the extension SMJansson (`smjansson.ext`) was missing. The discord-api repo's README lists it; the relay plugin's README doesn't.
- **Added:** `relay-install` now also downloads SMJansson from the srcdslab/sm-ext-SMJansson releases (a fork of davenonymous/SMJansson), prefers a SourceMod 1.12 build, and stops, changing nothing, unless it is a 32-bit build. It also prints the release's file names.
- **Removed:** nothing.
- **Not tested:** the release's file names and its 32-bit Linux build are not checked (the page I could open didn't list them), and the plugins have not loaded yet.

## sp-discordrelay installer: picked the 64-bit ripext by mistake
**Sun Oct 25, 2026 · 2:30 PM HST**
- **Found:** the first run of `relay-install` copied `extensions/x64/rip.ext.so` (64-bit) to the server, but the TF2 server here is 32-bit. SourceMod would not load it, and the relay plugin needs it. The server was not restarted, so nothing has loaded it yet.
- **Changed:** the installer now skips the `x64` folder and stops, changing nothing, unless both extensions are 32-bit builds. Running it again replaces the wrong file with the 32-bit one.
- **Removed:** nothing.
- **Not tested:** the rerun has not happened yet; whether the 32-bit ripext is in that package is not checked.

## Trying sp-discordrelay for chat in both directions
**Sun Oct 25, 2026 · 2:20 PM HST**
- **Added:** `vps/install-discordrelay.sh` and the `relay-install` action. It downloads [sp-discordrelay](https://github.com/log-ical/sp-discordrelay) (log-ical) and the three things it needs (ripext, SteamWorks, discord-api) into a staging folder on the VPS, and only if every piece is found copies them into the TF2 server's `addons/sourcemod`. It does not restart the server or change any settings. The webhook link and the bot token get typed into `discordrelay.cfg` on the VPS by the owner, never into the repo.
- **Why:** the log-feed script (`discord-feed.py`) received 0 log lines from the server, and the cause wasn't found.
- **Removed:** nothing. `discord-feed.py` is still installed and running; it is not removed.
- **Not tested:** nothing has run yet. Which release files are picked, the plugin's own `.smx` being current with its source, and whether these load on this TF2 server are all not checked.

## TF2 feed: no log lines were arriving
**Sun Oct 25, 2026 · 2:05 PM HST**
- **Found:** the feed ran but received 0 log lines in 5 minutes (journal: "last 5 min: 0 log lines"). Likely cause, not confirmed: `discord-feed.py` ran `log on` and `logaddress_add` in one block, so if the server gave no reply to `log on`, the timeout skipped `logaddress_add`.
- **Changed:** each of the two commands now runs on its own, a timeout with no reply is no longer treated as a failure, and a real failure is printed once to the journal (command name and error type only).
- **Removed:** the single combined block.
- **Tested here:** against the fake server only (both commands still arrive). Not tested on the real server.

## Live TF2 feed to Discord: chat, kills, joins
**Sun Oct 25, 2026 · 1:55 PM HST**
- **Added:** `vps/discord-feed.py` (Python standard library only) listens for the TF2 server's own log lines on 127.0.0.1 and posts them in batches every few seconds to a separate Discord channel: chat (all and team), kills with the weapon, joins and leaves, suicides, round wins and map changes. `vps/discord-feed-setup.sh` runs it as an always-on service; `vps-tools.yml` gets `discord-feed-install` and `discord-feed-check`. Every minute the script tells the server over RCON to turn logging on and send it there, so a restart can't silently stop it and `server.cfg` doesn't change.
- **Kept off GitHub and out of Discord:** the feed's webhook link goes in `/home/tf2/discord/tf2-feed.url` on the VPS. IP addresses and Steam IDs are never posted, and chat text is never written to the journal. Kills between two bots are skipped.
- **Removed:** nothing.
- **Tested here:** against a fake RCON server, a fake webhook and made-up log packets in the expected format. Not tested on the real server, so whether TF2's real log lines match is not checked. L4D1 is not included yet. Freeze and rescue events would need changes to `freezetag.sp` and are not included.

## Discord status for the TF2 and L4D1 servers
**Sun Oct 25, 2026 · 1:20 PM HST**
- **Added:** `vps/discord-status.py` (Python standard library only) asks each server for `status` over RCON on 127.0.0.1 and edits one Discord message through a webhook: online or offline, map, player count, and human players' names (bots are counted, not named; IP addresses are never posted). `vps/discord-status-setup.sh` installs it with a systemd timer that runs every minute (TF2 port 27015, L4D1 port 27016). `vps-tools.yml` gets two actions: `discord-install` and `discord-check`.
- **Kept off GitHub:** the webhook links go in `/home/tf2/discord/tf2.url` and `l4d.url` on the VPS, and the RCON passwords are read from each server's `server.cfg`. Nothing secret is in the repo or in the workflow inputs.
- **Removed:** nothing.
- **Tested here:** against a fake RCON server and a fake webhook: first run posts, second run edits the same message, a wrong password and a server that is down show up as "can't read" and "offline", no password or IP in what is sent. **Not tested yet:** on the real servers, and whether L4D1 prints `status` in the same layout.

## Krampus taken out of the pool
**Sun Oct 25, 2026 · 12:59 PM HST**
- **Removed:** `koth_krampus` from `mapcycle.txt` and from the map list in the welcome window (`motd.txt`, `motd_text.txt`), at the owner's request. The pool is now 10 maps. Takes effect when the map cycle is next read.
- **Changed:** nothing else. Not tested yet.

## Frozen too long: back to spawn after 10 seconds
**Sun Oct 25, 2026 · 12:52 PM HST**
- **Changed:** in `freezetag_maps.cfg`, `autotimered` and `autotimeblue` are 10 in the `default`, `cp_` and `koth_` profiles (they were 30), so a player who stays frozen for 10 seconds is respawned in their team's spawn room. Applies from the next map change.
- **Removed:** the 30 second wait.
- Not tested yet.

## Frostwatch taken out of the pool
**Sun Oct 25, 2026 · 12:51 PM HST**
- **Removed:** `cp_frostwatch` from `mapcycle.txt` and from the map list in the welcome window (`motd.txt`, `motd_text.txt`), because the bots stand still in spawn on it (the owner: "they dont takl or move"). It has a nav file on the server, so the cause is not known. The pool is now 11 maps. Takes effect when the map cycle is next read.
- **Changed:** nothing else. Not tested yet.

## Admin commands to skip the map: sm_next and sm_random
**Sun Oct 25, 2026 · 10:55 AM HST**
- **Added:** `88x31_settings` is now version 1.1 with two admin commands. `sm_next` (or `!next` in chat) changes to the next map in `mapcycle.txt` after a 3 second warning; `sm_random` (or `!random`) picks a random map from the cycle, never the one already being played. Both need the change-map admin right, which the full admins have.
- **Changed:** nothing else. Not tested yet (the new plugin is compiled by the deploy, so check that it built).

## Bot navigation files built for the pool maps
**Sun Oct 25, 2026 · 11:55 AM HST**
- **Added:** bot navigation (`.nav`) files, generated on the server, for `koth_snowtower`, `cp_gravelpit_snowy`, `cp_frostwatch`, `cp_snowplow`, `cp_coldfront`, `cp_yukon_final`, `koth_winter_ridge`, `koth_highpass`, `koth_overcast_final` and `koth_krampus`, so bots can move on them. `cp_vanguard` and `cp_process_final` already had one in the game files. The files live only on the server (in `tf/maps/`), not in this repo. They were built with the manual `generate-navs` server tool.
- **Changed:** nothing else. Not tested yet.

## Two maps where bots stood still removed
**Sun Oct 25, 2026 · 11:05 AM HST**
- **Removed:** `cp_steel` and `cp_mountainlab` from `mapcycle.txt` and from the map list in the welcome window (`motd.txt`, `motd_text.txt`), because the bots did nothing on them (they have no bot navigation file). The pool is now 12 maps. Takes effect when the map cycle is next read.
- **Changed:** nothing else. Not tested yet.

## Freezing everyone no longer wins the round
**Sun Oct 25, 2026 · 10:45 AM HST**
- **Changed:** in `freezetag_maps.cfg`, `eliminations` is now 0 in every profile (it was 1 in most), so freezing a whole team no longer ends the round. Rounds end by capturing points / the king of the hill timer, and frozen players still go back to spawn after 30 seconds. Applies from the next map change.
- **Removed:** nothing. Not tested yet.

## Payload map removed
**Sun Oct 25, 2026 · 10:15 AM HST**
- **Removed:** `pl_snowycoast` from `mapcycle.txt` and from the map list in the welcome window (`motd.txt`, `motd_text.txt`), because the payload map did not work. The pool is now 4 maps: `cp_gravelpit_snowy`, `cp_frostwatch`, `cp_snowplow`, `koth_snowtower`. Takes effect when the map cycle is next read.
- **Changed:** nothing else. Not tested yet.

## Frozen too long: back to spawn after 30 seconds
**Sun Oct 25, 2026 · 10:35 AM HST**
- **Changed:** in `freezetag_maps.cfg`, the `default`, `cp_` and `koth_` profiles now have `autotimered` and `autotimeblue` at 30 (was 0 = never) and `autohpratiored` and `autohpratioblue` at 0.0, so a player who stays frozen for 30 seconds is respawned in their team's spawn room instead of being thawed in place. Frozen players still take no damage. Applies from the next map change.
- **Removed:** nothing. Not tested yet.

## Three community maps taken out of the pool
**Sun Oct 25, 2026 · 10:30 AM HST**
- **Removed:** `koth_coldline_b2p`, `koth_winterstorm_b3a` and `cp_coldlands_rc3` from `mapcycle.txt` and from the welcome window map list (`motd.txt`, `motd_text.txt`). The pool is back to 14 maps. The map files stay in `tf/maps/` and on the server, so they can be added back by putting their names in those three files.
- **Changed:** nothing else. Not tested yet.

## Three community snow maps added
**Sun Oct 25, 2026 · 10:30 AM HST**
- **Added:** the community snow maps `koth_coldline_b2p`, `koth_winterstorm_b3a` and `cp_coldlands_rc3` (sent by Ryan), stored packed in `tf/maps/` (`*.bsp.bz2`, about 79 MB together), in `mapcycle.txt` and in the welcome window map list (`motd.txt`, `motd_text.txt`). The map pool is now 17 maps. They use the existing `koth_` and `cp_` profiles.
- **Changed:** `deploy.yml` now sends every `tf/maps/*.bsp.bz2` file to the server and unpacks it there (only when the packed file is newer than the unpacked map).
- **Removed:** nothing. Not tested yet. Players without a map download it from the server when they join, which can be slow for these big maps.

## Round limit back to 10
**Sun Oct 25, 2026 · 10:20 AM HST**
- **Changed:** in `freezetag_maps.cfg`, the round limit per map (`maxrounds`) is back to 10 in every profile (it was 30 for a short while). The plugin also uses this number as the win limit. Applies from the next map change.
- **Removed:** nothing. Not tested yet.

## More snowy control point and king of the hill maps
**Sun Oct 25, 2026 · 10:25 AM HST**
- **Added:** 8 maps that are already installed on the server, in `mapcycle.txt` and the welcome window (`motd.txt`, `motd_text.txt`): `cp_yukon_final`, `cp_vanguard`, `cp_mountainlab`, `cp_steel`, `cp_process_final`, `koth_highpass`, `koth_overcast_final`, `koth_krampus`. The pool is now 14 maps. They use the existing `cp_` and `koth_` profiles.
- **Removed:** nothing. Not tested yet; whether each map is really snowy comes from memory and web search, not from playing them. Community-made maps (like `koth_frostwind`, `koth_coldline`, `cp_glacier`) are not added yet because they must be downloaded to the server first.

## Two more snow maps
**Sun Oct 25, 2026 · 10:20 AM HST**
- **Added:** `cp_coldfront` and `koth_winter_ridge` in `mapcycle.txt` and in the map list of the welcome window (`motd.txt`, `motd_text.txt`). The pool is now 6 maps: `cp_gravelpit_snowy`, `cp_frostwatch`, `cp_snowplow`, `cp_coldfront`, `koth_snowtower`, `koth_winter_ridge`. They use the existing `cp_` and `koth_` profiles.
- **Removed:** nothing (capture the flag and payload maps were already out). Not tested yet.

## Maps last longer
**Sun Oct 25, 2026 · 10:10 AM HST**
- **Changed:** in `freezetag_maps.cfg`, the round limit per map (`maxrounds`) went from 10 to 30 for every profile, so a map no longer ends after 10 short rounds. The plugin also uses this number as the win limit. The new limit applies from the next map change.
- **Removed:** nothing. Not tested yet.

## Frozen players no longer run in place
**Sun Oct 25, 2026 · 9:59 AM HST**
- **Changed:** in `freezetag.sp`, a frozen player's walking keys (forward, back, left, right) are now ignored, and while standing on the ground their velocity is set to zero every tick. Before, the leftover tiny velocity looked like full-speed running because their max speed is 1.
- **Removed:** nothing. Not tested yet (the build runs when merged).

## Server moved to our own VPS
**Sun Oct 25, 2026 · 9:30 AM HST**
- **Changed:** the server runs on our own VPS (1 core, 4 GB RAM, 50 GB disk) instead of WinterNode. `deploy.yml` sends files over SSH (rsync) and reloads plugins through the server console. Secrets are now `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`.
- **Added:** `vps/setup.sh` (installs TF2, Metamod, SourceMod and a `tf2` service) and `vps-tools.yml` (manual: start, stop, restart, status, logs, console command, install a package, show a file or folder, open a port, system check).
- **Removed:** `server-tools.yml` (WinterNode only) and the WinterNode secrets. TF2 install and first start not finished yet.

## Welcome screen is now the server's MOTD
**Sun Oct 25, 2026 · 5:45 AM HST**
- **Added:** `tf/cfg/motd.txt` and `tf/cfg/motd_text.txt`: the window TF2 shows when you join says "Welcome to ~*~88x31 cLuB~*~ FrEEze tAg SeRveR:  ICEY COLD Edition!", a blank line, "Freeze Tag mod with a snowy map pool:" and the 5 maps. Both files are in the deploy. The map list is typed in, so it must be updated when `mapcycle.txt` changes.
- **Removed:** the welcome popup in `88x31_settings` (back to 1.0). Not tested yet; not checked that the server uses `cfg/motd.txt`.

## Welcome screen with the map pool
**Sun Oct 25, 2026 · 5:42 AM HST**
- **Added:** `88x31_settings` is 1.1. The moment a real player joins, a window shows "Welcome to ~*~88x31 cLuB~*~ FrEEze tAg SeRveR:  ICEY COLD Edition!", a blank line, "Freeze Tag mod with a snowy map pool:" and the map pool (read from `mapcycle.txt`) for 30 seconds, with a Close button. Bots don't get it.
- **Removed:** nothing. Not compiled or tested yet (the build runs when pushed).

## One payload map
**Sun Oct 25, 2026 · 5:40 AM HST**
- **Changed:** `mapcycle.txt` has 5 maps: `cp_gravelpit_snowy`, `cp_frostwatch`, `cp_snowplow`, `koth_snowtower`, `pl_snowycoast`.
- **Removed:** `pl_frostcliff` and `pl_coal_event` from `mapcycle.txt`. Not tested yet.

## No flag maps, 5 minute payload timer
**Sun Oct 25, 2026 · 5:39 AM HST**
- **Changed:** the `pl_` profile in `freezetag_maps.cfg` has `timer` 300 (was 0), so a payload round ends after 5 minutes and the team with fewer frozen players wins.
- **Removed:** the 4 capture the flag maps (`ctf_doublecross_snowy`, `ctf_frosty`, `ctf_snowfall_final`, `ctf_turbine_winter`) from `mapcycle.txt`, which now has 7 maps. Not tested yet.

## 3 snowy payload maps added
**Sun Oct 25, 2026 · 5:37 AM HST**
- **Added:** `pl_frostcliff`, `pl_snowycoast` and `pl_coal_event` in `mapcycle.txt` (11 maps now). They use the `pl_` profile: no round timer, and a round does not end when a team is all frozen.
- **Removed:** nothing. Not tested yet; not checked that the server has the map files.

## Only snowy maps in the rotation
**Sun Oct 25, 2026 · 5:36 AM HST**
- **Changed:** `mapcycle.txt` has 8 maps: `ctf_doublecross_snowy`, `ctf_frosty`, `ctf_snowfall_final`, `ctf_turbine_winter`, `cp_gravelpit_snowy`, `cp_frostwatch`, `cp_snowplow`, `koth_snowtower`.
- **Removed:** all 28 old maps (`cp_gravelpit`, `cp_dustbowl`, `koth_viaduct`, `cp_mountainlab` and the rest). Not tested yet; not checked that the server has all 8 map files.

## Thawed players come back with 75% health, more
**Sun Oct 25, 2026 · 5:28 AM HST**
- **Changed:** `hpratiored` and `hpratioblue` are 0.75 (were 0.5, and 0.75 for Red in `pl_` and `cp_`) in all 10 profiles, so a teammate thaws you with 75% health. `cp_` now has `eliminations` 1, so a control point round ends when a whole team is frozen. `88x31.cfg` sets `sm_freezetag_thirdperson 1` (third person view while frozen), `sm_freezetag_proxpulse 0.1` (thaw rings update 10 times a second, was 0.2) and `sm_freezetag_forcecap 0` (push cap, was 500).
- **Removed:** nothing. Map settings apply from the next map; `thirdperson` and `proxpulse` should apply from the next map too (not checked). Not tested yet.

## 10 rounds per map, thaw radius 200
**Sun Oct 25, 2026 · 5:24 AM HST**
- **Changed:** `maxrounds` is 10 (was 30, and 15 in one profile) and `radius` is 200 (was 150) in all 10 profiles of `freezetag_maps.cfg`.
- **Removed:** nothing. The map now changes after 10 rounds, and a teammate can thaw you from further away. Not tested yet.

## No thawing by yourself
**Sun Oct 25, 2026 · 5:22 AM HST**
- **Changed:** `autotimered` and `autotimeblue` in `freezetag_maps.cfg` are 0 (off) in all 10 profiles (the default and 9 map profiles; they were 60, or 10 to 15 on payload and some other profiles).
- **Removed:** the automatic thaw. A frozen player now stays frozen until a teammate thaws them or the round ends. Not tested yet.

## Bots are "normal" difficulty
**Sun Oct 25, 2026 · 5:20 AM HST**
- **Changed:** `tf_bot_difficulty` in `tf/cfg/88x31.cfg` is now 1 (normal), was 2 (hard).
- **Removed:** nothing. Takes effect when the bots are next added (map change). Not tested yet.

## No penalty for joining a round in progress
**Sun Oct 25, 2026 · 5:16 AM HST**
- **Changed:** in `freezetag.sp`, a player who joins during a round now just plays, instead of being killed (and so frozen) on arrival.
- **Removed:** the "slay late joiners" step and its chat message (`feedback_joinpenalty`). The message text stays unused in `freezetag.phrases.txt`. Not tested yet.

## Frozen players are not pushed around
**Sun Oct 25, 2026 · 5:13 AM HST**
- **Added:** `sm_freezetag_forcemulti 0` in `tf/cfg/88x31.cfg`. This is a setting the plugin already had (it was 10); no code changed.
- **Removed:** the push a frozen player gets when shot. They no longer fly or bounce around from hits. Not tested yet; if they still move, the cause is something else (for example explosion knockback).

## Frozen players are held still on the ground only
**Sun Oct 25, 2026 · 5:05 AM HST**
- **Changed:** in `OnPlayerRunCmd` in `freezetag.sp`, a frozen player is set to "no movement" every tick while standing on the ground, and to walking while in the air, so the game holds them still (no sliding and snapping back) but gravity still works. `unfreezeClient` sets walking again, so nobody is left stuck.
- **Removed:** nothing. Not tested yet. Known side effect: while on the ground a frozen player can't be pushed by shots (the game ignores push speed with "no movement").

## Rounds start with no setup wait
**Sun Oct 25, 2026 · 5:01 AM HST**
- **Changed:** `preround` in `freezetag_maps.cfg` is now 0 (was 10) in the default profile and all 9 map profiles, so the round starts as soon as it loads.
- **Removed:** the 10-second setup wait before each round. That wait was also the time players had to change class, so there is no class change before a round starts now. Not tested yet.

## Frozen players fall instead of hanging in the air
**Sun Oct 25, 2026 · 4:55 AM HST**
- **Changed:** nothing new. Frozen players are held still by the zeroed walk input and speed 1 again, so gravity works and anyone frozen mid-jump falls and lands.
- **Removed:** in `freezetag.sp`, the "no movement" setting when frozen (`freezeClient`) and the "walking" setting when unfrozen (`unfreezeClient`). "No movement" also turns gravity off, which left players hanging in the air. Not tested yet; if the snap-back comes back, that is what to look at.

## Frozen in place, no snap-back
**Sun Oct 25, 2026 · 4:50 AM HST**
- **Changed:** in `freezetag.sp`, frozen players are now set to "no movement" when frozen (`freezeClient`) and back to walking when unfrozen (`unfreezeClient`), so the game holds them still instead of pulling them back after they try to move.
- **Added:** the `addadmin` action in `.github/workflows/server-tools.yml` (adds an admin to the server's `admins_simple.ini`).
- **Removed:** nothing. Not tested yet.

## Frozen players can't walk; the deploy compiles again
**Sun Oct 25, 2026 · 4:39 AM HST** (771f195)
- **Changed:** in `OnPlayerRunCmd` in `freezetag.sp`, frozen players now have their move input zeroed on every tick (before, only jumping and attacking were blocked and their speed was set every 0.2 s). The game could change their speed in between, so they could walk.
- **Added:** the compile step is back in `.github/workflows/deploy.yml` (a changed `.sp` is compiled with SourceMod 1.12 first; a failed compile sends nothing); `tf/addons/sourcemod/scripting/include/tf2items.inc` from TF2Items 1.6.4, the version that matches the server's extension.
- **Removed:** nothing. Not tested yet.

## Server tools, matching weapon numbers, SourceMod auto-update off
**Sun Oct 25, 2026 · 4:03 AM HST** (45996ef, 6c0a4d5, cf0a363 and the commits before them)
- **Added:** `.github/workflows/server-tools.yml`, started by hand only: read the server's logs, list a folder, show a file, send a console command, restart the server, make the `GiveNamedItem` numbers in the server's `tf2.items.txt` equal to the ones in `sdktools.games/game.tf.txt`, and switch off SourceMod's automatic gamedata update.
- **Changed on the server (not in this repo):** `tf2.items.txt` was 487/494, now 413/414 (the same numbers `game.tf.txt` has); `configs/core.cfg` `DisableAutoUpdate` "no" → "yes".
- **Removed:** nothing from the repo. The updater no longer rewrites `tf2.items.txt` at start-up.
- **Why:** the plugin's README says the two numbers must match, and the server log shows the updater putting 494 back at every start (00:12 and 03:53).

## Everything from tonight's plugin edit restored
**Sun Oct 25, 2026 · 3:43 AM HST** (1510e07)
- **Changed:** `deploy.yml`, `88x31.cfg`, `freezetag.sp` and `freezetag.smx` are the files from commit 92ec34f, the state before tonight's plugin edit (commit c276347 changed the first three plus this changelog). Kept: bots, no random crits and no damage spread (they were already in 92ec34f), and `server-tools.yml`.
- **Removed:** the compile-when-`.sp`-changes step from `deploy.yml` (a `.sp` change needs compiling by hand again until it is added back); the plugin settings lines I had written out in `88x31.cfg` (`sm_freezetag_model 1`, `sm_freezetag_forcemulti 10`); the rebuilt plugin file.

## Original plugin file restored
**Sun Oct 25, 2026 · 3:42 AM HST** (8ce7181)
- **Changed:** `freezetag.smx` is the exact file from commit 92ec34f (47,645 bytes), not the fresh build GitHub made from the same source (47,603 bytes). The source `freezetag.sp` was already identical to 92ec34f.
- **Removed:** the rebuilt `freezetag.smx` (commit 9e967c5).

## Plugin rolled back to before tonight's edits
**Sun Oct 25, 2026 · 3:36 AM HST** (5507a98)
- **Why:** the bots stopped moving after tonight's changes; Kura asked to roll the plugin back and change one thing at a time.
- **Removed:** the 3 edits to `freezetag.sp` (hits on frozen players do no push and no damage; no slide at freeze; no kill for joining a round in progress) and the plugin build made from them. `freezetag.sp` and `freezetag.smx` are the files from commit 92ec34f. `freezetag.smx` will be rebuilt from that source when this is pushed (the build step runs because the `.sp` changes), so it may not be byte-identical to the old file.
- **Changed:** `tf/cfg/88x31.cfg`: `sm_freezetag_model` 0 → 1 and `sm_freezetag_forcemulti` 0 → 10 (the plugin's own values; written out because a value already set on the running server stays until changed). Kept: bots, no random crits, no damage spread.

## Frozen players stay put, no join penalty, no ice block, plugin builds itself
**Sun Oct 25, 2026 · 3:17 AM HST** (c276347)
- **Changed in `tf/addons/sourcemod/scripting/freezetag.sp`:** hitting a frozen player no longer pushes them and no longer hurts them; frozen players no longer slide with the speed they had when they died.
- **Removed:** the kill and the "[Freeze]" message given to players who join while a round is running (the text `feedback_joinpenalty` stays in the phrases file, unused); the saved death speed (`g_fDeathVel`, 3 lines); the old "no push" shortcut that let damage through.
- **Added in `tf/cfg/88x31.cfg`:** `sm_freezetag_model 0` (no ice block, just the player model; applies from the next map) and `sm_freezetag_forcemulti 0` (no push).
- **Added in `.github/workflows/deploy.yml`:** when a `.sp` file changes, GitHub compiles it first and saves the built `.smx` back to the repo; if compiling fails, nothing is sent to the server. Pushes that change no `.sp` skip this step. **Removed:** nothing from the deploy.
- **Ran once (Sun Oct 25, 2026, GitHub run 40196990922):** the plugin compiled with SourceMod 1.12.0-git7255 (47,257 bytes), was sent to the server and read back identical, and both reload commands were accepted (HTTP 204). **Not tested:** how it plays in the game.

## No random crits, no damage spread
**Sun Oct 25, 2026 · 3:11 AM HST** (47eaa33)
- **Added:** `tf_weapon_criticals 0` and `tf_damage_disablespread 1` in `tf/cfg/88x31.cfg`.
- **Removed:** nothing. Not added: `tf_weapon_criticals_melee`, because its name was not confirmed.

## Bots join when the server is empty
**Sun Oct 25, 2026 · 3:06 AM HST** (f0ab6c8)
- **Changed:** `tf/cfg/88x31.cfg` line 11, `tf_bot_join_after_player` from 1 to 0. Removed: the rule that bots stay out until a real player joins. Added: nothing else; the quota stays 12 in fill mode, so bots fill the server to 12 players and leave one by one as real players join.

## Deploy over SFTP
**Sun Oct 25, 2026 · 2:59 AM HST** (e37dc58)
- **Added:** `.github/workflows/deploy.yml`. A push to `main` that changes `freezetag.smx`, `88x31_settings.smx`, `88x31.cfg` or `mapcycle.txt` sends those 4 files to the server over SFTP, checks each one arrived identical, then reloads the plugins and applies the settings.
- **Removed:** nothing.
- **Not covered:** changing `freezetag.sp` still needs compiling to `freezetag.smx` by hand.

## Header comment in 88x31.cfg
**Sun Oct 25, 2026 · 2:53 AM HST** (82665e1)
- **Changed:** the top comment of `tf/cfg/88x31.cfg`. Removed: the sentence saying GitHub uploads the file. No setting changed.

## Old upload pipeline removed
**Sun Oct 25, 2026 · 2:51 AM HST** (b58a30c)
- **Removed:** the earlier deploy (it sent files through the panel's file API, which reportedly damaged plugin files and rejected the other upload methods), the one-time test workflow, and the "Server settings and auto-deploy" section of this README.
- **Added:** nothing. The settings files stayed.

## One-time tests of the panel's file upload
**Sun Oct 25, 2026 · 2:47 AM and 2:49 AM HST** (8d0e483, bd13393; removed in b58a30c)
- **Added:** a test workflow, twice, to find out how the panel accepts files.
- **Removed:** nothing.

## Earlier deploy attempts through the panel's API
**Sun Oct 25, 2026 · 1:49 AM to 2:31 AM HST** (4352bf2, 5f4b108, a9cbdd5, d0c3c82, a37ae8b; all removed in b58a30c)
- **Added:** a GitHub Actions deploy that sent the plugin, then the settings files too (`88x31_settings.sp` and `.smx`, `88x31.cfg`, `mapcycle.txt`), through the panel's API, with 2 fallback upload methods at the end.
- **Removed:** the single-plugin upload and the `sm plugins reload freezetag` command (a9cbdd5, replaced by a loop over 4 files and `sm plugins refresh`); the plugins from the plain write loop (d0c3c82).

## Freeze Tag 1.1.4 patched for current TF2
**Sun Oct 25, 2026 · 1:42 AM HST** (9475abb)
- **Added:** the plugin, with 3 changes from the original 1.1.4: spawn points are stored as the game now hands them out (rounds could not start before), bots ignore frozen players, and frozen players stay visible. Details are in the README.
- **Removed:** nothing.
