#include <sourcemod>
#include <events>
#include <tf2>
#include <tf2_stocks>
#include <advancedsaxtonhale>

#define MAX_HEADSHOTS_FOR_ACTIVATION        4

static const int g_iAmbassadorItemDefinitionIndexes[] = { 1006, 61 };
static const char g_szGamemodeLibrary[] = "advancedsaxtonhale";

bool    g_bGamemodeLoaded = false;
bool    g_bIsActivated[MAXPLAYERS+1] = { false, ... };
int     g_iHeadshots[MAXPLAYERS+1] = { 0, ... };

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
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);

    LoadTranslations("ash.phrases");
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

public void OnPlayerHurt(Event hEvent, const char[] szEventName, bool bDontBroadcast)
{
    if (!IsReady())
    {
        return;
    }

    int iHaleTeam = ASH_GetSaxtonHaleTeam(); // потому что есть "миньоны".
    int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

    if (GetClientTeam(iAttacker) == iHaleTeam || TF2_GetPlayerClass(iAttacker) != TFClass_Spy ||
        !IsWeaponSlotActive(iAttacker, TFWeaponSlot_Primary) || !IsWearingAmbassador(iAttacker))
    {
        return;
    }

    int iTarget = GetClientOfUserId(hEvent.GetInt("userid"));
    if (GetClientTeam(iTarget) != iHaleTeam || TF2_IsPlayerInCondition(iTarget, TFCond_MegaHeal)) // _TFCond(28)
    {
        return;
    }

    if (g_bIsActivated[iAttacker])
    {
        ASH_TeleportToMultiMapSpawn(iTarget);
        return;
    }

    if (hEvent.GetInt("custom") == TF_CUSTOM_HEADSHOT)
    {
        g_iHeadshots[iAttacker]++;
    }
}

stock bool IsReady()
{
    if (!g_bGamemodeLoaded) return false;
    if (!ASH_IsSaxtonHaleModeEnabled()) return false;

    return ASH_GetRoundState() == ASHRState_Active;
}

stock bool IsWearingAmbassador(int iTarget)
{
    int iWeaponIndex = GetIndexOfWeaponSlot(iTarget, TFWeaponSlot_Primary);
    for (int iIndex = 0; iIndex < sizeof(g_iAmbassadorItemDefinitionIndexes); ++iIndex)
    {
        if (iWeaponIndex == g_iAmbassadorItemDefinitionIndexes[iIndex])
        {
            return true;
        }
    }

    return false;
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