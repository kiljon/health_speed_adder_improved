#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "4.0"
#define MAX_UNIT_TYPES 4
#define MAX_UNITMESS_LENGTH 5

new Handle:g_hTimer_Think = INVALID_HANDLE;
new Handle:g_cvarDisplayTick = INVALID_HANDLE;
new Float:g_fPlugin_DisplayTick = 0.0;
new Handle:g_cvarUnit = INVALID_HANDLE;

new Handle:g_FFA;
new Handle:g_HealthAdd;
new Handle:g_HealthLimit;
new Handle:g_HealthAddEnable;
new Handle:g_SpeedDefault;
new Handle:g_SpeedLimit;
new Handle:g_SpeedEnable;
new Handle:g_SpeedMulti;
new Handle:g_SpeedHintEnable;
new Handle:g_MSG;
new Handle:g_HeadShotAdd;
new Handle:g_KnifeAdd;
new Handle:g_SpeedHeadshot;
new Handle:g_SpeedKnife;

new g_iPlugin_Unit = 0;
new String:g_szUnitMess_Name[MAX_UNIT_TYPES][MAX_UNITMESS_LENGTH] = {
	
	"km/h",
	"mph",
	"u/s",
	"m/s"
};
new Float:g_fUnitMess_Calc[MAX_UNIT_TYPES] = {
	
	0.04263157894736842105263157894737,
	0.05681807590283512505382617918945,
	1.0,
	0.254
};


public Plugin:myinfo =
{
	name = "Health and Speed Adder",
	author = "AbNeR_CSS and Arkarr",
	description = "Health and Speed Bonus by kill a enemy",
	version = PLUGIN_VERSION,
	url = "www.tecnohardclan.com"
};

public OnPluginStart()
{  
	//Cvars
	AutoExecConfig(true, "health_speed_adder");
	CreateConVar("health_speed_adder_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_FFA = CreateConVar("health_speed_adder_ffa", "0", "When enable the plugin works with ffa mode", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAddEnable = CreateConVar("health_add_enable", "1", "Active the health bonus when kill", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAdd = CreateConVar("health_add", "10", "Amount of life added by kill", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthLimit = CreateConVar("health_limit", "0", "Max health added by kill, 0 to disable", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedEnable = CreateConVar("speed_add_enable", "1", "Active speed bonus when kill", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedMulti = CreateConVar("speed_add", "100", "Amount of speed added by kill", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedLimit = CreateConVar("speed_limit", "800", "Max amount of speed after killing", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedHintEnable = CreateConVar("speed_hint_enable", "1", "Show a hint with the speed", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedDefault = CreateConVar("speed_default", "260", "Default speed of a player default value is 260", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedHeadshot = CreateConVar("speed_headshot_add", "50", "Default speed of a player default value is 260", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedKnife = CreateConVar("speed_knife_add", "100", "Default speed of a player default value is 260", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_MSG = CreateConVar("health_speed_msg", "1", "Enable the menssages when kill a player", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HeadShotAdd = CreateConVar("health_headshot_add", "20", "Extra health by headshot", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_KnifeAdd = CreateConVar("health_knife_add", "50", "Extra health by knifekill", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_cvarDisplayTick = CreateConVar("hint_tick", "0.2", "This sets how often the display is redrawn (this is the display tick rate).", FCVAR_NOTIFY);
	g_cvarUnit = CreateConVar("speed_unit", "0", "Unit of measurement of speed (0=kilometers per hour, 1=miles per hour, 2=units per second, 3=meters per second)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	
	g_fPlugin_DisplayTick = GetConVarFloat(g_cvarDisplayTick);
	g_iPlugin_Unit = GetConVarInt(g_cvarUnit);
	
	HookEvent("player_death", PlayerDeath); 
	HookEvent("player_spawn", PlayerSpawn); 
	
	LoadTranslations("common.phrases");
	LoadTranslations("health_speed_adder.phrases");
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(userid, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_SpeedDefault)/260); 
	//PrintToChatAll("%f", GetConVarFloat(g_SpeedDefault)/260);
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new killer = GetClientOfUserId(GetEventInt(event, "attacker")); 
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	decl String:sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	//The default speed is 260 so to get the speed vector like 2.0 or 3.0  you need to divide the speed by 260 
	
	if(!IsValidClient(killer))
	{
		return Plugin_Continue;
	}
	
	if((killer == 0) || !IsPlayerAlive(killer))
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(killer) == GetClientTeam(victim) && GetConVarInt(g_FFA) == 0)
	{
		return Plugin_Handled;
	}
	
	if(GetConVarInt(g_HealthAddEnable) != 0)
	{
		new vida = GetClientHealth(killer);
		new nvida = vida + GetConVarInt(g_HealthAdd);	
		if (GetEventBool(event, "headshot"))
		{
			nvida = nvida + GetConVarInt(g_HeadShotAdd);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_HeadShotAdd) != 0)
			{
				//PrintToChat(killer, "+%dHP by HeadShot Kill", nvida - vida);
				PrintToChat(killer, "\x01%t", "HeadShotHealth", nvida - vida);
			}
		}
		
		if (!GetEventBool(event, "headshot") && !StrEqual(sWeapon, "knife"))
		{
			//PrintToChat(killer, "+%dHP by Kill Enemy", nvida - vida);
			PrintToChat(killer, "\x01%t", "KillHealth", nvida - vida);
		}
		
		if(StrEqual(sWeapon, "knife") && GetConVarInt(g_KnifeAdd) != 0)
		{
			nvida = nvida + GetConVarInt(g_KnifeAdd);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_KnifeAdd) != 0)
			{
				//PrintToChat(killer, "+%dHP by Knife Kill", nvida - vida);
				PrintToChat(killer, "\x01%t", "KnifeHealth", nvida - vida);
			}
		}
		
		if(GetConVarInt(g_HealthLimit) != 0)
		{
			if(nvida <= GetConVarInt(g_HealthLimit))
			{
				SetEntityHealth(killer, nvida);
			}
			if(nvida > GetConVarInt(g_HealthLimit) && vida < GetConVarInt(g_HealthLimit))
			{
				SetEntityHealth(killer, GetConVarInt(g_HealthLimit));
			}
		}
		else
		{
			SetEntityHealth(killer, nvida);
		}
	}
	
	
	if(GetConVarInt(g_SpeedEnable) != 0)
	{
		new Float:speed = GetEntPropFloat(killer, Prop_Send, "m_flMaxspeed")+GetConVarInt(g_SpeedMulti);
		if (speed > GetConVarFloat(g_SpeedLimit))
		{
			speed = GetConVarFloat(g_SpeedLimit);
		}
		if (GetEventBool(event, "headshot"))
		{
			speed = speed + GetConVarInt(g_SpeedHeadshot);
			if (speed > GetConVarFloat(g_SpeedLimit))
			{
				speed = GetConVarFloat(g_SpeedLimit);
			}
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_SpeedHeadshot) != 0)
			{
				//PrintToChat(killer, "+%0.2f speed by HeadShot Kill", (speed - GetConVarInt(g_SpeedDefault))/260);
				PrintToChat(killer, "\x01%t", "HeadShotSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
			}
		}
		if (!GetEventBool(event, "headshot") && !StrEqual(sWeapon, "knife"))
		{
			PrintToChat(killer, "\x01%t", "KillSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
		}
		
		if(StrEqual(sWeapon, "knife") && GetConVarInt(g_SpeedKnife) != 0)
		{
			speed = speed + GetConVarInt(g_SpeedKnife);
			if (speed > GetConVarFloat(g_SpeedLimit))
			{
				speed = GetConVarFloat(g_SpeedLimit);
			}
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_SpeedKnife) != 0)
			{
				PrintToChat(killer, "\x01%t", "KnifeSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
			}
		}
		SetEntPropFloat(killer, Prop_Send, "m_flMaxspeed", speed);
		SetEntPropFloat(killer, Prop_Data, "m_flLaggedMovementValue", speed/260); 
	}
	

	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public Action:Timer_Think(Handle:timer)
{
	// If a vote is in progress then remember it, it may not show the speedmeter
	new bool:voteInProgress = false;
	if (IsVoteInProgress())
	{
		voteInProgress = true;
	}

	new Float:speed = 0.0;
	for (new client=1; client<=MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsClientAuthorized(client) || IsFakeClient(client) || voteInProgress)
		{
			continue;
		}
		if (IsPlayerAlive(client))
		{
			speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
			//ShowSpeedMeter(client, voteInProgress);
			PrintHintText(client, "%t\n%.1f %s", "Speed", speed * g_fUnitMess_Calc[g_iPlugin_Unit], g_szUnitMess_Name[g_iPlugin_Unit]);
		}
		else if (IsClientObserver(client))
		{
			continue;
		}
		else
		{
			// Something went wrong, client is not alive and not spectating
			continue;
		}
	}
	
}

public OnConfigsExecuted()
{
	
	// Verify that the timer for the plugin is invalid
	if (g_hTimer_Think == INVALID_HANDLE && GetConVarInt(g_SpeedHintEnable) != 0)
	{
		// Start timer for the plugin
		g_hTimer_Think = CreateTimer(g_fPlugin_DisplayTick, Timer_Think, INVALID_HANDLE, TIMER_REPEAT);
	}
}