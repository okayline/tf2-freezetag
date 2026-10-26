// Reserved 5th slot for admins. The server allows 5 (via l4dtoolz sv_maxplayers 5),
// but when a non-admin joins and more than 4 humans are on, they are kicked with "server full".
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = { name = "88x31 reserved slot", author = "88x31", description = "5th slot for admins only", version = "1.2", url = "" };

ConVar g_public;

public void OnPluginStart()
{
    g_public = CreateConVar("l4d_public_slots", "4", "Slots anyone can use; the rest are for admins");
}

int Humans()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i) || IsFakeClient(i)) continue;
        // an admin sitting in spectator (idle/afk) does not take a public slot
        if (IsClientInGame(i) && GetClientTeam(i) == 1 && GetUserAdmin(i) != INVALID_ADMIN_ID) continue;
        n++;
    }
    return n;
}

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client)) return;
    if (GetUserAdmin(client) == INVALID_ADMIN_ID) ReleaseIdleAdmins();
    if (Humans() <= g_public.IntValue) return;
    if (GetUserAdmin(client) != INVALID_ADMIN_ID) return;
    KickClient(client, "Server is full (4/4)");
}

// An admin who used "take a break" (idle) still owns their survivor bot. When a regular player joins,
// free those bots so the newcomer can take one; the admin stays on as a spectator.
void ReleaseIdleAdmins()
{
    for (int b = 1; b <= MaxClients; b++) {
        if (!IsClientInGame(b) || !IsFakeClient(b) || GetClientTeam(b) != 2) continue;
        if (!HasEntProp(b, Prop_Send, "m_humanSpectatorUserID")) continue;
        int owner = GetClientOfUserId(GetEntProp(b, Prop_Send, "m_humanSpectatorUserID"));
        if (owner > 0 && GetUserAdmin(owner) != INVALID_ADMIN_ID) {
            SetEntProp(b, Prop_Send, "m_humanSpectatorUserID", 0);
            PrintToChat(owner, "\x04[88x31]\x01 A new player joined, so your survivor went to them. Type !back when a spot opens.");
        }
    }
}
