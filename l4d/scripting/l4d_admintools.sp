// "88x31 Tools" in the !admin menu (also !tools): next campaign, god mode, spawn specials,
// give items, heal everyone, teleport a player to you, restart the chapter.
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin myinfo = { name = "88x31 admin tools", author = "88x31", description = "Fun admin menu", version = "1.0", url = "" };

TopMenu g_top;
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
    t.AddItem("88x31_open", ItemHandler, cat, "sm_tools", ADMFLAG_GENERIC);
}

public void CatHandler(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
    if (a == TopMenuAction_DisplayTitle || a == TopMenuAction_DisplayOption) Format(buf, len, "88x31 Tools");
}

public void ItemHandler(TopMenu t, TopMenuAction a, TopMenuObject o, int c, char[] buf, int len)
{
    if (a == TopMenuAction_DisplayOption) Format(buf, len, "Open tools");
    else if (a == TopMenuAction_SelectOption) MainMenu(c);
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
    m.Display(c, MENU_TIME_FOREVER);
}

public int MainH(Menu m, MenuAction a, int c, int p)
{
    if (a == MenuAction_End) { delete m; return 0; }
    if (a != MenuAction_Select) return 0;
    char k[16];
    m.GetItem(p, k, sizeof(k));
    if (StrEqual(k, "next")) { ServerCommand("sm_nextcampaign"); return 0; }
    if (StrEqual(k, "god")) {
        g_god[c] = !g_god[c];
        if (IsPlayerAlive(c)) SetEntProp(c, Prop_Data, "m_takedamage", g_god[c] ? 0 : 2, 1);
        PrintToChat(c, "\x04[88x31]\x01 God mode %s", g_god[c] ? "ON" : "OFF");
        MainMenu(c);
    }
    else if (StrEqual(k, "spawn")) SpawnMenu(c);
    else if (StrEqual(k, "give")) GiveMenu(c);
    else if (StrEqual(k, "heal")) {
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) Cheat(i, "give", "health");
        PrintToChatAll("\x04[88x31]\x01 Everyone was healed!");
        MainMenu(c);
    }
    else if (StrEqual(k, "tp")) TpMenu(c);
    else if (StrEqual(k, "restart")) {
        char map[64];
        GetCurrentMap(map, sizeof(map));
        PrintToChatAll("\x04[88x31]\x01 Restarting this chapter...");
        ServerCommand("changelevel %s", map);
    }
    return 0;
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
