bool g_bHooked[MAXPLAYERS + 1];
static Handle g_ptrGetMaxHealth;

void UTIL_MakeCommands() {
    // CHEATS
    RegConsoleCmd("say", OnSay);
    RegConsoleCmd("say_team", OnSay);
    // CHEATS

//    RegAdminCmd("sm_hale_reboot", Debug_ReloadASH, ADMFLAG_ROOT, "Reloads the ASH plugin safely and silently.");
    RegConsoleCmd("sm_hale", HalePanel);
    RegConsoleCmd("sm_hale_hp", Command_GetHPCmd);
    RegConsoleCmd("sm_halehp", Command_GetHPCmd);
    RegConsoleCmd("sm_hale_next", QueuePanelCmd);
    RegConsoleCmd("sm_halenext", QueuePanelCmd);
    RegConsoleCmd("sm_hale_help", HelpPanelCmd);
    RegConsoleCmd("sm_halehelp", HelpPanelCmd);
    RegConsoleCmd("sm_hale_class", HelpPanel2Cmd);
    RegConsoleCmd("sm_haleclass", HelpPanel2Cmd);
    RegConsoleCmd("sm_hale_classinfotoggle", ClasshelpinfoCmd);
    RegConsoleCmd("sm_haleclassinfotoggle", ClasshelpinfoCmd);
    RegConsoleCmd("sm_infotoggle", ClasshelpinfoCmd);
    RegConsoleCmd("sm_hale_new", NewPanelCmd);
    RegConsoleCmd("sm_halenew", NewPanelCmd);
    
    RegConsoleCmd("sm_halemusic", MusicTogglePanelCmd);
    RegConsoleCmd("sm_hale_music", MusicTogglePanelCmd);
    RegConsoleCmd("sm_halevoice", VoiceTogglePanelCmd);
    RegConsoleCmd("sm_hale_voice", VoiceTogglePanelCmd);
    RegAdminCmd("sm_hale_resetqueuepoints", ResetQueuePointsCmd, 0);
    RegAdminCmd("sm_hale_resetq", ResetQueuePointsCmd, 0);
    RegAdminCmd("sm_halereset", ResetQueuePointsCmd, 0);
    RegAdminCmd("sm_resetq", ResetQueuePointsCmd, 0);
    RegAdminCmd("sm_hale_special", Command_MakeNextSpecial, 0, "Call a special to next round.");
    AddCommandListener(DoTaunt, "taunt");
    AddCommandListener(DoTaunt, "+taunt");
    AddCommandListener(cdVoiceMenu, "voicemenu");
    AddCommandListener(DoSuicide, "explode");
    AddCommandListener(DoSuicide, "kill");
    AddCommandListener(DoSuicide2, "jointeam");
    //AddCommandListener(Destroy, "destroy");
    AddCommandListener(OnEurekaUse, "eureka_teleport");
    RegAdminCmd("sm_hale_select", Command_HaleSelect, ADMFLAG_CHEATS, "hale_select <target> - Select a player to be next boss");
    RegAdminCmd("sm_hale_setdmg", Command_HaleSetDamage, ADMFLAG_CHEATS, "hale_setdmg <target> <damage> - Set a player damage");
    RegAdminCmd("sm_hale_addpoints", Command_Points, ADMFLAG_CHEATS, "hale_addpoints <target> <points> - Add queue points to user.");
    RegAdminCmd("sm_hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with hale_point_type = 0");
    RegAdminCmd("sm_hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with hale_point_type = 0");
    RegAdminCmd("sm_hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music.");
    
    //RegAdminCmd("sm_alpha", Experiment, ADMFLAG_CHEATS, "Expriment");
    //RegAdminCmd("sm_alpha_ex", Experiment_Alpha, ADMFLAG_CHEATS, "Expriment");
}

void UTIL_MakeHooks() {
    HookEvent("teamplay_round_start", event_round_start);
    HookEvent("teamplay_round_win", event_round_end);
    HookEvent("player_changeclass", event_changeclass);
    HookEvent("player_spawn", event_player_spawn);
    HookEvent("player_death", event_player_death, EventHookMode_Pre);
    HookEvent("player_chargedeployed", event_uberdeployed);
    HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
    HookEvent("object_destroyed", event_destroy, EventHookMode_Pre);
    HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
    HookEvent("rps_taunt_event", event_rps);
    HookEvent("player_sapped_object", event_sapped);

    HookUserMessage(GetUserMessageId("PlayerJarated"), event_jarate);

    AddNormalSoundHook(HookSound);
}

void UTIL_MakeConVars() {
    cvarVersion = CreateConVar("hale_version", ASH_PLUGIN_VERSION, "VS Saxton Hale Version", FCVAR_VERSION);
    cvarBuild = CreateConVar("hale_build", ASH_BUILD, "Advanced Saxton Hale Build", FCVAR_VERSION);
    cvarHaleSpeed = CreateConVar("hale_speed", "352.0", "Speed of Saxton Hale", FCVAR_NOTIFY);
    cvarPointType = CreateConVar("hale_point_type", "0", "Select condition to enable point (0 - alive players, 1 - time)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarPointDelay = CreateConVar("hale_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_NOTIFY);
    cvarAliveToEnable = CreateConVar("hale_point_alive", "0", "Enable control points when there are X people left alive.", FCVAR_NOTIFY);
    cvarRageDMG = CreateConVar("hale_rage_damage", "2650", "Damage required for Hale to gain rage", FCVAR_NOTIFY, true, 0.0);
    cvarRageDist    = CreateConVar("hale_rage_dist", "625.0", "Distance to stun in Hale's rage. Vagineer and CBS are /3 (/2 for sentries)", FCVAR_NOTIFY, true, 0.0);
    cvarAnnounce = CreateConVar("hale_announce", "300.0", "Info about mode will show every X seconds. Must be greater than 1.0 to show.", FCVAR_NOTIFY, true, 0.0);
    cvarSpecials = CreateConVar("hale_specials", "1", "Enable Special Rounds (Vagineer, HHH, CBS)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnabled = CreateConVar("hale_enabled", "1", "Do you really want set it to 0?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarCrits = CreateConVar("hale_crits", "0", "Can Hale get crits?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    //cvarDemoShieldCrits = CreateConVar("hale_shield_crits", "0", "Does Demoman's shield grant crits (1) or minicrits (0)?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarDisplayHaleHP = CreateConVar("hale_hp_display", "1", "Display Hale Health at all times.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarRageSentry = CreateConVar("hale_ragesentrydamagemode", "1", "If 0, to repair a sentry that has been damaged by rage, the Engineer must pick it up and put it back down.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarFirstRound = CreateConVar("hale_first_round", "0", "Disable(0) or Enable(1) ASH in 1st round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    //cvarEnableEurekaEffect = CreateConVar("hale_enable_eureka", "1", "1- allow Eureka Effect, else disallow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarForceHaleTeam = CreateConVar("hale_force_team", "0", "0- Use plugin logic, 1- random team, 2- red, 3- blue", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    
    cvarEnableJumper = CreateConVar("hale_enable_jumper", "1", "Enable rocket jumper and sticky jumper", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    //cvarEnableCloak = CreateConVar("hale_enable_cloak", "0", "Enable Cloak and Dagger", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableSapper = CreateConVar("hale_enable_sapper", "1", "Enable passive attributes of spy's sappers", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    /*cvarEnableCBS = CreateConVar("hale_boss_cbs", "1", "Enable Christian Brutal Sniper", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableHHH = CreateConVar("hale_boss_hhh", "1", "Enable Horseless Headless Horsemann", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableBunny = CreateConVar("hale_boss_bunny", "1", "Enable Easter Bunny", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableVagineer = CreateConVar("hale_boss_vagineer", "1", "Enable Vagineer", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableAgent = CreateConVar("hale_boss_agent", "1", "Enable Agent", FCVAR_NOTIFY, true, 0.0, true, 1.0);*/
    
    cvarEnableSecret1 = CreateConVar("hale_boss_secret_1", "1", "Enable First Secret Boss", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarEnableSecretCheats = CreateConVar("hale_enable_secret_cheats", "1", "Enable secret cheats", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    cvarTryhardDirecthit = CreateConVar("hale_tryhard_directhit", "0", "Enable Direct Hit stun", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarTryhardMachina = CreateConVar("hale_tryhard_machina", "1", "Enable Machina stun", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    /*cvarTryhardLochnload = CreateConVar("hale_tryhard_lochnload", "1", "Enable Loch-n-Load stun", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    cvarSpecial = CreateConVar("hale_spec", "1", "Allow weapons' special abilities", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialRestrict = CreateConVar("hale_spec_restrict", "1", "Replace disallowed weapons with the stock one (1) or leave it without its abilities (0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBoston = CreateConVar("hale_spec_boston", "1", "Allow special ability of Boston Basher", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialSoda = CreateConVar("hale_spec_soda", "1", "Allow special ability of Soda Popper", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBabyFace = CreateConVar("hale_spec_babyface", "1", "Allow special ability of Baby Face's Blaster", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialManmelter = CreateConVar("hale_spec_manmelter", "1", "Allow special ability of Manmelter", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialNatascha = CreateConVar("hale_spec_natascha", "1", "Allow special ability of Natascha", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialTomislav = CreateConVar("hale_spec_tomislav", "1", "Allow special ability of Tomislav", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialHuo = CreateConVar("hale_spec_huo", "1", "Allow special ability of Huo-Long Heater", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBrassBeast = CreateConVar("hale_spec_brassbeast", "1", "Allow special ability of Brass Beast", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBuffalo = CreateConVar("hale_spec_buffalo", "1", "Allow special ability of Buffalo Steak Sandvich", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialPistol = CreateConVar("hale_spec_pistol", "1", "Allow special ability of Pistol", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialVita = CreateConVar("hale_spec_vita", "1", "Allow special ability of Vita-saw", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialAmputator = CreateConVar("hale_spec_amputator", "1", "Allow special ability of Amputator", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialVow = CreateConVar("hale_spec_vow", "1", "Allow special ability of Solemn Vow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialSniperShield = CreateConVar("hale_spec_snipershield", "1", "Allow sniper special ability (shield)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBazaar = CreateConVar("hale_spec_bazaar", "1", "Allow special ability of Bazaar Bargain", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialShiv = CreateConVar("hale_spec_shiv", "1", "Allow special ability of Tribalman's Shiv", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    cvarSpecialBoss = CreateConVar("hale_special_boss", "1", "Allow bosses' special abilities", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialSaxton = CreateConVar("hale_special_saxton", "1", "Allow Saxton Hale's special ability (Shield)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialCBS = CreateConVar("hale_special_cbs", "1", "Allow Christian Brutal Sniper's special ability (Infection)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialHHH = CreateConVar("hale_special_hhh", "1", "Allow Horseless Headless Horsemann's spells", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialVagineer = CreateConVar("hale_special_vagineer", "1", "Allow Vagineer's special ability (Hook)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialBunny = CreateConVar("hale_special_bunny", "1", "Allow Easter Bunny's special ability (Flash Grenade)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvarSpecialAgent = CreateConVar("hale_special_agent", "1", "Allow Agent's special ability (Bomb)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    */
    cvarHaleMinPlayersResetQ = CreateConVar("hale_min_players_resetq", "6", "Minimum number of players to use a command /resetq", FCVAR_NOTIFY, true, 0.0);
    
    HookConVarChange(FindConVar("tf_bot_count"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_arena_use_queue"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_arena_first_blood"), HideCvarNotify);
    HookConVarChange(FindConVar("mp_friendlyfire"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_dropped_weapon_lifetime"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_feign_death_activate_damage_scale"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_feign_death_damage_scale"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_feign_death_duration"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_feign_death_speed_duration"), HideCvarNotify);
    HookConVarChange(FindConVar("tf_stealth_damage_reduction"), HideCvarNotify);

    HookConVarChange(cvarEnabled, CvarChange);
    HookConVarChange(cvarHaleSpeed, CvarChange);
    HookConVarChange(cvarRageDMG, CvarChange);
    HookConVarChange(cvarRageDist, CvarChange);
    HookConVarChange(cvarAnnounce, CvarChange);
    HookConVarChange(cvarSpecials, CvarChange);
    HookConVarChange(cvarPointType, CvarChange);
    HookConVarChange(cvarPointDelay, CvarChange);
    HookConVarChange(cvarAliveToEnable, CvarChange);
    HookConVarChange(cvarCrits, CvarChange);
    //HookConVarChange(cvarDemoShieldCrits, CvarChange);
    HookConVarChange(cvarDisplayHaleHP, CvarChange);
    HookConVarChange(cvarRageSentry, CvarChange);
    //HookConVarChange(cvarCircuitStun, CvarChange);
    
    HookConVarChange(cvarEnableJumper, CvarChange);
    HookConVarChange(cvarEnableSapper, CvarChange);
    HookConVarChange(cvarEnableSecret1, CvarChange);
    HookConVarChange(cvarEnableSecretCheats, CvarChange);
    HookConVarChange(cvarTryhardDirecthit, CvarChange);
    HookConVarChange(cvarTryhardMachina, CvarChange);
    
    /*HookConVarChange(cvarEnableCloak, CvarChange);
    HookConVarChange(cvarEnableCBS, CvarChange);
    HookConVarChange(cvarEnableHHH, CvarChange);
    HookConVarChange(cvarEnableBunny, CvarChange);
    HookConVarChange(cvarEnableVagineer, CvarChange);
    HookConVarChange(cvarEnableAgent, CvarChange);
    HookConVarChange(cvarTryhardLochnload, CvarChange);
    HookConVarChange(cvarSpecial, CvarChange);
    HookConVarChange(cvarSpecialRestrict, CvarChange);
    HookConVarChange(cvarSpecialBoston, CvarChange);
    HookConVarChange(cvarSpecialSoda, CvarChange);
    HookConVarChange(cvarSpecialBabyFace, CvarChange);
    HookConVarChange(cvarSpecialManmelter, CvarChange);
    HookConVarChange(cvarSpecialNatascha, CvarChange);
    HookConVarChange(cvarSpecialTomislav, CvarChange);
    HookConVarChange(cvarSpecialHuo, CvarChange);
    HookConVarChange(cvarSpecialBrassBeast, CvarChange);
    HookConVarChange(cvarSpecialBuffalo, CvarChange);
    HookConVarChange(cvarSpecialPistol, CvarChange);
    HookConVarChange(cvarSpecialVita, CvarChange);
    HookConVarChange(cvarSpecialAmputator, CvarChange);
    HookConVarChange(cvarSpecialVow, CvarChange);
    HookConVarChange(cvarSpecialSniperShield, CvarChange);
    HookConVarChange(cvarSpecialBazaar, CvarChange);
    HookConVarChange(cvarSpecialShiv, CvarChange);
    HookConVarChange(cvarSpecialBoss, CvarChange);
    HookConVarChange(cvarSpecialSaxton, CvarChange);
    HookConVarChange(cvarSpecialCBS, CvarChange);
    HookConVarChange(cvarSpecialHHH, CvarChange);
    HookConVarChange(cvarSpecialVagineer, CvarChange);
    HookConVarChange(cvarSpecialBunny, CvarChange);
    HookConVarChange(cvarSpecialAgent, CvarChange);*/
    
    HookConVarChange(cvarHaleMinPlayersResetQ, CvarChange);
}

void UTIL_LoadConfig() {
    AutoExecConfig(true, "AdvancedSaxtonHale");
}

void UTIL_InitMsg() {
    LogMessage("===Advanced Saxton Hale Initializing - v%s (build %s) ===", ASH_PLUGIN_VERSION, ASH_BUILD);
    CPrintToChatAll("{ash}[ASH] {default}Initializing Advanced Saxton Hale v{ash}%s {default}(build {ash}%s{default})", ASH_PLUGIN_VERSION, ASH_BUILD);
}

void UTIL_InitVars() {
    // Cheats.
    mooEnabled = true;
    seeEnabled = true;
    ullapoolWarRound = false;
    hotnightEnabled = false;
    BushmanRulesRound = false;
    
    // Goomba FakeKill
    FakeKill_Goomba = 0;

    // Cache plugin name
    GetPluginFilename(GetMyHandle(), ASH_pluginname, PLATFORM_MAX_PATH);
    ReplaceString(ASH_pluginname, PLATFORM_MAX_PATH, ".smx", "", false);

    g_bReloadASHOnRoundEnd = false;
}

void UTIL_RegCookies() {
    PointCookie         = RegClientCookie("hale_queuepoints", "Amount of ASH Queue points player has", CookieAccess_Protected);
    MusicCookie         = RegClientCookie("hale_music_setting", "HaleMusic setting", CookieAccess_Public);
    VoiceCookie         = RegClientCookie("hale_voice_setting", "HaleVoice setting", CookieAccess_Public);
    ClasshelpinfoCookie = RegClientCookie("hale_classinfo", "HaleClassinfo setting", CookieAccess_Public);
}

void UTIL_MakeHUDs() {
    jumpHUD             = CreateHudSynchronizer();
    rageHUD             = CreateHudSynchronizer();
    healthHUD           = CreateHudSynchronizer();
    infoHUD             = CreateHudSynchronizer();
    soulsHUD            = CreateHudSynchronizer();
    bushwackaHUD        = CreateHudSynchronizer();
    BazaarBargainHUD    = CreateHudSynchronizer();
    cheatsHUD           = CreateHudSynchronizer();
}

void UTIL_MakeSpawn() {
    s_hSpawnArray = CreateArray(2);
}

void UTIL_LoadTranslations() {
    LoadTranslations("saxtonhale.phrases");
    LoadTranslations("ash.phrases");

#if defined EASTER_BUNNY_ON
    LoadTranslations("saxtonhale_bunny.phrases");
#endif

    LoadTranslations("common.phrases");
}

void UTIL_InitGamedata() {
    Handle hGameConf = LoadGameConfigFile("ash");
    if (!hGameConf)
    {
        SetFailState("Can't load gamedata file.");
        return; // supress compiler warnings about "null"-used variable.
    }

    // CTFPlayer::GetMaxHealth()
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::GetMaxHealth")
     || !PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain)
     || !(g_ptrGetMaxHealth = EndPrepSDKCall())) {
        CloseHandle(hGameConf);
        SetFailState("Invalid gamedata file for CTFPlayer::GetMaxHealth()");
    }
    
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GrenadeDetonate");
    g_CTFGrenadeDetonate = EndPrepSDKCall();

    CloseHandle(hGameConf);
}

void UTIL_LookupOffsets() {
    LookupOffset(g_iOffsetModelScale, "CTFPlayer", "m_flModelScale");
}

void UTIL_Cleanup(int iClient) {
    SpecialDemo_Kostyl[iClient] = 0;
    BasherDamage[iClient]       = 0;
    SpeedDamage[iClient]        = 0;
    PersDamage[iClient]         = 0;
    uberTarget[iClient]         = -1;
    NatDamage[iClient]          = 0;
    HuoDamage[iClient]          = 0;
    TomDamage[iClient]          = 0;
    BetDamage[iClient]          = 0;
    AirDamage[iClient]          = 0;
    AmpDefend[iClient]          = 0;
    ASHFlags[iClient]           = 0;
    Damage[iClient]             = 0;
    headmeter[iClient]          = 0;
    g_flEurekaCooldown[iClient] = 0.0;

    SpecialPlayers_LastActiveWeapons[iClient] = -1;
    SpecialSoldier_Airshot[iClient] = false;
    InfectPlayers[iClient] = false;
    if (IsHologram(iClient)) Holograms[GetHologramNum(iClient)] = 0;
}

void UTIL_Hook(int iClient) {
    if (g_bHooked[iClient])
        return;

    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(iClient, SDKHook_PreThinkPost, OnPreThinkPost);
    SDKHook(iClient, SDKHook_StartTouch,   OnStartTouch);

    g_bHooked[iClient] = true;
}

void UTIL_UnHook(int iClient) {
    if (!g_bHooked[iClient])
        return;

    SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKUnhook(iClient, SDKHook_PreThinkPost, OnPreThinkPost);
    SDKUnhook(iClient, SDKHook_StartTouch,   OnStartTouch);

    g_bHooked[iClient] = false;
}

stock int FloatToInt(float num) {
    char Temp[30];
    Format(Temp, 30, "%f", num);
    return StringToInt(Temp);
}

stock void SetPlayerRenderAlpha(int client, int alpha) {
    int Temp = -1;
    // Player
    SetEntityRenderColor(client, 255, 255, 255, alpha);
    
    // Weapons
    for (int i = 0; i <= 5; i++) {
        if ((Temp = GetPlayerWeaponSlot(client, i)) != -1) {
            SetEntityRenderColor(Temp, 255, 255, 255, alpha);
        }
    }
    
    // Wearables
    Temp = -1;
    while ((Temp = FindEntityByClassname(Temp, "tf_wearable")) != -1) {
        if (GetEntPropEnt(Temp, Prop_Send, "m_hOwnerEntity" ) == client) {
            SetEntityRenderColor(Temp, 255, 255, 255, alpha);
        }
    }
}

stock float IntToFloat(int num) {
    char Temp[30];
    Format(Temp, 30, "%i.0", num);
    return StringToFloat(Temp);
}

stock bool IsPlayerInAir(int client) {
    if (!(GetEntityFlags(client) & FL_ONGROUND)) return true;
    else return false;
}

stock void ChangeAttribs(int entindex, char[] AttribLine) {
    char atts[32][32];
    int count = ExplodeString(AttribLine, " ; ", atts, 32, 32);
    if (count > 1) {
        for (int i = 0; i < count; i += 2) {
            TF2Attrib_SetByDefIndex(entindex, StringToInt(atts[i]), StringToFloat(atts[i+1]));
        }
    }
}

stock void BuddhaSwitch(int client, bool mode) {
    SetEntProp(client, Prop_Data, "m_takedamage", mode?1:2, 1);
}

stock int GetAmmoClipNum(int weapon) {
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

stock int GetAmmoNum(int client, int weapon) {
    return GetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo")+GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4, 4);
}

stock void SetAmmoClipNum(int weapon, int numAmmo) {
    SetEntProp(weapon, Prop_Send, "m_iClip1", numAmmo);
}

stock void SetAmmoNum(int client, int weapon, int numAmmo) {
    SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo")+GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4, numAmmo, 4);
}

stock void TF2_ForceClass(int client, TFClassType class) {
    TF2_SetPlayerClass(client, class);

    SetEntityHealth(client, 25);
    TF2_RegeneratePlayer(client);
}

stock int GetPlayersInTeam(int team) {
    int players = 0;
    for (int iCli = 1; iCli<=MAXPLAYERS; iCli++) {
        if (!IsValidClient(iCli)) continue;
        
        if (GetEntProp(iCli, Prop_Send, "m_iTeamNum") == team) players++;
    }
    return players;
}

void UTIL_AddToDownload()
{
    /*
        Files to precache that are originally part of TF2 or HL2 / etc and don't need to be downloaded
    */
    PrepareSound("saxton_hale/demowar.mp3");
    PrecacheSound("vo/scout_stunballhit14.mp3", true);
    PrecacheSound("weapons/mantreads.wav", true);
    
    PrecacheModel("models/props_mvm/mvm_player_shield2.mdl");
    // PrecacheModel("models/effects/resist_shield/resist_shield.mdl", true);
    PrecacheModel("materials/models/effects/resist_shield/resist_shield_blue.vtf" , true);
    PrecacheModel("materials/models/effects/resist_shield/resist_shield.vtf" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_bullets.vtf" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_explosives.vtf" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_fire.vtf" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_resist_shield.vmt" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_bullets.vmt" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_explosives.vmt" , true);
    PrecacheModel("materials/models/effects/resist_shield/mvm_vaccinator_shield_fire.vmt" , true);
    PrecacheModel("materials/models/effects/resist_shield/resist_shield.vmt" , true);
    PrecacheModel("materials/models/effects/resist_shield/resist_shield_blue.vmt" , true);
    PrecacheSound("vo/announcer_am_capincite01.mp3", true);
    PrecacheSound("vo/announcer_am_capincite03.mp3", true);
    PrecacheSound("vo/announcer_am_capenabled02.mp3", true);
    PrecacheSound("weapons/vaccinator_toggle.wav", true);

    //PrecacheSound("weapons/barret_arm_zap.wav", true);
    PrecacheSound("player/doubledonk.wav", true);
    PrecacheSound("misc/halloween/spell_meteor_impact.wav", true);
#if defined EASTER_BUNNY_ON
    PrecacheSound("items/pumpkin_pickup.wav", true); // Only necessary for servers that don't have halloween holiday mode enabled.
#endif

    // Hale Stun Effect

    PrecacheParticleSystem("ghost_appearation");
    PrecacheParticleSystem("yikes_fx");

    // Player Specials

    PrecacheSoundList(ScoutRandomScream, sizeof(ScoutRandomScream));
    PrecacheSoundList(ScoutRandomScream2, sizeof(ScoutRandomScream2));
    PrecacheSoundList(MedicRandomScream, sizeof(MedicRandomScream));
    PrecacheSoundList(SpyRandomScream, sizeof(SpyRandomScream));
    PrecacheSoundList(SpyRandomScream2, sizeof(SpyRandomScream2));
    PrecacheSound("player/mannpower_invulnerable.wav", true);
    PrecacheSound("ui/duel_score_behind.wav", true);
    PrecacheSound("mvm/mvm_tele_activate.wav", true);
    PrecacheSound("mvm/mvm_revive.wav", true);
    PrecacheSound(ScoutSodaPopper_Sound, true);
    PrecacheSound("weapons/weapon_crit_charged_off.wav", true);
    PrecacheSound("weapons/icicle_freeze_victim_01.wav", true);
    PrecacheSound("weapons/teleporter_send.wav", true);
    PrecacheSound("weapons/medi_shield_deploy.wav", true);
    PrecacheSound("misc/ks_tier_04_kill_01.wav", true);
    PrecacheSound("misc/ks_tier_03_kill_01.wav", true);
    PrecacheSound("misc/halloween/merasmus_appear.wav", true);
    PrecacheSound("misc/sniper_railgun_double_kill.wav", true);
    PrecacheSound("misc/halloween/spell_stealth.wav", true);
    PrecacheSound("misc/doomsday_lift_start.wav", true);
    PrecacheSound("misc/rd_robot_explosion01.wav", true);
    PrecacheSound("ui/message_update.wav", true);
    PrecacheSound(ManmelterSound, true);
    PrecacheParticleSystem("mini_fireworks");
    PrecacheParticleSystem("teleported_blue");
    PrecacheParticleSystem("heavy_ring_of_fire_child03");
    PrecacheParticleSystem("mvm_levelup1");
    PrecacheParticleSystem("mvm_soldier_shockwave2d");
    PrecacheParticleSystem("god_rays");
    PrecacheParticleSystem("god_rays_fog");
    PrecacheParticleSystem("spell_batball_impact2_blue");
    PrecacheParticleSystem("medic_resist_fire");
    PrecacheParticleSystem("medic_resist_blast");
    PrecacheParticleSystem("ping_circle");
    PrecacheParticleSystem("powerup_icon_plague");
    PrecacheParticleSystem("skull_island_embers");
    PrecacheParticleSystem("skull_island_flash");
    PrecacheParticleSystem("hightower_explosion");
    PrecacheParticleSystem("powerup_icon_supernova");

    // Player Win Voice Line

    // Scout
    PrecacheSound("vo/scout_domination01.mp3", true);
    PrecacheSound("vo/scout_domination07.mp3", true);
    PrecacheSound("vo/scout_domination08.mp3", true);
    PrecacheSound("vo/scout_domination12.mp3", true);
    PrecacheSound("vo/scout_domination19.mp3", true);

    // Soldier
    PrecacheSound("vo/soldier_dominationheavy03.mp3", true);
    PrecacheSound("vo/soldier_dominationmedic05.mp3", true);
    PrecacheSound("vo/soldier_dominationpyro03", true);
    PrecacheSound("vo/soldier_dominationpyro07", true);
    PrecacheSound("vo/soldier_dominationpyro09", true);
    PrecacheSound("vo/soldier_dominationscout07.mp3", true);
    PrecacheSound("vo/soldier_dominationscout09.mp3", true);
    PrecacheSound("vo/soldier_hatoverhearttaunt03.mp3", true);

    // Pyro
    PrecacheSound("vo/pyro_specialcompleted01.mp3", true);
    PrecacheSound("vo/pyro_laughhappy01.mp3", true);

    // Demoman
    PrecacheSound("vo/demoman_dominationengineer06.mp3", true);
    PrecacheSound("vo/demoman_dominationspy02.mp3", true);
    PrecacheSound("vo/demoman_laughlong01.mp3", true);
    PrecacheSound("vo/demoman_dominationdemoman01.mp3", true);
    PrecacheSound("vo/demoman_dominationheavy02.mp3", true);
    PrecacheSound("vo/demoman_dominationpyro03.mp3", true);
    PrecacheSound("vo/demoman_eyelandertaunt01.mp3", true);

    // Heavy
    PrecacheSound("vo/heavy_award03.mp3", true);
    PrecacheSound("vo/heavy_award16.mp3", true);
    PrecacheSound("vo/heavy_domination08.mp3", true);
    PrecacheSound("vo/heavy_domination15.mp3", true);
    PrecacheSound("vo/heavy_laughlong01.mp3", true);

    // Engineer
    PrecacheSound("vo/engineer_dominationscout03.mp3", true);
    PrecacheSound("vo/engineer_dominationscout06.mp3", true);
    PrecacheSound("vo/engineer_goldenwrenchkill04.mp3", true);
    PrecacheSound("vo/engineer_gunslingertriplepunchfinal01.mp3", true);
    PrecacheSound("vo/engineer_dominationengineer06.mp3", true);
    PrecacheSound("vo/engineer_dominationheavy02.mp3", true);
    PrecacheSound("vo/engineer_dominationheavy09.mp3", true);
    PrecacheSound("vo/engineer_dominationheavy14.mp3", true);

    // Sniper
    PrecacheSound("vo/sniper_dominationheavy02.mp3", true);
    PrecacheSound("vo/sniper_dominationsoldier05.mp3", true);
    PrecacheSound("vo/sniper_laughlong01.mp3", true);
    PrecacheSound("vo/sniper_laughlong02.mp3", true);
    PrecacheSound("vo/sniper_revenge21.mp3", true);

    // Spy
    PrecacheSound("vo/spy_dominationmedic01.mp3", true);
    PrecacheSound("vo/spy_dominationsniper05.mp33", true);
    PrecacheSound("vo/spy_dominationsoldier01.mp3", true);
    PrecacheSound("vo/spy_laughevil01.mp3", true);
    PrecacheSound("vo/spy_laughlong01.mp3", true);
    PrecacheSound("vo/spy_mvm_resurrect07.mp3", true);
    PrecacheSound("vo/spy_dominationspy03.mp3", true);
    PrecacheSound("vo/spy_dominationscout02.mp3", true);
    PrecacheSound("vo/spy_stabtaunt03.mp3", true);
    PrecacheSound("vo/spy_tietaunt02.mp3", true);

    /*
        Files to download + precache that are not originally part of TF2 or HL2 / etc
    */
    
    PrepareSound("saxton_hale/9000.wav");
    PrepareSound("saxton_hale/secret_completed.wav");
    PrepareSound("saxton_hale/secret_enabled.wav");
    PrepareSound("saxton_hale/see.mp3");
    PrepareSound("saxton_hale/spy_special_ele_ambient.wav");
    PrepareSound("saxton_hale/spy_special_auto_used.wav");

    /*
        All boss related files
    */

    // Saxton Hale

    // Precache
    // None.. he's all custom

    // Download

    PrepareModel(HaleModel);
    PrepareModel(DispenserModel);

    PrepareMaterial("materials/models/player/saxton_hale/eye"); // Some of these materials are used by Christian Brutal Sniper
    PrepareMaterial("materials/models/player/saxton_hale/hale_head");
    PrepareMaterial("materials/models/player/saxton_hale/hale_body");
    PrepareMaterial("materials/models/player/saxton_hale/hale_misc");
    PrepareMaterial("materials/models/player/saxton_hale/sniper_red");
    PrepareMaterial("materials/models/player/saxton_hale/sniper_lens");

    //Saxton Hale Materials
    AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head.vtf"); // So we're keeping ALL of them.
    AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head_red.vmt");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc_normal.vtf");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body_normal.vtf");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_l.vmt");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_r.vmt");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vtf");
    AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vmt");

    DownloadMaterialList(HaleMatsV2, sizeof(HaleMatsV2)); // New material files for Saxton Hale's new model.

    PrepareSound(HaleComicArmsFallSound);
    PrepareSound("saxton_hale/player_special_secondchance_used.wav");
    PrepareSound(HaleKSpree);

    int i;
    char s[PLATFORM_MAX_PATH];
    
    for (i = 1; i <= 4; i++)
    {
        FormatEx(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HaleLastB, i);
        PrecacheSound(s, true);
    }
    
    // Agent
    PrecacheSoundList(Agent_RoundStart, sizeof(Agent_RoundStart));
    PrecacheSoundList(Agent_KSpree, sizeof(Agent_KSpree));
    PrecacheSoundList(Agent_Win, sizeof(Agent_Win));
    PrecacheSoundList(Agent_Fail, sizeof(Agent_Fail));
    PrecacheSoundList(Agent_Backstabbed, sizeof(Agent_Backstabbed));
    PrecacheSoundList(Agent_Circumfused, sizeof(Agent_Circumfused));
    PrecacheSoundList(Agent_Jump, sizeof(Agent_Jump));
    PrecacheSoundList(Agent_LaughInvis, sizeof(Agent_LaughInvis));
    PrecacheSoundList(Agent_SpecialAbility_Zipper, sizeof(Agent_SpecialAbility_Zipper));
    PrecacheSoundList(Agent_KillScout, sizeof(Agent_KillScout));
    PrecacheSoundList(Agent_KillPyro, sizeof(Agent_KillPyro));
    PrecacheSoundList(Agent_KillMedic, sizeof(Agent_KillMedic));
    PrecacheSoundList(Agent_KillHeavy, sizeof(Agent_KillHeavy));
    PrecacheSoundList(Agent_LastAlive, sizeof(Agent_LastAlive));
    PrecacheSound(Agent_KillSentry, true);
    PrecacheSound(Agent_SpecialAbility_Start, true);
    PrecacheSound(Agent_SixHolograms, true);
    PrecacheSound(Agent_Rage, true);
    PrecacheSound(Agent_Whistle, true);
    PrepareModel(Agent_Model);
    DownloadMaterialList(AgentMats, sizeof(AgentMats));

    PrepareSound(HaleKillMedic);
    PrepareSound(HaleKillSniper1);
    PrepareSound(HaleKillSniper2);
    PrepareSound(HaleKillSpy1);
    PrepareSound(HaleKillSpy2);
    PrepareSound(HaleKillEngie1);
    PrepareSound(HaleKillEngie2);
    PrepareSound(HaleKillDemo132);

    PrepareSound(HaleKillHeavy132);
    PrepareSound(HaleKillScout132);
    PrepareSound(HaleKillSpy132);
    PrepareSound(HaleKillPyro132);
    PrepareSound(HaleSappinMahSentry132);
    PrepareSound(HaleKillLast132);
    PrepareSound(HaleKillDemo132);
    PrepareSound(HaleKillDemo132);
    PrepareSound(HaleKillDemo132);
    PrepareSound(HaleKillDemo132);
    PrepareSound(HaleKillDemo132);

    for (i = 1; i <= 5; i++)
    {
        if (i <= 2)
        {
            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, i);
            PrepareSound(s);

            /*Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerRageSound2, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerFail, i);
            PrepareSound(s);*/

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, i);
            PrepareSound(s);
        }

        if (i <= 3)
        {
            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, i);
            PrepareSound(s);
        }

        if (i <= 4)
        {
            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, i);
            PrepareSound(s);
        }

        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, i);
        PrepareSound(s);

        //Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, i);
        //PrepareSound(s);

        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, i);
        PrepareSound(s);

        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, i);
        PrepareSound(s);

        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, i);
        PrepareSound(s);
    }
    
    PrepareSound(VagineerSAStart);

    if (!bSpecials)
    {
        return;
    }

    // Christian Brutal Sniper
    // Precache

    PrecacheSound(CBS0, true);
    PrecacheSound(CBS1, true);
    //PrecacheSound(CBS3, true);
    PrecacheSound(CBSJump1, true);
    PrecacheSoundList(CBS3, sizeof(CBS3));

    for (i = 1; i <= 25; i++)
    {
        if (i <= 9)
        {
            Format(s, PLATFORM_MAX_PATH, "%s%02i.mp3", CBS2, i);
            PrecacheSound(s, true);
        }
        Format(s, PLATFORM_MAX_PATH, "%s%02i.mp3", CBS4, i);
        PrecacheSound(s, true);
    }

    PrecacheSound("vo/sniper_dominationspy04.mp3", true);

    // Download

    PrepareModel(CBSModel);
    PrepareSound(CBSTheme);


    // Horseless Headless Horsemann

    // Precache

    PrecacheSound(HHHRage, true);
    PrecacheSound(HHHRage2, true);

    for (i = 1; i <= 4; i++)
    {
        Format(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHLaught, i);
        PrecacheSound(s, true);
        Format(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHAttack, i);
        PrecacheSound(s, true);
    }

    PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
    PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);

    PrecacheSound("vo/halloween_boss/knight_pain01.mp3", true);
    PrecacheSound("vo/halloween_boss/knight_pain02.mp3", true);
    PrecacheSound("vo/halloween_boss/knight_pain03.mp3", true);
    PrecacheSound("vo/halloween_boss/knight_death01.mp3", true);
    PrecacheSound("vo/halloween_boss/knight_death02.mp3", true);

    PrecacheSound("misc/halloween/spell_teleport.wav", true);

    PrecacheSound(HHHTheme, true);

    // Download

    PrepareModel(HHHModel);
    

    // Vagineer

    // Precache

    PrecacheSound("vo/engineer_no01.mp3", true);
    PrecacheSound("vo/engineer_jeers02.mp3", true);

    // Download

    PrepareModel(VagineerModel);

    PrepareSound(VagineerLastA);
    PrepareSound(VagineerStart);
    PrepareSound(VagineerRageSoundA);
    PrepareSound(VagineerRageSoundB);
    PrepareSound(VagineerKSpree);
    PrepareSound(VagineerKSpree2);
    PrepareSound(VagineerKSpree3);
    PrepareSound(VagineerHit);
    PrepareSound(VagineerStabbed);

    for (i = 1; i <= 5; i++)
    {
        if (i <= 2)
        {
            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, i);
            PrepareSound(s);

            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerRageSound2, i);
            PrepareSound(s);
        }
        
        if (i <= 4) {
            Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerFail, i);
            PrepareSound(s);
        }

        Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, i);
        PrepareSound(s);
    }

    PrepareSound(VagineerRoundStart);

#if defined EASTER_BUNNY_ON
    // Easter Bunny

    // Precache

    PrecacheSoundList(BunnyWin, sizeof(BunnyWin));
    PrecacheSoundList(BunnyJump, sizeof(BunnyJump));
    PrecacheSoundList(BunnyRage, sizeof(BunnyRage));
    PrecacheSoundList(BunnyFail, sizeof(BunnyFail));
    PrecacheSoundList(BunnyKill, sizeof(BunnyKill));
    PrecacheSoundList(BunnySpree, sizeof(BunnySpree));
    PrecacheSoundList(BunnyLast, sizeof(BunnyLast));
    PrecacheSoundList(BunnyPain, sizeof(BunnyPain));
    PrecacheSoundList(BunnyStart, sizeof(BunnyStart));
    PrecacheSoundList(BunnyRandomVoice, sizeof(BunnyRandomVoice));

    // Download

    PrepareModel(BunnyModel);
    PrepareModel(EggModel);
    // PrepareModel(ReloadEggModel);

    DownloadMaterialList(BunnyMaterials, sizeof(BunnyMaterials));

    PrepareMaterial("materials/models/props_easteregg/c_easteregg");
    AddFileToDownloadsTable("materials/models/props_easteregg/c_easteregg_gold.vmt");
#endif
}

void UTIL_SetPluginDetection(const char[] szName, bool bBool) {
    if (StrEqual(szName, "SteamWorks")) {
        g_bSteamWorksIsRunning = bBool;
    }
}

void UTIL_MakeMultiTarget() {
    AddMultiTargetFilter("@hale", HaleTargetFilter, "the current Boss", false);
    AddMultiTargetFilter("@!hale", HaleTargetFilter, "all non-Boss players", false);
}

void UTIL_CheckClient(int client) {
    UTIL_Cleanup(client);
    if (IsClientInGame(client)) {
        UTIL_Hook(client);

        if (IsPlayerAlive(client)) {
            TF2Attrib_RemoveByName(client, "damage force reduction");
        }
    }
}

void UTIL_ValidateMap() {
    UTIL_ValidateMap_KingOfTheHill();
}

void UTIL_ValidateMap_KingOfTheHill() {
    int i_KOTH_Entity     = FindEntityByClassname(-1, "tf_logic_koth");
    int i_Arena_Entity    = FindEntityByClassname(-1, "tf_logic_arena");

    if (i_KOTH_Entity > 0 && i_Arena_Entity == -1) {
        if ((i_Arena_Entity = CreateEntityByName("tf_logic_arena")) != -1) {
            DispatchSpawn(i_Arena_Entity);

            AcceptEntityInput(i_KOTH_Entity, "Kill");

            GameRules_SetProp("m_nGameType", 4);
            GameRules_SetProp("m_bPlayingKoth", 0);
        }
    }
}

public Action ResetPunchProtect(Handle hTimer) {
    g_bHaleProtectPunch = false;
}

void UTIL_SetupEntityAnimation(int iEntity, const char[] szAnimation) {
    SetVariantString(szAnimation);
    AcceptEntityInput(iEntity, "SetAnimation");
}

public Action OnPlayEndRoundSound(Handle hTimer, any eClass) {
    switch (eClass) 
    {
        case TFClass_Scout:     {
            switch (GetRandomInt(0, 4)) {
                case 0: MegaEmitSoundToAll("vo/scout_domination01.mp3");
                case 1: MegaEmitSoundToAll("vo/scout_domination07.mp3");
                case 2: MegaEmitSoundToAll("vo/scout_domination08.mp3");
                case 3: MegaEmitSoundToAll("vo/scout_domination12.mp3");
                case 4: MegaEmitSoundToAll("vo/scout_domination19.mp3");
            }
        }

        case TFClass_Soldier:    {
            switch (GetRandomInt(0, 7)) {
                case 0: MegaEmitSoundToAll("vo/soldier_dominationheavy03.mp3");
                case 1: MegaEmitSoundToAll("vo/soldier_dominationmedic05.mp3");
                case 2: MegaEmitSoundToAll("vo/soldier_dominationpyro03.mp3");
                case 3: MegaEmitSoundToAll("vo/soldier_dominationpyro07.mp3");
                case 4: MegaEmitSoundToAll("vo/soldier_dominationpyro09.mp3");
                case 5: MegaEmitSoundToAll("vo/soldier_dominationscout07.mp3");
                case 6: MegaEmitSoundToAll("vo/soldier_dominationscout09.mp3");
                case 7: MegaEmitSoundToAll("vo/soldier_hatoverhearttaunt03.mp3");
            }
        }

        case TFClass_Pyro:    {
            switch (GetRandomInt(0, 1)) {
                case 0: MegaEmitSoundToAll("vo/pyro_specialcompleted01.mp3");
                case 1: MegaEmitSoundToAll("vo/pyro_laughhappy01.mp3");
            }
        }

        case TFClass_DemoMan:    {
            switch (GetRandomInt(0, 6)) {
                case 0: MegaEmitSoundToAll("vo/demoman_dominationengineer06.mp3");
                case 1: MegaEmitSoundToAll("vo/demoman_dominationspy02.mp3");
                case 2: MegaEmitSoundToAll("vo/demoman_laughlong01.mp3");
                case 3: MegaEmitSoundToAll("vo/demoman_dominationdemoman01.mp3");
                case 4: MegaEmitSoundToAll("vo/demoman_dominationheavy02.mp3");
                case 5: MegaEmitSoundToAll("vo/demoman_dominationpyro03.mp3");
                case 6: MegaEmitSoundToAll("vo/demoman_eyelandertaunt01.mp3");
            }
        }

        case TFClass_Heavy:    {
            switch (GetRandomInt(0, 4)) {
                case 0: MegaEmitSoundToAll("vo/heavy_award03.mp3");
                case 1: MegaEmitSoundToAll("vo/heavy_award16.mp3");
                case 2: MegaEmitSoundToAll("vo/heavy_domination08.mp3");
                case 3: MegaEmitSoundToAll("vo/heavy_domination15.mp3");
                case 4: MegaEmitSoundToAll("vo/heavy_laughlong01.mp3");
            }
        }

        case TFClass_Engineer:    {
            switch (GetRandomInt(0, 7)) {
                case 0: MegaEmitSoundToAll("vo/engineer_dominationscout03.mp3");
                case 1: MegaEmitSoundToAll("vo/engineer_dominationscout06.mp3");
                case 2: MegaEmitSoundToAll("vo/engineer_goldenwrenchkill04.mp3");
                case 3: MegaEmitSoundToAll("vo/engineer_gunslingertriplepunchfinal01.mp3");
                case 4: MegaEmitSoundToAll("vo/engineer_dominationengineer06.mp3");
                case 5: MegaEmitSoundToAll("vo/engineer_dominationheavy02.mp3");
                case 6: MegaEmitSoundToAll("vo/engineer_dominationheavy09.mp3");
                case 7: MegaEmitSoundToAll("vo/engineer_dominationheavy14.mp3");
            }
        }

        case TFClass_Medic:    {
            switch (GetRandomInt(0, 3)) {
                case 0: MegaEmitSoundToAll("vo/medic_laughhappy02.mp3");
                case 1: MegaEmitSoundToAll("vo/medic_laughlong02.mp3");
                case 2: MegaEmitSoundToAll("vo/medic_sf12_badmagic12.mp3");
                case 3: MegaEmitSoundToAll("vo/medic_sf13_influx_big03.mp3");
            }
        }

        case TFClass_Sniper:    {
            switch (GetRandomInt(0, 4)) {
                case 0: MegaEmitSoundToAll("vo/sniper_dominationheavy02.mp3");
                case 1: MegaEmitSoundToAll("vo/sniper_dominationsoldier05.mp3");
                case 2: MegaEmitSoundToAll("vo/sniper_laughlong01.mp3");
                case 3: MegaEmitSoundToAll("vo/sniper_laughlong02.mp3");
                case 4: MegaEmitSoundToAll("vo/sniper_revenge21.mp3");
            }
        }

        case TFClass_Spy:    {
            switch (GetRandomInt(0, 9)) {
                case 0: MegaEmitSoundToAll("vo/spy_dominationmedic01.mp3");
                case 1: MegaEmitSoundToAll("vo/spy_dominationsniper05.mp3");
                case 2: MegaEmitSoundToAll("vo/spy_dominationsoldier01.mp3");
                case 3: MegaEmitSoundToAll("vo/spy_laughevil01.mp3");
                case 4: MegaEmitSoundToAll("vo/spy_laughlong01.mp3");
                case 5: MegaEmitSoundToAll("vo/spy_mvm_resurrect07.mp3");
                case 6: MegaEmitSoundToAll("vo/spy_dominationspy03.mp3");
                case 7: MegaEmitSoundToAll("vo/spy_dominationscout02.mp3");
                case 8: MegaEmitSoundToAll("vo/spy_stabtaunt03.mp3");
                case 9: MegaEmitSoundToAll("vo/spy_tietaunt02.mp3");
            }
        }
    }
}

stock int UTIL_FindConnTracker(int iClient) {
    int iEntity;
    while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_campaign_item")) != -1)
        if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 5869)
            return iEntity;

    return -1;
}

stock void UTIL_CreateBelatedAttributeDelete(float flTime, int iEntity, int iAttribute) {
    DataPack hPack;
    CreateDataTimer(flTime, OnBelatedDeleteAttribute, hPack, TIMER_FLAG_NO_MAPCHANGE);

    hPack.WriteCell(EntIndexToEntRef(iEntity));
    hPack.WriteCell(iAttribute);
}

stock void UTIL_CreateBelatedAttributeChange(float flTime, int iEntity, int iAttribute, float flValue) {
    DataPack hPack;
    CreateDataTimer(flTime, OnBelatedChangeAttribute, hPack, TIMER_FLAG_NO_MAPCHANGE);

    hPack.WriteCell(EntIndexToEntRef(iEntity));
    hPack.WriteCell(iAttribute);
    hPack.WriteFloat(flValue);
}

int UTIL_GetAlivePlayers(int iTeam) {
    int iCounter = 0;
    for (int iClient = MaxClients; iClient != 0; --iClient) {
        if (IsClientInGame(iClient) && GetClientTeam(iClient) == iTeam && IsPlayerAlive(iClient))
            iCounter++;
    }
    
    //PrintToChatAll("iCounter: %d", iCounter);
    return iCounter;
}

int UTIL_LookupClient(int iTeam, TFClassType eClass, bool bAlive) {
    for (int iClient = MaxClients; iClient != 0; --iClient)
        if (IsClientInGame(iClient) && GetClientTeam(iClient) == iTeam && (eClass == TFClass_Unknown || TF2_GetPlayerClass(iClient) == eClass) && (!bAlive || IsPlayerAlive(iClient)))
            return iClient;
    return 0;
}

void UTIL_AddFunction(int iEventType, Function ptrFunc, DataPack &hPack) {
    hPack = new DataPack();
    DataPack hCall = new DataPack();
    hCall.WriteFunction(ptrFunc);
    hCall.WriteCell(hPack);

    switch (iEventType) {
        case ASHEvent_RoundStart: g_hRSHooks.Push(hCall);
        case ASHEvent_RoundEnd:     g_hREHooks.Push(hCall);
    }
}

void UTIL_Call(int iEventType) {
    switch (iEventType) {
        case ASHEvent_RoundStart: UTIL_CallStart(g_hRSHooks);
        case ASHEvent_RoundEnd:     UTIL_CallStart(g_hREHooks);
    }
}

void UTIL_CallStart(ArrayList hFunctions) {
    int iLength = hFunctions.Length;
    DataPack hCall, hData;

    for (int iFunction; iFunction < iLength; ++iFunction) {
        hCall = hFunctions.Get(iFunction);
        hCall.Reset();

        Call_StartFunction(null, hCall.ReadFunction());

        hData = hCall.ReadCell();
        hData.Reset();

        Call_PushCell(hData);
        Call_Finish();

        delete hData;
        delete hCall;
    }

    hFunctions.Clear();
}

int UTIL_FindNearestPlayer(int iClient, float &flDistance = 0.0) {
    int iTarget;
    float vecPosition[2][3];

    GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vecPosition[0]);
    int iClientTeam = GetClientTeam(iClient);
    int iTargetTeam = 0;
    float flTempDistance;

    for (int iPlayer = MaxClients; iPlayer != 0; --iPlayer) {
        if (!IsClientInGame(iPlayer) || IsFakeClient(iPlayer) || iPlayer == iClient || !IsPlayerAlive(iPlayer))
        continue;

        iTargetTeam = GetClientTeam(iPlayer);
        if (iTargetTeam < 2 || iTargetTeam == iClientTeam)
        continue;

        GetEntPropVector(iPlayer, Prop_Send, "m_vecOrigin", vecPosition[1]);
        flTempDistance = GetVectorDistance(vecPosition[0], vecPosition[1], true);

        // PrintToChatAll("UTIL_FindNearestPlayer(): %d %f %f", iPlayer, flTempDistance, flDistance);
        if (iTarget == 0 || flTempDistance < flDistance) {
            iTarget = iPlayer;
            flDistance = flTempDistance;
        }
    }

    // PrintToServer("UTIL_FindNearestPlayer(): %L %f", iTarget, flDistance);
    return iTarget;
}

int UTIL_GetMaxHealthByClass(TFClassType eClass) {
    switch (eClass) {
        case TFClass_Heavy:     return 300;
        case TFClass_Soldier:   return 200;
        case TFClass_Pyro,
            TFClass_DemoMan:    return 175;
        default:                return 125;
    }
    return 0;
}

/*int UTIL_GetRandomClientFromTeam(int iTeam, bool bIsAlive = false) {
    ArrayList hList = new ArrayList(4);

    for (int iClient = MaxClients; iClient != 0; iClient--) {
        if (IsClientInGame(iClient) && GetClientTeam(iClient) == iTeam) {
            if (bIsAlive && !IsPlayerAlive(iClient))
                continue;

            hList.Push(iClient);
        }
    }

    int iResult = 0;
    if (hList.Length > 0)
        iResult = GetRandomInt(0, hList.Length-1);
    CloseHandle(hList);

    return iResult;
}*/

stock int UTIL_GetMaxHealth(int iClient) {
    return SDKCall(g_ptrGetMaxHealth, iClient);
}

stock void UTIL_SetMaxHealth(int iClient, int iHealth = 0) {
    // First, reset our entity health.
    UTIL_SetAdditionalHealth(iClient, 0);

    // Second, recalculate required additional health.
    int iMaxHealth = UTIL_GetMaxHealth(iClient);
    int iRequiredAdditionalHealth = iHealth - iMaxHealth;

    // Third, set additional health.
    UTIL_SetAdditionalHealth(iClient, iRequiredAdditionalHealth);
}

stock void UTIL_SetAdditionalHealth(int iClient, int iHealth = 0) {
    if (iHealth == 0)
    {
        TF2Attrib_RemoveByDefIndex(iClient, 26);
        return;
    }

    TF2Attrib_SetByDefIndex(iClient, 26, float(iHealth));
}