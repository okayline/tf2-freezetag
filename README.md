# [TF2] Freeze Tag (patched)

Freeze Tag 1.1.4 for Team Fortress 2, a SourceMod plugin by **Friagram**
(http://steamcommunity.com/groups/poniponiponi), with fixes so it runs on current TF2.

## Changes from the original 1.1.4

All changes are in `tf/addons/sourcemod/scripting/freezetag.sp`:

- **Line 1272: spawn-point fix.** Current TF2 hands back spawn points as negative entity
  references, and the original code errored on them (`Invalid entity index` in
  `CacheSpawnPoints`). That error stopped the round from starting, so everyone stayed stuck in place.
  Now references are stored as-is.
- **Bots ignore frozen players.** When a player freezes, they get condition 66
  (`TFCond_StealthedUserBuffFade`). TF2 bots skip any enemy with that condition. It's removed on unfreeze.
- **Frozen players stay visible.** Condition 66 is normally a cloak. Every frame, the plugin keeps the
  frozen player's `m_flInvisChangeCompleteTime` 1.5 seconds ahead, which keeps their
  see-through amount at 0. It's reset to 0 on unfreeze.

Nothing was removed.

## Requirements

- SourceMod 1.12 and Metamod:Source 1.12 (older SourceMod made players hang on "Getting game info")
- TF2Items extension (1.6.4 works on the 32-bit server). Its `GiveNamedItem` number in
  `tf/addons/sourcemod/gamedata/tf2.items.txt` must match the one in
  `tf/addons/sourcemod/gamedata/sdktools.games/game.tf.txt`, or the server crashes when weapons are given out.

## Install

Copy the `tf/` folder over the server's `tf/` folder (for example `/home/container/tf/`), then in the server console:

```
sm plugins reload freezetag
changelevel cp_dustbowl
```

## Building

```
spcomp freezetag.sp -o freezetag.smx
```

This needs SourceMod 1.12's include files plus `tf2items.inc` from the TF2Items download.
