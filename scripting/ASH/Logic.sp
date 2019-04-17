public Action ClientTimer(Handle hTimer)
{
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    char wepclassname[32];
    int i = -1;

    Vitasaw_ExecutionTimes++;
    
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client != Hale && IsClientInGame(client) && GetEntityTeamNum(client) == OtherTeam)
        {
            SetGlobalTransTarget(client);
            TFClassType iPlayerClass = ((IsPlayerAlive(client)) ? TF2_GetPlayerClass(client) : TFClass_Unknown);
           
            
            // ULLAPOOL WAR, BITCHES!
            if (ullapoolWarRound && IsPlayerAlive(client)) {
                if (iPlayerClass != TFClass_DemoMan)
                    TF2_ForceClass(client, TFClass_DemoMan);
                
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) != 307) {
                    int Ullapool = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
                    if (Ullapool > MaxClients)
                        AcceptEntityInput(Ullapool, "Kill");
                    
                    Ullapool = SpawnWeapon(client, "tf_weapon_stickbomb", 307, 100, TFQual_Unusual, "5 ; 1.2 ; 773 ; 2.0 ; 15 ; 0");
                    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", Ullapool);
                }
                
                /*if (!FindWearableOnPlayer(client, 405)) {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
                    
                    int iAllahAkbar = SpawnWeapon(client, "tf_wearable", 405, 100, TFQual_Unusual, "259 ; 1 ; 252 ; 0.25 ; 54 ; 0.9 ; 135 ; 0.50"); // Ali Baba' Wee Booties
                    TF2_EquipPlayerWearable(client, iAllahAkbar);
                }
                
                if (!FindWearableOnPlayer(client, 1099)) {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                    
                    int iShield = SpawnWeapon(client, "tf_wearable_demoshield", 1099, 100, TFQual_Unusual, "60 ; 0.85 ; 64 ; 0.85 ; 676 ; 1 ; 2029 ; 1 ; 639 ; 50 ; 2034 ; 0.75"); // Tide Turner
                    TF2_EquipPlayerWearable(client, iShield);
                }*/
            }
			
			// BUSHWACKA MODE
            
            if (BushmanRulesRound && IsPlayerAlive(client)) {
                if (iPlayerClass != TFClass_Sniper)
                    TF2_ForceClass(client, TFClass_Sniper);
                
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) != 232) {
                    int BushmanRules = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
                    if (BushmanRules > MaxClients)
                        AcceptEntityInput(BushmanRules, "Kill");
                    
                    BushmanRules = SpawnWeapon(client, "tf_weapon_club", 232, 100, TFQual_Unusual, "236 ; 1 ; 1 ; 0 ; 75 ; 1.35");
                    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", BushmanRules);
                }
                
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary); 
                
                if (!FindWearableOnPlayer(client, 57)) {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                }
            }
            
            // Disable "Dispenser Mode" (Scout Cheat) using Right Mouse Button (RMB)
            /*if (dispenserEnabled[client] && GetClientButtons(client) & IN_ATTACK2 && iPlayerClass == TFClass_Scout && IsPlayerAlive(client)) {
                float pos[3];
                GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
                pos[2] += 20.0;
                EmitSoundToAll("misc/doomsday_lift_start.wav", client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
                float pPos[3] = {0.0, 0.0, 10.0};
                CreateTimer(0.5, Dispenser_Disable_TP, client);
                AttachParticle(client, "heavy_ring_of_fire_child03", 1.0, pPos, true);
                SetVariantString("");
                AcceptEntityInput(client, "SetCustomModel");
                TF2_RegeneratePlayer(client);
                SetEntProp(client, Prop_Send, "m_iHealth", ClientsHealth[client]);
                dispenserEnabled[client] = false;
            }*/

            // Right click 
            if (GetClientButtons(client) & IN_ATTACK2) {
                RCPressed[client] += 0.2;
                
                if (iPlayerClass == TFClass_Soldier && IsWeaponSlotActive(client, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 775) {
                    if (RCPressed[client] >= 4.0) {
                        RCPressed[client] = 0.0;
                        
                        Address TF2Attrib_EscapePlan = TF2Attrib_GetByDefIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 236);
                        if (TF2Attrib_EscapePlan == Address_Null || TF2Attrib_GetValue(TF2Attrib_EscapePlan) == 0.0) {
                            Soldier_EscapePlan_ModeNoHeal[client] = true;
                            TF2Attrib_SetByDefIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 236, 1.0);
                            TF2Attrib_SetByDefIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 734, 0.0);
                            
                            Handle dptrie = CreateTrie();
                            Soldier_EscapePlan_ModeNoHeal_PARTICLE[client] = CreateTimer(1.0, Particle_cycle, dptrie, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                            SetTrieValue(dptrie, "soldier", client);
                            SetTrieString(dptrie, "particle", "ping_circle");
                            
                            EmitSoundToClient(client, "weapons/vaccinator_toggle.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                        } else if (TF2Attrib_GetValue(TF2Attrib_EscapePlan) == 1.0) {
                            Soldier_EscapePlan_ModeNoHeal[client] = false;
                            TF2Attrib_RemoveByDefIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 236);
                            TF2Attrib_RemoveByDefIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), 734);
                            
                            KillTimer(Soldier_EscapePlan_ModeNoHeal_PARTICLE[client]);
                            
                            EmitSoundToClient(client, "weapons/vaccinator_toggle.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                        }
                        
                        SpecialHintsTime[client] = 3.0;
                        SpecialHints[client] = TF2Soldier_EscapePlan_NewState;
                    }
                }
            } else RCPressed[client] = 0.0;
            
            // Medic and Vita-saw
            if (iPlayerClass == TFClass_Medic && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 173 && Vitasaw_ExecutionTimes >= 25) {
                int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                float uberCharge;
                if ((uberCharge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")) < 1.0 && GetEntProp(medigun, Prop_Send, "m_bChargeRelease") == 0) SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uberCharge+0.03);
                if ((uberCharge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")) > 1.0) SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.0);
            }

            if (iPlayerClass == TFClass_Spy && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 461) {
                if (TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly) && TF2_IsPlayerInCondition(client, TFCond_Dazed)) {
                    TF2_RemoveCondition(client, TFCond_Dazed);
                    MakeModelTimer(null);
                }
            }
            
            // Infection
            if (InfectPlayers[client]) {
                SetHudTextParams(-1.0, 0.3, 1.0, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
                ShowHudText(client, -1, "%t", "ash_cbs_specialPower_YouBeenInfected");
                
                float pos[3];
                float pos2[3];
                float distance;

                GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
                for (i = 1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && IsPlayerAlive(i) && (i != client) && (i != Hale) && !ImmunityClient[i])
                    {
                        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
                        distance = GetVectorDistance(pos, pos2);
                        if (!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && distance < ASH_INFECTIONRADIUS_PLAYERS && !InfectPlayers[i])
                        {
                            InfectPlayers[i] = true;
                            CreateTimer(20.0, DisableInfection, i);
                            CreateTimer(1.0, InfectiionDamage, i, TIMER_REPEAT);
                        }
                    }
                }
                
                if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) DisableInfection(INVALID_HANDLE, client);
            }
            
            // Spy, Dead Ringer, Fake death
            if (IsPlayerAlive(client) && iPlayerClass == TFClass_Spy && GetIndexOfWeaponSlot(client, TFWeaponSlot_Watch) == 59 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked)) {
                if (GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") == 100.0) {
                    if (GetClientButtons(client) & IN_ATTACK2) {
                        if (DeadRinger_ManualActivation[client] < 1.0) DeadRinger_ManualActivation[client] += 0.2;
                        else if (DeadRinger_ManualActivation[client] < 6.0 && DeadRinger_ManualActivation[client] >= 1.0) DeadRinger_ManualActivation[client] += 1.0;
                    } else {
                        if (DeadRinger_ManualActivation[client] < 6.0 && DeadRinger_ManualActivation[client] > 1.0) DeadRinger_ManualActivation[client] = 0.0;
                        else if (DeadRinger_ManualActivation[client] >= 6.0 && DeadRinger_ManualActivation[client] >= 1.0) {
                            // Start fake death
                            TF2Attrib_SetByDefIndex(client, 728, 1.0);
                            TF2_AddCondition(client, TFCond_Cloaked, TFCondDuration_Infinite);
                            DeadRinger_ManualActivation[client] = 0.0;
                            
                            // Particle
                            float SpyPos[3];
                            GetEntPropVector(client, Prop_Send, "m_vecOrigin", SpyPos);
                            SpyPos[2] += 15.0;
                            AttachParticle(0, "heavy_ring_of_fire_child03", 1.5, SpyPos);
                            
                            // Sound
                            EmitSoundToAll("misc/doomsday_lift_start.wav", client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, SpyPos, NULL_VECTOR, true, 0.0);
                        }
                    }
                }
            }
            
            // Fix position
            if (plManmelterUsed[client] > 100) plManmelterUsed[client] = 100;
            
            // Pyro, Manmelter
            if (!ManmelterBan[client] && !plManmelterBlock[client] && IsPlayerAlive(client) && iPlayerClass == TFClass_Pyro && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 595 && IsWeaponSlotActive(client, TFWeaponSlot_Secondary) && (GetClientButtons(client) & IN_ATTACK2)) {
                int aimclient;
                if ((aimclient = GetClientAimTarget(client, true)) > 0) {
                    // Positions
                    float PyroPos[3];
                    float aimPos[3];
                    
                    GetClientEyePosition(client, PyroPos);
                    GetClientEyePosition(aimclient, aimPos);

                    if (GetVectorDistance(PyroPos, aimPos) < 800.0 && TF2_IsPlayerInCondition(aimclient, view_as<TFCond>(15)) && aimclient != Hale && TF2_GetPlayerClass(aimclient) != TFClass_Pyro) {
                        // Delete stun
                        TF2_RemoveCondition(aimclient, view_as<TFCond>(15));
                        
                        // Shoot sound
                        float vPos[3];
                        GetEntPropVector(aimclient, Prop_Send, "m_vecOrigin", vPos);
                        EmitSoundToClient(client, ManmelterSound, _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vPos, NULL_VECTOR, false, 0.0);
                        EmitSoundToClient(aimclient, ManmelterSound, _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vPos, NULL_VECTOR, false, 0.0);
                        
                        // Block pyro weapon, create timer, add usage num
                        SetNextAttack(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), 5.0);
                        plManmelterBlock[client] = true;
                        CreateTimer(5.0, ManmelterUnban, client);
                        if (plManmelterUsed[client] < 100) plManmelterUsed[client] += ManmelterHUD_Calc();
                        if (plManmelterUsed[client] > 100) plManmelterUsed[client] = 100;
                        
                        // Pyro ammo's
                        int PyroWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                        int PyroAmmos = GetAmmoNum(client, PyroWeapon);
                        if (PyroAmmos < 200) {
                            PyroAmmos += 50;
                            if (PyroAmmos > 200) PyroAmmos = 200;
                            SetAmmoNum(client, PyroWeapon, PyroAmmos);
                        }
                    }
                }
            }
            
            // Engineer Short Circuit
            if (iPlayerClass == TFClass_Engineer && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 528 && IsPlayerAlive(client) && (GetClientButtons(client) & IN_ATTACK) && IsWeaponSlotActive(client, TFWeaponSlot_Secondary)) {
                int aimentity;
                if ((aimentity = GetClientAimTarget(client, false)) > 0) {
                    char aimentityName[64];
                    GetEntityClassname(aimentity, aimentityName, 64);
                    if (StrEqual(aimentityName, "obj_sentrygun", true)) {
                        // Positions
                        float engiPos[3];
                        float aimPos[3];
                        
                        GetClientEyePosition(client, engiPos);
                        GetEntPropVector(aimentity, Prop_Send, "m_vecOrigin", aimPos);

                        if (GetVectorDistance(engiPos, aimPos) < 1300.0 && GetEntProp(aimentity, Prop_Send, "m_bDisabled") == 1 && aimentity != Hale) {
                            SetEntProp(aimentity, Prop_Send, "m_bDisabled", 0);
                            EmitSoundToClient(client, ManmelterSound, _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                        }
                    }
                }
            }

            if (iShivInv[client] != 0) 
            {
                iShivInv[client]--;
                if (TF2_IsPlayerInCondition(client, view_as<TFCond>(66)))
                    TF2_RemoveCondition(client, view_as<TFCond>(66));
            }

            
            if (iPlayerClass == TFClass_Pyro && TF2_IsPlayerInCondition(client, TFCond_BlastJumping) && (GetEntityFlags(client) & FL_ONGROUND)) TF2_RemoveCondition(client, TFCond_BlastJumping); // PYRO, MARKET GARDENER
            
            // SPY
            // Cloak and dagger
            // Player health
            int spyTemp = 0;
            /*if (iPlayerClass == TFClass_Spy) 
            {
                spyTemp = GetPlayerWeaponSlot(client, 4);
                if (IsPlayerAlive(client) && spyTemp > MaxClients && IsValidEdict(spyTemp) && GetEntProp(spyTemp, Prop_Send, "m_iItemDefinitionIndex") == 60)
                {
                    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) {
                        if (TEMP_SpyCaDTimer[client] == 5)
                        {
                            TEMP_SpyCaDTimer[client] = 0;
                            int spyHP;
                            if (spyTimeInvis[client] < 8) spyHP = 0;
                            else spyHP = 10;
                            SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth")-spyHP);
                            if (spyTimeInvis[client] != 8) spyTimeInvis[client]++;
                        }
                        else TEMP_SpyCaDTimer[client]++;
                    } else if (spyTimeInvis[client] != 0) {
                        TEMP_SpyCaDTimer[client]--;
                        if (TEMP_SpyCaDTimer[client] == 0) {
                          TEMP_SpyCaDTimer[client] = 5;
                          spyTimeInvis[client]--;
                        }
                    }
                    if (GetEntProp(client, Prop_Send, "m_iHealth") < 0) ForcePlayerSuicide(client);
                }
                else { TEMP_SpyCaDTimer[client] = 0; spyTimeInvis[client] = 0; }
            }*/
            
            // Sapper 1
            spyTemp = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
            if (spyTemp > MaxClients && IsValidEdict(spyTemp))
            {
                spyTemp = GetEntProp(spyTemp, Prop_Send, "m_iItemDefinitionIndex");
                if (spyTemp == 735 || spyTemp == 736 || spyTemp == 933 || spyTemp == 1080 || spyTemp == 1102)
                {
                    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) TF2Attrib_SetByDefIndex(client, 112, 0.0);
                    else TF2Attrib_SetByDefIndex(client, 112, 0.05);
                }
                else TF2Attrib_SetByDefIndex(client, 112, 0.0);
            }
            // Sapper 2
            if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 810 || GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 831)
            {
                if (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
                { 
                    int iHealth;
                    if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 356) 
                    {
                        iHealth = 2;
                    }
                    else if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 461)
                    {
                        iHealth = 3;
                    }
                    else 
                    {
                        iHealth = 4;
                    }
                    if (TEMP_SpySaPTimer[client] == 10)
                    {
                        int MaxHP = 125; 
                        if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 356) MaxHP = 70; 
                        else if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 461) MaxHP = 100;
                        if (GetEntProp(client, Prop_Send, "m_iHealth") < MaxHP)
                        {
                            if (MaxHP - GetEntProp(client, Prop_Send, "m_iHealth") < iHealth)
                            {   
                                iHealth = MaxHP - GetEntProp(client, Prop_Send, "m_iHealth");
                            }
                            SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth")+iHealth);
                            if (GetEntProp(client, Prop_Send, "m_iHealth") > MaxHP) SetEntProp(client, Prop_Send, "m_iHealth", MaxHP);
                        }
                        TEMP_SpySaPTimer[client] = 0;
                    }
                    else TEMP_SpySaPTimer[client]++;
                }
            }
            
            // DEMOMAN
            // Ka-Boom!
            if (iPlayerClass == TFClass_DemoMan)
            {
                int KABOOOOM = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
                if (IsPlayerAlive(client) && KABOOOOM > MaxClients && IsValidEdict(KABOOOOM) && GetEntProp(KABOOOOM, Prop_Send, "m_iItemDefinitionIndex") == 307)
                {
                    if (GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_iDetonated") == 1) ForcePlayerSuicide(client);
                }
            }
            
            bool bHudAdjust = false;
            bool bHudAdjust2 = false;

            // Engineer Eureka Effect
            if (iPlayerClass == TFClass_Engineer && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 589 && g_flEurekaCooldown[client] > GetGameTime()) {
                int iTime = RoundToCeil(g_flEurekaCooldown[client] - GetGameTime());
                if (iTime > 0) {
                    SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
                    bHudAdjust = true;
                    ShowSyncHudText(client, jumpHUD, "%t", "ash_engineer_eurekacooldown", iTime);
                }
            }
            
            /*if (GetClientCloakIndex(client) == 60) {
                int r = 255;
                int g = spyTimeInvis[client] == 0 ? 255 : 64;
                int b = spyTimeInvis[client] == 0 ? 255 : 64;
                bHudAdjust = true;
                SetHudTextParams(-1.0, 0.78, 0.35, r, g, b, 255, 0, 0.0, 0.0, 0.0);
                ShowSyncHudText(client, jumpHUD, "%t", "ash_CAD_damage", 8-spyTimeInvis[client]);
            }*/
            
            SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
            if (!IsPlayerAlive(client))
            {
                int obstarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                if (obstarget != client && obstarget != Hale && IsValidClient(obstarget))
                {
                    if (!(GetClientButtons(client) & IN_SCORE)) ShowSyncHudText(client, rageHUD, "%t", "vsh_damage_others", Damage[client], obstarget, Damage[obstarget]);
                }
                else
                {
                    if (!(GetClientButtons(client) & IN_SCORE)) ShowSyncHudText(client, rageHUD, "%t: %d", "vsh_damage_own", Damage[client]);
                }
                continue;
            }
            if (!(GetClientButtons(client) & IN_SCORE)) ShowSyncHudText(client, rageHUD, "%t: %d", "vsh_damage_own", Damage[client]);
            TFClassType class = iPlayerClass;
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            if (weapon <= MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, wepclassname, sizeof(wepclassname))) strcopy(wepclassname, sizeof(wepclassname), "");
            bool validwep = (strncmp(wepclassname, "tf_wea", 6, false) == 0);
            int index = (validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
            
            // Chdata's Deadringer Notifier
            if (iPlayerClass == TFClass_Spy)
            {
                if (GetClientCloakIndex(client) == 59)
                {
                    int drstatus = TF2_IsPlayerInCondition(client, TFCond_Cloaked) ? 2 : GetEntProp(client, Prop_Send, "m_bFeignDeathReady") ? 1 : 0;

                    char s[128];

                    switch (drstatus)
                    {
                        case 1:
                        {
                            SetHudTextParams(-1.0, 0.78, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
                            FormatEx(s, sizeof(s), "%t", "ash_spy_deadringer_ready");
                        }
                        case 2:
                        {
                            SetHudTextParams(-1.0, 0.78, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
                            FormatEx(s, sizeof(s), "%t", "ash_spy_deadringer_dead");
                        }
                        default:
                        {
                            SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
                            FormatEx(s, sizeof(s), "%t", "ash_spy_deadringer_inactive");
                        }
                    }

                    if (!(GetClientButtons(client) & IN_ATTACK2) && DeadRinger_ManualActivation[client] >= 1.0) DeadRinger_ManualActivation[client] = 0.0;
                    if (DeadRinger_ManualActivation[client] > 1.0) FormatEx(s, sizeof(s), "%t: %i%%", "ash_spy_deadringer_forcedeath", RoundToFloor(DeadRinger_ManualActivation[client]-1.0)*20);
                    
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, jumpHUD, "%s", s);
                    }

                    bHudAdjust = true;
                }
            }

            if (class == TFClass_Pyro && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 595) {
                ManmelterHUD_Render(client);
            }
            
            if (class == TFClass_Sniper)
            {
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 232)
                {
                    char s[256];
                    bHudAdjust = true;
                    if (bushJUMP[client] < 5)
                    {
                        SetHudTextParams(-1.0, 0.78, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
                        Format(s, sizeof(s), "%t", "ash_sniper_bushwacka_meter", bushJUMP[client]);
                    }
                    else
                    {
                        SetHudTextParams(-1.0, 0.78, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
                        Format(s, sizeof(s), "%t", "ash_sniper_bushwacka_holdon", bushTIME[client]);
                    }
                    
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, bushwackaHUD, "%s", s);
                    }
                }
                
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 402) {
                    char s[128];
                    SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (bHudAdjust) bHudAdjust2 = true;
                    else bHudAdjust = true;
                    int BeggarBazaarInt = BB_Sniper_Shots[client];
                    Format (s, sizeof(s), "%t", "ash_sniper_bazaar_meter", BeggarBazaarInt);
                    
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, BazaarBargainHUD, "%s", s);
                    }
                    
                    SetEntityRenderMode(client, RENDER_TRANSCOLOR);
                    
                    switch (BeggarBazaarInt)
                    {
                        /* 
                         * 17:06 - CrazyHackGUT: 100% - 255
                         * 17:07 - CrazyHackGUT: 85% - 216
                         * 17:07 - CrazyHackGUT: 70% - 157
                         * 17:07 - CrazyHackGUT: 55% - 140
                         * 17:07 - CrazyHackGUT: 50% - 127
                         * 17:07 - NITROUIH: Максимум, какой результат может выжать эта винтовка - 50%.
                         */
                        
                        case 0:            SetPlayerRenderAlpha(client, 255);
                        case 1:            SetPlayerRenderAlpha(client, 216);
                        case 2:            SetPlayerRenderAlpha(client, 157);
                        case 3:            SetPlayerRenderAlpha(client, 140);
                        case 4, 5:        SetPlayerRenderAlpha(client, 127);
                        default:        GetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), Prop_Send, "m_flChargedDamage");
                    }
                }
                else SetPlayerRenderAlpha(client, 255);
                
                // All shoots
                if (SniperNoMimoShoots[client] == 3) {
                    SniperNoMimoShoots[client] = 0;
                    SniperActivity[client] += 50;
                    if (SniperActivity[client] > 100) SniperActivity[client] = 100;
                }
                
                if (SniperActivity[client] > 100) SniperActivity[client] = 100;
                if (SniperActivity[client] < 0) SniperActivity[client] = 0;

                SetHudTextParams(-1.0, (bHudAdjust?(bHudAdjust2?0.68:0.73):0.78), 0.35, 255, (SniperActivity[client]==100?64:255), (SniperActivity[client]==100?64:255), 255, 0, 0.2, 0.0, 0.1);
                
                char s[256];
                if (SniperActivity[client] != 100) FormatEx(s, sizeof(s), "%t: %i%%", "ash_sniper_ActivityMeter", SniperActivity[client]);
                else Format(s, sizeof(s), "%t", "ash_sniper_ActivityMeter_DONE");
                int WeaponID = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);
                if (!(WeaponID == 56 || WeaponID == 1005 || WeaponID == 1092) && SniperActivity[client] < 100) Format(s, sizeof(s), "%s (%i/3)", s, SniperNoMimoShoots[client]);

                if (!(GetClientButtons(client) & IN_SCORE))
                {
                    ShowSyncHudText(client, soulsHUD, "%s", s);
                }
            }

            if (class == TFClass_Medic)
            {
                int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

                char mediclassname[64];

                if (IsValidEdict(medigun) && GetEdictClassname(medigun, mediclassname, sizeof(mediclassname)) && strcmp(mediclassname, "tf_weapon_medigun", false) == 0)
                {
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);

                    int charge = RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") * 100);

                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, jumpHUD, "%T: %i", "vsh_uber-charge", client, charge);
                    }

                    if (charge == 100 && !(ASHFlags[client] & ASHFLAG_UBERREADY))
                    {
                        FakeClientCommandEx(client, "voicemenu 1 7");
                        ASHFlags[client] |= ASHFLAG_UBERREADY;
                    }
                }

                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 413)
                {
                    SetHudTextParams(-1.0, 0.73, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1); 
                    
                    char sHyppocrate[256];
                    bool isSpecial = false;
                    
                    Format(sHyppocrate, sizeof(sHyppocrate), "%t: %i", "ash_medic_halerage_meter", HaleRage*100/RageDMG);
                    if (Special == ASHSpecial_HHH)
                    {
                        Format(sHyppocrate, sizeof(sHyppocrate), "%s\n%t: %i\\10", sHyppocrate, "ash_medic_halesouls", SpecialHHH_Souls);
                        isSpecial = true;
                    }
                    else if (Special == ASHSpecial_CBS)
                    {
                        int SniperBow = GetPlayerWeaponSlot(Hale, TFWeaponSlot_Primary);
                        if (SniperBow != -1)
                        {
                            // new Arrows = GetEntProp(SniperBow, Prop_Send, "m_iClip1")+GetEntData(Hale, FindSendPropInfo("CTFPlayer", "m_iAmmo")+GetEntProp(SniperBow, Prop_Send, "m_iPrimaryAmmoType", 1)*4, 4);
                            int Arrows = GetAmmoNum(Hale, SniperBow)+GetAmmoClipNum(SniperBow);
                            Format(sHyppocrate, sizeof(sHyppocrate), "%s\n%t: %i", sHyppocrate, "ash_medic_halearrows", Arrows);
                        }
                        else Format(sHyppocrate, sizeof(sHyppocrate), "%s\%t: 0", sHyppocrate, "ash_medic_halearrows");
                        
                        isSpecial = true;
                    }
                    if (isSpecial) SetHudTextParams(-1.0, 0.75, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, infoHUD, "%s", sHyppocrate);
                    if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && Special != ASHSpecial_Agent)
                    {
                        TF2_RemoveCondition(client, TFCond_Dazed);
                        MakeModelTimer(null);
                    }
                }
                if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
                {
                    int healtarget = GetHealingTarget(client);
                    if (IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget) == TFClass_Scout)
                    {
                        TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
                    }
                }
                if (AmpDefend[client]/AmpDEF >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.73, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, infoHUD, "%t", "ash_medic_shield_ready");
                    }
                }
                else if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 304)
                {
                    float amp = 0.001*AmpDEF;
                    SetHudTextParams(-1.0, 0.73, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1); 
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, infoHUD, "%t: %i", "ash_medic_shield_meter", AmpDefend[client]*100/AmpDEF);
                    AmpDefend[client] += RoundToCeil(amp);
                    if (AmpDefend[client] > AmpDEF)
                        AmpDefend[client] = AmpDEF;
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
            }

            if (class == TFClass_Soldier)
            {
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 1104)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);

                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_soldier_airstrike_meter", AirDamage[client]);
                    }
                }
                
				
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 128)
                {
                    float flHaleDamageNeed = (float(HaleHealthMax) / 2.5);
                    if (flHaleDamageNeed >= 2500)
                    {
                      flHaleDamageNeed = 2500.0;
	                }
                    int iHaleDamageNeed = RoundToCeil(flHaleDamageNeed);
					
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.73, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);

                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        ShowSyncHudText(client, soulsHUD, "%t: %i/%i", "ash_soldier_equalizer_meter", Damage[client], iHaleDamageNeed);
                    }
                }
				
                // Soldier and Escape Plan
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 775) {
                    if (SpecialHintsTime[client] > 0.0) {
                        
                        SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
                    
                        if (!(GetClientButtons(client) & IN_SCORE)) {
                            ShowSyncHudText(client, bushwackaHUD, "%t %t", "ash_soldier_EscapePlan_HelpTint", Soldier_EscapePlan_ModeNoHeal[client]?"ash_common_disabled":"ash_common_enabled");
                        }
                        
                        SpecialHintsTime[client] -= 0.2;
                        if (SpecialHintsTime[client] <= 0.0) {
                            SpecialHintsTime[client] = 0.0;
                            SpecialHints[client] = SpecialHint_None;
                        }
                    }
                }
            }

            if (class == TFClass_Scout)
            {
                int bash = GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee);
                if (BasherDamage[client]/BasherDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 64, 64, 255, 0, 0.2, 0.0, 0.1); 
                        ShowSyncHudText(client, infoHUD, "%t", "ash_scout_bostonbasher_rageready");
                        bHudAdjust = true;
                    }
                }
                else if (bash == 325 || bash == 452)
                {
                    SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1); 
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, infoHUD, "%t: %i", "ash_scout_bostonbasher_ragemeter", BasherDamage[client]*100/BasherDMG);
                    if (BasherDamage[client] > BasherDMG)
                        BasherDamage[client] = BasherDMG;
                    if (TF2_IsPlayerInCondition(client, TFCond_TeleportedGlow))
                        BasherDamage[client] = 0;
                    bHudAdjust = true;
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
            }
            if (class == TFClass_Spy)
            {
                int autoaim = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);
                if (headmeter[client] >= 4)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 64, 64, 255, 0, 0.2, 0.0, 0.1); 
                        ShowSyncHudText(client, infoHUD, "%t", "ash_spy_autoaim_ready");
                        bHudAdjust = true;
                    }
                }
                else if (autoaim == 61 || autoaim == 1006)
                {
                    if (headmeter[client] >= 0)
                    {
                        if (!(GetClientButtons(client) & IN_SCORE))
                        {
                            SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
                            ShowSyncHudText(client, infoHUD, "%t", "ash_spy_autoaim_meter", headmeter[client]);
                            bHudAdjust = true;
                        }
                    }
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
            }

            if (class == TFClass_Scout)
            {
                int speedboost = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);
                if (speedboost == 772) {
                    if (SpeedDamage[client]/SpeedDMG >= 1)
                    {
                        if (!(GetClientButtons(client) & IN_SCORE))
                        {
                            SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 64, 64, 255, 0, 0.2, 0.0, 0.1);
                            ShowSyncHudText(client, jumpHUD, "%t", "ash_mc_speedboost_ready");
                        }
                    }
                    else {
                        SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                        if (!(GetClientButtons(client) & IN_SCORE))
                            ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_sh_speedboost", SpeedDamage[client]*100/SpeedDMG);
                        if (SpeedDamage[client] > SpeedDMG)
                            SpeedDamage[client] = SpeedDMG;
                    }
                    if (!bHudAdjust) bHudAdjust = true;
                    else bHudAdjust2 = true;
                } else if (speedboost == 448 && SpeedDamage[client] < 2281337) {
                    if (SpeedDamage[client]/SodaDMG >= 1)
                    {
                        if (!(GetClientButtons(client) & IN_SCORE))
                        {
                            SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 64, 64, 255, 0, 0.2, 0.0, 0.1);
                            ShowSyncHudText(client, jumpHUD, "%t", "ash_scout_soda_ready");
                        }
                    }
                    else {
                        SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                        if (!(GetClientButtons(client) & IN_SCORE))
                            ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_scout_soda_meter", SpeedDamage[client]*100/SodaDMG);
                        if (SpeedDamage[client] > SodaDMG)
                            SpeedDamage[client] = SodaDMG;
                    }
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
            }

            if (class == TFClass_DemoMan)
            {
                int pers = GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee);
                int MOH = GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee);
                if (PersDamage[client]/PersDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, jumpHUD, "%t", "ash_demoman_smallsize_ready");
                    }
                }
                else if (MOH == 327)
                {
                    TF2_RemoveCondition(client, TFCond_Dazed);
                    MakeModelTimer(null);
                }
                else if (pers == 404)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_demoman_smallsize_meter", PersDamage[client]*100/PersDMG);
                    if (PersDamage[client] > PersDMG)
                        PersDamage[client] = PersDMG;
                    if (GetEntPropFloat(client, Prop_Send, "m_flModelScale") < 1.0)
                        PersDamage[client] = 0;
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
                
                // Iron Bomber
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 1151) {
                    // Mode Change
                    if (GetClientButtons(client) & IN_ATTACK3) {
                        if (IronBomberMode[client] < 2) IronBomberMode[client]++;
                        else IronBomberMode[client] = 0;
                        
                        IronBomber_ChangeMode(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), IronBomberMode[client]);
                        EmitSoundToClient(client, "weapons/vaccinator_toggle.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
                    }

                    // HUD
                    SetHudTextParams(-1.0, bHudAdjust?0.73:0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    char IronBomberString[256];
                    switch (IronBomberMode[client]) {
                        case 0:        strcopy(IronBomberString, 256, "ash_demoman_ironbomber_modeselector_spray"); // Спрей
                        case 1:        strcopy(IronBomberString, 256, "ash_demoman_ironbomber_modeselector_charge"); // Заряд
                        case 2:        strcopy(IronBomberString, 256, "ash_demoman_ironbomber_modeselector_round"); // Очередь
                    }
                    ShowSyncHudText(client, bushwackaHUD, "%t: %t", "ash_demoman_ironbomber_modeselector_info", IronBomberString);
                }
            }

            if (class == TFClass_Heavy)
            {
                int curt = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);
                if (NatDamage[client]/NatDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, jumpHUD, "%t", "ash_heavy_evacuate_ready");
                    }
                }
                else if (curt == 41) // || curt == 298)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_heavy_evacuate_meter", NatDamage[client]*100/NatDMG);
                    if (NatDamage[client] > NatDMG)
                        NatDamage[client] = NatDMG;
                }
                if (HuoDamage[client]/HuoDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, jumpHUD, "%t", "ash_heavy_crits_ready");
                    }
                }
                else if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 811)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_heavy_crits_meter", HuoDamage[client]*100/HuoDMG);
                    if (HuoDamage[client] > HuoDMG)
                        HuoDamage[client] = HuoDMG;
                    if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
                    {
                        TF2_RemoveCondition(client, TFCond_Dazed);
                        MakeModelTimer(null);
                    }
                    if (TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture))
                        HuoDamage[client] = 0;
                }
                if (TomDamage[client]/TomDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, jumpHUD, "%t", "ash_mc_speedboost_ready");
                    }
                }
                else if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 424)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_sh_speedboost", TomDamage[client]*100/TomDMG);
                    if (TomDamage[client] > TomDMG)
                        TomDamage[client] = TomDMG;
                }
                if (BetDamage[client]/BetDMG >= 1)
                {
                    if (!(GetClientButtons(client) & IN_SCORE))
                    {
                        SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
                        ShowSyncHudText(client, jumpHUD, "%t", "ash_heavy_vitality_ready");
                    }
                }
                else if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 312)
                {
                    bHudAdjust = true;
                    SetHudTextParams(-1.0, 0.78, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
                    if (!(GetClientButtons(client) & IN_SCORE))
                        ShowSyncHudText(client, jumpHUD, "%t: %i", "ash_heavy_vitality_meter", BetDamage[client]*100/BetDMG);
                    if (BetDamage[client] > BetDMG)
                        BetDamage[client] = BetDMG;
                }
                SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
                if (GlowTimer <= 0.0)
                {
                    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;
                }
                else
                    GlowTimer -= 0.2;
            }

            if (bAlwaysShowHealth)
            {
                SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
                if (!(GetClientButtons(client) & IN_SCORE)) ShowSyncHudText(client, healthHUD, "%t", "vsh_health", HaleHealth, HaleHealthMax);
            }
            
            if (RedAlivePlayers == 1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !dispenserEnabled[client])
            {
                int SpecialIndex = GetActiveWeaponIndex(client);
                if (SpecialIndex != 402 && SpecialIndex != 812 && SpecialIndex != 833 && SpecialIndex != 152 && SpecialIndex != 171) { // "One Player" Bonus
                    TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
                    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                    if (class == TFClass_Engineer && weapon == primary && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false)) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
                    TF2_AddCondition(client, TFCond_Buffed, 0.3);
                    if (validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && index == 312) TF2_RemoveCondition(client, TFCond_HalloweenCritCandy);
                    continue;
                }
            }
            if (RedAlivePlayers == 2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked)) {
                int SpecialIndex = GetActiveWeaponIndex(client);
                if (SpecialIndex != 402 && SpecialIndex != 812 && SpecialIndex != 833 && SpecialIndex != 152 && !dispenserEnabled[client]) // "Two Players" Bonus
                    TF2_AddCondition(client, TFCond_Buffed, 0.3);
            }
            TFCond cond = TFCond_HalloweenCritCandy;
            if (TF2_IsPlayerInCondition(client, TFCond_CritCola) && class == TFClass_Heavy)
            {
                TF2_AddCondition(client, cond, 0.3);
                continue;
            }
            bool addmini = false;
            for (i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsPlayerAlive(i) && GetHealingTarget(i) == client)
                {
                    addmini = true;
                    break;
                }
            }
            bool addthecrit = false;
            if (validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))  //&& index != 4 && index != 194 && index != 225 && index != 356 && index != 461 && index != 574) addthecrit = true; //class != TFClass_Spy
            {
                //slightly longer check but makes sure that any weapon that can backstab will not crit (e.g. Saxxy)
                if (strcmp(wepclassname, "tf_weapon_knife", false) != 0 && index != 416)
                    addthecrit = true;
            }
            switch (index)
            {
                case 305, 1079, 1081, 56, 16, 203,
                     1149, 15001, 15022, 15032, 15037, 15058, // SMG
                     58, 1083, 1105, 1100, 1005, 1092, 997, 39, 351, 740, 588, 595, 442: //Critlist
                {
                    int flindex = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);

                    if (iPlayerClass == TFClass_Pyro && flindex == 594) // No crits if using phlog
                        addthecrit = false;
                    else
                        addthecrit = true;
                }
                case 22, 23, 160, 209, 294, 449, 773,      // Pistol minicrits
                     15013, 15018, 15035, 15041, 15046, 15056, // Gunmettle
                     30666: // INVASION
                {
                    addthecrit = true;
                    if (class == TFClass_Scout && cond == TFCond_HalloweenCritCandy) cond = TFCond_Buffed;
                    if (class == TFClass_Engineer && cond == TFCond_HalloweenCritCandy)
                        addthecrit = false;
                }
                case 656:
                {
                    addthecrit = true;
                    cond = TFCond_Buffed;
                }
            }
            if (index == 16 && addthecrit && IsValidEntity(FindPlayerBack(client, { 642 }, 1)))
            {
                addthecrit = false;
            }
            if (index == 16 && addthecrit && IsValidEntity(FindPlayerBack(client, { 231 }, 1)))
            {
                addthecrit = false;
            }
            if (class == TFClass_DemoMan /*&& !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))*/)
            {
                addthecrit = true;

                if (!bDemoShieldCrits && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
                {
                    cond = TFCond_Buffed;
                }
            }

            if (GetActiveWeaponIndex(client) == 402) addthecrit = false;
            if (iPlayerClass == TFClass_Soldier && IsWeaponSlotActive(client, TFWeaponSlot_Secondary) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) != 442) { addthecrit = false; TF2_AddCondition(client, TFCond_Buffed, 0.3); }
            if (iPlayerClass == TFClass_Heavy && IsWeaponSlotActive(client, TFWeaponSlot_Secondary)) { addthecrit = true; cond = TFCond_HalloweenCritCandy; }
            if (IsWeaponSlotActive(client, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 152) { addthecrit = false; cond = TFCond_BlastJumping; }
            
            if (addthecrit) {
                TF2_AddCondition(client, cond, 0.3);
                if (addmini && cond != TFCond_Buffed) TF2_AddCondition(client, TFCond_Buffed, 0.3);
            }

            if (iPlayerClass == TFClass_Sniper && IsWeaponSlotActive(client, TFWeaponSlot_Secondary) && StrEqual(wepclassname, "tf_weapon_charged_smg")) 
            { 
                if (!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed))
                {
                    TF2_AddCondition(client, TFCond_CritCola, 0.3);
                }
            }
            
            if (class == TFClass_Spy && validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
            {
                if (!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
                {
                    TF2_AddCondition(client, TFCond_CritCola, 0.3);
                }
            }
            if (class == TFClass_Medic && validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && (GetEntProp(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex") != 36))
            {
                if (!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed))
                {
                    TF2_AddCondition(client, TFCond_CritCola, 0.3);
                }
            }
            if (class == TFClass_Engineer && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false))
            {
                int sentry = FindSentry(client);
                if (IsValidEntity(sentry) && GetEntPropEnt(sentry, Prop_Send, "m_hEnemy") == Hale)
                {
                    SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
                    TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
                }
                else
                {
                    if (GetEntProp(client, Prop_Send, "m_iRevengeCrits")) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
                    else if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
                    {
                        TF2_RemoveCondition(client, TFCond_Kritzkrieged);
                    }
                }
            }
            if (class == TFClass_Engineer && IsWeaponSlotActive(client, TFWeaponSlot_Primary) && (StrEqual(wepclassname, "tf_weapon_shotgun") || StrEqual(wepclassname, "tf_weapon_shotgun_primary"))) {
                int iWIndex = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary); 
                if (iWIndex != 1153 && iWIndex != 527) 
                    TF2_AddCondition(client, TFCond_CritCola, 0.3); 
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Buffed) && (iPlayerClass == TFClass_Soldier || iPlayerClass == TFClass_DemoMan) && IsWeaponSlotActive(client, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 152) TF2_RemoveCondition(client, TFCond_Buffed);
            
            if (TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) && (iPlayerClass == TFClass_Soldier || iPlayerClass == TFClass_DemoMan) && IsWeaponSlotActive(client, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 152) TF2_RemoveCondition(client, TFCond_HalloweenCritCandy);
            
            if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 171 && TF2_IsPlayerInCondition(client, view_as<TFCond>(66))) {
                RemoveCond(client, TFCond_Buffed);
                RemoveCond(client, cond);
            }
        }
    }
    
    if (Vitasaw_ExecutionTimes == 25) Vitasaw_ExecutionTimes = 0;
    
    return Plugin_Continue;
}

public Action HaleTimer(Handle hTimer)
{
    if (ASHRoundState == ASHRState_End)
    {
        if (IsValidClient(Hale) && IsPlayerAlive(Hale)) TF2_AddCondition(Hale, TFCond_SpeedBuffAlly, 14.0); // IsValidClient(Hale, false)
        return Plugin_Stop;
    }
    
    iHaleSpecialPower++;
    if (iHaleSpecialPower > 1000)
        iHaleSpecialPower = 1000;
    
    if (Special == ASHSpecial_Agent) {
        if (AgentHelper_IsAllowedEnterToInvis(Hale))
            InsertCond(Hale, view_as<TFCond>(64), TFCondDuration_Infinite);
        else
            RemoveCond(Hale, view_as<TFCond>(64));
    }

    if (Special == ASHSpecial_Agent && AgentHelper_IsAllowedEnterToInvis(Hale) && !g_bGod[Hale]) {
        float AgentPos[3];
        float PlayerPos[3];
        GetClientEyePosition(Hale, AgentPos);
        for (int Player = 1; Player <= MaxClients; Player++) {
            if (!IsValidClient(Player)) continue;
            if (Player == Hale) continue;
            if (IsHologram(Player)) continue;
            if (!IsPlayerAlive(Player)) continue;

            GetClientEyePosition(Player, PlayerPos);

            if (GetVectorDistance(AgentPos, PlayerPos) < 1800.0) {
                if (TF2_IsPlayerInCondition(Hale, view_as<TFCond>(64))) TF2_RemoveCondition(Hale, view_as<TFCond>(64));
                break;
            } else if (!TF2_IsPlayerInCondition(Hale, view_as<TFCond>(64))) TF2_AddCondition(Hale, view_as<TFCond>(64));
        }
    }
    
    if (Special == ASHSpecial_Agent) {
        bool bPlayLaugh = false;
        if (TF2_IsPlayerInCondition(Hale, view_as<TFCond>(64))) {
            InvisibleAgent += 0.2;
            if (InvisibleAgent > 12.0) LastSound += 0.2;
        } else {
            InvisibleAgent = 0.0;
            LastSound = 0.0;
            AgentPreparedSoundLaugh = 0.0;
        }
        
        if (InvisibleAgent > 12.0 && AgentPreparedSoundLaugh == 0.0) {
            bPlayLaugh = true;
        } else if (InvisibleAgent > 12.0 && LastSound >= AgentPreparedSoundLaugh) {
            bPlayLaugh = true;
        }
        
        if (bPlayLaugh) {
            LastSound = 0.0;
            AgentPreparedSoundLaugh = 0.0;
            AgentPreparedSoundLaugh = GetRandomFloat(2.0, 10.0);
            
            char s[PLATFORM_MAX_PATH];
            float vecPos[3];
            strcopy(s, PLATFORM_MAX_PATH, Agent_LaughInvis[GetRandomInt(0,3)]);
            GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", vecPos);
            
            EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
            EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
        }
    }
    
    if (!IsPlayerInAir(Hale)) {
        if (TF2_IsPlayerInCondition(Hale, TFCond_BlastJumping)) TF2_RemoveCondition(Hale, TFCond_BlastJumping);
        for (int client = 1; client <= MaxClients; client++) {
            if (!IsValidClient(client) || client == Hale) continue;
            if (TF2_GetPlayerClass(client) == TFClass_Soldier || TF2_GetPlayerClass(client) == TFClass_DemoMan) SpecialSoldier_Airshot[client] = false;
        }
    }

    if (!IsValidClient(Hale))
        return Plugin_Continue;
        
    // Hale shield
    if (isHaleNeedManyDamage && TF2_IsPlayerInCondition(Hale, TFCond_Milked)) 
        TF2_RemoveCondition(Hale, TFCond_Milked);
    if (isHaleNeedManyDamage && TF2_IsPlayerInCondition(Hale, TFCond_Dazed))
        TF2_RemoveCondition(Hale, TFCond_Dazed);
    
    
    if (TF2_IsPlayerInCondition(Hale, TFCond_Milked) && Special != ASHSpecial_Agent)
        TF2_StunPlayer(Hale, 1.00, 0.08, TF_STUNFLAG_SLOWDOWN);
    if (TF2_IsPlayerInCondition(Hale, TFCond_Bleeding))
        TF2_RemoveCondition(Hale, TFCond_Bleeding);
    /*if (TF2_IsPlayerInCondition(Hale, TFCond_Jarated) && Special != ASHSpecial_Agent)
        TF2_RemoveCondition(Hale, TFCond_Jarated);*/
    if (TF2_IsPlayerInCondition(Hale, TFCond_Disguised) && Special != ASHSpecial_Agent)
        TF2_RemoveCondition(Hale, TFCond_Disguised);
    if (TF2_IsPlayerInCondition(Hale, view_as<TFCond>(15)) && isHaleStunBanned)
        TF2_RemoveCondition(Hale, view_as<TFCond>(15));
    if (TF2_IsPlayerInCondition(Hale, view_as<TFCond>(30)) && isHaleNeedManyDamage)
        TF2_RemoveCondition(Hale, view_as<TFCond>(30));
    float speed = HaleSpeed + 0.7 * (100 - HaleHealth * 100 / HaleHealthMax);
    SetEntPropFloat(Hale, Prop_Send, "m_flMaxspeed", speed*((Special==ASHSpecial_MiniHale)?1.02:1.0));
    if (HaleHealth <= 0 && IsPlayerAlive(Hale)) HaleHealth = 1;
    SetEntityHealth(Hale, HaleHealth);
    SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
    SetGlobalTransTarget(Hale);
    if ((GetClientButtons(Hale) & IN_RELOAD)) DoAction();
    if (!(GetClientButtons(Hale) & IN_SCORE)) ShowSyncHudText(Hale, healthHUD, "%t", "vsh_health", HaleHealth, HaleHealthMax);
    if (HaleRage/RageDMG >= 1)
    {
        if (IsFakeClient(Hale) && !(ASHFlags[Hale] & ASHFLAG_BOTRAGE))
        {
            CreateTimer(1.0, Timer_BotRage, _, TIMER_FLAG_NO_MAPCHANGE);
            ASHFlags[Hale] |= ASHFLAG_BOTRAGE;
        }
        else if (!(GetClientButtons(Hale) & IN_SCORE))
        {
            SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, rageHUD, "%t", (Special!=ASHSpecial_Agent)?"vsh_do_rage":"ash_Agent_Rage");
        }
    }
    else if (!(GetClientButtons(Hale) & IN_SCORE))
    {
        SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, rageHUD, "%t", "vsh_rage_meter", HaleRage*100/RageDMG);
    }
    
    if (Special != ASHSpecial_HHH && iHaleSpecialPower != 1000) {
        SetHudTextParams(-1.0, 0.73, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, soulsHUD, "%t", "ash_special_loading", iHaleSpecialPower/10);
    }
    
    if (Special == ASHSpecial_HHH)
    {
        SetHudTextParams(-1.0, 0.73, 0.35, 255, 255, 255, 255);
        if (SpecialHHH_Souls < 3) ShowSyncHudText(Hale, soulsHUD, "%t", "ash_hhh_souls_meter", SpecialHHH_Souls);
        else
        {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            if (SpecialHHH_Souls == 3) ShowSyncHudText(Hale, soulsHUD, "%t\n%t", "ash_hhh_souls_teleportready", "ash_hhh_souls_meter", SpecialHHH_Souls);
            else if (SpecialHHH_Souls == 4) ShowSyncHudText(Hale, soulsHUD, "%t\n%t", "ash_hhh_souls_meteorready", "ash_hhh_souls_meter", SpecialHHH_Souls);
            else if (SpecialHHH_Souls == 5) ShowSyncHudText(Hale, soulsHUD, "%t\n%t", "ash_hhh_souls_lightningorbready", "ash_hhh_souls_meter", SpecialHHH_Souls);
        }
    } else if (Special == ASHSpecial_Hale || Special == ASHSpecial_MiniHale) {
        if (iHaleSpecialPower == 1000 && (GetClientButtons(Hale) & IN_RELOAD)) {
            ASHStats[SpecialAbilities]++;
            float MVMLevelUP_Pos[3] = {0.0, 0.0, 80.0};
            float MedicResistFire[3] = {0.0, 0.0, 10.0};
            AttachParticle(Hale, "mvm_levelup1", 12.0, MVMLevelUP_Pos, true);
            AttachParticle(Hale, "medic_resist_fire", 12.0, MedicResistFire, true);
            TF2_AddCondition(Hale, view_as<TFCond>(28), 12.0);
            EmitSoundToAll("mvm/mvm_revive.wav", _);
            TF2_AddCondition(Hale, TFCond_DefenseBuffed, 12.0);
            
            TF2Attrib_SetByDefIndex(Hale, 252, 0.0);
            
            isHaleStunBanned = true;
            isHaleNeedManyDamage = true;
            CreateTimer(12.0, DisableDamageInflictor);
            
            iHaleSpecialPower = 0;
        } else if (iHaleSpecialPower == 1000 && !(GetClientButtons(Hale) & IN_SCORE)) {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, soulsHUD, "%t", "ash_hale_shieldHint");
        }
    } else if (Special == ASHSpecial_CBS) {
        if (iHaleSpecialPower == 1000 && (GetClientButtons(Hale) & IN_RELOAD)) {
            ASHStats[SpecialAbilities]++;
            float ParticlePos[3] = {0.0, 0.0, 10.0};
            AttachParticle(Hale, "mvm_soldier_shockwave2d", 10.0, ParticlePos, true);
            AttachParticle(Hale, "medic_resist_blast", 10.0, ParticlePos, true);
            EmitSoundToAll("mvm/mvm_revive.wav", _);
            InfectPlayers[Hale] = true;
            CreateTimer(10.0, DisableInfection, Hale);
            
            iHaleSpecialPower = 0;
        } else if (iHaleSpecialPower == 1000 && !(GetClientButtons(Hale) & IN_SCORE)) {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, soulsHUD, "%t", "ash_cbs_specialPowerHint");
        }
    } else if (Special == ASHSpecial_Bunny) {
        if (iHaleSpecialPower == 1000 && (GetClientButtons(Hale) & IN_RELOAD)) {
            ASHStats[SpecialAbilities]++;
            
            // Delete all bombs from other grenadelauncher
            int iGrenade = -1;
            while ((iGrenade = FindEntityByClassname(iGrenade, "tf_projectile_pipe")) != -1) {
                if (GetEntProp(iGrenade, Prop_Send, "m_iTeamNum") == HaleTeam) {
                    AcceptEntityInput(iGrenade, "Kill");
                }
            }
            
            // Create new weapon
            TF2_RemoveWeaponSlot(Hale, TFWeaponSlot_Primary);
            int weapon = SpawnWeapon(Hale, "tf_weapon_cannon", 996, 100, 5, "280 ; 17.0 ; 466 ; 1.0 ; 467 ; 1.0 ; 103 ; 1.2 ; 477 ; 1.0 ; 293 ; 65.0 ; 99 ; 3.20 ; 77 ; 0.01");
            SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", weapon);
            SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
            SetAmmo(Hale, TFWeaponSlot_Primary, 0);
            SpecialWeapon = weapon;
            
            iHaleSpecialPower = 0;
        } else if (iHaleSpecialPower == 1000 && !(GetClientButtons(Hale) & IN_RELOAD)) {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, soulsHUD, "%t", "ash_EasterBunny_specialHint");
        }
    } else if (Special == ASHSpecial_Vagineer) {
        if (iHaleSpecialPower == 1000 && (GetClientButtons(Hale) & IN_RELOAD)) {
            ASHStats[SpecialAbilities]++;
            
            float MVMLevelUP_Pos[3] = {0.0, 0.0, 80.0};
            float MedicResistFire[3] = {0.0, 0.0, 10.0};
            
            AttachParticle(Hale, "mvm_levelup1", 10.0, MVMLevelUP_Pos, true);
            AttachParticle(Hale, "medic_resist_fire", 10.0, MedicResistFire, true);
            EmitSoundToAll("mvm/mvm_revive.wav", _);
            CreateTimer(0.5, PlaySoundToAll);
            
            //new WeaponCreated = CreateGrapplingHook(Hale);
            int WeaponCreated = SpawnWeapon(Hale, "tf_weapon_grapplinghook", 1152, 100, TFQual_Unusual, "241 ; 0.0 ; 280 ; 26.0 ; 547 ; 0.0 ; 199 ; 0.2 ; 712 ; 1.0");
            EquipPlayerWeapon(Hale, WeaponCreated);
            SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", WeaponCreated);
            
            Handle hndlTrie = CreateTrie();
            SetTrieValue(hndlTrie, "time", 20);
            SetTrieValue(hndlTrie, "hook", WeaponCreated);
            
            CreateTimer(1.0, RemoveHook, hndlTrie);
            VagineerTime_GH = 20;
            
            iHaleSpecialPower = 0;
        } else if (iHaleSpecialPower == 1000 && !(GetClientButtons(Hale) & IN_RELOAD)) {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, soulsHUD, "%t", "ash_Vagineer_specialHint");
        }
    } else if (Special == ASHSpecial_Agent) {
      AbilityAgent_RunLogic();
      /*
        if (iHaleSpecialPower == 1000 && (GetClientButtons(Hale) & IN_RELOAD)) {
            ASHStats[SpecialAbilities]++;

            g_iAgentSpecialMode = 1;

            TF2_StunPlayer(Hale, 7.0, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT, 0);
            TF2Attrib_SetByDefIndex(Hale, 252, 0.0);

            TimeAbility = 7.0;
            TF2_RemoveCondition(Hale, view_as<TFCond>(64));
            CreateTimer(0.7, SpecialAbility_Agent, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            CreateTimer(0.5, SpecialAbility_Agent_Sound, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            
            iHaleSpecialPower = 0;
        } else if (iHaleSpecialPower == 1000 && !(GetClientButtons(Hale) & IN_RELOAD)) {
            SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
            ShowSyncHudText(Hale, soulsHUD, "%t", "ash_Agent_SpecialAbility");
        }
      */
        
    }
    
    // Grappling Hook Interface
    if (!(GetClientButtons(Hale) & IN_SCORE) && VagineerTime_GH)
    {
        SetGlobalTransTarget(Hale);
        SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, BazaarBargainHUD, "%t", "ash_Vagineer_hook_action", VagineerTime_GH);
    }
    
    if (InfectPlayers[Hale]) {
        float pos[3];
        float pos2[3];
        float distance;

        GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && (i != Hale) && !ImmunityClient[i])
            {
                GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
                distance = GetVectorDistance(pos, pos2);
                if (!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && distance < ASH_INFECTIONRADIUS_HALE && !InfectPlayers[i])
                {
                    InfectPlayers[i] = true;
                    CreateTimer(20.0, DisableInfection, i);
                    CreateTimer(1.0, InfectiionDamage, i, TIMER_REPEAT);
                }
            }
        }
    }
    
    SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
    if (GlowTimer <= 0.0)
    {
        SetEntProp(Hale, Prop_Send, "m_bGlowEnabled", 0);
        GlowTimer = 0.0;
    }
    else
        GlowTimer -= 0.2;
    if (bEnableSuperDuperJump)
    {
        /*if (HaleCharge <= 0)
        {
            HaleCharge = 0;
            if (!(GetClientButtons(Hale) & IN_SCORE)) ShowSyncHudText(Hale, jumpHUD, "%t", "vsh_super_duper_jump");
        }*/
        SetHudTextParams(-1.0, 0.88, 0.35, 255, 64, 64, 255);
    }

    int buttons = GetClientButtons(Hale);
    if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && HaleCharge >= 0) // && !(buttons & IN_JUMP)
    {
        if (Special == ASHSpecial_HHH)
        {
            if (HaleCharge + 10 < HALEHHH_TELEPORTCHARGE)
                HaleCharge += 10;
            else
                HaleCharge = HALEHHH_TELEPORTCHARGE;
            if (!(GetClientButtons(Hale) & IN_SCORE))
            {
                if (bEnableSuperDuperJump)
                {
                    ShowSyncHudText(Hale, jumpHUD, "%t", "vsh_super_duper_jump");
                }
                else
                {
                    ShowSyncHudText(Hale, jumpHUD, "%t", "vsh_teleport_status", HaleCharge * 2);
                }
            }
        }
        else
        {
            if (HaleCharge + 5 < HALE_JUMPCHARGE)
                HaleCharge += 5;
            else
                HaleCharge = HALE_JUMPCHARGE;
            if (!(GetClientButtons(Hale) & IN_SCORE))
            {
                if (bEnableSuperDuperJump)
                {
                    ShowSyncHudText(Hale, jumpHUD, "%t", "vsh_super_duper_jump");
                }
                else
                {
                    ShowSyncHudText(Hale, jumpHUD, "%t", "vsh_jump_status", HaleCharge * 4);
                }
            }
        }
    }
    else if (HaleCharge < 0)
    {
        HaleCharge += 5;
        if (Special == ASHSpecial_HHH)
        {
            if (!(GetClientButtons(Hale) & IN_SCORE)) ShowSyncHudText(Hale, jumpHUD, "%t %i", "vsh_teleport_status_2", -HaleCharge/20);
        }
        else if (!(GetClientButtons(Hale) & IN_SCORE)) ShowSyncHudText(Hale, jumpHUD, "%t %i", "vsh_jump_status_2", -HaleCharge/20);
    }
    else
    {
        float ang[3];
        GetClientEyeAngles(Hale, ang);
        if ((ang[0] < -45.0) && (HaleCharge > 1))
        {
            // Agent
            if (Special == ASHSpecial_Agent)
                AgentHelper_ChangeTimeBeforeInvis(2.0, Hale);
            
            Action act = Plugin_Continue;
            bool super = bEnableSuperDuperJump;
            Call_StartForward(OnHaleJump);
            Call_PushCellRef(super);
            Call_Finish(act);
            if (act != Plugin_Continue && act != Plugin_Changed)
                return Plugin_Continue;
            if (act == Plugin_Changed) bEnableSuperDuperJump = super;
            float pos[3];
            if (Special == ASHSpecial_HHH && (HaleCharge == HALEHHH_TELEPORTCHARGE || bEnableSuperDuperJump))
            {
                int target = -1;

                do
                {
                    target = GetRandomInt(1, MaxClients);
                }
                while ((RedAlivePlayers > 0) && (!IsClientInGame(target) || (target == Hale) || !IsPlayerAlive(target) || GetEntityTeamNum(target) != OtherTeam)); // IsValidClient(target, false)
                
                if (IsValidClient(target)) // Maybe it can fail it we teleport to nobody?
                {
                    // Chdata's HHH teleport rework
                    if (TF2_GetPlayerClass(target) != TFClass_Scout && TF2_GetPlayerClass(target) != TFClass_Soldier)
                    {
                        SetEntProp(Hale, Prop_Send, "m_CollisionGroup", 2); //Makes HHH clipping go away for player and some projectiles
                        CreateTimer(bEnableSuperDuperJump ? 4.0:2.0, HHHTeleTimer, _, TIMER_FLAG_NO_MAPCHANGE);
                    }

                    SetEntPropFloat(Hale, Prop_Send, "m_flNextAttack", GetGameTime() + (bEnableSuperDuperJump ? 4.0 : 2.0));
                    SetEntProp(Hale, Prop_Send, "m_bGlowEnabled", 0);
                    GlowTimer = 0.0;

                    AttachParticle(Hale, "ghost_appearation", 3.0);             // One is parented and one is not

                    if (TeleMeToYou(Hale, target)) // This returns true if teleport to a ducking player happened
                    {
                        ASHFlags[Hale] |= ASHFLAG_NEEDSTODUCK;

                        Handle timerpack;
                        CreateDataTimer(0.2, Timer_StunHHH, timerpack, TIMER_FLAG_NO_MAPCHANGE);
                        WritePackCell(timerpack, bEnableSuperDuperJump);
                        WritePackCell(timerpack, GetClientUserId(target));
                    }
                    else
                    {
                        TF2_StunPlayer(Hale, (bEnableSuperDuperJump ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
                    }

                    AttachParticle(Hale, "ghost_appearation", 3.0, _, true);    // So the teleport smoke appears at both destinations
                    
                    // Chdata's HHH teleport rework
                    float vPos[3];
                    GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);

                    EmitSoundToClient(Hale, "misc/halloween/spell_teleport.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vPos, NULL_VECTOR, false, 0.0);
                    EmitSoundToClient(target, "misc/halloween/spell_teleport.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vPos, NULL_VECTOR, false, 0.0);

                    PriorityCenterText(target, true, "You've been teleported to!");

                    HaleCharge = -910;
                }
                if (bEnableSuperDuperJump)
                    bEnableSuperDuperJump = false;
            }
            else if (Special != ASHSpecial_HHH)
            {
                float vel[3];
                GetEntPropVector(Hale, Prop_Data, "m_vecVelocity", vel);
                if (bEnableSuperDuperJump)
                {
                    vel[2]=750 + HaleCharge * 13.0 + 2000;
                    bEnableSuperDuperJump = false;
                }
                else
                    vel[2]=750 + HaleCharge * 13.0;
                SetEntProp(Hale, Prop_Send, "m_bJumping", 1);
                vel[0] *= (1+Sine(float(HaleCharge) * FLOAT_PI / 50));
                vel[1] *= (1+Sine(float(HaleCharge) * FLOAT_PI / 50));
                TeleportEntity(Hale, NULL_VECTOR, NULL_VECTOR, vel);
                TF2_AddCondition(Hale, TFCond_BlastJumping);
                HaleCharge=-120;
                char s[PLATFORM_MAX_PATH];
                switch (Special)
                {
                    case ASHSpecial_Agent:
                        strcopy(s, PLATFORM_MAX_PATH, Agent_Jump[GetRandomInt(0,3)]);
                    case ASHSpecial_Vagineer:
                        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));
                    case ASHSpecial_CBS:
                        strcopy(s, PLATFORM_MAX_PATH, CBSJump1);
#if defined EASTER_BUNNY_ON
                    case ASHSpecial_Bunny:
                        strcopy(s, PLATFORM_MAX_PATH, BunnyJump[GetRandomInt(0, sizeof(BunnyJump)-1)]);
#endif
                    case ASHSpecial_Hale, ASHSpecial_MiniHale:
                    {
                        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", GetRandomInt(0, 1) ? HaleJump : HaleJump132, GetRandomInt(1, 2));
                    }
                }
                if (s[0] != '\0')
                {
                    GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
                    
                    if (Special != ASHSpecial_Agent) {
                        EmitSoundToAll(s, Hale, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, true, 0.0);
                        EmitSoundToAll(s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, true, 0.0);
                    }
                    
                    if (Special == ASHSpecial_Agent) {
                        EmitAmbientSound(s, pos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
                        EmitAmbientSound(s, pos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
                    }
                    
                    for (int i = 1; i <= MaxClients; i++)
                        if (IsClientInGame(i) && (i != Hale))
                        {
                            EmitSoundToClient(i, s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, true, 0.0);
                            EmitSoundToClient(i, s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, true, 0.0);
                        }
                }
            }
        }
        else
            HaleCharge = 0;
    }
    
    if (RedAlivePlayers == 1)
    {
        switch (Special)
        {
            case ASHSpecial_Bunny:
                PriorityCenterTextAll(_, "%t", "vsh_bunny_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_Vagineer:
                PriorityCenterTextAll(_, "%t", "vsh_vagineer_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_HHH:
                PriorityCenterTextAll(_, "%t", "vsh_hhh_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_CBS:
                PriorityCenterTextAll(_, "%t", "vsh_cbs_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_Agent:
                PriorityCenterTextAll(_, "%t", "ash_agent_hp", HaleHealth, HaleHealthMax);
            default:
                PriorityCenterTextAll(_, "%t", "vsh_hale_hp", HaleHealth, HaleHealthMax);
        }
    }
    if (OnlyScoutsLeft())
    {
        float rage = 0.001*RageDMG;
        HaleRage += RoundToCeil(rage);
        if (HaleRage > RageDMG)
            HaleRage = RageDMG;
    }

    if (!(GetEntityFlags(Hale) & FL_ONGROUND))
    {
        WeighDownTimer += 0.2;
    }
    else
    {
        HHHClimbCount = 0;
        WeighDownTimer = 0.0;
    }

    if (WeighDownTimer >= 4.0 && buttons & IN_DUCK && GetEntityGravity(Hale) != 6.0)
    {
        float ang[3];
        GetClientEyeAngles(Hale, ang);
        if ((ang[0] > 60.0))
        {
            Action act = Plugin_Continue;
            Call_StartForward(OnHaleWeighdown);
            Call_Finish(act);
            if (act != Plugin_Continue)
                return Plugin_Continue;
            float fVelocity[3];
            GetEntPropVector(Hale, Prop_Data, "m_vecVelocity", fVelocity);
            fVelocity[2] = -1000.0;
            TeleportEntity(Hale, NULL_VECTOR, NULL_VECTOR, fVelocity);
            SetEntityGravity(Hale, 6.0);
            CreateTimer(2.0, Timer_GravityCat, GetClientUserId(Hale), TIMER_FLAG_NO_MAPCHANGE);
            CPrintToChat(Hale, "{ash}[ASH]{default} %t", "vsh_used_weighdown");
            
            WeighDownTimer = 0.0;
        }
    }
    return Plugin_Continue;
}