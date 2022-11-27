/*	Copyright (C) 2021 y0ung
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

#pragma semicolon 1
#pragma newdecls required
#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <chat-processor>

#define MAXTAGS 16 

int g_iTags;
int g_iTag[MAXPLAYERS + 1];
char g_sTag[MAXTAGS][32];
char g_sFlags[MAXTAGS][16];
char g_sTagChat[MAXTAGS][64];


public Plugin myinfo =  {
	name = "[ CSGO ] yTags", 
	author = "y0ung [ Thanks Pawel for help ]", 
	description = "[ Plugin sets tags in table and in chat ]", 
	version = "1.0.2", 
	url = "feelthegame.eu"
};


public void OnPluginStart() {
	HookEvent("player_spawn", EventSetTag);
	RegAdminCmd("sm_reloadtags", ReloadTags, ADMFLAG_GENERIC);
}

public Action ReloadTags(int client, int args) {
	LoadConfig();
	for (int i = 0; i < MaxClients; i++)
	if (IsValidClient(i))
		SetTag(i);
}

public Action EventSetTag(Event event, const char[] name, bool dontbrodcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
		SetTag(client);
}

void SetTag(int client) {
	for (int j = 1; j <= g_iTags; j++) {
		if (g_iTag[client] == 0 && CheckFlags(client, g_sFlags[j])) {
			g_iTag[client] = j;
		}
	}
	CreateTimer(2.0, timer_forcetag, client);
}

public Action timer_forcetag(Handle hTimer, int client) {
	if (IsValidClient(client)) {
		CS_SetClientClanTag(client, g_sTag[g_iTag[client]]);
	}
}

public void OnClientPutInServer(int client) {
	if (IsValidClient(client))
		g_iTag[client] = 0;
}

public void OnClientDisconnect(int client) {
	if (IsValidClient(client))
		g_iTag[client] = 0;
}

public void OnMapStart() {
	CreateTimer(30.0, Timer_SetTag, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted() {
	LoadConfig();
}

void LoadConfig() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/yTags.cfg");
	KeyValues kv = new KeyValues("yTags - Config");
	if (!kv.ImportFromFile(sPath)) {
		if (!FileExists(sPath)) {
			if (GenerateConfig())
				LoadConfig();
			else
				SetFailState("[ X yTags X ] Nie udało się utworzyć pliku konfiguracyjnego!");
			delete kv;
			return;
		}
		else {
			if (GenerateConfig())
				LoadConfig();
			else
				SetFailState("[ X yTags X ] Nie udało się utworzyć pliku konfiguracyjnego!");
			delete kv;
			return;
		}
	}
	kv.GotoFirstSubKey();
	g_iTags = 0;
	char sTag[32], sFlags[16], sChatTag[64];
	do {
		g_iTags++;
		kv.GetSectionName(sTag, sizeof(sTag));
		g_sTag[g_iTags] = sTag;
		kv.GetString("chattag", sChatTag, sizeof(sChatTag));
		g_sTagChat[g_iTags] = sChatTag;
		kv.GetString("flags", sFlags, sizeof(sFlags));
		g_sFlags[g_iTags] = sFlags;
	}
	while (kv.GotoNextKey());
	kv.GoBack();
	delete kv;
}

bool GenerateConfig() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/yTags.cfg");
	KeyValues kv = new KeyValues("yTags - Config");
	if (kv.JumpToKey("Wlasciciel", true)) {
		kv.SetString("flags", "z");
		kv.SetString("chattag", "{darkred}Wlasciciel");
		kv.GoBack();
	}
	kv.Rewind();
	bool result = kv.ExportToFile(sPath);
	delete kv;
	return result;
}

public Action CP_OnChatMessage(int & author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors) {
	if (g_iTag[author] == 0)
		return Plugin_Continue;
	Format(name, MAXLENGTH_NAME, " %s {teamcolor}%s", g_sTagChat[g_iTag[author]], name);
	Format(message, MAXLENGTH_MESSAGE, "%s", message);
	return Plugin_Changed;
}

public Action Timer_SetTag(Handle hTimer) {
	for (int j = 1; j <= g_iTags; j++) {
		for (int i = 0; i < MaxClients; i++) {
			if (IsValidClient(i)) {
				if (g_iTag[i] == 0 && CheckFlags(i, g_sFlags[j])) {
					g_iTag[i] = j;
					CS_SetClientClanTag(i, g_sTag[j]);
				}
				else
					CS_SetClientClanTag(i, g_sTag[g_iTag[i]]);
			}
		}
	}
}

bool CheckFlags(int client, char[] sFlags) {
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)return true;
	if (GetUserFlagBits(client) & ReadFlagString(sFlags))return true;
	if (StrEqual(sFlags, ""))return true;
	
	return false;
}

bool IsValidClient(int client) {
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}

/* © 2020 Coded with ❤ for clients		  */