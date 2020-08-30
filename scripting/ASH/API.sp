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

    /* Admin functions */
    CreateNative("ASH_SetNextPlayer",           Native_SetNextPlayer);
    CreateNative("ASH_SetNextBoss",             Native_SetNextBoss);
    CreateNative("ASH_SetQueuePoints",          Native_SetQueuePoints);
    CreateNative("ASH_GetQueuePoints",          Native_GetQueuePoints);
    CreateNative("ASH_SetClientDamage",         Native_SetDamage);
    CreateNative("ASH_SetSaxtonHaleHealth",     Native_SetSaxtonHaleHealth);
    CreateNative("ASH_SetSaxtonHaleHealthMax",  Native_SetSaxtonHaleHealthMax);
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
}

/* Admin natives */
public int Native_SetNextPlayer(Handle hPlugin, int iNumParams) {
    ForceHale(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), false);
}

public int Native_SetNextBoss(Handle hPlugin, int iNumParams) {
    Incoming = GetNativeCell(1);
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
}

public int Native_GetQueuePoints(Handle hPlugin, int iNumParams) {
    return GetClientQueuePoints(GetNativeCell(1));
}

public int Native_SetDamage(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return;
    Damage[client] = GetNativeCell(2);
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
}

public int Native_SetSaxtonHaleHealthMax(Handle hPlugin, int iNumParams) {
    HaleHealthMax = GetNativeCell(1);
    // TODO: rework this for correct working on max health fix.
}
