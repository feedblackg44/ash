#include <sourcemod>
#include <saxtonhale>
#include <sdktools>

#pragma newdecls required

ConVar g_cvTime;
int iTime;
Handle g_hHUD;
Handle hTimerr;

public Plugin myinfo = {
    name        = "[ASH] Time for last players",
    version     = "1.0",
    author      = "ASH Dev Team",
    url         = "https://steamcommunity.com/groups/garage44tf2"
};

public void OnPluginStart() {
    g_hHUD = CreateHudSynchronizer();

    iTime = 120;
    g_cvTime = CreateConVar("sm_hale_lastplayerstime", "120", "", FCVAR_NOTIFY|FCVAR_REPLICATED);
    g_cvTime.AddChangeHook(OnConVarChanged);
    
    char Temp[64];
    int AnnouncerEndsTime[] = {60, 30, 10, 5, 4, 3, 2, 1};
    
    for (int i = 1; i<=2; i++) {
        FormatEx(Temp, 64, "vo/announcer_dec_failure0%d.mp3", i);
        PrecacheSound(Temp, true);
    }
    
    for (int i = 0; i<8; i++) {
        FormatEx(Temp, 64, "vo/announcer_ends_%dsec.mp3", AnnouncerEndsTime[i]);
        PrecacheSound(Temp, true);
    }
    
    for (int i = 2; i<=4; i++) {
        FormatEx(Temp, 64, "vo/announcer_am_lastmanforfeit0%d.mp3", i);
        PrecacheSound(Temp, true);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    iTime = StringToInt(newValue);
}

public void OnMapStart() {
    CreateTimer(0.5, WaitingLastPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action WaitingLastPlayers(Handle hTimer) {
    if (!VSH_IsSaxtonHaleModeEnabled() || VSH_GetRoundState() != VSHRState_Active)
        return Plugin_Continue;
    
    int ClientTeam = GetAnotherTeam();
    int iPlayers = 0;
    
    for (int iPly = 1; iPly<=MaxClients; iPly++) {
        if (!IsClientConnected(iPly) || !IsClientInGame(iPly)) continue;
        if (GetClientTeam(iPly) != ClientTeam || !IsPlayerAlive(iPly)) continue;
        iPlayers++;
    }
    
    if (iPlayers == 1 && !hTimerr)
        hTimerr = CreateTimer(0.1, TimerCenter, iTime);
    
    return Plugin_Continue;
}

public Action TimerCenter(Handle hTimer, any iLastTime) {
    if (VSH_GetRoundState() != VSHRState_Active) {
        hTimerr = null;
        return Plugin_Stop;
    }
    
    if (!iLastTime) {
        SetWinner();
        CreateTimer(2.0, RandomSound_Timer);
        hTimerr = null;
        return Plugin_Stop;
    }
    
    // Format time
    char sFormattedTime[20];
    FormatTime(sFormattedTime, sizeof(sFormattedTime), "%M:%S", iLastTime);
    
    // Sounds
    switch (iLastTime) {
        case 60:    PlaySoundForAll("vo/announcer_ends_60sec.mp3");
        case 30:    PlaySoundForAll("vo/announcer_ends_30sec.mp3");
        case 10:    PlaySoundForAll("vo/announcer_ends_10sec.mp3");
        case 5:     PlaySoundForAll("vo/announcer_ends_5sec.mp3");
        case 4:     PlaySoundForAll("vo/announcer_ends_4sec.mp3");
        case 3:     PlaySoundForAll("vo/announcer_ends_3sec.mp3");
        case 2:     PlaySoundForAll("vo/announcer_ends_2sec.mp3");
        case 1:     PlaySoundForAll("vo/announcer_ends_1sec.mp3");
    }
    
    // HUD
    SetHudTextParams(-1.0, 0.25, 1.25, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
    for (int iPly = 1; iPly <= MaxClients; iPly++) {
        if (!IsClientConnected(iPly) || !IsClientInGame(iPly))
            continue;
        
        ShowSyncHudText(iPly, g_hHUD, sFormattedTime);
    }
    hTimerr = CreateTimer(1.0, TimerCenter, iLastTime-1);
    
    return Plugin_Stop;
}

public Action RandomSound_Timer(Handle hTimer) {
    RandomSound_End();
}

public void RandomSound_End() {
    switch (GetRandomInt(0,4)) {
        case 0: PlaySoundForAll("vo/announcer_am_lastmanforfeit02.mp3");
        case 1: PlaySoundForAll("vo/announcer_am_lastmanforfeit03.mp3");
        case 2: PlaySoundForAll("vo/announcer_am_lastmanforfeit04.mp3");
        case 3: PlaySoundForAll("vo/announcer_dec_failure01.mp3");
        case 4: PlaySoundForAll("vo/announcer_dec_failure02.mp3");
    }
}

public int GetAnotherTeam() {
    if (VSH_GetSaxtonHaleTeam() == 2)
        return 3;
    else
        return 2;
}

stock void KillAll() {
    for (int ply = 1; ply<=MaxClients; ply++) {
        if (IsClientConnected(ply) && GetClientTeam(ply) > 1)
            ForcePlayerSuicide(ply);
    }
}

stock void SetWinner(int iWinTeam = 0, bool bWithEntity = true) {
    if (bWithEntity) {
        int iEnt = -1;
        iEnt = FindEntityByClassname(iEnt, "game_round_win");
        
        if (iEnt < 1)
        {
            iEnt = CreateEntityByName("game_round_win");
            if (IsValidEntity(iEnt))
                DispatchSpawn(iEnt);
            else {
                SetWinner(iWinTeam, false);
                return;
            }
            
            SetVariantInt(iWinTeam);
            AcceptEntityInput(iEnt, "SetTeam");
            AcceptEntityInput(iEnt, "RoundWin");
        }
    } else {
        int iFlags = GetCommandFlags("mp_forcewin");
        SetCommandFlags("mp_forcewin", iFlags & ~FCVAR_CHEAT);
        ServerCommand("mp_forcewin %i", iWinTeam);
        SetCommandFlags("mp_forcewin", iFlags);
    }
}

stock void PlaySound(int ply, char[] sound) {
    ClientCommand(ply, "play %s", sound);
}
    
stock void PlaySoundForAll(char[] sound) {
    for (int ply = 1; ply<=MaxClients; ply++) {
        if (IsClientConnected(ply) && !IsFakeClient(ply))
            PlaySound(ply, sound);
    }
}
