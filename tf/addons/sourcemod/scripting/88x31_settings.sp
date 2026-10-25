#include <sourcemod>

public Plugin myinfo =
{
	name = "88x31 Settings",
	author = "okayline",
	description = "Runs cfg/88x31.cfg after all other config files, and welcomes players with the map pool",
	version = "1.1",
	url = "https://github.com/okayline/tf2-freezetag"
};

public void OnConfigsExecuted()
{
	ServerCommand("exec 88x31.cfg");
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	Panel panel = new Panel();
	panel.SetTitle("Welcome to ~*~88x31 cLuB~*~ FrEEze tAg SeRveR:  ICEY COLD Edition!");
	panel.DrawText(" ");
	panel.DrawText("Freeze Tag mod with a snowy map pool:");

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
}

public int Welcome_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}
