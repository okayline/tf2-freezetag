# Changelog

[TF2] Freeze Tag (patched): the Freeze Tag SourceMod plugin for a modded TF2 server, plus its server settings and the push-to-update deploy. The plugin is **Freeze Tag 1.1.4 (patched)**; the settings plugin `88x31_settings` is 1.0. There are no other version numbers, so entries are named by what changed. Newest first. Times are Hawaii time (HST).

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
