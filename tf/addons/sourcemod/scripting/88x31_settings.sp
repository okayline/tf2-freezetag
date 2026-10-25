#include <sourcemod>

public Plugin myinfo =
{
	name = "88x31 Settings",
	author = "okayline",
	description = "Runs cfg/88x31.cfg after all other config files",
	version = "1.0",
	url = "https://github.com/okayline/tf2-freezetag"
};

public void OnConfigsExecuted()
{
	ServerCommand("exec 88x31.cfg");
}
