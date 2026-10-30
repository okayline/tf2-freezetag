// 88x31 BBS: the Default shell with Oblivion/2's menus inside it (made by bbs/setup.sh from the repo's bbs/mods/menus88.js;
// do not edit here). bbs/setup.sh copies exec/default.js to mods/default.js and loads this file just before its menu loop,
// so everything else (the frame, the prompts in ctrl/text.ini [default.js], every command's own code) stays Default's.
// The letters and items are Oblivion/2's (exec/obv-2.js), with its sub-menus for messages, e-mail, files and quick.
// The screens are bbs/menu/main.msg and obv*.msg: Default's header and footer around Oblivion's lists.
// Where obv-2.js's keys didn't match its own menu screens, the key follows the screen (noted below).

function show_sysop_wants()   // (from obv-2.js) the file section's "x sysop's want list"
{
	console.crlf();
	var f = system.text_dir + "sysop_wants.txt";
	if (file_exists(f))
		console.printfile(f);
	else
		console.print("\r\n\x01n\x01hThe SysOp has not posted any requests.\r\n");
}
shell.show_sysop_wants = show_sysop_wants;

function prompt88(word, end)   // a prompt in Default's style: "■ Word ■ time" and the end
{
	return gettext("\x01-\x01c\xfe \x01b\x01h", "shell_prompt_begin") + gettext(word)
		+ gettext(" \x01n\x01c\xfe \x01h", "shell_prompt_middle") + time_code + end;
}

// ---------- main ----------
shell.main_menu.command = {
	 'A': { eval: 'bbs.auto_msg()' },
	 'B': { eval: 'bbs.exec_xtrn("sbbslist")' },
	 'C': { eval: 'bbs.page_sysop()' },
	 'D': { eval: 'bbs.list_logons()' },
	 'F': { eval: 'send_feedback()' },
	 'G': { eval: 'logoff(false)' },
	'/G': { eval: 'logoff(true)' },
	 'H': { eval: 'bbs.whos_online()' },
	 'I': { eval: 'bbs.chat_sec()' },
	 'K': { eval: 'bbs.user_config(); exit()' },
	 'L': { eval: 'list_users()' },
	 'P': { eval: 'bbs.xtrn_sec()' },
	 'S': { eval: 'main_info()' },
	 'U': { eval: 'bbs.time_bank()' },
	 'W': { exec: 'logonlist.js', args: ['-l'] },
	 'X': { eval: 'user.settings ^= USER_EXPERT' },
	 'Y': { eval: 'bbs.user_info()' },
	 'Z': { eval: 'bbs.reinit_msg_ptrs()' },
	 '+': { eval: 'bbs.user_config(); exit()' },
	 '!': { eval: 'bbs.menu("sysmain")', ars: 'SYSOP or EXEMPT Q or I or N' },
	// kept from Default, not on the screen: avatar, node list, meme, poll, the "all" scans
	'/A': { exec: 'avatar_chooser.js', ars: 'ANSI and not GUEST', err: '\r\n' + gettext("Sorry, only regular users with ANSI terminals can do that.") + '\r\n' },
	'/L': { eval: 'bbs.list_nodes()' },
	'/M': { exec: 'postmeme.js' },
	'/P': { exec: 'postpoll.js' },
	'/V': { exec: 'scanpolls.js', args: ['all'] },
};
shell.main_menu.nav = {
	'\r': { },
	 'E': { eval: 'menu = email_menu' },
	 'M': { eval: 'menu = message_menu' },
	 'Q': { eval: 'menu = quick_menu' },
	 'T': { eval: 'enter_file_section(); menu = file_menu' },
};
// the main menu's prompt stays Default's (it shows the message group and sub)

// ---------- messages ----------
shell.message_menu = {
	file: "obvmsg",
	cls: true,
	eval: 'bbs.main_cmds++',
	node_action: NODE_RMSG,
	prompt: prompt88("Message", gettext(" \x01n\x01c[\x01h@GN@\x01n\x01c] @GRP@\x01\\ [\x01h@SN@\x01n\x01c] @SUB@: \x01n", "shell_main_prompt_end")),
	num_input: shell.get_sub_num,
	slash_num_input: shell.get_grp_num,
	command: {
	 'A': { eval: 'console.clear(); select_msg_area()' },
	 'B': { eval: 'show_subs(bbs.curgrp)' },
	 'C': { eval: 'console.clear(); bbs.cfg_msg_scan(SCAN_CFG_NEW)' },
	 'G': { eval: 'logoff(false)' },
	'/G': { eval: 'logoff(true)' },
	 'J': { eval: 'show_grps()' },
	 'N': { eval: 'bbs.scan_subs(SCAN_NEW)', msg: '\r\n\x01c\x01h' + gettext("New Message Scan") + '\r\n' },   // (on the screen; obv-2.js had no N)
	 'O': { eval: 'bbs.qwk_sec()' },
	 'P': { eval: 'console.clear(); bbs.post_msg()' },
	 'R': { eval: 'bbs.scan_msgs()' },
	 'Y': { eval: 'console.clear(); bbs.scan_subs(SCAN_TOYOU)' },
	 'Z': { eval: 'bbs.scan_subs(SCAN_NEW | SCAN_CONT)', msg: '\r\n\x01c\x01h' + gettext("Continuous New Message Scan") + '\r\n' },
	 '*': { eval: 'show_subs(bbs.curgrp)' },
	'/*': { eval: 'show_grps()' },
	},
	nav: {
	'\r': { },
	 'Q': { eval: 'menu = main_menu' },
	 'T': { eval: 'enter_file_section(); menu = file_menu' },
	 '+': { eval: 'sub_up()' },    // (on the screen; obv-2.js had no +)
	 '-': { eval: 'sub_down()' },
	 '>': { eval: 'grp_up()' },    // (obv-2.js called group_up, which doesn't exist)
	 '<': { eval: 'grp_down()' },
	},
};
shell.message_menu.nav[KEY_UP] = { eval: 'sub_up()' };
shell.message_menu.nav[KEY_DOWN] = { eval: 'sub_down()' };
shell.message_menu.nav[KEY_RIGHT] = { eval: 'grp_up()' };
shell.message_menu.nav[KEY_LEFT] = { eval: 'grp_down()' };

// ---------- e-mail ----------
shell.email_menu = {
	file: "obvmail",
	cls: true,
	eval: 'bbs.main_cmds++',
	node_action: NODE_RMAL,
	prompt: prompt88("E-mail", " \x01n\x01c: \x01n"),
	command: {
	 'R': { eval: 'bbs.read_mail(MAIL_YOUR, user.number)' },
	 'S': { eval: 'send_email()' },
	 'V': { eval: 'bbs.read_mail(MAIL_SENT, user.number)' },
	},
	nav: {
	'\r': { },
	 'Q': { eval: 'menu = main_menu' },
	},
};

// ---------- quick ----------
shell.quick_menu = {
	file: "obvquick",
	cls: true,
	eval: 'bbs.main_cmds++',
	node_action: NODE_MAIN,
	prompt: prompt88("Quick", " \x01n\x01c: \x01n"),
	command: {
	 'C': { eval: 'bbs.page_sysop()' },
	 'F': { eval: 'send_feedback()' },
	 'G': { eval: 'logoff(false)' },
	'/G': { eval: 'logoff(true)' },
	},
	nav: {
	'\r': { },
	 'E': { eval: 'menu = email_menu' },
	 'M': { eval: 'menu = message_menu' },
	 'Q': { eval: 'menu = main_menu' },
	 'T': { eval: 'enter_file_section(); menu = file_menu' },
	},
};

// ---------- files (Default's file menu and prompt, Oblivion's keys) ----------
shell.file_menu.file = "obvfiles";
shell.file_menu.command = {
	 'A': { eval: 'console.clear(); select_file_area()' },
	 'B': { eval: 'bbs.batch_menu()' },
	 'C': { exec: 'filescancfg.js' },
	 'D': { eval: 'download_files()', msg: '\r\n\x01c\x01h' + gettext("Download File(s)") + '\r\n', ars: 'REST NOT D' },   // (obv-2.js had it on /D)
	'/D': { eval: 'download_user_files()', msg: '\r\n\x01c\x01h' + gettext("Download File(s) from User(s)") + '\r\n', ars: 'REST NOT D' },
	 'E': { eval: 'view_file_info(FI_REMOVE)', msg: '\r\n\x01c\x01h' + gettext("Remove/Edit File(s)") + '\r\n' },
	 'G': { eval: 'logoff(false)' },
	'/G': { eval: 'logoff(true)' },
	 'K': { exec: 'filescancfg.js' },
	 'L': { eval: 'list_files()' },
	 'N': { eval: 'bbs.scan_dirs(FL_ULTIME)', msg: '\r\n\x01c\x01h' + gettext("New File Scan") + '\r\n' },
	 'R': { eval: 'bbs.batch_menu()' },
	 'S': { eval: 'bbs.scan_dirs(FL_NO_HDR)', msg: '\r\n\x01c\x01h' + gettext("Search for Filename(s)") + '\r\n' },
	 'T': { eval: 'bbs.temp_xfer()' },
	 'U': { eval: 'upload_file()', msg: '\r\n\x01c\x01h' + gettext("Upload File") + '\r\n' },
	'/U': { eval: 'upload_user_file()', msg: '\r\n\x01c\x01h' + gettext("Upload File to User") + '\r\n' },
	 'V': { eval: 'view_files()', msg: '\r\n\x01c\x01h' + gettext("View File(s)") + '\r\n' },
	 'W': { eval: 'view_file_info(FI_INFO)', msg: '\r\n\x01c\x01h' + gettext("List Extended File Information") + '\r\n' },
	 'X': { eval: 'show_sysop_wants()' },
	 '!': { eval: 'bbs.menu("sysxfer")', ars: 'SYSOP' },
};
shell.file_menu.nav = {
	'\r': { },
	 'M': { eval: 'menu = message_menu' },
	 'Q': { eval: 'menu = main_menu' },
	 '+': { eval: 'dir_up()' },
	 '-': { eval: 'dir_down()' },
	 '*': { eval: 'show_dirs(bbs.curlib)' },
	'/*': { eval: 'show_libs()' },
	'/+': { eval: 'lib_up()' },
	'/-': { eval: 'lib_down()' },
};
shell.file_menu.nav[KEY_UP] = { eval: 'dir_up()' };
shell.file_menu.nav[KEY_DOWN] = { eval: 'dir_down()' };
shell.file_menu.nav[KEY_RIGHT] = { eval: 'lib_up()' };
shell.file_menu.nav[KEY_LEFT] = { eval: 'lib_down()' };
