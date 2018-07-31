Handle  g_hLookupBone;
Handle  g_hGetBonePosition;

int     g_iPlayerDesiredFOV[MAXPLAYERS+2];
int     g_iActiveWeapon[MAXPLAYERS+2];
float   g_FOISpeed[MAXPLAYERS+2];
bool    g_bAimActive[MAXPLAYERS+2];
bool    g_bToHead[MAXPLAYERS+2];

stock void AIM_Unhook(int iClient) {
    SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
    SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

stock void AIM_UpdateFOV(int iClient) {
    g_iPlayerDesiredFOV[iClient] = 90;
    
    if (!IsFakeClient(iClient))
        QueryClientConVar(iClient, "fov_desired", OnClientGetDesiredFOV);
}

public void OnClientGetDesiredFOV(QueryCookie cookie, int iClient, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (!IsValidClient(iClient)) return;
    
    g_iPlayerDesiredFOV[iClient] = StringToInt(cvarValue);
}

/**
 * @section UTILs
 */
void UTIL_PrepareCalls() {
    Handle hGameConf;

    if (!(hGameConf = LoadGameConfigFile("aimbot.games")))
    {
        SetFailState("Could not locate gamedata file aimbot.games.txt, pausing plugin");
    }

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::LookupBone");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    if (!(g_hLookupBone=EndPrepSDKCall()))
    {
        SetFailState("Could not initialize SDK call CBaseAnimating::LookupBone");
    }

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseAnimating::GetBonePosition");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
    if(!(g_hGetBonePosition=EndPrepSDKCall()))
    {
        SetFailState("Could not initialize SDK call CBaseAnimating::GetBonePosition");
    }

    CloseHandle(hGameConf);
}

void UTIL_SwitchAIM(int iClient, bool bNewState) {
    if (bNewState) {
        SDKHook(iClient, SDKHook_PreThink,              OnPreThink);
        SDKHook(iClient, SDKHook_WeaponSwitchPost,      OnWeaponSwitch);
        AIM_Ambassador_attr_changer(GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary), 1);
        g_bAimActive[iClient] = true;
    } else {
        SDKUnhook(iClient, SDKHook_PreThink,            OnPreThink);
        SDKUnhook(iClient, SDKHook_WeaponSwitchPost,    OnWeaponSwitch);
        AIM_Ambassador_attr_changer(GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary), 0);
        g_bAimActive[iClient] = false;
    }
}

bool UTIL_IsAIMEnabled(int iClient) {
    return g_bAimActive[iClient];
}

void UTIL_UpdateFirstOrderIntercept(int iClient) {
    switch(g_iActiveWeapon[iClient])
    {
        case 812,833,44,648,595: g_FOISpeed[iClient] = 3000.0;
        case 49,351,740,1081: g_FOISpeed[iClient] = 2000.0;
        case 442,588: g_FOISpeed[iClient] = 1200.0;
        case 997,305,1079: g_FOISpeed[iClient] = 2400.0;
        case 414: g_FOISpeed[iClient] = 1540.0;
        case 127: g_FOISpeed[iClient] = 1980.0;
        case 222,1121,58,1083,1105: g_FOISpeed[iClient] = 925.0;
        case 996: g_FOISpeed[iClient] = 1811.0;
        case 56,1005,1092: g_FOISpeed[iClient] = 1800.0;
        case 308: g_FOISpeed[iClient] = 1510.0;
        case 19,206,1007,1151: g_FOISpeed[iClient] = 1215.0;
        case 18,205,228,441,513,658,730,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057: g_FOISpeed[iClient] = 1100.0;
        case 17,204,36,412,20,207,130,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15045,15048: g_FOISpeed[iClient] = 1000.0;
        default: g_FOISpeed[iClient] = 1000000.0;        // Arbitrary value for hitscan
    }
}

bool UTIL_ShouldAimToHead(TFClassType iClass, const char[] szStrWeapon, int iWeapon)
{
    // These checks are probably mostly redundant, but just want to be sure I make certain classes aim at certain points of the body to be effective
        
    /**
    if(StrEqual(strWeapon, "tf_weapon_crossbow", false)
    || StrEqual(strWeapon, "tf_weapon_syringegun_medic", false)
    || StrEqual(strWeapon, "tf_weapon_flaregun", false))
        return true;
    */

    switch(iWeapon)            // Any revolver other than Ambassador
    {
        case 24,161,210,224,460,535,1142,15011,15027,15042,15051:
            return false;
    }
    
    if (iClass == TFClass_Sniper || (iClass == TFClass_Spy && !StrEqual(szStrWeapon, "tf_weapon_knife", false)))
        return true;
        
    return false;
}

// Props to Friagram
//first-order intercept using absolute target position (http://wiki.unity3d.com/index.php/Calculating_Lead_For_Projectiles)
void UTIL_FirstOrderIntercept(float shooterPosition[3], float shooterVelocity[3], float shotSpeed, float targetPosition[3], float targetVelocity[3], int iTarget) {
    float originalPosition[3];
    UTIL_CopyVector(targetPosition, originalPosition);
    
    float targetRelativePosition[3];
    SubtractVectors(targetPosition, shooterPosition, targetRelativePosition);
    float targetRelativeVelocity[3];
    SubtractVectors(targetVelocity, shooterVelocity, targetRelativeVelocity);
    float t = UTIL_FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity);

    ScaleVector(targetRelativeVelocity, t);
    AddVectors(targetPosition, targetRelativeVelocity, targetPosition);
    
    // Check if we are going to shoot a wall or the floor
    TR_TraceRayFilter(shooterPosition, targetPosition, MASK_SOLID, RayType_EndPoint, TRAIM_TraceRayFilterClients, iTarget);
    if(TR_DidHit())
    {
        float vEndPos[3];
        float fDist1 = GetVectorDistance(shooterPosition, vEndPos);
        float fDist2 = GetVectorDistance(shooterPosition, targetPosition);
        if(fDist1 < fDist2 || TR_GetFraction() != 1.0)
            UTIL_CopyVector(originalPosition, targetPosition);
    }
}

stock float UTIL_FirstOrderInterceptTime(float shotSpeed, float targetRelativePosition[3], float targetRelativeVelocity[3])
{
    float velocitySquared = GetVectorLength(targetRelativeVelocity, true);
    if(velocitySquared < 0.001)
    {
        return 0.0;
    }

    float a = velocitySquared - shotSpeed*shotSpeed;
    if (FloatAbs(a) < 0.001)  //handle similar velocities
    {
        float t = -GetVectorLength(targetRelativePosition, true)/(2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition));

        return t > 0.0 ? t : 0.0; //don't shoot back in time
    }

    float b = 2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition);
    float c = GetVectorLength(targetRelativePosition, true);
    float determinant = b*b - 4.0*a*c;

    if (determinant > 0.0)    //determinant > 0; two intercept paths (most common)
    { 
        float t1 = (-b + SquareRoot(determinant))/(2.0*a);
        float t2 = (-b - SquareRoot(determinant))/(2.0*a);
        if (t1 > 0.0)
        {
            if (t2 > 0.0) 
            {
                return t2 < t2 ? t1 : t2; //both are positive
            }
            else
            {
                return t1; //only t1 is positive
            }
        }
        else
        {
            return t2 > 0.0 ? t2 : 0.0; //don't shoot back in time
        }
    }
    else if (determinant < 0.0) //determinant < 0; no intercept path
    {
        return 0.0;
    }
    else //determinant = 0; one intercept path, pretty much never happen
    {
        determinant = -b/(2.0*a);        // temp
        return determinant > 0.0 ? determinant : 0.0; //don't shoot back in time
    }
}

stock float UTIL_InterpolateVector(int iClient, float vVelocity[3], float vVector[3])
{
    if(IsFakeClient(iClient))
        return;
    
    float flLatency = GetClientLatency(iClient, NetFlow_Both);
    for(int x = 0; x < 3; x++)
        vVector[x] -= (vVelocity[x] * flLatency);
}

stock float UTIL_MAX(float a, float b) {
    return (a < b) ? a : b;
}

stock float UTIL_MIN(float a, float b) {
    return (a > b) ? a : b;
}

stock void UTIL_CopyVector(float vIn[3], float vOut[3])
{
    vOut[0] = vIn[0];
    vOut[1] = vIn[1];
    vOut[2] = vIn[2];
}

stock void UTIL_AnglesNormalize(float vAngles[3])
{
    while(vAngles[0] >  89.0) vAngles[0]-=360.0;
    while(vAngles[0] < -89.0) vAngles[0]+=360.0;
    while(vAngles[1] > 180.0) vAngles[1]-=360.0;
    while(vAngles[1] <-180.0) vAngles[1]+=360.0;
}

stock void UTIL_AngleNormalize(float &flAngle)
{
    if(flAngle > 180.0) flAngle-=360.0;
    if(flAngle <-180.0) flAngle+=360.0;
}

stock float UTIL_ChangeAngle(int iClient, float flIdeal, float flCurrent)
{
    static float flAimMoment[MAXPLAYERS+1], flAlphaSpeed, flAlpha;
    float flDiff, flDelta;
    
    flAlphaSpeed = 8.0 / 20.0;
    flAlpha = flAlphaSpeed * 0.21;
    
    flDiff = flIdeal - flCurrent;
    UTIL_AngleNormalize(flDiff);
    
    flDelta = (flDiff * flAlpha) + (flAimMoment[iClient] * flAlphaSpeed);
    if(flDelta < 0.0)
        flDelta *= -1.0;
    
    flAimMoment[iClient] = (flAimMoment[iClient] * flAlphaSpeed) + (flDelta * (1.0 - flAlphaSpeed));
    if(flAimMoment[iClient] < 0.0)
        flAimMoment[iClient] *= -1.0;
    
    return flCurrent + flDelta;
}

stock float UTIL_GetVectorAnglesTwoPoints(const float vStartPos[3], const float vEndPos[3], float vAngles[3])
{
    static float tmpVec[3];
    tmpVec[0] = vEndPos[0] - vStartPos[0];
    tmpVec[1] = vEndPos[1] - vStartPos[1];
    tmpVec[2] = vEndPos[2] - vStartPos[2];
    GetVectorAngles(tmpVec, vAngles);
}

stock int GetClosestClient(int iClient)
{
    float vPos1[3], vPos2[3];
    GetClientEyePosition(iClient, vPos1);

    int iTeam = GetClientTeam(iClient);
    int iClosestEntity = -1;
    float flClosestDistance = -1.0;
    float flEntityDistance;

    for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i))
    {
        if(GetClientTeam(i) != iTeam && IsPlayerAlive(i) && i != iClient)
        {
            GetClientEyePosition(i, vPos2);
            flEntityDistance = GetVectorDistance(vPos1, vPos2);
            if((flEntityDistance < flClosestDistance) || flClosestDistance == -1.0)
            {
                if(CanSeeTarget(iClient, i, iTeam, false))
                {
                    flClosestDistance = flEntityDistance;
                    iClosestEntity = i;
                }
            }
        }
    }
    return iClosestEntity;
}

bool CanSeeTarget(int iClient, int iTarget, int iTeam, bool bCheckFOV)
{
    float flStart[3], flEnd[3];
    GetClientEyePosition(iClient, flStart);
    GetClientEyePosition(iTarget, flEnd);
    
    TR_TraceRayFilter(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TRAIM_TraceRayFilterClients, iTarget);
    if(TR_GetEntityIndex() == iTarget)
    {
        if(TF2_GetPlayerClass(iTarget) == TFClass_Spy)
        {
            if(TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked) || TF2_IsPlayerInCondition(iTarget, TFCond_Disguised))
            {
                if(TF2_IsPlayerInCondition(iTarget, TFCond_CloakFlicker)
                || TF2_IsPlayerInCondition(iTarget, TFCond_OnFire)
                || TF2_IsPlayerInCondition(iTarget, TFCond_Jarated)
                || TF2_IsPlayerInCondition(iTarget, TFCond_Milked)
                || TF2_IsPlayerInCondition(iTarget, TFCond_Bleeding))
                {
                    return true;
                }

                return false;
            }
            if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && GetEntProp(iTarget, Prop_Send, "m_nDisguiseTeam") == iTeam)
            {
                return false;
            }

            return true;
        }
        
        if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged)
        || TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden)
        || TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen)
        || TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage)
        || TF2_IsPlayerInCondition(iTarget, TFCond_PreventDeath)
        || TF2_IsPlayerInCondition(iTarget, TFCond_Bonked))
        {
            return false;
        }
        
        if(bCheckFOV)
        {
            float eyeAng[3], reqVisibleAng[3];
            float flFOV = float(g_iPlayerDesiredFOV[iClient]);
            
            GetClientEyeAngles(iClient, eyeAng);
            
            SubtractVectors(flEnd, flStart, reqVisibleAng);
            GetVectorAngles(reqVisibleAng, reqVisibleAng);
            
            float flDiff = FloatAbs(reqVisibleAng[0] - eyeAng[0]) + FloatAbs(reqVisibleAng[1] - eyeAng[1]);
            if (flDiff > ((flFOV * 0.5) + 10.0)) 
                return false;
        }

        return true;
    }

    return false;
}

stock float GetGrenadeZ(const float vOrigin[3], const float vTarget[3], float flSpeed)
{
    float flDist = GetVectorDistance(vOrigin, vTarget);
    float flTime = flDist / (flSpeed * 0.707);
    
    return UTIL_MIN(0.0, ((Pow(2.0, flTime) - 1.0) * (800.0 * 0.1)));
}

/**
 * @section Hooks
 */
public void OnPreThink(int iClient) {   // Predict speed changes based on charge
    if(g_iActiveWeapon[iClient] == 56 || g_iActiveWeapon[iClient] == 1005 || g_iActiveWeapon[iClient] == 1092)
    {
        float flCharge = GetEntPropFloat(GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"), Prop_Data, "m_fFireDuration");
        g_FOISpeed[iClient] = 1800.0 + UTIL_MAX(flCharge, 1.0) * 8.0;
    }
}

public void OnWeaponSwitch(int iClient, int iWeapon)
{
    if(!IsValidEdict(iWeapon))
        return;
    
    g_iActiveWeapon[iClient] = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
    UTIL_UpdateFirstOrderIntercept(iClient);
}

/**
 * @section AIM Tick
 */
public void AimTick(int iClient, int &iButtons, float vAngle[3], float vVelocity[3]) {
    if (!g_bAimActive[iClient])
        return;

    static float flNextTargetTime[MAXPLAYERS+1];
    static int iTarget[MAXPLAYERS+1];
    static int iBone[MAXPLAYERS+1];

    float vClientEyes[3], vCamAngle[3], vTargetEyes[3], vTargetVel[3];

    GetClientEyePosition(iClient, vClientEyes);

    int iTeam = GetClientTeam(iClient);

    // Thanks Mitchell for this awesome code
    if(flNextTargetTime[iClient] <= GetEngineTime()) {
        iTarget[iClient] = GetClosestClient(iClient);
        flNextTargetTime[iClient] = GetEngineTime() + 5.0;
    }

    if(!IsValidClient(iTarget[iClient]) || !IsPlayerAlive(iTarget[iClient])) {
        iTarget[iClient] = GetClosestClient(iClient);
        flNextTargetTime[iClient] = GetEngineTime() + 5.0;
        return;
    } else {
        GetClientEyePosition(iTarget[iClient], vTargetEyes);
        if(!CanSeeTarget(iClient, iTarget[iClient], iTeam, false)) {
            iTarget[iClient] = GetClosestClient(iClient);
            flNextTargetTime[iClient] = GetEngineTime() + 5.0;
            return;
        }
    }

    //GetClientEyePosition(iTarget[iClient], vTargetEyes);
    //vTargetEyes[0] += 1.5;
    GetEntPropVector(iTarget[iClient], Prop_Data, "m_vecAbsVelocity", vTargetVel);

    float vBoneAngle[3];
    iBone[iTarget[iClient]] = SDKCall(g_hLookupBone, iTarget[iClient], (g_bToHead[iClient]) ? "bip_spine_2" : "bip_spine_2");
    SDKCall(g_hGetBonePosition, iTarget[iClient], iBone[iTarget[iClient]], vTargetEyes, vBoneAngle);

    UTIL_FirstOrderIntercept(vClientEyes, view_as<float>({0.0, 0.0, 0.0}), g_FOISpeed[iClient], vTargetEyes, vTargetVel, iTarget[iClient]);
    UTIL_InterpolateVector(iClient, vTargetVel, vTargetEyes);
    
    switch(g_iActiveWeapon[iClient])
    {    // Calculate the dropoff
        case 39, 56, 351, 595, 740, 1005, 1081, 1092, 19, 206, 308, 
        996, 1007, 1151, 15077, 15079, 15091, 15092, 15116, 15117, 15142, 15158:
        {
            if(GetVectorDistance(vClientEyes, vTargetEyes) > 512.0)
                vTargetEyes[2] += GetGrenadeZ(vClientEyes, vTargetEyes, g_FOISpeed[iClient]);
        }
    }
    
    UTIL_GetVectorAnglesTwoPoints(vClientEyes, vTargetEyes, vCamAngle);
    UTIL_AnglesNormalize(vCamAngle);

    /**
    if(g_bSmoothAim[iClient])
    {
        vCamAngle[0] = UTIL_ChangeAngle(iClient, vCamAngle[0], vAngle[0]);
        vCamAngle[1] = UTIL_ChangeAngle(iClient, vCamAngle[1], vAngle[1]);
        UTIL_AnglesNormalize(vCamAngle);
    }
    */
    
    TeleportEntity(iClient, NULL_VECTOR, vCamAngle, NULL_VECTOR);
    UTIL_CopyVector(vCamAngle, vAngle);
}

/**
 * @section TraceRay
 */
public bool TRAIM_TraceRayFilterClients(int iEntity, int iMask, any hData) {
    if (iEntity > 0 && iEntity <=MaxClients) {
        return (iEntity == hData);
    }

    return true;
}