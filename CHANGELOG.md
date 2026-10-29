# Changelog

[TF2] Freeze Tag (patched): the Freeze Tag SourceMod plugin for a modded TF2 server, plus its server settings and the push-to-update deploy. The plugin is **Freeze Tag 1.1.4 (patched)**; the settings plugin `88x31_settings` is 1.0. There are no other version numbers, so entries are named by what changed. Newest first. Times are Hawaii time (HST).

## BBS: card taps rolled back, v0.90
**Thu Oct 29, 2026 · 11:23 AM HST** (committed, not pushed)

- **Removed:** the v0.87 tap rule (a tap inside a box presses the key above it). Taps are back to the v0.86 rules. Owner: "the taps are way off right now, maybe roll back one with the tap screen". Footer v0.90.
- **Kept:** the v0.88 end-screen fix and the v0.89 [B]ACK label.

## BBS: scoundrel board's back button tappable, v0.89
**Thu Oct 29, 2026 · 11:20 AM HST** (committed, not pushed)

- **Changed:** the scoundrel board's "[any key] back" is now "[B]ACK", so a tap has a key to press; any key still goes back. Owner: "on this screen i cant click [any key] to go back". Footer v0.89.
- **Removed:** the "[any key] back" label.

## BBS: scoundrel end screen fixed, v0.88
**Thu Oct 29, 2026 · 11:17 AM HST** (pushed)

- **Fixed:** the end screen stopped with "r.marks.replace is not a function": the server sends the route as a list of marks (`worker.js` runView, `[...fixMarks(run.marks)]`), and the door read it as text. It now joins the list first. Footer v0.88.
- **Removed:** nothing.

## BBS: tap a card, v0.87
**Thu Oct 29, 2026 · 11:15 AM HST** (pushed)

- **Added:** in the tap script: a tap inside a box, or on the line just under it, presses the key shown on the line above the box. scoundrel.exe's cards are boxes with `[1]` to `[4]` over them, so tapping a card takes it. It checks this before the other tap rules, so the number on a card is not pressed as a key. Owner: "can you program the clicks on the cards for scoundrel please". Footer v0.87.
- **Removed:** nothing.

## BBS: NetHack in the programs list, v0.86
**Thu Oct 29, 2026 · 11:08 AM HST** (pushed)

- **Fixed:** NetHack was not in the programs list either: its entry was `[prog:GAMES.NETHACK]`. setup.sh now writes `[prog:GAMES:NETHACK]` and removes the old entry. Owner: "i dont see nethack either". Footer v0.86.
- **Removed:** the old NetHack entry.

## BBS: tap any word of an item, scoundrel in the programs list, v0.85
**Thu Oct 29, 2026 · 11:05 AM HST** (pushed)

- **Changed:** the tap script finds an item's key from any word of it: it looks left from the tap and now also right, so "Get" in "Get [I]nfo" presses I. A word whose key letter is in its own colour with no brackets (Synchronet's "Which or Quit" style) presses that letter. Owner: "i cant click on Q or Quit to go back on this page" and "make it so clicking the whole word is the same as the letter".
- **Fixed:** scoundrel.exe was not in the programs list: its xtrn.ini entry was `[prog:GAMES.SCOUNDREL]` with `settings = 1<<0`; Synchronet's own entries are `[prog:GAMES:CODE]` with a number. setup.sh now writes it that way and removes the old entry. Footer v0.85.
- **Removed:** the v0.83 scoundrel entry.

## BBS: scoundrel door file copied, v0.84
**Thu Oct 29, 2026 · 10:58 AM HST** (pushed)

- **Fixed:** setup.sh did not copy the scoundrel door (v0.83): it moves into /sbbs before that line, so the repo's folder was looked for in the wrong place. It now remembers the repo's bbs folder (`HERE`) first. Footer v0.84.

## BBS: scoundrel.exe door, v0.83
**Thu Oct 29, 2026 · 10:50 AM HST** (pushed)

- **Added:** a scoundrel.exe door in the programs menu (`bbs/xtrn/scoundrel.js`, installed by setup.sh as `[prog:...SCOUNDREL]`). It plays today's daily deck from scoundrel.88x31.app: the same run, deck and leaderboard as the website. Screens: title, the room (HP, blade, deck counts, the four cards with what taking each does), the end (score, route) and the board. Keys `[1-4]` take, `[B]` bare hands, `[S]` skip, `[Q]` quit.
- **Accounts:** the door signs in as the BBS user's 88x31 account (`accountOf('bbs', user)`); a user with no account gets one, linked to them. scoundrel.exe's new `POST /api/bbs-enter` (scoundrel.exe v0.9.6) gives that account's player and a token, kept in `data/scoundrel/`. Owner: "the accounts this bbs uses should be the same as scoundrel".
- **Changed:** the tap script also takes digits as keys, so `[1]` to `[4]` can be tapped. Footer v0.83.
- **Removed:** nothing.
- Needs scoundrel.exe v0.9.6 pushed and its `ACCOUNTS_KEY` secret (set by the owner).

## BBS: no time limit, v0.82
**Thu Oct 29, 2026 · 10:22 AM HST** (pushed)

- **Changed:** every user and every new user also gets Synchronet's T exemption (no time-per-day or time-per-call limit), next to the v0.81 L exemption. Owner: "remove the time limit too please". Footer v0.82.

## BBS: no logon limit, v0.81
**Thu Oct 29, 2026 · 10:20 AM HST** (pushed)

- **Changed:** every user and every new user gets Synchronet's L exemption (no logons-per-day limit). Users are level 50, which allowed 50 logons a day, and every page reload is a logon. Time-per-day limits are unchanged. Owner: "can you please remove logon limit". Footer v0.81.

## BBS: tap anywhere at [Hit a key] removed, v0.80
**Thu Oct 29, 2026 · 10:16 AM HST** (pushed)

- **Removed:** the v0.77 rule in the tap script that sent Enter on any tap when the cursor's line showed [Hit a key]. Taps on menu letters and the phone keyboard work as before. Owner: "remove 'tap anywhere to hit a key' please". Footer v0.80.

## BBS: taller font removed, v0.79
**Thu Oct 29, 2026 · 10:14 AM HST** (pushed)

- **Removed:** the forced 8x16 font (v0.78); fTelnet picks its font to fit the window again. Owner: "can we remove the taller font please". Footer v0.79.

## BBS: taller lines with the 8x16 VGA font, v0.78
**Thu Oct 29, 2026 · 10:15 AM HST** (pushed)

- **Changed:** the web terminal always uses the 8x16 CP437 font (`Options.Font = 'CP437_8x16'`). fTelnet picked a font to fit the window, which with 45 lines (and on phones) meant a small, squat one scaled up, so lines looked crowded. Each line is now twice as tall as a character is wide; real font, not a stretched picture. The terminal is taller, so it may need more scrolling on a phone. Owner: "the text looks too crowded vertically". Footer v0.78.

## BBS: tap anywhere at [Hit a key], v0.77
**Thu Oct 29, 2026 · 10:12 AM HST** (pushed)

- **Added:** in the tap script: when the cursor's line shows Synchronet's [Hit a key] pause, a tap or click anywhere on the terminal continues (sends Enter), on phones and desktop. Owner: "for the two [Hit a key] screens when you log in, could it be click anywhere to continue?". Footer v0.77.

## BBS: phone keyboard no longer pushes the terminal out of view, v0.76
**Thu Oct 29, 2026 · 10:10 AM HST** (pushed)

- **Fixed:** when the phone keyboard opened, the phone scrolled to the hidden text field at the bottom and pushed the terminal off screen. The field is now at the top and takes focus without scrolling; once the keyboard is up the page scrolls so the terminal's cursor line sits just above it, and again as you type. Closing the keyboard scrolls back to the top. Owner: "when the phone keyboard pops up, it pushes the screen up and out of view". Footer v0.76.

## BBS: terminal 45 lines tall, v0.75
**Thu Oct 29, 2026 · 10:07 AM HST** (pushed)

- **Changed:** the web terminal is 45 lines tall (was 40), still 80 columns. Owner: "could you give us a few more lines vertically please". Footer v0.75.

## BBS: phone keyboard stays open, v0.74
**Thu Oct 29, 2026 · 10:06 AM HST** (pushed)

- **Fixed:** tapping an empty spot made the phone keyboard flash on and off. The text field took focus on the tap's first event and the phone's follow-up mousedown took it away again. It now takes focus on the tap's last event (click), and mousedown on the terminal no longer moves focus (phones only). Owner: "it like flashes on and off when i tap an empty space". Footer v0.74.

## BBS: phone's own keyboard instead of the on-screen one, v0.73
**Thu Oct 29, 2026 · 10:04 AM HST** (pushed)

- **Removed:** fTelnet's on-screen keyboard on phones (`Options.VirtualKeyboardVisible = false`).
- **Added:** in the tap script, on phones only: tapping the terminal anywhere but a menu letter brings up the phone's own keyboard (an invisible text field takes focus); what you type is sent on as keys, including Enter and Backspace. Owner: "is there a way to use the users keyboard, maybe with the tap screen script?". Footer v0.73.
- **Not changed:** desktop works as before.

## BBS: no Forum link, bigger BBS name, v0.72
**Thu Oct 29, 2026 · 10:00 AM HST** (pushed)

- **Removed:** the Forum link from the top bar (the forum page itself is still there).
- **Changed:** the BBS name at the top left is 24 pixels (was 20). Owner: "get rid of menu item Forum, and make ~*~88x31~*~ part a little bigger". Footer v0.72.

## BBS: your name smaller in the top bar, v0.71
**Thu Oct 29, 2026 · 9:59 AM HST** (pushed)

- **Changed:** your name at the top right is 16 pixels; the rest of the top bar and its drop-down menu stay 20 pixels. Owner: "could we have the name be smaller please". Footer v0.71.

## BBS: arrow mouse pointer over the terminal, v0.70
**Thu Oct 29, 2026 · 9:58 AM HST** (pushed)

- **Changed:** the mouse shows the normal arrow over the terminal instead of the text bar. Owner: "could you have the mouse change to the pointer instead of the text input bar". Footer v0.70.
- **Changelog:** v0.66 to v0.69 marked pushed.

## BBS: bigger top bar text, smaller footer text, v0.69
**Thu Oct 29, 2026 · 9:57 AM HST** (pushed)

- **Changed:** the top bar text is 20 pixels (was 16) and the footer line is 12 pixels, the same sizes tried in v0.65 before the rollback. Owner: "make the header row text bigger and the footer text row smaller please". Footer v0.69.

## BBS: tap a menu letter, fixed, v0.68
**Thu Oct 29, 2026 · 9:56 AM HST** (pushed)

- **Added back:** the v0.61 tap script and the v0.62 line that puts the terminal on `window`. Tapping or clicking a menu letter, or the words of its item, presses that key: it reads whatever is on screen at the tapped spot, so no screen needs a map. Owner: the tap screen is the better way. Footer v0.68.
- **Fixed:** why it never worked. fTelnet keeps its terminal at `fTelnet._Crt`; the old script waited for `fTelnet.Crt`, which does not exist, so it never hooked in. It now also uses fTelnet's own mouse-to-cell function, which allows for the scrollback area the old math left out.
- **Not changed:** no click spots; mouse setting stays off.

## BBS: terminal stretch removed, v0.67
**Thu Oct 29, 2026 · 9:49 AM HST** (pushed)

- **Removed:** the script that stretched the terminal picture 25% taller (v0.64). The terminal is back to its normal proportions, still 80 columns by 40 lines. Owner: "can we reverse the canvas stretch too please". Footer v0.67.

## BBS: tap script removed, v0.66
**Thu Oct 29, 2026 · 9:48 AM HST** (pushed)

- **Removed:** the tap/click-a-menu-letter script from the home page (v0.61) and the line that put the terminal on `window` for it (v0.62). It never worked on the live site. Owner: "can we remove the tap script maybe". Footer v0.66 (v0.65 was the rolled-back text sizes).
- **Not changed:** mouse click spots stay off in the menus and the mouse setting stays off for every user (v0.60).

## BBS: text sizes tried and rolled back, v0.65
**Thu Oct 29, 2026 · 9:40 AM HST** (pushed)

- **Added, then removed:** the top bar text at 20 pixels and the footer line at 12 pixels (v0.65). Owner: "roll back one". It was undone with a new commit, so the BBS is on v0.64 again and its footer says v0.64.
- **Removed:** the v0.65 text-size rule from the site's CSS.

## BBS: taller letters, v0.64
**Thu Oct 29, 2026 · 9:38 AM HST** (pushed)

- **Added:** a small script on the home page that stretches the terminal picture 25% taller at the same width (still 80 columns by 40 lines). Footer v0.64.
- **Removed:** nothing.

## BBS: line above the footer gone, v0.63
**Thu Oct 29, 2026 · 9:34 AM HST** (pushed)

- **Changed:** the thin white line above the footer has no border and no height. Owner: "footer line is gone !". Footer v0.63.
- **Removed:** the line.

## BBS: terminal reachable for the tap script, v0.62
**Thu Oct 29, 2026 · 9:34 AM HST** (pushed)

- **Changed:** the home page puts the terminal on `window` (the page kept it in a local variable, so the v0.61 script could not find it); the script also accepts the Unicode box characters. Footer v0.62.
- **Not working:** taps and clicks on menu letters still did nothing on the live site after this. Owner: "taps dont work, but dont worry about it anymore please". The script is still in the page; the cause was not looked into.

## BBS: tap or click a menu letter, v0.61
**Thu Oct 29, 2026 · 9:30 AM HST** (pushed)

- **Added:** a script on the home page: a tap or click on a highlighted menu letter, or on a word of its item, was meant to press that key, by reading the tapped cell from the terminal. It never worked on the live site (see v0.62). No new buttons or boxes. Footer v0.61.
- **Removed:** nothing.

## BBS: no click spots, v0.60
**Thu Oct 29, 2026 · 9:25 AM HST** (pushed)

- **Removed:** the mouse click spots from bbs/menu/main.msg, main.40col.msg and maininfo.msg, and the mouse setting that setup.sh switched on for every user and for new users (it now switches it off). Owner: "let's not use click spots please". Footer v0.60.
- **Changed:** nothing else; the menus look the same.

## BBS: no border around the terminal, v0.59
**Thu Oct 29, 2026 · 9:21 AM HST** (pushed)

- **Added:** a CSS rule removing any border, outline and shadow on the terminal and its parts. It changed nothing you could see: the line the owner meant was the one above the footer (v0.63). Footer v0.59.

## BBS: footer text on the right, v0.58
**Thu Oct 29, 2026 · 9:18 AM HST** (pushed)

- **Changed:** the footer text is on the right, right under the line, with the big gap gone (a CSS rule on the footer). Owner: "footer is good". Footer v0.58.

## BBS: a dot between Main and the time, v0.57
**Thu Oct 29, 2026 · 9:16 AM HST** (pushed)

- **Added:** the small cyan dot between "Main" and the time in the prompt (ctrl/text.ini). Owner: "the dot is good". Footer v0.57.

## BBS: the main menu without four options, v0.56
**Thu Oct 29, 2026 · 9:14 AM HST** (pushed)

- **Removed:** [T]ransfer Files, [G]eneral Text File Area, Get [Q]WK and List [U]sers from the 80-column main menu (the keys still work if typed), as in v0.40. The columns close up and the sysop [!] sits at the bottom of the right column. Footer v0.56.
- **Changed:** bbs/menu/main.msg is rebuilt from Synchronet's own 80-column menu.

## BBS: prompt colours fixed, v0.55
**Thu Oct 29, 2026 · 9:11 AM HST** (pushed)

- **Fixed:** the prompt showed `^An ^Ac^Ah` as plain text after "Main" (v0.52 wrote the colour codes as text instead of the real control characters). Footer v0.55.

## BBS: logon screen back to Synchronet's own, v0.54
**Thu Oct 29, 2026 · 9:08 AM HST** (pushed)

- **Removed:** the three settings that made the logon screen fit 40 columns (the one-line caller list, the avatar above the box, and the avatar position), so Synchronet's own logon screen is back: full caller columns, avatar to the right. Footer v0.54.

## BBS: clickable menus at 80 columns, v0.53
**Thu Oct 29, 2026 · 9:08 AM HST** (pushed)

- **Added:** bbs/menu/main.msg, Synchronet's own 80-column main menu with a mouse click spot on each single key letter (21, counting the sysop [!]); the click spots in bbs/menu/maininfo.msg (Get Info: Y, I, V, S, Q). Footer v0.53.
- **Removed:** nothing. The two-key cells (/A, /L, ^K) are not clickable. main.40col.msg stays, but only a 40-column terminal shows it now.

## BBS: "Main" back in the prompt, v0.52
**Thu Oct 29, 2026 · 9:03 AM HST** (pushed)

- **Changed:** the main prompt shows "Main" again before the time, with a space after it (ctrl/text.ini [default.js]). Footer v0.52.
- **Removed:** the `Main = ^An` line that blanked the label (it was there to fit 40 columns).

## BBS: taller terminal, v0.51
**Thu Oct 29, 2026 · 9:00 AM HST** (pushed)

- **Changed:** the web terminal is 40 lines tall (was 25), still 80 columns. Footer v0.51.
- **Removed:** nothing.

## BBS: back to 80 columns, v0.50
**Thu Oct 29, 2026 · 8:56 AM HST** (pushed)

- **Changed:** the web terminal is 80 columns again, like telnet. The home page is restored from its saved copy on every run, so nothing else is needed. Footer v0.50.
- **Removed:** the line in setup.sh that set the web terminal to 40 columns. bbs/menu/main.40col.msg and bbs/text/answer.40col.msg stay in the repo, but only a 40-column terminal shows them now.

## BBS: tidier logon screen, v0.49
**Thu Oct 29, 2026 · 8:33 AM HST** (pushed)

- **Changed:** "Last few callers" is one short line per caller (name, time, how they connected), set in modopts.ini [logonlist] last_few_callers_fmt.
- **Removed:** the node, call number, location and logons-today columns from that list; the avatar drawn to the right of the stats box (it's above it now). Footer v0.49.

## BBS: space under the top bar, v0.48
**Thu Oct 29, 2026 · 8:27 AM HST** (pushed)

- **Changed:** one empty line (16 more pixels) under the web top bar. **Removed:** the old 10-pixel gap. Footer v0.48.

## BBS: no pause on the connect screen in the web terminal, v0.47
**Thu Oct 29, 2026 · 8:26 AM HST** (pushed)

- **Added:** bbs/text/answer.40col.msg, the connect screen for 40-column terminals; setup.sh copies bbs/text into the BBS's text folder.
- **Removed:** the big Synchronet logo from that screen at 40 columns, so it fits 25 lines and doesn't stop at [Hit a key]. Telnet (80 columns) keeps the full screen. Footer v0.47.

## BBS: Your statistics in one column, v0.46
**Thu Oct 29, 2026 · 8:19 AM HST** (pushed)

- **Added:** bbs/menu/userinfo.msg, the Your statistics screen with one item per line so it fits 40 columns.
- **Removed:** the stock 3–4-columns-per-line layout (it wrapped at 40 columns). Telnet users see the one-column version too. Footer v0.46.

## BBS: "Logged in as" moved to Get Info, v0.45
**Thu Oct 29, 2026 · 8:16 AM HST** (pushed)

- **Added:** bbs/menu/maininfo.msg (the stock Get Info menu) with a "Logged in as <name>" line at the top; setup.sh now copies every menu in bbs/menu.
- **Removed:** the user name under the BBS name on the main menu. Footer v0.45.

## BBS: a dot before the time in the prompt, v0.44
**Thu Oct 29, 2026 · 8:13 AM HST** (pushed)

- **Added:** a small cyan dot (CP437 ∙) at the start of the main prompt. **Removed:** nothing. Footer v0.44.

## BBS: space after the time in the prompt, v0.43
**Thu Oct 29, 2026 · 8:12 AM HST** (pushed)

- **Changed:** the prompt text starts with a color code, then the space (the ini file dropped a leading space, so the time ran into "[1]"). **Removed:** nothing. Footer v0.43.

## BBS: user name on the main menu, v0.42
**Thu Oct 29, 2026 · 8:11 AM HST** (pushed)

- **Added:** the signed-in user's name, centered under the BBS name on the 40-column main menu. **Removed:** nothing. Footer v0.42.

## BBS: one-line prompt, menu colors fixed, v0.41
**Thu Oct 29, 2026 · 8:08 AM HST** (pushed)

- **Added:** bbs/ctrl/text.ini (custom text for Synchronet's scripts), copied to ctrl/text.ini by setup.sh.
- **Removed:** "■ Main ■" and the line break from the main prompt; it is now the time left, then group and area on one line.
- **Changed:** the last two menu lines are bright again (v0.40 left them dim). Footer v0.41.

## BBS: shorter main menu, v0.40
**Thu Oct 29, 2026 · 7:59 AM HST** (pushed)

- **Removed:** [T]ransfer Files, [G]eneral Text File Area, Get [Q]WK and List [U]sers from the 40-column main menu (the keys still work if typed).
- **Changed:** Log [O]ff moved up a line; the sysop-only [!] menu item is on the Chat line. Footer v0.40.

## BBS: user menu in the top bar, no User page, v0.39
**Thu Oct 29, 2026 · 7:56 AM HST** (pushed)

- **Added:** the user name on the right of the top bar ("Guest" when not signed in); clicking it opens a small menu: Log in with passkey, Link passkey (only when not linked yet), Log out.
- **Removed:** the User page and its links (Mail, Register, BBS List and the sysop pages); "User" in the top bar. Footer v0.39.

## BBS: DOVE-Net connected, v0.38
**Thu Oct 29, 2026 · 7:47 AM HST** (pushed)

- **Added:** the stock VERT hub is turned on with the BBS's Vertrauen QWK password (repo secret DOVE_PASS, never printed); vps-tools passes it to the server like BBS_SYSPASS.
- **Removed:** the placeholder password in the hub's call-out line. Footer v0.38.

## BBS: no Files web page, v0.37
**Thu Oct 29, 2026 · 7:33 AM HST** (pushed)

- **Removed:** the web Files page (the file areas are still on the BBS menu under [T]ransfer Files). Footer v0.37.

## BBS: User page trimmed, v0.36
**Thu Oct 29, 2026 · 7:33 AM HST** (pushed)

- **Removed:** the web Games page (its door programs are still on the BBS menu under [X]ternal programs).
- **Changed:** User List is sysop-only (level 90) instead of every signed-in user. Footer v0.36.

## BBS: click the menu letters in the web terminal, v0.35
**Thu Oct 29, 2026 · 7:31 AM HST** (pushed)

- **Added:** bbs/menu/main.40col.msg, Synchronet's 40-column main menu with a click spot on each key letter; setup.sh copies it over the stock one.
- **Added:** the mouse flag (MOUSE) is on for every user and for new users, next to the spinning cursor.
- **Removed:** nothing. Other screens stay keyboard-only. Footer v0.35.

## BBS: 24-hour time, v0.34
**Thu Oct 29, 2026 · 7:25 AM HST** (pushed)

- **Added:** Synchronet's 24-hour time setting (SM_MILITARY) is turned on. **Removed:** am/pm times. Footer v0.34.

## BBS: 40-column web terminal, bigger letters, v0.33
**Thu Oct 29, 2026 · 7:19 AM HST** (pushed)

- **Removed:** the 40-line terminal (back to 25 lines).
- **Added:** the web terminal is 40 columns wide, so letters are twice as big; Synchronet's stock 40-column main menu shows. Screens made for 80 columns may wrap. Footer v0.33.

## BBS: smooth letters again, v0.32
**Thu Oct 29, 2026 · 7:15 AM HST** (pushed)

- **Removed:** `image-rendering:pixelated` on the terminal. Since v0.31 the font is smaller, and stretching it with sharp pixels made the letters jagged.
- **Changed:** the stretched terminal is smoothed by the browser. Footer v0.32.

## BBS: terminal fits the window on first load, v0.31
**Thu Oct 29, 2026 · 7:14 AM HST** (pushed)

- **Removed:** the fixed 12x23 font (`CP437_12x23`). fTelnet uses a font name with a size at exactly that size, so the terminal started too big; a resize then switched to the best fit.
- **Changed:** the terminal uses plain `CP437`, so fTelnet picks the size that fits the window from the start, the same as after a resize. Footer v0.31.

## BBS: clean-up of the earlier work, v0.30
**Thu Oct 29, 2026 · 7:13 AM HST** (pushed)

- **Removed:** three copies of the code that fills in a new user's fields (web page account, passkey login, "New"). **Added:** one `fillUser()` in mods/rollname.js that all three use.
- **Removed:** the "only add once" checks on the site's extra CSS, so edits in the repo never reached the site. **Changed:** custom.css lines are taken out and written fresh on every run.
- **Removed:** the parked Recent Visitors files (webv4-sidebar-removed); they are deleted now.
- Footer v0.30.

## BBS: passkey sign-ups get the same names as everyone else, v0.29
**Thu Oct 29, 2026 · 7:11 AM HST** (pushed)

- **Removed:** `freshName()` and its own word lists in api/passkey.ssjs (names like `BraveOwl123`).
- **Changed:** a new user made by a passkey sign-in gets a rolled name from `rollName()` (like `Quiet Heron`), the same as the web page and "New". Footer v0.29.

## BBS: no _ cursor in the browser terminal, v0.28
**Thu Oct 29, 2026 · 7:08 AM HST** (pushed)

- **Removed:** the old cursor patch (it sent every blink to the wrong handler, so the `_` was drawn and never erased: a frozen `_`).
- **Added:** the `_` bar is drawn see-through instead, so only Synchronet's spinning cursor shows. Blinking text still blinks.
- **Changed:** footer v0.28; the terminal script link ends in `-nocursor2` so browsers fetch the new copy.

## BBS: terminal size tries, back to the full-width look, v0.20 to v0.27
**Thu Oct 29, 2026 · 6:35 AM – 6:50 AM HST** (commits ceab526 … 049be4d, pushed and applied)

- **Changed:** the terminal is stretched to the page width and uses the biggest letters (12x23). On screen the letters are the same size as with any font (80 columns always fill the width); the bigger font is just smoother. v0.20 used the 8x16 letters (blockier); v0.21 switched to 12x23.
- **Changed:** the footer is v0.27 (`049be4d`). v0.27 is v0.24 put back: the full-width look of v0.21.
- **Removed:** four things tried and taken out again: a 960-pixel width limit (v0.22), a 480-pixel limit with a width rule for the boxes around the terminal (v0.23), a frame width rule (v0.25) and a window resize sent after the page loads (v0.26). The 8x16 letters (v0.20) and the footer's v0.19 are gone too. v0.24 and v0.27 were made by undoing the earlier ones as new steps, so v0.22 to v0.26 are still in the history.
- **Known:** the terminal starts too big and sticks out on the right until the window is resized once. Not fixed.

## BBS: spinning cursor for everyone, 40-line terminal, v0.19
**Thu Oct 29, 2026 · 6:23 AM – 6:25 AM HST** (commits 6a629e4, 681c7be, e8e7383, pushed and applied; the BBS was restarted)

- **Added:** the spinning cursor is on for every user (user setting "spinning cursor", set by `bbs/setup.sh`).
- **Changed:** new users start with it on (`main.ini` new-user settings `0x6910` to `0x6930`). Rolled accounts used to be made with it off, so they saw only a still `_`. The web terminal is 40 lines tall instead of 25 (still 80 columns). The footer is v0.19.
- **Removed:** new users starting with the spinning cursor off, the 25-line terminal, and the footer's v0.18. A rule that shrank the terminal in a narrow window (e8e7383) was replaced by the stretch-to-width rule above.

## BBS: User page, Log out, fewer links, v0.14 to v0.18
**Thu Oct 29, 2026 · 5:57 AM – 6:17 AM HST** (commits 965c38e … f70b40b, pushed and applied)

- **Added:** a "User" page (`pages/900-user.xjs`, was "Stuff"): who you are logged in as (with the unread mail count), Link passkey, Sign in with passkey, Log out, and links to every other page. On the terminal page, Forum and User open in a panel where the terminal was; the terminal is only moved out of sight, so it stays connected. The BBS name brings it back without a reload.
- **Changed:** like aura-farm v0.21, each browser keeps its own account: Log out goes back to it, and a new one is made only if it was deleted. After a passkey sign-in the whole page reloads, so the terminal logs in as that user too. The top links are the BBS name, Forum and User. The footer is v0.18.
- **Removed:** the Home link, the "Sign in" link at the top right, your name and Link passkey from the top links, the second passkey link on the home page, the code that made a passkey sign-in re-point the browser's account (the page never sent it), `pages/900-stuff.xjs`, and the footer's v0.13.

## BBS: 10 nodes, all-black page, text links, DOS font, v0.13
**Thu Oct 29, 2026 · 5:45 AM – 5:53 AM HST** (commits 5ff1db5 … 42eb93a, pushed and applied; the BBS was restarted at 5:53 AM)

- **Added:** nodes 5 to 10, so 10 people can be on at once (`bbs/setup.sh`: `LastNode = 10`, folders `node5` to `node10`, their lines in `main.ini`). The page text uses the same DOS letters as the terminal: the "Web437 IBM VGA 8x16" web font by VileR (int10h.org, CC BY-SA 4.0), kept with its license in `/fonts` on the BBS site.
- **Changed:** the page is all black (top bar, page and footer) so it blends with the terminal, which keeps its thin border. The top menu bar is now one row of plain text links. The passkey sign-in links, which only existed on the server, are now in the repo (`components/navbar.xjs` made by `bbs/setup.sh`). The footer is v0.13.
- **Removed:** the 4-node limit, the dark grey fixed menu bar with its dropdowns and phone menu button, and the footer's v0.12.

## BBS: our own web terminal, no Bulletins screen, no blinking text, v0.10 to v0.12
**Thu Oct 29, 2026 · 5:25 AM – 5:41 AM HST** (commits 84b2b90 … b87d93f, pushed and applied; the BBS was restarted at 5:41 AM)

- **Added:** a copy of the web terminal (fTelnet: its script, styles, keyboard styles, fonts and proxy list) on our own site at `bbs.88x31.app/ftelnet`, made by `bbs/setup.sh`. The home page loads it from there. It loads faster.
- **Changed:** after logging in you go straight to the main menu; BullsEye Bulletins is still in the programs menu (its logon event in `xtrn.ini` is off). Our copy of fTelnet has its blink timer patched so blinking text (the BBS's `_`) no longer blinks. The home page links the terminal as `?v=2026-01-16-nocursor` so browsers load the patched copy. The footer is v0.12.
- **Removed:** loading the terminal, its fonts and its proxy list from `embed-v2.ftelnet.ca`, the Bulletins screen at every logon, and the footer's v0.9. v0.11 went out only to put the version number right after two changes had been pushed without a bump.

## BBS: no Login on the web page, v0.9
**Thu Oct 29, 2026 · 5:16 AM HST** (commit eb908c4, pushed and applied)

- **Added:** web visitors who are not signed in get a BBS account with a rolled name automatically. A key kept in their browser finds the same account when they come back. Signing in with a passkey points that key at the passkey account. The passkey link stays on the page.
- **Changed:** the footer is v0.9.
- **Removed:** the Login step for web visitors. Telnet keeps its Login: prompt.

## BBS: no new-user questions, rolled names, v0.8
**Thu Oct 29, 2026 · about 4:30 AM – 5:15 AM HST** (commits 0ad32de, d6ed90d, pushed)

- **Added:** "New" at the telnet Login: rolls a two-word name (like the games) and goes straight to the main screen.
- **Changed:** the system name is `~*~88x31~*~ BbS`. The footer is v0.8. Passkey users, guests and new users are filled in (name, location, birth date, e-mail) instead of being asked.
- **Removed:** the new-user questions (name, real name, location, birth date, e-mail, terminal type), the guest name and e-mail prompts, and the "search all groups" scan questions at logon.

## BBS: passkey sign-in, automatic login on the web terminal, v0.7
**Thu Oct 29, 2026 · 3:07 AM – 4:19 AM HST** (commits 41e6c78 … bda4ec3, pushed)
- **Added:** passkey sign-in on the BBS web site (`api/passkey.ssjs`, written by `bbs/setup.sh`), through the shared Accounts service. A passkey with no BBS user gets a new one with a random name; a signed-in user can link a passkey once. The "Sign in with passkey" link only shows while the account is not linked.
- **Added:** automatic login on the web terminal. When you are signed in on the site, the page types a one-time code (22 characters, good for 60 seconds, used once) at the Login: prompt, and `mods/login.js` (a copy of the stock login plus a code check) logs you in and starts the session. Users made by passkey get a random password, so a name alone can't log in.
- **Added:** the `ACCOUNTS_KEY` repo secret. The `run` action in `vps-tools.yml` writes it to `/sbbs/ctrl/secrets/accounts-key` (readable by the `bbs` user only, never printed).
- **Changed:** the web terminal connects as soon as the page opens, and the page is silent (no terminal beeps). The stock "mybbs" names are now the real ones: address `bbs.88x31.app`, QWK ID `BBS88X31`, IRC channel `#88x31`.
- **Changed:** the page version in the footer is plain, selectable text and is rewritten on every setup run (it could not change before). Now **v0.7**.
- **Changed:** RLogin listens only on 127.0.0.1 (it listened on every address), and the BBS's own HTTPS is off so it does not fight Caddy for port 443.
- **Changed:** the `run` output filter in `vps-tools.yml` also hides IPv6 addresses.
- **Removed:** the Connect button, the red "click here to enable keyboard input" banner, the stock "mybbs" names, and the footer version rule in `custom.css` (the text replaced it). Login by RLogin (tried in v0.3 to v0.5) was dropped for the Login: prompt code in v0.6.
- **Not checked:** whether these changes were applied on the server; passkey sign-in and the automatic login in a browser.

## BBS web page: big terminal, Fullscreen, dark; BBS in the nightly backup
**Thu Oct 29, 2026 · 2:34 AM – 3:02 AM HST** (commits 0aab8bb … 2a51205, pushed and applied)
- **Added:** the BBS (`/sbbs` settings, data, text and mods) and its NetHack saves to the nightly backup (`vps/backup-setup.sh`).
- **Changed:** the BBS home page (`bbs/setup.sh`): full-width layout, no sidebar on the home page, a much bigger terminal, black page. A small Fullscreen icon sits in the terminal's lower-right corner and fits the terminal to the screen; click it again to leave. No scrollbars inside the terminal.
- **Changed:** dark mode is on by default and the Dark/Light switch is hidden (`css/custom.css`). On phones the Sidebar button and the sliding sidebar are hidden.
- **Removed:** the Recent Visitors block from the sidebar (files kept in `/sbbs/webv4-sidebar-removed`).
- **Added:** page version **v0.1**, shown in the footer next to the year.
- **Removed:** the Fullscreen icon and its scripts (`bbs/setup.sh`), at the owner's request. The page keeps the big terminal, black page and no scrollbars.
- **Applied:** `bbs/setup.sh` with `SKIPBUILD=1` through the `run` action. No game server or BBS restart.

## 88x31 BBS at bbs.88x31.app
**Thu Oct 29, 2026 · 1:50 AM – 2:28 AM HST**
- **Added:** a Synchronet bulletin board, "88x31 BBS" (`bbs/setup.sh`, service `sbbs`). Connect with telnet or SyncTERM to `bbs.88x31.app`, or open https://bbs.88x31.app in a browser. Message boards, chat and NetHack as a door game. Runs at low priority with a memory cap.
- **Added:** `bbs.88x31.app` in `vps/Caddyfile` (the web site and its browser terminal).
- **Changed:** the game servers were stopped for about 10 minutes while the BBS was built, then started again. Nothing was removed.

## OpenRA Red Alert server
**Thu Oct 29, 2026 · HST**
- **Added:** `openra/setup.sh`: installs the OpenRA Red Alert dedicated server (latest release, unpacked AppImage) in `/home/tf2/openra`, service `openra`, port 1234/tcp, named "88x31 | Red Alert | US West", listed on the public OpenRA server list. No game files needed. Runs at lower priority (nice 5) with a 400 MB memory cap so TF2 and L4D stay smooth. Install: `run` action with `curl -fsSL https://raw.githubusercontent.com/okayline/tf2-freezetag/main/openra/setup.sh | bash`.

## TF2 sleeps when empty
**Thu Oct 29, 2026 · HST**
- **Changed:** TF2 is named "88x31 | Freeze Tag | US West | Snow Maps". It runs 8 bots (4v4), and they only join once a real player is on (`tf_bot_join_after_player 1`).
- **Changed:** the nightly backup also covers TF2's `tf/logs` and `tf/custom`.

## Vanilla friendly fire; live log writing; one-by-one Discord posts; new chapter card; story series numbers
**Wed Oct 28, 2026 · 10:27 PM – 11:50 PM HST** (commits 80b5f90 … 3489d8c)
- **Removed:** Reverse FF on every L4D server (`REVERSE_FF=0` in `l4d/servers/*.conf`). Friendly fire is vanilla again: the victim takes normal damage for the lobby's difficulty, nothing is reflected and nobody is kicked for it. It had kicked a Tank player, split a lobby with a ban and incapped and kicked the owner, and never caught a griefer. Unloaded live with `sm plugins unload` and its file moved to `plugins/disabled` (no restarts). Before that, the same night: bots no longer counted (`reverseff_bot "0"`), reflected damage 75%, kick at 400; those settings stay in `l4d/base/reverse_ff.cfg` in case it comes back. Its kick cannot work with reflected damage at 0 (it adds up the reflected amount), so "normal FF plus a kick" would need our own code.
- **Changed:** welcome pages (`l4d/motd/motd.txt`, `motd-vs.txt`): the last line is now "Vanilla Friendly Fire Behavior ❀ Have fun!!". Applied with the `motd` action (classic, versus) and by hand on vintage, whose title was briefly overwritten with classic's and then put back to "~*~88x31~*~ L4D ViNtaGe Edition".
- **Added:** `sv_logflush 1` in `l4d/base/server.cfg`: the game writes each log line right away instead of in chunks (versus went from 1 write in 40 seconds to 21 in 30). Set live with the console and in each server's server.cfg.
- **Changed:** Discord feed posts one event per message, at most one every 2.5 seconds (`GAP` in `vps/discord-feed-l4d.py`); when events pile up, the waiting ones go out a few together. Item pickup posts are off. Grab, pounce and puke posts name the infected player ("Chu Haur grabbed Wenus_Boi"). Repeated map, round start, finale and mission-lost lines are skipped.
- **Changed:** the chapter stats post is now a Discord card (embed): MVP, first into the safe room and how many made it, Tank time, Witches and one-shot kills, who startled her, and per player: fighting, helping, rough moments, items, safe room place and time on.
- **Added:** `series` column on the `stories` table (items-db): a chapter's number within its level, the same as the "#N" in its title. Chapters already saved keep it empty (the table refuses edits); new chapters fill it. Checked first that the ledger only fingerprints title and body, so sealed chapters are unaffected; all 8 sealed chapters were re-checked and still match. `l4d/stories/WRITER.md` saves it.
- **Changed:** `l4d/stories/WRITER.md` has a reference of how the four survivors look in Left 4 Dead, with a gate check that any description matches; there is no rule asking for descriptions.
- **Not checked:** item, witch and tank card lines on a long live round; how the chapter card looks after the feed runs a full night without restarts (time-on resets when the feed restarts).

## L4D event log; richer Discord feed; versus teams kept across campaigns; ads every 65 minutes
**Wed Oct 28, 2026 · 9:35 PM – 10:25 PM HST** (commits 1542a81 … 77bc00c)
- **Added:** `l4d/scripting/l4d_eventlog.sp`: writes round events into the game log as `[88x31ev]` lines: heals, revives, closet rescues, pills, incaps, ledge grabs, deaths (weapon, headshot), pounces, smoker grabs, boomer vomit, witch startled and killed (one shot or not), tank spawned and killed (how long it lived), safe room arrivals in order, round start and end, finale won, mission lost. Players appear as `<id> "name" (survivor or infected class)`. Only writes to the log, never changes gameplay. Switched on with `EVENTLOG=1` in `l4d/servers/*.conf` (on for classic, versus and vintage; `deploy.sh` adds it to the plugin list). Loaded live on all three servers with `sm plugins load` (no restarts); the next deploy makes it permanent.
- **Added, then taken out:** team-keeping in `l4d_campaign_rotate` (remember each versus player's team before a campaign change and put them back after). Taken out before it ever went live, while the owner decides how to handle uneven teams like a 4v1 (the code is in commit 4451658 if wanted later).
- **Added:** Discord feed (`vps/discord-feed-l4d.py`) posts from the event log: heals, revives and ledge pull-ups, closet rescues, boomer pukes, smoker grabs and pounces (with the infected player's name, e.g. "Chu Haur grabbed Wenus_Boi"; bots stay "A Hunter"), witch startled and killed (one shot), tank down with how long it lasted, first into the safe room, finale won, mission lost. Bot-on-bot events are skipped. **Removed:** the old pounce and smoker posts from the game's own log (no name, and they would have doubled). Applied with the `discord` action, job `feed`.
- **Fixed:** Discord feed no longer says "killed **a** Justin18" when the infected is a real player in versus; "a" stays only for bot infected ("killed a Hunter").
- **Changed:** Discord bot chat announcements now every 65 minutes instead of 60 (`AD_EVERY` in `vps/discord-bot.py`). Applied with the `discord` action, job `bot`.
- **Added, then removed:** a private test server (folder `l4d-d`, service `l4dd`, port 27019, password set by hand) used to test the event log; it worked on the first round (pounce, heal, kills, safe room order). Stopped, its service and folder deleted on the VPS, and its config taken out of the repo.
- **Not checked:** witch, tank, incap, revive, rescue and friendly fire lines on a live round (none happened in the test); co-op has no `round_end` when a chapter ends, so a "chapter done" line may be needed; team-keeping in a real campaign change.

## Reverse FF kicks instead of bans; deploy no longer sets a difficulty
**Wed Oct 28, 2026 · 7:43 PM – 7:52 PM HST**
- **Changed:** Reverse FF now kicks at 200 friendly damage per map and never bans (`reverseff_survivormaxdmg "200"`, `reverseff_banduration "-1"` in `l4d/base/reverse_ff.cfg`). A 24 hour ban had split up a lobby group. Applied live on all three servers with the console (no restarts), and that player's ban was lifted. **Removed:** the 120 damage limit and the 24 hour ban.
- **Removed:** `DIFFICULTY` in `l4d/servers/*.conf` and the `z_difficulty` line deploy wrote into server.cfg (it was Hard on vintage). Lobbies pick their own difficulty. Also taken out of vintage's live server.cfg; the current game keeps its difficulty until the next lobby or restart.
- **Changed:** the Discord bot's `/difficulty` now changes the difficulty for the current game only. It no longer writes `z_difficulty` into server.cfg, which had kept a difficulty stuck across restarts.

## Tales from the Safe Room: server logs become written stories; Reverse FF spares infected players
**Tue Oct 27, 2026 · 9:27 PM – 10:30 PM HST** (commits fcf1331 … 6791235; the story pieces that run on the Worker are in okayline/dungeon-items)
- **Added:** `vps/story-title.py`: turns a Steam ID into a stable story title like "the Quiet Wanderer" (32 describing words x 31 nouns), using a secret key that is created on first use at `/etc/l4d-story/title.key` and exists only on the server. Nobody can work back from a title to a Steam ID. Words were changed twice at the owner's request (Hermit swapped for Falcon; Silent, Wild, Last, Lonely, Grim, Stubborn, Hollow, Weary, Broken, Distant, Lost and Stranger dropped, 16 friendlier words added). **Removed:** those words.
- **Added:** `vps/story-facts.py`: reads one L4D log and prints each round as JSON (kills by weapon, headshots, lowest health, items picked up, Tank and Witch kills, bans and leaves, how the round ended). Players appear only as character plus title ("Zoey, the Mighty Wolf"); bots are left out; names, Steam IDs and IPs never appear in the output. A round that starts before its log file does takes the map from the newest earlier log.
- **Added:** `run` in `vps-tools.yml` now writes the `STORIES_KEY` GitHub secret to `/etc/l4d-story/stories.key` (root only, never printed). That key is the password for the stories door on the registry Worker. The story scripts were copied to `/opt/story` on the VPS with `run` (that copy is not in the repo).
- **Added (outside the repo):** a daily scheduled task, "Write the day's server stories", at 9:47 PM HST. It reads the day's logs, writes chapters in the owner's style and posts them to the registry. It has not run yet; the first run is Wed Oct 28 at 9:47 PM HST.
- **Changed:** Reverse FF no longer limits team attacks by infected and Tank players (`reverseff_infectedmaxdmg "0"`, `reverseff_tankmaxdmg "0"` in `l4d/base/reverse_ff.cfg`). A Tank player had been removed for hitting survivors, which is what a Tank does. Survivors keep the 120 damage limit and the 24 hour ban. Applied live on classic, versus and vintage with rcon (no restarts), and that player's ban was lifted on all three. **Removed:** the old limit for infected and Tank players.
- **Not checked:** the scheduled task (not run yet); the stories page on a phone; whether the new Reverse FF values hold after the next restart (the repo file is the same as the live value, so it should).

## Welcome pages: TF2 without stats, versus says reverse friendly fire
**Tue Oct 27, 2026**
- **Added:** the Discord bot posts one random chat line per server every hour while someone is on (`say`, no plugin). Each server has its own file, `vps/announcements-<tf2|l4d|l4db|l4dc>.txt`, with its own tone. **Removed:** the unused L4D announcement file and `ANNOUNCE` settings (no plugin ever read them). Takes effect after a push and the `discord` action, job `bot`.
- **Added:** Discord bot keeps a small SQLite file (`/home/tf2/discord/bot.db`, already in the nightly backup): kicks and bans (`/history`), playtime per player name (`/seen`) and player counts every 5 minutes. Names only, no Steam IDs or IPs. Takes effect after a push and the `discord` action, job `bot`.
- **Added:** Discord `/backup keep [id]` tags a restic snapshot so cleanup never deletes it (sudoers line added in `discord-bot-setup.sh`). `/backup status` already lists the latest snapshots. Takes effect after a push and the `discord` action, job `bot`.
- **Added:** Discord `/status` now ends with a VPS line (free memory, disk, load, uptime). Takes effect after a push and the `discord` action, job `bot`.
- **Added:** Discord bot `/ban` (pick a live player, reason, confirm button; uses `sm_ban` permanent, posts no Steam ID), connected time in `/players`, and a weekly stats post (Sunday 18:00 VPS time, once per server channel: totals only, no names) using `week_summary` in `vps/leaderboard.py`. Takes effect after a push and the `discord` action, job `bot`.
- **Changed:** the nightly backup now includes `/home/tf2/uptime-kuma/data` (Uptime Kuma monitors, Discord alert and admin login). Takes effect after a push and the `backup` action (job `install`).
- **Added:** Uptime Kuma 2.x on the VPS (`vps/kuma-setup.sh`, service `uptime-kuma`, 127.0.0.1:3001, runs as tf2, memory capped at 400 MB). `vps/Caddyfile` has a `status.88x31.app` entry; it goes live after the `web` action (job `https`) runs and a DNS record for `status` exists in Cloudflare. Monitors and the Discord webhook are set in its web page.
- **Changed:** TF2 server name in `tf/cfg/88x31.cfg` is now "~*~88x31~*~ TF2 FrEEze tAg SeRveR:  ICEY COLD Edition" (also set live). Needs a push to stick after a restart.
- **Changed:** 9 more actions merged into three: `backup` (install, run, status, restore), `vintage` (private, public, unlock) and `leaderboard` (install, ignore; replaces `leaderboard-install` and `leaderboard-ignore`). The menu is now 20 actions. The box starts with the job. Not run since the merge.
- **Removed:** `vps/nav-check.py` and 11 unused Python wheel files (4.3 MB) at the repo root; nothing referred to them. The stale `/var/www/banner` test page was deleted from the VPS. `CLAUDE.md` now describes the `run` action and the owner's rules (no restarts or pushes unless asked, 2-minute limit).
- **Changed:** 14 more actions merged into three. `discord` (jobs: status, feed, urls, l4d-feed-channel, relay, relay-l4d, bot, bot-status), `web` (stats, logs, https) and `motd` (classic, versus, host). The box starts with the job. Not run since the merge.
- **Changed:** the nine Minecraft install and setting actions are now one: `mc` (box: the job, then its own text, like `set ...` or `plugin-install <name>`). Jobs: setup, set, motd, discord-install, discord-format, bluemap-install, plugin-install, bluemap-render, import. Not run since the merge; Minecraft is off.
- **Changed:** `l4d-setup`, `l4db-setup` and `l4dc-setup` are now one: `l4d-setup` (box: `classic`, `versus` or `vintage`). Not run since the merge.
- **Changed:** the four leaderboard install actions are now one: `leaderboard-install` (box: `tf2`, `l4d`, `l4dvs`, `l4dc` or `all`, then optional days). `run` now hides IP addresses and Steam IDs in its output (`(ip)`, `(steamid)`). Not run yet after the merge.
- **Removed:** 27 more workflow actions that `run` replaces: start/stop/restart for TF2, classic, versus, vintage and Minecraft; `tf2-pause`, `tf2-resume`; `logs`, `command`, `l4d-console`, `l4d-command`, `l4d-log`, `l4d-log-on`, `l4d-log-kinds`, `tf2-log-on`, `l4d-toolz-find`, `host-remove`. `status` stays as the default. For versus and vintage, check free memory before starting (they used to refuse under 900 MB).
- **Removed:** 12 more workflow actions that `run` replaces: `install-package`, `list-maps`, `list-navs`, `map-history`, `console-view`, `list-dir`, `show-file`, `open-port`, `discord-check`, `discord-feed-check`, `disk-usage`, `mc-import-cleanup`.
- **Removed:** 12 workflow actions that `run` replaces: `l4db-console`, `l4db-command`, `l4db-log`, `l4dc-console`, `l4dc-command`, `l4dc-log`, `mc-console`, `mc-command`, `mc-log`, `mem-use`, `cpu-use`, `net-check`. Use `run` with a command instead (for example `free -m`, `ss -tulnp`, `tail -n 60 /home/tf2/mc/logs/latest.log`).
- **Added:** `run` action in `vps-tools.yml`: runs one command as root on the VPS (box: the command). Output is public, so no passwords, tokens, IPs or Steam IDs.
- **Changed:** Reverse FF ban rule: 120 friendly damage in one map (survivors) gets a 24 hour ban (`reverseff_survivormaxdmg 120`, `reverseff_banduration 1440` in `l4d/base/reverse_ff.cfg`).
- **Changed:** the Reverse FF plugin no longer posts chat messages when damage is reversed (`reverseff_chatmsg 0` in `l4d/base/reverse_ff.cfg`).
- **Changed:** shooting a bot teammate now hurts the shooter too (`reverseff_bot 1`, new file `l4d/base/reverse_ff.cfg`, copied by `deploy.sh`). Admins now take reversed damage too (`reverseff_admin 1`). On classic both were also set live; versus and vintage get it at their next deploy.
- **Changed:** the backup repository moved inside the owner's pCloud "Backups" folder (`pcloud:Backups/vps-backup`), in `vps/backup-setup.sh` and the `backup-restore` action.
- **Added:** backups can be kept forever: `backup-run` with "keep" in the box tags the newest snapshot (or "keep ID"), and the nightly cleanup skips tagged snapshots (`vps/backup-setup.sh`). No new action.
- **Fixed:** the deploy workflow no longer copies `tf/cfg/motd.txt`. It was putting the raw template (with the empty `<!--LEADERBOARD-->` spot) over the page the leaderboard timer builds, so the stats board showed blank after every push. Only `tf2-leaderboard-install` and its timer write that file now.
- **Changed:** `tf/cfg/motd.txt` no longer has the stats board (1,507 bytes). `l4d/motd/motd-vs.txt` now says "Reverse friendly fire is ON" like the co-op page.

## Discord bot: /map is TF2 only
**Tue Oct 27, 2026**
- **Changed:** `/map` in `vps/discord-bot.py` now refuses L4D servers ("use /campaign"). It sent any map name straight to the server, so a co-op name on the versus server (or the reverse) put it on the wrong map. `/campaign` already picks the right name for each server. The versus server was found on `l4d_farm03_bridge` with nobody playing.
- **Changed:** versus has reverse friendly fire on (`l4d/servers/versus.conf`). TF2 welcome page `tf/cfg/motd.txt` is smaller (2,015 → 1,572 bytes before the stats) in case it was too long. TF2 maps nobody plays were removed (`tf2-prune-maps`, 219 maps, 9.9 GB). New action `ban-player` (ban by exact name on every running L4D server; the Steam ID is looked up in the logs and not shown).

## L4D rebuild: one shared base, one deploy
**Tue Oct 27, 2026**
- **Added:** `l4d/base/` (shared config, plugin list, announcements), `l4d/servers/` (one small file per server: classic, versus, vintage) and `l4d/deploy.sh`, run by the `l4d-deploy` action. All three L4D servers were reinstalled from it (fresh MetaMod, SourceMod and l4dtoolz). New rcon passwords were generated on the VPS and are not in the repo.
- **Changed:** `l4d_campaign_rotate.sp` is back to the simple version, 10 second delay, and is the only plugin that changes maps. `l4d_admintools.sp` no longer has the co-op/versus switch or "restart chapter".
- **Removed:** `l4d_idlereset.sp`; the scripts `setup-l4d-sourcemod.sh`, `l4d-install-*.sh`, `l4db-install-*.sh`; and the actions `l4d-sourcemod`, `l4d-reverse-ff`, `l4d-rotate-install`, `l4db-rotate-install`, `l4d-reserve-install`, `l4d-scorekeeper-install`, `l4db-damagelog-install`, `l4d-idlereset-install`, `l4d-rename`, `l4db-rename`, `l4dc-rename`, `l4db-order`, `l4db-rff`, `l4dc-difficulty`, `l4d-addons-off`, `l4db-cfg`, `l4db-admins`, `l4dc-compare`. Also the committed `__pycache__` files.
- **Removed:** the picture banner test: actions `l4dc-host-banner`, `l4dc-host-plain`, `l4dc-banner-web` and the files in `l4d/motd/test/`. ViNtaGe's `host.txt` is back to plain "88x31 cLuB".
- **Added:** `CLAUDE.md` with the ground rules for this repo.

## Restored: welcome-screen stats without names and the two plugin changes
**Tue Oct 27, 2026 · 9:17 AM HST**
- **Changed:** `vps/leaderboard.py`, `vps/leaderboard-setup.sh`, `l4d/scripting/l4d_campaign_rotate.sp` and `l4d/scripting/l4d_damagelog.sp` are back to this morning's versions (before the 8:40 rollback), at the owner's request. The L4D welcome screens show stats without player names again. Installing on the 3 L4D servers follows. TF2 is not included.
- **Why the rollback was wrong:** a stock L4D server with nothing installed shows the same welcome window layout, so the layout was not caused by these changes.

## Rolled back: welcome-screen stats and the two plugin changes
**Tue Oct 27, 2026 · 8:40 AM HST**
- **Changed (in the repo only; not installed on the servers yet):** `vps/leaderboard.py`, `vps/leaderboard-setup.sh`, `l4d/scripting/l4d_campaign_rotate.sp` and `l4d/scripting/l4d_damagelog.sp` are back to how they were before this morning's stats work (the board shows the top players by name again; no "Campaigns finished", "Tanks killed", "Survivors incapacitated" or "Tank damage" lines; no `[88x31camp]` or `[88x31tank]` log lines). Done at the owner's request, because the L4D welcome screen layout changed after this morning's installs and the cause was not found. The entries below describe the work that was rolled back. The `host-install` action and the `sm plugins reload` fix in `l4db-install-damagelog.sh` are kept.

## L4D "provided by" name
**Tue Oct 27, 2026 · 8:15 AM HST**
- **Changed:** new action `host-install` puts `l4d/motd/host.txt` (the orange name in "This third-party server provided by:") on all three L4D servers (no restart, the welcome screens are not touched). `l4d-motd` still sends it to the first server too.
- **Tried and undone:** "~*~ 88x31 cLuB ~*~" and "~*~88x31 cLuB~*~". The welcome box had moved from the right of the screen to the top, but it stayed there with the shorter name, so the name was not the cause. `host.txt` went back to "88x31 cLuB", then was emptied at the owner's request (8:25 AM HST) to see if the empty file changes the welcome-screen layout. An empty `host.txt` makes the game show the placeholder "#L4D_Default_Hostname", so it was put back to "88x31 cLuB". The box was still at the top with every version of the welcome screen tried (current, without the scrollbar line, from before the spacing edit, and the oldest), so the welcome-screen files are not what moved it. The game takes plain text only (no color codes; not tested).

## Welcome screens: stats, no names
**Tue Oct 27, 2026 · 7:50 AM HST**
- **Changed:** the welcome-screen board in `vps/leaderboard.py` no longer lists players. It shows plain lines with the server total for the past 5 days: "Zombies killed: 5523", "Tanks killed: N" and "Campaigns finished: 3" (L4D co-op; Versus has no Tanks line because a human plays the Tank there; Versus shows "Damage", "Survivors incapacitated", "Tank damage" and "Campaigns finished". "Survivors incapacitated" counts the game log's existing "(INCAP)" lines for human survivors. "Tank damage" is new: `l4d_damagelog.sp` adds up damage from `tank_claw` and `tank_rock` hits and writes one `[88x31tank] N` line a minute, with no names. Needs the damage plugin reinstalled (`l4db-damagelog-install`); the count starts at 0 then. Not checked in a real match: the log formats and the `tank_claw`/`tank_rock` weapon names are from memory. "Rounds won" is not done: how L4D1 reports the winner of a versus round has not been checked), "Freezes: N" (TF2) and "Damage: N" plus "Campaigns finished: N" (Versus). The ranking and the player count are gone, and the players-shown number in the install box is ignored. "Campaigns finished" counts a new `[88x31camp] finished` line that `l4d_campaign_rotate.sp` now writes to the game log when a rescue happens (co-op) or the second finale round ends (Versus); the admin next-campaign command does not count. The count starts at 0 when the plugin is reinstalled (older logs have no such line). A bold heading "Past 5 days" sits above the lines ("Past day" if the window is 1). Bots are still not counted. Takes effect on each server after reinstalling its leaderboard (`l4d-leaderboard-install`, `l4dc-leaderboard-install`, `l4dvs-leaderboard-install` and `tf2-leaderboard-install`); no restart.
- **Tested:** on made-up log lines only (totals, player count, the empty case). Not run on the VPS or seen in game. Not pushed or deployed yet.

## Bot /logs: easier to read
**Tue Oct 27, 2026**
- **Changed:** `/logs` shows `19:46:10 text` lines with names as "Name (Team)", looks back through the last few log files when the newest is quiet, finds TF2's log files, and hides lines nobody reads: RCON status checks, bots getting stuck on the map, the server settings list at map start, and map loading lines (NAV_MOB_ONLY, Computing Flow Distances, Preventing spawning).

## Discord control bot
**Tue Oct 27, 2026**
- **Added:** `vps/discord-bot.py`, `vps/discord-bot-setup.sh` and the `bot-install` and `bot-status` actions. One bot with slash commands for TF2 and the three L4D servers: `/status`, `/players`, `/map`, `/say`, `/kick` (pick from the live player list), `/start`, `/stop`, `/restart`, `/pause`, `/resume`, `/restartround`, `/scramble` (TF2), `/difficulty`, `/campaign`, `/bots` (TF2), `/logs`, `/health`, `/backup now` and `/backup status`. Only people with the **teal** role, and only in l4d-classic, l4d-vintage, l4d-vs and tf2-freezetag. Stop, restart and pause ask for a Confirm button. Its posts are italic action lines (*Name restarted cLaSSiC*), plus server went offline / back online, low memory or disk (over 90%), and the nightly backup result. Runs as user tf2 and may only run the exact `systemctl` and backup commands in its sudoers file. Needs repo secret `DISCORD_BOT_TOKEN`. No Minecraft, no rename, no add-admin, no ban.
- **Not tested:** the bot has only been checked for syntax and that its commands register; it has not run against Discord or the VPS.

## Nightly backup to pCloud
**Tue Oct 27, 2026**
- **Added:** `vps/backup-setup.sh` and the `backup-install`, `backup-run` and `backup-status` actions. restic (encrypted, only changed data uploads) backs up to pCloud through rclone every night: server configs, SourceMod data/plugins/extensions/gamedata/logs, TF2 maps (with .nav files), leaderboard and log page folders, Minecraft world, Discord files, systemd, Caddy, SSH and firewall settings, the stats page. Not the TF2/L4D game installs (steamcmd re-downloads those). Keeps 7 daily, 4 weekly and 3 monthly snapshots. Needs repo secrets `PCLOUD_RCLONE_TOKEN` (from `rclone authorize "pcloud"`) and `RESTIC_PASSWORD` (keep a copy somewhere else: without it the backup cannot be opened), plus `PCLOUD_HOST` = `eapi.pcloud.com` only for an EU pCloud account.
- **Added:** `backup-restore` action: sets up restic on a new VPS from the saved secrets and restores the newest backup (or a snapshot id), either into /root/restore to look, or with `apply` over the real folders.
- **Not tested:** the restore has not been run yet.

## Stats page: tab order
**Tue Oct 27, 2026 · 7:10 PM HST**
- **Changed:** the tabs are now All servers, cLaSSiC, ViNtaGe, VeRsUs, TF2 (ViNtaGe moved up to sit after cLaSSiC).
- **Added:** a "Last updated: ... Hawaii time" line at the bottom of the page, set each time the page is rebuilt (every 5 minutes).

## Stats page: no intro line, stacked charts, color themes
**Tue Oct 27, 2026 · 6:50 PM HST**
- **Changed:** the two charts at the bottom ("When people play" and "Players per day") are now full width, stacked one above the other. The page colors now come from a theme table in `vps/stats.py` (pastel pink, blue, mint, peach and lavender; pastel pink is the default until one is picked). Also removed the line under the title ("The past 7 days. Updated ... Hawaii time."). The page still looks at the past 7 days and rebuilds every 5 minutes.

## Stats page: tabs
**Tue Oct 27, 2026 · 6:35 PM HST**
- **Changed:** instead of one long page (or two columns), the stats page has tabs: All servers, cLaSSiC, VeRsUs, ViNtaGe and TF2. The tab you pick is remembered while the page refreshes, and a link like `stats.88x31.app/#vs` opens a tab directly. The panel is narrower (about 700px) and the boards sit in two columns inside it (one column on a phone). Without JavaScript the tabs are skipped and every section shows one after another.

## Stats page: smaller, two columns
**Tue Oct 27, 2026 · 6:20 PM HST**
- **Changed:** the stats page text and spacing are about 12% smaller (the font a little more), and the four servers sit in two columns (one column on narrow screens and phones). The "all servers together" box stays full width.

## Public stats page (stats.88x31.app)
**Tue Oct 27, 2026 · 6:00 PM HST**
- **Added:** `vps/stats.py`, `vps/stats-setup.sh` and the `stats-install` action. A timer rebuilds one static page every 5 minutes from the game logs of all four servers (L4D cLaSSiC, Versus, ViNtaGe Edition, TF2), plus a live look at each server over RCON (online, map, players). Per server: totals (players, hours, zombies and special infected killed, Tanks, Witches, finales, friendly fire hits, incapacitations, damage in Versus, freezes in TF2, longest stay), top-10 boards (names only), campaigns or maps played, busiest hours (Hawaii time) and players per day. Bots, Steam IDs, addresses and chat are never shown; the ignore list is honored. Caddy serves it as `stats.88x31.app` (DNS record added in Cloudflare, proxied like logs.88x31.app).
- **Fixed:** the `l4d-log-kinds` action printed Steam IDs into the public Actions log; it now strips them.
- **Not tested:** the special infected, Tank, Witch and finale counts depend on log line formats that have not been checked against real logs; some tiles may show zero until fixed. The page has only been rendered with made-up sample logs.

## Idle reset: 10 minutes empty
**Tue Oct 27, 2026 · 5:45 PM HST**
- **Changed:** the idle reset is meant to run with `l4d_idle_minutes 10`; the check stays every 10 minutes, so the server goes back to No Mercy chapter 1 10 to 20 minutes after the last player left, which gives players time to come back and resume the same playthrough. The install action now replaces the minutes and map in each `server.cfg` (before, it kept old values, and server.cfg is read again on every map change) and reloads the plugin, so running `l4d-idlereset-install` with `all 10` updates the two co-op servers and the Versus server live, no restart. Versus uses `l4d_vs_hospital01_apartment`.
- **Not tested:** not compiled or run on the VPS yet. Nothing installed.

## Idle reset (back to No Mercy when empty)
**Tue Oct 27, 2026 · 5:35 PM HST**
- **Added:** `l4d/scripting/l4d_idlereset.sp` and the `l4d-idlereset-install` action. After the server has had no humans on it for 30 minutes (`l4d_idle_minutes`, 0 turns it off) it goes back to `l4d_hospital01_apartment` (`l4d_idle_map`; the Versus server uses `l4d_vs_hospital01_apartment`), so the next players start at the beginning of No Mercy. A timer checks every 10 minutes (so the reset lands 30 to 40 minutes after the last player left); a human joining cancels the count. It does nothing at join time and does nothing if the server is already on that map. Not handled: if the empty server hibernates, its timers may stop and the reset would not happen until it wakes; this has not been tested. The install covers the two co-op servers by default and the Versus server with "all"; live, no restart; the settings go into each server.cfg.
- **Not tested:** the plugin has not been compiled or run yet.

## Welcome screens: no scrollbar
**Tue Oct 27, 2026 · 5:25 PM HST**
- **Changed:** the three L4D welcome screens (`motd.txt`, `motd-vs.txt`) had a scrollbar in game because the page ran a little past the panel (about 383 px tall). Spacing is tighter (page padding, the gaps between lines and dividers, the box padding), so the screen ends at about 336 px with a three-name leaderboard, and scrolling is switched off on the page (`overflow:hidden`) as a backstop. Same look otherwise. The TF2 screen was not changed. Applied by reinstalling the three L4D leaderboards; no restart. Not seen in game after the change.

## Discord status and live feed for the Versus and ViNtaGe Edition servers
**Mon Oct 26, 2026 · 9:15 PM HST**
- **Added:** `discord-urls-install` copies four GitHub secrets (`DISCORD_L4DB_STATUS_URL`, `DISCORD_L4DB_FEED_URL`, `DISCORD_L4DC_STATUS_URL`, `DISCORD_L4DC_FEED_URL`) onto the VPS as private files and never prints them. `discord-status-setup.sh` now also posts a status message for each new server (port 27017 and 27018, the same one-message-edited-every-minute as the first server) and `discord-feed-setup.sh` adds a live feed service for each (`discord-feed-l4db`, `discord-feed-l4dc`: chat, joins, kills, map changes; game to Discord only, as on the first server). Running `discord-feed-install` again restarts the existing feeds for a moment. Nothing is posted until the secrets exist.
- **Not tested:** none of this has run yet.

## Welcome screens: small divider lines
**Mon Oct 26, 2026 · 8:45 PM HST**
- **Added:** a short centered line (a quarter of the panel width, same pink as the border) under the campaign list and another under the leaderboard, on all three welcome screens (`motd.txt` for both co-op servers, `motd-vs.txt` for Versus). The TF2 welcome screen (`tf/cfg/motd.txt`) has the same two lines, under the map list and under the leaderboard. Applied by reinstalling the leaderboards (three L4D plus TF2); no restart. Not seen in game: only the preview in a desktop browser.

## Co-op welcome screen: one bottom line
**Mon Oct 26, 2026 · 8:35 PM HST**
- **Changed:** `l4d/motd/motd.txt` (first server and "L4D ViNtaGe Edition"): "Reverse friendly fire is ON   Have fun!!" is now one line at the bottom, under the leaderboard (it was two lines with the leaderboard between them). The Versus screen already had its line this way. Applied by reinstalling the two co-op leaderboards, which rebuild the screen; no restart.

## Hard difficulty on the third server
**Mon Oct 26, 2026 · 8:25 PM HST**
- **Added:** `l4dc-difficulty` (box: Easy, Normal, Hard or Impossible; empty = Hard) for "L4D ViNtaGe Edition". It writes `z_difficulty` into that server's server.cfg and applies it live, no restart. Set to Hard at min's request. The welcome screen does not mention the difficulty. Not tested: that the server keeps Hard across campaign changes (a map change may reset it).

## Who joined and left, Steam IDs stripped from log actions
**Mon Oct 26, 2026 · 8:15 PM HST**
- **Added:** `l4d-sessions`: when humans connected and disconnected on all three L4D servers over the last 3 hours (names and times only).
- **Changed:** `l4d-log`, `l4db-log`, `l4dc-log` and `l4d-sessions` now remove every Steam ID from the lines they print, including the ones inside disconnect reasons (a ban message had one). The first `l4d-sessions` run printed one into the public log and was deleted.

## Leaderboard on the third server
**Mon Oct 26, 2026 · 8:05 PM HST**
- **Added:** `l4dc-leaderboard-install` (same board as the first server's: "Most Zombies Killed in the Past 5 Days", names only, rebuilt every 5 minutes, ignore list applies) for "L4D ViNtaGe Edition", plus `l4dc-command` (one console command) and `l4dc-compare` (checks it against the first server). `leaderboard-setup.sh` has a new `l4dc` game that uses the same counting rules as `l4d` on the third server's logs.

## Versus server renamed
**Mon Oct 26, 2026 · 7:55 PM HST**
- **Changed:** the second L4D server is now "~*~88x31~*~ L4D VeRsUs SeRveR" (the 1 is gone), in the `l4db-rename` default, the `l4db-setup` default and the title of `motd-vs.txt`. Applied live with `l4db-rename` and `l4db-motd`; no restart.

## Third L4D server (second co-op)
**Mon Oct 26, 2026 · 7:50 PM HST**
- **Added:** `vps/setup-l4d-extra.sh` and the `l4dc-setup` action. It makes a third Left 4 Dead (1) server, a copy of the first in `/home/tf2/l4d-c` with its own service `l4dc` (screen `l4dc`), game port 27018, name "~*~88x31~*~ L4D ViNtaGe Edition", co-op, starting on No Mercy. Same recipe as the second server (big files hard-linked, about 2 GB of extra disk, logs and the Discord relay not copied, same SourceMod, plugins and admins). The script takes a letter, port, mode, start map and name, so more copies can be made the same way. Renamed at min's request (`l4dc-rename` renames it live and in its welcome screen title). Also added `l4dc-start` (refuses below 900 MB of free memory), `l4dc-stop`, `l4dc-restart`, `l4dc-console` and `l4dc-log`.
- **Not tested:** the script has only had its service-file rewrite checked on a sample file; it has not run on the VPS yet. Min plans to compare this server with the Versus one and keep the busier one.

## Second L4D server (versus), memory check, TF2 pause
**Mon Oct 26, 2026 · 7:10 PM HST**
- **Added:** the `l4db-setup` action (`vps/setup-l4d-b.sh`). It makes a second Left 4 Dead (1) server, a copy of the first in `/home/tf2/l4d-b` with its own service `l4db` (screen `l4db`), game port 27017, name "~*~88x31~*~ L4D1 VeRsUs SeRveR" (first named "L4D cLaSSiC 2"; renamed with `l4db-rename`), 8 players, starting in versus on `l4d_vs_hospital01_apartment`. Game files of 4 MB and up are hard links to the first server's (about 2 GB of extra disk instead of 8.5 GB); everything smaller is a real copy, and logs are not copied. The copy has the same SourceMod, plugins and admins, so `!tools` can switch it between co-op and versus. The Discord chat relay plugin and its settings are not copied.
- **Added:** a "Most Damage in the Past 5 Days" leaderboard for the second server. `l4d/scripting/l4d_damagelog.sp` (`l4db-damagelog-install`, second server only) writes each human's damage to the enemy team into the game log about once a minute, as `[88x31dmg] <STEAM_ID> amount "Name"` (player_hurt for both teams, infected_hurt for survivors hitting common infected, at most 100 per hit; bots and friendly fire are not counted). `vps/leaderboard.py` has a new game `l4dvs` that adds those lines up over the rolling window, and `l4dvs-leaderboard-install` sets up the 5-minute timer for the second server's welcome screen (top 3, names only, the ignore list applies). The board counts only from when the plugin was installed.
- **Changed:** `motd-vs.txt` has the leaderboard spot above one line reading "Friendly fire is ON   Have fun!!" (they were two lines).
- **Added:** `l4d/motd/motd-vs.txt` and the `l4db-motd` action: the second server's welcome screen, titled "~*~88x31~*~ L4D1 VeRsUs SeRveR" with the campaigns in its order (No Mercy, Blood Harvest, Death Toll, Dead Air, Crash Course, The Sacrifice). The first server's `l4d/motd/motd.txt` is unchanged.
- **Added:** the campaign order of the rotation plugin is now the `l4d_rotate_order` setting (default is the story order); `l4db-order` sets it on the second server (saved in its server.cfg, applied live, also sets the start map). `l4db-admins` compares plugins and admins of the two servers.
- **Changed:** on the second server only, Reverse Friendly-Fire is off (`l4db-rff`, box off/on): the plugin file is moved to `plugins/disabled` and unloaded live, and its welcome screen (`motd-vs.txt`) says "Friendly fire is ON" instead of "Reverse friendly fire is ON" (normal game friendly fire applies; not checked in a match).
- **Not tested (damage board):** the plugin has only been compiled on the VPS, not played; damage numbers (does `dmg_health` / `amount` match what a player would expect, are infected players' hits counted) and the board in a real match. The first server still has it on.
- **Added:** `l4db-rename`, `l4db-cfg` (its server.cfg with secrets hidden, and what differs from the first server's), `l4db-log` (game log with IPs and Steam IDs removed), `l4db-rotate-install` (campaign rotation with versus support, compiled and loaded on the second server only), `net-check`, `cpu-use`.
- **Added:** `l4db-start` (refuses if less than 900 MB of memory is free), `l4db-stop`, `l4db-restart`, `l4db-console`, `l4db-command`; `mem-use` (memory per program); `tf2-pause` (stops the tf2 service and keeps it from starting at boot, nothing deleted) and `tf2-resume`.
- **Changed:** nothing on the first L4D server or on TF2. TF2 was not paused: measured memory is Minecraft 1,671 MB, TF2 698 MB, the first L4D server 134 MB (with two players on).
- **Removed:** nothing.
- **Not tested:** joining the new server from the game client or seeing it in the server browser; a full versus match; what happens after a versus finale (the campaign rotation plugin only acts in co-op, so the server may stay on the same campaign); the Discord status and live feed do not include the new server; its welcome screen is a copy of the first server's.

## L4D: scores carry over between chapters and campaigns (score keeper)
**Mon Oct 26, 2026 · 7:00 PM HST**
- **Added:** `l4d/scripting/l4d_scorekeeper.sp` 1.0 and the `l4d-scorekeeper-install` action (`vps/l4d-install-scorekeeper.sh`). When a chapter ends (or a player leaves) it remembers each human player's score by Steam ID and puts it back when they spawn, in the next chapter and the next campaign. The play session ends, and scores start over, when the last human leaves. Kept in memory only: a plugin reload or server restart forgets them. The admin command `sm_frags` shows each human's score as the server sees it.
- **Changed:** nothing.
- **Removed:** nothing.
- **Not tested:** not compiled and not loaded anywhere yet (the sandbox could not download the SourceMod compiler; the install action compiles it on the VPS and loads nothing if that fails). Not checked that the score changed is the one the server browser and scoreboard show, or that L4D1 allows setting it; `sm_frags` is there to test that.

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
