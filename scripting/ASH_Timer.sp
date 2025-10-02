#include <sourcemod>
#include <saxtonhale>
#include <sdktools>

#pragma newdecls required

ConVar g_cvTime;
ConVar g_cvMinPlayers;

int g_iTime = 120;
int g_iMinPlayers = 1;

Handle g_hHUD;
Handle g_hGuiTimer;

public Plugin myinfo = {
    name        = "[ASH] Time for last players",
    version     = "1.1",
    author      = "ASH Dev Team",
    url         = "https://steamcommunity.com/groups/garage44tf2"
};

public void OnPluginStart()
{
    g_hHUD = CreateHudSynchronizer();

    g_cvTime = CreateConVar("sm_hale_lastplayerstime", "120", "", FCVAR_NOTIFY);
    g_cvTime.AddChangeHook(OnConVarChanged);
    g_cvMinPlayers = CreateConVar("sm_hale_minplayers", "1", "", FCVAR_NOTIFY);
    g_cvMinPlayers.AddChangeHook(OnConVarChanged);

    char szTemp[PLATFORM_MAX_PATH];
    int iAnnouncerEndsTime[] = {60, 30, 10, 5, 4, 3, 2, 1};

    for (int i = 1; i <= 2; i++)
    {
        FormatEx(szTemp, sizeof(szTemp), "vo/announcer_dec_failure0%d.mp3", i);
        PrecacheSound(szTemp, true);
    }
    
    for (int i = 0; i < sizeof(iAnnouncerEndsTime); i++)
    {
        FormatEx(szTemp, sizeof(szTemp), "vo/announcer_ends_%dsec.mp3", iAnnouncerEndsTime[i]);
        PrecacheSound(szTemp, true);
    }
    
    for (int i = 2; i <= 4; i++)
    {
        FormatEx(szTemp, sizeof(szTemp), "vo/announcer_am_lastmanforfeit0%d.mp3", i);
        PrecacheSound(szTemp, true);
    }
}

public void OnConfigsExecuted()
{
    char szData[24];

    g_cvTime.GetString(szData, sizeof(szData));
    g_iTime = StringToInt(szData);

    g_cvMinPlayers.GetString(szData, sizeof(szData));
    g_iMinPlayers = StringToInt(szData);
}

public void OnConVarChanged(ConVar hConvar, const char[] szOldValue, const char[] szNewValue)
{
    if (hConvar == g_cvTime)
    {
        g_iTime = StringToInt(szNewValue);
    }
    else if (hConvar == g_cvMinPlayers)
    {
        g_iMinPlayers = StringToInt(szNewValue);
    }
}

public void OnMapStart()
{
    CreateTimer(0.5, WaitingLastPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action WaitingLastPlayers(Handle hTimer)
{
    if (!VSH_IsSaxtonHaleModeEnabled() || VSH_GetRoundState() != VSHRState_Active || g_hGuiTimer)
    {
        return Plugin_Continue;
    }

    int iBossTeam = VSH_GetSaxtonHaleTeam();
    int iPlayers = 0;

    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (!IsClientConnected(iClient) || !IsClientInGame(iClient)) continue;
        if (GetClientTeam(iClient) == iBossTeam || !IsPlayerAlive(iClient)) continue;

        iPlayers++;
    }
    
    if (iPlayers > 0 && iPlayers <= g_iMinPlayers)
    {
        g_hGuiTimer = CreateTimer(0.1, TimerRenderUi, g_iTime);
    }
    
    return Plugin_Continue;
}

public Action TimerRenderUi(Handle hTimer, any iTimeCounter)
{
    if (VSH_GetRoundState() != VSHRState_Active)
    {
        g_hGuiTimer = null;
        return Plugin_Stop;
    }
    
    if (!iTimeCounter)
    {
        SetWinner(0, true);
        CreateTimer(2.0, RandomSound_Timer);
        g_hGuiTimer = null;
        return Plugin_Stop;
    }
    
    // Sounds
    switch (iTimeCounter)
    {
        case 60:    PlaySoundForAll("vo/announcer_ends_60sec.mp3");
        case 30:    PlaySoundForAll("vo/announcer_ends_30sec.mp3");
        case 10:    PlaySoundForAll("vo/announcer_ends_10sec.mp3");
        case 5:     PlaySoundForAll("vo/announcer_ends_5sec.mp3");
        case 4:     PlaySoundForAll("vo/announcer_ends_4sec.mp3");
        case 3:     PlaySoundForAll("vo/announcer_ends_3sec.mp3");
        case 2:     PlaySoundForAll("vo/announcer_ends_2sec.mp3");
        case 1:     PlaySoundForAll("vo/announcer_ends_1sec.mp3");
    }

    // Format time
    char szFormattedTime[20];
    FormatTime(szFormattedTime, sizeof(szFormattedTime), "%M:%S", iTimeCounter);

    // HUD
    SetHudTextParams(-1.0, 0.25, 1.25, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
        {
            continue;
        }

        ShowSyncHudText(iClient, g_hHUD, szFormattedTime);
    }

    g_hGuiTimer = CreateTimer(1.0, TimerRenderUi, iTimeCounter-1);    
    return Plugin_Stop;
}

public Action RandomSound_Timer(Handle hTimer)
{
    RandomSound_End();

    return Plugin_Continue;
}

public void RandomSound_End() {
    switch (GetRandomInt(0, 4))
    {
        case 0: PlaySoundForAll("vo/announcer_am_lastmanforfeit02.mp3");
        case 1: PlaySoundForAll("vo/announcer_am_lastmanforfeit03.mp3");
        case 2: PlaySoundForAll("vo/announcer_am_lastmanforfeit04.mp3");
        case 3: PlaySoundForAll("vo/announcer_dec_failure01.mp3");
        case 4: PlaySoundForAll("vo/announcer_dec_failure02.mp3");
    }
}

stock void KillAll()
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientConnected(iClient) && GetClientTeam(iClient) > 1)
            ForcePlayerSuicide(iClient);
    }
}

stock void SetWinner(int iWinTeam = 0, bool bWithEntity = true)
{
    if (bWithEntity)
    {
        int iEnt = -1;
        iEnt = FindEntityByClassname(iEnt, "game_round_win");
        
        if (iEnt < 1)
        {
            iEnt = CreateEntityByName("game_round_win");
            if (IsValidEntity(iEnt))
            {
                DispatchSpawn(iEnt);
            }
            else
            {
                SetWinner(iWinTeam, false);
                return;
            }
            
            SetVariantInt(iWinTeam);
            AcceptEntityInput(iEnt, "SetTeam");
            AcceptEntityInput(iEnt, "RoundWin");
        }
    }
    else
    {
        int iFlags = GetCommandFlags("mp_forcewin");
        SetCommandFlags("mp_forcewin", iFlags & ~FCVAR_CHEAT);
        ServerCommand("mp_forcewin %i", iWinTeam);
        SetCommandFlags("mp_forcewin", iFlags);
    }
}

stock void PlaySound(int iClient, char[] szSound)
{
    ClientCommand(iClient, "play %s", szSound);
}
    
stock void PlaySoundForAll(char[] szSound)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientConnected(iClient) && !IsFakeClient(iClient))
            PlaySound(iClient, szSound);
    }
}
