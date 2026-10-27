// After a finale rescue, moves the server on to the next campaign before the credits
// send everyone back to the main menu. story order: No Mercy -> Crash Course -> Death Toll
// -> Dead Air -> Blood Harvest -> The Sacrifice -> No Mercy. Campaigns not installed are skipped.
// The order is the l4d_rotate_order setting (default: the story order above).
// Versus: both teams play the finale, so it moves on after the second round ends on a finale map
// (the l4d_vs_* version of the next campaign).
#include <sourcemod>

public Plugin myinfo = {
    name = "88x31 campaign rotation",
    author = "88x31",
    description = "Next campaign after a finale, keeps players together",
    version = "1.3",
    url = ""
};

static const char FINALES[][] = {
    "l4d_hospital05_rooftop", "l4d_garage02_lots", "l4d_smalltown05_houseboat",
    "l4d_airport05_runway", "l4d_farm05_cornfield", "l4d_river03_port"
};
static const char STARTS[][] = {
    "l4d_hospital01_apartment", "l4d_garage01_alleys", "l4d_smalltown01_caves",
    "l4d_airport01_greenhouse", "l4d_farm01_hilltop", "l4d_river01_docks"
};
static const char VS_STARTS[][] = {
    "l4d_vs_hospital01_apartment", "l4d_vs_garage01_alleys", "l4d_vs_smalltown01_caves",
    "l4d_vs_airport01_greenhouse", "l4d_vs_farm01_hilltop", "l4d_vs_river01_docks"
};
static const char NAMES[][] = {
    "No Mercy", "Crash Course", "Death Toll", "Dead Air", "Blood Harvest", "The Sacrifice"
};
static const char CAMPS[][] = {"hospital", "garage", "smalltown", "airport", "farm", "river"};
static const int FINALE_CHAPTER[] = {5, 2, 5, 5, 5, 3};   // chapter number of each campaign's finale map

ConVar g_delay;
ConVar g_order;
bool g_pending;
char g_next[64];
int g_vsRounds;          // rounds that have ended on a versus finale map since it loaded
float g_lastRoundEnd;

public void OnPluginStart()
{
    g_order = CreateConVar("l4d_rotate_order", "hospital garage smalltown airport farm river",
        "Campaign order, space separated: hospital (No Mercy) garage (Crash Course) smalltown (Death Toll) airport (Dead Air) farm (Blood Harvest) river (The Sacrifice)");
    g_delay = CreateConVar("l4d_rotate_delay", "15.0", "Seconds after the rescue leaves before changing campaign", _, true, 1.0, true, 60.0);
    HookEvent("finale_vehicle_leaving", OnRescue, EventHookMode_PostNoCopy);
    HookEvent("finale_win", OnRescue, EventHookMode_PostNoCopy);
    // versus: not every event exists in every game version, so hook them softly and log what happened
    if (!HookEventEx("round_end", OnRoundEnd, EventHookMode_PostNoCopy)) LogMessage("round_end event not available");
    if (HookEventEx("versus_match_finished", OnMatchFinished, EventHookMode_PostNoCopy)) LogMessage("hooked versus_match_finished");
    RegAdminCmd("sm_nextcampaign", CmdNext, ADMFLAG_CHANGEMAP, "Go to the next campaign now");
}

public void OnMapStart()
{
    g_pending = false;
    g_vsRounds = 0;
    g_lastRoundEnd = 0.0;
    CreateTimer(3.0, LogMap, _, TIMER_FLAG_NO_MAPCHANGE);
}

// L4D does not write the map name into its game log, so the Discord feed can't see map changes
public Action LogMap(Handle t)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    LogToGame("Started map \"%s\"", map);
    return Plugin_Stop;
}

bool IsVersus()
{
    char mode[16];
    FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
    return StrEqual(mode, "versus", false);
}

bool IsCoop()
{
    char mode[16];
    FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
    return StrEqual(mode, "coop", false);
}

// which campaign the current map belongs to (-1 if none)
int CampaignOf(const char[] map)
{
    for (int i = 0; i < sizeof(CAMPS); i++) {
        if (StrContains(map, CAMPS[i], false) != -1) return i;
    }
    return -1;
}

// is this map the finale chapter of its campaign (l4d_hospital05_rooftop, l4d_vs_hospital05_rooftop, ...)
bool IsFinaleMap(const char[] map)
{
    int c = CampaignOf(map);
    if (c == -1) return false;
    int at = StrContains(map, CAMPS[c], false) + strlen(CAMPS[c]);
    char num[3];
    strcopy(num, sizeof(num), map[at]);
    return StringToInt(num) == FINALE_CHAPTER[c];
}

// the campaign that follows the current map's campaign in l4d_rotate_order (-1 if none can be loaded)
int NextIndex(bool versus)
{
    char map[64], order[128], parts[8][16];
    GetCurrentMap(map, sizeof(map));
    g_order.GetString(order, sizeof(order));
    int cnt = ExplodeString(order, " ", parts, sizeof(parts), sizeof(parts[]));
    int seq[8], n = 0;
    for (int i = 0; i < cnt; i++) {
        for (int c = 0; c < sizeof(CAMPS); c++) {
            if (StrEqual(parts[i], CAMPS[c], false)) { seq[n++] = c; break; }
        }
    }
    if (n == 0) {   // unusable setting: story order
        for (int c = 0; c < sizeof(CAMPS); c++) seq[n++] = c;
    }
    int cur = CampaignOf(map);
    int pos = -1;   // a map outside the order starts at its first campaign
    for (int i = 0; i < n; i++) {
        if (seq[i] == cur) pos = i;
    }
    for (int step = 1; step <= n; step++) {
        int c = seq[(pos + step) % n];
        if (IsMapValid(versus ? VS_STARTS[c] : STARTS[c])) return c;
    }
    return -1;
}

void Schedule(float delay, bool force)
{
    if (g_pending) return;
    bool versus = IsVersus();
    if (!force && !IsCoop()) return;   // versus has its own trigger (OnRoundEnd): a rescue is only half of the finale
    int n = NextIndex(versus);
    if (n == -1) return;
    g_pending = true;
    strcopy(g_next, sizeof(g_next), versus ? VS_STARTS[n] : STARTS[n]);
    PrintToChatAll("\x04[88x31]\x01 %s Next campaign: \x05%s\x01 in %d seconds.", versus ? "Match over!" : "Rescued!", NAMES[n], RoundToFloor(delay));
    CreateTimer(delay, DoChange, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnRescue(Event event, const char[] name, bool dontBroadcast)
{
    Schedule(g_delay.FloatValue, false);
}

// versus: round_end fires once per team's turn; on a finale map the second one ends the campaign
public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsVersus()) return;
    char map[64];
    GetCurrentMap(map, sizeof(map));
    if (!IsFinaleMap(map)) return;
    float now = GetGameTime();
    if (g_lastRoundEnd > 0.0 && now - g_lastRoundEnd < 5.0) return;   // ignore a duplicate event
    g_lastRoundEnd = now;
    g_vsRounds++;
    LogMessage("versus round_end on %s, round %d", map, g_vsRounds);
    if (g_vsRounds >= 2) Schedule(g_delay.FloatValue, true);
}

public void OnMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
    LogMessage("versus_match_finished");
    Schedule(g_delay.FloatValue, true);
}

public Action CmdNext(int client, int args)
{
    Schedule(3.0, true);
    return Plugin_Handled;
}

public Action DoChange(Handle timer)
{
    LogMessage("campaign rotation: changing to %s", g_next);
    ServerCommand("changelevel %s", g_next);
    return Plugin_Stop;
}
