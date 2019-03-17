static bool   g_bWaitUnpress;
static int    g_iCurrentAbilityMode;
static int    g_iCurrentPlayer;
Handle hBombTimer = null;

#define AGENT_WAIT          0
#define AGENT_BOMBWAIT		1
#define AGENT_SELECTING     2
#define AGENT_SAPPED        3

public Action AbilityAgent_ResetAction(Handle hTimer) {
    if (g_iCurrentAbilityMode == AGENT_SELECTING) {
    g_iCurrentAbilityMode = AGENT_WAIT;
    g_bWaitUnpress = true;
    iHaleSpecialPower = 0;
    g_iCurrentPlayer = 0;
    ASHStats[SpecialAbilities]++;
    return;
    }
}

void AbilityAgent_Reset() {
    g_iCurrentAbilityMode = AGENT_WAIT;
    g_bWaitUnpress = true;
    iHaleSpecialPower = 0;
    g_iCurrentPlayer = 0;
    return;
}

void AbilityAgent_RunLogic() {
    if (iHaleSpecialPower < 1000)
        return;
    if (g_bWaitUnpress && (GetClientButtons(Hale) & IN_RELOAD))
        return;

    g_bWaitUnpress = false;
    switch (g_iCurrentAbilityMode) {
        case AGENT_WAIT:          AbilityAgent_DoWait();
		case AGENT_BOMBWAIT:	  AbilityAgent_DoBombWait();
        case AGENT_SELECTING:     AbilityAgent_DoSelect();
        case AGENT_SAPPED:        AbilityAgent_DoSap();
    }
}

void AbilityAgent_DoWait() {
    if (GetClientButtons(Hale) & IN_RELOAD) {
        g_iCurrentAbilityMode = AGENT_BOMBWAIT;
        g_bWaitUnpress = true;
        
        float MVMLevelUP_Pos[3] = {0.0, 0.0, 80.0};
        float MedicResistFire[3] = {0.0, 0.0, 10.0};

        AttachParticle(Hale, "mvm_levelup1", 15.0, MVMLevelUP_Pos, true);
        AttachParticle(Hale, "medic_resist_fire", 15.0, MedicResistFire, true);
        EmitSoundToAll("mvm/mvm_revive.wav", _);

        return;
    }

    SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
    ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bombready");
}

public Action ChangeAbilityMode(Handle hTimer)
{
    g_iCurrentAbilityMode = AGENT_SELECTING;
    hBombTimer = null;
}

void AbilityAgent_DoBombWait() {
    if (!hBombTimer)
        hBombTimer = CreateTimer(3.0, ChangeAbilityMode);
    SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
    ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bombwait");
}

void AbilityAgent_DoSelect() {
    float flDistance;
    int iClient = UTIL_FindNearestPlayer(Hale, flDistance);

    CreateTimer(12.0, AbilityAgent_ResetAction);
    if (!iClient) {
        SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bombplayers", flDistance);
        return;
    }

    flDistance /= 50;
    if (flDistance > 3250.0) {
        SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bomblocate", flDistance);
        return;
    }

    if (TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged)) {
        SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bombubercharge");
        return;
    }
    
    if (g_iFidovskiyFix[iClient] == 1) {
        SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255);
        ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_bombimmune");
        return;
    }
    
    if (!TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) && g_iFidovskiyFix[iClient] == 0) {
        g_iCurrentAbilityMode = AGENT_SAPPED;
        g_iCurrentPlayer = iClient;
        CreateTimer(1.0, AbilityAgent_PlaySound, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        ASHStats[SpecialAbilities]++;
    }
}

void AbilityAgent_DoSap() {
    if (TF2_IsPlayerInCondition(g_iCurrentPlayer, TFCond_Ubercharged)) AbilityAgent_Reset();
    
    if (!IsClientInGame(g_iCurrentPlayer) || !IsPlayerAlive(g_iCurrentPlayer) || GetClientTeam(g_iCurrentPlayer) != OtherTeam) {
        AgentAbility_Explode();
        CPrintToChat(Hale, "{ash}[ASH] {default}%t", "ash_agent_bombfailed");

        g_iCurrentPlayer = 0;
        g_iCurrentAbilityMode = AGENT_WAIT;
        iHaleSpecialPower = 0;
        return;
    }

    if (GetClientButtons(Hale) & IN_RELOAD) {
        AgentAbility_Explode();

        g_iCurrentAbilityMode = AGENT_WAIT;
        g_bWaitUnpress = true;
        iHaleSpecialPower = 0;
        g_iCurrentPlayer = 0;
        return;
    }
    
    float PlayerSapped[3] = {0.0, 0.0, 92.0};
    AttachParticle(g_iCurrentPlayer, "powerup_icon_supernova", 1.0, PlayerSapped, true);

    SetHudTextParams(-1.0, 0.68, 0.35, 255, 64, 64, 255);
    SetGlobalTransTarget(Hale);
    ShowSyncHudText(Hale, soulsHUD, "%t", "ash_agent_deploybomb");

    // SetHudTextParams(-1.0, 0.40, 0.35, 255, 64, 64, 255);
    // ShowSyncHudText(g_iCurrentPlayer, soulsHUD, "%02d:%02d", GetRandomInt(0, 60), GetRandomInt(0, 60));

    SetHudTextParams(-1.0, 0.35, 0.35, 255, 64, 64, 255);
    SetGlobalTransTarget(g_iCurrentPlayer);
    ShowSyncHudText(g_iCurrentPlayer, soulsHUD, "%t\n%02d:%02d", "ash_agent_yousapped", GetRandomInt(0, 60), GetRandomInt(0, 60));
}

void AgentAbility_Explode() {
    float vecBombPosition[3];
    float vecReceiverPosition[3];
    int iMaxHealth = UTIL_GetMaxHealthByClass(TF2_GetPlayerClass(g_iCurrentPlayer));
    GetEntPropVector(g_iCurrentPlayer, Prop_Send, "m_vecOrigin", vecBombPosition);

    FakeClientCommand(g_iCurrentPlayer, "explode");

    int iDistance;
    float flDamage;

    float BigBoom[3] = {0.0, 0.0, 0.0};
    AttachParticle(g_iCurrentPlayer, "hightower_explosion", 1.0, BigBoom, true);
    EmitSoundToAll("misc/rd_robot_explosion01.wav", _);

    for (int iClient = MaxClients; iClient != 0; --iClient) {
        if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != OtherTeam)
            continue;

        GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vecReceiverPosition);
        iDistance = RoundToCeil(((GetVectorDistance(vecBombPosition, vecReceiverPosition, true) / 50) * 0.1905) / 80);
        if (iDistance > 5)
            continue;

        flDamage = ((iMaxHealth * 2.0) / iDistance);
        SDKHooks_TakeDamage(iClient, 0, 0, flDamage);
    }
}

public Action AbilityAgent_PlaySound(Handle hTimer) {
  if (g_iCurrentAbilityMode != AGENT_SAPPED || !IsClientInGame(g_iCurrentPlayer) || !IsPlayerAlive(g_iCurrentPlayer) || GetClientTeam(g_iCurrentPlayer) != OtherTeam)
    return Plugin_Stop;

  EmitSoundToClient(g_iCurrentPlayer, "ui/message_update.wav", _, _, _, _, 0.7, 100, _, _, _, false);
  return Plugin_Continue;
}