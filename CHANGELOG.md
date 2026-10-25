# Changelog

[TF2] Freeze Tag (patched): the Freeze Tag SourceMod plugin for a modded TF2 server, plus its server settings and the push-to-update deploy. The plugin is **Freeze Tag 1.1.4 (patched)**; the settings plugin `88x31_settings` is 1.0. There are no other version numbers, so entries are named by what changed. Newest first. Times are Hawaii time (HST).

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
