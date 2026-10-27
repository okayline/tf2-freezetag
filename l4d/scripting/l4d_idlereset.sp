// Takes the server back to the first chapter of the first campaign when nobody has been on it for a while,
// so the next players start at the beginning instead of in the middle of whatever the last group reached.
// l4d_idle_minutes: minutes with no humans on the server before it goes back (default 30, 0 = off).
// l4d_idle_map: the map to go back to (default l4d_hospital01_apartment, No Mercy chapter 1; use l4d_vs_hospital01_apartment on a versus server).
// A check runs every 10 minutes (so with 10 minutes the reset lands 10 to 20 minutes after the last player left); a human joining cancels the count. Nothing happens at join time.
#include <sourcemod>

public Plugin myinfo = { name = "88x31 idle reset", author = "88x31", description = "Back to the first campaign after a long empty spell", version = "1.0", url = "" };

ConVar g_minutes;
ConVar g_map;
int g_emptySince = 0;   // GetTime() when the last human left, 0 while a human is on

public void OnPluginStart()
{
    g_minutes = CreateConVar("l4d_idle_minutes", "30", "Minutes with no humans before the server goes back to l4d_idle_map (0 = off)", _, true, 0.0, true, 1440.0);
    g_map = CreateConVar("l4d_idle_map", "l4d_hospital01_apartment", "Map to go back to after the idle time");
    CreateTimer(600.0, TimerCheck, _, TIMER_REPEAT);
    MarkIfEmpty(0);
}

// humans on the server, not counting bots or the client in `skip`
int Humans(int skip)
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (i != skip && IsClientConnected(i) && !IsFakeClient(i)) n++;
    return n;
}

void MarkIfEmpty(int skip)
{
    if (Humans(skip) == 0) { if (g_emptySince == 0) g_emptySince = GetTime(); }
    else g_emptySince = 0;
}

bool IdleLongEnough()
{
    int m = g_minutes.IntValue;
    return m > 0 && g_emptySince > 0 && GetTime() - g_emptySince >= m * 60;
}

void GoBack()
{
    char want[64], now[64];
    g_map.GetString(want, sizeof(want));
    GetCurrentMap(now, sizeof(now));
    g_emptySince = GetTime();   // count again from here, so a failed try is not repeated at every check
    if (StrEqual(want, now) || !IsMapValid(want)) return;
    LogMessage("[88x31] Nobody on for %d minutes, going back to %s", g_minutes.IntValue, want);
    ForceChangeLevel(want, "idle reset");
}

public void OnMapStart()
{
    MarkIfEmpty(0);
}

public void OnClientDisconnect(int client)
{
    if (!IsFakeClient(client)) MarkIfEmpty(client);
}

public void OnClientConnected(int client)
{
    if (IsFakeClient(client)) return;
    g_emptySince = 0;
}

public Action TimerCheck(Handle timer)
{
    if (Humans(0) == 0 && IdleLongEnough()) GoBack();
    return Plugin_Continue;
}
