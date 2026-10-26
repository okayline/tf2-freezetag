// !afk moves you to spectator (a bot takes your survivor), !back puts you back in.
// Works even when you are the only human, unlike the game's own "Take a Break".
#include <sourcemod>

public Plugin myinfo = { name = "88x31 afk", author = "88x31", description = "!afk and !back", version = "1.0", url = "" };

public void OnPluginStart()
{
    RegConsoleCmd("sm_afk", CmdAfk, "Go spectate, a bot takes your place");
    RegConsoleCmd("sm_away", CmdAfk, "Go spectate, a bot takes your place");
    RegConsoleCmd("sm_back", CmdBack, "Come back from spectating");
}

public Action CmdAfk(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    if (GetClientTeam(client) == 1) { ReplyToCommand(client, "[88x31] You're already spectating. Type !back to play."); return Plugin_Handled; }
    ChangeClientTeam(client, 1);
    PrintToChatAll("\x04[88x31]\x01 %N is taking a break.", client);
    return Plugin_Handled;
}

public Action CmdBack(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    if (GetClientTeam(client) != 1) { ReplyToCommand(client, "[88x31] You're already playing."); return Plugin_Handled; }
    // take over a survivor bot right away (sb_takecontrol is a cheat command, so lift the flag for this one call)
    int flags = GetCommandFlags("sb_takecontrol");
    if (flags != INVALID_FCVAR_FLAGS) {
        SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
        FakeClientCommand(client, "sb_takecontrol");
        SetCommandFlags("sb_takecontrol", flags);
    }
    if (GetClientTeam(client) == 1)
        FakeClientCommand(client, "jointeam 2");   // fallback: idle on a bot, click to take over
    PrintToChatAll("\x04[88x31]\x01 %N is back.", client);
    return Plugin_Handled;
}
