void Hud_OnPlayerDisconnect(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt( "userid" ));
	if(!client || (IsClientConnected(client) && !IsClientInGame(client))) return; 
	
	Neko_ClientInfo[client].Reset();
	
	if(IsPlayerTank(client))
		CreateTimer(0.5, Timer_DelayDeath);
}

void NekoKillHUD_OnClientConnected(int client)
{
	Neko_ClientInfo[client].Reset();
}

void NekoKillHUD_OnMapStart()
{
	HudRunning = false;
	ResetHudSolt();
	StyleChatDelay = NCvar_NekoKillHud[CKillHud_StyleChatDelay].IntValue;
	StartCatchTime();
}

void NekoKillHUD_OnConfigsExecuted()
{
	if(!IsMapTransition)
		Neko_GlobalState.ResetGO();
	else
		IsMapTransition = false;
}

void NekoKillHUD_OnMapEnd()
{
	HudRunning = false;
	ResetHudSolt();
}

Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int damage = GetEventInt(event, "dmg_health");
		
	if (IsValidClient(victim) && IsValidClient(attacker) && victim != attacker && GetClientTeam(victim) == 2 && !IsFakeClient(attacker))
	{
		Neko_ClientInfo[victim].Friendly_Hurt += damage;
		Neko_ClientInfo[attacker].Friendly_Fire += damage;
	}
	
	if (TankAlive && IsPlayerTank(victim) && IsValidClient(attacker) && GetClientTeam(attacker) == 2 && !IsTankIncapacitated(victim))
		Neko_ClientInfo[attacker].DmgToTank += damage;
	
	return Plugin_Continue;
}

Action Timer_DelayDeath(Handle hTimer)
{
	if(IsTankLive())
		TankAlive = true;
	else
	{
		TankAlive = false;
		if(NCvar_NekoKillHud[CKillHud_KillTank].BoolValue && NCvar_NekoKillHud[CKillHud_HudStyle].IntValue > 0)
			CreateTimer(0.1, KillTankHUD);
	}
	return Plugin_Continue;
}

Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	HudRunning = false;
	
	Kill_Init();
	
	CreateTimer(0.2, RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

static Action RoundStart(Handle Timer)
{
	if(NCvar_NekoKillHud[CKillHud_Show].BoolValue)
		CreateTimer(1.0, Timer_PlayerLeftStart, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else
		CreateHud();
	return Plugin_Continue;
}

static Action Timer_PlayerLeftStart(Handle Timer)
{
	if(L4D_HasAnySurvivorLeftSafeArea())
	{
		CreateHud();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	HudRunning = false;
	Kill_Init();
	return Plugin_Continue;
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt( "userid" ));
	int attacker = GetClientOfUserId(event.GetInt( "attacker"));
	
	if(IsValidClient(victim) && GetClientTeam(victim) == 3 && !IsPlayerTank(victim) && IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		Neko_ClientInfo[attacker].Kill_Infected ++;
		Neko_GlobalState.Kill_AllInfected ++;
		Neko_GlobalState.Kill_AllInfectedGO ++;
	}
	
	return Plugin_Continue;
}

Action Event_infectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt( "attacker"));
	
	if(IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		Neko_GlobalState.Kill_AllZombie ++;
		Neko_GlobalState.Kill_AllZombieGO ++;
		Neko_ClientInfo[attacker].Kill_Zombie ++;
	}
	
	return Plugin_Continue;
}

Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	IsMapTransition = true;
	return Plugin_Continue;

}
