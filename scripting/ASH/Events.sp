// Generic Events
public Action event_round_start(Handle event, const char[] name, bool dontBroadcast)
{
    if (hotnightEnabled) {
        ServerCommand("mp_friendlyfire 0");
        hotnightEnabled = false;
    }

    if (SpecialHHH_Souls != 0) SpecialHHH_Souls = 0;
    HaleState = 1;
    teamplay_round_start_TeleportToMultiMapSpawn(); // Cache spawns
    Vitasaw_ExecutionTimes = 0;
    VagineerTime_GH = 0;
    
    InvisibleAgent = 0.0;
    TimeAbility = 0.0;
    LastSound = 0.0;
    ShieldEnt = -1;
    Stun = 0;
    
    if (ullapoolWarEnabled) {
        ullapoolWarRound = true;
        ullapoolWarMap = false;
        ullapoolWarEnabled = false;
    }
	
    if (BushmanRulesEnabled) {
        BushmanRulesRound = true;
        BushmanRulesMap = false;
       	BushmanRulesEnabled = false;
	}
    
    for (int ply = 0; ply<=MAXPLAYERS; ply++) Holograms[ply] = 0;

    if (!GetConVarBool(cvarEnabled))
    {
#if defined _SteamWorks_Included
        if (g_bAreEnoughPlayersPlaying && g_bSteamWorksIsRunning)
        {
            SteamWorks_SetGameDescription("Adv. Saxton Hale");
        }
#endif
        g_bAreEnoughPlayersPlaying = false;
    }
    g_bEnabled = g_bAreEnoughPlayersPlaying;
    if (CheckNextSpecial() && !g_bEnabled) //QueuePanelH(Handle:0, MenuAction:0, 9001, 0) is HaleEnabled
        return Plugin_Continue;
    if (FileExists("bNextMapToHale"))
        DeleteFile("bNextMapToHale");
    ClearTimer(MusicTimer);
    KSpreeCount = 0;
    CheckArena();
    GetCurrentMap(currentmap, sizeof(currentmap));
    bool bBluHale;
    int convarsetting = GetConVarInt(cvarForceHaleTeam);
    isHaleStunBanned = false;
    switch (convarsetting)
    {
        case 3: bBluHale = true;
        case 2: bBluHale = false;
        case 1: bBluHale = GetRandomInt(0, 1) == 1;
        default:
        {
            if (strncmp(currentmap, "vsh_", 4, false) == 0) bBluHale = true;
            else if (TeamRoundCounter >= 3 && GetRandomInt(0, 1))
            {
                bBluHale = (HaleTeam != 3);
                TeamRoundCounter = 0;
            }
            else bBluHale = (HaleTeam == 3);
        }
    }
    if (bBluHale)
    {
        int score1 = GetTeamScore(OtherTeam);
        int score2 = GetTeamScore(HaleTeam);
        SetTeamScore(2, score1);
        SetTeamScore(3, score2);
        OtherTeam = 2;
        HaleTeam = 3;
        bBluHale = false;
    }
    else
    {
        int score1 = GetTeamScore(HaleTeam);
        int score2 = GetTeamScore(OtherTeam);
        SetTeamScore(2, score1);
        SetTeamScore(3, score2);
        HaleTeam = 2;
        OtherTeam = 3;
        bBluHale = true;
    }
    playing = 0;
    for (int ionplay = 1; ionplay <= MaxClients; ionplay++)
    {
        Damage[ionplay] = 0;
        AirDamage[ionplay] = 0;
        BasherDamage[ionplay] = 0;
        SpeedDamage[ionplay] = 0;
        PersDamage[ionplay] = 0;
        NatDamage[ionplay] = 0;
        HuoDamage[ionplay] = 0;
        TomDamage[ionplay] = 0;
        BetDamage[ionplay] = 0;
        AmpDefend[ionplay] = 0;
        headmeter[ionplay] = 0;
        SpecialDemo_Kostyl[ionplay] = 0;
        uberTarget[ionplay] = -1;
        SniperActivity[ionplay] = 0;
        SniperNoMimoShoots[ionplay] = 0;
        ManmelterBan[ionplay] = false;
        BlockDamage[ionplay] = false;
        dispenserEnabled[ionplay] = false;
        g_flEurekaCooldown[ionplay] = 0.0;
        if (IsClientInGame(ionplay))
        {
            ResizePlayer(ionplay, 1.0);

            if (IsPlayerAlive(ionplay)) {
                TF2Attrib_RemoveByName(ionplay, "damage force reduction");
            }

            StopHaleMusic(ionplay);
            if (IsClientParticipating(ionplay)) //GetEntityTeamNum(ionplay) > _:TFTeam_Spectator)
            {
                playing++;
            }
            //if (GetEntityTeamNum(ionplay) > _:TFTeam_Spectator) playing++;
        }
    }
    if (GetClientCount() <= 1 || playing < 2)
    {
        CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_needmoreplayers");
        
        g_bEnabled = false;
        ASHRoundState = ASHRState_Disabled;
        SetControlPoint(true);
        return Plugin_Continue;
    }
    else if (RoundCount >= 0 && GetConVarBool(cvarFirstRound)) // This line was breaking the first round sometimes
    {
        g_bEnabled = true;
    }
    else if (RoundCount <= 0 && !GetConVarBool(cvarFirstRound))
    {
        CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_first_round");

        g_bEnabled = false;
        ASHRoundState = ASHRState_Disabled;
        SetArenaCapEnableTime(60.0);

        SearchForItemPacks();
        SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);

        CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Continue;
    }

    SetConVarInt(FindConVar("mp_teams_unbalance_limit"), TF2_GetRoundWinCount() ? 0 : 1); // s_bLateLoad ? 0 : 

    if (FixUnbalancedTeams())
    {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        if (!(ASHFlags[i] & ASHFLAG_HASONGIVED)) TF2_RespawnPlayer(i);
        if (RoundCount == 1) {
            TF2_RemoveAllWeapons(i);
            TF2_RespawnPlayer(i);
        }
    }
    bool see[TF_MAX_PLAYERS];
    int tHale = FindNextHale(see);
    if (tHale == -1)
    {
        CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_needmoreplayers");
        g_bEnabled = false;
        ASHRoundState = ASHRState_Disabled;
        SetControlPoint(true);
        return Plugin_Continue;
    }
    if (NextHale > 0)
    {
        Hale = NextHale;
        NextHale = -1;
    }
    else
    {
        Hale = tHale;
    }

    SetNextTime(e_flNextAllowBossSuicide, 29.1);
    SetNextTime(e_flNextAllowOtherSpawnTele, 60.0);

    // bTenSecStart[0] = true;
    // bTenSecStart[1] = true;
    // CreateTimer(29.1, tTenSecStart, 0);
    // CreateTimer(60.0, tTenSecStart, 1);

    AbilityAgent_Reset();
    CreateTimer(9.1, StartHaleTimer, _, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(3.5, StartResponceTimer, _, TIMER_FLAG_NO_MAPCHANGE);
    if (Special == ASHSpecial_MiniHale) CreateTimer(2.3, SecretHaleTimer);
    CreateTimer(9.6, MessageTimer, true, TIMER_FLAG_NO_MAPCHANGE);
    //bNoTaunt = false;
    HaleRage = 0;
    g_flStabbed = 0.0;
    g_flMarketed = 0.0;
    HHHClimbCount = 0;
    PointReady = false;
    int ent = -1;
    while ((ent = FindEntityByClassname2(ent, "func_regenerate")) != -1)
        AcceptEntityInput(ent, "Disable");
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "func_respawnroomvisualizer")) != -1)
        AcceptEntityInput(ent, "Disable");
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "obj_dispenser")) != -1)
    {
        SetVariantInt(OtherTeam);
        AcceptEntityInput(ent, "SetTeam");
        AcceptEntityInput(ent, "skin");
        SetEntProp(ent, Prop_Send, "m_nSkin", OtherTeam-2);
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "mapobj_cart_dispenser")) != -1)
    {
        SetVariantInt(OtherTeam);
        AcceptEntityInput(ent, "SetTeam");
        AcceptEntityInput(ent, "skin");
    }

    SearchForItemPacks();

    CreateTimer(0.3, MakeHale);
    CreateTimer(0.1, MakeEngineersSpeed, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    healthcheckused = 0;
    ASHRoundState = ASHRState_Waiting;
    
    // ASH STATS UPDATE
    ASHStats[Rages] = 0;
    ASHStats[SpecialAbilities] = 0;
    ASHStats[StunsNum] = 0;
    ASHStats[HeadShots] = 0;
    ASHStats[BackStabs] = 0;
    ASHStats[UberCharges] = 0;
    // ASH STATS UPDATE
    
    return Plugin_Continue;
}

public Action event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
    char s[265];
    char s1[80]; 
    char s2[265];
    char s3[80];
    char s4[80];
    
    ullapoolWarRound = false;
    BushmanRulesRound = false;
    
    RoundCount++;

    if (g_bReloadASHOnRoundEnd)
    {
        SetClientQueuePoints(Hale, 0);
        ServerCommand("sm plugins reload %s", ASH_pluginname);
    }

    if (!g_bEnabled)
    {
        return Plugin_Continue;
    }

    UTIL_Call(ASHEvent_RoundEnd);

    if (hotnightEnabled)
        ServerCommand("mp_friendlyfire 1");
    
    ASHRoundState = ASHRState_End;
    TeamRoundCounter++;
    if (GetEventInt(event, "team") == HaleTeam)
    {
        switch (Special)
        {
            case ASHSpecial_Agent:
            {
                char SoundFile[PLATFORM_MAX_PATH];
                FormatEx(SoundFile, PLATFORM_MAX_PATH, "%s", Agent_Win[GetRandomInt(0,3)]);
                
                PlaySoundForPlayers(SoundFile);
                PlaySoundForPlayers(SoundFile);
            }
            case ASHSpecial_Hale, ASHSpecial_MiniHale:
            {
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, GetRandomInt(1, 2));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, _, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, _, NULL_VECTOR, false, 0.0);
            }
            case ASHSpecial_Vagineer:
            {
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, GetRandomInt(1, 5));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
            }
#if defined EASTER_BUNNY_ON
            case ASHSpecial_Bunny:
            {
                strcopy(s, PLATFORM_MAX_PATH, BunnyWin[GetRandomInt(0, sizeof(BunnyWin)-1)]);
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);    
            }
#endif
        }
    }
    for (int i = 1 ; i <= MaxClients; i++)
    {
        ASHFlags[i] &= ~ASHFLAG_HASONGIVED;
        if (!IsClientInGame(i)) continue;
        StopHaleMusic(i);
        
        if (i != Hale && TF2_GetPlayerClass(i) == TFClass_Soldier && Soldier_EscapePlan_ModeNoHeal[i]) {
            int WeaponSolly = GetPlayerWeaponSlot(i, TFWeaponSlot_Melee);
            if (WeaponSolly != -1) {
                Address TF2Attrib_EscapePlan = TF2Attrib_GetByDefIndex(WeaponSolly, 236);
                if (TF2Attrib_EscapePlan != Address_Null && TF2Attrib_GetValue(TF2Attrib_EscapePlan) != 0.0) {
                    TF2Attrib_RemoveByDefIndex(GetPlayerWeaponSlot(i, TFWeaponSlot_Melee), 236);
                    TF2Attrib_RemoveByDefIndex(GetPlayerWeaponSlot(i, TFWeaponSlot_Melee), 734);
                    Soldier_EscapePlan_ModeNoHeal[i] = false;
                }
            }
        }
    }
    ClearTimer(MusicTimer);

    for (int i = 1; i <= MaxClients; i++)
    if (dispenserEnabled[i] && TF2_GetPlayerClass(i) == TFClass_Scout && IsPlayerAlive(i)) {
        float pos[3];
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
        pos[2] += 20.0;
        EmitSoundToAll("misc/doomsday_lift_start.wav", i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i, pos, NULL_VECTOR, true, 0.0);
        float pPos[3] = {0.0, 0.0, 10.0};
        CreateTimer(0.5, Dispenser_Disable_TP, i);
        AttachParticle(i, "heavy_ring_of_fire_child03", 1.0, pPos, true);
        SetVariantString("");
        AcceptEntityInput(i, "SetCustomModel");
        TF2_RegeneratePlayer(i);
        // SetEntProp(i, Prop_Send, "m_iHealth", ClientsHealth[i]);
        dispenserEnabled[i] = false;
    }
    
    if (IsClientInGame(Hale) && Hale > 0)
    {
        char translation[32];
    
        SetEntProp(Hale, Prop_Send, "m_bGlowEnabled", 0);
        GlowTimer = 0.0;
        if (IsPlayerAlive(Hale))
        {
            switch (Special)
            {
                case ASHSpecial_Bunny:        strcopy(translation, sizeof(translation), "vsh_bunny_is_alive");
                case ASHSpecial_Vagineer:     strcopy(translation, sizeof(translation), "vsh_vagineer_is_alive");
                case ASHSpecial_HHH:        strcopy(translation, sizeof(translation), "vsh_hhh_is_alive");
                case ASHSpecial_CBS:        strcopy(translation, sizeof(translation), "vsh_cbs_is_alive");
                case ASHSpecial_MiniHale:    strcopy(translation, sizeof(translation), "ash_secretHale_is_alive");
                case ASHSpecial_Agent:        strcopy(translation, sizeof(translation), "ash_agent_is_alive");
                default:                    strcopy(translation, sizeof(translation), "vsh_hale_is_alive");
            }
            CPrintToChatAll("{ash}[ASH]{default} %t", translation, Hale, HaleHealth, HaleHealthMax);
        }
        else
        {
            ChangeTeam(Hale, HaleTeam);
        }
        int top[5];
        Damage[0] = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (Damage[i] >= Damage[top[0]]) {
                top[4]=top[3];
                top[3]=top[2];
                top[2]=top[1];
                top[1]=top[0];
                top[0]=i;
            } else if (Damage[i] >= Damage[top[1]]) {
                top[4]=top[3];
                top[3]=top[2];
                top[2]=top[1];
                top[1]=i;
            } else if (Damage[i] >= Damage[top[2]]) {
                top[4]=top[3];
                top[3]=top[2];
                top[2]=i;
            } else if (Damage[i] >= Damage[top[3]]) {
                top[4]=top[3];
                top[3]=i;
            } else if (Damage[i] >= Damage[top[4]]) {
                top[4]=i;
            }
        }
        if (Damage[top[0]] > 9000)
        {
            CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        if (IsClientInGame(top[0]) && (GetEntityTeamNum(top[0]) >= 1)) GetClientName(top[0], s, 80);
        else {
            strcopy(s, 80, "---");
            top[0]=0;
        }
        if (IsClientInGame(top[1]) && (GetEntityTeamNum(top[1]) >= 1)) GetClientName(top[1], s1, 80);
        else {
            strcopy(s1, 80, "---");
            top[1]=0;
        }
        if (IsClientInGame(top[2]) && (GetEntityTeamNum(top[2]) >= 1)) GetClientName(top[2], s2, 80);
        else {
            strcopy(s2, 80, "---");
            top[2]=0;
        }
        if (IsClientInGame(top[3]) && (GetEntityTeamNum(top[3]) >= 1)) GetClientName(top[3], s3, 80);
        else {
            strcopy(s3, 80, "---");
            top[3]=0;
        }
        if (IsClientInGame(top[4]) && (GetEntityTeamNum(top[4]) >= 1)) GetClientName(top[4], s4, 80);
        else {
            strcopy(s4, 80, "---");
            top[4]=0;
        }
        
        SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
        PriorityCenterTextAll(_, ""); //Should clear center text
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !(GetClientButtons(i) & IN_SCORE))
            {
                SetGlobalTransTarget(i);
                {
                    // Hale Health
                    SetHudTextParams(-1.0, 0.15, 15.0, 255, 255, 255, 255);
                    ShowHudText(i, -1, "%t", translation, Hale, HaleHealth, HaleHealthMax);
                    
                    // Top Damage
                    SetHudTextParams(0.15, -1.0, 15.0, 255, 255, 255, 255);
                    ShowHudText(i, -1, "%t\n1). %i - %s\n2). %i - %s\n3). %i - %s\n4). %i - %s\n5). %i - %s", "vsh_top_3", Damage[top[0]], s, Damage[top[1]], s1, Damage[top[2]], s2, Damage[top[3]], s3, Damage[top[4]], s4);
                    
                    // Other hale statistics
                    SetHudTextParams(0.65, 0.39, 15.0, 255, 255, 255, 255);
                    ShowHudText(i, -1, "%t %t\n%t\n%t", "ash_stats_Boss", "ash_stats_Used", ASHStats[Rages], ASHStats[SpecialAbilities], "ash_stats_HeadShots", ASHStats[HeadShots], "ash_stats_BackStabs", ASHStats[BackStabs]);
                    
                    char sKiller[64];
                    char sKilled[12];
                    if (!HaleKiller || HaleKiller == Hale)
                        FormatEx(sKiller, sizeof(sKiller), "%t", "ash_stats_SUICIDE");
                    else {
                        if (FormatEx(sKilled, sizeof(sKilled), "%N", HaleKiller) > sizeof(sKilled)-2)
                            FormatEx(sKiller, sizeof(sKiller), "%t: %s...", "ash_stats_LastHit", sKilled);
                        else
                            FormatEx(sKiller, sizeof(sKiller), "%t: %s", "ash_stats_LastHit", sKilled);
                    }
                    
                    SetHudTextParams(0.65, 0.54, 15.0, 255, 255, 255, 255);
                    ShowHudText(i, -1, "%t\n%s", "ash_stats_UberCharges", ASHStats[UberCharges], sKiller);
                    
                    // Client damage
                    if (GetClientTeam(i) == OtherTeam) {
                        SetHudTextParams(-1.0, 0.75, 15.0, 255, 255, 255, 255);
                        ShowHudText(i, -1, "%t %i\n%t %i", "vsh_damage_fx",Damage[i], "vsh_scores", RoundFloat(Damage[i] / 600.0));
                    }
                }
            }
        }
    }
    HaleKiller = 0;
    CreateTimer(3.0, Timer_CalcScores, _, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action event_changeclass(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client == Hale)
    {
        switch(Special)
        {
            case ASHSpecial_Hale, ASHSpecial_MiniHale:
                if (TF2_GetPlayerClass(client) != TFClass_Soldier)
                    TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
            case ASHSpecial_Vagineer:
                if (TF2_GetPlayerClass(client) != TFClass_Engineer)
                    TF2_SetPlayerClass(client, TFClass_Engineer, _, false);
            case ASHSpecial_HHH, ASHSpecial_Bunny:
                if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
                    TF2_SetPlayerClass(client, TFClass_DemoMan, _, false);
            case ASHSpecial_CBS:
                if (TF2_GetPlayerClass(client) != TFClass_Sniper)
                    TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
        }
        TF2_RemovePlayerDisguise(client);
    }
    return Plugin_Continue;
}

public Action event_uberdeployed(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    char s[64];
    if (client != 0)
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        if (IsValidEntity(medigun) && medigun != 0 && medigun != -1)
        {
            GetEntityClassname(medigun, s, sizeof(s));
            if (strcmp(s, "tf_weapon_medigun", false) == 0)
            {
                TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
                int target = GetHealingTarget(client);
                if (IsValidClient(target) && IsPlayerAlive(target)) // IsValidClient(target, false)
                {
                    TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
                    uberTarget[client] = target;
                }
                else uberTarget[client] = -1;
                CreateTimer(0.4, Timer_Lazor, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                TF2_RemoveCondition(client, view_as<TFCond>(5));
                TF2_AddCondition(client, view_as<TFCond>(5), 11.2);
                TimerMedic_UberCharge[client] =    CreateTimer(0.5, Timer_UberCharge_MEDIC, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    return Plugin_Continue;
}

public Action event_player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsClientInGame(client)) return Plugin_Continue;
    if (!g_bEnabled) return Plugin_Continue;
    SetVariantString("");
    AcceptEntityInput(client, "SetCustomModel");
    if (IsHologram(client) && ASHRoundState == ASHRState_Active) {
        CreateTimer(0.1, MakeHologram, client);
        return Plugin_Continue;
    }
    if (client == Hale && ASHRoundState < ASHRState_End && ASHRoundState != ASHRState_Disabled)
    {
        CreateTimer(0.1, MakeHale);
    }
    
    plManmelterUsed[client] = 0;
    SpecialHale_RPSWins[client] = 0;
    BB_Sniper_Shots[client] = 0;
    BB_LastShotTime[client] = 0;
    BB_Sniper_ShootTime[client] = 0;
    SpecialPlayers_LastActiveWeapons[client] = -1;
    isStunnedBlock[client] = false;
    if (TF2_GetPlayerClass(client) == TFClass_DemoMan && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 1151) {
        if (IronBomberMode[client] != 0) {
            if (IronBomberMode[client] == 1) {
                IronBomber_ChangeMode(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), 2);
                IronBomberMode[client]++;
            }
            if (IronBomberMode[client] == 2) IronBomber_ChangeMode(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), 0);
            IronBomberMode[client] = 0;
        }
    }

    if (ASHRoundState != ASHRState_Disabled)
    {
        CreateTimer(0.2, MakeNoHale, GetClientUserId(client));
        if (!(ASHFlags[client] & ASHFLAG_HASONGIVED))
        {
            ASHFlags[client] |= ASHFLAG_HASONGIVED;
            RemovePlayerBack(client, { 57, 133, 231, 405, 444, 608, 642 }, 7);
            RemoveDemoShield(client);
            RemoveRazorback(client);
            TF2_RemoveAllWeapons(client);
            TF2_RegeneratePlayer(client);
            CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        }
    } 
    if (!(ASHFlags[client] & ASHFLAG_HELPED))
    {
//        HelpPanel(client);
        ASHFlags[client] |= ASHFLAG_HELPED;
    }
    ASHFlags[client] &= ~ASHFLAG_UBERREADY;
    ASHFlags[client] &= ~ASHFLAG_CLASSHELPED;
    
    TF2_RegeneratePlayer(client);
    
    return Plugin_Continue;
}

public Action event_player_death(Handle event, const char[] name, bool dontBroadcast)
{
    char s[PLATFORM_MAX_PATH];
    if (!g_bEnabled)
        return Plugin_Continue;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if(g_iTauntedSpys[client] == 1)
    {
        g_iTauntedSpys[client] = 0;
    }
    
    if (FakeKill_Goomba) {
        int damageBits = GetEventInt(event, "damagebits");
        
        SetEventString(event, "weapon_logclassname", "goomba");
        SetEventString(event, "weapon", "taunt_scout");
        SetEventInt(event, "damagebits", damageBits |= DMG_ACID);
        SetEventInt(event, "customkill", 0);
        SetEventInt(event, "playerpenetratecount", 0);
        
        if (GetRandomInt(0,100) > 99)
            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_stunballhit14.mp3");
        else
            strcopy(s, PLATFORM_MAX_PATH, "weapons/mantreads.wav");
        
        float vecPos[3];
        GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", vecPos);
        EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
        EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
        PushClient(Hale);
    }
    
    if (!client || !IsClientInGame(client))
        return Plugin_Continue;
        
    if (client == Hale)
    {
        HaleKiller = attacker;
        if (client != attacker)
        {
            CreateTimer(3.0, OnPlayEndRoundSound, TF2_GetPlayerClass(attacker));
        }
    }

    // PrintToChatAll("event_player_death");
    // PrintToChatAll("UTIL_GetAlivePlayers(): %d", UTIL_GetAlivePlayers(OtherTeam));
    RequestFrame(Ext_CheckAlivePlayers, 0);
    
    if (attacker == Hale && Special == ASHSpecial_Agent) {
        AgentHelper_ChangeTimeBeforeInvis(6.5, Hale);
        bool playSound = false;
        int randomizer = GetRandomInt(0, 100);
        char soundfile[PLATFORM_MAX_PATH];
        
        switch(TF2_GetPlayerClass(client)) {
            case TFClass_Scout: {
                if (randomizer <= 35) {
                    playSound = true;
                    strcopy(soundfile, PLATFORM_MAX_PATH, Agent_KillScout[GetRandomInt(0,2)]);
                }
            }
            
            case TFClass_Pyro: {
                if (randomizer <= 35) {
                    playSound = true;
                    strcopy(soundfile, PLATFORM_MAX_PATH, Agent_KillPyro[GetRandomInt(0,2)]);
                }
            }
            
            case TFClass_Medic: {
                if (randomizer <= 35) {
                    playSound = true;
                    strcopy(soundfile, PLATFORM_MAX_PATH, Agent_KillMedic[GetRandomInt(0,2)]);
                }
            }
            
            case TFClass_Heavy: {
                if (randomizer <= 35) {
                    playSound = true;
                    strcopy(soundfile, PLATFORM_MAX_PATH, Agent_KillHeavy[GetRandomInt(0,2)]);
                }
            }
        }
        
        if (playSound) PlaySoundForPlayers(soundfile);
    }
    
    if (IsHologram(client) && Special == ASHSpecial_Agent) return Plugin_Continue;
    
    if (GetClientOfUserId(GetEventInt(event, "attacker")) == Hale && Special == ASHSpecial_HHH)
    {
        char WeaponName[30];
        GetEventString(event, "weapon", WeaponName, sizeof(WeaponName));
        if (strcmp(WeaponName, "headtaker") == 0 || strcmp(WeaponName, "mantreads") == 0) if (SpecialHHH_Souls < 5) SpecialHHH_Souls++;
    }
    
    int deathflags = GetEventInt(event, "death_flags");
    int customkill = GetEventInt(event, "customkill");
#if defined EASTER_BUNNY_ON
    if (attacker == Hale && Special == ASHSpecial_Bunny && ASHRoundState == ASHRState_Active)    SpawnManyAmmoPacks(client, EggModel, 1, 5, 120.0);
#endif
    if (attacker == Hale && ASHRoundState == ASHRState_Active && (deathflags & TF_DEATHFLAG_DEADRINGER))
    {
        numHaleKills++;
        if (customkill != TF_CUSTOM_BOOTS_STOMP)
        {
            if (Special == ASHSpecial_Hale) SetEventString(event, "weapon", "fists");
        }
        return Plugin_Continue;
    }
    if (GetClientHealth(client) > 0)
        return Plugin_Continue;
    CreateTimer(0.1, CheckAlivePlayers);
    if (client != Hale && ASHRoundState == ASHRState_Active)
        CreateTimer(1.0, Timer_Damage, GetClientUserId(client));
    if (client == Hale && ASHRoundState == ASHRState_Active)
    {
        switch (Special)
        {
            case ASHSpecial_HHH:
            {
                Format(s, PLATFORM_MAX_PATH, "vo/halloween_boss/knight_death0%d.mp3", GetRandomInt(1, 2));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAll("ui/halloween_boss_defeated_fx.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
//                CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
            }
            case ASHSpecial_Hale, ASHSpecial_MiniHale:
            {
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, GetRandomInt(1, 3));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
//                CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
            }
            case ASHSpecial_Vagineer:
            {
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerFail, GetRandomInt(1, 4));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
//                CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
            }
#if defined EASTER_BUNNY_ON
            case ASHSpecial_Bunny:
            {
                strcopy(s, PLATFORM_MAX_PATH, BunnyFail[GetRandomInt(0, sizeof(BunnyFail)-1)]);
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
//                CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
                SpawnManyAmmoPacks(client, EggModel, 1);
            }
#endif
            case ASHSpecial_Agent:
            {
                strcopy(s, PLATFORM_MAX_PATH, Agent_Fail[GetRandomInt(0,2)]);
                
                PlaySoundForPlayers(s);
                PlaySoundForPlayers(s);
            }
        }
        if (HaleHealth < 0)
            HaleHealth = 0;
        ForceTeamWin(OtherTeam);
        return Plugin_Continue;
    }
    if (attacker == Hale && ASHRoundState == ASHRState_Active)
    {
        numHaleKills++;
        switch (Special)
        {
            case ASHSpecial_Hale, ASHSpecial_MiniHale:
            {
                if (customkill != TF_CUSTOM_BOOTS_STOMP) SetEventString(event, "weapon", "fists");
                if (!GetRandomInt(0, 2) && RedAlivePlayers != 1)
                {
                    strcopy(s, PLATFORM_MAX_PATH, "");
                    TFClassType playerclass = TF2_GetPlayerClass(client);
                    switch (playerclass)
                    {
                        case TFClass_Scout:     strcopy(s, PLATFORM_MAX_PATH, HaleKillScout132);
                        case TFClass_Pyro:      strcopy(s, PLATFORM_MAX_PATH, HaleKillPyro132);
                        case TFClass_DemoMan:   strcopy(s, PLATFORM_MAX_PATH, HaleKillDemo132);
                        case TFClass_Heavy:     strcopy(s, PLATFORM_MAX_PATH, HaleKillHeavy132);
                        case TFClass_Medic:     strcopy(s, PLATFORM_MAX_PATH, HaleKillMedic);
                        case TFClass_Sniper:
                        {
                            if (GetRandomInt(0, 1)) strcopy(s, PLATFORM_MAX_PATH, HaleKillSniper1);
                            else strcopy(s, PLATFORM_MAX_PATH, HaleKillSniper2);
                        }
                        case TFClass_Spy:
                        {
                            int see = GetRandomInt(0, 2);
                            if (!see) strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy1);
                            else if (see == 1) strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy2);
                            else strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy132);
                        }
                        case TFClass_Engineer:
                        {
                            int see = GetRandomInt(0, 3);
                            if (!see) strcopy(s, PLATFORM_MAX_PATH, HaleKillEngie1);
                            else if (see == 1) strcopy(s, PLATFORM_MAX_PATH, HaleKillEngie2);
                            else Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, GetRandomInt(1, 2));
                        }
                    }
                    if (!StrEqual(s, ""))
                    {
                        EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                        EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                    }
                }
            }
            case ASHSpecial_Vagineer:
            {
                strcopy(s, PLATFORM_MAX_PATH, VagineerHit);
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
//                CreateTimer(0.1, Timer_DissolveRagdoll, any:GetEventInt(event, "userid"));
            }
            case ASHSpecial_HHH:
            {
                Format(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHAttack, GetRandomInt(1, 4));
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
            }
#if defined EASTER_BUNNY_ON
            case ASHSpecial_Bunny:
            {
                strcopy(s, PLATFORM_MAX_PATH, BunnyKill[GetRandomInt(0, sizeof(BunnyKill)-1)]);
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
            }
#endif
            case ASHSpecial_CBS:
            {
                if (!GetRandomInt(0, 3) && RedAlivePlayers != 1)
                {
                    TFClassType playerclass = TF2_GetPlayerClass(client);
                    switch (playerclass)
                    {
                        case TFClass_Spy:
                        {
                            strcopy(s, PLATFORM_MAX_PATH, "vo/sniper_dominationspy04.mp3");
                            EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                            EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                        }
                    }
                }
                int weapon = GetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon");
                if (weapon == GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee))
                {
                    TF2_RemoveWeaponSlot(Hale, TFWeaponSlot_Melee);
                    int clubindex;
                    int wepswitch = GetRandomInt(0, 3);
                    switch (wepswitch)
                    {
                        case 0: clubindex = 171;
                        case 1: clubindex = 3;
                        case 2: clubindex = 232;
                        case 3: clubindex = 401;
                    }
                    weapon = SpawnWeapon(Hale, "tf_weapon_club", clubindex, 100, TFQual_Unusual, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 275 ; 1.0");
                    SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", weapon); // Technically might be pointless, as SpawnWeapon already calls EquipPlayerWeapon
                }
            }
        }
        if (IsNextTime(e_flNextBossKillSpreeEnd, 5.0)) //GetGameTime() <= KSpreeTimer)
        {
            KSpreeCount = 1;
        }
        else
        {
            KSpreeCount++;
        }

        if (KSpreeCount == 3 && RedAlivePlayers != 1)
        {
            switch (Special)
            {
                case ASHSpecial_Hale, ASHSpecial_MiniHale:
                {
                    int see = GetRandomInt(0, 7);
                    if (!see || see == 1)
                        strcopy(s, PLATFORM_MAX_PATH, HaleKSpree);
                    else if (see < 5)
                        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
                    else
                        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));
                }
                case ASHSpecial_Vagineer: 
                {
                    int AudioVaginaRandom = GetRandomInt(1,4);
                    if (AudioVaginaRandom == 1) 
                        strcopy(s, PLATFORM_MAX_PATH, VagineerKSpree); 
                    else if (AudioVaginaRandom == 2)
                        strcopy(s, PLATFORM_MAX_PATH, VagineerKSpree2); 
                    else if (AudioVaginaRandom == 3) 
                        strcopy(s, PLATFORM_MAX_PATH, VagineerKSpree3); 
                    else 
                        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, GetRandomInt(1, 5)); 
                }
                case ASHSpecial_HHH: Format(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHLaught, GetRandomInt(1, 4));
                case ASHSpecial_CBS:
                {
                    if (!GetRandomInt(0, 3))
                        Format(s, PLATFORM_MAX_PATH, CBS0);
                    else if (!GetRandomInt(0, 3))
                        Format(s, PLATFORM_MAX_PATH, CBS1);
                    else
                        Format(s, PLATFORM_MAX_PATH, "%s%02i.mp3", CBS2, GetRandomInt(1, 9));
                    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                }
#if defined EASTER_BUNNY_ON
                case ASHSpecial_Bunny:
                {
                    strcopy(s, PLATFORM_MAX_PATH, BunnySpree[GetRandomInt(0, sizeof(BunnySpree)-1)]);
                }
#endif
                case ASHSpecial_Agent:
                    strcopy(s, PLATFORM_MAX_PATH, Agent_KSpree[GetRandomInt(0,5)]);
            }
            
            if (Special != ASHSpecial_Agent) {
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
            } else {
                //decl Float:vecPos[3];
                //GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", vecPos);
                
                // EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
                // EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
                PlaySoundForPlayers(s);
                PlaySoundForPlayers(s);
                PlaySoundForPlayers(s);
                PlaySoundForPlayers(s);

                //EmitSoundToAll(s, Hale, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                //EmitSoundToAll(s, Hale, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
            }
            KSpreeCount = 0;
        }
        else
        {
            SetNextTime(e_flNextBossKillSpreeEnd, 5.0);
            //KSpreeTimer = GetGameTime() + 5.0;
        }
    }
    if ((TF2_GetPlayerClass(client) == TFClass_Engineer) && !(deathflags & TF_DEATHFLAG_DEADRINGER))
    {
        int ent = -1;
        while ((ent = FindEntityByClassname2(ent, "obj_sentrygun")) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client)
            {
                SetVariantInt(GetEntProp(ent, Prop_Send, "m_iMaxHealth") + 8);
                AcceptEntityInput(ent, "RemoveHealth");
            }
        }
    }
    
    if ((TF2_GetPlayerClass(client) == TFClass_Scout) && dispenserEnabled[client]) {
        dispenserEnabled[client] = false;
        SetVariantString("");
        AcceptEntityInput(client, "SetCustomModel");
    }
    
    InfectPlayers[client] = false;
    
    return Plugin_Continue;
}

public Action event_deflect(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return Plugin_Continue;
    int deflector = GetClientOfUserId(GetEventInt(event, "userid"));
    int owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
    int weaponid = GetEventInt(event, "weaponid");
    if (owner != Hale) return Plugin_Continue;
    if (weaponid != 0) return Plugin_Continue;
    float rage = 0.04*RageDMG;
    HaleRage += RoundToCeil(rage);
    if (HaleRage > RageDMG)
        HaleRage = RageDMG;
    if (Special != ASHSpecial_Vagineer) return Plugin_Continue;
    if (!TF2_IsPlayerInCondition(owner, TFCond_Ubercharged)) return Plugin_Continue;
    if (UberRageCount > 11) UberRageCount -= 10;
    int newammo = GetAmmo(deflector, 0) - 5;
    SetAmmo(deflector, 0, newammo <= 0 ? 0 : newammo);
    return Plugin_Continue;
}

public Action event_jarate(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
    int client = BfReadByte(bf);
    int victim = BfReadByte(bf);
    if (victim != Hale) return Plugin_Continue;
    int jar = GetPlayerWeaponSlot(client, 1);

    int jindex = GetEntProp(jar, Prop_Send, "m_iItemDefinitionIndex");

    if (jar != -1 && (jindex == 58 || jindex == 1083 || jindex == 1105) && GetEntProp(jar, Prop_Send, "m_iEntityLevel") != -122)    //-122 is the Jar of Ants and should not be used in this
    {
        float rage = 0.50*RageDMG;
        HaleRage -= RoundToFloor(rage);
        if (HaleRage < 0)
            HaleRage = 0;
        if (Special == ASHSpecial_Vagineer && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && UberRageCount < 99)
        {
            UberRageCount += 7.0;
            if (UberRageCount > 99) UberRageCount = 99.0;
        }
        int ammo = GetAmmo(Hale, 0);
        if (Special == ASHSpecial_CBS && ammo > 0) SetAmmo(Hale, 0, ammo - 1);
    }
    return Plugin_Continue;
}

public Action event_hurt(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return Plugin_Continue;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int damage = GetEventInt(event, "damageamount");
    int custom = GetEventInt(event, "custom");
    int weapon = GetEventInt(event, "weaponid");
    
    if (GetPlayersInTeam(OtherTeam) > 12)
        iHaleSpecialPower += damage/18;
    else
        iHaleSpecialPower += damage/12;
        
    if (client == Hale && Special == ASHSpecial_Agent && (custom == TF_CUSTOM_BURNING || custom == TF_CUSTOM_BURNING_ARROW || custom == TF_CUSTOM_BURNING_FLARE)) {
        CreateTimer(2.0, RemoveBurn, Hale);
    }

    if (client != Hale && IsHologram(attacker) && client != attacker && attacker != 0) {
        if (GetRandomInt(0, 100) <= 25)
            TF2_StunPlayer(client, 1.3, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
    }

    if (client != Hale && !IsHologram(client)) return Plugin_Continue;
    
    if (SpecialCrits_ForHale[attacker]) TF2Attrib_RemoveByDefIndex(Hale, 62);

    if (!IsValidClient(attacker) || !IsValidClient(client) || client == attacker)
        return Plugin_Continue;
        
    if (custom == TF_CUSTOM_TELEFRAG) damage = (IsPlayerAlive(attacker) ? 9001:1);

    if (GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit")) SetEventBool(event, "allseecrit", false);

    if (!IsHologram(client))
        HaleHealth -= damage;
    
    bool IsForceANature = false;
    if (IsValidEntity(SpecialPlayers_LastActiveWeapons[attacker]) && IsValidClient(attacker))
        IsForceANature = (SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary) && FindItemInArray(GetEntProp(SpecialPlayers_LastActiveWeapons[attacker], Prop_Send, "m_iItemDefinitionIndex"), {45, 1078}, 2));
    HaleRage += (IsForceANature)?damage*2:damage;

    if (custom == TF_CUSTOM_TELEFRAG) SetEventInt(event, "damageamount", damage);

    Damage[attacker] += damage;

    if (TF2_GetPlayerClass(attacker) == TFClass_Sniper && damage >= 275 && Special == ASHSpecial_Agent) {
        AgentHelper_ChangeTimeBeforeInvis(5.0, Hale);
    }
    
    ASH_ExecuteRages(attacker, damage, custom, weapon);
    
//    switch (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee)) 
//    {
//        case 7, 169, 197, 662, 795, 804, 884, 893, 902, 
//             911, 960, 969, 15073, 15074, 
//             15075, 15114, 15139, 15140, 15156,
//             1123, 423, 1071: 
//        if (TF2_GetPlayerClass(attacker) == TFClass_Engineer && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee)) PushClient(Hale);
//    }
    
    if (TF2_GetPlayerClass(attacker) == TFClass_Heavy && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 331 && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28))) PushClient(Hale);
    
    if (TF2_GetPlayerClass(attacker) == TFClass_Spy && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary) && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28)) && g_iTauntedSpys[attacker] == 1) {
        if (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 61 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 1006) {
            TeleportToMultiMapSpawn(Hale);
        }
    }   

    if (TF2_GetPlayerClass(attacker) == TFClass_Pyro && (damage == 146 || damage == 1316) && (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 153 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 466) && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee))
    {
        if (Stun<3) {
            TF2_StunPlayer(Hale, 0.7, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
            PushClient(attacker);
        }
        
        Stun++;
        if (Stun == 3) CreateTimer(3.0, StunDisable);
    }

    if (TF2_GetPlayerClass(attacker) == TFClass_Soldier && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 1104)
    {
        if (SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary))
        {
            AirDamage[attacker] += damage;
        }
        SetEntProp(attacker, Prop_Send, "m_iDecapitations", AirDamage[attacker]/200);
    }
    
    // Rages
    // Rage for Boston Basher
    if (TF2_GetPlayerClass(attacker) == TFClass_Scout && (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 325 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 452)) {
        // Fix boolean
        bool isAdded = false;
        
        // Attack with Guillotine
        if ((GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Secondary) == 812 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Secondary) == 833) && (damage == 50 || damage == 68 || damage == 150) && damage != 4 && damage != 5) {
            BasherDamage[attacker] += 80;
            isAdded = true;
        }
        
        // Attack with Melee weapon
        if (!isAdded && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && damage != 50 && damage != 4 && damage != 5)
            BasherDamage[attacker] += 160;
    }
    
    // Machina Stun code
    int iIndex = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary);
    if (attacker != Hale && TF2_GetPlayerClass(attacker) == TFClass_Sniper && TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping) && (iIndex == 526 || iIndex == 30665) && custom == TF_CUSTOM_HEADSHOT && damage > 320)
    {
        TF2_StunPlayer(Hale, 4.0, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);

        char s[PLATFORM_MAX_PATH];
        Format(s, PLATFORM_MAX_PATH, "misc/sniper_railgun_double_kill.wav");
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);

        SetGlobalTransTarget(attacker);
        PriorityCenterText(attacker, true, "%t", "ash_sniper_machina_tryhard_player");
        SetGlobalTransTarget(Hale);
        PriorityCenterText(Hale, true, "%t", "ash_sniper_machina_tryhard_victim");
    }

    // Bazaar Inv
    if (attacker != Hale && TF2_GetPlayerClass(attacker) == TFClass_Sniper && !TF2_IsPlayerInCondition(attacker, view_as<TFCond>(66)) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 402 && custom == TF_CUSTOM_HEADSHOT)
    {
        TF2_AddCondition(attacker, view_as<TFCond>(66), 12.0);
        EmitSoundToClient(attacker, "misc/halloween/spell_stealth.wav");
    }
    
    // Airshots for Soldier's Direct Hit
    if (attacker != Hale && TF2_GetPlayerClass(attacker) == TFClass_Soldier && IsPlayerInAir(Hale) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 127 && SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary)) {
        if (SpecialSoldier_Airshot[attacker] && TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) {
            TF2_StunPlayer(Hale, 4.0, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
            SpecialSoldier_Airshot[attacker] = false;
            if (TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) TF2_RemoveCondition(Hale, TFCond_BlastJumping);
            
            char s[PLATFORM_MAX_PATH];
            Format(s, PLATFORM_MAX_PATH, "misc/sniper_railgun_double_kill.wav");
            EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);

            SetGlobalTransTarget(attacker);
            PriorityCenterText(attacker, true, "%t", "ash_soldier_directhit_tryhard_player");
            SetGlobalTransTarget(Hale);
            PriorityCenterText(Hale, true, "%t", "ash_soldier_directhit_tryhard_victim");
        } else if (TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) {
            SpecialSoldier_Airshot[attacker] = true;
        } else 
        {
            if (!TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) TF2_AddCondition(Hale, TFCond_BlastJumping);
        }
    }
    
    // Cow Mangler 5000
    if (attacker != Hale && TF2_GetPlayerClass(attacker) == TFClass_Soldier && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 441 && SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary) && custom == 3 && !isStunnedBlock[attacker]) {
        // Stun. 3 sec
        TF2_StunPlayer(Hale, 3.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
        isStunnedBlock[attacker] = true;
        CreateTimer(6.0, IsStunnedBlockDisable, attacker);
    }
    
    // Stun block
    if ((GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 56 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 1092 || GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 1005) && damage == 500 && !isHaleStunBanned) {
        CreateTimer(2.5, DisableHuntsTaunt);
        CreateTimer(7.5, EnableHuntsTaunt);
    }

    int[] healers = new int[TF_MAX_PLAYERS];
    int healercount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i) == attacker))
        {
            healers[healercount] = i;
            healercount++;
        }
    }
    for (int i = 0; i < healercount; i++)
    {
        if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
        {
            if (damage < 10 || uberTarget[healers[i]] == attacker)
                Damage[healers[i]] += damage;
            else
                Damage[healers[i]] += damage/(healercount+1);
        }
    }

    if (HaleRage > RageDMG)
        HaleRage = RageDMG;
    
    if (client == Hale && Special == ASHSpecial_Agent)
        AgentHelper_ChangeTimeBeforeInvis(1.3, Hale);

    return Plugin_Continue;
}

public Action event_rps(Handle EventHndl, const char[] name, bool dontBroadcast) {
    if (ASHRoundState != ASHRState_Active) {
        return Plugin_Stop;
    }
    
    int RPS_Winner, RPS_Loser;
    RPS_Winner = GetEventInt(EventHndl, "winner");
    RPS_Loser = GetEventInt(EventHndl, "loser");
    if (RPS_Loser == Hale) {
        SpecialHale_RPSWins[RPS_Winner]++;
        if (SpecialHale_RPSWins[RPS_Winner] >= 3) {
            // Round int to float
            char TempDmg[30];
            float DmgToHale;
            Format(TempDmg, 30, "%i.0", HaleHealth);
            DmgToHale = StringToFloat(TempDmg);
            
            CPrintToChat(RPS_Winner, "{ash}[ASH] {default}%t", "ash_RPS_player_3times");
            CPrintToChat(Hale, "{ash}[ASH] {default}%t", "ash_RPS_boss_3times");
            
            SDKHooks_TakeDamage(RPS_Loser, RPS_Winner, RPS_Winner, DmgToHale, DMG_CLUB, GetEntPropEnt(RPS_Winner, Prop_Send, "m_hActiveWeapon"));
        }
    } else SpecialHale_RPSWins[RPS_Loser] = 0;
    
    return Plugin_Handled;
}

public Action event_destroy(Handle event, const char[] name, bool dontBroadcast)
{
    if (g_bEnabled)
    {
        int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        int customkill = GetEventInt(event, "customkill");
        int objecttype = GetEventInt(event, "objecttype");
        if (attacker == Hale)
        {
            if (Special == ASHSpecial_Hale)
            {
                if (customkill != TF_CUSTOM_BOOTS_STOMP) SetEventString(event, "weapon", "fists");
                if (!GetRandomInt(0, 4))
                {
                    char s[PLATFORM_MAX_PATH];
                    strcopy(s, PLATFORM_MAX_PATH, HaleSappinMahSentry132);
                    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                }
            }
            if (Special == ASHSpecial_Agent)
            {
                if (objecttype == 2) {
                    if (GetRandomInt(0, 100) <= 35) {
                        PlaySoundForPlayers("vo/spy_specialcompleted05.mp3");
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action event_sapped(Handle event, const char[] name, bool dontBroadcast) {
    if (g_bEnabled) {
        int ply = GetClientOfUserId(GetEventInt(event, "userid"));
        if (Special == ASHSpecial_Agent && ply == Hale)
            AgentHelper_ChangeTimeBeforeInvis(1.6, Hale);
    }
    return Plugin_Continue;
}

// Update Fov
stock void UpdateFOV(int iClient) {
    g_iPlayerDesiredFOV[iClient] = 90;
    
    if (!IsFakeClient(iClient))
        QueryClientConVar(iClient, "fov_desired", OnClientGetDesiredFOV);
}

public void OnClientGetDesiredFOV(QueryCookie cookie, int iClient, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (!IsValidClient(iClient)) return;
    
    g_iPlayerDesiredFOV[iClient] = StringToInt(cvarValue);
}

// SourceMod events
public void OnClientPostAdminCheck(int client) {
    UpdateFOV(client);
    UTIL_Cleanup(client);
    UTIL_Hook(client);
}

public void OnClientDisconnect(int client) {
    UTIL_Cleanup(client);
    UTIL_UnHook(client);
    if (g_bEnabled)
    {
        if (client == Hale)
        {
            if (ASHRoundState >= ASHRState_Active)
            {
                char authid[32];
                GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
                Handle pack;
                CreateDataTimer(3.0, Timer_SetDisconQueuePoints, pack, TIMER_FLAG_NO_MAPCHANGE);
                WritePackString(pack, authid);
                bool see[TF_MAX_PLAYERS];
                see[Hale] = true;
                int tHale = FindNextHale(see);
                if (NextHale > 0)
                {
                    tHale = NextHale;
                }
                if (IsValidClient(tHale))
                {
                    ChangeTeam(tHale, HaleTeam);
                }
            }
            if (ASHRoundState == ASHRState_Active)
            {
                ForceTeamWin(OtherTeam);
            }
            if (ASHRoundState == ASHRState_Waiting)
            {
                bool see[TF_MAX_PLAYERS];
                see[Hale] = true;
                int tHale = FindNextHale(see);
                if (NextHale > 0)
                {
                    tHale = NextHale;
                    NextHale = -1;
                }
                if (IsValidClient(tHale))
                {
                    Hale = tHale;
                    ChangeTeam(Hale, HaleTeam);
                    CreateTimer(0.1, MakeHale);
                    // CPrintToChat(Hale, "{olive}[ASH]{default} Surprise! You're on NOW!");
                    CPrintToChat(Hale, "{ash}[ASH] {default}Surprise! You're on NOW!");
                }
            }
            CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_hale_disconnected");
        }
        else
        {
            if (IsClientInGame(client))
            {
                if (IsPlayerAlive(client)) CreateTimer(0.0, CheckAlivePlayers);
                if (client == FindNextHaleEx()) CreateTimer(1.0, Timer_SkipHalePanel, _, TIMER_FLAG_NO_MAPCHANGE);
            }
            if (client == NextHale)
            {
                NextHale = -1;
            }
        }
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    Ext_BlockSpectatingOnAnotherTeam(client);

    if (g_bEnabled && client == Hale)
    {
        if (Special == ASHSpecial_HHH)
        {
            if (ASHFlags[client] & ASHFLAG_NEEDSTODUCK)
            {
                buttons |= IN_DUCK;
            }
            if (HaleCharge >= 47 && (buttons & IN_ATTACK))
            {
                buttons &= ~IN_ATTACK;
                return Plugin_Changed;
            }
        }
        if (Special == ASHSpecial_Bunny)
        {
            int weap = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
            if (weap == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") && SpecialWeapon != weap)
            {
                buttons &= ~IN_ATTACK;
                return Plugin_Changed;
            }
        }
        if (Special == ASHSpecial_Agent) {
            if (buttons & IN_ATTACK3) {
                if (IsNextTime(e_flNextMedicCall)) {
                    float pos[3];
                    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
                    SetNextTime(e_flNextMedicCall, 3.0);
                    EmitAmbientSound(Agent_Whistle, pos, client, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);

                    AgentPreparedSoundLaugh = 0.0;
                    InvisibleAgent = 0.0;
                    LastSound = 0.0;
                }
            } 
        }
    }
    return Plugin_Continue;
}

/*
Runs every frame for clients

*/
public void OnPreThinkPost(int client)
{
    if (IsNearSpencer(client) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
    {
        float cloak = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") - 0.5;

        if (cloak < 0.0)
        {
            cloak = 0.0;
        }

        SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloak);

        /*if (RoundFloat(GetGameTime()) == GetGameTime())
        {
            CPrintToChdata("%N DISPENSE %f", client, GetGameTime());
        }*/
    }
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
    if (BlockDamage[client] && AQUACURE_EntShield[client] > 0 && AQUACURE_EntShield[client] == client) {
        damage = 0.0;
        damagetype = 0;
        damagecustom = 0;

        return Plugin_Changed;
        // return Plugin_Handled;
    }
    if (g_bGod[client]) return Plugin_Handled;
    
//    if (attacker > 0 && attacker <= MaxClients && TF2_GetPlayerClass(attacker) == TFClass_Engineer && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 588 && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary) && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28)) && !StrEqual(sAttackerObject, "obj_sentrygun") && attacker != client) PushClient(Hale);
    
    // Airshots for Demo's Loch'n'Load
    
    char sAttackerObject[128];
    GetEdictClassname(inflictor, sAttackerObject, sizeof(sAttackerObject));
    
    if (attacker != Hale && TF2_GetPlayerClass(attacker) == TFClass_DemoMan && IsPlayerInAir(Hale) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 308 && SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary) && StrEqual(sAttackerObject, "tf_projectile_pipe")) {
        if (SpecialSoldier_Airshot[attacker] && TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) {
            TF2_StunPlayer(Hale, 4.0, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
            SpecialSoldier_Airshot[attacker] = false;
            if (TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) TF2_RemoveCondition(Hale, TFCond_BlastJumping);
            
            char s[PLATFORM_MAX_PATH];
            Format(s, PLATFORM_MAX_PATH, "misc/sniper_railgun_double_kill.wav");
            EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);

            SetGlobalTransTarget(attacker);
            PriorityCenterText(attacker, true, "%t", "ash_demo_directhit_tryhard_player");
            SetGlobalTransTarget(Hale);
            PriorityCenterText(Hale, true, "%t", "ash_demo_directhit_tryhard_victim");
        } else if (TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) {
            SpecialSoldier_Airshot[attacker] = true;
        } else 
        {
            if (!TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) TF2_AddCondition(Hale, TFCond_BlastJumping);
        }
    }
    
    if (attacker > 0 && attacker <= MaxClients && attacker != client && TF2_GetPlayerClass(attacker) == TFClass_Engineer && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28)) && damagecustom == TF_CUSTOM_PLASMA)
    {
        if (damagetype != DMG_SHOCK && inflictor != attacker) {
            PushClient(Hale);
        } else {
            TF2_StunPlayer(Hale, 4.00, 0.5, TF_STUNFLAG_SLOWDOWN);
        }
    }
    
    if (attacker > 0 && attacker <= MaxClients && TF2_GetPlayerClass(attacker) == TFClass_Engineer && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 329 && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28)) && StrEqual(sAttackerObject, "obj_sentrygun")) {
        TF2_AddCondition(Hale, TFCond_MarkedForDeath, 4.0);
    }
    
    //Sandman stun ball
    if (attacker > 0 && attacker <= MaxClients && attacker != client) {
        float ScoutPos[3];
        float HalePos[3];

        GetClientEyePosition(attacker, ScoutPos);
        GetClientEyePosition(client, HalePos);
        
        if (TF2_GetPlayerClass(attacker) == TFClass_Scout && !TF2_IsPlayerInCondition(Hale, view_as<TFCond>(28)) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 44 && inflictor != attacker && damagecustom != TF_CUSTOM_CLEAVER /*&& StrEqual(sAttackerObject, "tf_projectile_stun_ball")*/) {
            if (GetVectorDistance(ScoutPos, HalePos) > 1450.0) {
                TF2_StunPlayer(client, 6.0, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
            } else if (GetVectorDistance(ScoutPos, HalePos) > 350.0) {
                TF2_StunPlayer(client, 4.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
            }
        }
    }
    
    if (client > 0) {
        if (!ManmelterBan[client] && TF2_GetPlayerClass(client) == TFClass_Pyro && plManmelterUsed[client] == 100 && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 595 && IntToFloat(GetEntProp(client, Prop_Send, "m_iHealth")) <= damage) {
            TF2_OnPyroSecondChance(client);
            
            damagetype = DMG_CLUB;
            damagecustom = 0;
            damage = 0.0;
            return Plugin_Changed;
        }
        
        if (client == Hale && Special == ASHSpecial_Agent && TimeAbility > 0.0) {
            damage = 0.0;
            damagetype = 0;
            return Plugin_Changed;
        }
        
        if (client != attacker && TF2_GetPlayerClass(client) == TFClass_Scout && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 448 && SpeedDamage[client] >= 2281336) {
            // Miss!
            damage = GetRandomFloat(20.0, 30.0);
            damagetype = 0;
            
            float iPlyVec[3];
            float iPlySpeed[3];
            GetEntPropVector(client, Prop_Send, "m_vecOrigin", iPlyVec);
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", iPlySpeed);
            
            if (iPlySpeed[0] <= 2.0 || iPlySpeed[1] <= 2.0) {
                iPlyVec[0] += (GetRandomInt(0, 1)?-1:1)*GetRandomFloat(25.0, 50.0)*5;
                iPlyVec[1] += (GetRandomInt(0, 1)?-1:1)*GetRandomFloat(25.0, 50.0)*5;
            } else {
                iPlyVec[0] += iPlySpeed[0]*5;
                iPlyVec[1] += iPlySpeed[1]*5;
            }
            TeleportEntity(client, iPlyVec, NULL_VECTOR, NULL_VECTOR);
            CreateTimer(0.1, Timer_CheckStuck, GetClientUserId(client));
            
            SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
            CreateTimer(2.0, DisableCollision, client);
            
            return Plugin_Changed;
        }
        
        if (client != attacker && TF2_IsPlayerInCondition(client, view_as<TFCond>(65)) && Special != ASHSpecial_Agent && Special != ASHSpecial_MiniHale && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, view_as<TFCond>(13)))
        {
            float client_hp = float(TF2_GetPlayerMaxHealth(client));
            if (TF2_GetPlayerClass(client) != TFClass_Heavy) {
                float damage_client = client_hp * 0.75 / 3;
                damage = damage_client;
            } else {
                float damage_client = client_hp * 0.45 / 3;
                damage = damage_client;
            }
            damagetype = 0;
        }
    }
    
    if (g_bEnabled) {
        if (attacker == 0 && client == Hale) {
            damage = 0.0;
            damagetype = 0;
            damagecustom = 0;
            return Plugin_Changed;
        }
    }
    
    if (!g_bEnabled || !IsValidEdict(attacker) || ((attacker <= 0) && (client == Hale)) || TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
        return Plugin_Continue;

    if (attacker == Hale && Special == ASHSpecial_Agent && TF2_GetPlayerClass(client) == TFClass_Sniper && FindWearableOnPlayer(client, 57) && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee)) {
        CreateTimer(0.1, StunPlayer_Timer, GetClientUserId(Hale));
    }
    
    if (attacker == Hale && client != Hale && Special == ASHSpecial_Bunny && IsValidEntity(SpecialWeapon) && (!(damagetype & DMG_CLUB))) {
        if (SpecialWeapon == GetPlayerWeaponSlot(Hale, TFWeaponSlot_Primary)) {
            char className[64];
            GetEntityClassname(GetPlayerWeaponSlot(Hale, TFWeaponSlot_Primary), className, 64);
            if (StrEqual(className, "tf_weapon_cannon"))
                BlindPlayer(client, 6);
        }
    }

    // if (client == 0 || attacker == 0 || inflictor == 0) return Plugin_Continue;
    
    if (isHaleNeedManyDamage && client == Hale) {
        if (damagecustom == TF_CUSTOM_BACKSTAB) {
            damagecustom = 0;
            damage *= 0.01;
        }
        damage *= 0.5;
        return Plugin_Changed;
    }
    
    if (ASHRoundState == ASHRState_Waiting && (client == Hale || (client != attacker && attacker != Hale)))
    {
        damage *= 0.0;
        return Plugin_Changed;
    }
    
    float vPos[3];
    GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vPos);
    
    if ((attacker == Hale) && IsValidClient(client) && (client != Hale) && !TF2_IsPlayerInCondition(client, TFCond_Bonked) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) {
        char InflictorName[64];
        GetEntityClassname(inflictor, InflictorName, 64);
        if (!StrEqual(InflictorName, "tf_projectile_pipe")) {
            if (RemoveDemoShield(client) || RemoveRazorback(client)) { // If the demo had a shield to break
                EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, 100, _, vPos, _, false);
                EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, 100, _, vPos, _, false);
                TF2_AddCondition(client, TFCond_UberchargedHidden, 0.1);
                TF2_AddCondition(client, TFCond_SpeedBuffAlly, 2.0);
                return Plugin_Continue;
            }
        }
        
        if (Special == ASHSpecial_MiniHale && damage > 120.0) {
            damagetype = DMG_CLUB;
            damage = 120.0;
            return Plugin_Changed;
        }
        
        if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
        {
            ScaleVector(damageForce, 9.0);
            damage *= 0.3;
            return Plugin_Changed;
        }
        if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
        {
            damage *= 9;
            TF2_AddCondition(client, TFCond_Bonked, 0.1);
            return Plugin_Changed;
        }
        if (TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
        {
            damage *= 0.25;

            return Plugin_Changed;
        }

        bool bDontDeadRingDamage = false;
        TFClassType iClass = TF2_GetPlayerClass(client);

        switch (iClass)
        {
            case TFClass_Spy:
            {
                if (damagecustom != TF_CUSTOM_BOOTS_STOMP)
                {
                    if (GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_Cloaked))
                    {
                        damagetype &= ~DMG_CRIT;

                        if ((damagetype & DMG_CLUB) && !bDontDeadRingDamage) // Check melee damage so eggs from bunny don't get processed here.
                        {
                            damage = (GetClientCloakIndex(client) == 59) ? 620.0 : 850.0;
                        }
                        else if (bDontDeadRingDamage) // This is in preparation for for future stuff.
                        {
                            damage *= 10.0; 
                        }

                        return Plugin_Changed;
                    }
                }
            }
        }

        if ((TF2_GetPlayerClass(client) == TFClass_Heavy) && ((damagetype & DMG_CLUB) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 312) & (TF2_IsPlayerInCondition(Hale, TFCond_TeleportedGlow)))
        {
            damage = 150.0;
            return Plugin_Changed;
        }

        int buffweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        int buffindex = (IsValidEntity(buffweapon) && buffweapon > MaxClients ? GetEntProp(buffweapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
        if (buffindex == 226)
        {
            CreateTimer(0.25, Timer_CheckBuffRage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        }
        if (damage <= 160.0 && !(Special == ASHSpecial_CBS && inflictor != attacker) && (Special != ASHSpecial_Bunny || weapon == -1 || weapon == GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee)))
        {
            damage *= 3;
            return Plugin_Changed;
        }
    }
    else if (attacker != Hale && client == Hale)
    {
        if (attacker <= MaxClients)
        {
            // ASH STATS UPDATE
            if (damagecustom == TF_CUSTOM_HEADSHOT) ASHStats[HeadShots]++;
            if (damagecustom == TF_CUSTOM_BACKSTAB) ASHStats[BackStabs]++;
            // ASH STATS UPDATE

            if (!g_bHaleProtectPunch && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 656 && 656 == 657) {
                g_bHaleProtectPunch = true;
                CreateTimer(7.0, ResetPunchProtect);

                float fAnimLength;
                switch (Special) {
                    case ASHSpecial_Vagineer:   fAnimLength = 0.0;
                    case ASHSpecial_Agent:      fAnimLength = 0.0;
                    case ASHSpecial_Bunny:      fAnimLength = 0.0;
                    case ASHSpecial_CBS:        fAnimLength = 0.0;
                    case ASHSpecial_HHH:        fAnimLength = 0.0;
                    default:                    fAnimLength = 0.0;
                }

                TF2_StunPlayer(Hale, fAnimLength, 0.0, TF_STUNFLAG_LIMITMOVEMENT | TF_STUNFLAG_THIRDPERSON, 0);
                UTIL_SetupEntityAnimation(Hale, "taunt_laugh");
            }

            if (Special == ASHSpecial_Agent && attacker == Hale && damagecustom == TF_CUSTOM_BACKSTAB)
                AgentHelper_ChangeTimeBeforeInvis(4.0, Hale);
            
            bool bChanged = false;
            int iFlags = GetEntityFlags(Hale);
            
            if ((iFlags & (FL_ONGROUND|FL_DUCKING)) == (FL_ONGROUND|FL_DUCKING)) {
                TF2Attrib_SetByDefIndex(Hale, 252, 0.0);        // "damage force reduction"
            } else {
                TF2Attrib_RemoveByDefIndex(Hale, 252);
            }
            
            if ((iFlags & (FL_ONGROUND|FL_DUCKING)) == (FL_ONGROUND|FL_DUCKING)) {
                damagetype |= DMG_PREVENT_PHYSICS_FORCE;
                bChanged = true;
            }
    
            if (IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 154 && SpecialPlayers_LastActiveWeapons[attacker] == GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")) {
                if (SpecialDemo_Kostyl[attacker] < 4) damage = 108.25;
                else damage = 14.15;
                
                SpecialDemo_Kostyl[attacker]++;
                if (SpecialDemo_Kostyl[attacker] == 4)
                    EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, 100, _, _, _, false);
                return Plugin_Changed;
            }

            int wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
            if (inflictor == attacker || inflictor == weapon) // This prevents sentry damage and grenade/rocket damage from processing... not sure why this is here really.
            {
                if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
                {
                    damage = 1024.0;

                    return Plugin_Changed;
                }
                if (damagecustom == TF_CUSTOM_TELEFRAG) //if (!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) == DMG_CRUSH && damage == 1000.0)    //THIS IS A TELEFRAG
                {
                    if (!IsPlayerAlive(attacker)) // Is this even possible?
                    {
                        damage = 1.0;
                        return Plugin_Changed;
                    }

                    damage = 9001.0; //(HaleHealth > 9001 ? 15.0:float(GetEntProp(Hale, Prop_Send, "m_iHealth")) + 90.0);

                    int teleowner = FindTeleOwner(attacker);

                    if (IsValidClient(teleowner) && teleowner != attacker)
                    {
                        Damage[teleowner] += 5401; //RoundFloat(9001.0 * 3 / 5);
                        PriorityCenterText(teleowner, true, "TELEFRAG ASSIST! Nice job setting up!");
                    }

                    PriorityCenterText(attacker, true, "TELEFRAG! Well done, engineer!");
                    PriorityCenterText(client, true, "TELEFRAG! Be careful around quantum tunneling devices!");
                    return Plugin_Changed;
                }
                switch (wepindex)
                {
                    case 461:    // Big Earner
                    {
                        TF2_AddCondition(attacker, TFCond_TeleportedGlow);
                    }
                    case 593:       //Third Degree
                    {
                        int[] healers = new int[TF_MAX_PLAYERS];
                        int healercount = 0;
                        for (int i = 1; i <= MaxClients; i++)
                        {
                            if (IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i) == attacker))
                            {
                                healers[healercount] = i;
                                healercount++;
                            }
                        }
                        for (int i = 0; i < healercount; i++)
                        {
                            if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
                            {
                                int medigun = GetPlayerWeaponSlot(healers[i], TFWeaponSlot_Secondary);
                                if (IsValidEntity(medigun))
                                {
                                    char s[64];
                                    GetEntityClassname(medigun, s, sizeof(s));
                                    if (StrEqual(s, "tf_weapon_medigun", false))
                                    {
                                        float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") + (0.1 / healercount);
                                        float max = 1.0;
                                        if (GetEntProp(medigun, Prop_Send, "m_bChargeRelease")) max = 1.5;
                                        if (uber > max) uber = max;
                                        SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
                                    }
                                }
                            }
                        }
                    }
                    case 14, 201, 664, 851,
                         230, 402, 526, 30665, 1098, 752,          // Non-stock weapons
                         792, 801, 881, 890, 899, 908, 957, 966,   // Botkillers
                         15000, 15007, 15019, 15023, 15033, 15059: // Gunmettle weapons
                    {
                        switch (wepindex) // Stock sniper rifle highlights Hale
                        {
                            case 14, 201, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966, 15000, 15007, 15019, 15023, 15033, 15059:
                            {
                                if (ASHRoundState != ASHRState_End)
                                {
                                    float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
                                    float time = (GlowTimer > 10 ? 1.0 : 2.0);
                                    time += (GlowTimer > 10 ? (GlowTimer > 20 ? 1 : 2) : 4)*(chargelevel/100);
                                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
                                    GlowTimer += RoundToCeil(time);
                                    if (GlowTimer > 30.0) GlowTimer = 30.0;
                                }
                            }
                        }
                        if (wepindex == 752 && ASHRoundState != ASHRState_End)
                        {
                            float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
                            float add = 10 + (chargelevel / 10);
                            if (TF2_IsPlayerInCondition(attacker, view_as<TFCond>(46))) add /= 3;
                            float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
                            SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + add > 100) ? 100.0 : rage + add);
                        }
                        if (!(damagetype & DMG_CRIT))
                        {
                            bool ministatus = (TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_CritHype));

                            damage *= (ministatus) ? 2.222222 : 3.0;

                            if (wepindex == 230)
                            {
                                HaleRage -= RoundFloat(damage/2.0);
                                if (HaleRage < 0) HaleRage = 0;
                            }

                            return Plugin_Changed;
                        }
                        else if (wepindex == 230)
                        {
                            HaleRage -= RoundFloat(damage*3.0/2.0);
                            if (HaleRage < 0) HaleRage = 0;
                        }
                    }
                    case 355:
                    {
                        CreateTimer(8.0, Timer_DeathMark, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                    }
                    case 132, 266, 482, 1082: IncrementHeadCount(attacker);
                    case 416:     // Chdata's Market Gardener backstab
                    {
                        if (!isHaleNeedManyDamage && RemoveCond(attacker, TFCond_BlastJumping)) // New way to check explosive jumping status
                        {
                            // if (Special == ASHSpecial_HHH && !(GetEntityFlags(client) & FL_ONGROUND) && IsPlayerStuck(attacker) && TR_GetEntityIndex() == client) // TFCond_Dazed
                            // {
                            //     TF2_RemoveCondition(attacker, TFCond_BlastJumping);     // Prevent HHH from being market gardened more than once in midair during a teleport
                            // }

                            float flHaleHealthMax = float(HaleHealthMax);
                            damage = (Pow(flHaleHealthMax*0.0015, 2.0) + 650.0 - (g_flMarketed/128.0*flHaleHealthMax))/3.0;    //divide by 3 because this is basedamage and lolcrits
                            damagetype |= DMG_CRIT;

                            if (RemoveCond(attacker, TFCond_Parachute))     // If you parachuted to do this, remove your parachute.
                            {
                                damage *= 0.67;                         //    And nerf your damage
                            }

                            if (g_flMarketed < 5.0)
                            {
                                g_flMarketed++;
                            }

                            PriorityCenterText(attacker, true, "You market gardened him!");
                            PriorityCenterText(client, true, "You were just market gardened!");

                            EmitSoundToAll("player/doubledonk.wav", attacker);

                            return Plugin_Changed;
                        }
                    }
                    case 38, 457, 1000:
                    {
                        if (!isHaleNeedManyDamage && RemoveCond(attacker, TFCond_BlastJumping))
                        {
                            float flHaleHealthMax = float(HaleHealthMax);
                            damage = (Pow(flHaleHealthMax*0.0015, 2.0) + 650.0 - (g_flMarketed/128.0*flHaleHealthMax))/3.0;
                            damagetype |= DMG_CRIT;

                            if (g_flMarketed < 5.0)
                            {
                                g_flMarketed++;
                            }

                            PriorityCenterText(attacker, true, "You market gardened him!");
                            PriorityCenterText(client, true, "You were just market gardened!");

                            EmitSoundToAll("player/doubledonk.wav", attacker);

                            return Plugin_Changed;
                        }
                    }
                    case 307: // [s]KABOOM INDEED[/s] Ullapool Caber
                    {
                        float flHaleHealthMax = float(HaleHealthMax);
                        if (!ullapoolWarRound) {
                            damage = (Pow(flHaleHealthMax*0.0005, 2.0) + 500.0 - (g_flMarketed/128.0*flHaleHealthMax))/3.0;
                            damagetype |= DMG_CRIT;
                        } else {
                            damage = GetRandomFloat(650.0, 950.0);
                            damagetype = 0;
                        }
                        PriorityCenterText(attacker, true, "You cabered him!");
                        PriorityCenterText(client, true, "You were just cabered!");
                        EmitSoundToAll("misc/halloween/spell_meteor_impact.wav", attacker);
                        return Plugin_Changed;
                    }
                    case 317: SpawnSmallHealthPackAt(client, GetEntityTeamNum(attacker));
                    case 214: // Powerjack
                    {
                        AddPlayerHealth(attacker, 25, 50);
                        RemoveCond(attacker, TFCond_OnFire);
                        return Plugin_Changed;
                    }
                    case 594: // Phlog
                    {
                        if (!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
                        {
                            damage /= 2.0;
                            return Plugin_Changed;
                        }
                    }
                    case 357:
                    {
                        SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
                        if (GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
                            SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
                        AddPlayerHealth(attacker, 100, 125);
                        RemoveCond(attacker, TFCond_OnFire);
                    }
                    case 36:
                        AddPlayerHealth(attacker, 15, 125);
                    case 61, 1006:    //Ambassador does 2.5x damage on headshot
                    {
                        if (damagecustom == TF_CUSTOM_HEADSHOT)
                        {
                            damage = 51.5;
                            return Plugin_Changed;
                        }
                    }
                    case 525, 595:
                    {
                        int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");

                        if (iCrits > 0) //If a revenge crit was used, give a damage bonus
                        {
                            damage = 66.6667;
                            return Plugin_Changed;
                        }
                    }
                    /*case 528:
                    {
                        if (circuitStun > 0.0)
                        {
                            TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
                            EmitSoundToAll("weapons/barret_arm_zap.wav", client);
                            EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
                        }
                    }*/
                    case 812, 833:
                    {
                        TF2_StunPlayer(client, 2.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
                    }
                    /*case 44:
                    {
                        int iStunParity = GetEntProp(client, Prop_Send, "m_iMovementStunParity");
                        if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && (iStunParity == 2 || iStunParity == 1))
                        {
                            TF2_StunPlayer(client, 4.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
                        }
                    }*/
                    case 447:
                    {
                        InsertCond(attacker, TFCond_SpeedBuffAlly, 23.0);
                    }
                    case 1181:
                    {
                        InsertCond(attacker, TFCond_SpeedBuffAlly, 12.0);
                    }
                    case 426:
                    {
                        InsertCond(attacker, TFCond_SpeedBuffAlly, 8.0);
                    }
                    case 171: // Shiv Inv
                    {
                        if (!TF2_IsPlayerInCondition(attacker, view_as<TFCond>(66)))
                        {
                            TF2_AddCondition(attacker, view_as<TFCond>(66), 6.0);
                            EmitSoundToClient(attacker, "misc/halloween/spell_stealth.wav");
                        }
                    }
                }
                
                if (damagecustom == TF_CUSTOM_BACKSTAB)
                {
                    /*
                     Rebalanced backstab formula.
                     By: Chdata

                     Stronger against low HP Hale.
                     Weaker against high HP Hale (but still good).

                    */
                    if (wepindex == 649)
                    {
                        float flHaleHealthMax = float(HaleHealthMax);
                        damage = ( (Pow(flHaleHealthMax*0.0014, 2.0) + 599.0) - (flHaleHealthMax*g_flStabbed/100.0) )/3.0;
                    }
                    else
                    {
                        float flHaleHealthMax = float(HaleHealthMax);
                        damage = ( (Pow(flHaleHealthMax*0.0014, 2.0) + 899.0) - (flHaleHealthMax*g_flStabbed/100.0) )/3.0;
                    }

                    damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

                    if (wepindex == 649) {
                        TF2_StunPlayer(client, 3.0, 0.35, TF_STUNFLAG_SLOWDOWN, attacker);
                    }

                    EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, vPos, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, vPos, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(client, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(client, "weapons/icicle_freeze_victim_01.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.00, 100, _, vPos, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(attacker, "weapons/icicle_freeze_victim_01.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.00, 100, _, vPos, NULL_VECTOR, false, 0.0);

                    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
                    SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);
                    SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime() + 2.0);
                    int vm = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
                    if (vm > MaxClients && IsValidEntity(vm) && TF2_GetPlayerClass(attacker) == TFClass_Spy)
                    {
                        int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
                        int anim = 15;
                        switch (melee)
                        {
                            case 727: anim = 41;
                            case 4, 194, 665, 794, 803, 883, 892, 901, 910: anim = 10;
                            case 638: anim = 31;
                        }
                        SetEntProp(vm, Prop_Send, "m_nSequence", anim);
                    }
                    if (wepindex != 649)
                    {
                        PriorityCenterText(attacker, true, "You backstabbed him!");
                        PriorityCenterText(client, true, "You were just backstabbed!");
                    }
                    int pistol = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary);

                    if (pistol == 525)
                    {
                        int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
                        SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+2);
                    }

                    if (wepindex == 356) // Kunai
                    {
                        AddPlayerHealth(attacker, 180, 270, true);
                        TF2_StunPlayer(client, 3.0, 0.0, TF_STUNFLAGS_GHOSTSCARE, attacker);
                    }
                    if (wepindex == 461)
                    {
                        SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);
                        TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 8.0);
                    }
                    char s[PLATFORM_MAX_PATH];

                    if (wepindex != 649) {
                        switch (Special) {
                            case ASHSpecial_Hale, ASHSpecial_MiniHale: {
                                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, GetRandomInt(1, 4));
                                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                            }

                            case ASHSpecial_Vagineer: {
                                if (GetRandomInt(0,1)) {
                                    EmitSoundToAll("vo/engineer_positivevocalization01.mp3", _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "vo/engineer_positivevocalization01.mp3", _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                } else {
                                    EmitSoundToAll(VagineerStabbed, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, VagineerStabbed, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                }
                            }

                            case ASHSpecial_HHH: {
                                Format(s, PLATFORM_MAX_PATH, "vo/halloween_boss/knight_pain0%d.mp3", GetRandomInt(1, 3));
                                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                            }

                            case ASHSpecial_Bunny: {
                                strcopy(s, PLATFORM_MAX_PATH, BunnyPain[GetRandomInt(0, sizeof(BunnyPain)-1)]);
                                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                                EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                            }

                            case ASHSpecial_Agent: {
                                char SoundFile[PLATFORM_MAX_PATH];
                                strcopy(SoundFile, PLATFORM_MAX_PATH, Agent_Backstabbed[GetRandomInt(0,4)]);
                                        
                                PlaySoundForPlayers(SoundFile);
                                PlaySoundForPlayers(SoundFile);
                            }
                        }
                    }

                    if (g_flStabbed < 4.0)
                        g_flStabbed++;
                    /*new healers[TF_MAX_PLAYERS]; // Medic assist unnecessary due to being handled in player_hurt now.
                    new healercount = 0;
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i) == attacker))
                        {
                            healers[healercount] = i;
                            healercount++;
                        }
                    }
                    for (new i = 0; i < healercount; i++)
                    {
                        if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
                        {
                            if (uberTarget[healers[i]] == attacker)
                                Damage[healers[i]] += iChangeDamage;
                            else
                                Damage[healers[i]] += RoundFloat(changedamage/(healercount+1));
                        }
                    }*/
                    return Plugin_Changed;
                }

                if (bChanged)
                {
                    return Plugin_Changed;
                }
            }
            if (TF2_GetPlayerClass(attacker) == TFClass_Scout)
            {
                if (wepindex == 45 || ((wepindex == 209 || wepindex == 294 || wepindex == 23 || wepindex == 160 || wepindex == 449) && (TF2_IsPlayerCritBuffed(client) || TF2_IsPlayerInCondition(client, TFCond_CritCola) || TF2_IsPlayerInCondition(client, TFCond_Buffed) || TF2_IsPlayerInCondition(client, TFCond_CritHype))))
                {
                    ScaleVector(damageForce, 0.38);
                    return Plugin_Changed;
                }
            }
            
            if (Special == ASHSpecial_Agent && client == Hale && damagecustom != TF_CUSTOM_BACKSTAB) {
                TFClassType attackerclass = TF2_GetPlayerClass(attacker);
                
                char InflictorName[64];
                GetEntityClassname(inflictor, InflictorName, 64);
                
                if (!(StrEqual(InflictorName, "obj_sentrygun") || StrEqual(InflictorName, "tf_projectile_sentryrocket"))) {
                    if ((damage > 500.0 && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary)) || attackerclass == TFClass_DemoMan) damage = (damage/4.0)*3.0;
                    else damage *= 1.5;
                    
                    if (IsWeaponSlotActive(attacker, TFWeaponSlot_Primary) || attackerclass == TFClass_DemoMan) {
                        if (attackerclass == TFClass_Pyro) {
                            damage *= 0.2;
                        }
                        if (attackerclass == TFClass_Pyro) damagetype = 16779264;
                        if (attackerclass != TFClass_Pyro) damagecustom = 0;
                    }
                }
            }
        }
        else
        {
            char s[64];
            if (GetEdictClassname(attacker, s, sizeof(s)) && strcmp(s, "trigger_hurt", false) == 0 && damage >= 150)
            {
                if (bSpawnTeleOnTriggerHurt)
                {
                    // Teleport the boss back to one of the spawns.
                    // And during the first 30 seconds, he can only teleport to his own spawn.
                    //TeleportToSpawn(Hale, (bTenSecStart[1]) ? HaleTeam : 0);
                    TeleportToMultiMapSpawn(Hale, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? HaleTeam : 0);
                }
                else if (damage >= 300.0)
                {
                    if (Special == ASHSpecial_HHH)
                    {
                        //TeleportToSpawn(Hale, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? HaleTeam : 0);
                        TeleportToMultiMapSpawn(Hale, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? HaleTeam : 0);
                    }
                    else if (HaleCharge >= 0)
                    {
                        bEnableSuperDuperJump = true;
                    }
                }

                float flMaxDmg = float(HaleHealthMax) * 0.05;
                if (flMaxDmg > 500.0)
                {
                    flMaxDmg = 500.0;
                }

                if (damage > flMaxDmg)
                {
                    damage = flMaxDmg;
                }
                HaleHealth -= RoundFloat(damage);
                HaleRage += RoundFloat(damage);
                if (HaleHealth <= 0) damage *= 5;
                if (HaleRage > RageDMG)
                    HaleRage = RageDMG;
                return Plugin_Changed;
            }
        }
    }
    else if (attacker != Hale && client != Hale && IsValidClient(client) && (damagetype & DMG_FALL)) // IsValidClient(client, false)
    {
        bool isHaveBooties = FindWearableOnPlayer(client, 133);
        if (!isHaveBooties) isHaveBooties = FindWearableOnPlayer(client, 405);
        if (!isHaveBooties) isHaveBooties = FindWearableOnPlayer(client, 444);

        if (isHaveBooties && attacker == 0)
        {
            PrintToServer("[ASH] Client %N have booties. Change damage value...", client);
            damage /= 10.0;

            return Plugin_Changed;
        }
        
        if (IsPlayerAlive(client) && attacker == 0 && TF2_GetPlayerClass(client) == TFClass_Pyro)
        {
            TF2_RemoveCondition(client, TFCond_BlastJumping);
        }
        
        if (IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Spy && GetIndexOfWeaponSlot(client, TFWeaponSlot_Watch) == 59) {
            char clsnm[64];
            GetEntityClassname(attacker, clsnm, 64);
            
            if (StrEqual(clsnm, "trigger_hurt") && damage >= 300.0) {
                damage *= 100.0;
                return Plugin_Changed;
            }
        }
    }
    
    if (client == attacker && TF2_GetPlayerClass(client) == TFClass_Pyro && IsPlayerAlive(client))
    {
        TF2_AddCondition(client, TFCond_BlastJumping);
    }
    
    // Crits on air, Dev Kruzya
    if (IsValidClient(attacker) && IsValidClient(client)) {
        if (client == Hale && SpecialCrits_ForHale[attacker]) {
            /*
             * Rocket Launcher [MINI] = 18, 205, 513, 658, 800, 809, 889, 898, 907, 916, 965, 974, 15006, 15014, 15028, 15043, 15052, 15057, 15081, 15104, 15129, 15150.
             * Black Box [MINI] = 228, 1085. 
             * Libery Launcher [MINI] = 414. 
             * Beggar's Bazooka [MINI] = 730. 
             * Direct Hit [CRIT] = 127. (DISABLED IN 1.05)
             * Cow Mangler 5000 [MINI] = 441. 
             * Reserve Shooter [MINI] = 415.
             * Air Strike [MINI] = 1104.
             */
                         
            if (IsWeaponSlotActive(attacker, TFWeaponSlot_Primary)) {
                switch (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)) {
                    case 18, 205, 513, 658, 800, 809, 889, 898, 907, 916, 965, 974, 15006, 15014, 15028, 15043, 15052, 15057, 15081, 15104, 15129, 15150, 228, 1085, 414, 730, 441, 1104: {
                        damage *= 1.35;
                        return Plugin_Changed;
                    }
                }
            }
                        
            if (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Secondary) == 415 && IsWeaponSlotActive(attacker, TFWeaponSlot_Secondary)) {
                damage *= 1.35;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

/*public void OnGameFrame() {
    for (int i = 1; i <= MAXPLAYERS; i++) {
        if (AQUACURE_EntShield[i] != 0) {
            if (AQUACURE_EntShield[i] > 0) {
                float pos[3];
//        int iClient = GetEntPropEnt(AQUACURE_EntShield, Prop_Send, "m_hOwnerEntity");
                int iClient = AQUACURE_EntShield[i];
                if (IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1) {
                    GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", pos);
                    TeleportEntity(AQUACURE_EntShield[i], pos, NULL_VECTOR, NULL_VECTOR);
                } else {
                    DataPack hPack = new DataPack();
                    hPack.WriteCell(iClient);
                    hPack.WriteCell(AQUACURE_EntShield[i]);
                    hPack.Reset();
                    AQUACURE_Disable(null, hPack);
                }
            }
        }
    }
}*/

public Action OnEurekaUse(int iClient, const char[] szCommand, int iArgC) {
    if (g_flEurekaCooldown[iClient] > GetGameTime()) {
        return Plugin_Handled;
    }

    int iWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
    if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") != 589) {
        return Plugin_Continue;
    }

    g_flEurekaCooldown[iClient] = GetGameTime() + 20.0;
    TF2Attrib_RemoveByDefIndex(iWeapon, 352);
    UTIL_CreateBelatedAttributeChange(20.0, iWeapon, 352, 1.0);

    return Plugin_Continue;
}

public Action OnStartTouch(int client, int other) 
{
    if (!IsValidClient(other))
        return Plugin_Continue;
    if (client != Hale)
        return Plugin_Continue;
    
    float ClientPos[3], VictimPos[3], VictimVecMaxs[3];
    GetClientAbsOrigin(client, ClientPos);
    GetClientAbsOrigin(other,    VictimPos);
    GetEntPropVector(other, Prop_Send, "m_vecMaxs", VictimVecMaxs);
    
    float VictimHeight = VictimVecMaxs[2];
    float HeightDiff     = ClientPos[2] - VictimPos[2];
    
    if (HeightDiff > VictimHeight) {
        float vec[3];
        GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
        float vPos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
        
        if (vec[2] <= -550.0 && !TF2_IsPlayerInCondition(client, view_as<TFCond>(64))) {
            if (RemoveDemoShield(other) || RemoveRazorback(other)) { // If the demo had a shield to break
                EmitSoundToClient(other, "player/spy_shield_break.wav", _, _, _, _, 0.7, 100, _, vPos, _, false);
                EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, 100, _, vPos, _, false);
                TF2_AddCondition(other, TFCond_UberchargedHidden, 0.1);
                TF2_AddCondition(other, TFCond_SpeedBuffAlly, 2.0);
                return Plugin_Continue;
            } else {
                FakeKill_Goomba = 1;
                SDKHooks_TakeDamage(other, client, client, 202.0, DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH | DMG_ALWAYSGIB);
                FakeKill_Goomba = 0;
            }
        }
    }
    return Plugin_Continue;
}

public void OnConfigsExecuted()
{
    char oldversion[64];
    GetConVarString(cvarVersion, oldversion, sizeof(oldversion));
    if (strcmp(oldversion, ASH_PLUGIN_VERSION, false) != 0) LogError("[VS Saxton Hale] Warning: your config may be outdated. Back up your tf/cfg/sourcemod/SaxtonHale.cfg file and delete it, and this plugin will generate a new one that you can then modify to your original values.");
    SetConVarString(FindConVar("hale_version"), ASH_PLUGIN_VERSION);
    SetConVarString(cvarBuild, ASH_BUILD);
    HaleSpeed = GetConVarFloat(cvarHaleSpeed);
    RageDMG = GetConVarInt(cvarRageDMG);
    RageDist = GetConVarFloat(cvarRageDist);
    Announce = GetConVarFloat(cvarAnnounce);
    bSpecials = GetConVarBool(cvarSpecials);
    PointType = GetConVarInt(cvarPointType);
    PointDelay = GetConVarInt(cvarPointDelay);
    if (PointDelay < 0) PointDelay *= -1;
    AliveToEnable = GetConVarInt(cvarAliveToEnable);
    haleCrits = GetConVarBool(cvarCrits);
    bDemoShieldCrits = GetConVarBool(cvarDemoShieldCrits);
    bAlwaysShowHealth = GetConVarBool(cvarDisplayHaleHP);
    newRageSentry = GetConVarBool(cvarRageSentry);
    if (IsSaxtonHaleMap() && GetConVarBool(cvarEnabled))
    {
        UTIL_ValidateMap();

        tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
        mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
        tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
        mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
        tf_scout_hype_pep_max = GetConVarFloat(FindConVar("tf_scout_hype_pep_max"));
        tf_dropped_weapon_lifetime = GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
        tf_feign_death_activate_damage_scale = GetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"));
        tf_feign_death_damage_scale = GetConVarFloat(FindConVar("tf_feign_death_damage_scale"));
        tf_stealth_damage_reduction = GetConVarFloat(FindConVar("tf_stealth_damage_reduction"));
        tf_feign_death_duration = GetConVarFloat(FindConVar("tf_feign_death_duration"));
        tf_feign_death_speed_duration = GetConVarFloat(FindConVar("tf_feign_death_speed_duration"));
        
        SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
        SetConVarInt(FindConVar("mp_teams_unbalance_limit"), (RoundCount > 0) ? 0 : 1); // s_bLateLoad ? 0 : 
        //SetConVarInt(FindConVar("mp_teams_unbalance_limit"), GetConVarBool(cvarFirstRound)?0:1);
        SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
        SetConVarInt(FindConVar("mp_forcecamera"), 0);
        SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), 100.0);
        SetConVarInt(FindConVar("tf_damage_disablespread"), 1);
        SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);

        SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), 0.1);
        SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), 0.1);
        SetConVarFloat(FindConVar("tf_stealth_damage_reduction"), 0.1);
        SetConVarFloat(FindConVar("tf_feign_death_duration"), 7.0);
        SetConVarFloat(FindConVar("tf_feign_death_speed_duration"), 0.0);

#if defined _SteamWorks_Included
        if (g_bSteamWorksIsRunning)
        {
            char gameDesc[64];
            FormatEx(gameDesc, sizeof(gameDesc), "Advanced Saxton Hale (%s)", ASH_PLUGIN_VERSION);
            SteamWorks_SetGameDescription(gameDesc);
        }
#endif

        g_bEnabled = true;
        g_bAreEnoughPlayersPlaying = true;
        if (Announce > 1.0)
        {
            CreateTimer(Announce, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        g_bAreEnoughPlayersPlaying = false;
        g_bEnabled = false;
    }
}
public void OnMapStart()
{
    PrecachedLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    PrecacheModel("models/effects/resist_shield/resist_shield.mdl");

    cheatEnable(null, 2);
    ullapoolWarMap = true;
    hotnightMap = true;
    BushmanRulesMap = true;
    // AQUACURE_Available = true;
    TeamRoundCounter = 0;
    MusicTimer = null;
    doorchecktimer = null;
    Hale = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        ASHFlags[i] = 0;
    }
    if (IsSaxtonHaleMap(true))
    {
        UTIL_AddToDownload();
        IsDate(.bForceRecalc = true);
        MapHasMusic(true);
        CheckToChangeMapDoors();
        CheckToTeleportToSpawn();
    }
    RoundCount = 0;
}
public void OnMapEnd()
{
    if (g_bAreEnoughPlayersPlaying || g_bEnabled)
    {
        SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
        SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
        SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
        SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
        SetConVarFloat(FindConVar("tf_scout_hype_pep_max"), tf_scout_hype_pep_max);
        SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);

        SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), tf_feign_death_activate_damage_scale);
        SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), tf_feign_death_damage_scale);
        SetConVarFloat(FindConVar("tf_stealth_damage_reduction"), tf_stealth_damage_reduction);
        SetConVarFloat(FindConVar("tf_feign_death_duration"), tf_feign_death_duration);
        SetConVarFloat(FindConVar("tf_feign_death_speed_duration"), tf_feign_death_speed_duration);
#if defined _SteamWorks_Included
        if (g_bSteamWorksIsRunning)
        {
            SteamWorks_SetGameDescription("Adv. Saxton Hale");
        }
#endif

        if (GetConVarBool(cvarFirstRound)) {
            g_bEnabled = false;
            ASHRoundState = ASHRState_Disabled;
        }
    }

    ClearTimer(MusicTimer);
}
public void OnPluginEnd()
{
    OnMapEnd();

    if (!g_bReloadASHOnRoundEnd && ASHRoundState == ASHRState_Active) {
        CPrintToChatAll("{ash}[ASH] {default}The plugin has been unexpectedly unloaded! (version {ash}v%s{default}, build {ash}%s{default})", ASH_PLUGIN_VERSION, ASH_BUILD);
    }
}

public void OnLibraryAdded(const char[] name) {
    UTIL_SetPluginDetection(name, true);
}

public void OnLibraryRemoved(const char[] name) {
    UTIL_SetPluginDetection(name, false);
}

public void OnPluginStart() {
    g_hRSHooks = new ArrayList(4);
    g_hREHooks = new ArrayList(4);

    UTIL_InitVars();
    UTIL_InitMsg();

    UTIL_LoadTranslations();
    UTIL_MakeMultiTarget();
    UTIL_LookupOffsets();
    UTIL_MakeCommands();
    UTIL_MakeConVars();
    UTIL_LoadConfig();
    UTIL_RegCookies();
    UTIL_MakeHooks();
    UTIL_MakeSpawn();
    UTIL_MakeHUDs();

    for (int client = 1; client <= MaxClients; client++) {
        UTIL_CheckClient(client);
    }
}

public Action HookSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (!g_bEnabled || ((entity != Hale) && ((entity <= 0) || !IsValidClient(Hale) || (entity != GetPlayerWeaponSlot(Hale, 0)))))
        return Plugin_Continue;
    
    if (StrContains(sample, "saxton_hale", false) != -1) {
        if (Special == ASHSpecial_MiniHale) {
            pitch = RoundToNearest((175 / (1 + (6 * 0.5))) + 75);
            flags |= SND_CHANGEPITCH;
            return Plugin_Changed;
        }
        else return Plugin_Continue;
    }
    if (strcmp(sample, "vo/engineer_LaughLong01.mp3", false) == 0)
    {
        strcopy(sample, PLATFORM_MAX_PATH, VagineerKSpree);
        return Plugin_Changed;
    }
    if (entity == Hale && Special == ASHSpecial_HHH && strncmp(sample, "vo", 2, false) == 0 && StrContains(sample, "halloween_boss") == -1)
    {
        if (GetRandomInt(0, 100) <= 10)
        {
            Format(sample, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHLaught, GetRandomInt(1, 4));
            return Plugin_Changed;
        }
    }
    
    if (Special != ASHSpecial_CBS && !strncmp(sample, "vo", 2, false) && StrContains(sample, "halloween_boss") == -1)
    {
        if (Special == ASHSpecial_Vagineer)
        {
            if (StrContains(sample, "engineer_moveup", false) != -1)
                Format(sample, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));
            else if (StrContains(sample, "engineer_no", false) != -1 || GetRandomInt(0, 9) > 6)
                strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_no01.mp3");
            else
                strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_jeers02.mp3");
            return Plugin_Changed;
        }
#if defined EASTER_BUNNY_ON
        if (Special == ASHSpecial_Bunny)
        {
            if (StrContains(sample, "gibberish", false) == -1 && StrContains(sample, "burp", false) == -1 && !GetRandomInt(0, 2))
            {
                //Do sound things
                strcopy(sample, PLATFORM_MAX_PATH, BunnyRandomVoice[GetRandomInt(0, sizeof(BunnyRandomVoice)-1)]);
                return Plugin_Changed;
            }
            return Plugin_Continue;
        }
#endif
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] szClassName)
{
    if (g_bEnabled && ASHRoundState == ASHRState_Active && strcmp(szClassName, "tf_projectile_pipe", false) == 0)
        SDKHook(entity, SDKHook_SpawnPost, OnEggBombSpawned);
}
public void OnEggBombSpawned(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (IsValidClient(owner) && owner == Hale && Special == ASHSpecial_Bunny)
        RequestFrame(Timer_SetEggBomb, EntIndexToEntRef(entity));
}

public void HideCvarNotify(Handle convar, char[] oldValue, char[] newValue)
{
    Handle svtags = FindConVar("sv_tags");
    int sflags = GetConVarFlags(svtags);
    sflags &= ~FCVAR_NOTIFY;
    SetConVarFlags(svtags, sflags);

    int flags = GetConVarFlags(convar);
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(convar, flags);
}

public void CvarChange(Handle convar, char[] oldValue, char[] newValue)
{
    if (convar == cvarHaleSpeed)
        HaleSpeed = GetConVarFloat(convar);
    else if (convar == cvarPointDelay)
    {
        PointDelay = GetConVarInt(convar);
        if (PointDelay < 0) PointDelay *= -1;
    }
    else if (convar == cvarRageDMG)
        RageDMG = GetConVarInt(convar);
    else if (convar == cvarRageDist)
        RageDist = GetConVarFloat(convar);
    else if (convar == cvarAnnounce)
        Announce = GetConVarFloat(convar);
    else if (convar == cvarSpecials)
        bSpecials = GetConVarBool(convar);
    else if (convar == cvarPointType)
        PointType = GetConVarInt(convar);
    else if (convar == cvarAliveToEnable)
        AliveToEnable = GetConVarInt(convar);
    else if (convar == cvarCrits)
        haleCrits = GetConVarBool(convar);
    else if (convar == cvarDemoShieldCrits)
        bDemoShieldCrits = GetConVarBool(cvarDemoShieldCrits);
    else if (convar == cvarDisplayHaleHP)
        bAlwaysShowHealth = GetConVarBool(cvarDisplayHaleHP);
    else if (convar == cvarRageSentry)
        newRageSentry = GetConVarBool(convar);
    //else if (convar == cvarCircuitStun)
    //    circuitStun = GetConVarFloat(convar);
    else if (convar == cvarEnabled)
    {
        if (GetConVarBool(convar) && IsSaxtonHaleMap())
        {
            g_bAreEnoughPlayersPlaying = true;
#if defined _SteamWorks_Included
            if (g_bSteamWorksIsRunning)
            {
                char gameDesc[64];
                FormatEx(gameDesc, sizeof(gameDesc), "Advanced Saxton Hale (%s)", ASH_PLUGIN_VERSION);
                SteamWorks_SetGameDescription(gameDesc);
            }
#endif
        }
    }
}

public Action Timer_Announce(Handle hTimer)
{
    static int announcecount=-1;
    announcecount++;
    if (Announce > 1.0 && g_bAreEnoughPlayersPlaying)
    {
        switch (announcecount)
        {
            case 1:        CPrintToChatAll("{ash}[ASH] {default}VS Saxton Hale group: {ash}http://steamcommunity.com/groups/vssaxtonhale");
            case 3:        CPrintToChatAll(" \n{ash}ASH v%s {default}by {olive}NITROYUASH {default}, {selfmade}CrazyHackGUT , {selfmade}FeedBlack {default}& {lightsteelblue}G44 Group\n{default}Based on {ash}VSH v%s {default}by {olive}Rainbolt Dash{default}, {olive}FlaminSarge {default}& {lightsteelblue}Chdata{default}.\n ", ASH_PLUGIN_VERSION, VSH_PLUGIN_VERSION);
            case 5:
            {
                announcecount = 0;
                CPrintToChatAll("{ash}[ASH] {default}%t", "vsh_last_update", ASH_PLUGIN_VERSION, ASH_PLUGIN_RELDATE);
            }
            default:    CPrintToChatAll("{ash}[ASH] {default}%t", "vsh_open_menu");
        }
    }
    return Plugin_Continue;
}

/*public void OnGameFrame()
{
    if (Special == ASHSpecial_Agent) 
    {
        SetEntPropFloat(Hale, Prop_Send, "m_flHeadScale", 0.1);
        SetEntPropFloat(Hale, Prop_Send, "m_flTorsoScale", 0.1); 
    }
}*/