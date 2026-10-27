// Writes how much damage each human player dealt to the enemy team into the game log, for the welcome-screen
// leaderboard ("Most Damage"). Works in versus for both teams (survivors hurting infected, infected hurting
// survivors); friendly fire and bots do not count. Line format (one per player, about once a minute):
//   [88x31dmg] <STEAM_1:0:12345> 250 "Name"
// The number is the damage since the last line, so the leaderboard adds them up over its window.
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "88x31 damage log",
    author = "88x31",
    description = "Logs each human's damage to the enemy team (leaderboard)",
    version = "1.0",
    url = ""
};

#define MAX_COMMON_HIT 100   // one hit on a common infected can report more than its health; keep it sane

int g_dmg[MAXPLAYERS + 1];
int g_tankDmg;   // damage by player-controlled Tanks since the last log line (not per player)

public void OnPluginStart()
{
    if (!HookEventEx("player_hurt", OnPlayerHurt)) LogMessage("player_hurt event not available");
    if (!HookEventEx("infected_hurt", OnInfectedHurt)) LogMessage("infected_hurt event not available");
    HookEventEx("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
    CreateTimer(60.0, FlushTimer, _, TIMER_REPEAT);
    RegAdminCmd("sm_damage", CmdDamage, ADMFLAG_GENERIC, "Show the damage not yet logged");
}

bool IsHuman(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

public void OnClientPutInServer(int client)
{
    g_dmg[client] = 0;
}

public void OnClientDisconnect(int client)
{
    Flush(client);
    g_dmg[client] = 0;
}

public void OnMapEnd()
{
    FlushAll();
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    FlushAll();
}

public Action FlushTimer(Handle timer)
{
    FlushAll();
    return Plugin_Continue;
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker == victim || !IsHuman(attacker) || victim < 1 || victim > MaxClients || !IsClientInGame(victim)) return;
    if (GetClientTeam(attacker) == GetClientTeam(victim)) return;   // friendly fire
    int d = event.GetInt("dmg_health");
    if (d > 0) {
        g_dmg[attacker] += d;
        // damage from a player-controlled Tank (swipes and thrown rocks), for the Versus welcome screen
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));
        if (StrEqual(weapon, "tank_claw") || StrEqual(weapon, "tank_rock")) g_tankDmg += d;
    }
}

public void OnInfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!IsHuman(attacker) || GetClientTeam(attacker) != 2) return;   // survivors hitting common infected
    int d = event.GetInt("amount");
    if (d > MAX_COMMON_HIT) d = MAX_COMMON_HIT;
    if (d > 0) g_dmg[attacker] += d;
}

void Flush(int client)
{
    if (g_dmg[client] < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsClientAuthorized(client)) return;
    char id[32], nick[64];
    if (!GetClientAuthId(client, AuthId_Steam2, id, sizeof(id))) return;
    GetClientName(client, nick, sizeof(nick));
    ReplaceString(nick, sizeof(nick), "\"", "'");
    LogToGame("[88x31dmg] <%s> %d \"%s\"", id, g_dmg[client], nick);
    g_dmg[client] = 0;
}

void FlushAll()
{
    for (int i = 1; i <= MaxClients; i++) Flush(i);
    if (g_tankDmg > 0) {
        LogToGame("[88x31tank] %d", g_tankDmg);   // no player name or ID
        g_tankDmg = 0;
    }
}

public Action CmdDamage(int client, int args)
{
    int shown = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (g_dmg[i] > 0 && IsClientInGame(i)) {
            ReplyToCommand(client, "[88x31] %N: %d damage not yet logged", i, g_dmg[i]);
            shown++;
        }
    }
    if (!shown) ReplyToCommand(client, "[88x31] nothing waiting to be logged");
    return Plugin_Handled;
}
