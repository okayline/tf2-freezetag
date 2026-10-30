// The Lounge (web IRC client) settings, installed by vps/lounge-setup.sh into /etc/thelounge/config.js.
// Private: only accounts made on the server can log in. Locked to the BBS's own IRC server (127.0.0.1:6667),
// which is reached at irc.88x31.app through Caddy (vps/Caddyfile). Anything not set here is The Lounge's default.
"use strict";
module.exports = {
	public: false,             // logins only (accounts made with: thelounge add NAME)
	host: "127.0.0.1",         // only Caddy reaches it
	port: 9000,
	reverseProxy: true,        // behind Caddy and Cloudflare
	prefetch: false,           // no link previews (no outside fetching)
	fileUpload: { enable: false },
	lockNetwork: true,         // no other IRC networks, only the one below
	defaults: {
		name: "88x31 BBS",
		host: "127.0.0.1",
		port: 6667,
		tls: false,            // local connection on the VPS
		rejectUnauthorized: false,
		password: "",          // no server password (one would be checked against BBS accounts)
		join: "#88x31,#tf2-freezetag,#l4d-classic,#l4d-vs,#l4d-vintage",
	},
};
