
/*	Copyright (C) 2018 IT-KiLLER
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <multi1v1>
#pragma semicolon 1
#pragma newdecls required

Handle g_DrugTimers[MAXPLAYERS+1];
float g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
UserMsg g_FadeUserMsgId;
ConVar sm_multi1v1_druground_chance;

public Plugin myinfo = 
{
	name = "[multi-1v1] RDR - Random Drug Round",
	author = "IT-KiLLER",
	description = "Randomly selected rounds will be Drug Rounds.",
	version = "1.0 pre-release",
	url = "https://github.com/IT-KiLLER"
}

public void OnPluginStart()
{
	g_FadeUserMsgId = GetUserMessageId("Fade");
	sm_multi1v1_druground_chance = CreateConVar("sm_multi1v1_druground_chance", "20.00", "The chance % to get a drug round. [Default: 20%, 0 = disabled]", _, true, 0.0, true, 100.0);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			KillDrugTimer(client);
		}
	}
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			KillDrugTimer(client);
		}
	}
}

public void Multi1v1_OnRoundTypeDecided(int arena, int player1, int player2, int& roundType)
{
	int rand = GetRandomInt(1, 100);
	// the chance of getting RDR
	if(rand <= sm_multi1v1_druground_chance.IntValue && sm_multi1v1_druground_chance.BoolValue)
	{
		CreateDrug(player1);
		Multi1v1_Message(player1, "\x0FD\x02r\x03u\x04g \x05r\x06o\x07u\x08n\x09d\x0A!"); // Drug round
		CreateDrug(player2);
		Multi1v1_Message(player2, "\x0FD\x02r\x03u\x04g \x05r\x06o\x07u\x08n\x09d\x0A!"); // Drug round
	}
	else
	{
		KillDrugTimer(player1);
		KillDrugTimer(player2);
	}
}

stock void CreateDrug(int client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

stock void KillDrugTimer(int client)
{
	if(g_DrugTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_DrugTimers[client]);
	}
	g_DrugTimers[client] = INVALID_HANDLE;	
}

stock Action Timer_Drug(Handle timer, any client)
{
	if(!IsClientInGame(client) || g_DrugTimers[client] != timer)
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,19)];
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	
	int clients[2];
	clients[0] = client;	
	
	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;
	int color[4] = { 0, 0, 0, 128 };
	color[0] = GetRandomInt(0,255);
	color[1] = GetRandomInt(0,255);
	color[2] = GetRandomInt(0,255);

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
		
	return Plugin_Handled;
}