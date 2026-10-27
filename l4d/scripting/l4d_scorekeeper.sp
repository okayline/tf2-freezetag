// Keeps each player's score (the number the server browser and the scoreboard show) from one chapter to the next.
// When a chapter ends the scores are remembered by Steam ID, and put back when the player spawns in the next one.
// They start over when a new campaign begins (the first chapter) and when the last human leaves the server.
// Scores are kept in memory only: a plugin reload or a server restart forgets them.
#include <sourcemod>

public Plugin myinfo = { name = "88x31 score keeper", author = "88x31", description = "Scores carry over between chapters", version = "1.0", url = "" };

StringMap g_scores;                 // Steam ID -> score
bool g_restored[MAXPLAYERS + 1];    // already put back this chapter

public void OnPluginStart()
{
    g_scores = new StringMap();
    HookEvent("player_spawn", Event_Spawn);
    RegAdminCmd("sm_frags", CmdFrags, ADMFLAG_GENERIC, "Show each human player's score as the server sees it");
}

public void OnMapStart()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    if (StrContains(map, "01_") != -1)   // first chapter of a campaign (l4d_hospital01_apartment, l4d_smalltown01_caves, ...)
        g_scores.Clear();
    for (int i = 1; i <= MaxClients; i++)
        g_restored[i] = false;
}

public void OnMapEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        Save(i);
}

public void OnClientDisconnect(int client)
{
    Save(client);
    g_restored[client] = false;
    for (int i = 1; i <= MaxClients; i++)
        if (i != client && IsClientInGame(i) && !IsFakeClient(i))
            return;
    g_scores.Clear();   // that was the last human: the next group starts fresh
}

void Save(int client)
{
    char id[32];
    if (!Human(client) || !HasEntProp(client, Prop_Data, "m_iFrags") || !GetClientAuthId(client, AuthId_Steam2, id, sizeof(id)))
        return;
    g_scores.SetValue(id, GetEntProp(client, Prop_Data, "m_iFrags"));
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (Human(client) && !g_restored[client])
        CreateTimer(1.5, Timer_Restore, GetClientUserId(client));
}

public Action Timer_Restore(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    char id[32];
    int score;
    if (!Human(client) || g_restored[client] || GetClientTeam(client) != 2 || !HasEntProp(client, Prop_Data, "m_iFrags"))
        return Plugin_Stop;
    if (GetClientAuthId(client, AuthId_Steam2, id, sizeof(id)) && g_scores.GetValue(id, score))
        SetEntProp(client, Prop_Data, "m_iFrags", score);
    g_restored[client] = true;
    return Plugin_Stop;
}

bool Human(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

public Action CmdFrags(int client, int args)
{
    for (int i = 1; i <= MaxClients; i++)
        if (Human(i) && HasEntProp(i, Prop_Data, "m_iFrags"))
            ReplyToCommand(client, "[88x31] %N: score %d, team %d", i, GetEntProp(i, Prop_Data, "m_iFrags"), GetClientTeam(i));
    return Plugin_Handled;
}
