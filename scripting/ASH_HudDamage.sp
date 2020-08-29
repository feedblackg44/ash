#include <advancedsaxtonhale>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

Handle  g_hHUD; /**< HUD Sync */

public void OnMapStart() {
    CreateTimer(0.2, OnNeedRenderAnotherClientDamage, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    LoadTranslations("ASH_HudDamage.phrases");
}

public void OnPluginStart() {
    g_hHUD = CreateHudSynchronizer();
}

public Action OnNeedRenderAnotherClientDamage(Handle hTimer) {
    if (ASH_GetRoundState() != ASHRState_Active)
        return;

    int iHale = GetClientOfUserId(ASH_GetSaxtonHaleUserId());
    int iTracedEntity;
    for (int i = 1; i <= MaxClients; ++i) {
        if (!IsClientInGame(i) || IsFakeClient(i) || iHale == i || GetClientTeam(i) < 2 || !IsPlayerAlive(i)) {
            continue;
        }

        iTracedEntity = UTIL_TraceClientViewEntity(i);
        if (iTracedEntity < 1 || iHale == iTracedEntity) {
            ClearSyncHud(i, g_hHUD);
            continue;
        }

        SetHudTextParams(-1.0, 0.35, 0.2, 255, 255, 255, 255);
        ShowSyncHudText(i, g_hHUD, "%t", "ASH_TRACE_DMG", iTracedEntity, ASH_GetClientDamage(iTracedEntity));
    }
}

/**
 * @section Trace Helper
 */
stock int UTIL_TraceClientViewEntity(int iClient) {
    float   m_vecOrigin[3];
    float   m_angRotation[3];
    Handle  hTrace;
    int pEntity = -1;

    GetClientEyePosition(iClient, m_vecOrigin);
    GetClientEyeAngles(iClient, m_angRotation);
    hTrace = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, iClient); 

    if (hTrace && TR_DidHit(hTrace)) {
        pEntity = TR_GetEntityIndex(hTrace);
    }

    if (hTrace) {
        CloseHandle(hTrace);
    }

    return pEntity;
} 

public bool TRDontHitSelf(int iEntity, int iMask, any iData) {
    return (0 < iEntity <= MaxClients && iEntity != iData);
}