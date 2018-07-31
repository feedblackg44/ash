void API_Init() {
    API_MakeForwards();
    API_MakeNatives();

    RegPluginLibrary("advancedsaxtonhale");
}

void API_MakeForwards() {
    OnHaleJump      = CreateGlobalForward("ASH_OnDoJump", ET_Hook, Param_CellByRef);
    OnHaleRage      = CreateGlobalForward("ASH_OnDoRage", ET_Hook, Param_FloatByRef);
    OnHaleWeighdown = CreateGlobalForward("ASH_OnDoWeighdown", ET_Hook);
    OnMusic         = CreateGlobalForward("ASH_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
    OnHaleNext      = CreateGlobalForward("ASH_OnHaleNext", ET_Hook, Param_Cell);
}

void API_MakeNatives() {
    /* Generic */
    CreateNative("ASH_IsSaxtonHaleModeMap",     Native_IsASHMap);
    CreateNative("ASH_IsSaxtonHaleModeEnabled", Native_IsEnabled);
    CreateNative("ASH_GetSaxtonHaleUserId",     Native_GetHale);
    CreateNative("ASH_GetSaxtonHaleTeam",       Native_GetTeam);
    CreateNative("ASH_GetSpecialRoundIndex",    Native_GetSpecial);
    CreateNative("ASH_GetSaxtonHaleHealth",     Native_GetHealth);
    CreateNative("ASH_GetSaxtonHaleHealthMax",  Native_GetHealthMax);
    CreateNative("ASH_GetRoundState",           Native_GetRoundState);
    CreateNative("ASH_GetRoundNum",             Native_GetRoundNum);
    CreateNative("ASH_PrintToChat",             Native_PrintToChat);
    
    /* Admin functions */
    CreateNative("ASH_SetNextPlayer",           Native_SetNextPlayer);
    CreateNative("ASH_SetNextBoss",             Native_SetNextBoss);
    CreateNative("ASH_SetQueuePoints",          Native_SetQueuePoints);
    CreateNative("ASH_GetQueuePoints",          Native_GetQueuePoints);
    CreateNative("ASH_SetClientDamage",         Native_SetDamage);
    CreateNative("ASH_GetClientDamage",         Native_GetDamage);
    CreateNative("ASH_SetSaxtonHaleHealth",     Native_SetSaxtonHaleHealth);
    CreateNative("ASH_SetSaxtonHaleHealthMax",  Native_SetSaxtonHaleHealthMax);
}

public int Native_IsASHMap(Handle plugin, int numParams) {
    return IsSaxtonHaleMap();
}

public int Native_IsEnabled(Handle plugin, int numParams) {
    return g_bEnabled;
}

public int Native_GetHale(Handle plugin, int numParams) {
    if (IsValidClient(Hale))
        return GetClientUserId(Hale);
    return -1;
}

public int Native_GetTeam(Handle plugin, int numParams) {
    return HaleTeam;
}

public int Native_GetSpecial(Handle plugin, int numParams) {
    return Special;
}

public int Native_GetHealth(Handle plugin, int numParams) {
    return HaleHealth;
}

public int Native_GetHealthMax(Handle plugin, int numParams) {
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

public int Native_GetDamage(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client))
        return 0;
    return Damage[client];
}

public int Native_SetSaxtonHaleHealth(Handle hPlugin, int iNumParams) {
    HaleHealth = GetNativeCell(1);
}

public int Native_SetSaxtonHaleHealthMax(Handle hPlugin, int iNumParams) {
    HaleHealthMax = GetNativeCell(1);
}
