// 88x31: emoji -> text for the BBS's IRC screen (mods/irc.js loads this; copied by bbs/setup.sh).
// The BBS's character set (CP437, the old DOS one) has no emoji, so they showed as an upside-down question mark.
// Only used for callers whose terminal is not UTF-8 (like the web terminal); UTF-8 terminals get the real emoji.
// Lines arrive as UTF-8 bytes, and this file is UTF-8 too, so each emoji below is the same bytes as in a line.
// An emoji not in the list becomes *.  To add one: "emoji": "text", (keep the text plain ASCII).
var EMOJI88 = {
	"😀": ":D", "😃": ":D", "😄": ":D", "😁": ":D", "😆": "XD", "😂": "XD", "🤣": "XD", "😅": "^^;",
	"😊": "^_^", "🙂": ":)", "🙃": "(:", "😉": ";)", "😍": "*_*", "🥰": "<3", "😘": ":*", "😋": ":P",
	"😛": ":P", "😜": ";P", "😝": "XP", "🤪": ":P", "🤔": ":?", "😐": ":|", "😑": "-_-", "😶": ":x",
	"🙄": "-.-", "😏": ";]", "😒": ":/", "😕": ":/", "😟": ":(", "🙁": ":(", "😞": ":(", "😔": ":(",
	"😢": ":'(", "😭": "T_T", "😤": ">:/", "😠": ">:(", "😡": ">:(", "🤬": ">:(", "😱": "D:", "😨": "D:",
	"😮": ":O", "😯": ":O", "😲": ":O", "😳": "O_O", "🥺": ";_;", "😴": "zzz", "😪": "zzz", "😎": "B)",
	"🤓": "8)", "😇": "O:)", "😈": ">:)", "🤗": "(hug)", "🥳": "\\o/", "😬": ":S", "🤐": ":#", "🤭": ":x",
	"🤫": "shh", "😷": ":-#", "🤢": ":&", "🤮": ":&", "😵": "X_X", "💀": "x_x", "☠️": "x_x", "👻": "boo",
	"🤖": "[o_o]", "👽": "(alien)", "💩": "(poo)", "🤡": ":o)",
	"❤️": "<3", "❤": "<3", "🧡": "<3", "💛": "<3", "💚": "<3", "💙": "<3", "💜": "<3", "🖤": "<3", "🤍": "<3",
	"💕": "<3<3", "💖": "<3", "💗": "<3", "💘": "<3", "💔": "</3",
	"👍": "+1", "👎": "-1", "👌": "ok", "✌️": "v", "🤞": "(fingers crossed)", "👋": "o/", "🙌": "\\o/",
	"👏": "*clap*", "🙏": "_/\\_", "💪": "(strong)", "🤷": "(shrug)", "🤦": "(facepalm)", "👀": "o.o",
	"🔥": "(fire)", "✨": "*", "⭐": "*", "🌟": "*", "🎉": "\\o/", "🎊": "\\o/", "💯": "100", "✅": "[x]",
	"❌": "x", "⚠️": "(!)", "❗": "!", "❓": "?", "💤": "zzz", "💥": "*boom*", "💬": "...", "🎮": "(game)",
	"🧟": "(zombie)", "🔫": "(gun)", "🍕": "(pizza)", "☕": "(coffee)", "🍺": "(beer)", "🎂": "(cake)",
	"🐱": "=^.^=", "🐶": "(dog)", "🐸": "(frog)", "🦊": "(fox)", "🦇": "(bat)", "🎃": "(pumpkin)"
};

var EMOJI88_N = {};	// the same list without the invisible colour variant, which emoji88 takes out of lines first
for (var e in EMOJI88)
	EMOJI88_N[e.replace(/\xEF\xB8\x8F/g, "")] = EMOJI88[e];
EMOJI88 = EMOJI88_N;

function emoji88(line) {
	// leave out the invisible joiners and colour variants: variation selector, zero-width joiner, skin tones
	line = line.replace(/\xEF\xB8\x8F|\xE2\x80\x8D|\xF0\x9F\x8F[\xBB-\xBF]/g, "");
	for (var e in EMOJI88)
		if (line.indexOf(e) >= 0)
			line = line.split(e).join(EMOJI88[e]);
	return line.replace(/[\xF0-\xF4][\x80-\xBF]{3}/g, "*");	// any other emoji (4-byte UTF-8)
}
