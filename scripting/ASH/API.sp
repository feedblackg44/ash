void API_Init() {
    API_MakeForwards();
    API_MakeNatives();

    RegPluginLibrary("advancedsaxtonhale");

#if defined __ASH_API_COMPABILITY
    RegPluginLibrary("saxtonhale");
#endif

}

void API_MakeForwards() {
    OnHaleJump      = CreateGlobalForward("ASH_OnDoJump", ET_Hook, Param_CellByRef);
    OnHaleRage      = CreateGlobalForward("ASH_OnDoRage", ET_Hook, Param_FloatByRef);
    OnHaleWeighdown = CreateGlobalForward("ASH_OnDoWeighdown", ET_Hook);
    OnMusic         = CreateGlobalForward("ASH_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
    OnHaleNext      = CreateGlobalForward("ASH_OnHaleNext", ET_Hook, Param_Cell);

    // int iClient
    g_hForwards[ASHEvent_OnPlayerThink] = CreateForward(ET_Ignore, Param_Cell);
    g_hForwards[ASHEvent_OnPlayerTaunt] = CreateForward(ET_Hook, Param_Cell);
}

void API_MakeGeneralNatives(const char[] szPrefix)
{
    char szNativeName[32];
#define __temp_declare_native(%0)   FormatEx(szNativeName, sizeof(szNativeName), "%s_%s", szPrefix, #%0); CreateNative(szNativeName, Native_%0)

    /** Generic */
    __temp_declare_native(IsSaxtonHaleModeMap);
    __temp_declare_native(IsSaxtonHaleModeEnabled);
    __temp_declare_native(GetSaxtonHaleUserId);
    __temp_declare_native(GetSaxtonHaleTeam);
    __temp_declare_native(GetSpecialRoundIndex);
    __temp_declare_native(GetSaxtonHaleHealth);
    __temp_declare_native(GetSaxtonHaleHealthMax);
    __temp_declare_native(GetRoundState);
    __temp_declare_native(GetRoundNum);

    /** Admin functions */
    __temp_declare_native(GetClientDamage);

#undef __temp_declare_native
}

void API_MakeNatives() {
    API_MakeGeneralNatives("ASH");

#if defined __ASH_API_COMPABILITY
    API_MakeGeneralNatives("VSH");
#endif

    /* Generic */
    CreateNative("ASH_PrintToChat",             Native_PrintToChat);
    CreateNative("ASH_TeleportToMultiMapSpawn", Native_TeleportToMultiMapSpawn);
    CreateNative("ASH_SetHUDParams",            Native_SetHUDParams);
    CreateNative("ASH_DrawHUD",                 Native_DrawHUD);
    CreateNative("ASH_AttachParticle",          Native_AttachParticle);

    /* Admin functions */
    CreateNative("ASH_SetNextPlayer",           Native_SetNextPlayer);
    CreateNative("ASH_SetNextBoss",             Native_SetNextBoss);
    CreateNative("ASH_SetQueuePoints",          Native_SetQueuePoints);
    CreateNative("ASH_GetQueuePoints",          Native_GetQueuePoints);
    CreateNative("ASH_SetClientDamage",         Native_SetDamage);
    CreateNative("ASH_SetSaxtonHaleHealth",     Native_SetSaxtonHaleHealth);
    CreateNative("ASH_SetSaxtonHaleHealthMax",  Native_SetSaxtonHaleHealthMax);

    /* Hooks */
    CreateNative("ASH_Hook", Native_Hook);
    CreateNative("ASH_Unhook", Native_Unhook);
}

public int Native_IsSaxtonHaleModeMap(Handle plugin, int numParams) {
    return IsSaxtonHaleMap();
}

public int Native_IsSaxtonHaleModeEnabled(Handle plugin, int numParams) {
    return g_bEnabled;
}

public int Native_GetSaxtonHaleUserId(Handle plugin, int numParams) {
    if (IsValidClient(Hale))
        return GetClientUserId(Hale);
    return -1;
}

public int Native_GetSaxtonHaleTeam(Handle plugin, int numParams) {
    return HaleTeam;
}

public int Native_GetSpecialRoundIndex(Handle plugin, int numParams) {
    return Special;
}

public int Native_GetSaxtonHaleHealth(Handle plugin, int numParams) {
    return HaleHealth;
}

public int Native_GetSaxtonHaleHealthMax(Handle plugin, int numParams) {
    return HaleHealthMax;
}

public int Native_GetRoundState(Handle plugin, int numParams) {
    return ASHRoundState;
}

public int Native_GetRoundNum(Handle plugin, int numParams) {
    return RoundCount; 
}

public int Native_PrintToChat(Handle hPlugin, int iNumParams) {
    char szMsg[255];
    
    int iClient = GetNativeCell(1);
    GetNativeString(2, szMsg, sizeof(szMsg));
    if (iClient)
        CPrintToChat(iClient, "{ash}[ASH] {default}%s", szMsg);
    else
        CPrintToChatAll("{ash}[ASH] {default}%s", szMsg);

    return 0;
}

public int Native_TeleportToMultiMapSpawn(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    if (!IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index");
    }

    int iTeam = GetNativeCell(2);
    TeleportToMultiMapSpawn(iClient, iTeam);
    return 0;
}

public int Native_SetHUDParams(Handle hPlugin, int iNumParams)
{
    int iColor[4];
    GetNativeArray(1, iColor, sizeof(iColor));

    int iEffect = GetNativeCell(2);
    float flFxTime = GetNativeCell(3);
    float flFadeIn = GetNativeCell(4);
    float flFadeOut = GetNativeCell(5);
    float flHoldTime = GetNativeCell(6);

    _Internal_SetHUDParams(iColor, iEffect, flFxTime, flFadeIn, flFadeOut, flHoldTime);
    return 0;
}

public int Native_DrawHUD(Handle hPlugin, int iNumParams)
{
    int iClient = GetNativeCell(1);
    if (!IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index");
    }

    SetGlobalTransTarget(iClient);

    ASHPosition ePosition = GetNativeCell(2);
    if (ePosition >= _ASHPosition_End)
    {
        return ThrowNativeError(SP_ERROR_INDEX, "Invalid position");
    }

    char szMessage[256];
    int iBytesWritten = 0;
    int iFormatErrorCode = FormatNativeString(0, 3, 4, sizeof(szMessage), iBytesWritten, szMessage);
    if (iFormatErrorCode != SP_ERROR_NONE)
    {
        return iFormatErrorCode;
    }

    _Internal_DrawHUD(iClient, ePosition, "%s", szMessage);
    return 0;
}

public int Native_AttachParticle(Handle hPlugin, int iNumParams)
{
    int iEntity = GetNativeCell(1);
    if (!IsValidEntity(iEntity))
    {
        return ThrowNativeError(SP_ERROR_INDEX, "Invalid entity index");
    }

    char szParticleName[64];
    GetNativeString(2, szParticleName, sizeof(szParticleName));
    float flTimeToDie = GetNativeCell(3);
    bool bAttach = GetNativeCell(5);
    float flTimeToStart = GetNativeCell(6);

    float vecOffsets[3];
    GetNativeArray(4, vecOffsets, sizeof(vecOffsets));

    return AttachParticle(iEntity, szParticleName, flTimeToDie, vecOffsets, bAttach, flTimeToStart);
}

/* Admin natives */
public int Native_SetNextPlayer(Handle hPlugin, int iNumParams) {
    ForceHale(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), false);

    return 0;
}

public int Native_SetNextBoss(Handle hPlugin, int iNumParams) {
    Incoming = GetNativeCell(1);

    return 0;
}

public int Native_SetQueuePoints(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    int iPoints = GetNativeCell(2);
    if (iClient <= 0) {
        char szAuthId[32];
        GetNativeString(3, szAuthId, sizeof(szAuthId));
        SetAuthIdQueuePoints(szAuthId, iPoints);
    } else {
        SetClientQueuePoints(iClient, iPoints);
    }

    return 0;
}

public int Native_GetQueuePoints(Handle hPlugin, int iNumParams) {
    return GetClientQueuePoints(GetNativeCell(1));
}

public int Native_SetDamage(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return 0;
    Damage[client] = GetNativeCell(2);

    return 0;
}

public int Native_GetClientDamage(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client))
        return 0;
    return Damage[client];
}

public int Native_SetSaxtonHaleHealth(Handle hPlugin, int iNumParams) {
    HaleHealth = GetNativeCell(1);
    // TODO: rework this for correct working on max health fix.

    return 0;
}

public int Native_SetSaxtonHaleHealthMax(Handle hPlugin, int iNumParams) {
    HaleHealthMax = GetNativeCell(1);
    // TODO: rework this for correct working on max health fix.

    return 0;
}

public int Native_Hook(Handle hPlugin, int iNumParams)
{
    ASHEvent eEvent = GetNativeCell(1);
    if (eEvent >= _ASHEvent_End) return ThrowNativeError(SP_ERROR_NOT_FOUND, "Required hook not found or not supported in this plugin version");

    g_hForwards[eEvent].AddFunction(hPlugin, GetNativeFunction(2));
    return 0;
}

public int Native_Unhook(Handle hPlugin, int iNumParams)
{
    ASHEvent eEvent = GetNativeCell(1);
    if (eEvent >= _ASHEvent_End) return ThrowNativeError(SP_ERROR_NOT_FOUND, "Required hook not found or not supported in this plugin version");

    g_hForwards[eEvent].RemoveFunction(hPlugin, GetNativeFunction(2));
    return 0;
}