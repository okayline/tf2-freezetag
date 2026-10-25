# Changelog

[TF2] Freeze Tag (patched): the Freeze Tag SourceMod plugin for a modded TF2 server, plus its server settings and the push-to-update deploy. The plugin is **Freeze Tag 1.1.4 (patched)**; the settings plugin `88x31_settings` is 1.0. There are no other version numbers, so entries are named by what changed. Newest first. Times are Hawaii time (HST).

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
