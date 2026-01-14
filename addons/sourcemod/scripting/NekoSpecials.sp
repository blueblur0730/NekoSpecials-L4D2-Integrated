#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>
#include <binhooks>

// Macros to define whether or not to compile these modules.
#define NEKO_VOTE 1
#define NEKO_SERVERNAME 1
#define NEKO_KILLHUD 1
#define NEKO_ADMINMENU 1

#include "nspecials/globals.sp"
#include "nspecials/general.sp"
#include <neko/nekotools>
#include <neko/nekonative>

#define PLUGIN_VERSION "7.13NS_r1.3"

// Neko Special Modules.
#include "nspecials/native.sp"
#include "nspecials/cmd.sp"
#include "nspecials/hooks.sp"
#include "nspecials/menus.sp"
#include "nspecials/events.sp"
#include "nspecials/timer.sp"
#include "nspecials/frame.sp"
#include "nspecials/api.sp"

public Plugin myinfo =
{
	name		= "[L4D2] Neko Specials Spawner Intergrated",
	description = "Neko Specials Spawner Based on Binhooks",
	author		= "Neko Channel & Mr Cheng, blueblur",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/NekoSpecials-L4D2"
	//请勿修改插件信息！
};

#if NEKO_SERVERNAME
	#include "nservername/neko_servername.sp"
#endif

#if NEKO_VOTE
	#include <l4d2_nativevote>
	#include "nvote/natives.sp"
	#include "nvote/api.sp"
	#include "nvote/hooks.sp"
	#include "nvote/timers.sp"
	#include "nvote/adminmenus.sp"
	#include "nvote/menus.sp"
	#include "nvote/vote.sp"

	#include "nvote/neko_vote.sp"
#endif

#if NEKO_KILLHUD
	#include "nhud/native.sp"
	#include "nhud/event.sp"
	#include "nhud/menu.sp"
	#include "nhud/main.sp"
	#include "nhud/tank.sp"

	#include "nhud/neko_hud.sp"
#endif

#if NEKO_ADMINMENU
	#include <adminmenu>

	#include "nadminmenu/neko_adminmenu.sp"
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	NekoSpecial_AskPluginLoad2();

#if NEKO_VOTE
	NekoVote_CreateNatives();
#endif

#if NEKO_KILLHUD
	NekoKillHUD_CreateNatives();
#endif

#if NEKO_SERVERNAME
	NekoServerName_CreateNatives();
#endif

// Admin menu should always be the last to check other features.
#if NEKO_ADMINMENU
	NekoAdminMenu_CreateNatives();
#endif

	RegPluginLibrary("nekospecials");

	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile(NEKO_SPECIALS_PLUGIN_CONFIG);
	CreateNekoSpecialCvars();

#if NEKO_VOTE
	NekoVote_OnPluginStart();
#endif

#if NEKO_KILLHUD
	NekoKillHUD_OnPluginStart();
#endif

#if NEKO_ADMINMENU
	NekoAdminMenu_OnPluginStart();
#endif

#if NEKO_SERVERNAME
	NekoServerName_OnPluginStart();
#endif

#if NEKO_ADMINMENU
	NekoAdminMenu_OnPluginStart();
#endif

	AutoExecConfig_OnceExec();
	HookNekoSpecialEvent();

	RequestFrame(SetCvarHook);
	RequestFrame(SetAISpawnInit);

	AddCommandListener(ChatListener, "say");
	AddCommandListener(ChatListener, "say2");
	AddCommandListener(ChatListener, "say_team");

	RegAdminCmd("sm_nekotg", OpenSpecialMenu, ADMFLAG_ROOT, "打开Neko多特管理员菜单");
	RegAdminCmd("sm_tgadmin", OpenSpecialMenu, ADMFLAG_ROOT, "打开Neko多特管理员菜单");
	RegAdminCmd("sm_ntg", OpenSpecialMenu, ADMFLAG_ROOT, "打开Neko多特管理员菜单");
	RegAdminCmd("sm_tgmenu", OpenSpecialMenu, ADMFLAG_ROOT, "打开Neko多特管理员菜单");
	RegAdminCmd("sm_ntgversion", SpecialVersionCMD, ADMFLAG_ROOT, "Neko多特版本&状态查询");
	RegAdminCmd("sm_reloadntgconfig", ReloadNTGConfig, ADMFLAG_ROOT, "重载多特配置文件");
	RegAdminCmd("sm_updatentgconfig", UpdateNTGConfig, ADMFLAG_ROOT, "写入多特配置文件");
	RegAdminCmd("sm_resetntgconfig", ReSetNTGConfig, ADMFLAG_ROOT, "重置多特配置文件");
}

#if NEKO_ADMINMENU
public void OnLibraryRemoved(const char[] name)
{
	NekoAdminMenu_OnLibraryRemoved(name);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	NekoAdminMenu_OnAdminMenuReady(aTopMenu);
}
#endif

#if NEKO_KILLHUD
public void OnClientConnected(int client)
{
	NekoKillHUD_OnClientConnected(client);
}
#endif

public void OnConfigsExecuted()
{
	SetAISpawnInit();
	TgModeStartSet();
	UpdateSpawnWeight();
	UpdateSpawnDirChance();
	UpdateSpawnArea();
	UpdateSpawnDistance();

	for (int i = 1; i <= MaxClients; i++)
	{
		CheckBiledTime[i] = 0.0;
		CheckFreeTime[i]  = 0.0;
		CheckNotCombat[i] = 0;
		N_ClientItem[i].Reset();
		N_ClientMenu[i].Reset(true);
	}

#if NEKO_VOTE
	NekoVote_OnConfigsExecuted();
#endif

#if NEKO_KILLHUD
	NekoKillHUD_OnConfigsExecuted();
#endif

#if NEKO_SERVERNAME
	NekoServerName_OnConfigsExecuted();
#endif
}

// Try to fix lag when specials spawn at first time.
public void OnMapStart()
{
#if NEKO_KILLHUD
	NekoKillHUD_OnMapStart();
#endif

#if NEKO_SERVERNAME
	NekoServerName_OnMapStart();
#endif
	CreateTimer(0.1, Timer_SpawnFakeClient);
}

public void OnMapEnd()
{

#if NEKO_KILLHUD
	NekoKillHUD_OnMapEnd();
#endif

	SetSpecialRunning(false);
	IsPlayerLeftCP = false;
}

#if NEKO_SERVERNAME
public void OnGameFrame()
{
	NekoServerName_OnGameFrame();
}
#endif

public void OnClientPostAdminCheck(int client)
{
	CheckBiledTime[client] = 0.0;
	CheckFreeTime[client]  = 0.0;
	CheckNotCombat[client] = 0;
	N_ClientItem[client].Reset();
	N_ClientMenu[client].Reset(true);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
#if NEKO_VOTE
	NekoVote_OnClientSayCommand(client, args);
#endif

	return Plugin_Continue;
}

public Action ChatListener(int client, const char[] command, int args)
{
	NekoSpecials_ChatListener(client);

#if NEKO_VOTE
	NekoVote_ChatListener(client);
#endif

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	NekoSpecials_OnPlayerRunCmd(client, buttons, impulse, weapon, subtype, cmdnum, tickcount, seed);

	return Plugin_Continue;
}

public Action OnPlayerStuck(int client)
{
	NekoSpecials_OnPlayerStuck(client);

	return Plugin_Continue;
}

public Action BinHook_OnSpawnSpecial()
{
	if (!NCvar[CSpecial_Spawn_Tank_Alive].BoolValue && NCvar[CSpecial_Spawn_Tank_Alive_Pro].BoolValue)
	{
		if (L4D2_IsTankInPlay())
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;

				if (GetClientTeam(i) != 3)
					continue;

				if (IsPlayerTank(i))
					continue;

				if (!IsFakeClient(i))
					continue;

				KickClient(i, "Infected Not Allow Spawn");
			}
		}
	}

	if (NCvar[CSpecial_Random_Mode].BoolValue)
		TgModeStartSet();

	if (NCvar[CSpecial_Catch_FastPlayer].BoolValue)
	{
		int client = GetHighestFlowSurvivor();
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			if (GetCurrentFlowDistanceForPlayer(client) - GetAverageSurvivorFlowDistance() >= NCvar[CSpecial_Catch_FastPlayer_CheckDistance].FloatValue)
			{
				SetSpecialSpawnClient(client);
			}
		}
	}

	if (NCvar[CSpecial_Catch_SlowestPlayer].BoolValue)
	{
		int client = GetLowestFlowSurvivor();
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			if (GetAverageSurvivorFlowDistance() - GetCurrentFlowDistanceForPlayer(client) >= NCvar[CSpecial_Catch_SlowestPlayer_CheckDistance].FloatValue)
			{
				SetSpecialSpawnClient(client);
			}
		}
	}

	if (NCvar[CSpecial_Check_IsPlayerNotInCombat].BoolValue)
	{
		for (int i = 0; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && !IsClientInCombat(i))
			{
				SetSpecialSpawnClient(i);
			}
		}
	}

	return Plugin_Continue;
}

#if NEKO_SERVERNAME
public Action NekoSpecials_OnSetSpecialsNum()
{
	SetServerName();
	return Plugin_Continue;
}

public Action NekoSpecials_OnSetSpecialsTime()
{
	SetServerName();
	return Plugin_Continue;
}

public Action NekoSpecials_OnStartFirstSpawn()
{
	SetServerName();
	return Plugin_Continue;
}
#endif
