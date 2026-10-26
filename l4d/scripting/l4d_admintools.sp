// "88x31 Tools" in the !admin menu (also !tools): next campaign, god mode, spawn specials,
// give items, heal everyone, teleport a player to you, restart the chapter, switch co-op/versus.
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin myinfo = { name = "88x31 admin tools", author = "88x31", description = "Fun admin menu", version = "1.2", url = "" };

TopMenu g_top;
static const char KEYS[][] = {"next", "god", "spawn", "give", "heal", "tp", "restart", "mode"};
static const char LABELS[][] = {"Next campaign", "God mode on/off", "Spawn a special...", "Give me an item...",
                                "Heal everyone", "Teleport a player to me...", "Restart this chapter", "Switch co-op/versus"};
bool g_god[MAXPLAYERS + 1];

public void OnPluginStart()
{
    RegAdminCmd("sm_tools", CmdTools, ADMFLAG_GENERIC, "Open the 88x31 tools menu");
    HookEvent("player_spawn", OnSpawn);
    TopMenu t;
    if (LibraryExists("adminmenu") && ((t = GetAdminTopMenu()) != null))
        OnAdminMenuReady(t);
}

public void OnClientDisconnect(int client) { g_god[client] = false; }

public void OnSpawn(Event e, const char[] n, bool nb)
{
    int c = GetClientOfUserId(e.GetInt("userid"));
    if (c > 0 && g_god[c]) SetEntProp(c, Prop_Data, "m_takedamage", 0, 1);
}

public void OnAdminMenuReady(Handle h)
{
    TopMenu t = TopMenu.FromHandle(h);
    if (t == g_top) return;
    g_top = t;
    TopMenuObject cat = t.AddCategory("88x31 Tools", CatHandler, "sm_tools", ADMFLAG_GENERIC);
    char name[32];
    for (int i = 0; i < sizeof(KEYS); i++) {
        Format(name, sizeof(name), "88x31_%s", KEYS[i]);
        t.AddItem(name, ItemHandler, cat, "sm_tools", ADMFLAG_GENERIC);
    }
}

public void CatHandler(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
    if (a == TopMenuAction_DisplayTitle || a == TopMenuAction_DisplayOption) Format(buf, len, "88x31 Tools");
}

public void ItemHandler(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
    char full[32];
    t.GetObjName(o, full, sizeof(full));
    char k[16];
    strcopy(k, sizeof(k), full[6]);
    int i = 0;
    while (i < sizeof(KEYS) - 1 && !StrEqual(KEYS[i], k)) i++;
    if (a == TopMenuAction_DisplayOption) {
        if (StrEqual(k, "god")) Format(buf, len, g_god[c] ? "God mode: ON (turn off)" : "God mode: OFF (turn on)");
        else if (StrEqual(k, "mode")) Format(buf, len, IsVersus() ? "Switch to Co-op" : "Switch to Versus");
        else Format(buf, len, "%s", LABELS[i]);
    }
    else if (a == TopMenuAction_SelectOption) {
        if (!DoAction(c, k)) t.Display(c, TopMenuPosition_LastCategory);
    }
}

public Action CmdTools(int c, int args)
{
    if (c > 0) MainMenu(c);
    return Plugin_Handled;
}

void MainMenu(int c)
{
    Menu m = new Menu(MainH);
    m.SetTitle("88x31 Tools");
    m.AddItem("next", "Next campaign");
    m.AddItem("god", g_god[c] ? "God mode: ON (turn off)" : "God mode: OFF (turn on)");
    m.AddItem("spawn", "Spawn a special...");
    m.AddItem("give", "Give me an item...");
    m.AddItem("heal", "Heal everyone");
    m.AddItem("tp", "Teleport a player to me...");
    m.AddItem("restart", "Restart this chapter");
    m.AddItem("mode", IsVersus() ? "Switch to Co-op" : "Switch to Versus");
    m.Display(c, MENU_TIME_FOREVER);
}

public int MainH(Menu m, MenuAction a, int c, int p)
{
    if (a == MenuAction_End) { delete m; return 0; }
    if (a != MenuAction_Select) return 0;
    char k[16];
    m.GetItem(p, k, sizeof(k));
    if (!DoAction(c, k)) MainMenu(c);
    return 0;
}

// returns true if it opened another menu (or changed map), false to reopen the previous menu
bool DoAction(int c, const char[] k)
{
    if (StrEqual(k, "next")) { ServerCommand("sm_nextcampaign"); return true; }
    if (StrEqual(k, "god")) {
        g_god[c] = !g_god[c];
        if (IsPlayerAlive(c)) SetEntProp(c, Prop_Data, "m_takedamage", g_god[c] ? 0 : 2, 1);
        PrintToChat(c, "\x04[88x31]\x01 God mode %s", g_god[c] ? "ON" : "OFF");
        return false;
    }
    if (StrEqual(k, "spawn")) { SpawnMenu(c); return true; }
    if (StrEqual(k, "give")) { GiveMenu(c); return true; }
    if (StrEqual(k, "heal")) {
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) Cheat(i, "give", "health");
        PrintToChatAll("\x04[88x31]\x01 Everyone was healed!");
        return false;
    }
    if (StrEqual(k, "tp")) { TpMenu(c); return true; }
    if (StrEqual(k, "restart")) {
        char map[64];
        GetCurrentMap(map, sizeof(map));
        PrintToChatAll("\x04[88x31]\x01 Restarting this chapter...");
        ServerCommand("changelevel %s", map);
        return true;
    }
    if (StrEqual(k, "mode")) { SwitchMode(!IsVersus()); return true; }
    return false;
}

// ---- co-op / versus ----
// server.cfg runs on every map load and sets the co-op limits (sv_maxplayers 5, browser /4), so in versus
// they are put back to 8 each time a map starts.
static const char CAMPS[][] = {"hospital", "garage", "smalltown", "airport", "farm", "river"};
static const char COOP_START[][] = {"l4d_hospital01_apartment", "l4d_garage01_alleys", "l4d_smalltown01_caves",
                                    "l4d_airport01_greenhouse", "l4d_farm01_hilltop", "l4d_river01_docks"};
static const char VS_START[][] = {"l4d_vs_hospital01_apartment", "l4d_vs_garage01_alleys", "l4d_vs_smalltown01_caves",
                                  "l4d_vs_airport01_greenhouse", "l4d_vs_farm01_hilltop", "l4d_vs_river01_docks"};

bool IsVersus()
{
    char mode[32];
    ConVar cv = FindConVar("mp_gamemode");
    if (cv == null) return false;
    cv.GetString(mode, sizeof(mode));
    return StrEqual(mode, "versus", false);
}

void SetLimits(bool versus)
{
    ServerCommand("sv_maxplayers %d; sv_visiblemaxplayers %d; l4d_public_slots %d", versus ? 8 : 5, versus ? 8 : 4, versus ? 8 : 4);
}

public void OnConfigsExecuted()
{
    if (IsVersus()) SetLimits(true);
}

void SwitchMode(bool versus)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    int n = 0;                                    // same campaign if we can tell, otherwise No Mercy
    for (int i = 0; i < sizeof(CAMPS); i++) if (StrContains(map, CAMPS[i], false) != -1) n = i;
    for (int step = 0; step < sizeof(CAMPS); step++) {
        int j = (n + step) % sizeof(CAMPS);
        if (IsMapValid(versus ? VS_START[j] : COOP_START[j])) { n = j; break; }
    }
    PrintToChatAll("\x04[88x31]\x01 Switching to \x05%s\x01...", versus ? "VERSUS" : "CO-OP");
    LogMessage("mode switch: %s, map %s", versus ? "versus" : "coop", versus ? VS_START[n] : COOP_START[n]);
    ServerCommand("mp_gamemode %s", versus ? "versus" : "coop");
    SetLimits(versus);
    ServerCommand("changelevel %s", versus ? VS_START[n] : COOP_START[n]);
}

void SpawnMenu(int c)
{
    Menu m = new Menu(SpawnH);
    m.SetTitle("Spawn a special");
    m.AddItem("tank", "Tank");
    m.AddItem("witch", "Witch");
    m.AddItem("hunter", "Hunter");
    m.AddItem("smoker", "Smoker");
    m.AddItem("boomer", "Boomer");
    m.AddItem("mob", "Horde");
    m.ExitBackButton = true;
    m.Display(c, MENU_TIME_FOREVER);
}

public int SpawnH(Menu m, MenuAction a, int c, int p)
{
    if (a == MenuAction_End) delete m;
    else if (a == MenuAction_Cancel && p == MenuCancel_ExitBack) MainMenu(c);
    else if (a == MenuAction_Select) {
        char k[16];
        m.GetItem(p, k, sizeof(k));
        Cheat(c, "z_spawn", k);
        SpawnMenu(c);
    }
    return 0;
}

void GiveMenu(int c)
{
    Menu m = new Menu(GiveH);
    m.SetTitle("Give me");
    m.AddItem("first_aid_kit", "Medkit");
    m.AddItem("pain_pills", "Pills");
    m.AddItem("pipe_bomb", "Pipe bomb");
    m.AddItem("molotov", "Molotov");
    m.AddItem("autoshotgun", "Auto shotgun");
    m.AddItem("rifle", "Assault rifle");
    m.AddItem("hunting_rifle", "Hunting rifle");
    m.AddItem("health", "Full health");
    m.ExitBackButton = true;
    m.Display(c, MENU_TIME_FOREVER);
}

public int GiveH(Menu m, MenuAction a, int c, int p)
{
    if (a == MenuAction_End) delete m;
    else if (a == MenuAction_Cancel && p == MenuCancel_ExitBack) MainMenu(c);
    else if (a == MenuAction_Select) {
        char k[24];
        m.GetItem(p, k, sizeof(k));
        Cheat(c, "give", k);
        GiveMenu(c);
    }
    return 0;
}

void TpMenu(int c)
{
    Menu m = new Menu(TpH);
    m.SetTitle("Teleport to me");
    char id[12], name[64];
    for (int i = 1; i <= MaxClients; i++) {
        if (i == c || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2) continue;
        IntToString(GetClientUserId(i), id, sizeof(id));
        GetClientName(i, name, sizeof(name));
        m.AddItem(id, name);
    }
    if (m.ItemCount == 0) m.AddItem("", "Nobody to teleport", ITEMDRAW_DISABLED);
    m.ExitBackButton = true;
    m.Display(c, MENU_TIME_FOREVER);
}

public int TpH(Menu m, MenuAction a, int c, int p)
{
    if (a == MenuAction_End) delete m;
    else if (a == MenuAction_Cancel && p == MenuCancel_ExitBack) MainMenu(c);
    else if (a == MenuAction_Select) {
        char id[12];
        m.GetItem(p, id, sizeof(id));
        int t = GetClientOfUserId(StringToInt(id));
        if (t > 0 && IsClientInGame(t) && IsPlayerAlive(t)) {
            float pos[3];
            GetClientAbsOrigin(c, pos);
            pos[2] += 10.0;
            TeleportEntity(t, pos, NULL_VECTOR, NULL_VECTOR);
        }
        MainMenu(c);
    }
    return 0;
}

// run a cheat-protected command (give, z_spawn) as this player without turning sv_cheats on
void Cheat(int c, const char[] cmd, const char[] arg)
{
    int flags = GetCommandFlags(cmd);
    SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(c, "%s %s", cmd, arg);
    SetCommandFlags(cmd, flags);
}
