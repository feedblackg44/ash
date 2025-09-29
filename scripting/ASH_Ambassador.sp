#include <sourcemod>
#include <events>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <advancedsaxtonhale>

#define MAX_HEADSHOTS_FOR_ACTIVATION        4

static const int g_iAmbassadorItemDefinitionIndexes[] = { 1006, 61 };
static const char g_szGamemodeLibrary[] = "advancedsaxtonhale";

bool    g_bGamemodeLoaded = false;
bool    g_bIsActivated[MAXPLAYERS+1] = { false, ... };
int     g_iHeadshots[MAXPLAYERS+1] = { 0, ... };
bool    g_bHooked[MAXPLAYERS+1] = { false, ... };

public Plugin myinfo =
{
    name = "[ASH] Ambassador",
    author = "ASH Dev Team",
    description = "Ambassador functionality for ASH",
    version = "1.0.0",
    url = "https://github.com/feedblackg44/ash"
};

// copied from ASH_Core.sp

char SpyRandomScream[][] = {
    "vo/spy_sf13_influx_big01.mp3",
    "vo/spy_sf13_influx_big02.mp3",
    "vo/spy_sf13_round_start06.mp3",
    "vo/compmode/cm_spy_matchwon_12.mp3",
};

char SpyRandomScream2[][] = {
    "vo/compmode/cm_spy_pregamefirst_10.mp3",
    "vo/compmode/cm_spy_pregamefirst_12.mp3",
    "vo/compmode/cm_spy_pregamelostlast_03.mp3",
    "vo/compmode/cm_spy_pregamewonlast_07.mp3",
};

#define _TFCond(%0) view_as<TFCond>(%0)
stock bool IsWeaponSlotActive(int iClient, int iSlot) { return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"); }
stock bool IsValidClient(int iClient) { return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient)); }

stock int GetIndexOfWeaponSlot(int client, int slot)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

// copied from ASH_Core.sp

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);

    LoadTranslations("ash.phrases");

    for (int iClient = 1; iClient <= MaxClients; ++iClient)
    {
        if (IsValidClient(iClient))
        {
            UTIL_HookClient(iClient);
        }
    }
}

public void OnAllPluginsLoaded()
{
    g_bGamemodeLoaded = LibraryExists(g_szGamemodeLibrary);
    if (g_bGamemodeLoaded)
    {
        ASH_Configure();
    }
}

public void OnLibraryAdded(const char[] szLibraryName)
{
    if (strcmp(g_szGamemodeLibrary, szLibraryName))
    {
        return;
    }

    ASH_Configure();
    g_bGamemodeLoaded = true;
}

public void OnLibraryRemoved(const char[] szLibraryName)
{
    if (strcmp(g_szGamemodeLibrary, szLibraryName))
    {
        return;
    }

    g_bGamemodeLoaded = false;
}

void UTIL_HookClient(int iClient)
{
    if (g_bHooked[iClient]) return;

    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);

    g_bHooked[iClient] = true;
}

void UTIL_UnhookClient(int iClient)
{
    if (!g_bHooked[iClient]) return;

    SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);

    g_bHooked[iClient] = false;
}

public void OnClientPostAdminCheck(int iClient)
{
    g_iHeadshots[iClient] = 0;
    g_bIsActivated[iClient] = false;
    UTIL_HookClient(iClient);
}

public void OnClientDisconnect(int iClient)
{
    UTIL_UnhookClient(iClient);
}

void ASH_Configure()
{
    ASH_Hook(ASHEvent_OnPlayerThink, OnPlayerThink);
    ASH_Hook(ASHEvent_OnPlayerTaunt, OnPlayerTaunt);
}

public void OnPlayerThink(int iClient)
{
    // Если будем это и в Хейле вызывать.
    // if (GetClientTeam(iClient) == ASH_GetSaxtonHaleTeam()) return;

    if (TF2_GetPlayerClass(iClient) != TFClass_Spy) return;
    if (!IsWearingAmbassador(iClient)) return;

    int iHeadshots = g_iHeadshots[iClient];
    bool bCanBeActivated = (iHeadshots >= MAX_HEADSHOTS_FOR_ACTIVATION);
    if (bCanBeActivated)
    {
        iHeadshots = MAX_HEADSHOTS_FOR_ACTIVATION;
    }

    if (bCanBeActivated)
    {
        ASH_SetHUDParams({ 255, 64, 64, 255 });
        ASH_DrawHUD(iClient, ASHPosition_Bottom, "%t", "ash_spy_autoaim_ready");
    }
    else
    {
        ASH_SetHUDParams({ 90, 255, 90, 255 });
        ASH_DrawHUD(iClient, ASHPosition_Bottom, "%t", "ash_spy_autoaim_meter", iHeadshots);
    }

    ASH_SetHUDParams({ 255, 255, 255, 255 });
}

public Action OnPlayerTaunt(int iClient)
{
    if (!IsPlayerAlive(iClient)) // wut??? moved without changes from source code
    {
        return Plugin_Continue;
    }

    int iHaleTeam = ASH_GetSaxtonHaleTeam(); // потому что есть "миньоны".
    if (GetClientTeam(iClient) == iHaleTeam)
    {
        return Plugin_Continue;
    }

    if (TF2_GetPlayerClass(iClient) != TFClass_Spy || g_iHeadshots[iClient] < MAX_HEADSHOTS_FOR_ACTIVATION)
    {
        return Plugin_Continue;
    }

    char szSoundPath[PLATFORM_MAX_PATH];
    FormatEx(szSoundPath, sizeof(szSoundPath), "saxton_hale/spy_special_auto_used.wav");

    g_iHeadshots[iClient] = 0;
    g_bIsActivated[iClient] = true;

    int iUserId = GetClientUserId(iClient);
    CreateTimer(0.1, OnRageActivated, iUserId);
    CreateTimer(0.3, OnRageEffects, iUserId);
    CreateTimer(1.5, OnRageSounds, iUserId);
    CreateTimer(7.0, OnRageAlmostDone, iUserId);
    CreateTimer(9.2, OnRageDone, iUserId);

    float szSoundPosition[3] = { 0.0, 0.0, 20.0 };
    EmitSoundToAll(szSoundPath, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, szSoundPosition, NULL_VECTOR, false, 0.0);

    return Plugin_Handled;
}

public void OnPlayerDeath(Event hEvent, const char[] szEventName, bool bDontBroadcast)
{
    // Тут раньше тоже была проверка, что мы находимся в ASH, но по итогу
    // кажется проще её оставить в соответствующих событиях, а тут просто
    // сбрасывать стейт.

    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    g_bIsActivated[iClient] = false;
    g_iHeadshots[iClient] = 0;
}

public void OnRoundStart(Event hEvent, const char[] szEventName, bool bDontBroadcast)
{
    for (int iClient = 0; iClient < MAXPLAYERS; ++iClient)
    {
        g_bIsActivated[iClient] = false;
        g_iHeadshots[iClient] = 0;
    }
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
    Action result = Plugin_Continue;

    if (!IsReady())
    {
        return result;
    }

    int iHaleTeam = ASH_GetSaxtonHaleTeam(); // потому что есть "миньоны".
    int wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
    
    if (!IsValidClient(attacker) || GetClientTeam(attacker) == iHaleTeam || GetClientTeam(client) != iHaleTeam || 
        TF2_GetPlayerClass(attacker) != TFClass_Spy || !IsWeaponSlotActive(attacker, TFWeaponSlot_Primary) || !IsWearingAmbassador(attacker) ||
        !ItemInArray(wepindex, g_iAmbassadorItemDefinitionIndexes, sizeof(g_iAmbassadorItemDefinitionIndexes)) ||
        inflictor != attacker || TF2_IsPlayerInCondition(client, TFCond_MegaHeal)) // _TFCond(28)
    {
        return result;
    }

    if (damagecustom == TF_CUSTOM_HEADSHOT)
    {
        if (!g_bIsActivated[attacker] && g_iHeadshots[attacker] < MAX_HEADSHOTS_FOR_ACTIVATION)
            g_iHeadshots[attacker]++;
        
        damage = 51.5;
        result = Plugin_Changed;
    }

    if (g_bIsActivated[attacker])
    {
        ASH_TeleportToMultiMapSpawn(client);
        result = Plugin_Changed;
    }

    return result;
}

stock bool IsReady()
{
    if (!g_bGamemodeLoaded) return false;
    if (!ASH_IsSaxtonHaleModeEnabled()) return false;

    return ASH_GetRoundState() == ASHRState_Active;
}
    
stock bool ItemInArray(int item, const int[] array, int iArrayLength)
{
    for (int i = 0; i < iArrayLength; i++) if (item == array[i]) return true;
    return false;
}

stock bool IsWearingAmbassador(int iTarget)
{
    int iWeaponIndex = GetIndexOfWeaponSlot(iTarget, TFWeaponSlot_Primary);
    return ItemInArray(iWeaponIndex, g_iAmbassadorItemDefinitionIndexes, sizeof(g_iAmbassadorItemDefinitionIndexes));
}

/**
 * @section Timers
 */
public Action OnRageActivated(Handle hTimer, int iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (!IsValidClient(iClient))
        return Plugin_Continue;

    if (!GetEntProp(iClient, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(iClient, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(iClient, TFCond_Taunting);
        float pPos[3] = {0.0, 0.0, 10.0};
        ASH_AttachParticle(iClient, "skull_island_embers", 1.0, pPos, true);
        ASH_AttachParticle(iClient, "skull_island_flash", 1.0, pPos, true);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", iClient);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", iClient);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", iClient);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", iClient);
    }
    return Plugin_Continue;
}

public Action OnRageEffects(Handle hTimer, int iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (!IsValidClient(iClient))
        return Plugin_Continue;

    float pPos[3] = {0.0, 0.0, 50.0};
    ASH_AttachParticle(iClient, "outerspace_belt_blue", 6.7, pPos, true);
    return Plugin_Continue;
}

public Action OnRageSounds(Handle hTimer, int iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (!IsValidClient(iClient))
        return Plugin_Continue;

    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, SpyRandomScream[GetRandomInt(0, sizeof(SpyRandomScream)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action OnRageAlmostDone(Handle hTimer, int iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (!IsValidClient(iClient))
        return Plugin_Continue;

    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, SpyRandomScream2[GetRandomInt(0, sizeof(SpyRandomScream2)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action OnRageDone(Handle hTimer, int iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (!IsValidClient(iClient))
        return Plugin_Continue;

    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    g_bIsActivated[iClient] = false;
    return Plugin_Continue;
}