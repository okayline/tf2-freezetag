#include <sourcemod>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin myinfo =
{
	name = "88x31 Settings",
	author = "okayline",
	description = "Runs cfg/88x31.cfg after all other config files; admin commands sm_next and sm_random change the map; 88x31 Tools in the admin menu",
	version = "1.5",
	url = "https://github.com/okayline/tf2-freezetag"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_next", Cmd_Next, ADMFLAG_CHANGEMAP, "Go to the next map in the map cycle");
	RegAdminCmd("sm_random", Cmd_Random, ADMFLAG_CHANGEMAP, "Go to a random map from the map cycle");
	RegAdminCmd("sm_restartround", Cmd_RestartRound, ADMFLAG_CHANGEMAP, "Start a new round");
	RegAdminCmd("sm_bigheads", Cmd_BigHeads, ADMFLAG_CHANGEMAP, "Big heads for everyone on/off");
	RegAdminCmd("sm_tactical", Cmd_Tactical, ADMFLAG_CHANGEMAP, "Tactical mode (arena, first to 7) on/off");
	g_tactical = CreateConVar("sm_88x31_tactical", "0", "1 = tactical mode (arena maps, one life, first to 7), 0 = Freeze Tag", _, true, 0.0, true, 1.0);
	HookEvent("teamplay_round_win", OnRoundWin);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) SDKHook(i, SDKHook_PostThinkPost, HeadThink);
	TopMenu t;
	if (LibraryExists("adminmenu") && ((t = GetAdminTopMenu()) != null))
		OnAdminMenuReady(t);
}

// ---- "88x31 Tools" in the !admin menu ----
TopMenu g_top;

public void OnAdminMenuReady(Handle h)
{
	TopMenu t = TopMenu.FromHandle(h);
	if (t == g_top) return;
	g_top = t;
	TopMenuObject cat = t.AddCategory("88x31 Tools", ToolsCategory, "sm_restartround", ADMFLAG_CHANGEMAP);
	t.AddItem("88x31_restartround", RestartItem, cat, "sm_restartround", ADMFLAG_CHANGEMAP);
	t.AddItem("88x31_bigheads", BigHeadsItem, cat, "sm_bigheads", ADMFLAG_CHANGEMAP);
	t.AddItem("88x31_tactical", TacticalItem, cat, "sm_tactical", ADMFLAG_CHANGEMAP);
}

public void ToolsCategory(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
	if (a == TopMenuAction_DisplayTitle || a == TopMenuAction_DisplayOption) Format(buf, len, "88x31 Tools");
}

public void RestartItem(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
	if (a == TopMenuAction_DisplayOption) Format(buf, len, "Restart round");
	else if (a == TopMenuAction_SelectOption) RestartRound();
}

public Action Cmd_RestartRound(int client, int args)
{
	RestartRound();
	return Plugin_Handled;
}

void RestartRound()
{
	PrintToChatAll("\x04[88x31]\x01 New round!");
	ServerCommand("mp_restartround 1");
}

public void OnConfigsExecuted()
{
	ServerCommand("exec 88x31.cfg");
	ApplyMode();
}

// ---- Tactical mode: arena maps, one life, first to 7 rounds, Freeze Tag off ----
// The mode is kept in sm_88x31_tactical, which lasts across map changes (a server restart goes back to Freeze Tag).
ConVar g_tactical;

void ApplyMode()
{
	if (g_tactical.BoolValue)
		ServerCommand("sm_freezetag_enabled 0; mp_winlimit 7; tf_arena_use_queue 0; mapcyclefile mapcycle_tactical.txt");
	else
		ServerCommand("sm_freezetag_enabled 1; mp_winlimit 0; mapcyclefile mapcycle.txt");
}

public void TacticalItem(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
	if (a == TopMenuAction_DisplayOption) Format(buf, len, g_tactical.BoolValue ? "Tactical mode: ON (back to Freeze Tag)" : "Tactical mode: OFF (turn on)");
	else if (a == TopMenuAction_SelectOption) SwitchMode(c, !g_tactical.BoolValue);
}

public Action Cmd_Tactical(int client, int args)
{
	SwitchMode(client, !g_tactical.BoolValue);
	return Plugin_Handled;
}

void SwitchMode(int client, bool tactical)
{
	ArrayList maps = ReadCycle(tactical ? "mapcycle_tactical.txt" : "mapcycle.txt");
	if (maps.Length == 0)
	{
		if (client > 0) PrintToChat(client, "\x04[88x31]\x01 No maps found for that mode.");
		delete maps;
		return;
	}
	char pick[PLATFORM_MAX_PATH];
	maps.GetString(GetRandomInt(0, maps.Length - 1), pick, sizeof(pick));
	delete maps;
	g_tactical.SetBool(tactical);
	PrintToChatAll("\x04[88x31]\x01 %s", tactical ? "TACTICAL MODE: one life, first to 7 rounds!" : "Back to Freeze Tag!");
	GoToMap(client, pick);
}

// Reads the maps in cfg/mapcycle.txt (one per line) that exist on the server.
ArrayList ReadCycle(const char[] only = "")
{
	ArrayList maps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	char file[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH], line[PLATFORM_MAX_PATH];
	ConVar cycle = FindConVar("mapcyclefile");
	if (only[0] != '\0')
	{
		strcopy(file, sizeof(file), only);
	}
	else if (cycle != null)
	{
		cycle.GetString(file, sizeof(file));
	}
	else
	{
		strcopy(file, sizeof(file), "mapcycle.txt");
	}
	Format(path, sizeof(path), "cfg/%s", file);

	File f = OpenFile(path, "r");
	if (f == null)
	{
		return maps;
	}
	while (!f.EndOfFile() && f.ReadLine(line, sizeof(line)))
	{
		TrimString(line);
		if (line[0] == '\0' || line[0] == '/' || line[0] == ';')
		{
			continue;
		}
		if (IsMapValid(line))
		{
			maps.PushString(line);
		}
	}
	delete f;
	return maps;
}

void GoToMap(int client, const char[] map)
{
	PrintToChatAll("\x04[Admin]\x01 Changing the map to %s in 3 seconds...", map);
	LogAction(client, -1, "\"%L\" changed the map to %s", client, map);
	DataPack pack;
	CreateDataTimer(3.0, Timer_Change, pack);
	pack.WriteString(map);
}

public Action Timer_Change(Handle timer, DataPack pack)
{
	char map[PLATFORM_MAX_PATH];
	pack.Reset();
	pack.ReadString(map, sizeof(map));
	ForceChangeLevel(map, "88x31 admin map change");
	return Plugin_Stop;
}

public Action Cmd_Next(int client, int args)
{
	ArrayList maps = ReadCycle();
	if (maps.Length == 0)
	{
		ReplyToCommand(client, "[SM] The map cycle is empty.");
		delete maps;
		return Plugin_Handled;
	}
	char current[PLATFORM_MAX_PATH], next[PLATFORM_MAX_PATH];
	GetCurrentMap(current, sizeof(current));
	int idx = maps.FindString(current);
	maps.GetString((idx + 1) % maps.Length, next, sizeof(next));
	delete maps;
	GoToMap(client, next);
	return Plugin_Handled;
}

public Action Cmd_Random(int client, int args)
{
	ArrayList maps = ReadCycle();
	char current[PLATFORM_MAX_PATH], pick[PLATFORM_MAX_PATH];
	GetCurrentMap(current, sizeof(current));
	int idx = maps.FindString(current);
	if (idx != -1)
	{
		maps.Erase(idx);   // never pick the map we are already on
	}
	if (maps.Length == 0)
	{
		ReplyToCommand(client, "[SM] The map cycle is empty.");
		delete maps;
		return Plugin_Handled;
	}
	maps.GetString(GetRandomInt(0, maps.Length - 1), pick, sizeof(pick));
	delete maps;
	GoToMap(client, pick);
	return Plugin_Handled;
}


// ---- Big heads (head size only; gravity and everything else unchanged) ----
// TF2 sets each player's head size every tick, so it is put back right after, while big heads are on.
bool g_bigHeads;            // off by default; turned on from the admin menu
bool g_loserHead[MAXPLAYERS + 1];   // losing team of the last round, until the next round starts
const float BIG_HEAD = 3.0;

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, HeadThink);
}

public void HeadThink(int client)
{
	if ((g_bigHeads || g_loserHead[client]) && IsPlayerAlive(client) && HasEntProp(client, Prop_Send, "m_flHeadScale"))
		SetEntPropFloat(client, Prop_Send, "m_flHeadScale", BIG_HEAD);
}

public void BigHeadsItem(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
	if (a == TopMenuAction_DisplayOption) Format(buf, len, g_bigHeads ? "Big heads: ON (turn off)" : "Big heads: OFF (turn on)");
	else if (a == TopMenuAction_SelectOption) { ToggleBigHeads(); t.Display(c, TopMenuPosition_LastCategory); }
}

public Action Cmd_BigHeads(int client, int args)
{
	ToggleBigHeads();
	return Plugin_Handled;
}

void ToggleBigHeads()
{
	g_bigHeads = !g_bigHeads;
	if (!g_bigHeads)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && HasEntProp(i, Prop_Send, "m_flHeadScale")) SetEntPropFloat(i, Prop_Send, "m_flHeadScale", 1.0);
	PrintToChatAll("\x04[88x31]\x01 Big heads %s", g_bigHeads ? "ON!" : "off");
}

// ---- Losing team gets big heads at the end of a round, until the next round starts ----
public void OnRoundWin(Event e, const char[] name, bool nb)
{
	int winner = e.GetInt("team");
	if (winner != 2 && winner != 3) return;            // stalemate: nobody
	int loser = (winner == 2) ? 3 : 2;
	for (int i = 1; i <= MaxClients; i++)
		g_loserHead[i] = IsClientInGame(i) && GetClientTeam(i) == loser;
}

public void OnRoundStart(Event e, const char[] name, bool nb)
{
	ClearLoserHeads();
}

public void OnMapStart()
{
	for (int i = 0; i <= MAXPLAYERS; i++) g_loserHead[i] = false;
}

void ClearLoserHeads()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (g_loserHead[i] && !g_bigHeads && IsClientInGame(i) && HasEntProp(i, Prop_Send, "m_flHeadScale"))
			SetEntPropFloat(i, Prop_Send, "m_flHeadScale", 1.0);
		g_loserHead[i] = false;
	}
}

public void OnClientDisconnect(int client)
{
	g_loserHead[client] = false;
}
