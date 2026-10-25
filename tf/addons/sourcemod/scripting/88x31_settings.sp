#include <sourcemod>

public Plugin myinfo =
{
	name = "88x31 Settings",
	author = "okayline",
	description = "Runs cfg/88x31.cfg after all other config files, and greets players with the map pool",
	version = "1.1",
	url = "https://github.com/okayline/tf2-freezetag"
};

public void OnConfigsExecuted()
{
	ServerCommand("exec 88x31.cfg");
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		CreateTimer(5.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Welcome(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}

	Panel panel = new Panel();
	panel.SetTitle("Hi!");
	panel.DrawText("Map pool:");

	File f = OpenFile("cfg/mapcycle.txt", "r");
	if (f != null)
	{
		char line[128];
		while (f.ReadLine(line, sizeof(line)))
		{
			TrimString(line);
			if (line[0] != '\0' && line[0] != '/')
			{
				panel.DrawText(line);
			}
		}
		delete f;
	}

	panel.DrawItem("Close", ITEMDRAW_CONTROL);
	panel.Send(client, Welcome_Handler, 30);
	delete panel;
	return Plugin_Stop;
}

public int Welcome_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}
