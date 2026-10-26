// After a finale rescue, moves the server on to the next campaign before the credits
// send everyone back to the main menu. No Mercy -> Blood Harvest -> Death Toll -> Dead Air
// -> No Mercy (ryan's order). Any other campaign goes to No Mercy next.
#include <sourcemod>

public Plugin myinfo = {
    name = "88x31 campaign rotation",
    author = "88x31",
    description = "Next campaign after a finale, keeps players together",
    version = "1.0",
    url = ""
};

static const char FINALES[][] = {
    "l4d_hospital05_rooftop", "l4d_farm05_cornfield", "l4d_smalltown05_houseboat", "l4d_airport05_runway"
};
static const char STARTS[][] = {
    "l4d_hospital01_apartment", "l4d_farm01_hilltop", "l4d_smalltown01_caves", "l4d_airport01_greenhouse"
};
static const char NAMES[][] = {
    "No Mercy", "Blood Harvest", "Death Toll", "Dead Air"
};

ConVar g_delay;
bool g_pending;
char g_next[64];

public void OnPluginStart()
{
    g_delay = CreateConVar("l4d_rotate_delay", "8.0", "Seconds after the rescue leaves before changing campaign", _, true, 1.0, true, 60.0);
    HookEvent("finale_vehicle_leaving", OnRescue, EventHookMode_PostNoCopy);
    HookEvent("finale_win", OnRescue, EventHookMode_PostNoCopy);
    RegAdminCmd("sm_nextcampaign", CmdNext, ADMFLAG_CHANGEMAP, "Go to the next campaign now");
}

public void OnMapStart()
{
    g_pending = false;
}

int NextIndex()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    int cur = -1;
    for (int i = 0; i < sizeof(FINALES); i++) {
        if (StrEqual(map, FINALES[i], false)) cur = i;
    }
    if (cur == -1) {
        // find the campaign by map name prefix (l4d_hospital, l4d_garage, ...)
        for (int i = 0; i < sizeof(STARTS); i++) {
            char prefix[32];
            strcopy(prefix, sizeof(prefix), STARTS[i]);
            int cut = FindCharInString(prefix, '0');
            if (cut > 0) prefix[cut] = '\0';
            if (StrContains(map, prefix, false) == 0) cur = i;
        }
    }
    for (int step = 1; step <= sizeof(STARTS); step++) {
        int n = (cur + step) % sizeof(STARTS);
        if (n < 0) n += sizeof(STARTS);
        if (IsMapValid(STARTS[n])) return n;
    }
    return -1;
}

void Schedule(float delay)
{
    if (g_pending) return;
    int n = NextIndex();
    if (n == -1) return;
    g_pending = true;
    strcopy(g_next, sizeof(g_next), STARTS[n]);
    PrintToChatAll("\x04[88x31]\x01 Rescued! Next campaign: \x05%s\x01 in %d seconds. Stay on!", NAMES[n], RoundToFloor(delay));
    CreateTimer(delay, DoChange, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnRescue(Event event, const char[] name, bool dontBroadcast)
{
    Schedule(g_delay.FloatValue);
}

public Action CmdNext(int client, int args)
{
    Schedule(3.0);
    return Plugin_Handled;
}

public Action DoChange(Handle timer)
{
    LogMessage("campaign rotation: changing to %s", g_next);
    ServerCommand("changelevel %s", g_next);
    return Plugin_Stop;
}
