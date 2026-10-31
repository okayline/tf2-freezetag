// Writes what happens in a round into the game log, so the stories and stats have more to read than kills.
// One line per event, all starting with [88x31ev], then the event name, then who and what:
//   [88x31ev] revive <STEAM_1:0:1> "Name" (Zoey) -> <BOT> "Bill" (Bill) ledge=0
// A player is written as <steam id or BOT> "name" (survivor name or infected class).
// Only writes to the log; it never changes gameplay. Switched on per server with EVENTLOG=1.
// Version 1: player actions, specials, witch, tank, safe room, round results. Versus points come later.
// Version 1.1: difficulty, mode and humans on round_start; difficulty changes; votes; each human's country when they join,
// and their country, ping and minutes when they leave. The country comes from SourceMod's GeoIP database; the address is never written.
#include <sourcemod>
#include <sdktools>
#include <geoip>

public Plugin myinfo = {
    name = "88x31 event log",
    author = "88x31",
    description = "Logs round events (heals, revives, specials, witch, tank, safe room, difficulty, votes, ping) for stories and stats",
    version = "1.1",
    url = ""
};

#define TAG "[88x31ev]"

bool g_leftStart;                  // someone has left the start area this round
bool g_safe[MAXPLAYERS + 1];       // already logged as reaching the end safe room this round
int g_safeCount;                   // order of arrival in the safe room
float g_tankSince[MAXPLAYERS + 1]; // when this client became a tank
ConVar g_difficulty, g_mode;

public void OnPluginStart()
{
    HookEvent("round_start", Ev_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Ev_RoundEnd);
    HookEvent("player_left_start_area", Ev_LeftStart);
    HookEvent("player_death", Ev_Death);
    HookEvent("player_incapacitated", Ev_Incap);
    HookEvent("player_ledge_grab", Ev_LedgeGrab);
    HookEvent("heal_success", Ev_Heal);
    HookEvent("revive_success", Ev_Revive);
    HookEvent("survivor_rescued", Ev_Rescued);
    HookEvent("pills_used", Ev_Pills);
    HookEvent("friendly_fire", Ev_FriendlyFire);
    HookEvent("lunge_pounce", Ev_Pounce);
    HookEvent("tongue_grab", Ev_Tongue);
    HookEvent("player_now_it", Ev_Vomit);
    HookEvent("witch_harasser_set", Ev_WitchStartled);
    HookEvent("witch_killed", Ev_WitchKilled);
    HookEvent("tank_spawn", Ev_TankSpawn);
    HookEvent("tank_killed", Ev_TankKilled);
    HookEvent("player_entered_checkpoint", Ev_Checkpoint);
    HookEvent("finale_win", Ev_FinaleWin, EventHookMode_PostNoCopy);
    HookEvent("mission_lost", Ev_MissionLost, EventHookMode_PostNoCopy);
    // votes: HookEventEx, so a missing event name can't stop the plugin from loading
    HookEventEx("vote_started", Ev_VoteStarted);
    HookEventEx("vote_passed", Ev_VotePassed);
    HookEventEx("vote_failed", Ev_VoteFailed);
    g_mode = FindConVar("mp_gamemode");
    g_difficulty = FindConVar("z_difficulty");
    if (g_difficulty != null) g_difficulty.AddChangeHook(Cv_Difficulty);   // a lobby or vote sets it; the game log doesn't say
}

// ---------- helpers ----------

bool Valid(int c) { return c > 0 && c <= MaxClients && IsClientInGame(c); }

// The survivor's character from their model, or the infected's class.
void Role(int c, char[] out, int len)
{
    if (GetClientTeam(c) == 3) {
        int z = GetEntProp(c, Prop_Send, "m_zombieClass");
        switch (z) {
            case 1: strcopy(out, len, "Smoker");
            case 2: strcopy(out, len, "Boomer");
            case 3: strcopy(out, len, "Hunter");
            case 5: strcopy(out, len, "Tank");
            default: strcopy(out, len, "Infected");
        }
        return;
    }
    char m[PLATFORM_MAX_PATH];
    GetClientModel(c, m, sizeof(m));
    if (StrContains(m, "namvet") != -1) strcopy(out, len, "Bill");
    else if (StrContains(m, "teenangst") != -1) strcopy(out, len, "Zoey");
    else if (StrContains(m, "biker") != -1) strcopy(out, len, "Francis");
    else if (StrContains(m, "manager") != -1) strcopy(out, len, "Louis");
    else strcopy(out, len, "Survivor");
}

// <id> "name" (role)
void Who(int c, char[] out, int len)
{
    if (!Valid(c)) { strcopy(out, len, "<WORLD> \"\" ()"); return; }
    char id[32], name[MAX_NAME_LENGTH], role[16];
    if (IsFakeClient(c) || !GetClientAuthId(c, AuthId_Steam2, id, sizeof(id))) strcopy(id, sizeof(id), "BOT");
    GetClientName(c, name, sizeof(name));
    ReplaceString(name, sizeof(name), "\"", "'");
    Role(c, role, sizeof(role));
    Format(out, len, "<%s> \"%s\" (%s)", id, name, role);
}

int U(Event e, const char[] key) { return GetClientOfUserId(e.GetInt(key)); }

int Humans()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i)) n++;
    return n;
}

void Log1(const char[] what, int a, const char[] extra = "")
{
    char wa[128];
    Who(a, wa, sizeof(wa));
    LogToGame("%s %s %s%s%s", TAG, what, wa, extra[0] ? " " : "", extra);
}

void Log2(const char[] what, int a, int b, const char[] extra = "")
{
    char wa[128], wb[128];
    Who(a, wa, sizeof(wa));
    Who(b, wb, sizeof(wb));
    LogToGame("%s %s %s -> %s%s%s", TAG, what, wa, wb, extra[0] ? " " : "", extra);
}

// ---------- round ----------

public void Ev_RoundStart(Event e, const char[] n, bool nb)
{
    g_leftStart = false;
    g_safeCount = 0;
    for (int i = 1; i <= MaxClients; i++) { g_safe[i] = false; g_tankSince[i] = 0.0; }
    char diff[32], mode[32];
    if (g_difficulty != null) g_difficulty.GetString(diff, sizeof(diff));
    if (g_mode != null) g_mode.GetString(mode, sizeof(mode));
    LogToGame("%s round_start difficulty=%s mode=%s humans=%d", TAG, diff, mode, Humans());
}

public void Ev_RoundEnd(Event e, const char[] n, bool nb)
{
    char msg[64];
    e.GetString("message", msg, sizeof(msg));
    LogToGame("%s round_end winner=%d reason=%d message=\"%s\" safe=%d", TAG, e.GetInt("winner"), e.GetInt("reason"), msg, g_safeCount);
}

public void Ev_LeftStart(Event e, const char[] n, bool nb)
{
    if (g_leftStart) return;
    g_leftStart = true;
    Log1("left_start", U(e, "userid"));
}

public void Ev_FinaleWin(Event e, const char[] n, bool nb) { LogToGame("%s finale_win", TAG); }
public void Ev_MissionLost(Event e, const char[] n, bool nb) { LogToGame("%s mission_lost", TAG); }

// ---------- survivors ----------

public void Ev_Death(Event e, const char[] n, bool nb)
{
    int victim = U(e, "userid");
    if (!Valid(victim)) return;                 // common infected and witches have no client; witch has its own event
    int attacker = U(e, "attacker");
    char wpn[32], extra[64];
    e.GetString("weapon", wpn, sizeof(wpn));
    Format(extra, sizeof(extra), "weapon=%s headshot=%d", wpn, e.GetBool("headshot"));
    if (GetClientTeam(victim) == 3 && g_tankSince[victim] > 0.0) {
        g_tankSince[victim] = 0.0;              // tank_killed logs the tank itself
    }
    Log2("death", attacker, victim, extra);
}

public void Ev_Incap(Event e, const char[] n, bool nb) { Log2("incap", U(e, "attacker"), U(e, "userid")); }
public void Ev_LedgeGrab(Event e, const char[] n, bool nb) { Log1("ledge_grab", U(e, "userid")); }

public void Ev_Heal(Event e, const char[] n, bool nb)
{
    char extra[24];
    Format(extra, sizeof(extra), "health=%d", e.GetInt("health_restored"));
    Log2("heal", U(e, "userid"), U(e, "subject"), extra);
}

public void Ev_Revive(Event e, const char[] n, bool nb)
{
    char extra[16];
    Format(extra, sizeof(extra), "ledge=%d", e.GetBool("ledge_hang"));
    Log2("revive", U(e, "userid"), U(e, "subject"), extra);
}

public void Ev_Rescued(Event e, const char[] n, bool nb) { Log2("rescue", U(e, "rescuer"), U(e, "victim")); }
public void Ev_Pills(Event e, const char[] n, bool nb) { Log1("pills", U(e, "userid")); }

// friendly_fire fires on every hit; the game marks who was at fault with "guilty"
public void Ev_FriendlyFire(Event e, const char[] n, bool nb)
{
    int a = U(e, "attacker"), v = U(e, "victim");
    if (!Valid(a) || !Valid(v) || U(e, "guilty") != a) return;
    Log2("friendly_fire", a, v);
}

// ---------- special infected ----------

public void Ev_Pounce(Event e, const char[] n, bool nb) { Log2("pounce", U(e, "userid"), U(e, "victim")); }
public void Ev_Tongue(Event e, const char[] n, bool nb) { Log2("tongue", U(e, "userid"), U(e, "victim")); }
public void Ev_Vomit(Event e, const char[] n, bool nb)
{
    int a = U(e, "attacker");
    if (Valid(a) && GetClientTeam(a) == 3) Log2("vomit", a, U(e, "userid"));
}

// ---------- witch and tank ----------

public void Ev_WitchStartled(Event e, const char[] n, bool nb) { Log1("witch_startled", U(e, "userid")); }

public void Ev_WitchKilled(Event e, const char[] n, bool nb)
{
    char extra[16];
    Format(extra, sizeof(extra), "oneshot=%d", e.GetBool("oneshot"));
    Log1("witch_killed", U(e, "userid"), extra);
}

public void Ev_TankSpawn(Event e, const char[] n, bool nb)
{
    int t = U(e, "userid");
    if (!Valid(t)) return;
    g_tankSince[t] = GetGameTime();
    Log1("tank_spawn", t);
}

public void Ev_TankKilled(Event e, const char[] n, bool nb)
{
    int t = U(e, "userid");
    char extra[48];
    int secs = (Valid(t) && g_tankSince[t] > 0.0) ? RoundToFloor(GetGameTime() - g_tankSince[t]) : -1;
    Format(extra, sizeof(extra), "lived=%ds solo=%d", secs, e.GetBool("solo"));
    if (Valid(t)) g_tankSince[t] = 0.0;
    Log2("tank_killed", U(e, "attacker"), t, extra);
}

// ---------- safe room ----------

// The game fires this for the start room too, so only count it after someone has left the start area.
public void Ev_Checkpoint(Event e, const char[] n, bool nb)
{
    int c = U(e, "userid");
    if (!g_leftStart || !Valid(c) || GetClientTeam(c) != 2 || !IsPlayerAlive(c) || g_safe[c]) return;
    g_safe[c] = true;
    g_safeCount++;
    char extra[16];
    Format(extra, sizeof(extra), "order=%d", g_safeCount);
    Log1("safe_room", c, extra);
}

// ---------- difficulty, votes, ping ----------

public void Cv_Difficulty(ConVar cv, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue, false)) LogToGame("%s difficulty %s was=%s humans=%d", TAG, newValue, oldValue, Humans());
}

// issue is the game's own text id, like #L4D_vote_change_difficulty; param is its value, like Expert
public void Ev_VoteStarted(Event e, const char[] n, bool nb)
{
    char issue[64], param[64], extra[160];
    e.GetString("issue", issue, sizeof(issue));
    e.GetString("param1", param, sizeof(param));
    ReplaceString(param, sizeof(param), "\"", "'");
    Format(extra, sizeof(extra), "issue=%s param=\"%s\"", issue, param);
    int c = e.GetInt("initiator");
    if (Valid(c)) Log1("vote_started", c, extra);
    else LogToGame("%s vote_started %s", TAG, extra);
}

public void Ev_VotePassed(Event e, const char[] n, bool nb)
{
    char details[64], param[64];
    e.GetString("details", details, sizeof(details));
    e.GetString("param1", param, sizeof(param));
    ReplaceString(param, sizeof(param), "\"", "'");
    LogToGame("%s vote_passed issue=%s param=\"%s\"", TAG, details, param);
}

public void Ev_VoteFailed(Event e, const char[] n, bool nb) { LogToGame("%s vote_failed", TAG); }

// two-letter country code (?? if unknown); the address stays in memory and is never logged
void Country(int c, char cc[3])
{
    char ip[64];
    if (!GetClientIP(c, ip, sizeof(ip)) || !GeoipCode2(ip, cc)) strcopy(cc, sizeof(cc), "??");
}

public void OnClientPostAdminCheck(int c)
{
    if (IsFakeClient(c)) return;
    char cc[3], extra[16];
    Country(c, cc);
    Format(extra, sizeof(extra), "country=%s", cc);
    Log1("join", c, extra);
}

// average ping over their stay, so we can see how far away players are and whether high ping makes them leave sooner
public void OnClientDisconnect(int c)
{
    if (!IsClientInGame(c) || IsFakeClient(c)) return;
    char cc[3], extra[64];
    Country(c, cc);
    Format(extra, sizeof(extra), "country=%s ping=%d minutes=%d", cc, RoundToNearest(GetClientAvgLatency(c, NetFlow_Both) * 1000.0), RoundToFloor(GetClientTime(c) / 60.0));
    Log1("disconnect", c, extra);
}
