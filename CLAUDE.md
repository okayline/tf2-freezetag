# Rules for this repo

This repo runs the game servers (TF2 Freeze Tag and the L4D servers). It got messy because every small
request became its own script or workflow action. These rules keep it simple.

## Ground rules

1. **Config files are the truth.** Settings (name, difficulty, map order, password, banner) live in the
   repo's config files. To change one, edit the file and deploy it. Do not write a script that edits the
   server's copy.
2. **No new script for a single change.** If the task is "set X to Y", it is a config edit. A script is
   only for something that really needs several steps, like a full install.
3. **Same setup for every server.** Servers share one base config. Each one only overrides what is
   different (name, port, mode).
4. **Few, generic workflow actions.** Keep to things like deploy, restart, console command, show log, and
   backup. Do not add a new workflow action for a one-off job.
5. **Plugins must earn their place.** Only ONE plugin may change maps. Every plugin needs a clear reason
   and one owner. Do not add a plugin to patch another plugin.
6. **Rebuild from the repo.** A server must be fully recreatable from this repo. If something lives only
   on the server, move it into the repo.
7. **Test on one server first.** Change one thing, play, then roll it out to the others.

## When asked for a small fix

Before writing any script or plugin, say whether it can be a config edit or a console command instead.
The default answer to a new script is no. If a script really is needed, say why, and delete any older
script it replaces.

## Clean-up

Now and then, look for scripts and workflow actions that have not been used and delete them.
