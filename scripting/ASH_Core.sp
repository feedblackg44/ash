/*
    ===Versus Saxton Hale Mode===
    Created by Rainbolt Dash (formerly Dr.Eggman): programmer, model-maker, mapper.
    Notoriously famous for creating plugins with terrible code and then abandoning them
    
    FlaminSarge - He makes cool things. He improves on terrible things until they're good.
    Chdata - A Hale enthusiast and a coder. An Integrated Data Sentient Entity.
    nergal - Added some very nice features to the plugin and fixed important bugs.
    
    New plugin thread on AlliedMods: https://forums.alliedmods.net/showthread.php?p=2167912

    ===Advanced Saxton Hale===
    Authors:

        CrazyHackGUT - Previous ASH Programmer.
        NITROYUASH - Something [s]bad[/s] good ideas for weapons and more [s]disbalanced merde for gibus-scouts[/s] special abilities for players/bosses.
        FeedBlack - Continued development of this plugin after CrazyHackGUT has leaved Dev Team.

*/
#define VSH_PLUGIN_VERSION "1.55"

/**
 * TODO на будущее:
 * 1. Выкинуть по максимуму #define, где возможно. Оставить только конст чары/инты.
 * 2. Рефакторнуть апи.
 * 3. Переделать работу с боссами и их логикой.
 * 4. См. 3, но для игроков.
 * 5. Атрибуты и их значения для оружий - в геймдату.
 * 6. Избавиться от FindConVar() по максимуму в каждом обработчике эвентов (и не только).
 */

// ASH Version controller
#define ASH_BUILD                     "8978"
#define ASH_PLUGIN_VERSION            "1.30"
#define ASH_PLUGIN_RELDATE            "21 June 2021"

// ASH Settings
#define ASH_SECRETBOSS_MAXRAND        498
#define ASH_SECRETBOSS_MINRAND        2
#define ASH_INFECTIONRADIUS_HALE      235.0
#define ASH_INFECTIONRADIUS_PLAYERS   210.0

// Declared constant for "declaring" obsolete natives.
#define __ASH_API_COMPABILITY

// Tech
#define PLUGINVERSION                 ASH_PLUGIN_VERSION ... " (" ... ASH_BUILD ... ")"

#pragma semicolon 1
#include <tf2_stocks>
#include <tf2items>
#include <regex>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#include <morecolors>
#include <sourcemod>
#include <nextmap>
#include <advancedsaxtonhale>
#include <tf2attributes>
//#include <tf2wearables>
//#include <collisionhook>

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

// New syntax
#pragma newdecls required

#if defined _SteamWorks_Included
bool g_bSteamWorksIsRunning = false;
#endif

#define CBS_MAX_ARROWS 4

#define EASTER_BUNNY_ON         // Add a "//" before this line [or delete it] to remove the easter bunny
#define OVERRIDE_MEDIGUNS_ON    // Blocking this will make all mediguns be visually replaced with a kritkrieg model instead of keeping their reskinned versions

// Not recommended to change the super jump defines below without knowing how they work.
#define HALEHHH_TELEPORTCHARGETIME 2
#define HALE_JUMPCHARGETIME 1

#define HALEHHH_TELEPORTCHARGE (25 * HALEHHH_TELEPORTCHARGETIME)
#define HALE_JUMPCHARGE (25 * HALE_JUMPCHARGETIME)
         
#define TF_MAX_PLAYERS          34           //Sourcemod supports up to 64 players? Too bad TF2 doesn't. 33 player server +1 for 0 (console/world)
#define MAX_ENTITIES            2049         //This is probably TF2 specific
#define MAX_CENTER_TEXT         192          //PrintCenterText()

#define FCVAR_VERSION           FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT

// Player team values from Team Fortress 2... but without the annoying enum type thing
#define TEAM_UNOWEN             0
#define TEAM_SPEC               1
#define TEAM_RED                2
#define TEAM_BLU                3

#define MAX_INT                 cellmax // 2147483647     //PriorityCenterText
#define MIN_INT                 cellmin // -2147483648    //PriorityCenterText
#define MAX_DIGITS              12           //10 + \0 for IntToString. And negative signs.

// events
ArrayList     g_hRSHooks;
ArrayList     g_hREHooks;

// cheats
bool mooEnabled;
bool seeEnabled;
bool ullapoolWarRound;
bool ullapoolWarEnabled;
bool ullapoolWarMap;
bool hotnightEnabled;
bool hotnightMap;
bool BushmanRulesRound;
bool BushmanRulesEnabled;
bool BushmanRulesMap;

// eureka effect
float g_flEurekaCooldown[MAXPLAYERS+1];
bool g_bHaleProtectPunch;

// TF2 Weapon Loadout Slots
enum
{
    TFWeaponSlot_DisguiseKit = 3,
    TFWeaponSlot_Watch = 4,
    TFWeaponSlot_DestroyKit = 4,
    TFWeaponSlot_BuildKit = 5
}

// m_lifeState
enum
{
    LifeState_Alive = 0,
    LifeState_Dead = 2
}

//    For IsDate()
enum
{
    Month_None = 0,
    Month_Jan,
    Month_Feb,
    Month_Mar,
    Month_Apr,
    Month_May,
    Month_Jun,
    Month_Jul,
    Month_Aug,
    Month_Sep,
    Month_Oct,
    Month_Nov,
    Month_Dec
}

// Default stock weapon item definition indexes for GunmettleToIndex()
enum
{
    TFWeapon_Invalid = -1,

    TFWeapon_SniperRifle = 14,
    TFWeapon_SMG = 16,
    TFWeapon_Scattergun = 13,

    TFWeapon_Shotgun = 10,
    TFWeapon_ShotgunSoldier = 10,
    TFWeapon_ShotgunPyro = 12,
    TFWeapon_ShotgunHeavy = 11,
    TFWeapon_ShotgunEngie = 9,

    TFWeapon_Minigun = 15,
    TFWeapon_Flamethrower = 21,
    TFWeapon_RocketLauncher = 18,
    TFWeapon_Medigun = 29,
    TFWeapon_StickyLauncher = 20,
    TFWeapon_Revolver = 24,

    TFWeapon_Pistol = 23,
    TFWeapon_PistolScout = 23,
    TFWeapon_PistolEngie = 22
}

// TF2 Weapon qualities
enum 
{
    TFQual_None = -1,         // Probably should never actually set an item's quality to this
    TFQual_Normal = 0,
    TFQual_NoInspect = 0,     // Players cannot see your attributes - NO LONGER WORKS due to Gunmettle update.
    TFQual_Rarity1,
    TFQual_Genuine = 1,
    TFQual_Rarity2,
    TFQual_Level = 2,         // Same color as "Level # Weapon" text in description
    TFQual_Vintage,
    TFQual_Rarity3,           // Is actually 4 - sort of brownish
    TFQual_Rarity4,
    TFQual_Unusual = 5,
    TFQual_Unique,
    TFQual_Community,
    TFQual_Developer,
    TFQual_Selfmade,
    TFQual_Customized,
    TFQual_Strange,
    TFQual_Completed,
    TFQual_Haunted,         // 13
    TFQual_Collectors
}

// START FILE DEFINTIONS & ENUMS

enum e_flNext
{
    e_flNextBossTaunt = 0,
    e_flNextAllowBossSuicide,
    e_flNextAllowOtherSpawnTele,
    e_flNextBossKillSpreeEnd,
    e_flNextHealthQuery,
    e_flNextMedicCall,
    e_flNextStun
}

enum e_flNext2
{
    e_flNextEndPriority = 0
}

// Saxton Hale Files

// Model
stock const char HaleModel[] = "models/player/saxton_hale_jungle_inferno/saxton_hale.mdl";

// Dispenser Mode
stock const char DispenserModel[] = "models/buildables/dispenser_lvl3_light.mdl";

// Materials

char HaleMatsV2[][] = {
//    "materials/models/player/saxton_test4/eyeball_l.vmt",
//    "materials/models/player/saxton_test4/eyeball_r.vmt",
//    "materials/models/player/saxton_test4/halebody.vmt",
//    "materials/models/player/saxton_test4/halebody.vtf",
//    "materials/models/player/saxton_test4/halebodyexponent.vtf",
//    "materials/models/player/saxton_test4/halehead.vmt",
//    "materials/models/player/saxton_test4/halehead.vtf",
//    "materials/models/player/saxton_test4/haleheadexponent.vtf",
//    "materials/models/player/saxton_test4/halenormal.vtf",
//    "materials/models/player/saxton_test4/halephongmask.vtf",
    "materials/models/player/saxton_test4/haleGibs.vmt",
    "materials/models/player/saxton_test4/halegibs.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_belt.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_belt_high.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_belt_high.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_belt_high_normal.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_body.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_body.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_body_alt.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_body_exp.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_body_normal.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_body_saxxy.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_body_saxxy.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_hat_color.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_hat_color.vtf",
    "materials/models/player/hwm_saxton_hale/saxton_hat_saxxy.vmt",
    "materials/models/player/hwm_saxton_hale/saxton_hat_saxxy.vtf",
    "materials/models/player/hwm_saxton_hale/tongue_saxxy.vmt",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head.vmt",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head.vtf",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head_exponent.vtf",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head_normal.vtf",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head_saxxy.vmt",
    "materials/models/player/hwm_saxton_hale/hwm/saxton_head_saxxy.vtf",
    "materials/models/player/hwm_saxton_hale/hwm/tongue.vmt",
    "materials/models/player/hwm_saxton_hale/hwm/tongue.vtf",
    "materials/models/player/hwm_saxton_hale/shades/eye.vtf",
    "materials/models/player/hwm_saxton_hale/shades/eyeball_l.vmt",
    "materials/models/player/hwm_saxton_hale/shades/eyeball_r.vmt",
    "materials/models/player/hwm_saxton_hale/shades/eyeball_saxxy.vmt",
    "materials/models/player/hwm_saxton_hale/shades/eye-extra.vtf",
    "materials/models/player/hwm_saxton_hale/shades/eye-saxxy.vtf",
    "materials/models/player/hwm_saxton_hale/shades/inv.vmt",
    "materials/models/player/hwm_saxton_hale/shades/null.vtf"
};

// SFX
#define HaleYellName              "saxton_hale/saxton_hale_responce_1a.wav"
#define HaleRageSoundB            "saxton_hale/saxton_hale_responce_1b.wav"
#define HaleComicArmsFallSound    "saxton_hale/saxton_hale_responce_2.wav"
#define HaleLastB                 "vo/announcer_am_lastmanalive"

#define HaleKSpree                "saxton_hale/saxton_hale_responce_3.wav"
//HaleKSpree2 - this line is broken and unused
#define HaleKSpree2             "saxton_hale/saxton_hale_responce_4.wav"

//===New responces===
#define HaleRoundStart            "saxton_hale/saxton_hale_responce_start"                // 1-5
#define HaleJump                "saxton_hale/saxton_hale_responce_jump"                 // 1-2
#define HaleRageSound             "saxton_hale/saxton_hale_responce_rage"                 // 1-4
#define HaleKillMedic             "saxton_hale/saxton_hale_responce_kill_medic.wav"
#define HaleKillSniper1         "saxton_hale/saxton_hale_responce_kill_sniper1.wav"
#define HaleKillSniper2         "saxton_hale/saxton_hale_responce_kill_sniper2.wav"
#define HaleKillSpy1            "saxton_hale/saxton_hale_responce_kill_spy1.wav"
#define HaleKillSpy2            "saxton_hale/saxton_hale_responce_kill_spy2.wav"
#define HaleKillEngie1          "saxton_hale/saxton_hale_responce_kill_eggineer1.wav"
#define HaleKillEngie2          "saxton_hale/saxton_hale_responce_kill_eggineer2.wav"
#define HaleKSpreeNew           "saxton_hale/saxton_hale_responce_spree"                // 1-5
#define HaleWin                 "saxton_hale/saxton_hale_responce_win"                    // 1-2
#define HaleLastMan             "saxton_hale/saxton_hale_responce_lastman"                // 1-5
//#define HaleLastMan2Fixed     "saxton_hale/saxton_hale_responce_lastman2.wav"
#define HaleFail                "saxton_hale/saxton_hale_responce_fail"                 // 1-3

//===1.32 responces===
#define HaleJump132             "saxton_hale/saxton_hale_132_jump_"                     // 1-2
#define HaleStart132            "saxton_hale/saxton_hale_132_start_"                    // 1-5
#define HaleKillDemo132         "saxton_hale/saxton_hale_132_kill_demo.wav"
#define HaleKillEngie132        "saxton_hale/saxton_hale_132_kill_engie_"                 // 1-2
#define HaleKillHeavy132        "saxton_hale/saxton_hale_132_kill_heavy.wav"
#define HaleKillScout132        "saxton_hale/saxton_hale_132_kill_scout.wav"
#define HaleKillSpy132          "saxton_hale/saxton_hale_132_kill_spie.wav"
#define HaleKillPyro132         "saxton_hale/saxton_hale_132_kill_w_and_m1.wav"
#define HaleSappinMahSentry132  "saxton_hale/saxton_hale_132_kill_toy.wav"
#define HaleKillKSpree132       "saxton_hale/saxton_hale_132_kspree_"                     // 1-2
#define HaleKillLast132         "saxton_hale/saxton_hale_132_last.wav"
#define HaleStubbed132          "saxton_hale/saxton_hale_132_stub_"                     // 1-4

// Unused
//#define HaleEnabled             QueuePanelH(Handle:0, MenuAction:0, 9001, 0)


// Christian Brutal Sniper Files

// Model
#define CBSModel                "models/player/saxton_hale/cbs_v4.mdl"

// Materials
// Prepared Manually

// SFX
#define CBSTheme                "saxton_hale/the_millionaires_holiday.mp3"
#define CBS0                    "vo/sniper_specialweapon08.mp3"
#define CBS1                "vo/taunts/sniper_taunts02.mp3"
#define CBS2                    "vo/sniper_award"
//#define CBS3                "vo/sniper_battlecry03.mp3"
#define CBS4                    "vo/sniper_domination"
#define CBSJump1                "vo/sniper_specialcompleted02.mp3"

// EXTRA SFX
char CBS3[][] = {
    "vo/sniper_battlecry03.mp3",
    "vo/sniper_cheers01.mp3",
    "vo/sniper_laughevil01.mp3",
    "vo/sniper_laughevil02.mp3",
    "vo/sniper_mvm_loot_rare05.mp3",
    "vo/sniper_mvm_loot_rare02.mp3",
    "vo/sniper_sf13_round_start02.mp3",
};

// Unused
//#define ShivModel                 "models/weapons/c_models/c_wood_machete/c_wood_machete.mdl"


// Horseless Headless Horsemann Files

// Model
#define HHHModel                "models/player/saxton_hale/hhh_jr_mk3.mdl"

// Materials

// SFX
#define HHHLaught                 "vo/halloween_boss/knight_laugh"
#define HHHRage                 "vo/halloween_boss/knight_attack01.mp3"
#define HHHRage2                "vo/halloween_boss/knight_alert.mp3"
#define HHHAttack                 "vo/halloween_boss/knight_attack"

#define HHHTheme                "ui/holiday/gamestartup_halloween.mp3"

// Unused
//#define AxeModel                "models/weapons/c_models/c_headtaker/c_headtaker.mdl"


// Vagineer Files

// Model
#define VagineerModel             "models/player/saxton_hale/vagineer_v150.mdl"

// Materials
// None! He uses Engineer's stuff

// SFX
#define VagineerLastA             "saxton_hale/lolwut_0.wav"
#define VagineerRageSoundA         "saxton_hale/lolwut_2.wav"
#define VagineerRageSoundB        "saxton_hale/vagineer_responce_rage_3.wav"
#define VagineerStart             "saxton_hale/lolwut_1.wav"
#define VagineerKSpree            "saxton_hale/lolwut_3.wav"
#define VagineerKSpree2         "saxton_hale/lolwut_4.wav"
#define VagineerKSpree3         "saxton_hale/vagineer_responce_taunt_6.wav"
#define VagineerHit             "saxton_hale/lolwut_5.wav"

//===New Vagineer's responces===
#define VagineerRoundStart        "saxton_hale/vagineer_responce_intro.wav"
#define VagineerJump            "saxton_hale/vagineer_responce_jump_"         //    1-2
#define VagineerRageSound2        "saxton_hale/vagineer_responce_rage_"         //    1-4
#define VagineerKSpreeNew         "saxton_hale/vagineer_responce_taunt_"        //    1-5
#define VagineerFail            "saxton_hale/vagineer_responce_fail_"         //    1-2
#define VagineerSAStart            "saxton_hale/vagineer_is_hungry.wav"
#define VagineerStabbed            "saxton_hale/vagineer_stabbed_1.wav"

// Unused
//#define VagineerModel             "models/player/saxton_hale/vagineer_v150.mdl"
//#define WrenchModel             "models/weapons/w_models/w_wrench.mdl"


#if defined EASTER_BUNNY_ON
// Easter Bunny Files

// Model
#define BunnyModel                "models/player/saxton_hale/easter_demo.mdl"
#define EggModel                "models/player/saxton_hale/w_easteregg.mdl"

// Materials
char BunnyMaterials[][] = {
    "materials/models/player/easter_demo/demoman_head_red.vmt",
    "materials/models/player/easter_demo/easter_body.vmt",
    "materials/models/player/easter_demo/easter_body.vtf",
    "materials/models/player/easter_demo/easter_rabbit.vmt",
    "materials/models/player/easter_demo/easter_rabbit.vtf",
    "materials/models/player/easter_demo/easter_rabbit_normal.vtf",
    "materials/models/player/easter_demo/eyeball_r.vmt"
    // "materials/models/player/easter_demo/demoman_head_blue_invun.vmt", // This is for the new version of easter demo which ASH isn't using
    // "materials/models/player/easter_demo/demoman_head_red_invun.vmt",
    // "materials/models/player/easter_demo/easter_rabbit_blue.vmt",
    // "materials/models/player/easter_demo/easter_rabbit_blue.vtf",
    // "materials/models/player/easter_demo/easter_rabbit_invun.vmt",
    // "materials/models/player/easter_demo/easter_rabbit_invun.vtf",
    // "materials/models/player/easter_demo/easter_rabbit_invun_blue.vmt",
    // "materials/models/player/easter_demo/easter_rabbit_invun_blue.vtf",
    // "materials/models/player/easter_demo/eyeball_invun.vmt"
};

// SFX
char BunnyWin[][] = {
    "vo/demoman_gibberish01.mp3",
    "vo/demoman_gibberish12.mp3",
    "vo/demoman_cheers02.mp3",
    "vo/demoman_cheers03.mp3",
    "vo/demoman_cheers06.mp3",
    "vo/demoman_cheers07.mp3",
    "vo/demoman_cheers08.mp3",
    "vo/taunts/demoman_taunts12.mp3"
};

char BunnyJump[][] = {
    "vo/demoman_gibberish07.mp3",
    "vo/demoman_gibberish08.mp3",
    "vo/demoman_laughshort01.mp3",
    "vo/demoman_positivevocalization04.mp3"
};

char BunnyRage[][] = {
    "vo/demoman_positivevocalization03.mp3",
    "vo/demoman_dominationscout05.mp3",
    "vo/demoman_cheers02.mp3"
};

char BunnyFail[][] = {
    "vo/demoman_gibberish04.mp3",
    "vo/demoman_gibberish10.mp3",
    "vo/demoman_jeers03.mp3",
    "vo/demoman_jeers06.mp3",
    "vo/demoman_jeers07.mp3",
    "vo/demoman_jeers08.mp3"
};

char BunnyKill[][] = {
    "vo/demoman_gibberish09.mp3",
    "vo/demoman_cheers02.mp3",
    "vo/demoman_cheers07.mp3",
    "vo/demoman_positivevocalization03.mp3"
};

char BunnySpree[][] = {
    "vo/demoman_gibberish05.mp3",
    "vo/demoman_gibberish06.mp3",
    "vo/demoman_gibberish09.mp3",
    "vo/demoman_gibberish11.mp3",
    "vo/demoman_gibberish13.mp3",
    "vo/demoman_autodejectedtie01.mp3"
};

char BunnyLast[][] = {
    "vo/taunts/demoman_taunts05.mp3",
    "vo/taunts/demoman_taunts04.mp3",
    "vo/demoman_specialcompleted07.mp3"
};

char BunnyPain[][] = {
    "vo/demoman_sf12_badmagic01.mp3",
    "vo/demoman_sf12_badmagic07.mp3",
    "vo/demoman_sf12_badmagic10.mp3"
};

char BunnyStart[][] = {
    "vo/demoman_gibberish03.mp3",
    "vo/demoman_gibberish11.mp3"
};

char BunnyRandomVoice[][] = {
    "vo/demoman_positivevocalization03.mp3",
    "vo/demoman_jeers08.mp3",
    "vo/demoman_gibberish03.mp3",
    "vo/demoman_cheers07.mp3",
    "vo/demoman_sf12_badmagic01.mp3",
    "vo/burp02.mp3",
    "vo/burp03.mp3",
    "vo/burp04.mp3",
    "vo/burp05.mp3",
    "vo/burp06.mp3",
    "vo/burp07.mp3"
};

// Unused
//#define ReloadEggModel            "models/player/saxton_hale/c_easter_cannonball.mdl"
#endif

char ScoutRandomScream[][] = {
    "vo/scout_award05.mp3",
    "vo/scout_award07.mp3",
    "vo/scout_domination20.mp3",
    "vo/scout_dominationsol06.mp3",
    "vo/scout_laughhappy02.mp3",
    "vo/scout_laughlong02.mp3",
    "vo/scout_meleedare06.mp3",
    "vo/scout_mvm_loot_rare07.mp3",
    "vo/scout_mvm_loot_rare08.mp3",
    "vo/scout_revenge04.mp3",
    "vo/scout_revenge08.mp3",
    "vo/scout_sf12_goodmagic07.mp3",
    "vo/scout_sf13_magic_reac03.mp3",
    "vo/scout_sf13_magic_reac04.mp3",
    "vo/scout_sf13_magic_reac05.mp3",
    "vo/taunts/scout_taunts02.mp3",
    "vo/taunts/scout_taunts05.mp3",
    "vo/taunts/scout_taunts06.mp3",
    "vo/taunts/scout_taunts09.mp3",
    "vo/taunts/scout_taunts18.mp3",
};

char SpyRandomScream[][] = {
    "vo/spy_sf13_influx_big01.mp3",
    "vo/spy_sf13_influx_big02.mp3",
    "vo/spy_sf13_round_start06.mp3",
    "vo/compmode/cm_spy_matchwon_12.mp3",
};

char SpyRandomScream2[][] = {
    "vo/compmode/cm_spy_pregamefirst_10.mp3",
    "vo/compmode/cm_spy_pregamefirst_12.mp3",
    "vo/compmode/cm_spy_pregamelostlast_03.mp3",
    "vo/compmode/cm_spy_pregamewonlast_07.mp3",
};

char ScoutRandomScream2[][] = {
    "vo/scout_apexofjump01.mp3",
    "vo/scout_apexofjump02.mp3",
    "vo/scout_apexofjump05.mp3",
    "vo/scout_autocappedcontrolpoint01.mp3",
    "vo/scout_award01.mp3",
    "vo/scout_award05.mp3",
    "vo/scout_domination06.mp3",
    "vo/scout_domination10.mp3",
    "vo/scout_domination17.mp3",
    "vo/scout_invinciblechgunderfire02.mp3",
    "vo/scout_laughevil02.mp3",
    "vo/scout_laughhappy02.mp3",
    "vo/scout_misc09.mp3",
    "vo/scout_mvm_loot_rare01.mp3",
    "vo/scout_sf13_influx_small02.mp3",
    "vo/scout_stunballhit16.mp3",
    "vo/scout_triplejump02.mp3",
};

char MedicRandomScream[][] = {
    "vo/medic_hat_taunts02.mp3",
    "vo/medic_hat_taunts03.mp3",
    "vo/medic_laughevil05.mp3",
    "vo/medic_laughhappy01.mp3",
    "vo/medic_laughhappy02.mp3",
    "vo/medic_mvm_get_upgrade01.mp3",
    "vo/medic_mvm_get_upgrade02.mp3",
    "vo/medic_mvm_get_upgrade03.mp3",
    "vo/medic_mvm_heal_shield01.mp3",
    "vo/medic_mvm_heal_shield04.mp3",
    "vo/medic_mvm_resurrect03.mp3",
    "vo/medic_mvm_wave_end01.mp3",
    "vo/medic_sf12_badmagic08.mp3",
    "vo/medic_sf12_badmagic09.mp3",
    "vo/medic_sf12_goodmagic01.mp3",
    "vo/medic_sf13_influx_big02.mp3",
    "vo/medic_sf13_magic_reac01.mp3",
    "vo/medic_specialcompleted02.mp3",
    "vo/medic_specialcompleted10.mp3",
    "vo/medic_specialcompleted11.mp3",
    "vo/medic_weapon_taunts01.mp3",
    "vo/medic_weapon_taunts02.mp3",
};

// END FILE DEFINTIONS

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1
int OtherTeam = 2;
int HaleTeam = 3;
int HaleKiller = 0;
int ASHRoundState = ASHRState_Disabled;
int playing;
int healthcheckused;
int RedAlivePlayers;
int RoundCount;
int Special;
int Incoming;
//int TEMP_SpyCaDTimer[MAXPLAYERS+1];
int TEMP_SpySaPTimer[MAXPLAYERS+1];
int g_iOffsetModelScale;
//bool g_bScoped[MAXPLAYERS+1];
bool BlockDamage[MAXPLAYERS+1];
int AQUACURE_EntShield[MAXPLAYERS+1];
int g_iFidovskiyFix[MAXPLAYERS+1];
int g_iAlphaSpys[MAXPLAYERS+1];
bool g_bAlphaSpysAllow[MAXPLAYERS+1][2];
bool g_bSpySwitchAllow[MAXPLAYERS+1];
bool g_bAlphaSpyDelay[MAXPLAYERS+1];
bool g_bProtectedShield[MAXPLAYERS+1];
int g_iTauntedSpys[MAXPLAYERS+1];
int g_iPlayerDesiredFOV[MAXPLAYERS+2];
Handle g_iTimerList[MAXPLAYERS+1];
Handle g_iTimerList_Alpha[MAXPLAYERS+1];
Handle g_iTimerList_Switch[MAXPLAYERS+1];
Handle g_iTimerList_Repeat[MAXPLAYERS+1][2];
float g_fStickyExplodeTime[4096];
//int g_iJarateRageMinus[MAXPLAYERS+1];
// bool AQUACURE_Available = true;
bool dispenserEnabled[MAXPLAYERS+1];
// int ClientsHealth[MAXPLAYERS+1];
Handle g_CTFGrenadeDetonate;
#define _TFCond(%0) view_as<TFCond>(%0)

bool g_bReloadASHOnRoundEnd = false;

// UPD: 12.11.2015
// SPELLS DEFINES
#define FIREBALL    0   // Done
#define BATS        1   // Done
#define PUMPKIN     2   // Done
#define TELE        3   // Done
#define LIGHTNING   4   // Done
#define BOSS        5   // Done
#define METEOR      6   // Done
#define ZOMBIEH     7   // Done
#define ZOMBIE      8
#define PUMPKIN2    9

bool plManmelterBlock[MAXPLAYERS+1] = false; 	// UPD: 28.01.2016
bool plSteelBlock[MAXPLAYERS+1] = false; 		// Heavy Nerf: 18.11.2016
bool g_bGod[MAXPLAYERS+1] = false;
int FakeKill_Goomba;
int plManmelterUsed[MAXPLAYERS+1] = 0;
int IronBomberMode[MAXPLAYERS+1] = 0;
bool PhlogMode[MAXPLAYERS+1] = false;
int g_iFreezePhlogPar = 0;
bool g_isVictimFrozen[MAXPLAYERS+1] = false;
int iShivInv[MAXPLAYERS+1] = 0;
bool isStunnedBlock[MAXPLAYERS+1] = false;
bool isHaleStunBanned = false;
int NeedlyUnstans = 0;
bool isHaleNeedManyDamage = false;
#define ManmelterSound        "player/flame_out.wav"
float DeadRinger_ManualActivation[MAXPLAYERS+1] = 0.0;

// UPD: 01.04.2016
bool InfectPlayers[MAXPLAYERS+1] = false;
bool ImmunityClient[MAXPLAYERS+1] = false;
//int spyTimeInvis[MAXPLAYERS+1] = 0;
int SniperActivity[MAXPLAYERS+1] = 0;
int SniperNoMimoShoots[MAXPLAYERS+1] = 0;
int SpecialWeapon = -1;
int Vitasaw_ExecutionTimes = 0;
int BuffTime[MAXPLAYERS+1] = 0;

// KOSTYL TIME
bool ManmelterBan[MAXPLAYERS+1] = false;

// STATS SCREEN UPDATE
enum ASHStatsEnum {
    Rages,
    SpecialAbilities,
    StunsNum,
    HeadShots,
    BackStabs,
    UberCharges
}

int ASHStats[ASHStatsEnum];
int VagineerTime_GH;
// End UPD: 01.04.2016

// UPD: 19.07.2016
bool Soldier_EscapePlan_ModeNoHeal[MAXPLAYERS+1] = false;
Handle Soldier_EscapePlan_ModeNoHeal_PARTICLE[MAXPLAYERS+1];
float RCPressed[MAXPLAYERS+1] = 0.0;
float SpecialHintsTime[MAXPLAYERS+1] = 0.0;
//float SpecialHintEq[MAXPLAYERS+1] = 3.0;
enum SpecialHintsEnum {
    SpecialHint_None = -1,
    TF2Soldier_EscapePlan_NewState = 1
}

SpecialHintsEnum SpecialHints[MAXPLAYERS+1] = SpecialHint_None;

// Meet the new boss: Agent
char Agent_RoundStart[][] = {
    "vo/spy_tietaunt03.mp3",
    "vo/spy_tietaunt07.mp3",
    "vo/spy_tietaunt08.mp3"
};

char Agent_KSpree[][] = {
    "vo/spy_specialcompleted06.mp3",
    "vo/spy_specialcompleted10.mp3",
    "vo/spy_specialcompleted12.mp3",
    "vo/spy_stabtaunt02.mp3",
    "vo/spy_stabtaunt04.mp3",
    "vo/spy_stabtaunt07.mp3"
};

char Agent_Win[][] = {
    "vo/spy_dominationscout08.mp3",
    "vo/spy_dominationscout01.mp3",
    "vo/spy_dominationscout07.mp3",
    "vo/spy_dominationpyro02.mp3"
};

char Agent_Fail[][] = {
    "vo/spy_paincrticialdeath01.mp3",
    "vo/spy_paincrticialdeath02.mp3",
    "vo/spy_paincrticialdeath03.mp3"
};

char Agent_Backstabbed[][] = {
    "vo/spy_negativevocalization02.mp3",
    "vo/spy_negativevocalization04.mp3",
    "vo/spy_negativevocalization06.mp3",
    "vo/spy_sf12_scared01.mp3",
    "vo/spy_sf13_magic_reac03.mp3"
};

char Agent_Circumfused[][] = {
    "vo/spy_jaratehit01.mp3",
    "vo/spy_jaratehit02.mp3",
    "vo/spy_jaratehit03.mp3",
    "vo/spy_jaratehit06.mp3",
    "vo/spy_sf13_magic_reac06.mp3"
};

char Agent_Jump[][] = {
    "vo/spy_rpscountgo01.mp3",
    "vo/taunts/spy/spy_taunt_exert_14.mp3",
    "vo/taunts/spy/spy_taunt_exert_16.mp3",
    "vo/taunts/spy/spy_taunt_head_exert_01.mp3"
};

char Agent_LaughInvis[][] = {
    "vo/spy_laughshort02.mp3",
    "vo/spy_laughshort03.mp3",
    "vo/spy_laughshort05.mp3",
    "vo/spy_laughshort06.mp3"
};

char Agent_SpecialAbility_Zipper[][] = {
    "weapons/capper_shoot.wav",
    "mvm/mvm_tele_deliver.wav"
};

char Agent_KillScout[][] = {
    "vo/spy_dominationscout03.mp3",
    "vo/spy_dominationscout04.mp3",
    "vo/spy_dominationscout06.mp3"
};

char Agent_KillPyro[][] = {
    "vo/spy_dominationpyro03.mp3",
    "vo/spy_dominationpyro04.mp3",
    "vo/spy_dominationpyro05.mp3"
};

char Agent_KillHeavy[][] = {
    "vo/spy_dominationheavy02.mp3",
    "vo/spy_dominationheavy03.mp3",
    "vo/spy_dominationheavy06.mp3"
};

char Agent_KillMedic[][] = {
    "vo/spy_dominationmedic02.mp3",
    "vo/spy_dominationmedic04.mp3",
    "vo/spy_dominationmedic05.mp3"
};

char Agent_KillSentry[] = "vo/spy_specialcompleted05.mp3";
char Agent_SpecialAbility_Start[] = "misc/rd_robot_explosion01.wav";
char Agent_SixHolograms[] = "vo/spy_dominationspy05.mp3";
char Agent_Rage[] = "vo/spy_revenge03.mp3";
char Agent_LastAlive[][] = {
    "vo/spy_laughhappy01.mp3",
    "vo/spy_stabtaunt08.mp3",
    "vo/spy_stabtaunt09.mp3",
    "vo/spy_stabtaunt11.mp3",
    "vo/spy_tietaunt04.mp3",
    "vo/spy_tietaunt09.mp3"
};
char Agent_Whistle[] = "vo/taunts/spy_taunts05.mp3";

// Model
char Agent_Model[] = "models/player/agent_v2/agent_2.mdl";

// Materials
char AgentMats[][] = {
    "materials/models/player/agent_1/eyeball_invun.vmt",
    "materials/models/player/agent_1/eyeball_l.vmt",
    "materials/models/player/agent_1/eyeball_r.vmt",
    "materials/models/player/agent_1/spy_blue.vmt",
    "materials/models/player/agent_1/spy_blue.vtf",
    "materials/models/player/agent_1/spy_blue_gib.vmt",
    "materials/models/player/agent_1/spy_blue_invun.vmt",
    "materials/models/player/agent_1/spy_hands_blue.vmt",
    "materials/models/player/agent_1/spy_hands_blue.vtf",
    "materials/models/player/agent_1/spy_hands_red.vmt",
    "materials/models/player/agent_1/spy_hands_red.vtf",
    "materials/models/player/agent_1/spy_head_blue.vmt",
    "materials/models/player/agent_1/spy_head_blue.vtf",
    "materials/models/player/agent_1/spy_head_blue_invun.vmt",
    "materials/models/player/agent_1/spy_head_red.vmt",
    "materials/models/player/agent_1/spy_head_red.vtf",
    "materials/models/player/agent_1/spy_head_red_invun.vmt",
    "materials/models/player/agent_1/spy_red.vmt",
    "materials/models/player/agent_1/spy_red.vtf",
    "materials/models/player/agent_1/spy_red_gib.vmt",
    "materials/models/player/agent_1/spy_red_invun.vmt",
};

// Vars
float InvisibleAgent;
float LastSound;
float AgentPreparedSoundLaugh;
int Holograms[MAXPLAYERS+1];
int Stun;
float TimeAbility;
int PrecachedLaserBeam;
int ShieldEnt;

#define ScoutSodaPopper_Sound        "misc/halloween/merasmus_disappear.wav"

bool IsNotNeedRemoveInvisible = false;
int HaleState = 1;

Damage[TF_MAX_PLAYERS];
AirDamage[TF_MAX_PLAYERS]; // Air Strike
BasherDamage[TF_MAX_PLAYERS];
SpeedDamage[TF_MAX_PLAYERS];
PersDamage[TF_MAX_PLAYERS];
NatDamage[TF_MAX_PLAYERS];
HuoDamage[TF_MAX_PLAYERS];
TomDamage[TF_MAX_PLAYERS]; 
BetDamage[TF_MAX_PLAYERS];
AmpDefend[TF_MAX_PLAYERS];
bushJUMP[MAXPLAYERS+1];
bushTIME[MAXPLAYERS+1];
headmeter[TF_MAX_PLAYERS];
uberTarget[TF_MAX_PLAYERS];
#define ASHFLAG_HELPED            (1 << 0)
#define ASHFLAG_UBERREADY         (1 << 1)
#define ASHFLAG_NEEDSTODUCK (1 << 2)
#define ASHFLAG_BOTRAGE     (1 << 3)
#define ASHFLAG_CLASSHELPED (1 << 4)
#define ASHFLAG_HASONGIVED    (1 << 5)
ASHFlags[TF_MAX_PLAYERS];
int Hale = -1;
int HaleHealthMax;
int HaleHealth;
int HaleHealthLast;
int HaleCharge = 0;
int HaleRage;
int NextHale;
float g_flStabbed;
float g_flMarketed;

float WeighDownTimer;
int KSpreeCount = 1;
float UberRageCount;
float GlowTimer;
bool bEnableSuperDuperJump;

bool bSpawnTeleOnTriggerHurt = false;
int HHHClimbCount;

Handle cvarVersion;
Handle cvarBuild;
Handle cvarHaleSpeed;
Handle cvarPointDelay;
Handle cvarRageDMG;
Handle cvarRageDist;
Handle cvarAnnounce;
Handle cvarSpecials;
Handle cvarEnabled;
Handle cvarAliveToEnable;
Handle cvarPointType;
Handle cvarCrits;
Handle cvarRageSentry;
Handle cvarFirstRound;
//Handle cvarDemoShieldCrits;
Handle cvarDisplayHaleHP;

Handle cvarEnableJumper;
//Handle cvarEnableCloak;
Handle cvarEnableSapper;

/*Handle cvarEnableCBS;
Handle cvarEnableHHH;
Handle cvarEnableBunny;
Handle cvarEnableVagineer;
Handle cvarEnableAgent;*/
Handle cvarEnableSecret1;

Handle cvarEnableSecretCheats;

Handle cvarTryhardDirecthit;
Handle cvarTryhardMachina;
/*Handle cvarTryhardLochnload;

Handle cvarSpecial;
Handle cvarSpecialRestrict;
Handle cvarSpecialBoston;
Handle cvarSpecialSoda;
Handle cvarSpecialBabyFace;
Handle cvarSpecialManmelter;
Handle cvarSpecialNatascha;
Handle cvarSpecialTomislav;
Handle cvarSpecialHuo;
Handle cvarSpecialBrassBeast;
Handle cvarSpecialBuffalo;
Handle cvarSpecialPistol;
Handle cvarSpecialVita;
Handle cvarSpecialAmputator;
Handle cvarSpecialVow;
Handle cvarSpecialSniperShield;
Handle cvarSpecialBazaar;
Handle cvarSpecialShiv;

Handle cvarSpecialBoss;
Handle cvarSpecialSaxton;
Handle cvarSpecialCBS;
Handle cvarSpecialHHH;
Handle cvarSpecialVagineer;
Handle cvarSpecialBunny;
Handle cvarSpecialAgent;
*/

Handle cvarHaleMinPlayersResetQ;

//Handle cvarEnableEurekaEffect;
Handle cvarForceHaleTeam;
Handle PointCookie;
Handle MusicCookie;
Handle VoiceCookie;
Handle ClasshelpinfoCookie;
Handle doorchecktimer;

Handle jumpHUD;
Handle rageHUD;
Handle healthHUD;
Handle infoHUD;
Handle soulsHUD;
Handle bushwackaHUD;
Handle BazaarBargainHUD;
Handle cheatsHUD;

bool g_bEnabled = false;
bool g_bAreEnoughPlayersPlaying = false;
float HaleSpeed = 340.0;
int PointDelay = 6;
int RageDMG = 3500;
int BasherDMG = 400;
int SpeedDMG = 650;
int SodaDMG = 750;
int PersDMG = 780;
int NatDMG = 325;
int HuoDMG = 700;
int AmpDEF = 400;
int TomDMG = 450;
int BetDMG = 400;
float RageDist = 800.0;
float Announce = 120.0;
bool bSpecials = true;
int AliveToEnable = 5;
int PointType = 0;
bool haleCrits = false;
/*bool bDemoShieldCrits = false;*/
bool bAlwaysShowHealth = true;
bool newRageSentry = true;
//Float:circuitStun = 0.0;
Handle MusicTimer;
int TeamRoundCounter;
int botqueuepoints = 0;
char currentmap[99];
bool checkdoors = false;
bool PointReady;
int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
float tf_scout_hype_pep_max;
int tf_dropped_weapon_lifetime;

// Cloak damage fixes
float tf_feign_death_activate_damage_scale;
float tf_feign_death_damage_scale;
float tf_stealth_damage_reduction;
float tf_feign_death_duration;
float tf_feign_death_speed_duration;

int defaulttakedamagetype;

// Medic Handles
Handle MedicRage_TimerHndl[TF_MAX_PLAYERS];
float MedicRage_TimerFloat[TF_MAX_PLAYERS];
Handle TimerMedic_UberCharge[MAXPLAYERS+1];

Handle OnHaleJump;
Handle OnHaleRage;
Handle OnHaleWeighdown;
Handle OnMusic;
Handle OnHaleNext;

//Handle hEquipWearable;
//Handle hSetAmmoVelocity;

/*Handle OnIsASHMap;
Handle OnIsEnabled;
Handle OnGetHale;
Handle OnGetTeam;
Handle OnGetSpecial;
Handle OnGetHealth;
Handle OnGetHealthMax;
Handle OnGetDamage;
Handle OnGetRoundState;*/

int SpecialHHH_Souls = 0; // UPD: 12.11.2015
int SpecialHale_RPSWins[MAXPLAYERS+1] = 0; // UPD: 25.12.2015
int SpecialSoldier_Airshot[MAXPLAYERS+1] = false; // UPD: 25.12.2015
int SpecialCrits_ForHale[MAXPLAYERS+1]; // UPD: 30.12.2015

// Bezzar Bargain. UPD: 25.12.2015
int BB_Sniper_Shots[MAXPLAYERS+1] = 0;
int BB_LastShotTime[MAXPLAYERS+1] = 0;
int BB_Sniper_ShootTime[MAXPLAYERS+1] = 0;

int SpecialDemo_Kostyl[MAXPLAYERS+1] = 0;

// Array with player last used weapons
int SpecialPlayers_LastActiveWeapons[MAXPLAYERS+1] = -1;

// Reworked Agent invis
float m_fAgent_InvisibleNext[MAXPLAYERS+1];

//bool ACH_Enabled;
public Plugin myinfo = {
    name           = "Advanced Saxton Hale",
    author         = "Rainbolt Dash, FlaminSarge, Chdata, nergal, fiagram, NITROYUASH, FeedBlack, CrazyHackGUT",
    description    = "RUUUUNN!! COWAAAARRDSS!",
    version        = PLUGINVERSION,
    url            = "https://forums.alliedmods.net/showthread.php?p=2167912",
};

// Check for whether or not optional plugins are running and relay that info to ASH.
#if defined _SteamWorks_Included
public void OnAllPluginsLoaded()
{
    g_bSteamWorksIsRunning    = LibraryExists("SteamWorks");
}
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("GetUserMessageType");
    MarkNativeAsOptional("PbSetInt");
    MarkNativeAsOptional("PbSetBool");
    MarkNativeAsOptional("PbSetString");
    MarkNativeAsOptional("PbAddString");

#if defined _SteamWorks_Included
    MarkNativeAsOptional("Steam_SetGameDescription");
#endif

    API_Init();

    return APLRes_Success;
}

char ASH_pluginname[PLATFORM_MAX_PATH];
int iHaleSpecialPower;

Handle s_hSpawnArray = null;

public bool HaleTargetFilter(char[] pattern, Handle clients)
{
    bool non = StrContains(pattern, "!", false) != -1;
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && FindValueInArray(clients, client) == -1) {
            if (g_bEnabled && client == Hale) {
                if (!non) {
                    PushArrayCell(clients, client);
                }
            } else if (non) {
                PushArrayCell(clients, client);
            }
        }
    }

    return true;
}

bool IsSaxtonHaleMap(bool forceRecalc = false)
{
    static bool found = false;
    static bool isASHMap = false;
    if (forceRecalc)
    {
        isASHMap = false;
        found = false;
    }
    if (!found)
    {
        char s[PLATFORM_MAX_PATH];
        GetCurrentMap(currentmap, sizeof(currentmap));
        if (FileExists("bNextMapToHale"))
        {
            isASHMap = true;
            found = true;
            return true;
        }
        BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/saxton_hale/saxton_hale_maps.cfg");
        if (!FileExists(s))
        {
            LogError("[ASH] Unable to find %s, disabling plugin.", s);
            isASHMap = false;
            found = true;
            return false;
        }
        Handle fileh = OpenFile(s, "r");
        if (fileh == null)
        {
            LogError("[ASH] Error reading maps from %s, disabling plugin.", s);
            isASHMap = false;
            found = true;
            return false;
        }
        int pingas = 0;
        while (!IsEndOfFile(fileh) && ReadFileLine(fileh, s, sizeof(s)) && (pingas < 100))
        {
            pingas++;
            if (pingas == 100)
                LogError("[VS Saxton Hale] Breaking infinite loop when trying to check the map.");
            Format(s, strlen(s)-1, s);
            if (strncmp(s, "//", 2, false) == 0) continue;
            if ((StrContains(currentmap, s, false) != -1) || (StrContains(s, "all", false) == 0))
            {
                CloseHandle(fileh);
                isASHMap = true;
                found = true;
                return true;
            }
        }
        CloseHandle(fileh);
    }
    return isASHMap;
}

bool MapHasMusic(bool forceRecalc = false)
{
    static bool hasMusic;
    static bool found = false;
    if (forceRecalc)
    {
        found = false;
        hasMusic = false;
    }
    if (!found)
    {
        int i = -1;
        char name[64];
        while ((i = FindEntityByClassname2(i, "info_target")) != -1)
        {
            GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
            if (strcmp(name, "hale_no_music", false) == 0) hasMusic = true;
        }
        found = true;
    }
    return hasMusic;
}

bool CheckToChangeMapDoors()
{
    char s[PLATFORM_MAX_PATH];
    GetCurrentMap(currentmap, sizeof(currentmap));
    checkdoors = false;
    BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/saxton_hale/saxton_hale_doors.cfg");
    if (!FileExists(s))
    {
        if (strncmp(currentmap, "vsh_lolcano_pb1", 15, false) == 0)
            checkdoors = true;
        return;
    }
    Handle fileh = OpenFile(s, "r");
    if (fileh == null)
    {
        if (strncmp(currentmap, "vsh_lolcano_pb1", 15, false) == 0)
            checkdoors = true;
        return;
    }
    while (!IsEndOfFile(fileh) && ReadFileLine(fileh, s, sizeof(s)))
    {
        Format(s, strlen(s)-1, s);
        if (strncmp(s, "//", 2, false) == 0) continue;
        if (StrContains(currentmap, s, false) != -1 || StrContains(s, "all", false) == 0)
        {
            CloseHandle(fileh);
            checkdoors = true;
            return;
        }
    }
    CloseHandle(fileh);
}

void CheckToTeleportToSpawn()
{
    bSpawnTeleOnTriggerHurt = true;
}

bool CheckNextSpecial()
{
    if (!bSpecials)
    {
        Special = ASHSpecial_Hale;
        
        if (Incoming == ASHSpecial_Hale) {
            int rndm = GetRandomInt(0, 500);
            if (rndm < ASH_SECRETBOSS_MINRAND || rndm > ASH_SECRETBOSS_MAXRAND && GetConVarInt(cvarEnableSecret1)) Special = ASHSpecial_MiniHale;
        }
        
        return true;
    }
    if (Incoming != ASHSpecial_None)
    {
        Special = Incoming;
        
        if (Incoming == ASHSpecial_Hale) {
            int rndm = GetRandomInt(0, 500);
            if (rndm < ASH_SECRETBOSS_MINRAND || rndm > ASH_SECRETBOSS_MAXRAND && GetConVarInt(cvarEnableSecret1)) Special = ASHSpecial_MiniHale;
        }
        
        Incoming = ASHSpecial_None;
        return true;
    }
    while (Incoming == ASHSpecial_None || (Special && Special == Incoming))
    {
        Incoming = GetRandomInt(0, 8);
        if (Special != ASHSpecial_Hale && !GetRandomInt(0, 6)) Incoming = ASHSpecial_Hale;
        else
        {
            switch (Incoming)
            {
                case 1: Incoming = ASHSpecial_Vagineer;
                case 2: Incoming = ASHSpecial_HHH;
                case 3: Incoming = ASHSpecial_CBS;
#if defined EASTER_BUNNY_ON
                case 4: Incoming = ASHSpecial_Bunny;
#endif
                case 5: Incoming = ASHSpecial_Agent;
                default: Incoming = ASHSpecial_Hale;
            }
            if (IsDate(Month_Dec, 15) && !GetRandomInt(0, 7)) Incoming = ASHSpecial_CBS; //IsDecemberHoliday()
#if defined EASTER_BUNNY_ON
            if (IsDate(Month_Mar, 25, Month_Apr, 20) && !GetRandomInt(0, 7)) Incoming = ASHSpecial_Bunny; //IsEasterHoliday()
#endif
        }
    }
    
    // Secret boss
    if (Incoming == ASHSpecial_Hale) {
        int rndm = GetRandomInt(0, 500);
        if (rndm < ASH_SECRETBOSS_MINRAND || rndm > ASH_SECRETBOSS_MAXRAND && GetConVarInt(cvarEnableSecret1)) Special = ASHSpecial_MiniHale;
        else Special = ASHSpecial_Hale;
    } else Special = Incoming;
    Incoming = ASHSpecial_None;
    return true;
}

public Action SecretHaleTimer(Handle hTimer) {
    EmitSoundToAll("saxton_hale/secret_completed.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
    EmitSoundToAll("saxton_hale/secret_completed.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
    EmitSoundToAll("saxton_hale/secret_completed.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
    
    for (int client = 1; client<=MAXPLAYERS; client++) {
        if (!IsValidClient(client)) continue;

        SetHudTextParams(-1.0, 0.15, 7.5, 255, 64, 64, 255);
        ShowHudText(client, -1, "%t", "ash_secretHale_summoned");
    }
}

bool FixUnbalancedTeams()
{
    if (GetTeamClientCount(HaleTeam) <= 0 || GetTeamClientCount(OtherTeam) <= 0)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                ChangeTeam(i, i==Hale?HaleTeam:OtherTeam);
            }
        }
        return true;
    }
    return false;
}

void SearchForItemPacks()
{
    bool foundAmmo = false;
    bool foundHealth = false;
    int ent = -1;
    float pos[3];
    while ((ent = FindEntityByClassname2(ent, "item_ammopack_full")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);

        if (g_bEnabled)
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
            AcceptEntityInput(ent, "Kill");
            int ent2 = CreateEntityByName("item_ammopack_small");
            TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(ent2);
            SetEntProp(ent2, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
            foundAmmo = true;
        }
        
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "item_ammopack_medium")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);

        if (g_bEnabled)
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
            AcceptEntityInput(ent, "Kill");
            int ent2 = CreateEntityByName("item_ammopack_small");
            TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(ent2);
            SetEntProp(ent2, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
        }
        
        foundAmmo = true;
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "Item_ammopack_small")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
        foundAmmo = true;
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "item_healthkit_small")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
        foundHealth = true;
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "item_healthkit_medium")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
        foundHealth = true;
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "item_healthkit_full")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
        foundHealth = true;
    }
    if (!foundAmmo) SpawnRandomAmmo();
    if (!foundHealth) SpawnRandomHealth();
}

void SpawnRandomAmmo()
{
    int iEnt = MaxClients + 1;
    float vPos[3];
    float vAng[3];
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        if (GetRandomInt(0, 4))
        {
            continue;
        }

        // Technically you'll never find a map without a spawn point.
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
        GetEntPropVector(iEnt, Prop_Send, "m_angRotation", vAng);

        int iEnt2 = !GetRandomInt(0, 3) ? CreateEntityByName("item_ammopack_medium") : CreateEntityByName("item_ammopack_small");
        TeleportEntity(iEnt2, vPos, vAng, NULL_VECTOR);
        DispatchSpawn(iEnt2);
        SetEntProp(iEnt2, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
    }
}

void SpawnRandomHealth()
{
    int iEnt = MaxClients + 1;
    float vPos[3];
    float vAng[3];
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        if (GetRandomInt(0, 4))
        {
            continue;
        }

        // Technically you'll never find a map without a spawn point.
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
        GetEntPropVector(iEnt, Prop_Send, "m_angRotation", vAng);

        int iEnt2 = !GetRandomInt(0, 3) ? CreateEntityByName("item_healthkit_medium") : CreateEntityByName("item_healthkit_small");
        TeleportEntity(iEnt2, vPos, vAng, NULL_VECTOR);
        DispatchSpawn(iEnt2);
        SetEntProp(iEnt2, Prop_Send, "m_iTeamNum", g_bEnabled?OtherTeam:0, 4);
    }
}

public Action Timer_EnableCap(Handle timer)
{
    if (ASHRoundState == ASHRState_Disabled)
    {
        SetControlPoint(true);
        if (checkdoors)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
            {
                AcceptEntityInput(ent, "Open");
                AcceptEntityInput(ent, "Unlock");
            }
            if (doorchecktimer == null)
                doorchecktimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        }
    }
}

public Action Timer_CheckDoors(Handle hTimer)
{
    if (!checkdoors)
    {
        doorchecktimer = null;
        return Plugin_Stop;
    }

    if ((!g_bEnabled && ASHRoundState != ASHRState_Disabled) || (g_bEnabled && ASHRoundState != ASHRState_Active)) return Plugin_Continue;
    int ent = -1;
    while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
    {
        AcceptEntityInput(ent, "Open");
        AcceptEntityInput(ent, "Unlock");
    }
    return Plugin_Continue;
}

public void CheckArena()
{
    if (PointType)
    {
        SetArenaCapEnableTime(float(45 + PointDelay * (playing - 1)));
    }
    else
    {
        SetArenaCapEnableTime(0.0);
        SetControlPoint(false);
    }
}

public int numHaleKills = 0;

public Action Timer_NineThousand(Handle timer)
{
    EmitSoundToAll("saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), _, _, NULL_VECTOR, false, 0.0);
    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), _, _, NULL_VECTOR, false, 0.0);
    EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), _, _, NULL_VECTOR, false, 0.0);
}

public Action Timer_CalcScores(Handle timer)
{
    CalcScores();
}

void CalcScores()
{
    int j;
    int damage;
    
    //bool spec = GetConVarBool(cvarForceSpecToHale);
    botqueuepoints += 5;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            damage = Damage[i];
            Handle aevent = CreateEvent("player_escort_score", true);
            SetEventInt(aevent, "player", i);
            for (j = 0; damage - 600 > 0; damage -= 600, j++){}
            SetEventInt(aevent, "points", j);
            FireEvent(aevent);
            if (i == Hale)
            {
                if (IsFakeClient(Hale)) botqueuepoints = 0;
                else SetClientQueuePoints(i, 0);
            }
            else if (!IsFakeClient(i) && (GetEntityTeamNum(i) > view_as<int>(TFTeam_Spectator)))
            {
                CPrintToChat(i, "{ash}[ASH]{default} %t", "vsh_add_points", 10);
                SetClientQueuePoints(i, GetClientQueuePoints(i)+10);
            }
        }
    }
}

public Action StartResponceTimer(Handle hTimer)
{
    char s[PLATFORM_MAX_PATH];
    float pos[3];
    switch (Special)
    {
        case ASHSpecial_Agent:
        {
            strcopy(s, PLATFORM_MAX_PATH, Agent_RoundStart[GetRandomInt(0,2)]);
        }
#if defined EASTER_BUNNY_ON
        case ASHSpecial_Bunny:
        {
            strcopy(s, PLATFORM_MAX_PATH, BunnyStart[GetRandomInt(0, sizeof(BunnyStart)-1)]);
        }
#endif
        case ASHSpecial_Vagineer:
        {
            if (!GetRandomInt(0, 1))
                strcopy(s, PLATFORM_MAX_PATH, VagineerStart);
            else
                strcopy(s, PLATFORM_MAX_PATH, VagineerRoundStart);
        }
        case ASHSpecial_HHH: Format(s, PLATFORM_MAX_PATH, "ui/halloween_boss_summoned_fx.wav");
        case ASHSpecial_CBS: strcopy(s, PLATFORM_MAX_PATH, CBS0);
        default:
        {
            if (!GetRandomInt(0, 1))
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, GetRandomInt(1, 5));
            else
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, GetRandomInt(1, 5));
        }
    }
    if (Special != ASHSpecial_Agent) {
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, false, 0.0);
        EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, false, 0.0);
    } else {
        PlaySoundForPlayers(s);
        PlaySoundForPlayers(s);
    }
    if (Special == ASHSpecial_CBS)
    {
        EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
    }
    return Plugin_Continue;
}

#define LoopPlayers(%0)    for (int %0 = MaxClients; %0 != 0; --%0) if (IsClientInGame(%0))

public Action StartHaleTimer(Handle hTimer)
{
    //CreateTimer(5.0, AddPrimary, _, TIMER_REPEAT);
    
    LoopPlayers(iClient)
    {
        if(TF2_GetPlayerClass(iClient) == TFClass_Engineer)
        {
            TF2_RegeneratePlayer(iClient);
        }
        /*if((GetIndexOfWeaponSlot(iClient, TFWeaponSlot_Melee) == 225 || GetIndexOfWeaponSlot(iClient, TFWeaponSlot_Melee) == 574) && TF2_GetPlayerClass(iClient) == TFClass_Spy)
        {
            g_iAlphaSpys[iClient] = 30;
            g_bAlphaSpyDelay[iClient] = true;
        }
        else
        {
            SetPlayerRenderAlpha(iClient, 255);
        }*/
        
        if (BushmanRulesRound && IsPlayerAlive(iClient)) {
            TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Primary);
        }
        if (IsPlayerAlive(iClient))
        {
            g_iTauntedSpys[iClient] = 0;
            g_iAlphaSpys[iClient] = 30;
            g_bAlphaSpysAllow[iClient][0] = false;
            g_bAlphaSpysAllow[iClient][1] = true;
            g_bProtectedShield[iClient] = true;
            g_iAlphaSpys[iClient] = 30;
            g_bAlphaSpyDelay[iClient] = true;
        }
        /*if (TF2_GetPlayerClass(iClient) == TFClass_Spy)
        {
            int iSlot = GetIndexOfWeaponSlot(iClient, TFWeaponSlot_Melee);
            switch(iSlot)
            {
                case 4, 194, 638, 665, 727, 794, 803, 883, 892, 901, 910, 959, 968, 15080, 15094, 15095, 15096, 15118, 15119, 15143, 15144:
                {
                    SetEntProp(iClient, Prop_Send, "m_CollisionGroup", 1);
                }
                default:
                {
                    if (GetEntProp(iClient, Prop_Send, "m_CollisionGroup") != 5)
                    {
                        CreateTimer(0.1, DisableCollision, iClient);
                    }
                }
            }
        }
        else
        {
            CreateTimer(0.1, DisableCollision, iClient);
        }*/
    }
    
    CreateTimer(0.1, GottamTimer);
    if (!IsClientInGame(Hale))
    {
        ASHRoundState = ASHRState_End;
        return Plugin_Continue;
    }
    FixUnbalancedTeams();
    if (!IsPlayerAlive(Hale))
    {
        TF2_RespawnPlayer(Hale);
    }
    playing = 0; // nergal's FRoG fix
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client) || client == Hale) continue;
        playing++;
        CreateTimer(0.2, MakeNoHale, GetClientUserId(client));
    }
    HaleHealthMax = RoundFloat(Pow(((((Special != ASHSpecial_MiniHale)?835.8:600.0) + playing)*(playing - 1)), 1.0341));

    HaleHealthMax += 2048;

    if (HaleHealthMax <= 0) // Rare glitches can cause his health to become negative.
    {
        HaleHealthMax = 2048;
    }

    UTIL_SetMaxHealth(Hale, HaleHealthMax);
    SetEntProp(Hale, Prop_Data, "m_iMaxHealth", HaleHealthMax);
    SetEntityHealth(Hale, HaleHealthMax);
    HaleHealth = HaleHealthMax;
    HaleHealthLast = HaleHealth;
    CreateTimer(0.2, CheckAlivePlayers);
    NeedlyUnstans = ManmelterHUD_GetNeedUnstans();
    CreateTimer(0.2, HaleTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    if (Special == ASHSpecial_Agent) CreateTimer(0.2, HologramsTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.2, StartRound);
    CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    int iConnTracker = UTIL_FindConnTracker(Hale);
    if (iConnTracker != -1) {
        AcceptEntityInput(iConnTracker, "Kill");
    }
    if (ullapoolWarRound)
        CreateTimer(0.3, UllapoolWarNotify);
    if (BushmanRulesRound)
        CreateTimer(0.3, BushmanRulesNotify);
    CreateTimer(1.0, BeggarBazaarTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(2.0, ManmelterTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(4.0, BushwackaTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(1.0, BushwackaTimerTWO, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    isHaleStunBanned = false;
    if (!PointType && playing > GetConVarInt(cvarAliveToEnable))
    {
        SetControlPoint(false);
    }
    if (ASHRoundState == ASHRState_Waiting)
    {
        CreateTimer(2.0, Timer_MusicPlay, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

public Action UllapoolWarNotify(Handle hTimer) {
    PlaySoundForPlayers("saxton_hale/demowar.mp3");
    
    for (int client = 1; client<=MAXPLAYERS; client++) {
        if (!IsValidClient(client)) continue;

        SetHudTextParams(-1.0, 0.15, 7.5, 255, 64, 64, 255);
        ShowHudText(client, -1, "%t", "ash_secretMode_enabled");
    }
}

public Action BushmanRulesNotify(Handle hTimer) {
    PlaySoundForPlayers("saxton_hale/secret_completed.wav");
    
    for (int client = 1; client<=MAXPLAYERS; client++) {
        if (!IsValidClient(client)) continue;

        SetHudTextParams(-1.0, 0.15, 7.5, 255, 64, 64, 255);
        ShowHudText(client, -1, "%t", "ash_secretMode2_enabled");
    }
}

public Action BushwackaTimer(Handle TimerHndl)
{
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (client != Hale && IsClientInGame(client) && GetEntityTeamNum(client) == OtherTeam)
        {
            if (TF2_GetPlayerClass(client) == TFClass_Sniper && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 232 && bushTIME[client] == 0 && bushJUMP[client] != 0) bushJUMP[client]--;
        }
    }
    return Plugin_Continue;
}

public Action BushwackaTimerTWO(Handle TimerHndl)
{
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (client != Hale && IsClientInGame(client) && GetEntityTeamNum(client) == OtherTeam)
        {
            if (TF2_GetPlayerClass(client) == TFClass_Sniper && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 232 && bushTIME[client] != 0)
            {
                bushTIME[client]--;
                if (bushTIME[client] == 0) bushJUMP[client] = 0;
            }
        }
    }
    return Plugin_Continue;
}

public Action Timer_MusicPlay(Handle timer)
{
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    char sound[PLATFORM_MAX_PATH] = "";
    float time = -1.0;
    ClearTimer(MusicTimer);
    if (MapHasMusic())
    {
        strcopy(sound, sizeof(sound), "");
        time = -1.0;
    }
    else
    {
        switch (Special)
        {
            case ASHSpecial_CBS:
            {
                strcopy(sound, sizeof(sound), CBSTheme);
                time = 137.0;
            }
            case ASHSpecial_HHH:
            {
                strcopy(sound, sizeof(sound), HHHTheme);
                time = 87.0;
            }
        }
    }
    Action act = Plugin_Continue;
    Call_StartForward(OnMusic);
    char sound2[PLATFORM_MAX_PATH];
    float time2 = time;
    strcopy(sound2, PLATFORM_MAX_PATH, sound);
    Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
    Call_PushFloatRef(time2);
    Call_Finish(act);
    switch (act)
    {
        case Plugin_Stop, Plugin_Handled:
        {
            strcopy(sound, sizeof(sound), "");
            time = -1.0;
        }
        case Plugin_Changed:
        {
            strcopy(sound, PLATFORM_MAX_PATH, sound2);
            time = time2;
        }
    }
    
    if (sound[0] != '\0')
    {
        EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    }
    
    if (time != -1.0)
    {
        Handle pack;
        MusicTimer = CreateDataTimer(time, Timer_MusicTheme, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        WritePackString(pack, sound);
        WritePackFloat(pack, time);
    }
    
    return Plugin_Continue;
}

public Action Timer_MusicTheme(Handle timer, any pack)
{
    char sound[PLATFORM_MAX_PATH];
    ResetPack(pack);
    ReadPackString(pack, sound, sizeof(sound));
    float time = ReadPackFloat(pack);
    if (g_bEnabled && ASHRoundState == ASHRState_Active)
    {
        Action act = Plugin_Continue;
        Call_StartForward(OnMusic);
        char sound2[PLATFORM_MAX_PATH];
        float time2 = time;
        strcopy(sound2, PLATFORM_MAX_PATH, sound);
        Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
        Call_PushFloatRef(time2);
        Call_Finish(act);
        switch (act)
        {
            case Plugin_Stop, Plugin_Handled:
            {
                strcopy(sound, sizeof(sound), "");
                time = -1.0;
                MusicTimer = null;
                return Plugin_Stop;
            }
            case Plugin_Changed:
            {
                strcopy(sound, PLATFORM_MAX_PATH, sound2);
                if (time2 != time)
                {
                    time = time2;
                    ClearTimer(MusicTimer);
                    if (time != -1.0)
                    {
                        Handle datapack;
                        MusicTimer = CreateDataTimer(time, Timer_MusicTheme, datapack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                        WritePackString(datapack, sound);
                        WritePackFloat(datapack, time);
                    }
                }
            }
        }
        if (sound[0] != '\0')
        {
            EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
        }
    }
    else
    {
        MusicTimer = null;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

void EmitSoundToAllExcept(int exceptiontype = SOUNDEXCEPT_MUSIC, char[] sample, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3] = NULL_VECTOR, const float dir[3] = NULL_VECTOR, bool updatePos = true, float soundtime = 0.0) {
    int[] clients = new int[MaxClients];
    int total = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckSoundException(i, exceptiontype))
        {
            clients[total++] = i;
        }
    }
    if (!total)
    {
        return;
    }
    EmitSound(clients, total, sample, entity, channel,
        level, flags, volume, pitch, speakerentity,
        origin, dir, updatePos, soundtime);
}

bool CheckSoundException(int client, int excepttype)
{
    if (!IsValidClient(client)) return false;
    if (IsFakeClient(client)) return true;
    if (!AreClientCookiesCached(client)) return true;
    char strCookie[32];
    if (excepttype == SOUNDEXCEPT_VOICE) GetClientCookie(client, VoiceCookie, strCookie, sizeof(strCookie));
    else GetClientCookie(client, MusicCookie, strCookie, sizeof(strCookie));
    if (strCookie[0] == 0) return true;
    else return view_as<bool>(StringToInt(strCookie));
}

void SetClientSoundOptions(int client, int excepttype, bool on)
{
    if (!IsValidClient(client)) return;
    if (IsFakeClient(client)) return;
    if (!AreClientCookiesCached(client)) return;
    char strCookie[32];
    if (on) strCookie = "1";
    else strCookie = "0";
    if (excepttype == SOUNDEXCEPT_VOICE) SetClientCookie(client, VoiceCookie, strCookie);
    else SetClientCookie(client, MusicCookie, strCookie);
}

public Action GottamTimer(Handle hTimer)
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && IsPlayerAlive(i))
            SetEntityMoveType(i, MOVETYPE_WALK);
}

public Action StartRound(Handle hTimer)
{
    ASHRoundState = ASHRState_Active;
    if (IsValidClient(Hale))
    {
        if (!IsPlayerAlive(Hale) && GetEntityTeamNum(Hale) > TEAM_SPEC)
        {
            TF2_RespawnPlayer(Hale);
        }
        ChangeTeam(Hale, HaleTeam);
        if (GetEntityTeamNum(Hale) == HaleTeam)
        {
            bool pri = IsValidEntity(GetPlayerWeaponSlot(Hale, TFWeaponSlot_Primary));
            bool sec = IsValidEntity(GetPlayerWeaponSlot(Hale, TFWeaponSlot_Secondary));
            bool mel = IsValidEntity(GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee));
            TF2_RemovePlayerDisguise(Hale);

            if (pri || sec || !mel)
                CreateTimer(0.05, Timer_ReEquipSaxton, _, TIMER_FLAG_NO_MAPCHANGE);
            iHaleSpecialPower = 0;
            //EquipSaxton(Hale);
        }
    }
    CreateTimer(10.0, Timer_SkipHalePanel);
    return Plugin_Continue;
}

public Action Timer_ReEquipSaxton(Handle timer)
{
    if (IsValidClient(Hale))
    {
        EquipSaxton(Hale);
    }
}

public Action Timer_SkipHalePanel(Handle hTimer)
{
    bool added[TF_MAX_PLAYERS];
    int i;
    int j;
    int client = Hale;
    
    do
    {
        client = FindNextHale(added);
        if (client >= 0) added[client] = true;
        if (IsValidClient(client) && client != Hale)
        {
            if (!IsFakeClient(client))
            {
                CPrintToChat(client, "{ash}[ASH]{default} %t", "vsh_to0_near");
                if (i == 0) SkipHalePanelNotify(client);
            }
            i++;
        }
        j++;
    }
    while (i < 3 && j < TF_MAX_PLAYERS);
}

void SkipHalePanelNotify(int client) {
    if (!g_bEnabled || !IsValidClient(client) || IsVoteInProgress())
    {
        return;
    }

    Action result = Plugin_Continue;
    Call_StartForward(OnHaleNext);
    Call_PushCell(client);
    Call_Finish(view_as<int>(result));

    switch(result)
    {
        case Plugin_Stop, Plugin_Handled:
            return;
    }

    Handle panel = CreatePanel();
    char s[256];

    SetPanelTitle(panel, "[ASH] You're Hale next!");
    Format(s, sizeof(s), "%t\nAlternatively, use !resetq.", "vsh_to0_near");

    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, SkipHalePanelH, 30);
    CloseHandle(panel);
    
    return;
}

public int SkipHalePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    return;
}
public Action EnableSG(Handle hTimer, any iid)
{
    int i = EntRefToEntIndex(iid);
    if (ASHRoundState == ASHRState_Active && IsValidEdict(i) && i > MaxClients)
    {
        char s[64];
        GetEdictClassname(i, s, 64);
        if (StrEqual(s, "obj_sentrygun"))
        {
            SetEntProp(i, Prop_Send, "m_bDisabled", 0);
        }
    }
    return Plugin_Continue;
}

public Action MessageTimer(Handle hTimer, any allclients)
{
    if (!IsValidClient(Hale)) // || ((client != 9001) && !IsValidClient(client))
        return Plugin_Continue;
    if (checkdoors)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
        {
            AcceptEntityInput(ent, "Open");
            AcceptEntityInput(ent, "Unlock");
        }
        if (doorchecktimer == null)
            doorchecktimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }
    char translation[32];
    switch (Special)
    {
        case ASHSpecial_Bunny: strcopy(translation, sizeof(translation), "vsh_start_bunny");
        case ASHSpecial_Vagineer: strcopy(translation, sizeof(translation), "vsh_start_vagineer");
        case ASHSpecial_HHH: strcopy(translation, sizeof(translation), "vsh_start_hhh");
        case ASHSpecial_CBS: strcopy(translation, sizeof(translation), "vsh_start_cbs");
        case ASHSpecial_MiniHale: strcopy(translation, sizeof(translation), "ash_start_secretHale");
        case ASHSpecial_Agent: strcopy(translation, sizeof(translation), "ash_start_agent");
        default: strcopy(translation, sizeof(translation), "vsh_start_hale");
    }
    SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
    if (!allclients) {
        ShowSyncHudText(Hale, infoHUD, "%T", translation, Hale, Hale, HaleHealthMax);
    } else {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i))
                ShowSyncHudText(i, infoHUD, "%T", translation, i, Hale, HaleHealthMax);
        }
    }
    return Plugin_Continue;
}

public Action MakeModelTimer(Handle hTimer)
{
    if (!IsValidClient(Hale) || !IsPlayerAlive(Hale) || ASHRoundState == ASHRState_End)
    {
        return Plugin_Stop;
    }
    int body = 0;
    switch (Special)
    {
#if defined EASTER_BUNNY_ON
        case ASHSpecial_Bunny:
        {
            SetVariantString(BunnyModel);
        }
#endif
        case ASHSpecial_Vagineer:
            SetVariantString(VagineerModel);
        case ASHSpecial_HHH:
            SetVariantString(HHHModel);
        case ASHSpecial_CBS:
            SetVariantString(CBSModel);
        case ASHSpecial_Agent:
            SetVariantString(Agent_Model);
        default:
        {
            SetVariantString(HaleModel);
            if (GetUserFlagBits(Hale) & ADMFLAG_CUSTOM1) body = (1 << 0)|(1 << 1);
        }
    }
    
    AcceptEntityInput(Hale, "SetCustomModel");
    SetEntProp(Hale, Prop_Send, "m_bUseClassAnimations", 1);
    SetEntProp(Hale, Prop_Send, "m_nBody", body);
    return Plugin_Continue;
}

void EquipSaxton(int client)
{
    if (!IsValidClient(client))
        return;
    bEnableSuperDuperJump = false;
    int SaxtonWeapon;
    TF2_RemoveAllWeapons(client);
    HaleCharge = 0;
    switch (Special)
    {
        case ASHSpecial_Bunny:
        {
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_bottle", 1, 100, TFQual_Unusual, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 326 ; 1.3");
        }
        case ASHSpecial_Vagineer:
        {
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_wrench", 7, 100, TFQual_Unusual, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 436 ; 1.0");
        }
        case ASHSpecial_HHH:
        {
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_sword", 266, 100, TFQual_Unusual, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 252 ; 0.6 ; 551 ; 1");
            SetEntPropFloat(SaxtonWeapon, Prop_Send, "m_flModelScale", 0.0001);
            HaleCharge = -1000;
        }
        case ASHSpecial_CBS:
        {
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_club", 171, 100, TFQual_Unusual, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0");
            //SetEntProp(client, Prop_Send, "m_nBody", 0);
        }
        case ASHSpecial_Agent:
        {
            // Invis watch
            TF2_RemoveWeaponSlot(client, 4);
            AgentHelper_ChangeTimeBeforeInvis(0.5, Hale);
        
            // Knife
            char attribs[64];
            FormatEx(attribs, sizeof(attribs), "252 ; 0.75 ; 68 ; 1.0 ; 2 ; 2.4 ; 214 ; %d ; 137 ; 2.1 ; 275 ; 1.0", GetRandomInt(1000000000, 2147483640));
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_knife", 727, 100, TFQual_Unusual, attribs);
            TF2Attrib_SetByDefIndex(SaxtonWeapon, 26, 275.0);
            
            // Sapper
            CreateTimer(0.1, SpawnAgentSapper, client);
            
            // Обоссадор
            if (IsHologram(client))
                CreateTimer(0.3, SpawnObossador, client);
        }
        case ASHSpecial_MiniHale:
        {
            char attribs[64];
            FormatEx(attribs, sizeof(attribs), "536 ; 0.25 ; 68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 551 ; %i ; 214 ; %d", !IsDate(Month_Oct, 15), GetRandomInt(9999, 99999));
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_shovel", 5, 100, TFQual_Strange, attribs);
        }
        default:
        {
            char attribs[64];
            FormatEx(attribs, sizeof(attribs), "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 551 ; %i ; 214 ; %d", !IsDate(Month_Oct, 15), GetRandomInt(9999, 99999));
            SaxtonWeapon = SpawnWeapon(client, "tf_weapon_shovel", 5, 100, TFQual_Strange, attribs);
        }
    }

    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
}

public Action SpawnObossador(Handle hTimer, any client) {
    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_revolver", 61, 100, TFQual_Strange, "51 ; 1 ; 1 ; 0.85 ; 5 ; 1.2 ; 15 ; 0 ; 275 ; 1"));
    CreateTimer(0.1, ReturnKnife, client);
}

public Action MakeHale(Handle hTimer)
{
    if (!IsValidClient(Hale))
    {
        return Plugin_Continue;
    }

    switch (Special)
    {
        case ASHSpecial_Hale, ASHSpecial_MiniHale:
            TF2_SetPlayerClass(Hale, TFClass_Soldier, _, false);
        case ASHSpecial_Vagineer:
            TF2_SetPlayerClass(Hale, TFClass_Engineer, _, false);
        case ASHSpecial_HHH, ASHSpecial_Bunny:
            TF2_SetPlayerClass(Hale, TFClass_DemoMan, _, false);
        case ASHSpecial_CBS:
            TF2_SetPlayerClass(Hale, TFClass_Sniper, _, false);
        case ASHSpecial_Agent:
            TF2_SetPlayerClass(Hale, TFClass_Spy, _, false);
    }
    TF2_RemovePlayerDisguise(Hale);

    ChangeTeam(Hale, HaleTeam);
    if (Special == ASHSpecial_MiniHale) ResizePlayer(Hale, 0.5);

    if (ASHRoundState < ASHRState_Waiting)
        return Plugin_Continue;
    if (!IsPlayerAlive(Hale))
    {
        if (ASHRoundState == ASHRState_Waiting) TF2_RespawnPlayer(Hale);
        else return Plugin_Continue;
    }
    int iFlags = GetCommandFlags("r_screenoverlay");
    SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
    ClientCommand(Hale, "r_screenoverlay \"\"");
    SetCommandFlags("r_screenoverlay", iFlags);
    CreateTimer(0.2, MakeModelTimer, _);
    CreateTimer(20.0, MakeModelTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    int ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
        {
            int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
            switch (index)
            {
                case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
                default:    TF2_RemoveWearable(Hale, ent);
            }
        }
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_powerup_bottle")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
        {
            int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
            switch (index)
            {
                case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
                default:    TF2_RemoveWearable(Hale, ent);
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_wearable_razorback")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
        {
            TF2_RemoveWearable(Hale, ent);
        }
    }
	
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
        {
            TF2_RemoveWearable(Hale, ent);
            //AcceptEntityInput(ent, "kill");
        }
    }
    
    EquipSaxton(Hale);

    if (ASHRoundState >= ASHRState_Waiting && GetClientClasshelpinfoCookie(Hale))
    {
        HintPanel(Hale);
    }

    return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem)
{
    if (RoundCount <= 0 && !GetConVarBool(cvarFirstRound)) return Plugin_Continue;

    Handle hItemOverride = UTIL_PrepareItemHandle(iItemDefinitionIndex, hItem, "TF2Items_OnGNI__");
    TFClassType iClass = TF2_GetPlayerClass(client);

    switch (iItemDefinitionIndex)
    {
        case 1153: // Panic Attack
        {
            if (iClass == TFClass_Engineer)
                hItemOverride = PrepareItemHandle(hItem, _, _, "708 ; 1.0 ; 709 ; 2.5 ; 710 ; 1 ; 651 ; 0.50 ; 394 ; 0.70 ; 97 ; 0.50 ; 424 ; 0.66 ; 547 ; 0.5 ; 2 ; 1.4", true);
        }
        case 22, 160, 209, 294, 15013, 15018, 15035, 15041, 15046, 15056, 30666: // Engie Pistols
        {
            if (iClass == TFClass_Engineer)
                hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.6", true);
        }
        case 1071: // Golden Frying Pan
        {
            if (iClass == TFClass_Spy)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "6 ; 0.80 ; 150 ; 1", true);
            }
            else if (iClass == TFClass_Medic)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.15 ; 6 ; 0.80 ; 150 ; 1", true);
            }
            else if (iClass == TFClass_DemoMan)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "150 ; 1", true);
            }
            else if (iClass == TFClass_Sniper)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "236 ; 1 ; 2 ; 1.15 ; 6 ; 0.80", true);
            }
            else
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.20 ; 150 ; 1", true);
            }
        }
        case 264, 474, 880, 939, 954, 1123, 1127, 30758: 								// DEFAULT MELEE WEAPONS BUFF (MULTI-CLASS)
        {
            if (iClass == TFClass_Spy)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "6 ; 0.80", true);
            }
            else if (iClass == TFClass_Medic)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.15 ; 6 ; 0.80", true);
            }
            else if (iClass == TFClass_DemoMan)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "", true);
            }
            else if (iClass == TFClass_Sniper)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "236 ; 1 ; 2 ; 1.15 ; 6 ; 0.80", true);
            }
            else if (iClass == TFClass_Engineer)
			{
                hItemOverride = PrepareItemHandle(hItem, _, _, "80 ; 2 ; 2 ; 1.20", true);
            }
			else
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "2 ; 1.20", true);
            }
        }
    }

    if (hItemOverride != null) // This has to be here, else stuff below can overwrite what's above
    {
        hItem = hItemOverride;

        return Plugin_Changed;
    } 

    switch (iClass)
    {
        case TFClass_Sniper:
        {
            if (StrEqual(classname, "tf_weapon_club", false) || StrEqual(classname, "saxxy", false))
            {
                switch (iItemDefinitionIndex)
                {
                    case 401: // Shahanshah
                        hItemOverride = PrepareItemHandle(hItem, _, _, "236 ; 1 ; 224 ; 1.66 ; 225 ; 0.5", true);
                    default:
                        hItemOverride = PrepareItemHandle(hItem, _, _, "236 ; 1 ; 2 ; 1.15 ; 6 ; 0.80", true);
                }
            }
        }
        case TFClass_Soldier: // TODO if (TF2_GetPlayerClass(client) == TFClass_Soldier && (strncmp(classname, "tf_weapon_rocketlauncher", 24, false) == 0 || strncmp(classname, "tf_weapon_particle_cannon", 25, false) == 0 || strncmp(classname, "tf_weapon_shotgun", 17, false) == 0 || strncmp(classname, "tf_weapon_raygun", 16, false) == 0))
        {
            if (StrStarts(classname, "tf_weapon_shotgun", false) || GunmettleToIndex(iItemDefinitionIndex) == TFWeapon_Shotgun)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "135 ; 0.6"); // Soldier shotguns get 40% rocket jump dmg reduction
            }
            else if (StrStarts(classname, "tf_weapon_rocketlauncher", false)    || GunmettleToIndex(iItemDefinitionIndex) == TFWeapon_RocketLauncher)
            {
                if (iItemDefinitionIndex == 127) // Direct hit
                {
                    hItemOverride = PrepareItemHandle(hItem, _, _, "179 ; 1"); //    ; 215 ; 300.0
                }
                /*else
                {
                    hItemOverride = PrepareItemHandle(hItem, _, _, "488 ; 1", (iItemDefinitionIndex == 237)); // Rocket jumper
                }*/
            }
        }
#if defined OVERRIDE_MEDIGUNS_ON
        case TFClass_Medic:
        {
            //Medic mediguns
            if (StrStarts(classname, "tf_weapon_medigun", false) || GunmettleToIndex(iItemDefinitionIndex) == TFWeapon_Medigun)
            {
                hItemOverride = PrepareItemHandle(hItem, _, _, "10 ; 1.25 ; 178 ; 0.75 ; 18 ; 0 ; 314 ; 3.2", true);
            }
        }
#endif
    }

    if (hItemOverride != null)
    {
        hItem = hItemOverride;

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

Handle PrepareItemHandle(Handle hItem, char[] name = "", int index = -1, char[] att = "", bool dontpreserve = false)
{
    static Handle hWeapon;
    int addattribs = 0;

    char weaponAttribsArray[32][32];
    int attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);

    int flags = OVERRIDE_ATTRIBUTES;
    if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
    if (hWeapon == null) hWeapon = TF2Items_CreateItem(flags);
    else TF2Items_SetFlags(hWeapon, flags);
    if (hItem != null)
    {
        addattribs = TF2Items_GetNumAttributes(hItem);
        if (addattribs > 0)
        {
            for (int i = 0; i < 2 * addattribs; i += 2)
            {
                bool dontAdd = false;
                int attribIndex = TF2Items_GetAttributeId(hItem, i);
                for (int j = 0; j < attribCount+i; j += 2)
                {
                    if (StringToInt(weaponAttribsArray[j]) == attribIndex)
                    {
                        dontAdd = true;
                        break;
                    }
                }
                if (!dontAdd)
                {
                    IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
                    FloatToString(TF2Items_GetAttributeValue(hItem, i), weaponAttribsArray[i+1+attribCount], 32);
                }
            }
            attribCount += 2 * addattribs;
        }
        CloseHandle(hItem); //probably returns false but whatever
    }

    if (name[0] != '\0')
    {
        flags |= OVERRIDE_CLASSNAME;
        TF2Items_SetClassname(hWeapon, name);
    }
    if (index != -1)
    {
        flags |= OVERRIDE_ITEM_DEF;
        TF2Items_SetItemIndex(hWeapon, index);
    }
    if (attribCount > 1)
    {
        TF2Items_SetNumAttributes(hWeapon, (attribCount/2));
        int i2 = 0;
        for (int i = 0; i < attribCount && i < 32; i += 2)
        {
            TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
            i2++;
        }
    }
    else
    {
        TF2Items_SetNumAttributes(hWeapon, 0);
    }
    TF2Items_SetFlags(hWeapon, flags);
    return hWeapon;
}

public Action MakeNoHale(Handle hTimer, any clientid)
{
    int client = GetClientOfUserId(clientid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || ASHRoundState == ASHRState_End || client == Hale)
        return Plugin_Continue;

    ChangeTeam(client, OtherTeam);

    if (!ASHRoundState && GetClientClasshelpinfoCookie(client) && !(ASHFlags[client] & ASHFLAG_CLASSHELPED))
        HelpPanel2(client);

    if (IsValidEntity(FindPlayerBack(client, { 444 }, 1))) {
        TF2Attrib_SetByDefIndex(client, 58, 1.0);
    } else {
        TF2Attrib_RemoveByDefIndex(client, 58);
    }

    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int index = -1;
    if (weapon > MaxClients && IsValidEdict(weapon))
    {
        index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        switch (index)
        {
            case 237:
            {
                if(!GetConVarBool(cvarEnableJumper))
                {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
                    SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 0, "");
                    SetAmmo(client, 0, 20);
                }
            }
        }
    }
    weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (weapon > MaxClients && IsValidEdict(weapon))
    {
        index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        switch (index)
        {
            /*case 46, 1145:
            {
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                SpawnWeapon(client, "tf_weapon_lunchbox_drink", 163, 1, 6, "144 ; 2 ; 798 ; 1.1");
            }*/
            case 265:
            {
                if(!GetConVarBool(cvarEnableJumper))
                {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                    SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20, 1, 0, "");
                    SetAmmo(client, 1, 24);
                }
            }
            /*case 159,433:
            {
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                SpawnWeapon(client, "tf_weapon_lunchbox", 159, 1, 6, "292 ; 50 ; 551 ; 1 ; 2029 ; 1");
            }*/
        }
    }
    if (IsValidEntity(FindPlayerBack(client, { 231 }, 1)))
    {
        SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "15 ; 0.0 ; 1 ; 0.85 ; 208 ; 1");
    }
    if (IsValidEntity(FindPlayerBack(client, { 642 }, 1)))
    {
        SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "15 ; 0.0 ; 1 ; 0.85 ; 32 ; 0.10");
    }
    weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
    if (weapon > MaxClients && IsValidEdict(weapon))
    {
        index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        switch (index)
        {
            case 43:
            {
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
                SpawnWeapon(client, "tf_weapon_fists", 239, 1, 6, "107 ; 1.5 ; 1 ; 0.5 ; 128 ; 1 ; 191 ; -7");
            }
            /* case 128:
            {
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
                SpawnWeapon(client, "tf_weapon_shovel", 775, 1, 6, "128 ; 1 ; 235 ; 2 ; 740 ; 0.1 ; 414 ; 1 ; 551 ; 1");
            }*/
            case 173:
            {
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
                SpawnWeapon(client, "tf_weapon_bonesaw", 173, 1, 6, "");
            }
            case 357:
            {
                CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            }
            /*case 589:
            {
                if (!GetConVarBool(cvarEnableEurekaEffect))
                {
                    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
                    SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "2 ; 1.20");
                }
            }*/
        }
    }
    weapon = GetPlayerWeaponSlot(client, 4);
    if (weapon > MaxClients && IsValidEdict(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 60)
    {
        //if(GetConVarBool(cvarEnableCloak))
        //{
        //    TF2_RemoveWeaponSlot(client, 4);
        //    SpawnWeapon(client, "tf_weapon_invis", 60, 1, 0, "292 ; 58 ; 728 ; 1 ; 83 ; -9999.0 ; 109 ; 0.70 ; 253 ; 1.0");
        //}
        //else
        //{
            TF2_RemoveWeaponSlot(client, 4);
            SpawnWeapon(client, "tf_weapon_invis", 30, 1, 6, "");
        //}
    }
    if (TF2_GetPlayerClass(client) == TFClass_Medic)
    {
        weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
#if defined OVERRIDE_MEDIGUNS_ON
        if (GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") < 0.41)
            SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.41);
        if (index == 173 && GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
            SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.99);
#else
        int mediquality = (weapon > MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iEntityQuality") : -1);
        if (mediquality != 10)
        {
            TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
            weapon = SpawnWeapon(client, "tf_weapon_medigun", 35, 5, 10, "18 ; 0.0 ; 10 ; 1.25 ; 178 ; 0.75");    //200 ; 1 for area of effect healing    // ; 178 ; 0.75 ; 128 ; 1.0 Faster switch-to
            if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)
            {
                SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
                SetEntityRenderColor(weapon, 255, 255, 255, 75); // What is the point of making gunslinger translucent? When will a medic ever even have a gunslinger equipped???    According to FlaminSarge: Randomizer Hale
            }
            SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.41);
        }
#endif
    }
    return Plugin_Continue;
}

public Action Timer_NoHonorBound(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        int index = ((IsValidEntity(weapon) && weapon > MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
        int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        char classname[64];
        if (IsValidEdict(active)) GetEdictClassname(active, classname, sizeof(classname));
        if (index == 357 && active == weapon && strcmp(classname, "tf_weapon_katana", false) == 0)
        {
            SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
            if (GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
                SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
        }
    }
}

public Action Timer_UberCharge_MEDIC(Handle TimerHndl_LOCAL, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsValidEntity(client)) return Plugin_Stop;
    if (!IsValidClient(client)) return Plugin_Stop;
    int MediGun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (MediGun == -1 || !IsValidEntity(MediGun)) return Plugin_Stop;
    if (GetEntProp(MediGun, Prop_Send, "m_bChargeRelease") == 0) return Plugin_Stop;
    if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
    {
        if (TF2_IsPlayerInCondition(client, _TFCond(5))) return Plugin_Continue;
        TF2_RemoveCondition(client, _TFCond(5));
        TF2_AddCondition(client, _TFCond(5), 1.0);
    }
    else TF2_RemoveCondition(client, _TFCond(5));
    
    return Plugin_Continue;
}

public Action Timer_Lazor(Handle hTimer, any medigunid)
{
    int medigun = EntRefToEntIndex(medigunid);
    if (medigun && IsValidEntity(medigun) && ASHRoundState == ASHRState_Active)
    {
        int client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
        float charge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
        if (IsValidClient(client) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == medigun)
        {
            int target = GetHealingTarget(client);
            if (charge > 0.05)
            {
                TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
                if (IsValidClient(target) && IsPlayerAlive(target)) // IsValidClient(target, false)
                {
                    int SpecialIndex;
                    SpecialIndex = GetEntProp(GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex");
                    if (SpecialIndex != 812 && SpecialIndex != 833) {
                        TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
                    }
                    uberTarget[client] = target;
                }
                else uberTarget[client] = -1;
            }
        }
        if (charge <= 0.05)
        {
            CreateTimer(3.0, Timer_Lazor2, EntIndexToEntRef(medigun));
            ASHFlags[client] &= ~ASHFLAG_UBERREADY;
            return Plugin_Stop;
        }
    }
    else
        return Plugin_Stop;
    return Plugin_Continue;
}

public Action Timer_Lazor2(Handle hTimer, any medigunid)
{
    int medigun = EntRefToEntIndex(medigunid);
    if (IsValidEntity(medigun))
        SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+0.31);
    return Plugin_Continue;
}

public Action Command_RefreshGamedata(int iArgC)
{
    ASH_ResolveGameData(true);
    PrintToServer("[ASH] Gamedata updated successfully.");

    return Plugin_Handled;
}

public Action Command_GetHPCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    Command_GetHP(client);
    return Plugin_Handled;
}

public Action Command_GetHP(int client)
{
    if (!g_bEnabled || ASHRoundState != ASHRState_Active)
        return Plugin_Continue;
    if (client == Hale)
    {
        switch (Special)
        {
            case ASHSpecial_Bunny:
                PriorityCenterTextAll(_, "%t", "vsh_bunny_show_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_Vagineer:
                PriorityCenterTextAll(_, "%t", "vsh_vagineer_show_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_HHH:
                PriorityCenterTextAll(_, "%t", "vsh_hhh_show_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_CBS:
                PriorityCenterTextAll(_, "%t", "vsh_cbs_show_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_MiniHale:
                PriorityCenterTextAll(_, "%t", "ash_secretHale_show_hp", HaleHealth, HaleHealthMax);
            case ASHSpecial_Agent:
                PriorityCenterTextAll(_, "%t", "ash_Agent_show_hp", HaleHealth, HaleHealthMax);
            default:
                PriorityCenterTextAll(_, "%t", "vsh_hale_show_hp", HaleHealth, HaleHealthMax);
        }
        HaleHealthLast = HaleHealth;
        return Plugin_Continue;
    }
    if (IsNextTime(e_flNextHealthQuery)) //    GetGameTime() >= HPTime
    {
        healthcheckused++;
        switch (Special)
        {
            case ASHSpecial_Bunny:
            {
                PriorityCenterTextAll(_, "%t", "vsh_bunny_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_bunny_hp", HaleHealth, HaleHealthMax);
            }
            case ASHSpecial_Vagineer:
            {
                PriorityCenterTextAll(_, "%t", "vsh_vagineer_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_vagineer_hp", HaleHealth, HaleHealthMax);
            }
            case ASHSpecial_HHH:
            {
                PriorityCenterTextAll(_, "%t", "vsh_hhh_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_hhh_hp", HaleHealth, HaleHealthMax);
            }
            case ASHSpecial_CBS:
            {
                PriorityCenterTextAll(_, "%t", "vsh_cbs_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_cbs_hp", HaleHealth, HaleHealthMax);
            }
            
            case ASHSpecial_MiniHale:
            {
                PriorityCenterTextAll(_, "%t", "ash_secretHale_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_hale_hp", HaleHealth, HaleHealthMax);
            }
            
            case ASHSpecial_Agent:
            {
                PriorityCenterTextAll(_, "%t", "ash_Agent_show_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "ash_agent_hp", HaleHealth, HaleHealthMax);
            }
            
            default:
            {
                PriorityCenterTextAll(_, "%t", "vsh_hale_hp", HaleHealth, HaleHealthMax);
                CPrintToChatAll("{ash}[ASH]{default} %t", "vsh_hale_hp", HaleHealth, HaleHealthMax);
            }
        }
        HaleHealthLast = HaleHealth;
        SetNextTime(e_flNextHealthQuery, healthcheckused < 3 ? 20.0 : 80.0);
    }
    else if (RedAlivePlayers == 1)
        CPrintToChat(client, "{ash}[ASH]{default} %t", "vsh_already_see");
    else
        CPrintToChat(client, "{ash}[ASH]{default} %t", "vsh_wait_hp", GetSecsTilNextTime(e_flNextHealthQuery), HaleHealthLast);
    return Plugin_Continue;
}

public Action Command_MakeNextSpecial(int client, int args)
{
    if (!CheckCommandAccess(client, "sm_hale_special", ADMFLAG_CHEATS, true))
    {
        ReplyToCommand(client, "[SM] You do not have access to this command.");
        return Plugin_Handled;
    }

    char arg[32];
    char name[64];
    if (!bSpecials)
    {
        CReplyToCommand(client, "{olive}[ASH]{default} This server isn't set up to use special bosses! Set the cvar hale_specials 1 in the ASH config to enable on next map!");
        return Plugin_Handled;
    }
    if (args < 1)
    {
        CReplyToCommand(client, "{olive}[ASH]{default} Usage: hale_special <hale, vagineer, hhh, christian, spy>");
        return Plugin_Handled;
    }
    GetCmdArgString(arg, sizeof(arg));
    if (StrContains(arg, "hal", false) != -1)
    {
        Incoming = ASHSpecial_Hale;
        name = "Saxton Hale";
    }
    else if (StrContains(arg, "vag", false) != -1)
    {
        Incoming = ASHSpecial_Vagineer;
        name = "the Vagineer";
    }
    else if (StrContains(arg, "hhh", false) != -1)
    {
        Incoming = ASHSpecial_HHH;
        name = "the Horseless Headless Horsemann Jr.";
    }
    else if (StrContains(arg, "chr", false) != -1 || StrContains(arg, "cbs", false) != -1)
    {
        Incoming = ASHSpecial_CBS;
        name = "the Christian Brutal Sniper";
    }
#if defined EASTER_BUNNY_ON
    else if (StrContains(arg, "bun", false) != -1 || StrContains(arg, "eas", false) != -1)
    {
        Incoming = ASHSpecial_Bunny;
        name = "the Easter Bunny";
    }
#endif
    else if (StrContains(arg, "littlelittleman", false) != -1)
    {
        Incoming = ASHSpecial_MiniHale;
        name = "Secret Mini Saxton Hale";
    }
    else if (StrContains(arg, "agent", false) != -1 || StrContains(arg, "spy", false) != -1)
    {
        Incoming = ASHSpecial_Agent;
        name = "Agent";
    }
    else
    {
        CReplyToCommand(client, "{ash}[ASH]{default} Usage: hale_special <hale, vagineer, hhh, christian, agent>");
        return Plugin_Handled;
    }
    CReplyToCommand(client, "{ash}[ASH]{default} Set the next Special to %s", name);
    return Plugin_Handled;
}

public Action Command_NextHale(int client, int args)
{
    if (g_bEnabled)
        CreateTimer(0.2, MessageTimer);
    return Plugin_Continue;
}

public Action Command_HaleSetDamage(int client, int args) {
    if (!(g_bEnabled && g_bAreEnoughPlayersPlaying)) return Plugin_Continue;
    
    if (args < 2) {
        CReplyToCommand(client, "{ash}[ASH] {default}Usage: hale_setdmg <target> <damage>");
        return Plugin_Handled;
    }
    
    char targetname[MAX_TARGET_LENGTH];
    char damage[12];
    
    GetCmdArg(1, targetname, MAX_TARGET_LENGTH);
    GetCmdArg(2, damage, 12);
    
    int target = FindTarget(client, targetname);
    
    if (IsValidClient(target)) {
        Damage[target] = StringToInt(damage);
    } else {
        CReplyToCommand(client, "{ash}[ASH]{default} Target is not valid for being changed damage.");
    }
    
    return Plugin_Handled;
}

public Action Command_HaleSelect(int client, int args)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Continue;

    if (args < 1)
    {
        CReplyToCommand(client, "{ash}[ASH]{default} Usage: hale_select <target> [\"hidden\"]");
        return Plugin_Handled;
    }

    char s2[12];
    char targetname[32];

    GetCmdArg(1, targetname, sizeof(targetname));
    GetCmdArg(2, s2, sizeof(s2));

    int target = FindTarget(client, targetname);

    if (IsValidClient(target) && IsClientParticipating(target))
    {
        ForceHale(client, target, StrContains(s2, "hidden", false) >= 0);
    }
    else
    {
        CReplyToCommand(client, "{ash}[ASH]{default} Target is not valid for being selected as the boss.");
    }

    return Plugin_Handled;
}

public Action Command_Points(int client, int args)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Continue;
    if (args != 2)
    {
        CReplyToCommand(client, "{ash}[ASH]{default} Usage: hale_addpoints <target> <points>");
        return Plugin_Handled;
    }
    char s2[MAX_DIGITS];
    char targetname[PLATFORM_MAX_PATH];
    GetCmdArg(1, targetname, sizeof(targetname));
    GetCmdArg(2, s2, sizeof(s2));
    int points = StringToInt(s2);
    /**
     * target_name - stores the noun identifying the target(s)
     * target_list - array to store clients
     * target_count - variable to store number of clients
     * tn_is_ml - stores whether the noun must be translated
     */
    char target_name[MAX_TARGET_LENGTH];
    int[] target_list = new int[TF_MAX_PLAYERS];
    int target_count;
    bool tn_is_ml;
    if ((target_count = ProcessTargetString(
            targetname,
            client,
            target_list,
            TF_MAX_PLAYERS,
            0,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        /* This function replies to the admin with a failure message */
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    for (int i = 0; i < target_count; i++)
    {
        SetClientQueuePoints(target_list[i], GetClientQueuePoints(target_list[i])+points);
        LogAction(client, target_list[i], "\"%L\" added %d ASH queue points to \"%L\"", client, points, target_list[i]);
    }
    CReplyToCommand(client, "{ash}[ASH]{default} Added %d queue points to %s", points, target_name);
    return Plugin_Handled;
}

void StopHaleMusic(int client)
{
    if (!IsValidClient(client)) return;
    StopSound(client, SNDCHAN_AUTO, HHHTheme);
    StopSound(client, SNDCHAN_AUTO, CBSTheme);
}

public Action Command_StopMusic(int client, int args)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Continue;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        StopHaleMusic(i);
    }
    CReplyToCommand(client, "{ash}[ASH] {default}Stopped boss music.");
    return Plugin_Handled;
}

public Action Command_Point_Disable(int client, int args)
{
    if (g_bEnabled) SetControlPoint(false);
    return Plugin_Handled;
}

public Action Command_Point_Enable(int client, int args)
{
    if (g_bEnabled) SetControlPoint(true);
    return Plugin_Handled;
}

void SetControlPoint(bool enable)
{
    int CPm=-1; //CP = -1;
    while ((CPm = FindEntityByClassname2(CPm, "team_control_point")) != -1)
    {
        if (CPm > MaxClients && IsValidEdict(CPm))
        {
            AcceptEntityInput(CPm, (enable ? "ShowModel" : "HideModel"));
            SetVariantInt(enable ? 0 : 1);
            AcceptEntityInput(CPm, "SetLocked");
        }
    }
}

stock void ForceHale(int admin, int client, bool hidden, bool forever = false)
{
    if (forever)
        Hale = client;
    else
        NextHale = client;
    if (!hidden)
    {
        CPrintToChatAllEx(client, "{ash}[ASH] {teamcolor}%N {default}%t", client, "vsh_hale_select_text");
    }
}

public Action Timer_SetDisconQueuePoints(Handle timer, Handle pack)
{
    ResetPack(pack);
    char authid[32];
    ReadPackString(pack, authid, sizeof(authid));
    SetAuthIdQueuePoints(authid, 0);
}

public Action Timer_RegenPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
    {
        TF2_RegeneratePlayer(client);
    }
}

public Action ManmelterUnban(Handle hTimer, any Pyro) {
    plManmelterBlock[Pyro] = false;
}

public Action DisableInfection(Handle hTimer, any InfectedClient) {
    InfectPlayers[InfectedClient] = false;
    ImmunityClient[InfectedClient] = true;
    CreateTimer(60.0, DisableImmunity, InfectedClient);
}

public Action DisableImmunity(Handle hTimer, any immunned) {
    ImmunityClient[immunned] = false;
}

public Action InfectiionDamage(Handle hTimer, any InfectedClient) {
    if (!InfectPlayers[InfectedClient]) return Plugin_Stop;
    float INFECT_POS[3] = {0.0, 0.0, 92.0};
    AttachParticle(InfectedClient, "powerup_icon_plague", 1.0, INFECT_POS, true);
    if(!ManmelterBan[InfectedClient] && TF2_GetPlayerClass(InfectedClient) == TFClass_Pyro && plManmelterUsed[InfectedClient] == 100 && GetIndexOfWeaponSlot(InfectedClient, TFWeaponSlot_Secondary) == 595 && IntToFloat(GetEntProp(InfectedClient, Prop_Send, "m_iHealth")) <= 8.0)
    {
        TF2_OnPyroSecondChance(InfectedClient);
        CreateTimer(0.1, DisableInfection, InfectedClient);
    }  
    else
    {
        SDKHooks_TakeDamage(InfectedClient, Hale, Hale, 8.0, DMG_CLUB, 0);
    }
    return Plugin_Continue;
}

public Action ManmelterTimer(Handle hTimer) {
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    
    for (int client = 1; client<=MAXPLAYERS; client++) {
        if (!IsValidClient(client)) continue;
        if (TF2_GetPlayerClass(client) == TFClass_Pyro && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 595 && plManmelterUsed[client] < 100) plManmelterUsed[client]++;
    }
    
    return Plugin_Continue;
}

public Action MakeEngineersSpeed(Handle hTimer) {
    if (ASHRoundState == ASHRState_Active) return Plugin_Stop;
    for (int client = 1; client <= MaxClients; client++) {
        if (client != Hale && IsClientInGame(client) && GetEntityTeamNum(client) == OtherTeam) {
            int iWeapon = GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary);
            if (TF2_GetPlayerClass(client) == TFClass_Engineer && FindItemInArray(iWeapon, {22, 209, 160, 294, 15013, 15018, 15035, 15041, 15046, 15056, 30666}, 11)) {
                SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
            }
        }
    }
    
    return Plugin_Continue;
}

public Action BeggarBazaarTimer(Handle hTimer) {
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    
    for (int client = 1; client <= MaxClients; client++) {
        if (!(IsValidClient(client) && GetEntityTeamNum(client) == OtherTeam))
            continue;
        
        if (BB_Sniper_Shots[client] && BB_LastShotTime[client] < GetTime()-30)
            BB_Sniper_Shots[client]--;
    }
    return Plugin_Continue;
}

public Action RemoveWeapon(Handle hTimer, any weap) {
    AcceptEntityInput(weap, "Kill");
    SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee));
}

public Action RemoveWeapon_WhileLCNotPressed(Handle hTimer, any weap) {
    // if (!(GetClientButtons(Hale) & IN_ATTACK)) { Это блядь не показатель того, что я за что-то держусь :C
    if (FindEntityByClassname(-1, "tf_projectile_grapplinghook") == -1) { // а вот это показатель
        /* Projectiles */
        /*new iEnt = -1;
        while ((iEnt = FindEntityByClassname(iEnt, "tf_projectile_grapplinghook")) != -1) {
            AcceptEntityInput(iEnt, "KillHierarchy");
        }*/
        
        /* Hook */
        AcceptEntityInput(weap, "Kill");
        SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee));
    } else CreateTimer(0.05, RemoveWeapon_WhileLCNotPressed, weap);
}

public Action HHHTeleTimer(Handle timer)
{
    if (IsValidClient(Hale))
    {
        SetEntProp(Hale, Prop_Send, "m_CollisionGroup", 5); //Fix HHH's clipping.
    }
}

public Action Timer_StunHHH(Handle timer, Handle  pack)
{
    if (!IsValidClient(Hale)) return; // IsValidClient(Hale, false)
    ResetPack(pack);
    int superduper = ReadPackCell(pack);
    int targetid = ReadPackCell(pack);
    int target = GetClientOfUserId(targetid);
    if (!IsValidClient(target)) target = 0; // IsValidClient(target, false)
    ASHFlags[Hale] &= ~ASHFLAG_NEEDSTODUCK;
    TF2_StunPlayer(Hale, (superduper ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
}

public Action Timer_BotRage(Handle timer)
{
    if (!IsValidClient(Hale)) return;
    if (!TF2_IsPlayerInCondition(Hale, TFCond_Taunting)) FakeClientCommandEx(Hale, "taunt");
}

bool OnlyScoutsLeft()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client) && client != Hale && TF2_GetPlayerClass(client) != TFClass_Scout)
            return false;
    }
    return true;
}

public Action Timer_GravityCat(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client)) SetEntityGravity(client, 1.0);
}
/*public Action Destroy(int client, char[] command, int argc)
{
    if (!g_bEnabled || client == Hale)
        return Plugin_Continue;
    if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && TF2_IsPlayerInCondition(client, TFCond_Taunting) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 589)
        return Plugin_Handled;
    return Plugin_Continue;
}*/

static bool s_bPreventDeadringEffects[TF_MAX_PLAYERS] = {false, ...};

public void TF2_OnConditionAdded(int client, TFCond cond)
{
    if (!g_bEnabled)
        return;

    if (client != Hale)
    {
        switch (cond)
        {
            case TFCond_Cloaked:
            {
                switch (GetClientCloakIndex(client))
                {
                    case 59: // Deadringer
                    {
                        s_bPreventDeadringEffects[client] = true;
                        RequestFrame(Frame_AllowDeadringEffects, client);
                    }
                    /*case 60: // Dagger
                        TF2Attrib_SetByDefIndex(client, 109, 0.1);*/
                }	
            }
            /*case TFCond_DeadRingered, TFCond_SpeedBuffAlly: //, TFCond:102
            {
                if (s_bPreventDeadringEffects[client])
                {
                    TF2_RemoveCondition(client, cond);
                }
            }*/
            case TFCond_Ubercharged:
            {
                if (TF2_GetPlayerClass(client) != TFClass_Medic) return;
                
                int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                if (medigun <= 0 || !IsValidEntity(medigun)) return;
                
                if (GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") <= 0.9) ASHStats[UberCharges]++;
            }
            /*case _TFCond(65):
            {
                if (TF2_GetPlayerClass(client) == TFClass_DemoMan && GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) == 1150)
                {
                    int iSticky = -1;
                    //new iStickyCount = 0;
                    while ((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != -1)
                    {
                        if (client == GetEntPropEnt(iSticky, Prop_Send, "m_hThrower"))
                        {
                            SDKCall(g_CTFGrenadeDetonate, iSticky);
                            //iStickyCount++;
                        }   
                    }
                    //PrintToChatAll("%i stickies found", iStickyCount);
                }
            }*/
        }
        
        if (TF2_GetPlayerClass(client) == TFClass_Heavy && IsWeaponSlotActive(client, TFWeaponSlot_Secondary)) {
            switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary)) {
                /*case 159, 433:    {
                    if (cond == TFCond_Taunting)
                        CreateTimer(0.1, HeavyShokolad_OnUberNeed, client);
                }*/
                
                case 311:        {
                    if (cond == _TFCond(41)) {
                        float ParticlePos[3] = {0.0, 0.0, 01.0};
                        AttachParticle(client, "medic_resist_bullet", 8.0, ParticlePos, true);
                        char s[PLATFORM_MAX_PATH];
                        Format(s, PLATFORM_MAX_PATH, "misc/ks_tier_03_kill_01.wav");
                        float pos[3];
                        pos[2] += 20.0;
                        EmitSoundToAll(s, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
                        
                        BuffTime[client] = 080;
                        CreateTimer(0.1, BuffaloSteakActivation, client, TIMER_REPEAT);
                    }
                }
            }
        }
    } 
    else
    {
        /*if(cond == TFCond_Jarated)
        {
            float rage = 0.50*RageDMG;
            HaleRage -= RoundToFloor(rage);
            if (HaleRage < 0)
            {
                HaleRage = 0;
            }
            if (Special == ASHSpecial_Vagineer && TF2_IsPlayerInCondition(Hale, TFCond_Ubercharged) && UberRageCount < 99)
            {   
                UberRageCount += 7.0;
                if (UberRageCount > 99) UberRageCount = 99.0;
            }
            int ammo = GetAmmo(Hale, 0);
            if (Special == ASHSpecial_CBS && ammo > 0) 
            {
                SetAmmo(Hale, 0, ammo - 1);
            }
        }*/
        if (cond == _TFCond(15))
        {
            ASHStats[StunsNum]++;
        } 
        else if (Special == ASHSpecial_Agent) 
        {
            if (cond == TFCond_Jarated || cond == TFCond_Milked) 
            {
                // Sound
                char s[PLATFORM_MAX_PATH];
                strcopy(s, PLATFORM_MAX_PATH, Agent_Circumfused[GetRandomInt(0,4)]);
                
                float vecPos[3];
                GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", vecPos);
             
                EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
                EmitAmbientSound(s, vecPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
            
                // Remove condition
                CreateTimer(4.0, TF2_OnHaleCondRemove, cond);
            }
        }
    }
}

public Action BuffaloSteakActivation(Handle hTimer, any client) {
    if (IsValidClient(client)) {
        if (!(IsPlayerAlive(client) && BuffTime[client] > 0)) {
            BuffTime[client] = 080;
            return Plugin_Stop;
        }
        
        BuffTime[client]--;

        float Points[2][3];
        GetEntPropVector(Hale, Prop_Data, "m_vecOrigin", Points[1]);
        GetEntPropVector(client, Prop_Data, "m_vecOrigin", Points[0]);

        if (GetVectorDistance(Points[0], Points[1]) < 300.0) PushClient(Hale);
        return Plugin_Continue;
    } return Plugin_Stop;
}

public void Frame_AllowDeadringEffects(any client)
{
    s_bPreventDeadringEffects[client] = false;
    if (IsClientInGame(client))
    {
        SetVariantString("ParticleEffectStop");
        AcceptEntityInput(client, "DispatchEffect");
    }
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
    if (TF2_GetPlayerClass(client) == TFClass_Scout && condition == TFCond_CritHype) {
        TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);     //recalc their speed
    } else if (TF2_GetPlayerClass(client) == TFClass_Spy && condition == TFCond_Cloaked) {
        int iWatch = GetIndexOfWeaponSlot(client, TFWeaponSlot_Watch);
        if (iWatch == 59) {
            TF2Attrib_SetByDefIndex(client, 728, 0.0); // how, spy allow to pick ammo's
            SetEntProp(client, Prop_Send, "m_bFeignDeathReady", 0);
        } /*else if (iWatch == 60) {
            DataPack hData = new DataPack();
            hData.WriteCell(client);
            hData.WriteCell(109);
            hData.WriteFloat(1.0);
            CreateTimer(1.0, OnTimerRemoveCloakFeature, hData);
        }*/
    } else if (TF2_GetPlayerClass(client) == TFClass_Medic && condition == TFCond_Ubercharged && Special == ASHSpecial_Agent) {
        g_iFidovskiyFix[client] = 1;
        if (g_iTimerList[client] != null) {
            KillTimer(g_iTimerList[client]);
            g_iTimerList[client] = null;
        }
        g_iTimerList[client] = CreateTimer(6.0, CanBeTarget, client);
    }
}

public Action cdVoiceMenu(int iClient, char[] sCommand, int iArgc)
{
    if (iArgc < 2) return Plugin_Handled;

    char sCmd1[8];
    char sCmd2[8];
    
    GetCmdArg(1, sCmd1, sizeof(sCmd1));
    GetCmdArg(2, sCmd2, sizeof(sCmd2));
    
    // Capture call for medic commands (represented by "voicemenu 0 0")
    if (sCmd1[0] == '0' && sCmd2[0] == '0' && IsPlayerAlive(iClient) && iClient == Hale)
    {
        if (HaleRage / RageDMG >= 1)
        {
            DoTaunt(iClient, "", 0);
            return Plugin_Handled;
        }
    }
    return (iClient == Hale && Special != ASHSpecial_CBS && Special != ASHSpecial_Bunny) ? Plugin_Handled : Plugin_Continue;
}

public Action DoTauntScout(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (BasherDamage[client]/BasherDMG >= 1 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                float pPos[3] = {0.0, 0.0, 80.0};
                AttachParticle(client, "mini_fireworks", 5.0, pPos, true);
                Format(s, PLATFORM_MAX_PATH, "player/mannpower_invulnerable.wav");
                CreateTimer(0.1, UseScoutRage, client);
                CreateTimer(1.5, ScoutSoundRage, client);
                CreateTimer(5.0, ScoutSoundRageEnd, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        BasherDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseScoutRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        TF2_AddCondition(client, TFCond_Ubercharged, 6.0);
        TF2_AddCondition(client, TFCond_Kritzkrieged, 6.0);
        TF2_AddCondition(client, TFCond_TeleportedGlow, 6.0);
    }
    if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
    {
        TF2_RemoveCondition(client, TFCond_Dazed);
        MakeModelTimer(null);
    }
    return Plugin_Continue;
}

public Action ScoutSoundRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, ScoutRandomScream[GetRandomInt(0, sizeof(ScoutRandomScream)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action ScoutSoundRageEnd(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntScout2(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (SpeedDamage[client]/SpeedDMG >= 1 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                Format(s, PLATFORM_MAX_PATH, "mvm/mvm_tele_activate.wav");
                CreateTimer(0.1, UseScoutRage2, client);
                CreateTimer(1.5, ScoutSoundRage2, client);
                CreateTimer(4.0, ScoutSoundRageEnd2, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        SpeedDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseSpyRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        float pPos[3] = {0.0, 0.0, 10.0};
        AttachParticle(client, "skull_island_embers", 1.0, pPos, true);
        AttachParticle(client, "skull_island_flash", 1.0, pPos, true);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", client);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", client);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", client);
        EmitSoundToAll("saxton_hale/spy_special_ele_ambient.wav", client);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action SpyCineFX(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    float pPos[3] = {0.0, 0.0, 50.0};
    AttachParticle(client, "outerspace_belt_blue", 6.7, pPos, true);
    return Plugin_Continue;
}

public Action SpySoundRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, SpyRandomScream[GetRandomInt(0, sizeof(SpyRandomScream)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action SpySoundRageEndTaunt(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, SpyRandomScream2[GetRandomInt(0, sizeof(SpyRandomScream2)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntSpy(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (headmeter[client] >= 4 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                g_iTauntedSpys[client] = 1;
                Format(s, PLATFORM_MAX_PATH, "saxton_hale/spy_special_auto_used.wav");
                CreateTimer(0.1, UseSpyRage, client);
                CreateTimer(0.3, SpyCineFX, client);
                CreateTimer(1.5, SpySoundRage, client);
                CreateTimer(7.0, SpySoundRageEnd, client);
                CreateTimer(9.2, SpySoundRageEndTaunt, client);
                headmeter[client] = 0;
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action DoTauntScout3(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
        
    if (SpeedDamage[client] >= 2281337)
        return Plugin_Continue;
    
    char s[PLATFORM_MAX_PATH];
    if (SpeedDamage[client]/SodaDMG >= 1 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                Format(s, PLATFORM_MAX_PATH, ScoutSodaPopper_Sound);
                CreateTimer(1.5, ScoutRandomSound2, client);
                CreateTimer(6.9, ScoutRageEnd3, client);
            }
        }
        
        float pPos[3] = {0.0, 0.0, 10.0};
        
        AttachParticle(client, "heavy_ring_of_fire_child03", 1.0, pPos, true);
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        SpeedDamage[client] = 2281337;
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action ScoutRandomSound2(Handle hTimer, any client) {
    char s[PLATFORM_MAX_PATH];
    
    switch (GetRandomInt(0, 7)) {
        case 0:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_dominationhvy07.mp3");
        case 1:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_dominationmed01.mp3");
        case 2:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_dominationpyr03.mp3");
        case 3:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_dominationsct01.mp3");
        case 4:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_dominationsnp05.mp3");
        case 5:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_laughlong01.mp3");
        case 6:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_mvm_loot_rare03.mp3");
        case 7:            strcopy(s, PLATFORM_MAX_PATH, "vo/scout_revenge07.mp3");
    }
    
    PlaySoundForPlayers(s);
}

public Action UseScoutRage2(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        float pPos[3] = {0.0, 0.0, 10.0};
        AttachParticle(client, "heavy_ring_of_fire_child03", 1.0, pPos, true);
        TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action ScoutSoundRage2(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, ScoutRandomScream2[GetRandomInt(0, sizeof(ScoutRandomScream2)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action ScoutSoundRageEnd2(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action ScoutRageEnd3(Handle hTimer, int client) {
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    if(IsPlayerAlive(client)) {
        CreateTimer(0.1, Timer_CheckStuck, GetClientUserId(client));
        SpeedDamage[client] = 0;
        
        char s[PLATFORM_MAX_PATH];
        Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
        EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
        TeleportToMultiMapSpawn(client, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? OtherTeam : 0);
    }
    
    return Plugin_Continue;
}

public Action SpySoundRageEnd(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    g_iTauntedSpys[client] = 0;
    return Plugin_Continue;
}

public Action DoTauntDemo(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (PersDamage[client]/PersDMG >= 1 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                Format(s, PLATFORM_MAX_PATH, "misc/halloween/merasmus_appear.wav");
                CreateTimer(0.1, UseDemoRage, client);
                CreateTimer(9.0, DemoSoundRageEnd, client);
                CreateTimer(9.9, UseDemoRageFIX, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        PersDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action DoTauntDemo2(int client, char[] command, int argc) {
    if (!g_bEnabled)
        return Plugin_Continue;
    
    if (!IsWeaponSlotActive(client, TFWeaponSlot_Primary))
        return Plugin_Continue;
    
    int iHealth = GetEntProp(client, Prop_Send, "m_iHealth"), iMaxHealth = (FindWearableOnPlayer(client, 405) || FindWearableOnPlayer(client, 608)) ? 200 : 175;
    if (iMaxHealth <= iHealth)
        return Plugin_Continue;
    
    /* Здесь типа код получения активной анимации и проверки на соответствие, но его здесь пока что нет, т.к. ХЗ, как получать имя активной анимации (TODO крч)

    char sAnimation[32];
    if (StrEqual(sAnimation, "taunt03"))
        return Plugin_Continue; */
    
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner"))) {
        int iNewHealth = -iHealth+iMaxHealth;
        if (iNewHealth > 75) iNewHealth = 75;
        SetEntProp(client, Prop_Send, "m_iHealth", iHealth+iNewHealth);
    }
    return Plugin_Continue;
}

public Action UseDemoRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        float pPos[3] = {0.0, 0.0, 10.0};
        AttachParticle(client, "heavy_ring_of_fire_child03", 1.0, pPos, true);
        ResizePlayer(client, 0.5);
        TF2_AddCondition(client, TFCond_DefenseBuffed, 10.0);
    }
    if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
    {
        TF2_RemoveCondition(client, TFCond_Dazed);
        MakeModelTimer(null);
    }

    return Plugin_Continue;
}

public Action DemoSoundRageEnd(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action UseDemoRageFIX(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    ResizePlayer(client, 1.0);
    
    if(IsPlayerAlive(client))
    {
        CreateTimer(0.1, Timer_CheckStuck, GetClientUserId(client));
    }
    
    
    return Plugin_Continue;
}

public Action Timer_CheckStuck(Handle hTimer, any iUserId)
{
    int client = GetClientOfUserId(iUserId);
    if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsEntityStuck(client)) TeleportToMultiMapSpawn(client, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? OtherTeam : 0);
}

public Action DoTauntHeavyOne(int client, char[] command, int argc)
{
    float pos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    pos[2] += 20.0;
    if (!g_bEnabled)
        return Plugin_Continue;
    if (NatDamage[client]/NatDMG >= 1 && IsPlayerAlive(client))
    {
        char s[PLATFORM_MAX_PATH];
        Format(s, PLATFORM_MAX_PATH, "weapons/teleporter_send.wav");
        EmitSoundToAll(s, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
        float pPos[3] = {0.0,0.0,10.0};
        AttachParticle(client, "teleported_blue", 1.0, pPos, true);
        CreateTimer(0.6, UseHeavyRageOne, client);
        NatDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseHeavyRageOne(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        TeleportToMultiMapSpawn(client, (!IsNextTime(e_flNextAllowOtherSpawnTele)) ? OtherTeam : 0);
        MakeModelTimer(null);
    }
    return Plugin_Continue;
}

public Action DoTauntHeavyTwo(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (HuoDamage[client]/HuoDMG >= 1 && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                float pPos[3] = {0.0,0.0,80.0};
                AttachParticle(client, "mini_fireworks", 12.0, pPos, true);
                Format(s, PLATFORM_MAX_PATH, "ui/duel_score_behind.wav");
                CreateTimer(0.1, UseHeavyRageTwo, client);
                CreateTimer(11.0, HeavySoundRageEndTwo, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        HuoDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseHeavyRageTwo(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        TF2_AddCondition(client, TFCond_CritOnFlagCapture, 12.0);
    }
    return Plugin_Continue;
}

public Action HeavySoundRageEndTwo(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntHeavyThree(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (TomDamage[client]/TomDMG >= 1 && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                float pPos[3] = {0.0,0.0,80.0};
                AttachParticle(client, "mini_fireworks", 12.0, pPos, true);
                Format(s, PLATFORM_MAX_PATH, "ui/duel_score_behind.wav");
                CreateTimer(0.1, UseHeavyRageThree, client);
                CreateTimer(11.0, HeavySoundRageEndThree, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        TomDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseHeavyRageThree(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        MakeModelTimer(null);
        InsertCond(client, TFCond_SpeedBuffAlly, 7.0);
    }
    return Plugin_Continue;
}

public Action HeavySoundRageEndThree(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntHeavyFour(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (BetDamage[client]/BetDMG >= 1 && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                float pPos[3] = {0.0, 0.0, 80.0};
                AttachParticle(client, "mini_fireworks", 8.0, pPos, true);
                Format(s, PLATFORM_MAX_PATH, "ui/duel_score_behind.wav");
                CreateTimer(0.1, UseHeavyRageFour, client);
                CreateTimer(10.5, HeavySoundRageEndFour, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        BetDamage[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseHeavyRageFour(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(client, TFCond_Taunting);
        // TF2_AddCondition(Hale, TFCond_TeleportedGlow, 8.0);
        MakeModelTimer(null);
        if (IsPlayerAlive(client)) {

            int iShieldEnt = CreateEntityByName("prop_dynamic");

            /*if (iShieldEnt != -1) {
                float PlyPos[3];
                GetEntPropVector(client, Prop_Send, "m_vecOrigin", PlyPos);
                TeleportEntity(iShieldEnt, PlyPos, NULL_VECTOR, NULL_VECTOR);
                DispatchKeyValue(iShieldEnt, "model", "models/effects/resist_shield/resist_shield.mdl");
                DispatchSpawn(iShieldEnt);
            
                SetVariantString("idle");
                AcceptEntityInput(iShieldEnt, "SetDefaultAnimation");
                AcceptEntityInput(iShieldEnt, "SetAnimation");
            
                SetEntProp(iShieldEnt, Prop_Send, "m_nSkin", 1);
                SetEntPropEnt(iShieldEnt, Prop_Send, "m_hOwnerEntity", client);
                // SetParent(client, iShieldEnt);
                AcceptEntityInput(iShieldEnt, "TurnOn");
            }*/
        
            float MedicResistFire[3] = {0.0, 0.0, 10.0};
            BlockDamage[client] = true;
            TF2_AddCondition(client, _TFCond(58), 12.0);
            AttachParticle(client, "medic_resist_fire", 12.0, MedicResistFire, true);            
            SetEntityGravity(client, 0.10);
            int iEntWeapon;
            for (int iWeapon = 0; iWeapon<=5; iWeapon++) {
                if ((iEntWeapon = GetPlayerWeaponSlot(client, iWeapon)) > MaxClients+1)
                    SetNextAttack(iEntWeapon, 12.0);
            }
        
            DataPack hDP = new DataPack();
            hDP.WriteCell(client);
            hDP.WriteCell(iShieldEnt);
            hDP.Reset();
        
            AQUACURE_EntShield[client] = iShieldEnt;
            // AQUACURE_Available = false;

            CreateTimer(12.0, AQUACURE_Disable, hDP);
	    }
    }
    return Plugin_Continue;
}

public Action HeavySoundRageEndFour(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntMedic(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    if (AmpDefend[client]/AmpDEF >= 1 && IsPlayerAlive(client))
    {
        float pos[3];
        pos[2] += 20.0;
        {
            {
                float pPos[3] = {0.0, 0.0, 80.0};
                AttachParticle(client, "mvm_levelup1", 10.0, pPos, true);
                Format(s, PLATFORM_MAX_PATH, "misc/ks_tier_04_kill_01.wav");
                CreateTimer(0.1, UseMedicRage, client);
                
                Handle DPAmp = CreateTrie();
                CreateTimer(0.2, MedicAmpShield, DPAmp);
                SetTrieValue(DPAmp, "medic", client);
                SetTrieValue(DPAmp, "time", 8.8);
                
                CreateTimer(1.5, MedicSoundRage, client);
                CreateTimer(9.0, MedicSoundRageEnd, client);
            }
        }
        EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
        AmpDefend[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseMedicRage(Handle hTimer, any MEDIC)
{
    if (!IsValidClient(MEDIC)) return Plugin_Continue;
    if (!GetEntProp(MEDIC, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(MEDIC, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(MEDIC, TFCond_Taunting);
        MakeModelTimer(null);
        
        MedicRage_TimerFloat[MEDIC] = 0.0;
        MedicRage_TimerHndl[MEDIC] = CreateTimer(1.0, MedicRage_Timer, MEDIC, TIMER_REPEAT);
    }
    return Plugin_Continue;
}

public Action MedicRage_Timer(Handle TimerHndlMEDIC, int MedicID)
{
    if (MedicRage_TimerFloat[MedicID] != 10.0)
    {
        float pos[3];
        float pos2[3];
        int i;
        float distance;
        
        if (!IsValidClient(MedicID)) return Plugin_Continue;
        GetEntPropVector(MedicID, Prop_Send, "m_vecOrigin", pos);
        for (i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && (i != MedicID))
            {
                GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
                distance = GetVectorDistance(pos, pos2);
                if (GetClientTeam(i) != HaleTeam && distance < 400)
                {
                    TF2_AddCondition(i, TFCond_DefenseBuffed, 1.0);
                    TF2_AddCondition(i, _TFCond(28), 1.0);
                }
            }
        }

        MedicRage_TimerFloat[MedicID] += 1.0;

        return Plugin_Continue;
    }

    return Plugin_Stop;
}

public Action MedicSoundRage(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    strcopy(s, PLATFORM_MAX_PATH, MedicRandomScream[GetRandomInt(0, sizeof(MedicRandomScream)-1)]);
    EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action MedicSoundRageEnd(Handle hTimer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    char s[PLATFORM_MAX_PATH];
    Format(s, PLATFORM_MAX_PATH, "weapons/weapon_crit_charged_off.wav");
    EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
    return Plugin_Continue;
}

public Action DoTauntSniper(int client, char[] command, int argc)
{
    if (!g_bEnabled)
        return Plugin_Continue;
    if (SniperActivity[client] >= 100 && IsPlayerAlive(client))
    {
        CreateMedicShield(client);
        SniperActivity[client] = 0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action DoTaunt(int client, char[] command, int argc)
{
    if (!g_bEnabled) return Plugin_Continue;
    
    if (Hale != client) {
        switch(TF2_GetPlayerClass(client))
        {
            case TFClass_Scout:
            {
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 772 && (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 325 || GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 452))
                {
                    if (BasherDamage[client]/BasherDMG >= 1 && SpeedDamage[client]/SpeedDMG >= 1 && IsPlayerAlive(client))
                    {
                        switch(GetEntProp(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex"))
                        {
                            case 772:                                                    return DoTauntScout2(client, command, argc);
                            case 325, 452:                                                return DoTauntScout(client, command, argc);
                        }
                    }
                }
                
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 772 && SpeedDamage[client]/SpeedDMG >= 1 && IsPlayerAlive(client))            return DoTauntScout2(client, command, argc);
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 448 && SpeedDamage[client]/SodaDMG >= 1 && IsPlayerAlive(client))            return DoTauntScout3(client, command, argc);
                if ((GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 325 || GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 452) && BasherDamage[client]/BasherDMG >= 1 && IsPlayerAlive(client)) return DoTauntScout(client, command, argc);
                
            }
            case TFClass_DemoMan:
            {
                int iIndex = GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee);
                if (iIndex == 404)                                 return DoTauntDemo(client, command, argc);
                if (FindItemInArray(iIndex, {1, 191, 609}, 3))    return DoTauntDemo2(client, command, argc);
            }
            
            case TFClass_Heavy:
            {
                switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                {
                    case 41:            return DoTauntHeavyOne(client, command, argc);
                    case 811:            return DoTauntHeavyTwo(client, command, argc);
                    case 424:            return DoTauntHeavyThree(client, command, argc);
                    case 312:            return DoTauntHeavyFour(client, command, argc);
                }
            }
            
            case TFClass_Medic:
            {
                if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 304)             return DoTauntMedic(client, command, argc);
            }
            
            case TFClass_Sniper:
            {
                return DoTauntSniper(client, command, argc);
            }

            case TFClass_Spy:
            {
                return DoTauntSpy(client, command, argc);
            }
        }
    }
    
    if (client != Hale) return Plugin_Continue;

    if (!IfDoNextTime(e_flNextBossTaunt, 1.5)) // Prevent double-tap rages
    {
        return Plugin_Handled;
    }

    char s[PLATFORM_MAX_PATH];
    if (HaleRage/RageDMG >= 1)
    {
        // ASH STATS UPDATE
        ASHStats[Rages]++;
        // ASH STATS UPDATE
        
        float pos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
        pos[2] += 20.0;
        Action act = Plugin_Continue;
        Call_StartForward(OnHaleRage);
        float dist;
        float newdist;
        switch (Special)
        {
            case ASHSpecial_Vagineer: dist = RageDist/(1.5);
            case ASHSpecial_Bunny: dist = RageDist/(1.5);
            case ASHSpecial_CBS: dist = RageDist/(1.60);
            case ASHSpecial_HHH, ASHSpecial_Agent: dist = RageDist/(1.55);
            default: dist = RageDist;
        }
        newdist = dist;
        Call_PushFloatRef(newdist);
        Call_Finish(act);
        if (act != Plugin_Continue && act != Plugin_Changed)
            return Plugin_Continue;
        if (act == Plugin_Changed) dist = newdist;
        TF2_AddCondition(Hale, _TFCond(42), 4.0);
        switch (Special)
        {
            case ASHSpecial_Vagineer:
            {
                int audioVagineer = GetRandomInt(0, 2);
                if (audioVagineer == 1)
                    strcopy(s, PLATFORM_MAX_PATH, VagineerRageSoundA);
                else if (audioVagineer == 2)
                    strcopy(s, PLATFORM_MAX_PATH, VagineerRageSoundB);
                else
                    Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerRageSound2, GetRandomInt(1, 2));
                TF2_AddCondition(Hale, TFCond_Ubercharged, 99.0);
                UberRageCount = 0.0;

                CreateTimer(0.6, UseRage, dist);
                CreateTimer(0.1, UseUberRage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
            case ASHSpecial_HHH:
            {
                Format(s, PLATFORM_MAX_PATH, "%s", HHHRage2);
                CreateTimer(0.6, UseRage, dist);
            }
#if defined EASTER_BUNNY_ON
            case ASHSpecial_Bunny:
            {
                strcopy(s, PLATFORM_MAX_PATH, BunnyRage[GetRandomInt(1, sizeof(BunnyRage)-1)]);
                EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
                int weapon = SpawnWeapon(client, "tf_weapon_grenadelauncher", 19, 100, 5, "6 ; 0.1 ; 411 ; 150.0 ; 413 ; 1.0 ; 37 ; 0.0 ; 280 ; 17 ; 477 ; 1.0 ; 467 ; 1.0 ; 181 ; 2.0 ; 252 ; 0.7 ; 2 ; 1.35");
                SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
                SetEntProp(weapon, Prop_Send, "m_iClip1", 50);
                SetAmmo(client, TFWeaponSlot_Primary, 0);

                CreateTimer(0.6, UseRage, dist);
            }
#endif
            case ASHSpecial_CBS:
            {
                if (GetRandomInt(0, 1))
                    Format(s, PLATFORM_MAX_PATH, "%s", CBS1);
                else
//                    Format(s, PLATFORM_MAX_PATH, "%s", CBS3);
                    strcopy(s, PLATFORM_MAX_PATH, CBS3[GetRandomInt(0, sizeof(CBS3)-1)]);
                EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
                TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
                SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_compound_bow", 1005, 100, 5, "2 ; 2.1 ; 6 ; 0.5 ; 37 ; 0.0 ; 280 ; 19 ; 551 ; 1"));
                SetAmmo(client, TFWeaponSlot_Primary, ((RedAlivePlayers >= CBS_MAX_ARROWS) ? CBS_MAX_ARROWS : RedAlivePlayers));
                CreateTimer(0.6, UseRage, dist);
                CreateTimer(0.1, UseBowRage);
            }
            case ASHSpecial_Agent:
            {
                strcopy(s, PLATFORM_MAX_PATH, Agent_Rage);
                CreateTimer(0.6, UseRage, dist);
                CreateTimer(0.8, CreateHologram);
            }
            default:
            {
                Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, GetRandomInt(1, 4));
                CreateTimer(0.6, UseRage, dist);
            }
        }
        
        if (GetPlayersInTeam(OtherTeam) < 17)
            iHaleSpecialPower += 100;
        else
            iHaleSpecialPower += 150;
        
        if (Special != ASHSpecial_Agent) {
            EmitSoundToAll(s, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, pos, NULL_VECTOR, true, 0.0);
            EmitSoundToAll(s, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, pos, NULL_VECTOR, true, 0.0);
        } else {
            //EmitAmbientSound(s, pos, client, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
            //EmitAmbientSound(s, pos, client, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL);
            PlaySoundForPlayers(s);
            PlaySoundForPlayers(s);
        }
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && i != Hale)
            {
                EmitSoundToClient(i, s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, pos, NULL_VECTOR, true, 0.0);
                EmitSoundToClient(i, s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), client, pos, NULL_VECTOR, true, 0.0);
            }
        }
        HaleRage = 0;
        ASHFlags[Hale] &= ~ASHFLAG_BOTRAGE;
    }

    return Plugin_Continue;
}

public Action DoSuicide(int client, char[] command, int argc)
{
    if (g_bEnabled && (ASHRoundState == ASHRState_Waiting || ASHRoundState == ASHRState_Active))
    {
        if (client == Hale && !IsNextTime(e_flNextAllowBossSuicide))
        {
            PrintToChat(client, "Do not suicide as Hale. Use !resetq instead.");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action DoSuicide2(int client, char[] command, int argc)
{
    if (g_bEnabled && client == Hale && !IsNextTime(e_flNextAllowBossSuicide))
    {
        PrintToChat(client, "You can't change teams this early.");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action UseRage(Handle hTimer, any dist)
{
    float pos[3];
    float pos2[3];
    int i;
    float distance;
    
    if (!IsValidClient(Hale)) return Plugin_Continue;
    if (!GetEntProp(Hale, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(Hale, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(Hale, TFCond_Taunting);
        MakeModelTimer(null);
    }
    GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
    for (i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && (i != Hale))
        {
            if (!(Special == ASHSpecial_Agent && IsHologram(i))) {
                GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
                distance = GetVectorDistance(pos, pos2);
                if (!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && distance < dist)
                {
                    int flags = TF_STUNFLAGS_GHOSTSCARE;
                    if (Special != ASHSpecial_HHH)
                    {
                        flags |= TF_STUNFLAG_NOSOUNDOREFFECT;
                        float ppos[3] = {0.0, 0.0, 75.0};
                        AttachParticle(i, "yikes_fx", 5.0, ppos, true);
                    }
                    if (ASHRoundState != ASHRState_Waiting) {
                        TF2_StunPlayer(i, GetStunTime(i), _, flags, (Special == ASHSpecial_HHH ? 0 : Hale));
                        TF2_AddCondition(i, _TFCond(65), GetStunTime(i));
                        if (TF2_GetPlayerClass(i) == TFClass_DemoMan && GetIndexOfWeaponSlot(i, TFWeaponSlot_Secondary) == 1150)
                        {
                            int iSticky = -1;
                            //new iStickyCount = 0;
                            while ((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != -1)
                            {
                                if (i == GetEntPropEnt(iSticky, Prop_Send, "m_hThrower"))
                                {
                                    SDKCall(g_CTFGrenadeDetonate, iSticky);
                                    //iStickyCount++;
                                }   
                            }       
                            //PrintToChatAll("%i stickies found", iStickyCount);
                        }
                    }
                    if (GetIndexOfWeaponSlot(i, TFWeaponSlot_Melee) == 331)			// Heavy Nerf: 18.11.2016
                    {
                        SetNextAttack(GetPlayerWeaponSlot(i, TFWeaponSlot_Melee), 5.0);
                        plSteelBlock[i] = true;
                        CreateTimer(5.0, SteelUnban, i);
                    }
                }
            }
        }
    }
    i = -1;
    while ((i = FindEntityByClassname2(i, "obj_sentrygun")) != -1)
    {
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
        distance = GetVectorDistance(pos, pos2);
        if (dist <= RageDist/3) dist = RageDist/2;
        if (distance < dist)    //(!mode && (distance < RageDist)) || (mode && (distance < RageDist/2)))
        {
            SetEntProp(i, Prop_Send, "m_bDisabled", 1);
            float ppos[3] = {0.0, 0.0, 75.0};
            AttachParticle(i, "yikes_fx", 3.0, ppos, true);
            if (newRageSentry)
            {
                SetVariantInt(GetEntProp(i, Prop_Send, "m_iHealth")/2);
                AcceptEntityInput(i, "RemoveHealth");
            }
            else
            {
                SetEntProp(i, Prop_Send, "m_iHealth", GetEntProp(i, Prop_Send, "m_iHealth")/2);
            }
            CreateTimer(8.0, EnableSG, EntIndexToEntRef(i));
        }
    }
    i = -1;
    while ((i = FindEntityByClassname2(i, "obj_dispenser")) != -1)
    {
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
        distance = GetVectorDistance(pos, pos2);
        if (dist <= RageDist/3) dist = RageDist/2;
        if (distance < dist)    //(!mode && (distance < RageDist)) || (mode && (distance < RageDist/2)))
        {
            SetVariantInt(1);
            AcceptEntityInput(i, "RemoveHealth");
        }
    }
    i = -1;
    while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
    {
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
        distance = GetVectorDistance(pos, pos2);
        if (dist <= RageDist/3) dist = RageDist/2;
        if (distance < dist)    //(!mode && (distance < RageDist)) || (mode && (distance < RageDist/2)))
        {
            SetVariantInt(1);
            AcceptEntityInput(i, "RemoveHealth");
        }
    }

    return Plugin_Continue;
}

public Action SteelUnban(Handle hTimer, any Heavy) {
    plSteelBlock[Heavy] = false;
}

public Action UseUberRage(Handle hTimer, any param)
{
    if (!IsValidClient(Hale))
        return Plugin_Stop;
    if (UberRageCount == 1)
    {
        if (!GetEntProp(Hale, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(Hale, Prop_Send, "m_hHighFivePartner")))
        {
            TF2_RemoveCondition(Hale, TFCond_Taunting);
            MakeModelTimer(null); // should reset Hale's animation
        }
    }
    else if (UberRageCount >= 100)
    {
        if (defaulttakedamagetype == 0) defaulttakedamagetype = 2;
        SetEntProp(Hale, Prop_Data, "m_takedamage", defaulttakedamagetype);
        defaulttakedamagetype = 0;
        TF2_RemoveCondition(Hale, TFCond_Ubercharged);
        return Plugin_Stop;
    }
    else if (UberRageCount >= 85 && !TF2_IsPlayerInCondition(Hale, TFCond_UberchargeFading))
    {
        TF2_AddCondition(Hale, TFCond_UberchargeFading, 3.0);
    }
    if (!defaulttakedamagetype)
    {
        defaulttakedamagetype = GetEntProp(Hale, Prop_Data, "m_takedamage");
        if (defaulttakedamagetype == 0) defaulttakedamagetype = 2;
    }
    SetEntProp(Hale, Prop_Data, "m_takedamage", 0);
    UberRageCount += 1.0;
    return Plugin_Continue;
}

public Action UseBowRage(Handle hTimer)
{
    if (!GetEntProp(Hale, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(Hale, Prop_Send, "m_hHighFivePartner")))
    {
        TF2_RemoveCondition(Hale, TFCond_Taunting);
        MakeModelTimer(null); // should reset Hale's animation
    }
    SetAmmo(Hale, 0, ((RedAlivePlayers >= CBS_MAX_ARROWS) ? CBS_MAX_ARROWS : RedAlivePlayers));
    return Plugin_Continue;
}

stock void SpawnManyAmmoPacks(int client, char[] model, int skin=0, int num=14, float offsz = 30.0)
{
    float pos[3];
    float vel[3];
    float ang[3];
    
    ang[0] = 90.0;
    ang[1] = 0.0;
    ang[2] = 0.0;
    GetClientAbsOrigin(client, pos);
    pos[2] += offsz;
    for (int i = 0; i < num; i++)
    {
        vel[0] = GetRandomFloat(-400.0, 400.0);
        vel[1] = GetRandomFloat(-400.0, 400.0);
        vel[2] = GetRandomFloat(300.0, 500.0);
        pos[0] += GetRandomFloat(-5.0, 5.0);
        pos[1] += GetRandomFloat(-5.0, 5.0);
        int ent = CreateEntityByName("tf_ammo_pack");
        if (!IsValidEntity(ent)) continue;
        SetEntityModel(ent, model);
        DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1"); //for safety, but it shouldn't act like a normal ammopack
        SetEntProp(ent, Prop_Send, "m_nSkin", skin);
        SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
        SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
        SetEntProp(ent, Prop_Send, "m_triggerBloat", 24);
        SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
        SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
        SetEntProp(ent, Prop_Send, "m_iTeamNum", 2);
        TeleportEntity(ent, pos, ang, vel);
        DispatchSpawn(ent);
        TeleportEntity(ent, pos, ang, vel);
        SetEntProp(ent, Prop_Data, "m_iHealth", 900);
        int offs = GetEntSendPropOffs(ent, "m_vecInitialVelocity", true);
        SetEntData(ent, offs-4, 1, _, true);
    }
}

public Action Timer_Damage(Handle hTimer, any id)
{
    int client = GetClientOfUserId(id);
    if (IsValidClient(client)) { // IsValidClient(client, false)
        CPrintToChat(client, "{ash}[ASH]{default} %t. %t %i",
            "vsh_damage", Damage[client],
            "vsh_scores", RoundFloat(Damage[client] / 600.0)
        );
    }
    return Plugin_Continue;
}

public Action CheckAlivePlayers(Handle hTimer)
{
    if (ASHRoundState != ASHRState_Active)
    {
        return Plugin_Continue;
    }
    RedAlivePlayers = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && (GetEntityTeamNum(i) == OtherTeam))
            RedAlivePlayers++;
    }
    if (Special == ASHSpecial_CBS && GetAmmo(Hale, 0) > RedAlivePlayers && RedAlivePlayers != 0) SetAmmo(Hale, 0, RedAlivePlayers);
    if (RedAlivePlayers == 0)
        ForceTeamWin(HaleTeam);
    else if (RedAlivePlayers == 1 && IsValidClient(Hale) && ASHRoundState == ASHRState_Active)
    {
        float pos[3];
        char s[PLATFORM_MAX_PATH];
        GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
        if (Special != ASHSpecial_HHH)
        {
            if (Special == ASHSpecial_CBS)
            {
                if (!GetRandomInt(0, 2))
                    Format(s, PLATFORM_MAX_PATH, "%s", CBS0);
                else
                {
                    Format(s, PLATFORM_MAX_PATH, "%s%02i.mp3", CBS4, GetRandomInt(1, 25));
                }
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
            }
#if defined EASTER_BUNNY_ON
            else if (Special == ASHSpecial_Bunny)
                strcopy(s, PLATFORM_MAX_PATH, BunnyLast[GetRandomInt(0, sizeof(BunnyLast)-1)]);
#endif
            else if (Special == ASHSpecial_Vagineer)
                strcopy(s, PLATFORM_MAX_PATH, VagineerLastA);
            else if (Special == ASHSpecial_Agent)
                strcopy(s, PLATFORM_MAX_PATH, Agent_LastAlive[GetRandomInt(0,5)]);
            else
            {
                int see = GetRandomInt(0, 5);
                switch (see)
                {
                    case 0: strcopy(s, PLATFORM_MAX_PATH, HaleComicArmsFallSound);
                    case 1: Format(s, PLATFORM_MAX_PATH, "%s0%i.mp3", HaleLastB, GetRandomInt(1, 4));
                    case 2: strcopy(s, PLATFORM_MAX_PATH, HaleKillLast132);
                    default: Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, GetRandomInt(1, 5));
                }
            }
            if (Special != ASHSpecial_Agent) {
                EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, false, 0.0);
                EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, ((Special==ASHSpecial_MiniHale)?RoundToNearest((175 / (1 + (6 * 0.5))) + 75):100), Hale, pos, NULL_VECTOR, false, 0.0);
            } else {
                PlaySoundForPlayers(s);
                PlaySoundForPlayers(s);
            }
        }
    }
    
    if (!PointType && (RedAlivePlayers <= (AliveToEnable = GetConVarInt(cvarAliveToEnable))) && !PointReady)
    {
        PrintHintTextToAll("%t", "vsh_point_enable", RedAlivePlayers);
        if (RedAlivePlayers == AliveToEnable) EmitSoundToAll("vo/announcer_am_capenabled02.mp3");
        else if (RedAlivePlayers < AliveToEnable)
        {
            char s[PLATFORM_MAX_PATH];
            Format(s, PLATFORM_MAX_PATH, "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
            EmitSoundToAll(s);
        }
        SetControlPoint(true);
        PointReady = true;
    }
    return Plugin_Continue;
}

public Action ResurrectPyro(Handle hTimer, any PyroEntity) {
    SetEntityMoveType(PyroEntity, MOVETYPE_WALK);
    SetEntityGravity(PyroEntity, 1.0);
    TF2_RemoveCondition(PyroEntity, _TFCond(28));
    TF2_RespawnPlayer(PyroEntity);
    plManmelterUsed[PyroEntity] = 1;
    BuddhaSwitch(PyroEntity, false);
}

public Action ParticlePyro_ray(Handle hTimer, any PyroEntity) {
    float pPos[3] = {0.0, 0.0, 10.0};
    AttachParticle(PyroEntity, "god_rays", 3.0, pPos, true);
}

public Action ParticlePyro_smoke(Handle hTimer, any PyroEntity) {
    float pPos[3] = {0.0, 0.0, 10.0};
    AttachParticle(PyroEntity, "god_rays_fog", 1.0, pPos, true);
}

public Action ParticlePyro_tele(Handle hTimer, any PyroEntity) {
    float pPos[3] = {0.0, 0.0, 10.0};
    AttachParticle(PyroEntity, "spell_batball_impact2_blue", 1.0, pPos, true);
}

public Action ParticlePyro_tele2(Handle hTimer, any PyroEntity) {
    float pPos[3] = {0.0, 0.0, 10.0};
    AttachParticle(PyroEntity, "teleported_blue", 1.0, pPos, true);
}

public Action FreezePyro(Handle hTimer, any PyroEntity) {
    SetEntityMoveType(PyroEntity, MOVETYPE_NONE);
}

public Action StunPyro(Handle hTimer, any PyroEntity) {
    TF2_StunPlayer(PyroEntity, 2.9, 0.0, TF_STUNFLAGS_BIGBONK, PyroEntity); // Stun
}

public Action IsStunnedBlockDisable(Handle hTimer, any Soldier) {
    isStunnedBlock[Soldier] = false;
}

public Action EnableHuntsTaunt(Handle hTimer, any Weapon) {
    isHaleStunBanned = false;
}

public Action DisableHuntsTaunt(Handle hTimer, any Weapon) {
    isHaleStunBanned = true;
}

public Action DisableDamageInflictor(Handle hTimer) {
    isHaleNeedManyDamage = false;
    isHaleStunBanned = false;
    
    TF2Attrib_RemoveByDefIndex(Hale, 252);
}

public Action StunPlayer_Timer(Handle hTimer, any iClient) {
    iClient = GetClientOfUserId(iClient);
    if (!iClient)
        return Plugin_Stop;

    TF2_StunPlayer(iClient, 4.0, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
    return Plugin_Continue;
}

/*
 Teleports a client to a random spawn location
 By: Chdata

 iClient - Client to teleport
 iTeam - Team of spawn points to use. If not specified or invalid team number, teleport to ANY spawn point.

 TODO: Make it not HHH specific

*/
/*stock TeleportToSpawn(iClient, iTeam = 0)
{
    new iEnt = -1;
    decl Float:vPos[3];
    decl Float:vAng[3];
    Handle hArray = CreateArray();
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        if (iTeam <= 1) // Not RED (2) nor BLu (3)
        {
            PushArrayCell(hArray, iEnt);
        }
        else
        {
            new iSpawnTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
            if (iSpawnTeam == iTeam)
            {
                PushArrayCell(hArray, iEnt);
            }
        }
    }

    iEnt = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray) - 1));
    CloseHandle(hArray);

    // Technically you'll never find a map without a spawn point. Not a good map at least.
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
    GetEntPropVector(iEnt, Prop_Send, "m_angRotation", vAng);
    TeleportEntity(iClient, vPos, vAng, NULL_VECTOR);

    if (Special == ASHSpecial_HHH)
    {
        AttachParticle(i, "ghost_appearation", 3.0);
        EmitSoundToAll("misc/halloween/spell_teleport.wav", _, _, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vPos, NULL_VECTOR, false, 0.0);
    }
}*/


void SpawnSmallHealthPackAt(int client, int ownerteam = 0)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return; // IsValidClient(client, false)
    int healthpack = CreateEntityByName("item_healthkit_small");
    float pos[3];
    GetClientAbsOrigin(client, pos);
    pos[2] += 20.0;
    if (IsValidEntity(healthpack))
    {
        DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
        DispatchSpawn(healthpack);
        SetEntProp(healthpack, Prop_Send, "m_iTeamNum", ownerteam, 4);
        SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
        float vel[3];
        vel[0] = float(GetRandomInt(-10, 10)), vel[1] = float(GetRandomInt(-10, 10)), vel[2] = 50.0;
        TeleportEntity(healthpack, pos, NULL_VECTOR, vel);
    }
}

public Action Timer_StopTickle(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
    if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner"))) TF2_RemoveCondition(client, TFCond_Taunting);
}

public Action Timer_DeathMark(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;
    if (TF2_IsPlayerInCondition(Hale, TFCond_MarkedForDeath))
        TF2_RemoveCondition(Hale, TFCond_MarkedForDeath);
    return Plugin_Continue;
}

public Action Timer_CheckBuffRage(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
    }
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
    if (!IsValidClient(client) || !g_bEnabled || ASHRoundState != ASHRState_Active) return Plugin_Continue; // IsValidClient(client, false)
    
    // HHH can climb walls
    if (IsValidEntity(weapon) && Special == ASHSpecial_HHH && client == Hale && HHHClimbCount <= 9 && ASHRoundState > ASHRState_Waiting)
    {
        int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

        if (index == 266 && StrEqual(weaponname, "tf_weapon_sword", false))
        {
            SickleClimbWalls(client, weapon);
            WeighDownTimer = 0.0;
            HHHClimbCount++;
        }
    }

    if (client == Hale)
    {
        if (Special == ASHSpecial_Agent)
            AgentHelper_ChangeTimeBeforeInvis(1.6, Hale);
        
        if (Special == ASHSpecial_Bunny && IsWeaponSlotActive(Hale, TFWeaponSlot_Primary) && StrEqual(weaponname, "tf_weapon_cannon")) {
            CreateTimer(1.2, RemoveWeapon, SpecialWeapon);
        }
        
        if (ASHRoundState != ASHRState_Active) return Plugin_Continue;
        if (TF2_IsPlayerCritBuffed(client)) return Plugin_Continue;
        if (!haleCrits)
        {
            result = false;
            return Plugin_Changed;
        }
    }
    else if (IsValidEntity(weapon) && IsValidClient(client))
    {
        SpecialPlayers_LastActiveWeapons[client] = weapon;

        if (TF2_GetPlayerClass(client) == TFClass_Sniper) {
            int WeaponID = GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary);
            if ((WeaponID == 56 || WeaponID == 1005 || WeaponID == 1092) && IsWeaponSlotActive(client, TFWeaponSlot_Primary)) {
                if (SniperActivity[client] != 100) SniperActivity[client] -= 5;
            }
            if (IsWeaponSlotActive(client, TFWeaponSlot_Primary)) {
                BB_Sniper_ShootTime[client] = RoundToCeil(GetGameTime());
                CreateTimer(0.3, AllSnipers_ShootTimer, client);
            } else if (IsWeaponSlotActive(client, TFWeaponSlot_Melee)) {
                SickleClimbWalls(client, weapon);
            }

            if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 232 && GetRandomInt(0, 100) < 1) { // (0, 1000) - 0.1 o_o
                TF2Attrib_SetByDefIndex(weapon, 2, 200.0);
                TF2Attrib_RemoveByDefIndex(weapon, 1);

                UTIL_CreateBelatedAttributeDelete(0.5, weapon, 2);
                UTIL_CreateBelatedAttributeChange(0.5, weapon, 1, 0.0);
            }
        }

        if (TF2_GetPlayerClass(client) == TFClass_Sniper && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 171 && TF2_IsPlayerInCondition(client, _TFCond(66)))
        {
            TF2_RemoveCondition(client, _TFCond(66));
            EmitSoundToClient(client, "misc/halloween/spell_stealth.wav");
            iShivInv[client] = 5;
        }

        int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

        if (index == 155 && StrEqual(weaponname, "tf_weapon_wrench", false))
        {
            SickleClimbWalls(client, weapon);
            WeighDownTimer = 0.0;
        }
        
        if (IsPlayerInAir(Hale) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) SpecialCrits_ForHale[client] = true;
        else SpecialCrits_ForHale[client] = false;
        
        if ((GetClientButtons(client) & IN_ATTACK2) && GetEntPropFloat(weapon, Prop_Send, "m_flEnergy") == 100.0) {
            TF2_AddCondition(client, TFCond_DefenseBuffed, 3.0);
            TF2_AddCondition(client, _TFCond(28), 3.0);
        }
    }
    return Plugin_Continue;
}

public Action BB_ShootTimer(Handle TimerHndl, int client) {
    if (BB_Sniper_ShootTime[client] == 0) return Plugin_Stop;
    if (BB_Sniper_Shots[client] != 0) BB_Sniper_Shots[client]--;
    return Plugin_Stop;
}

public Action AllSnipers_ShootTimer(Handle TimerHndl, int client) {
    if (BB_Sniper_ShootTime[client] == 0) return Plugin_Stop;
    SniperNoMimoShoots[client] = 0;
    return Plugin_Stop;
}

void SickleClimbWalls(int client, int weapon)     //Credit to Mecha the Slag
{
    if (!IsValidClient(client) || (GetClientHealth(client)<=15) )return;
    if (bushJUMP[client] == 5) return;

    char classname[64];
    float vecClientEyePos[3];
    float vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos);
    GetClientEyeAngles(client, vecClientEyeAng);

    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

    if (!TR_DidHit(null)) return;

    int TRIndex = TR_GetEntityIndex(null);
    GetEdictClassname(TRIndex, classname, sizeof(classname));

    if (!((StrStarts(classname, "prop_") && classname[5] != 'p') || StrEqual(classname, "worldspawn")))
    {
        return;
    }

    float fNormal[3];
    TR_GetPlaneNormal(null, fNormal);
    GetVectorAngles(fNormal, fNormal);

    if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return;
    if (fNormal[0] <= -30.0) return;

    float pos[3];
    TR_GetEndPosition(pos);
    float distance = GetVectorDistance(vecClientEyePos, pos);

    if (distance >= 100.0) return;

    float fVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

    fVelocity[2] = 600.0;

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
    float DamageLevel;

    if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 232 || client == Hale) DamageLevel = 0.0;
    else DamageLevel = 15.0;
    
    SDKHooks_TakeDamage(client, client, client, DamageLevel, DMG_CLUB, GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));

    if (client != Hale)
    {
        ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
        RequestFrame(Timer_NoAttacking, GetClientUserId(client));
    }
}

public void Timer_NoAttacking(int client)
{
    client = GetClientOfUserId(client);
    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
    if (weapon != -1 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != 232)
    {
        SetNextAttack(weapon, 1.56);
    }
    else
    {
        SetNextAttack(weapon, 0.76);
        bushJUMP[client]++;
        if (bushJUMP[client] == 5) bushTIME[client] = 5;
    }
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
    return (entity != data);
}

int FindNextHale(bool[] array)
{
    int tBoss = -1;
    int tBossPoints = -1073741824;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsClientParticipating(i))
        {
            int points = GetClientQueuePoints(i);
            if (points >= tBossPoints && !array[i])
            {
                tBoss = i;
                tBossPoints = points;
            }
        }
    }
    return tBoss;
}

int FindNextHaleEx()
{
    bool added[TF_MAX_PLAYERS];
    if (Hale >= 0) added[Hale] = true;
    return FindNextHale(added);
}

void ForceTeamWin(int team)
{
    int ent = FindEntityByClassname2(-1, "team_control_point_master");
    if (ent == -1)
    {
        ent = CreateEntityByName("team_control_point_master");
        DispatchSpawn(ent);
        AcceptEntityInput(ent, "Enable");
    }
    SetVariantInt(team);
    AcceptEntityInput(ent, "SetWinner");
}

public int HintPanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (!IsValidClient(param1)) return;
    if (action == MenuAction_Select || (action == MenuAction_Cancel && param2 == MenuCancel_Exit)) ASHFlags[param1] |= ASHFLAG_CLASSHELPED;
    return;
}

public Action HintPanel(int client)
{
    if (IsVoteInProgress())
        return Plugin_Continue;
    if (client != Hale) return HelpPanel2(client);
    Handle panel = CreatePanel();
    char s[512];
    SetGlobalTransTarget(client);
    switch (Special) // ASH MOD, 19.12.2015
    {
        case ASHSpecial_Hale, ASHSpecial_MiniHale:
            FormatEx(s, 512, "%t\n%t\n%t: %t", "ash_help_bosses_jump", "ash_help_bosses_weighdown", "ash_help_hale_ragetype", "ash_help_bosses_userage");
        case ASHSpecial_Vagineer:
            FormatEx(s, 512, "%t\n%t\n%t: %t", "ash_help_bosses_jump", "ash_help_bosses_weighdown", "ash_help_vagineer_userage", "ash_help_bosses_userage");
        case ASHSpecial_HHH:
            FormatEx(s, 512, "%t\n%t: %t\n%t", "ash_help_hhh_teleport", "ash_help_hhh_userage", "ash_help_bosses_userage", "ash_help_hhh_souls");
        case ASHSpecial_CBS: // (͡ʘ ͜ʖ ͡ʘ)
            FormatEx(s, 512, "%t\n%t\n%t: %t", "ash_help_bosses_jump", "ash_help_bosses_weighdown", "ash_help_cbr_userage", "ash_help_bosses_userage");
        case ASHSpecial_Bunny:
            FormatEx(s, 512, "%t\n%t\n%t: %t", "ash_help_bosses_jump", "ash_help_bosses_weighdown", "ash_help_easterbunny_userage", "ash_help_bosses_userage");
        case ASHSpecial_Agent:
            FormatEx(s, 512, "%t\n%t\n%t\n%t\n%t\n%t", "ash_help_bosses_jump", "ash_help_bosses_weighdown", "ash_help_agent_userage", "ash_help_agent_hologram", "ash_help_agent_sapper", "ash_help_agent_sound");
    }
    DrawPanelText(panel, s);
    Format(s, 512, "%t", "vsh_menu_exit");
    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, HintPanelH, 9001);
    CloseHandle(panel);
    return Plugin_Continue;
}

public int QueuePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select && param2 == 10)
        TurnToZeroPanel(param1);
    return false;
}

public Action QueuePanelCmd(int client, int Args)
{
    if (!IsValidClient(client)) return Plugin_Handled;
    QueuePanel(client);
    return Plugin_Handled;
}

public Action QueuePanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Handled;
    Handle panel = CreatePanel();
    char s[512];
    Format(s, 512, "%T", "vsh_thequeue", client);
    SetPanelTitle(panel, s);
    bool[] added = new bool[TF_MAX_PLAYERS];
    int tHale = Hale;
    if (Hale >= 0) added[Hale] = true;
    if (!g_bEnabled) DrawPanelItem(panel, "None");
    else if (IsValidClient(tHale))
    {
        Format(s, sizeof(s), "%N - %i", tHale, GetClientQueuePoints(tHale));
        DrawPanelItem(panel, s);
    }
    else DrawPanelItem(panel, "None");
    int i;
    int pingas;
    bool botadded;
    DrawPanelText(panel, "---");
    do
    {
        tHale = FindNextHale(added);
        if (IsValidClient(tHale))
        {
            if (client == tHale)
            {
                Format(s, 64, "%N - %i", tHale, GetClientQueuePoints(tHale));
                DrawPanelText(panel, s);
                i--;
            }
            else
            {
                if (IsFakeClient(tHale))
                {
                    if (botadded)
                    {
                        added[tHale] = true;
                        continue;
                    }
                    Format(s, 64, "BOT - %i", botqueuepoints);
                    botadded = true;
                }
                else Format(s, 64, "%N - %i", tHale, GetClientQueuePoints(tHale));
                DrawPanelItem(panel, s);
            }
            added[tHale]=true;
            i++;
        }
        pingas++;
    }
    while (i < 8 && pingas < 100);
    for (; i < 8; i++)
        DrawPanelItem(panel, "");
    Format(s, 64, "%T %i (%T)", "vsh_your_points", client, GetClientQueuePoints(client), "vsh_to0", client);
    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, QueuePanelH, 9001);
    CloseHandle(panel);
    return Plugin_Handled;
}

public int TurnToZeroPanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select && param2 == 1)
    {
        if (UTIL_GetClientCount() < GetConVarInt(cvarHaleMinPlayersResetQ))
        {
            CPrintToChat(param1, "{ash}[ASH] {default}%t", "you_cant_perform_this_action_because_players_count_is_too_low");
            return;
        }

        SetClientQueuePoints(param1, 0);
        CPrintToChat(param1, "{ash}[ASH] {default}%t", "vsh_to0_done");
        int cl = FindNextHaleEx();
        if (IsValidClient(cl)) SkipHalePanelNotify(cl);
    }
}

public Action ResetQueuePointsCmd(int client, int args)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Handled;
    if (!IsValidClient(client))
        return Plugin_Handled;
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
        TurnToZeroPanel(client);
    else
        TurnToZeroPanelH(null, MenuAction_Select, client, 1);
    return Plugin_Handled;
}

public Action TurnToZeroPanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Continue;
    Handle panel = CreatePanel();
    char s[512];
    SetGlobalTransTarget(client);
    Format(s, 512, "%t", "vsh_to0_title");
    SetPanelTitle(panel, s);
    Format(s, 512, "%t", "Yes");
    DrawPanelItem(panel, s);
    Format(s, 512, "%t", "No");
    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, TurnToZeroPanelH, 9001);
    CloseHandle(panel);
    return Plugin_Continue;
}

bool GetClientClasshelpinfoCookie(int client)
{
    if (!IsValidClient(client)) return false;
    if (IsFakeClient(client)) return false;
    if (!AreClientCookiesCached(client)) return true;
    char strCookie[MAX_DIGITS];
    GetClientCookie(client, ClasshelpinfoCookie, strCookie, sizeof(strCookie));
    if (strCookie[0] == 0) return true;
    else return view_as<bool>(StringToInt(strCookie));
}

int GetClientQueuePoints(int client)
{
    if (!IsValidClient(client)) return 0;
    if (IsFakeClient(client))
    {
        return botqueuepoints;
    }
    if (!AreClientCookiesCached(client)) return 0;
    char strPoints[MAX_DIGITS];
    GetClientCookie(client, PointCookie, strPoints, sizeof(strPoints));
    return StringToInt(strPoints);
}

void SetClientQueuePoints(int client, int points)
{
    if (!IsValidClient(client)) return;
    if (IsFakeClient(client)) return;
    if (!AreClientCookiesCached(client)) return;
    char strPoints[MAX_DIGITS];
    IntToString(points, strPoints, sizeof(strPoints));
    SetClientCookie(client, PointCookie, strPoints);
}

void SetAuthIdQueuePoints(char[] authid, int points)
{
    char strPoints[MAX_DIGITS];
    IntToString(points, strPoints, sizeof(strPoints));
    SetAuthIdCookie(authid, PointCookie, strPoints);
}

public int HalePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        switch (param2)
        {
            case 1:
                Command_GetHP(param1);
            case 2:
                HelpPanel(param1);
            case 3:
                HelpPanel2(param1);
            case 4:
                NewPanel(param1);
            case 5:
                QueuePanel(param1);
            case 6:
                MusicTogglePanel(param1);
            case 7:
                VoiceTogglePanel(param1);
            case 8:
                ClasshelpinfoSetting(param1);
            default: return;
        }
    }
}

public Action HalePanel(int client, int args)
{
    if (!g_bAreEnoughPlayersPlaying || !client) // IsValidClient(client, false)
        return Plugin_Continue;
    Handle panel = CreatePanel();
    int size = 256;
    char[] s = new char[size];
    SetGlobalTransTarget(client);
    Format(s, size, "%t", "vsh_menu_1");
    SetPanelTitle(panel, s);
    Format(s, size, "%t", "vsh_menu_2");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_3");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_7");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_4");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_5");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_8");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_9");
    DrawPanelItem(panel, s);
    Format(s, size, "%t", "vsh_menu_9a");
    DrawPanelItem(panel, s);

    Format(s, size, "%t", "vsh_menu_exit");
    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, HalePanelH, 9001);
    CloseHandle(panel);
    return Plugin_Handled;
}

public Action NewPanelCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    NewPanel(client);
    return Plugin_Handled;
}

public Action NewPanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Continue;
    
    char TempTranslate[200];
    SetGlobalTransTarget(client);
    
    Menu MenuHndl = CreateMenu(MenuUpds_Handler);
    MenuHndl.ExitButton = false;
    
    Format(TempTranslate, 200, "%t\n \n%t\n%t", "ash_whatsup_title", "ash_whatsup_message1", "ash_whatsup_message2");
    MenuHndl.SetTitle(TempTranslate);
    
    Format(TempTranslate, 200, "%t", "ash_whatsup_button1");
    MenuHndl.AddItem("yes", TempTranslate);
    
    Format(TempTranslate, 200, "%t", "ash_whatsup_button2");
    MenuHndl.AddItem("no", TempTranslate);
    MenuHndl.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

public int HelpPanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        return;
    }
}

public Action HelpPanelCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    HelpPanel(client);
    return Plugin_Handled;
}

public Action HelpPanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying || IsVoteInProgress())
        return Plugin_Continue;
    Handle panel = CreatePanel();
    char s[512];
    SetGlobalTransTarget(client);
    Format(s, 512, "%t", "vsh_help_mode");
    DrawPanelItem(panel, s);
    Format(s, 512, "%t", "vsh_menu_exit");
    DrawPanelItem(panel, s);
    SendPanelToClient(panel, client, HelpPanelH, 9001);
    CloseHandle(panel);
    return Plugin_Continue;
}

public Action HelpPanel2Cmd(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    if (client == Hale)
    {
        HintPanel(Hale);
    }
    else
    {
        HelpPanel2(client);
    }
    
    return Plugin_Handled;
}

public Action HelpPanel2(int client)
{
    if (!g_bAreEnoughPlayersPlaying || IsVoteInProgress())
        return Plugin_Continue;
    if (client == Hale) return HintPanel(Hale);
    char s[1024];
    SetGlobalTransTarget(client);
    
    Menu menuHndl = CreateMenu(HelpHandler_HelpMenu_ASH);
    Format(s, 1024, "%t\n%t", "ash_help_title", "ash_help_selectweapon");
    menuHndl.SetTitle(s);
    switch (TF2_GetPlayerClass(client))
    {
        case TFClass_Scout:
        {
            Format(s, 1024, "%t", "ash_help_scout_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_scout_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Soldier:
        {
            Format(s, 1024, "%t", "ash_help_soldier_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_soldier_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Pyro:
        {
            Format(s, 1024, "%t", "ash_help_pyro_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_pyro_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_DemoMan:
        {
            Format(s, 1024, "%t", "ash_help_demoman_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_demoman_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Heavy:
        {
            Format(s, 1024, "%t", "ash_help_heavy_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_heavy_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Engineer:
        {
            Format(s, 1024, "%t", "ash_help_engineer_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_engineer_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Medic:
        {
            Format(s, 1024, "%t", "ash_help_medic_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_medic_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Sniper:
        {
            Format(s, 1024, "%t", "ash_help_sniper_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_sniper_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
        }
        
        case TFClass_Spy:
        {
            Format(s, 1024, "%t", "ash_help_spy_primary");
            menuHndl.AddItem("primary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_spy_secondary");
            menuHndl.AddItem("secondary", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_multiclass_melee");
            menuHndl.AddItem("melee", s, ITEMDRAW_DEFAULT);
            
            Format(s, 1024, "%t", "ash_help_spy_inviswatches");
            menuHndl.AddItem("inviswatch", s, ITEMDRAW_DEFAULT);
        }
    }
    
    //SetMenuExitButton(menuHndl, true);
    //SetMenuExitBackButton(menuHndl, true);
    menuHndl.ExitButton = true;
    
    menuHndl.Display(client, MENU_TIME_FOREVER);
    
    return Plugin_Continue;
}

public Action ClasshelpinfoCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    ClasshelpinfoSetting(client);
    return Plugin_Handled;
}
public Action ClasshelpinfoSetting(int client)
{
    if (!g_bAreEnoughPlayersPlaying)
        return Plugin_Handled;
    Handle panel = CreatePanel();
    SetPanelTitle(panel, "Turn the VS Saxton Hale class info...");
    DrawPanelItem(panel, "On");
    DrawPanelItem(panel, "Off");
    SendPanelToClient(panel, client, ClasshelpinfoTogglePanelH, 9001);
    CloseHandle(panel);
    return Plugin_Handled;
}

public int ClasshelpinfoTogglePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (IsValidClient(param1))
    {
        if (action == MenuAction_Select)
        {
            if (param2 == 2)
                SetClientCookie(param1, ClasshelpinfoCookie, "0");
            else
                SetClientCookie(param1, ClasshelpinfoCookie, "1");
            CPrintToChat(param1, "{ash}[ASH]{default} %t", "vsh_classinfo", param2 == 2 ? "off" : "on");
        }
    }
}

public Action MusicTogglePanelCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    MusicTogglePanel(client);
    return Plugin_Handled;
}
public Action MusicTogglePanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying || !client)
        return Plugin_Handled;
    Handle panel = CreatePanel();
    SetPanelTitle(panel, "Turn the VS Saxton Hale music...");
    DrawPanelItem(panel, "On");
    DrawPanelItem(panel, "Off");
    SendPanelToClient(panel, client, MusicTogglePanelH, 9001);
    CloseHandle(panel);
    return Plugin_Handled;
}
public int MusicTogglePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (IsValidClient(param1))
    {
        if (action == MenuAction_Select)
        {
            if (param2 == 2)
            {
                SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, false);
                StopHaleMusic(param1);
            }
            else
                SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, true);
            CPrintToChat(param1, "{ash}[ASH] {default}%t", "vsh_music", param2 == 2 ? "off" : "on");
        }
    }
}

public Action VoiceTogglePanelCmd(int client, int args)
{
    if (!client) return Plugin_Handled;
    VoiceTogglePanel(client);
    return Plugin_Handled;
}

public Action VoiceTogglePanel(int client)
{
    if (!g_bAreEnoughPlayersPlaying || !client)
        return Plugin_Handled;
    Handle panel = CreatePanel();
    SetPanelTitle(panel, "Turn the VS Saxton Hale voices...");
    DrawPanelItem(panel, "On");
    DrawPanelItem(panel, "Off");
    SendPanelToClient(panel, client, VoiceTogglePanelH, 9001);
    CloseHandle(panel);
    return Plugin_Handled;
}

public int VoiceTogglePanelH(Handle menu, MenuAction action, int param1, int param2)
{
    if (IsValidClient(param1))
    {
        if (action == MenuAction_Select)
        {
            if (param2 == 2)
                SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, false);
            else
                SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, true);
            
            CPrintToChat(param1, "{ash}[ASH] {default}%t", "vsh_voice", param2 == 2 ? "off" : "on");
        }
    }
}

public void Timer_SetEggBomb(any ref)
{
    int entity = EntRefToEntIndex(ref);
    bool isSpecialBomb = (GetPlayerWeaponSlot(Hale, TFWeaponSlot_Primary) == SpecialWeapon);
    if (isSpecialBomb) {
        ResizePlayer(entity, 5.0);
    }
    
    if (FileExists(EggModel) && IsModelPrecached(EggModel) && IsValidEntity(entity))
    {
        int att = AttachProjectileModel(entity, EggModel);
        SetEntProp(att, Prop_Send, "m_nSkin", 0);
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255, 0);
        
        if (isSpecialBomb) {
            ResizePlayer(att, 2.0);
        }
    }
}

stock int AttachProjectileModel(int entity, char[] strModel, char[] strAnim = "")
{
    if (!IsValidEntity(entity)) return -1;
    int model = CreateEntityByName("prop_dynamic");
    if (IsValidEdict(model))
    {
        float pos[3];
        float ang[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
        TeleportEntity(model, pos, ang, NULL_VECTOR);
        DispatchKeyValue(model, "model", strModel);
        DispatchSpawn(model);
        SetVariantString("!activator");
        AcceptEntityInput(model, "SetParent", entity, model, 0);
        if (strAnim[0] != '\0')
        {
            SetVariantString(strAnim);
            AcceptEntityInput(model, "SetDefaultAnimation");
            SetVariantString(strAnim);
            AcceptEntityInput(model, "SetAnimation");
        }
        SetEntPropEnt(model, Prop_Send, "m_hOwnerEntity", entity);
        return model;
    } else {
        LogError("(AttachProjectileModel): Could not create prop_dynamic");
    }
    return -1;
}

/*
public Action Debug_ReloadASH(int iClient, int iArgc) {
    g_bReloadAS OnRoundEnd = true;
    switch (ASHRoundState)
    {
        case ASHRState_End, ASHRState_Disabled:
        {
            CPrintToChatAll("{ash}[ASH] {default}Плагин перезагружен.");
            SetClientQueuePoints(Hale, 0);
            ServerCommand("sm plugins reload %s", ASH_pluginname);
        }
        default:
        {
            CPrintToChatAll("{ash}[ASH] {default}Плагин будет перезагружен в конце раунда.");
            SetClientQueuePoints(Hale, 0);
        }
    }
    return Plugin_Handled;
}
*/

stock bool InsertCond(int iClient, TFCond iCond, float flDuration = TFCondDuration_Infinite)
{
    if (!TF2_IsPlayerInCondition(iClient, iCond))
    {
        TF2_AddCondition(iClient, iCond, flDuration);
        return true;
    }
    return false;
}

stock bool RemoveCond(int iClient, TFCond iCond)
{
    if (TF2_IsPlayerInCondition(iClient, iCond))
    {
        TF2_RemoveCondition(iClient, iCond);
        return true;
    }
    return false;
}

stock bool RemoveDemoShield(int iClient)
{
    int iEnt = MaxClients + 1;
    while ((iEnt = FindEntityByClassname2(iEnt, "tf_wearable_demoshield")) != -1)
    {
        if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == iClient && !GetEntProp(iEnt, Prop_Send, "m_bDisguiseWearable"))
        {
            if (GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex") == 131) {
                // Explode effect!
                EmitSoundToAll("misc/halloween/spell_meteor_impact.wav", iClient);
                
                // And add damage to Hale!
                Damage[iClient] += 450;
                HaleHealth -= 450;
                TF2_RemoveWearable(iClient, iEnt);
                return true;
            }
            else if (GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex") == 406 && g_bProtectedShield[iClient])
            {   
                g_bProtectedShield[iClient] = false;
                return true;
            }
            else
            {
                TF2_RemoveWearable(iClient, iEnt);
                return true;
            }
        }
    }
    return false;
}

stock bool RemoveRazorback(int iClient)
{
    int iEnt = MaxClients + 1;
    while ((iEnt = FindEntityByClassname2(iEnt, "tf_wearable_razorback")) != -1)
    {
        int idx = GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex");

        if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == iClient && idx == 57 && !GetEntProp(iEnt, Prop_Send, "m_bDisguiseWearable"))
        {
            TF2_RemoveWearable(iClient, iEnt);
            return true;
        }
    }
    return false;
}

stock bool RemovePlayerBack(int client, int[] indices, int len)
{
    if (len <= 0)
    {
        return false;
    }

    bool bReturn = false;
    int edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
    {
        char netclass[32];
        if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
        {
            int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
            if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
            {
                for (int i = 0; i < len; i++)
                {
                    if (idx == indices[i])
                    {
                        TF2_RemoveWearable(client, edict);
                        bReturn = true;
                    }
                }
            }
        }
    }

    edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
    {
        char netclass[32];
        if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
        {
            int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
            if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
            {
                for (int i = 0; i < len; i++)
                {
                    if (idx == indices[i])
                    {
                        TF2_RemoveWearable(client, edict);
                        bReturn = true;
                    }
                }
            }
        }
    }

    edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "craft_item")) != -1)
    {

        int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
        if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
        {
            for (int i = 0; i < len; i++)
            {
                if (idx == indices[i])
                {
                    TF2_RemoveWearable(client, edict);
                    bReturn = true;
                }
            }
        }
    }

    edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "tf_wearable_campaign_item")) != -1)
    {

        int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
        if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
        {
            for (int i = 0; i < len; i++)
            {
                if (idx == indices[i])
                {
                    TF2_RemoveWearable(client, edict);
                    bReturn = true;
                }
            }
        }
    }

    return bReturn;
}

stock int FindPlayerBack(int client, int[] indices, int len)
{
    if (len <= 0)
    {
        return -1;
    }
    
    int edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "tf_wearable_razorback")) != -1)
    {
        char netclass[32];
        if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
        {
            int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
            if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
            {
                for (int i = 0; i < len; i++)
                {
                    if (idx == indices[i]) return edict;
                }
            }
        }
    }

    edict = MaxClients + 1;
    while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
    {
        char netclass[32];
        if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
        {
            int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
            if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
            {
                for (int i = 0; i < len; i++)
                {
                    if (idx == indices[i])
                        return edict;
                }
            }
        }
    }

    return -1;
}

stock float fmax(float a,float b) { return (a > b) ? a : b; }
stock float fmin(float a,float b) { return (a < b) ? a : b; }
stock float fclamp(float n, float mi, float ma)
{
    n = fmin(n,ma);
    return fmax(n,mi);
}

static float g_flNext[e_flNext];
static float g_flNext2[e_flNext][TF_MAX_PLAYERS];

stock bool IsNextTime(int iIndex, float flAdditional = 0.0)
{
    return (GetEngineTime() >= g_flNext[iIndex]+flAdditional);
}

stock void SetNextTime(int iIndex, float flSeconds, bool bAbsolute = false)
{
    g_flNext[iIndex] = bAbsolute ? flSeconds : GetEngineTime() + flSeconds;
}

stock int GetNextTime(int iIndex)
{
    return g_flNext[iIndex];
}

stock float GetTimeTilNextTime(int iIndex, bool bNonNegative = true)
{
    return bNonNegative ? fmax(g_flNext[iIndex] - GetEngineTime(), 0.0) : (g_flNext[iIndex] - GetEngineTime());
}

stock int GetSecsTilNextTime(int iIndex, bool bNonNegative = true)
{
    return RoundToFloor(GetTimeTilNextTime(iIndex, bNonNegative));
}

stock bool IfDoNextTime(int iIndex, float flThenAdd)
{
    if (IsNextTime(iIndex))
    {
        SetNextTime(iIndex, flThenAdd);
        return true;
    }
    return false;
}

stock bool IsNextTime2(int iClient, int iIndex, float flAdditional = 0.0)
{
    return (GetEngineTime() >= g_flNext2[iIndex][iClient]+flAdditional);
}

stock void SetNextTime2(int iClient, int iIndex, float flSeconds, bool bAbsolute = false)
{
    g_flNext2[iIndex][iClient] = bAbsolute ? flSeconds : GetEngineTime() + flSeconds;
}

stock float GetTimeTilNextTime2(int iClient, int iIndex, bool bNonNegative = true)
{
    return bNonNegative ? fmax(g_flNext2[iIndex][iClient] - GetEngineTime(), 0.0) : (g_flNext2[iIndex][iClient] - GetEngineTime());
}

stock int GetSecsTilNextTime2(int iClient, int iIndex, bool bNonNegative = true)
{
    return RoundToFloor(GetTimeTilNextTime2(iClient, iIndex, bNonNegative));
}

stock bool IfDoNextTime2(int iClient, int iIndex, float flThenAdd)
{
    if (IsNextTime2(iClient, iIndex))
    {
        SetNextTime2(iClient, iIndex, flThenAdd);
        return true;
    }
    return false;
}

static int s_iLastPriority[TF_MAX_PLAYERS] = {MIN_INT,...};

stock void PriorityCenterText(int iClient, int iPriority = MIN_INT, char[] szFormat, any:...)
{
    if (!IsValidClient(iClient))
    {
        ThrowError("Client index %i is invalid or not in game.", iClient);
    }

    if (s_iLastPriority[iClient] > iPriority)
    {
        if (IsNextTime2(iClient, e_flNextEndPriority))
        {
            s_iLastPriority[iClient] = MIN_INT;
        }
        else
        {
            return;
        }
    }

    if (iPriority > s_iLastPriority[iClient])
    {
        SetNextTime2(iClient, e_flNextEndPriority, 5.0);
        s_iLastPriority[iClient] = iPriority;
    }

    char szBuffer[MAX_CENTER_TEXT];
    SetGlobalTransTarget(iClient);
    VFormat(szBuffer, sizeof(szBuffer), szFormat, 4);
    PrintCenterText(iClient, "%s", szBuffer);
}

stock void PriorityCenterTextAll(int iPriority = MIN_INT, char[] szFormat, any:...)
{
    char szBuffer[MAX_CENTER_TEXT];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SetGlobalTransTarget(i);
            VFormat(szBuffer, sizeof(szBuffer), szFormat, 3);
            PriorityCenterText(i, iPriority, "%s", szBuffer);
        }
    }
}

stock void PriorityCenterTextAllEx(int iPriority = -2147483647, char[] szFormat, any:...)
{
    if (iPriority == MIN_INT)
    {
        iPriority++;
    }

    if (s_iLastPriority[0] > iPriority)
    {
        if (IsNextTime2(0, e_flNextEndPriority))
        {
            s_iLastPriority[0] = MIN_INT;

            for (new i = 1; i <= MaxClients; i++)
            {
                s_iLastPriority[i] = MIN_INT;
            }
        }
        else
        {
            return;
        }
    }

    if (iPriority > s_iLastPriority[0])
    {
        IncNextTime2(0, e_flNextEndPriority, 5.0);

        s_iLastPriority[0] = iPriority;

        for (new i = 1; i <= MaxClients; i++)
        {
            s_iLastPriority[i] = MAX_INT;
        }
    }

    char szBuffer[MAX_CENTER_TEXT];

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SetGlobalTransTarget(i);
            VFormat(szBuffer, sizeof(szBuffer), szFormat, 3);
            PrintCenterText(i, "%s", szBuffer);
        }
    }
}

stock bool IsDate(int StartMonth = Month_None, int StartDay = 0, int EndMonth = Month_None, int EndDay = 0, bool bForceRecalc = false)
{
    static int iMonth;
    static int iDate;
    static bool bFound = false;

    if (bForceRecalc)
    {
        bFound = false;
        iMonth = 0;
        iDate = 0;
    }

    if (!bFound)
    {
        int iTimeStamp = GetTime();
        char szMonth[MAX_DIGITS]; 
        char szDate[MAX_DIGITS];

        FormatTime(szMonth, sizeof(szMonth), "%m", iTimeStamp);
        FormatTime(szDate, sizeof(szDate),     "%d", iTimeStamp);

        iMonth = StringToInt(szMonth);
        iDate = StringToInt(szDate);
        bFound = true;
    }

    return (StartMonth == iMonth && StartDay <= iDate) || (EndMonth && EndDay && (StartMonth < iMonth && iMonth <= EndMonth) && (iDate <= EndDay));
}

stock void SetArenaCapEnableTime(float time)
{
    int ent = -1;
    char strTime[32];
    FloatToString(time, strTime, sizeof(strTime));
    if ((ent = FindEntityByClassname2(-1, "tf_logic_arena")) != -1 && IsValidEdict(ent))
    {
        DispatchKeyValue(ent, "CapEnableDelay", strTime);
    }
}

stock bool IsNearSpencer(int client) 
{ 
    bool dispenserheal;
    int medics = 0; 
    int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
    if (healers > 0) 
    { 
        for (int i = 1; i <= MaxClients; i++) 
        { 
            if (IsClientInGame(i) && IsPlayerAlive(i) && GetHealingTarget(i) == client) 
                medics++; 
        } 
    } 
    dispenserheal = (healers > medics) ? true : false; 
    return dispenserheal; 
} 

stock int FindSentry(int client)
{
    int i=-1;
    while ((i = FindEntityByClassname2(i, "obj_sentrygun")) != -1)
    {
        if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client) return i;
    }
    return -1;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

stock int GetClientCloakIndex(int iClient)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(iClient, TFWeaponSlot_Watch));
}

stock int GetWeaponIndex(int iWeapon)
{
    return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock bool IsValidEnt(int iEnt)
{
    return iEnt > MaxClients && IsValidEntity(iEnt);
}

stock void IncrementHeadCount(int iClient)
{
    InsertCond(iClient, TFCond_DemoBuff);
    SetEntProp(iClient, Prop_Send, "m_iDecapitations", GetEntProp(iClient, Prop_Send, "m_iDecapitations") + 1);
    AddPlayerHealth(iClient, 15, 300, true);             //    The old version of this allowed infinite health gain... so ;v
    TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.01);    //    Recalculate their speed
}

stock void SwitchToOtherWeapon(int client)
{
    int ammo = GetAmmo(client, 0);
    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int clip = (IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
    if (!(ammo == 0 && clip <= 0)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
    else SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
}

stock int FindTeleOwner(int client)
{
    if (!IsValidClient(client)) return -1;
    if (!IsPlayerAlive(client)) return -1;
    int tele = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
    char classname[32];
    if (IsValidEntity(tele) && GetEdictClassname(tele, classname, sizeof(classname)) && strcmp(classname, "obj_teleporter", false) == 0)
    {
        int owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");
        if (IsValidClient(owner)) return owner; // IsValidClient(owner, false)
    }
    return -1;
}

stock bool TF2_IsPlayerCritBuffed(int client)
{
    return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, _TFCond(34)) || TF2_IsPlayerInCondition(client, _TFCond(35)) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

stock void SetNextAttack(int weapon, float duration = 0.0)
{
    if (weapon <= MaxClients) return;
    if (!IsValidEntity(weapon)) return;
    float next = GetGameTime() + duration;
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}

#if defined _tf2items_included
stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
    Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
    if (hWeapon == null)
        return -1;
    TF2Items_SetClassname(hWeapon, name);
    TF2Items_SetItemIndex(hWeapon, index);
    TF2Items_SetLevel(hWeapon, level);
    TF2Items_SetQuality(hWeapon, qual);
    char atts[32][32];
    int count = ExplodeString(att, " ; ", atts, 32, 32);
    if (count > 1)
    {
        TF2Items_SetNumAttributes(hWeapon, count/2);
        int i2 = 0;
        for (int i = 0; i < count; i += 2)
        {
            TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
            i2++;
        }
    }
    else
        TF2Items_SetNumAttributes(hWeapon, 0);

    int entity = TF2Items_GiveNamedItem(client, hWeapon);
    CloseHandle(hWeapon);
    EquipPlayerWeapon(client, entity);
    return entity;
}
#endif

stock void SetAmmo(int client, int wepslot, int newAmmo)
{
    int weapon = GetPlayerWeaponSlot(client, wepslot);
    if (!IsValidEntity(weapon)) return;
    int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (type < 0 || type > 31) return;
    SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);
}

stock int GetAmmo(int client, int wepslot)
{
    if (!IsValidClient(client)) return 0;
    int weapon = GetPlayerWeaponSlot(client, wepslot);
    if (!IsValidEntity(weapon)) return 0;
    int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (type < 0 || type > 31) return 0;
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, type);
}

stock int TF2_GetMetal(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return 0;
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
}

stock int TF2_SetMetal(int client, int metal)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return;
    SetEntProp(client, Prop_Send, "m_iAmmo", metal, _, 3);
}

stock int GetHealingTarget(int client)
{
    char s[64];
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (medigun <= MaxClients || !IsValidEdict(medigun))
        return -1;
    GetEdictClassname(medigun, s, sizeof(s));
    if (strcmp(s, "tf_weapon_medigun", false) == 0)
    {
        if (GetEntProp(medigun, Prop_Send, "m_bHealing"))
            return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
    }
    return -1;
}

stock int FindEntityByClassname2(int startEnt, char[] classname)
{
    /* If startEnt isn't valid shifting it back to the nearest valid one */
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    return FindEntityByClassname(startEnt, classname);
}

/*
    @summary
        Changes a living player's team without killing/moving them
        I think it respawns them at spawn though.

    @params
        iClient should be validated before using this
        iTeam should be either 2 or 3

    @return
        false if not changed
        true if changed

        TODO: -1 not changed, 0 if changed with no respawn, 1 if changed with respawn

*/
stock void ChangeTeam(int iClient, int iTeam) // iTeam should never be less than 2
{
    int iOldTeam = GetEntityTeamNum(iClient);

    if (iOldTeam != iTeam && iOldTeam >= TEAM_RED)
    {
        SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
        ChangeClientTeam(iClient, iTeam);
        SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);
        TF2_RespawnPlayer(iClient);
    }
}

stock any min(any a,any b) { return (a < b) ? a : b; }

/*
    Player health adder
    By: Chdata
*/
stock void AddPlayerHealth(int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false)
{
    int iHealth = GetClientHealth(iClient);
    int iNewHealth = iHealth + iAdd;
    int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;
    if (iHealth < iMax)
    {
        iNewHealth = min(iNewHealth, iMax);
        SetEntityHealth(iClient, iNewHealth);
    }
}

stock void PrepareSound(char[] szSoundPath)
{
    PrecacheSound(szSoundPath, true);
    char s[PLATFORM_MAX_PATH];
    Format(s, sizeof(s), "sound/%s", szSoundPath);
    AddFileToDownloadsTable(s);
}

stock void DownloadSoundList(char[][] szFileList, int iSize)
{
    for (int i = 0; i < iSize; i++)
    {
        PrepareSound(szFileList[i]);
    }
}

stock void PrecacheSoundList(char[][] szFileList, int iSize)
{
    for (int i = 0; i < iSize; i++)
    {
        PrecacheSound(szFileList[i], true);
    }
}

// Adds both a .vmt and .vtf to downloads - must exclude extension
stock void PrepareMaterial(char[] szMaterialPath)
{
    char s[PLATFORM_MAX_PATH];
    Format(s, sizeof(s), "%s%s", szMaterialPath, ".vtf");
    AddFileToDownloadsTable(s);
    Format(s, sizeof(s), "%s%s", szMaterialPath, ".vmt");
    AddFileToDownloadsTable(s);
}

stock void DownloadMaterialList(char[][] szFileList, int iSize)
{
    char s[PLATFORM_MAX_PATH];
    for (int i = 0; i < iSize; i++)
    {
        strcopy(s, sizeof(s), szFileList[i]);
        AddFileToDownloadsTable(s); // if (FileExists(s, true))
    }
}

stock int PrepareModel(const char[] szModelPath, bool bMdlOnly = false)
{
    char szBase[PLATFORM_MAX_PATH];
    char szPath[PLATFORM_MAX_PATH];
    strcopy(szBase, sizeof(szBase), szModelPath);
    SplitString(szBase, ".mdl", szBase, sizeof(szBase));
    
    if (!bMdlOnly)
    {
        FormatEx(szPath, sizeof(szPath), "%s.phy", szBase);
        if (FileExists(szPath, true))
        {
            AddFileToDownloadsTable(szPath);
        }
        
        FormatEx(szPath, sizeof(szPath), "%s.sw.vtx", szBase);
        if (FileExists(szPath, true))
        {
            AddFileToDownloadsTable(szPath);
        }
        
        FormatEx(szPath, sizeof(szPath), "%s.vvd", szBase);
        if (FileExists(szPath, true))
        {
            AddFileToDownloadsTable(szPath);
        }
        
        FormatEx(szPath, sizeof(szPath), "%s.dx80.vtx", szBase);
        if (FileExists(szPath, true))
        {
            AddFileToDownloadsTable(szPath);
        }
        
        FormatEx(szPath, sizeof(szPath), "%s.dx90.vtx", szBase);
        if (FileExists(szPath, true))
        {
            AddFileToDownloadsTable(szPath);
        }
    }
    
    AddFileToDownloadsTable(szModelPath);
    
    return PrecacheModel(szModelPath, true);
}

/*
    Returns the the TeamNum of an entity.
    Works for both clients and things like healthpacks.
    Returns -1 if the entity doesn't have the m_iTeamNum prop.

    GetEntityTeamNum() doesn't always return properly when tf_arena_use_queue is set to 0
*/
stock int GetEntityTeamNum(int iEnt) { return GetEntProp(iEnt, Prop_Send, "m_iTeamNum"); }

stock bool IsValidClient(int iClient) { return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient)); }

stock bool IsClientParticipating(int iClient)
{
    if (IsSpectator(iClient) || IsReplayClient(iClient)) { return false; }
    if (view_as<bool>(GetEntProp(iClient, Prop_Send, "m_bIsCoaching"))) { return false; }
    if (TF2_GetPlayerClass(iClient) == TFClass_Unknown) { return false; }
    
    return true;
}

stock bool IsSpectator(int iClient) { return GetEntityTeamNum(iClient) <= TEAM_SPEC; }

stock bool IsReplayClient(int iClient) { return IsClientReplay(iClient) || IsClientSourceTV(iClient); }

stock int TF2_GetRoundWinCount() { return GetTeamScore(TEAM_RED) + GetTeamScore(TEAM_BLU); }

stock void ClearTimer(Handle &hTimer) {
    if (hTimer != null) {
        KillTimer(hTimer);
        hTimer = null;
    }
}

stock void teamplay_round_start_TeleportToMultiMapSpawn() {
    ClearArray(s_hSpawnArray);

    int iInt = 0;
    int iSkip[TF_MAX_PLAYERS] = {0,...};

    int iEnt = MaxClients + 1;
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        int iTeam = GetEntityTeamNum(iEnt);
        int iClient = GetClosestPlayerTo(iEnt, iTeam);

        if (iClient)
        {
            bool bSkip = false;
            for (int i = 0; i < TF_MAX_PLAYERS; i++)
            {
                if (iSkip[i] == iClient)
                {
                    bSkip = true;
                    break;
                }
            }
            if (bSkip)
            {
                continue;
            }
            iSkip[iInt++] = iClient;
            int iIndex = PushArrayCell(s_hSpawnArray, EntIndexToEntRef(iEnt));
            SetArrayCell(s_hSpawnArray, iIndex, iTeam, 1);
        }
    }
}

stock int TeleportToMultiMapSpawn(int iClient, int iTeam = 0)
{
    int iSpawn;
    int iTeleTeam;
    int iIndex;
    if (iTeam <= 1) {
        iSpawn = EntRefToEntIndex(GetRandBlockCellEx(s_hSpawnArray));
    } else {
        do { iTeleTeam = GetRandBlockCell(s_hSpawnArray, iIndex, 1); }
        while (iTeleTeam != iTeam);

        iSpawn = EntRefToEntIndex(GetArrayCell(s_hSpawnArray, iIndex, 0));
    }
    TeleMeToYou(iClient, iSpawn);
    return iSpawn;
}

stock int GetClosestPlayerTo(int iEnt, int iTeam = 0)
{
    int iBest;
    float flDist;
    float flTemp;
    
    float vLoc[3];
    float vPos[3];
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vLoc);
    for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
        {
            if (iTeam && GetEntityTeamNum(iClient) != iTeam)
            {
                continue;
            }
            
            GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPos);
            flTemp = GetVectorDistance(vLoc, vPos);
            if (!iBest || flTemp < flDist)
            {
                flDist = flTemp;
                iBest = iClient;
            }
        }
    }
    return iBest;
}

stock bool TeleMeToYou(int iMe, int iYou, bool bAngles = false)
{
    float vPos[3];
    float vAng[3];
    GetEntPropVector(iYou, Prop_Send, "m_vecOrigin", vPos);

    if (bAngles)
    {
        GetEntPropVector(iYou, Prop_Send, "m_angRotation", vAng);
    }

    bool bDucked = false;

    if (IsValidClient(iMe) && IsValidClient(iYou) && GetEntProp(iYou, Prop_Send, "m_bDucked"))
    {
        float vCollisionVec[3];
        vCollisionVec[0] = 24.0;
        vCollisionVec[1] = 24.0;
        vCollisionVec[2] = 62.0;
        SetEntPropVector(iMe, Prop_Send, "m_vecMaxs", vCollisionVec);
        SetEntProp(iMe, Prop_Send, "m_bDucked", 1);
        SetEntityFlags(iMe, GetEntityFlags(iMe) | FL_DUCKING);
        bDucked = true;
    }
    
    TeleportEntity(iMe, vPos, bAngles ? vAng : NULL_VECTOR, NULL_VECTOR);

    return bDucked;
}

stock int GetRandBlockCell(Handle hArray, int &iSaveIndex, int iBlock = 0, bool bAsChar = false, int iDefault = 0)
{
    int iSize = GetArraySize(hArray);
    if (iSize > 0)
    {
        iSaveIndex = GetRandomInt(0, iSize - 1);
        return GetArrayCell(hArray, iSaveIndex, iBlock, bAsChar);
    }
    iSaveIndex = -1;
    return iDefault;
}

stock int GetRandBlockCellEx(Handle hArray, int iBlock = 0, bool bAsChar = false, int iDefault = 0)
{
    int iIndex;
    return GetRandBlockCell(hArray, iIndex, iBlock, bAsChar, iDefault);
}

stock int AttachParticle(int iEnt, const char[] szParticleType, float flTimeToDie = -1.0, float vOffsets[3] = {0.0,0.0,0.0}, bool bAttach = false, float flTimeToStart = -1.0)
{
    int iParti = CreateEntityByName("info_particle_system");
    if (IsValidEntity(iParti))
    {
        float vPos[3];
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
        AddVectors(vPos, vOffsets, vPos);
        TeleportEntity(iParti, vPos, NULL_VECTOR, NULL_VECTOR);

        DispatchKeyValue(iParti, "effect_name", szParticleType);
        DispatchSpawn(iParti);

        if (bAttach)
        {
            SetParent(iEnt, iParti);
            SetEntPropEnt(iParti, Prop_Send, "m_hOwnerEntity", iEnt);
        }

        ActivateEntity(iParti);

        if (flTimeToStart > 0.0)
        {
            char szAddOutput[32];
            Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Start,,%0.2f,1", flTimeToStart);
            SetVariantString(szAddOutput);
            AcceptEntityInput(iParti, "AddOutput");
            AcceptEntityInput(iParti, "FireUser1");

            if (flTimeToDie > 0.0)
            {
                flTimeToDie += flTimeToStart;
            }
        }
        else
        {
            AcceptEntityInput(iParti, "Start");
        }

        if (flTimeToDie > 0.0) 
        {
            killEntityIn(iParti, flTimeToDie); // Interestingly, OnUser1 can be used multiple times, as the code above won't conflict with this.
        }

        return iParti;
    }
    return -1;
}

// Almost the same as the first AttachParticle(), but with rotation vector
stock int AttachParticle2(int iEnt, const char[] szParticleType, float flTimeToDie = -1.0, float vOffsets[3] = {0.0,0.0,0.0}, float rOffsets[3] = {0.0,0.0,0.0}, bool bAttach = false, float flTimeToStart = -1.0)
{
    int iParti = CreateEntityByName("info_particle_system");
    if (IsValidEntity(iParti))
    {
        float vPos[3],rPos[3];
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
        AddVectors(vPos, vOffsets, vPos);
        AddVectors(rPos, rOffsets, rPos);
        TeleportEntity(iParti, vPos, rPos, NULL_VECTOR);

        DispatchKeyValue(iParti, "effect_name", szParticleType);
        DispatchSpawn(iParti);

        if (bAttach)
        {
            SetParent(iEnt, iParti);
            SetEntPropEnt(iParti, Prop_Send, "m_hOwnerEntity", iEnt);
        }

        ActivateEntity(iParti);

        if (flTimeToStart > 0.0)
        {
            char szAddOutput[32];
            Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Start,,%0.2f,1", flTimeToStart);
            SetVariantString(szAddOutput);
            AcceptEntityInput(iParti, "AddOutput");
            AcceptEntityInput(iParti, "FireUser1");

            if (flTimeToDie > 0.0)
            {
                flTimeToDie += flTimeToStart;
            }
        }
        else
        {
            AcceptEntityInput(iParti, "Start");
        }

        if (flTimeToDie > 0.0) 
        {
            killEntityIn(iParti, flTimeToDie); // Interestingly, OnUser1 can be used multiple times, as the code above won't conflict with this.
        }

        return iParti;
    }
    return -1;
}

stock void SetParent(int iParent, int iChild)
{
    SetVariantString("!activator");
    AcceptEntityInput(iChild, "SetParent", iParent, iChild);
}

stock void killEntityIn(int iEnt, float flSeconds)
{
    char szAddOutput[32];
    Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
    SetVariantString(szAddOutput);
    AcceptEntityInput(iEnt, "AddOutput");
    AcceptEntityInput(iEnt, "FireUser1");
}

#if !defined _smlib_included
stock int PrecacheParticleSystem(const char[] particleSystem)
{
    static int particleEffectNames = INVALID_STRING_TABLE;

    if (particleEffectNames == INVALID_STRING_TABLE) {
        if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
            return INVALID_STRING_INDEX;
        }
    }

    int index = FindStringIndex2(particleEffectNames, particleSystem);
    if (index == INVALID_STRING_INDEX) {
        int numStrings = GetStringTableNumStrings(particleEffectNames);
        if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
            return INVALID_STRING_INDEX;
        }

        AddToStringTable(particleEffectNames, particleSystem);
        index = numStrings;
    }

    return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
    char buf[1024];

    int numStrings = GetStringTableNumStrings(tableidx);
    for (int i=0; i < numStrings; i++) {
        ReadStringTable(tableidx, i, buf, sizeof(buf));

        if (StrEqual(buf, str)) {
            return i;
        }
    }

    return INVALID_STRING_INDEX;
}
#endif

stock int GunmettleToIndex(int iGun, TFClassType iClass = TFClass_Unknown)
{
    switch (iGun)
    {
        case 792, 801, 851, 881, 890, 899, 908, 957, 966, // Botkiller
        15000, 15007, 15019, 15023, 15033, 15059, 15070, 15071, 15072, 15111, 15112, 15135, 15136, 15154, 30665: return TFWeapon_SniperRifle;
        case 15001, 15022, 15032, 15037, 15058, 15076, 15153, 15134: return TFWeapon_SMG;
        case 15002, 15015, 15021, 15029, 15036, 15053, 15065, 15131, 15069, 15106, 15107, 15108, 15151: return TFWeapon_Scattergun;
        case 15003, 15016, 15044, 15047, 15085, 15109, 15132, 15152:
        {
            switch (iClass)
            {
                case TFClass_Soldier: return TFWeapon_ShotgunSoldier;
                case TFClass_Pyro: return TFWeapon_ShotgunPyro;
                case TFClass_Heavy: return TFWeapon_ShotgunHeavy;
                case TFClass_Engineer: return TFWeapon_ShotgunEngie;

            }
            return TFWeapon_Shotgun;
        }
        case 15004, 15020, 15026, 15031, 15040, 15055, 15086, 15087, 15088, 15098, 15099, 15123, 15124, 15125, 15147: return TFWeapon_Minigun;
        case 15005, 15017, 15030, 15034, 15049, 15054, 15066, 15067, 15068, 15089, 15090, 15115, 15141: return TFWeapon_Flamethrower;
        case 15006, 15014, 15028, 15043, 15052, 15057, 15081, 15104, 15105, 15129, 15130, 15150: return TFWeapon_RocketLauncher;
        case 15008, 15010, 15025, 15039, 15050, 15078, 15097, 15121, 15122, 15145, 15146: return TFWeapon_Medigun;
        case 15009, 15012, 15024, 15038, 15045, 15048, 15082, 15083, 15084, 15113, 15137, 15138, 15155: return TFWeapon_StickyLauncher;
        case 15011, 15027, 15042, 15051, 15062, 15063, 15064, 15128, 15149: return TFWeapon_Revolver;
        case 15013, 15018, 15035, 15041, 15046, 15056, 15060, 15061, 15100, 15101, 15102, 15126, 15148:
        {
            switch (iClass)
            {
                case TFClass_Scout: return TFWeapon_PistolScout;
                case TFClass_Engineer: return TFWeapon_PistolEngie;
            }
            return TFWeapon_Pistol;
        }
    }
    return TFWeapon_Invalid;
}

stock bool StrStarts(const char[] szStr, const char[] szSubStr, bool bCaseSensitive = true) { return !StrContains(szStr, szSubStr, bCaseSensitive); }

stock bool IsWeaponSlotActive(int iClient, int iSlot) { return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"); }

// UPD: 12.11.2015
// SPELLS FOR HHH
public void DoAction()
{
    if (!g_bEnabled || Special != ASHSpecial_HHH || SpecialHHH_Souls <= 2) return;
    
    ASHStats[SpecialAbilities]++;
    
    //TELE
    if (SpecialHHH_Souls == 3)
    {
        SpecialHHH_Souls -= 3;
        ShootProjectile(Hale, TELE, 1100.0);
        PrintCenterText(Hale, "%t", "ash_hhh_teleportused");
    }
    //METEOR
    else if (SpecialHHH_Souls == 4)
    {
        SpecialHHH_Souls -= 4;
        ShootProjectile(Hale, METEOR, 1100.0);
        PrintCenterText(Hale, "%t", "ash_hhh_meteorused");
    }
    //LIGHT
    else if (SpecialHHH_Souls == 5)
    {
        SpecialHHH_Souls = 0;
        ShootProjectile(Hale, LIGHTNING, 300.0);
        PrintCenterText(Hale, "%t", "ash_hhh_lightningorbused");
    }
    
    return;
}

stock int ShootProjectile(int client, int spell, float SpeedMult)
{
    float vAngles[3]; // original
    float vPosition[3]; // original
    GetClientEyeAngles(client, vAngles);
    GetClientEyePosition(client, vPosition);
    char strEntname[45];
    switch(spell)
    {
        case FIREBALL:         strEntname = "tf_projectile_spellfireball";
        case LIGHTNING:     strEntname = "tf_projectile_lightningorb";
        case PUMPKIN:         strEntname = "tf_projectile_spellmirv";
        case PUMPKIN2:         strEntname = "tf_projectile_spellpumpkin";
        case BATS:             strEntname = "tf_projectile_spellbats";
        case METEOR:         strEntname = "tf_projectile_spellmeteorshower";
        case TELE:             strEntname = "tf_projectile_spelltransposeteleport";
        case BOSS:            strEntname = "tf_projectile_spellspawnboss";
        case ZOMBIEH:        strEntname = "tf_projectile_spellspawnhorde";
        case ZOMBIE:        strEntname = "tf_projectile_spellspawnzombie";
    }
    int iTeam = GetClientTeam(client);
    int iSpell = CreateEntityByName(strEntname);
    
    if(!IsValidEntity(iSpell))
        return -1;
    
    float vVelocity[3];
    float vBuffer[3];
    
    GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
    
    vVelocity[0] = vBuffer[0]*SpeedMult;
    vVelocity[1] = vBuffer[1]*SpeedMult;
    vVelocity[2] = vBuffer[2]*SpeedMult;
    
    SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
    SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
    SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
    
    TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
    
    SetVariantInt(iTeam);
    AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
    SetVariantInt(iTeam);
    AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
    
    DispatchSpawn(iSpell);

    TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
    
    return iSpell;
}

bool IsEntityStuck(int iEntity)
{
    float flOrigin[3];
    float flMins[3];
    float flMaxs[3];
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flOrigin);
    GetEntPropVector(iEntity, Prop_Send, "m_vecMins", flMins);
    GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", flMaxs);
    
    TR_TraceHullFilter(flOrigin, flOrigin, flMins, flMaxs, MASK_SOLID, TraceFilterNotSelf, iEntity);
    return TR_DidHit();
}

public bool TraceFilterNotSelf(int entity, int contentsMask, any client)
{
    if(entity == client) { return false; }
    return true;
}

void ResizePlayer(int client, float flMult)
{
    SetEntDataFloat(client, g_iOffsetModelScale, flMult);
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", flMult);
}

void LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
    iOffset = FindSendPropInfo(strClass, strProp);
    if(iOffset <= 0)
    {
        SetFailState("Could not locate offset for %s::%s!", strClass, strProp);
    }
}

public int HelpHandler_HelpMenu_ASH(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_End:
            CloseHandle(menu);
            
        case MenuAction_Cancel:
        {
            if (item == MenuCancel_ExitBack) HelpPanel2(client);
        }
        
        case MenuAction_Select:
        {
            char infoBuf[32];
            char s[1024];
            menu.GetItem(item, infoBuf, sizeof(infoBuf));
            
            SetGlobalTransTarget(client);
            
            Menu MenuHndl = CreateMenu(HelpHandler_HelpMenu_ASH);
            Format(s, 1024, "%t", "ash_help_title_info");
            MenuHndl.SetTitle(s);
            
            if (StrEqual(infoBuf, "primary"))
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 772:
                                Format(s, 1024, "%t\n", "ash_help_scout_bfb");
                            case 1103:
                                Format(s, 1024, "%t\n", "ash_help_scout_backscatter");
                            case 448:
                                Format(s, 1024, "%t\n", "ash_help_scout_sodapopper");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Soldier:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 18, 205, 414, 513, 658, 800, 809, 889, 898, 907, 916, 965, 974, 15006, 15014, 15028, 15043, 15052, 15057:
                                Format(s, 1024, "%t\n", "ash_help_soldier_rocketlaunchers");
                            case 127:
                                Format(s, 1024, "%t\n%t\n", "ash_help_soldier_rocketlaunchers", "ash_help_soldier_directhit");
                            case 228, 1085:
                                Format(s, 1024, "%t\n%t\n", "ash_help_soldier_rocketlaunchers", "ash_help_soldier_blackbox");
                            case 730:
                                Format(s, 1024, "%t\n%t\n", "ash_help_soldier_rocketlaunchers", "ash_help_soldier_beggarsbazooka");
                            case 1104:
                                Format(s, 1024, "%t\n", "ash_help_soldier_airstrike");
                            case 441:
                                Format(s, 1024, "%t\n", "ash_help_soldier_cow");
                            //case 237:
                             //   Format(s, 1024, "%t\n%t\n", "ash_help_soldier_rocketlaunchers", "ash_help_soldier_rocketjumper");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Pyro:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 40, 1146:
                                Format(s, 1024, "%t\n", "ash_help_pyro_backburner");
                            case 594:
                                Format(s, 1024, "%t\n", "ash_help_pyro_phlogistinator");
                            //case 215:
                            //    Format(s, 1024, "%t\n", "ash_help_pyro_degreaser");
                            default:
                            {
                                Format(s, 1024, "%t\n", "ash_help_pyro_flamethrower");
                            }
                        }
                    }
                    
                    case TFClass_DemoMan:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            //case 308:
                            //    Format(s, 1024, "%t\n", "ash_help_demoman_lochnload");
                            case 405:
                                Format(s, 1024, "%t\n", "ash_help_demoman_alibababooties");
                            case 1151:
                                Format(s, 1024, "%t\n", "ash_help_demoman_ironbomber");
                            case 996:
                                Format(s, 1024, "%t\n", "ash_help_demoman_cannon");
                            default:
                            {
                                bool SpecialEntity = false;
                                if (FindWearableOnPlayer(client, 405)) {
                                    Format(s, 1024, "%t\n", "ash_help_demoman_alibababooties");
                                    SpecialEntity = true;
                                }
                                
                                if (!SpecialEntity) {
                                    CloseHandle(MenuHndl);

                                    HelpPanel2(client);
                                
                                    CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                    return;
                                }
                            }
                        }
                    }
                    
                    case TFClass_Heavy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 41:
                                Format(s, 1024, "%t: %t\n", "ash_heavy_natascha_name", "ash_help_heavy_natascha");
                            case 312:
                                Format(s, 1024, "%t\n", "ash_help_heavy_brassbeast");
                            case 424:
                                Format(s, 1024, "%t\n", "ash_help_heavy_tomislav");
                            case 811, 832:
                                Format(s, 1024, "%t\n", "ash_help_heavy_huolongheater");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Engineer:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 141:
                                Format(s, 1024, "%t\n", "ash_help_engineer_frontierjustice");
                            case 588:
                                Format(s, 1024, "%t\n", "ash_help_engineer_pomson");
                            case 527:
                                Format(s, 1024, "%t\n", "ash_help_engineer_widowmaker");
                            case 1153:
                                Format(s, 1024, "%t\n", "ash_pe_panicattack");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Medic:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 17, 204:
                                Format(s, 1024, "%t\n", "ash_help_medic_syringe");
                            case 36:
                                Format(s, 1024, "%t\n", "ash_help_medic_blutsauger");
                            case 412:
                                Format(s, 1024, "%t\n", "ash_help_medic_overdose");
                            case 305, 1079:
                                Format(s, 1024, "%t\n", "ash_help_medic_crusadercrossbow");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Sniper:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 14, 201, 230, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966, 15000, 15007, 15019, 15023, 15033, 15059, 30665:
                                Format(s, 1024, "%t\n", "ash_help_sniper_allsniperrifles");
                            case 526:
                                Format(s, 1024, "%t\n%t\n", "ash_help_sniper_allsniperrifles", "ash_help_sniper_machina");
                            case 752:
                                Format(s, 1024, "%t\n%t\n", "ash_help_sniper_allsniperrifles", "ash_help_sniper_hitmansheatmaker");
                            case 56, 1005:
                                Format(s, 1024, "%t: %t\n", "ash_sniper_huntsman_name", "ash_help_sniper_huntsmanfortifiedcompound");
                            case 1092:
                                Format(s, 1024, "%t: %t\n", "ash_sniper_fortifiedcompound_name", "ash_help_sniper_huntsmanfortifiedcompound");
                            case 1098:
                                Format(s, 1024, "%t: %t\n", "ash_sniper_classic_name", "ash_help_sniper_classic");
                            case 402:
                                Format(s, 1024, "%t: %t\n", "ash_sniper_bazaar_name", "ash_help_sniper_bazaar_text");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Spy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
                        {
                            case 24, 210, 161, 1142, 15011, 15027, 15042, 15051:
                                Format(s, 1024, "%t\n", "ash_help_spy_allrevolvers");
                            case 61, 1006:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allrevolvers", "ash_help_spy_ambassador");
                            case 460:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allrevolvers", "ash_help_spy_enforcer");
                            case 525:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allrevolvers", "ash_help_spy_diamondback");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                }
            }
            else if (StrEqual(infoBuf, "secondary"))
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            //case 46, 1145:
                            //    Format(s, 1024, "%t\n%t\n", "ash_help_scout_bonkatomicpunch", "ash_help_scout_critacola");
                            //case 163:
                            //    Format(s, 1024, "%t\n", "ash_help_scout_critacola");
                            case 222:
                                Format(s, 1024, "%t: %t\n", "ash_scout_madmilk_secondaryweaponname", "ash_help_scout_milk");
                            case 1121:
                                Format(s, 1024, "%t: %t\n", "ash_scout_mutatedmilk_secondaryweaponname", "ash_help_scout_milk");
                            case 23, 209, 15013, 15018, 15041, 15046, 15056, 30666, 294, 160:
                                Format(s, 1024, "%t\n", "ash_help_se_pistol");
                            case 449:
                                Format(s, 1024, "%t\n", "ash_help_scout_winger");
                            case 812, 833:
                            {
                                Format(s, 1024, "%t", "ash_help_scout_guillotine");
                                char s2[50];
                                switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)) // я не уверен, что это будет работать
                                {
                                    case 325:
                                    {
                                        Format(s2, 50, "%t", "ash_scout_ragebasher_meleeweaponname");
                                        Format(s, 1024, "%s %t", s, "ash_help_scout_guillotine_ragebasher", s2);
                                    }
                                    case 452:
                                    {
                                        Format(s2, 50, "%t", "ash_scout_rageblade_meleeweaponname");
                                        Format(s, 1024, "%s %t", s, "ash_help_scout_guillotine_ragebasher", s2);
                                    }
                                }
                                Format(s, 1024, "%s\n", s);
                            }
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                    
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Soldier:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 10, 199, 1141, 1153, 15003, 15016, 15044, 15047:
                                Format(s, 1024, "%t\n", "ash_help_soldier_shotguns");
                            case 415:
                                Format(s, 1024, "%t\n%t: %t\n", "ash_help_soldier_shotguns", "ash_sp_reservershooter_name", "ash_help_soldier_reserveshooter");
                            case 444:
                                Format(s, 1024, "%t\n", "ash_help_soldier_mantreads");
                            case 442:
                                Format(s, 1024, "%t\n", "ash_help_soldier_righteousbison");
                            case 226:
                                Format(s, 1024, "%t\n", "ash_help_solder_battalionsbackup");
                            default:
                            {
                                bool SpecialEntity = false;
                                if (FindWearableOnPlayer(client, 133)) {
                                    Format(s, 1024, "%t\n", "ash_help_soldier_gunboats");
                                    SpecialEntity = true;
                                }
                                
                                if (FindWearableOnPlayer(client, 444)) {
                                    Format(s, 1024, "%t\n", "ash_help_soldier_mantreads");
                                    SpecialEntity = true;
                                }
                                
                                if (!SpecialEntity) {
                                    CloseHandle(MenuHndl);

                                    HelpPanel2(client);
                                    
                                    CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                    
                                    return;
                                }
                            }
                        }
                    }
                    
                    case TFClass_Pyro:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 415:
                                Format(s, 1024, "%t: %t\n", "ash_sp_reservershooter_name", "ash_help_pyro_reserveshooter");
                            case 39, 1081:
                                Format(s, 1024, "%t: %t\n", "ash_pyro_flaregun_name", "ash_help_pyro_flaregun_detonator");
                            case 351:
                                Format(s, 1024, "%t: %t\n", "ash_pyro_detonator_name", "ash_help_pyro_flaregun_detonator");
                            case 595:
                                Format(s, 1024, "%t\n", "ash_help_pyro_manmelter");
                            case 1153:
                                Format(s, 1024, "%t\n", "ash_pe_panicattack");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                    
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                    
                    case TFClass_DemoMan:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 1150:
                                Format(s, 1024, "%t\n", "ash_help_demoman_quickiebomblauncher");
                            //case 265:
                            //    Format(s, 1024, "%t\n", "ash_help_demoman_stickyjumper");
                            default:
                            {
                                bool SpecialEntity = false;
                                
                                if (FindWearableOnPlayer(client, 131, true) || FindWearableOnPlayer(client, 1144, true))
                                {
                                    Format(s, 1024, "%t\n", "ash_help_demoman_targe");
                                    SpecialEntity = true;
                                }
                                if (FindWearableOnPlayer(client, 406, true)) {
                                    Format(s, 1024, "%t\n", "ash_help_demoman_splendidscreen");
                                    SpecialEntity = true;
                                }
                                if (FindWearableOnPlayer(client, 1099, true)) {
                                    Format(s, 1024, "%t\n", "ash_help_demoman_tideturner");
                                    SpecialEntity = true;
                                }
                                
                                if (!SpecialEntity) {
                                    CloseHandle(MenuHndl);

                                    HelpPanel2(client);
                                
                                    CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                    return;
                                }
                            }
                        }
                    }
                    
                    case TFClass_Heavy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 11, 199, 425, 1141, 1153, 15003, 15016, 15044, 15047:
                                Format(s, 1024, "%t\n", "ash_help_heavy_shotguns");
                            case 311:
                                Format(s, 1024, "%t\n", "ash_help_heavy_buffalo");
                            //case 159:
                            //    Format(s, 1024, "%t\n", "ash_help_heavy_dalokosh");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                    
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Engineer:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 22, 209, 160, 294, 15013, 15018, 15035, 15041, 15046, 15056, 30666:
                                Format(s, 1024, "%t\n", "ash_help_engie_pistol");
                            case 528:
                                Format(s, 1024, "%t\n%t\n", "ash_help_engineer_shortcircuit", "ash_help_se_pistol");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                    
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                    
                    case TFClass_Medic:
                    {
                        Format(s, 1024, "%t\n%t\n", "ash_help_medic_allmediguns", "ash_help_medic_uberinfo"); // MEDIGUNS
                    }
                    
                    case TFClass_Sniper:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 16, 203, 1149, 15001, 15022, 15032, 15037, 15058:
                                Format(s, 1024, "%t\n", "ash_help_sniper_allsmgs");
                            case 751:
                                Format(s, 1024, "%t\n", "ash_help_sniper_cleanerscarabine");
                            case 58, 1083:
                                Format(s, 1024, "%t\n", "ash_help_sniper_jarate");
                            default:
                            {
                                bool SpecialEntity = false;
                                if (FindWearableOnPlayer(client, 57)) {
                                    SpecialEntity = true;
                                    Format(s, 1024, "%t\n", "ash_help_sniper_razorback");
                                } else if (FindWearableOnPlayer(client, 231)) {
                                    SpecialEntity = true;
                                    Format(s, 1024, "%t\n", "ash_help_sniper_darwinsdangershield");
                                //} else if (FindWearableOnPlayer(client, 642)) {
                                //    SpecialEntity = true;
                                //    Format(s, 1024, "%t\n", "ash_help_sniper_cozycamper");
                                }
                                
                                if (!SpecialEntity) {
                                    CloseHandle(MenuHndl);

                                    HelpPanel2(client);
                                        
                                    CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                    return;
                                }
                            }
                        }
                    }
                    
                    case TFClass_Spy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary))
                        {
                            case 735, 736, 933, 1080, 1102:
                                Format(s, 1024, "%t\n", "ash_help_spy_sappers");
                            case 810, 831:
                                Format(s, 1024, "%t\n", "ash_help_spy_redtaperecorder");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                    
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }
                }
            }
            else if (StrEqual(infoBuf, "melee"))
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 325:
                                Format(s, 1024, "%t: %t", "ash_scout_bostonbasher_name", "ash_help_scout_ragebasher_help");
                            case 452:
                                Format(s, 1024, "%t: %t", "ash_scout_threeruneblade_name", "ash_help_scout_ragebasher_help");
                            case 648:
                                Format(s, 1024, "%t", "ash_help_scout_wrapassassin");
                            case 355:
                                Format(s, 1024, "%t", "ash_help_scout_fanowar");
                            case 349:
                                Format(s, 1024, "%t", "ash_help_scout_sunonastick");
                            case 317:
                                Format(s, 1024, "%t", "ash_help_scout_candycane");
                            case 44:
                                Format(s, 1024, "%t", "ash_help_scout_sandman");
                            default:
                                Format(s, 1024, "%t", "ash_help_scout_bat");
                        }
                    }

                    case TFClass_Soldier:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 154:
                                Format(s, 1024, "%t: %t", "ash_sd_paintrain_meleeweaponname", "ash_sd_paintrain_damage");
                            case 357:
                                Format(s, 1024, "%t", "ash_sd_halfzatoichi");
                            case 447:
                                Format(s, 1024, "%t", "ash_help_soldier_disciplinaryaction");
                            case 416:
                                Format(s, 1024, "%t: %t", "ash_soldier_marketgardener_name", "ash_sp_flyattack");
                            case 775:
                                Format(s, 1024, "%t", "ash_help_soldier_escapeplan");
                            case 128:
                                Format(s, 1024, "%t", "ash_help_soldier_equalizer");
                            default:
                                Format(s, 1024, "%t", "ash_help_soldier_default");
                        }
                    }

                    case TFClass_Pyro:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 38, 1000:
                                Format(s, 1024, "%t: %t", "ash_pyro_axtinguisher_name", "ash_sp_flyattack");
                            case 153, 466:
                                Format(s, 1024, "%t", "ash_help_pyro_homewrecker");
                            case 214:
                                Format(s, 1024, "%t", "ash_help_pyro_powerjack");
                            case 593:
                                Format(s, 1024, "%t", "ash_help_pyro_thirddegree");
                            case 813, 834:
                                Format(s, 1024, "%t", "ash_help_pyro_neonannihilator");
                            case 1181:
                                Format(s, 1024, "%t", "ash_help_pyro_hothand");
                            default:
                                Format(s, 1024, "%t", "ash_help_pyro_fireaxe");
                        }
                    }

                    case TFClass_DemoMan:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 132:
                                Format(s, 1024, "%t: %t", "ash_demoman_eyelander_name", "ash_help_demoman_ehhhhnni");
                            case 154:
                                Format(s, 1024, "%t: %t", "ash_sd_paintrain_meleeweaponname", "ash_sd_paintrain_damage");
                            case 482:
                                Format(s, 1024, "%t: %t %t", "ash_demoman_nessiesnineiron_name", "ash_help_demoman_nessienineiron", "ash_help_demoman_ehhhhnni");
                            case 266:
                                Format(s, 1024, "%t: %t", "ash_demoman_horselessheadlesshorsemannheadtaker_name", "ash_help_demoman_ehhhhnni");
                            case 172:
                                Format(s, 1024, "%t", "ash_help_demoman_scotsmanskullcutter");
                            case 357:
                                Format(s, 1024, "%t", "ash_sd_halfzatoichi");
                            case 327:
                                Format(s, 1024, "%t", "ash_help_demoman_claidhearmhmor");
                            case 307:
                                Format(s, 1024, "%t", "ash_help_demoman_ullapoolcaber");
                            case 404:
                                Format(s, 1024, "%t", "ash_help_demoman_persianpersuader");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }

                    case TFClass_Heavy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 239, 1084:
                                Format(s, 1024, "%t", "ash_help_heavy_glovesofrunning");
                            case 331:
                                Format(s, 1024, "%t", "ash_help_heavy_fistsofsteel");
                            case 426:
                                Format(s, 1024, "%t", "ash_help_heavy_evictionnotice");
                            case 656:
                                Format(s, 1024, "%t", "ash_help_heavy_holidaypunch");
                            case 43:
                                Format(s, 1024, "%t\n%t", "ash_help_killingglovesofboxing", "ash_help_heavy_glovesofrunning");
                            default:
                                Format(s, 1024, "%t", "ash_help_heavy_fists");
                        }
                    }

                    case TFClass_Engineer:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 7, 169, 197, 662, 795, 804, 884, 893, 902, 911, 960, 969, 15073, 15074, 15075, 15114, 15139, 15140, 15156, 1123, 423, 1071:
                                Format(s, 1024, "%t", "ash_help_engineer_wrench");
                            case 142:
                                Format(s, 1024, "%t", "ash_help_engineer_gunslinger");
                            case 155:
                                Format(s, 1024, "%t\n%t", "ash_help_engineer_southernhospitality", "ash_help_shhh_climbwalls");
                            case 329:
                                Format(s, 1024, "%t", "ash_help_engineer_jag");
                            case 589:
                                Format(s, 1024, "%t", "ash_help_engineer_eurekaeffect");
                            default:
                            {
                                CloseHandle(MenuHndl);

                                HelpPanel2(client);
                                
                                CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                                return;
                            }
                        }
                    }

                    case TFClass_Medic:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 37, 1003:
                                Format(s, 1024, "%t", "ash_help_medic_ubersaw");
                            case 173:
                                Format(s, 1024, "%t", "ash_help_medic_vitasaw");
                            case 304:
                                Format(s, 1024, "%t", "ash_help_medic_amputator");
                            case 413:
                                Format(s, 1024, "%t", "ash_help_medic_solemnvow");
                            default:
                                Format(s, 1024, "%t", "ash_help_medic_saw");
                        }
                    }

                    case TFClass_Sniper:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 171:
                                Format(s, 1024, "%t\n%t\n%t", "ash_help_sniper_tribalmansshiv", "ash_help_sniper_allmeleeweapons", "ash_help_shhh_climbwalls");
                            case 232:
                                Format(s, 1024, "%t\n%t\n%t", "ash_help_sniper_bushwacka", "ash_help_sniper_allmeleeweapons", "ash_help_shhh_climbwalls");
                            case 401:
                                Format(s, 1024, "%t\n%t\n%t", "ash_help_sniper_shahanshah", "ash_help_sniper_allmeleeweapons", "ash_help_shhh_climbwalls");
                            default:
                                Format(s, 1024, "%t\n%t\n%t", "ash_help_sniper_default", "ash_help_sniper_allmeleeweapons", "ash_help_shhh_climbwalls");
                        }
                    }

                    case TFClass_Spy:
                    {
                        switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee))
                        {
                            case 225, 574:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allknives", "ash_help_spy_youreternalreward");
                            case 356:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allknives", "ash_help_spy_conniverskunai");
                            case 461:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allknives", "ash_help_spy_bigearner");
                            case 649:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allknives", "ash_help_spy_spycicle");
                            default:
                                Format(s, 1024, "%t\n%t\n", "ash_help_spy_allknives", "ash_help_spy_knife");
                        }
                    }
                }
            }
            else if (StrEqual(infoBuf, "inviswatch"))
            {
                if (TF2_GetPlayerClass(client) != TFClass_Spy)
                {
                    HelpPanel2(client);
                    return;
                }
                switch (GetIndexOfWeaponSlot(client, 4))
                {
                    //case 60:
                    //    Format(s, 1024, "%t", "ash_help_spy_cloakanddagger");
                    case 59:
                        Format(s, 1024, "%t", "ash_help_spy_deadringer");
                    default:
                    {
                        CloseHandle(MenuHndl);

                        HelpPanel2(client);
                                
                        CPrintToChat(client, "{ash}[ASH] {default}%t", "ash_help_no_specials");
                        return;
                    }
                }
            }
            
            ReplaceString(s, 1024, "#PERCENTAGE#", "%", true);
            
            MenuHndl.AddItem("null", s, ITEMDRAW_DISABLED);
            
            MenuHndl.ExitButton = true;
            MenuHndl.ExitBackButton = true;
            
            MenuHndl.Display(client, MENU_TIME_FOREVER);
        }
    }
}

bool FindWearableOnPlayer(int client, int wearIndex, bool IsShield = false, int entIndex = -1)
{
    if (!IsValidClient(client)) return false;
    
    bool IsNeedToReturnEntIndex = false;
    int iEntity = -1;
    char EntName[30];
    
    if (entIndex != -1) IsNeedToReturnEntIndex = true;
    
    if (IsShield) Format(EntName, 30, "tf_wearable_demoshield");
    else Format(EntName, 30, "tf_wearable");
    
    while( ( iEntity = FindEntityByClassname( iEntity, EntName ) ) != -1 )
    {
        if( GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" ) == client )
        {
            if (GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == wearIndex) {
                if (IsNeedToReturnEntIndex) entIndex = iEntity;
                return true;
            }
        }
    }
    
    return false;
}

public int MenuUpds_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select && item == 0) ShowMOTDPanel(client, "ASH - Change List", "http://g-44.ru/ash/changelist.html", MOTDPANEL_TYPE_URL);
}

stock void IronBomber_ChangeMode(int weapon, int mode) {
    switch (mode) {
        case 0:    {
            TF2Attrib_SetByDefIndex(weapon, 411, 6.0);
            TF2Attrib_SetByDefIndex(weapon, 6, -9.0);
            TF2Attrib_SetByDefIndex(weapon, 101, 1.0);
        }
        case 1:        TF2Attrib_SetByDefIndex(weapon, 411, 0.0);
        case 2:    {
            TF2Attrib_SetByDefIndex(weapon, 6, 0.4);
            TF2Attrib_SetByDefIndex(weapon, 101, 1.3);
        }
    }
}

// I though i will swap phlog attributes for ignition/freeze modes, but no, i made it without touching it! Yay!
// By the way, if i'll change my mind, i will uncomment this
/*stock void Phlog_ChangeMode(int weapon, bool mode) {
    switch (mode) {
        case false:    {
            // IGNITION
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
        }
        case true:    {
            // FREEZE
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
            TF2Attrib_SetByDefIndex(weapon, INSERT_ATTR);
        }
    }
}*/

stock void AIM_Ambassador_attr_changer(int weapon, int act_aim) {
    switch (act_aim) {
        case 0:    {
            //DEFAULT AMBASSADOR
            TF2Attrib_SetByDefIndex(weapon, 1, 0.85);
            TF2Attrib_SetByDefIndex(weapon, 6, 1.0);
            TF2Attrib_SetByDefIndex(weapon, 305, 0.0);
        }
        case 1:    {
            //MODDED AMBASSADOR
            TF2Attrib_SetByDefIndex(weapon, 1, 0.7);
            TF2Attrib_SetByDefIndex(weapon, 6, 0.35);
            TF2Attrib_SetByDefIndex(weapon, 305, 1.0);
        }
    }
}

stock float GetStunTime(int client) {
    // if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary))
    switch (GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary)) {
        case 595:         return 6.5;
        case 528:         return 3.846153846153846;
        case 163:         return 7.0;
    }
    
    return 5.0;
}

void ManmelterHUD_Render(int client, bool hud_corrector) {
    if (!ManmelterBan[client]) {
        if (plManmelterUsed[client] == 100) SetHudTextParams(-1.0, hud_corrector?0.78:0.73, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
        else SetHudTextParams(-1.0, hud_corrector?0.78:0.73, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
                    
        char s[128];
        if (plManmelterUsed[client] == 100) Format(s, 128, "%t: %t", "ash_pyro_secondchance_infometer", "ash_pyro_secondchance_ready");
        else Format(s, 128, "%t: %i%%", "ash_pyro_secondchance_infometer", plManmelterUsed[client]);
                    
        ShowSyncHudText(client, bushwackaHUD, "%s", s);
        
        if (plManmelterUsed[client] == 100 && GetEntProp(client, Prop_Send, "m_iHealth") == 1)
            TF2_OnPyroSecondChance(client);
    }
}

int ManmelterHUD_GetNeedUnstans() {
    int players = GetPlayersInTeam(OtherTeam);
    
    // Calc unstans
    /*
    17:09 - NITROUIH: 1-6 players = +100% SC
    7-14 players = +50% SC
    15-22 players = +35% SC
    23+ players = +25% SC */
    
    if (players >= 23) return 4;
    else if (players >= 15 && players <= 22) return 3;
    else if (players >= 7 && players <= 14) return 2;
    else if (players <= 6) return 1;
    return 0;
}

int ManmelterHUD_Calc() {
    switch (NeedlyUnstans) {
        case 4:        return 25;
        case 3:        return 35;
        case 2:        return 50;
        case 1:        return 100;
    }
    
    return 0;
}

void ASH_ExecuteRages(int attacker, int damage, int custom, int weapon) {
    // PrintToChatAll("%d", custom);
    if (TF2_GetPlayerClass(attacker) == TFClass_Pyro && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 593 && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && custom == 0) {
        DoTaunt(Hale, "", 0);
    }

    if (TF2_GetPlayerClass(attacker) == TFClass_Scout && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 772 && damage != 50 && damage != 68 && damage != 150 && damage != 4 && damage != 5 && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary))
    {
        if (weapon == TF_WEAPON_PEP_BRAWLER_BLASTER && custom != 3)
            SpeedDamage[attacker] += damage;
    }
    
    if (TF2_GetPlayerClass(attacker) == TFClass_Scout && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 448 && damage != 50 && damage != 68 && damage != 150 && damage != 4 && damage != 5 && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary))
    {
        if (weapon == TF_WEAPON_SODA_POPPER && custom != 3)
            SpeedDamage[attacker] += damage;
    }
    
    if (GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 404 && IsWeaponSlotActive(attacker, TFWeaponSlot_Melee) && (damage == 195 || damage == 137)) PersDamage[attacker] += damage;
    if (TF2_GetPlayerClass(attacker) == TFClass_Heavy && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 41)
    {
        if (weapon == TF_WEAPON_MINIGUN)
            NatDamage[attacker] += damage;
    }
    if (TF2_GetPlayerClass(attacker) == TFClass_Heavy && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 811)
    {
        if (weapon == TF_WEAPON_MINIGUN)
            HuoDamage[attacker] += damage;
    }
    if (TF2_GetPlayerClass(attacker) == TFClass_Heavy && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 424)
    {
        if (weapon == TF_WEAPON_MINIGUN)
            TomDamage[attacker] += damage;
        if (TF2_IsPlayerInCondition(attacker, TFCond_SpeedBuffAlly) && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary))
            TomDamage[attacker] = 0;
    }
    if (TF2_GetPlayerClass(attacker) == TFClass_Sniper && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 402 && IsWeaponSlotActive(attacker, TFWeaponSlot_Primary) && BB_Sniper_Shots[attacker] != 5) {
        BB_Sniper_Shots[attacker]++;
        BB_LastShotTime[attacker] = GetTime();
    }
    
    int WeaponID = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary);
    
    if (TF2_GetPlayerClass(attacker) == TFClass_Sniper && custom != 3 && damage > 30 && SpecialPlayers_LastActiveWeapons[attacker] == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary)) {
        if ((WeaponID == 56 || WeaponID == 1005 || WeaponID == 1092) && custom != TF_CUSTOM_BURNING_ARROW) {
            SniperActivity[attacker] += (SniperActivity)?25:20;

        } else {
            SniperNoMimoShoots[attacker]++;
            BB_Sniper_ShootTime[attacker] = 0;
        }
    }
    if (TF2_GetPlayerClass(attacker) == TFClass_Heavy && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 312)
    {
        if (weapon == TF_WEAPON_MINIGUN)
            BetDamage[attacker] += damage;
    }

    WeaponID = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary);
    if (TF2_GetPlayerClass(attacker) == TFClass_Spy && (WeaponID == 61 || WeaponID == 1006) && custom == TF_CUSTOM_HEADSHOT && headmeter[attacker] < 6 && g_iTauntedSpys[attacker] == 0 && !TF2_IsPlayerInCondition(Hale, _TFCond(28)))
    {
        ++headmeter[attacker];
    }
}

stock int CreateMedicShield(int owner, int rotate = 0) {
    int shield = CreateEntityByName("entity_medigun_shield");
    if(shield != -1) {
        SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", owner);    
        SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(owner));    
        SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(owner));    
        
        // Rotate
        char RotateStr[30];
        FormatEx(RotateStr, 30, "%i 0 0", rotate);
        DispatchKeyValue(shield, "angles", RotateStr);
        
        if (GetClientTeam(owner) == view_as<int>(TFTeam_Red)) DispatchKeyValue(shield, "skin", "0");
        else if (GetClientTeam(owner) == view_as<int>(TFTeam_Blue)) DispatchKeyValue(shield, "skin", "1");
        SetEntPropFloat(owner, Prop_Send, "m_flRageMeter", 100.0);
        SetEntProp(owner, Prop_Send, "m_bRageDraining", 1);
        DispatchSpawn(shield);
        char s[PLATFORM_MAX_PATH];
        Format(s, PLATFORM_MAX_PATH, "weapons/medi_shield_deploy.wav");
        float pos[3];
        pos[2] += 20.0;
        EmitSoundToAll(s, owner, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, owner, pos, NULL_VECTOR, true, 0.0);
        SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
        SniperNoMimoShoots[owner] = 0;
        SDKHook(shield, SDKHook_StartTouch, ShieldDefense);
        return true;
    } else return false;
}

public Action ShieldDefense(int entity, int owner) {
    if (entity != Hale && owner != Hale) return Plugin_Continue;

    PushClient(Hale);
    
    return Plugin_Changed;
}

stock void BlindPlayer(int client, int time) {
    Handle h_msg = StartMessageOne("Fade", client);
    if (h_msg)
    {
        int sec = 400 * time;
        BfWriteShort(h_msg, sec);    
        BfWriteShort(h_msg, sec);
        BfWriteShort(h_msg, 0x0001);
        BfWriteByte(h_msg, 255);
        BfWriteByte(h_msg, 255);
        BfWriteByte(h_msg, 255);
        BfWriteByte(h_msg, 255);
        EndMessage();
    }
}

public void PushClient(int client) {
    float fVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
    fVelocity[0] = fVelocity[0]-fVelocity[0]-fVelocity[0];
    if (fVelocity[0] == 0.0) fVelocity[0] = (GetRandomInt(0,1)==1)?-100.0:100.0;
    fVelocity[1] = fVelocity[1]-fVelocity[1]-fVelocity[1];
    if (fVelocity[1] == 0.0) fVelocity[1] = (GetRandomInt(0,1)==1)?-100.0:100.0;
    fVelocity[2] = 400.0;

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
}

stock bool PrepModel(const char[] model) {
    return (PrecacheModel(model, true)!=0)?true:false;
}

public Action OnSay(int client, int args) {
    if (ASHRoundState != ASHRState_Active || !GetConVarBool(cvarEnableSecretCheats))
        return Plugin_Continue;

    bool isCheat    = false;
    bool dsSound    = false;
    bool dsNotify = false;
    char msg[256];

    GetCmdArg(1, msg, 256);
    
    int IDDQD               = StrContains(msg, "IDDQD", true);
    int AEZAKMI             = StrContains(msg, "AEZAKMI", true);
    int MOOTANGO            = StrContains(msg, "MOOTANGO", true);
    int SEEMAN              = StrContains(msg, "SEEMAN", true);
    int SV_CHEATS           = StrContains(msg, "SV_CHEATS", false);
    // int AQUACURE            = StrContains(msg, "AQUACURE", false);
    int HOTNIGHT            = StrContains(msg, "HOTNIGHT", false);
    int ULLAPOOLWAR         = StrContains(msg, "ULLAPOOLWAR", false);
    int NEEDADISPENSERHERE  = StrContains(msg, "NEEDADISPENSERHERE", false);
    int BUSHMANRULES        = StrContains(msg, "BUSHMANRULES", false);

    SetGlobalTransTarget(client);
    if ((IDDQD < 2 && IDDQD >= 0) || (AEZAKMI < 2 && AEZAKMI >= 0)) {
        CPrintToChat(client, "{selfmade}%t", "ash_cheats_yourMemory");
        isCheat = true;
    } else if (MOOTANGO < 2 && MOOTANGO >= 0) {
        char sSound[64];
        FormatEx(sSound, sizeof(sSound), "ambient/cow%d.wav", GetRandomInt(1,3));
        
        if (mooEnabled && IsPlayerAlive(client))
            PlaySoundForPlayers(sSound);
        else
            dsNotify = true;
        isCheat = true;
        dsSound = true;
        
        mooEnabled = false;
        CreateTimer(60.0, cheatEnable, 0);
    } else if (SEEMAN < 2 && SEEMAN >= 0) {
        if (seeEnabled && IsPlayerAlive(client))
            PlaySoundForPlayers("saxton_hale/see.mp3");
        else
            dsNotify = true;
        isCheat = true;
        dsSound = true;
        
        seeEnabled = false;
        CreateTimer(60.0, cheatEnable, 1);
    } else if (SV_CHEATS == 1 || SV_CHEATS == 0) {
        CPrintToChat(client, "{selfmade}%t", "ash_cheats_printToConsole");
        isCheat = true;
	
    } else if (HOTNIGHT == 1 || HOTNIGHT == 0) {
        isCheat = true;
        if (hotnightEnabled || !hotnightMap || !IsPlayerAlive(client)) {
            dsSound = true;
            dsNotify = true;
        } else if (!hotnightEnabled && IsPlayerAlive(client)) {
            hotnightEnabled = true;
            hotnightMap = false;
        }
        
    } else if ((NEEDADISPENSERHERE < 2 && NEEDADISPENSERHERE >= 0)) {
        isCheat = true;
        if (!IsPlayerAlive(client) || dispenserEnabled[client] || TF2_GetPlayerClass(client) != TFClass_Scout) {
            dsSound = true;
            dsNotify = true;
        } else if (!dispenserEnabled[client] && TF2_GetPlayerClass(client) == TFClass_Scout && IsPlayerAlive(client)) {
            dispenserEnabled[client] = true;
            float pos[3];
            GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
            pos[2] += 20.0;
            EmitSoundToAll("misc/doomsday_lift_start.wav", client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
            float pPos[3] = {0.0, 0.0, 10.0};
            SetVariantInt(1);
            // ClientsHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
            AttachParticle(client, "heavy_ring_of_fire_child03", 1.0, pPos, true);
            AcceptEntityInput(client, "SetForcedTauntCam");
            SetVariantString(DispenserModel);
            AcceptEntityInput(client, "SetCustomModel");
            CreateTimer(0.5, Dispenser_Speed, client);
            SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
            SetEntProp(client, Prop_Send, "m_nBody", 0);
            TF2_RemoveAllPlayerItems(client);
        }

    } else if ((ULLAPOOLWAR < 2 && ULLAPOOLWAR >= 0)) {
        isCheat = true;
        if (!ullapoolWarMap || ullapoolWarEnabled || !IsPlayerAlive(client)) {
            dsSound = true;
            dsNotify = true;
        } else if (IsPlayerAlive(client) && !BushmanRulesEnabled) {
            ullapoolWarEnabled = true;
		}
    } else if ((BUSHMANRULES < 2 && BUSHMANRULES >= 0)) {
        isCheat = true;
        if (!BushmanRulesMap || BushmanRulesEnabled || !IsPlayerAlive(client)) {
            dsSound = true;
            dsNotify = true;
        } else if (IsPlayerAlive(client) && !ullapoolWarEnabled)
            BushmanRulesEnabled = true;
			
    } /* else if ((AQUACURE < 2 && AQUACURE >= 0)) {
        isCheat = true;
        int iShieldEnt = CreateEntityByName("prop_dynamic");
        if (!AQUACURE_Available || !IsPlayerAlive(client)) {
            dsSound = true;
            dsNotify = true;
        } else if (AQUACURE_Available && IsPlayerAlive(client)) {
            if (iShieldEnt != -1) {
                float PlyPos[3];
                GetEntPropVector(client, Prop_Send, "m_vecOrigin", PlyPos);
                TeleportEntity(iShieldEnt, PlyPos, NULL_VECTOR, NULL_VECTOR);
                DispatchKeyValue(iShieldEnt, "model", "models/effects/resist_shield/resist_shield.mdl");
                DispatchSpawn(iShieldEnt);
            
                SetVariantString("idle");
                AcceptEntityInput(iShieldEnt, "SetDefaultAnimation");
                AcceptEntityInput(iShieldEnt, "SetAnimation");
            
                SetEntProp(iShieldEnt, Prop_Send, "m_nSkin", 1);
                SetEntPropEnt(iShieldEnt, Prop_Send, "m_hOwnerEntity", client);
                // SetParent(client, iShieldEnt);
                AcceptEntityInput(iShieldEnt, "TurnOn");
            }
        
            BlockDamage[client] = true;
            SetEntityGravity(client, 0.25);
            int iEntWeapon;
            for (int iWeapon = 0; iWeapon<=5; iWeapon++) {
                if ((iEntWeapon = GetPlayerWeaponSlot(client, iWeapon)) > MaxClients+1)
                    SetNextAttack(iEntWeapon, 3.0);
            }
        
            DataPack hDP = new DataPack();
            hDP.WriteCell(client);
            hDP.WriteCell(iShieldEnt);
            hDP.Reset();
        
            AQUACURE_EntShield = iShieldEnt;
            AQUACURE_Available = false;

            CreateTimer(3.0, AQUACURE_Disable, hDP);
        }
    }*/
    
    if (isCheat) {
        if (!dsSound) PlaySound("saxton_hale/secret_enabled.wav", client);
        if (!dsNotify) {
            SetHudTextParams(-1.0, -0.7, 1.75, 200, 0, 0, 255, 0, 0.2, 0.0, 0.1);
            ShowSyncHudText(client, cheatsHUD, "CHEAT ENABLED");
        }
        return Plugin_Handled;
    } else return Plugin_Continue;
}

public void TF2_RemoveAllPlayerItems(int client) {
    if (!IsValidClient(client)) return;

    TF2_RemoveAllWeapons(client);

    int iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
        if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
            AcceptEntityInput(iEntity, "Kill");
}

public Action AQUACURE_Disable(Handle hTimer, Handle hDP) {
    int iClient = ReadPackCell(hDP);
    //int iEntShield = ReadPackCell(hDP);
    delete hDP;
    BlockDamage[iClient] = false;
//    if (AQUACURE_EntShield[iClient] <= 0)
//        return Plugin_Stop;
    if (IsValidClient(iClient)) {
        SetEntityGravity(iClient, 1.0);
    }
//    if (iEntShield > MaxClients)
//        AcceptEntityInput(iEntShield, "Kill");
    AQUACURE_EntShield[iClient] = -1;
    return Plugin_Stop;
}

public Action Dispenser_Speed(Handle hTimer, int client) {
    SetVariantInt(1);
    AcceptEntityInput(client, "SetForcedTauntCam");
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 175.0);
    return Plugin_Continue;
}

public Action Dispenser_Disable_TP(Handle hTimer, int client) {
    SetVariantInt(0);
    AcceptEntityInput(client, "SetForcedTauntCam");
    return Plugin_Continue;
}

public Action RemoveHook(Handle hTimer, any TrieData) {
    int Time;
    if (GetTrieValue(TrieData, "time", Time)) {
        Time--;
        VagineerTime_GH = Time;
        if (Time == 0) {
            int Weapon;
            GetTrieValue(TrieData, "hook", Weapon);
        
            CreateTimer(0.01, RemoveWeapon_WhileLCNotPressed, Weapon);
            CloseHandle(TrieData);
        } else {
            if (!(GetClientButtons(Hale) & IN_SCORE))
            {
                SetGlobalTransTarget(Hale);
                ShowSyncHudText(Hale, BazaarBargainHUD, "%t", "ash_Vagineer_hook_action", Time);
            }
            
            SetTrieValue(TrieData, "time", Time, true);
            CreateTimer(1.0, RemoveHook, TrieData);
        }
    }
    
    return Plugin_Stop;
}

public Action AddInvisible(Handle hTimer, any HaleHP) {
    if (ASHRoundState == ASHRState_Active && HaleHP != HaleHealth) return Plugin_Stop;
    
    //PrintToChatAll("[ASH Debug] HaleState = %i", HaleState);
    
    if (HaleState == 0) {
        HaleState = 1;
        return Plugin_Stop;
    }

    if (!IsNotNeedRemoveInvisible && (ASHRoundState == ASHRState_Active || ASHRoundState == ASHRState_Waiting)) TF2_AddCondition(Hale, _TFCond(64), TFCondDuration_Infinite);
    IsNotNeedRemoveInvisible = false;
    
    InvisibleAgent = 0.0;
    LastSound = 0.0;
    AgentPreparedSoundLaugh = 0.0;
    
    return Plugin_Stop;
}

public Action RemoveInvisible(Handle hTimer) {
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    
    TF2_RemoveCondition(Hale, _TFCond(64));
    
    return Plugin_Stop;
}

public void PlaySoundForPlayers(char[] Sound) {
    for (int ply = 1; ply<=MaxClients; ply++) {
        if (!IsValidClient(ply)) continue;
        
        PlaySound(Sound, ply);
    }
}

public void PlaySound(char[] Sound, int ply) {
    if (!IsValidClient(ply)) return;
    
    ClientCommand(ply, "play \"%s\"", Sound);
}

public Action TF2_OnHaleCondRemove(Handle hTimer, TFCond cond) {
    if (TF2_IsPlayerInCondition(Hale, cond)) TF2_RemoveCondition(Hale, cond);
}

// Agent rage
public Action CreateHologram(Handle hTimer) {
    // Find random player
    ArrayList PlayersArr = new ArrayList(ByteCountToCells(64));
    for (int iPly = 1; iPly <=MaxClients; iPly++) {
        if (!IsValidClient(iPly)) continue;
        if (IsPlayerAlive(iPly)) continue;
        if (GetClientTeam(iPly) != OtherTeam) continue;
        if (IsHologram(iPly)) continue;
        
        PlayersArr.Push(iPly);
    } 
    
    if (PlayersArr.Length == 0) return Plugin_Stop;
    
    int iPly = PlayersArr.Get(GetRandomInt(0, PlayersArr.Length-1));
    
    for (int ply = 0; ply<=MAXPLAYERS; ply++) {
        if (Holograms[ply] != 0) continue;
        
        Holograms[ply] = iPly;
        break;
    }
    
    // Change team, set class
    SetVariantInt(HaleTeam);
    AcceptEntityInput(iPly, "SetTeam");
    TF2_SetPlayerClass(iPly, TFClass_Spy);
    
    // And respawn
    TF2_RespawnPlayer(iPly);
    SetPlayerRenderAlpha(iPly, 255);
    
    return Plugin_Stop;
}

public Action Hologram_AmmoRegen(Handle hTimer, any iPly) {
    iPly = GetClientOfUserId(iPly);
    if (!iPly || ASHRoundState != ASHRState_Active)
        return Plugin_Stop;

    int iWeapon = GetPlayerWeaponSlot(iPly, TFWeaponSlot_Primary);
    if (GetAmmoNum(iPly, iWeapon) >= 24)
        return Plugin_Continue;

    SetAmmoNum(iPly, iWeapon, GetAmmoNum(iPly, iWeapon)+1);
    return Plugin_Continue;
}

public Action RemoveGod(Handle hTimer, int iPly) {
    g_bGod[iPly] = false;
}

public Action MakeHologram(Handle hTimer, any iPly) {
    if (!IsValidClient(iPly))
        return Plugin_Stop;
    TF2_RemoveAllWeapons(iPly);
    SetEntProp(iPly, Prop_Send, "m_iHealth", 400);
    EquipSaxton(iPly);

    g_bGod[iPly] = true;
    CreateTimer(4.0, RemoveGod, iPly);

    CreateTimer(5.0, Hologram_AmmoRegen, GetClientUserId(iPly), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    int ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == iPly)
        {
            int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
            switch (index)
            {
                case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
                default:    TF2_RemoveWearable(iPly, ent); //AcceptEntityInput(ent, "kill");
            }
        }
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_powerup_bottle")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == iPly)
        {
            int index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
            switch (index)
            {
                case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
                default:    TF2_RemoveWearable(iPly, ent); //AcceptEntityInput(ent, "kill");
            }
        }
    }
    ent = -1;
    while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == iPly)
        {
            TF2_RemoveWearable(iPly, ent);
            //AcceptEntityInput(ent, "kill");
        }
    }
    
    SetVariantString(Agent_Model);
    AcceptEntityInput(iPly, "SetCustomModel");
    SetEntProp(iPly, Prop_Send, "m_bUseClassAnimations", 1);
    
    return Plugin_Stop;
}

public bool IsHologram(int iPly) {
    for (int ply = 0; ply<=MAXPLAYERS; ply++) if (Holograms[ply] == iPly) return true;
    return false;
}

public int GetHologramNum(int iPly) {
    for (int ply = 0; ply<=MAXPLAYERS; ply++) if (Holograms[ply] == iPly) return ply;
    return -1;
}

public Action HologramsTimer(Handle hTimer) {
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    
    for (int ply = 0; ply <= MaxClients; ply++) {
        if (Holograms[ply] != 0) {
            int Ply = Holograms[ply];
            if (!IsPlayerAlive(Ply)) continue;
            
            /* Interface */
            SetGlobalTransTarget(Ply);
            {
                /* Hale Health */
                SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
                if (!(GetClientButtons(Ply) & IN_SCORE)) ShowSyncHudText(Ply, healthHUD, "%t", "vsh_health", HaleHealth, HaleHealthMax);
            }
            
            // Bug with MaxClassLimit
            if (TF2_GetPlayerClass(Ply) != TFClass_Spy) {
                TF2_SetPlayerClass(Ply, TFClass_Spy);
                
                SetEntityHealth(Ply, 25);
                TF2_RegeneratePlayer(Ply);
                CreateTimer(0.1, MakeHologram, Ply);
            }
            
            if (IsWeaponSlotActive(Ply, TFWeaponSlot_Primary))
                AgentHelper_ChangeTimeBeforeInvis(2.5, Ply);
            
            // Invisible state
            if (AgentHelper_IsAllowedEnterToInvis(Ply))
                InsertCond(Ply, _TFCond(64), TFCondDuration_Infinite);
            else
                RemoveCond(Ply, _TFCond(64));
            
            if (AgentHelper_IsAllowedEnterToInvis(Ply) && !g_bGod[Ply]) {
                float HologramPos[3];
                float PlayerPos[3];
                GetClientEyePosition(Ply, HologramPos);
                for (int Player = 1; Player <= MaxClients; Player++) {
                    if (!IsValidClient(Player)) continue;
                    if (Player == Hale) continue;
                    if (IsHologram(Player)) continue;
                    if (!IsPlayerAlive(Player)) continue;
                
                    GetClientEyePosition(Player, PlayerPos);

                    if (GetVectorDistance(HologramPos, PlayerPos) < 500.0) {
                        if (TF2_IsPlayerInCondition(Ply, _TFCond(64))) TF2_RemoveCondition(Ply, _TFCond(64));
                        break;
                    } else if (!TF2_IsPlayerInCondition(Ply, _TFCond(64))) TF2_AddCondition(Ply, _TFCond(64));
                }
            }
        }
    }
    
    return Plugin_Continue;
}

public void CreateBeam(int Input, int Output) {
    float InputPos[3];
    float OutputPos[3];
    
    GetEntPropVector(Input, Prop_Send, "m_vecOrigin", InputPos);
    GetEntPropVector(Output, Prop_Send, "m_vecOrigin", OutputPos);
    OutputPos[2] += 45.0;
    InputPos[2] += 45.0;
    
    TE_SetupBeamPoints(InputPos, OutputPos, PrecachedLaserBeam, 0, 0, 0, 0.25, 6.0, 0.0, 0, 0.0, {145, 176, 223, 255}, 30);
    TE_SendToAll();
}

public Action SpecialAbility_Agent(Handle hTimer) {
    if (TimeAbility <= 0.0 || ASHRoundState != ASHRState_Active) {
        AgentHelper_ChangeTimeBeforeInvis(0.2, Hale);
        TF2Attrib_RemoveByDefIndex(Hale, 252);
        
        AcceptEntityInput(ShieldEnt, "Kill");
        ShieldEnt = -1;
        
        return Plugin_Stop;
    }
    
    float BossPos[3];
    float PlyPos[3];
    
    GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", BossPos);
    
    if (ShieldEnt == -1) {
        ShieldEnt = CreateEntityByName("prop_dynamic");
        
        if (ShieldEnt != -1) {
            TeleportEntity(ShieldEnt, BossPos, NULL_VECTOR, NULL_VECTOR);
            DispatchKeyValue(ShieldEnt, "model", "models/effects/resist_shield/resist_shield.mdl");
            DispatchSpawn(ShieldEnt);
            
            SetVariantString("idle");
            AcceptEntityInput(ShieldEnt, "SetDefaultAnimation");
            SetVariantString("idle");
            AcceptEntityInput(ShieldEnt, "SetAnimation");
            
            SetEntProp(ShieldEnt, Prop_Send, "m_nSkin", 3);
            SetEntPropEnt(ShieldEnt, Prop_Send, "m_hOwnerEntity", Hale);
        }
    }
    
    for (int ply = 0; ply <= MaxClients; ply++) {
        if (!IsValidClient(ply) || ply == Hale || IsHologram(ply)) continue;
        GetEntPropVector(ply, Prop_Send, "m_vecOrigin", PlyPos);
        if (GetVectorDistance(BossPos, PlyPos) < 500.0) {
            // CRASH CLIENT: CreateBeam(Hale, ply);
            
            CreateSpark(ply);
            TF2_StunPlayer(ply, 0.5, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, Hale);
            SDKHooks_TakeDamage(ply, 0, Hale, 10.0, DMG_CLUB, GetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon"));
        }
        
        EmitAmbientSound(Agent_SpecialAbility_Zipper[1], BossPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.08);
    }
    
    int iEnt = -1;
    while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1) {
        if (GetEntProp(iEnt, Prop_Send, "m_bDisabled") == 1) continue;
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", PlyPos);
        if (GetVectorDistance(BossPos, PlyPos) < 500.0) {
            SetEntProp(iEnt, Prop_Send, "m_bDisabled", 1);
            CreateTimer(9.0, EnableSG, EntIndexToEntRef(iEnt));
        }
    }
    
    while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != -1) {
        if (GetEntProp(iEnt, Prop_Send, "m_bDisabled") == 1) continue;
        GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", PlyPos);
        if (GetVectorDistance(BossPos, PlyPos) < 500.0) {
            SetEntProp(iEnt, Prop_Send, "m_bDisabled", 1);
            CreateTimer(9.0, EnablePootis, EntIndexToEntRef(iEnt));
        }
    }
    
    CreateTesla(Hale);
    
    TimeAbility -= 0.7;
    
    return Plugin_Continue;
}

public Action EnablePootis(Handle hTimer, int iEnt) {
    int i = EntRefToEntIndex(iEnt);
    if (ASHRoundState == ASHRState_Active && IsValidEdict(i) && i > MaxClients)
    {
        char s[64];
        GetEdictClassname(i, s, 64);
        if (StrEqual(s, "obj_dispenser")) SetEntProp(i, Prop_Send, "m_bDisabled", 0);
    }
}

public Action SpecialAbility_Agent_Sound(Handle hTimer) {
    if (ASHRoundState != ASHRState_Active) return Plugin_Stop;
    if (TimeAbility <= 0.0) return Plugin_Stop;
    
    float BossPos[3];
    GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", BossPos);
    
    EmitAmbientSound(Agent_SpecialAbility_Zipper[0], BossPos, Hale, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.08);
    
    return Plugin_Continue;
}

public Action DisableCollision(Handle hTimer, int client) {
    if (IsValidClient(client)) SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
}

public Action RemoveBurn(Handle hTimer, int ply) { if (TF2_IsPlayerInCondition(ply, TFCond_OnFire)) { TF2_RemoveCondition(ply, TFCond_OnFire); } }

public void TF2_OnPyroSecondChance(int client) {
    ManmelterBan[client] = true;
    // RESURRECT! GOD POWER!
    SetEntProp(client, Prop_Send, "m_iHealth", 1);
    TF2_AddCondition(client, _TFCond(28), 0.85);
    SetEntityGravity(client, 0.35);

    float fVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
    fVelocity[2] = 300.0;
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

    EmitSoundToAll("saxton_hale/player_special_secondchance_used.wav", client);
            
    BuddhaSwitch(client, true);
    TF2_RemoveAllWeapons(client);
    // CreateTimer(0.2, StunPyro, client);
    CreateTimer(0.5, ParticlePyro_ray, client);
    CreateTimer(0.85, FreezePyro, client);
    CreateTimer(2.0, ParticlePyro_smoke, client);
    CreateTimer(2.5, ParticlePyro_tele, client);
    CreateTimer(2.6, ParticlePyro_tele2, client);
    CreateTimer(3.0, ResurrectPyro, client);
}

public Action PlaySoundToAll(Handle hTimer) {
    PlaySoundForPlayers(VagineerSAStart);
}

public Action RemoveAttackAttrib(Handle hTimer, any weapon) { TF2Attrib_RemoveByDefIndex(weapon, 1); }

/*
 * Refactored Medic Shield with Amputator
 * Dev by Kruzefaggen
 */
public Action MedicAmpShield(Handle hTimer, any DPAmp) {
    int Medic;
    float Time;
    
    // Check Trie is correctly
    if (!GetTrieValue(DPAmp, "medic", Medic) || !GetTrieValue(DPAmp, "time", Time)) {
        CloseHandle(DPAmp);
        return Plugin_Stop;
    }
    
    // Check medic is correctly
    if (!IsValidClient(Medic) || !IsPlayerAlive(Medic)) {
        CloseHandle(DPAmp);
        return Plugin_Stop;
    }
    
    // Ok
    if (Time > 0.0) {
        // Shield for medic
        if (TF2_IsPlayerInCondition(Medic, TFCond_DefenseBuffed)) TF2_RemoveCondition(Medic, TFCond_DefenseBuffed);
        if (TF2_IsPlayerInCondition(Medic, _TFCond(28))) TF2_RemoveCondition(Medic, _TFCond(28));
        TF2_AddCondition(Medic, TFCond_DefenseBuffed, 0.5);
        TF2_AddCondition(Medic, _TFCond(28), 0.5);
        
        // Shield for others (distance - 400)
        float MedicPos[3], OtherPos[3];
        GetEntPropVector(Medic, Prop_Send, "m_vecOrigin", MedicPos);
        for (int ply = 1; ply<=MaxClients; ply++) {
            // Ignore medic, Hale and other team (hello, holograms!)
            if (!IsValidClient(ply) || ply == Hale || ply == Medic || GetClientTeam(ply) != OtherTeam) continue;

            GetEntPropVector(ply, Prop_Send, "m_vecOrigin", OtherPos);
            if (GetVectorDistance(MedicPos, OtherPos) <= 585.0) {
                if (TF2_IsPlayerInCondition(ply, TFCond_DefenseBuffed)) TF2_RemoveCondition(ply, TFCond_DefenseBuffed);
                if (TF2_IsPlayerInCondition(ply, _TFCond(28))) TF2_RemoveCondition(ply, _TFCond(28));
                TF2_AddCondition(ply, TFCond_DefenseBuffed, 0.5);
                TF2_AddCondition(ply, _TFCond(28), 0.5);
            }
        }
    
        // Restart timer
        CreateTimer(0.2, MedicAmpShield, DPAmp);
        Time -= 0.2;
        SetTrieValue(DPAmp, "time", Time);
    }
    return Plugin_Stop;
}

public Action SpawnAgentSapper(Handle hTimer, int ply) {
    if (IsValidClient(ply)) {
        char attribs[64];
        FormatEx(attribs, sizeof(attribs), "451 ; 1.0 ; 452 ; 3.0 ; 214 ; %d ; 425 ; 2.5", GetRandomInt(1000000000, 2147483640));
        
        int sapper = SpawnWeapon(ply, "tf_weapon_sapper", 933, 100, TFQual_Unusual, attribs);
        if (sapper != -1) {
            SetEntProp(sapper, Prop_Send, "m_iObjectType", 3);
            SetEntProp(sapper, Prop_Data, "m_iSubType", 3);
            CreateTimer(0.1, ReturnKnife, ply);
            SetEntPropEnt(ply, Prop_Send, "m_hActiveWeapon", sapper);
        }
    }
}

public Action ReturnKnife(Handle hTimer, int ply) {
    if (IsValidClient(ply)) {
        int melee = GetPlayerWeaponSlot(ply, TFWeaponSlot_Melee);
        if (melee != -1) SetEntPropEnt(ply, Prop_Send, "m_hActiveWeapon", melee);
    }
}

// Visual helpers
public void CreateTesla(int iEnt) {
    float pos[3];
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", pos);
    
    {
        int tesla = CreateEntityByName("point_tesla");
        
        DispatchKeyValue(tesla, "m_flRadius", "100.0");
        DispatchKeyValue(tesla, "m_SoundName", "DoSpark");
        DispatchKeyValue(tesla, "beamcount_min", "42");
        DispatchKeyValue(tesla, "beamcount_max", "62");
        DispatchKeyValue(tesla, "texture", "sprites/physbeam.vmt");
        DispatchKeyValue(tesla, "m_Color", "255 255 255");
        DispatchKeyValue(tesla, "thick_min", "10.0");
        DispatchKeyValue(tesla, "thick_max", "11.0");
        DispatchKeyValue(tesla, "lifetime_min", "0.3");
        DispatchKeyValue(tesla, "lifetime_max", "0.3");
        DispatchKeyValue(tesla, "interval_min", "0.1");
        DispatchKeyValue(tesla, "interval_max", "0.2");
        
        DispatchSpawn(tesla);
        TeleportEntity(tesla, pos, NULL_VECTOR, NULL_VECTOR);
     
        AcceptEntityInput(tesla, "TurnOn"); 
        AcceptEntityInput(tesla, "DoSpark");
    }
}

public void CreateSpark(int iEnt) {
    float pos[3]; 
    float two[3];
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", pos);
    two[2] = pos [2] + 10.0;

    {
        TE_SetupSparks(pos, two, 500, 100);
        TE_SendToAll();
    }
}

public void DeleteParticle(int iParticle) {
    float NewPos[3] = {7999.0, 7999.0, 7999.0};
    TeleportEntity(iParticle, NewPos, NULL_VECTOR, NULL_VECTOR);
    CreateTimer(0.1, DeleteParticle_Tim, iParticle);
}

public Action DeleteParticle_Tim(Handle hTimer, any iParticle) {
    AcceptEntityInput(iParticle, "Kill");
}

public Action Particle_cycle(Handle hTimer, any dptrie) {
    int client;
    char particle[32];
    GetTrieValue(dptrie, "soldier", client);
    GetTrieString(dptrie, "particle", particle, 32);
    
    if (!IsPlayerAlive(client) || !IsValidClient(client) || ASHRoundState != ASHRState_Active) {
        CloseHandle(dptrie);
        return Plugin_Stop;
    }
    
    float parPos[3] = {0.0, 0.0, 0.5};
    AttachParticle(client, particle, 0.9, parPos, true);
    return Plugin_Continue;
}

public Action StunDisable(Handle hTimer) {
    Stun = 0;
}

public int GetActiveWeaponIndex(int client) {
    if (!IsValidClient(client)) return -1; // ThrowError("Invalid client");
    
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    return weapon != -1 ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

bool FindItemInArray(int iItem, int[] iItems, int iItemsLength) {
    for (int idx = 0; idx < iItemsLength; idx++)
        if (iItem == iItems[idx]) return true;
    return false;
}

stock int AttachSprite(int Client, char[] sprite, float scale = 0.1) {
    if(!IsPlayerAlive(Client)) return -1;
    
    /* char iTarget[16];
    Format(iTarget, 16, "Client%d", GetClientUserId(Client));
    DispatchKeyValue(Client, "targetname", iTarget); */
    float Origin[3];
    GetEntPropVector(Client, Prop_Send, "m_vecOrigin", Origin);
    Origin[2] += 85.0;
    
    int Ent = CreateEntityByName("env_sprite");
    if(!Ent) return -1;
    
    char sScale[20];
    FormatEx(sScale, sizeof(sScale), "%f", scale);
    
    DispatchKeyValue(Ent, "model", sprite);
    DispatchKeyValue(Ent, "classname", "env_sprite");
    DispatchKeyValue(Ent, "spawnflags", "1");
    DispatchKeyValue(Ent, "scale", sScale);
    DispatchKeyValue(Ent, "rendermode", "1");
    DispatchKeyValue(Ent, "rendercolor", "255 255 255");
    DispatchSpawn(Ent);
    TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);
    /* SetVariantString(iTarget);
    AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0); */
    
    SetParent(Client, Ent);
    SetEntPropEnt(Ent, Prop_Send, "m_hOwnerEntity", Client);
    return Ent;
}

public Action DeleteEntity(Handle hTimer, any iEntity) {
    if (iEntity <= 0 || !IsValidEntity(iEntity))
        return Plugin_Stop;

    AcceptEntityInput(iEntity, "Kill");
    return Plugin_Stop;
}

public void AgentHelper_ChangeTimeBeforeInvis(float time, int client) {
    if (Special != ASHSpecial_Agent)
        return;
    if (!client)
        client = Hale;

    float newtime = GetEngineTime() + time;
    if (newtime > m_fAgent_InvisibleNext[client])
        m_fAgent_InvisibleNext[client] = newtime;
}

public bool AgentHelper_IsAllowedEnterToInvis(int client) {
    if (!client)
        client = Hale;
    if (g_bGod[client])
        return true;

    return GetEngineTime() > m_fAgent_InvisibleNext[client];
}

public Action OnTimerRemoveCondition(Handle hTimer, Handle hDP) {
    DataPack hData = view_as<DataPack>(hDP);
    hData.Reset();
    int item            = hData.ReadCell();
    int attribID        = hData.ReadCell();
    float attribValue     = hData.ReadFloat();
    
    delete hDP;
    
    TF2Attrib_SetByDefIndex(item, attribID, attribValue);
}

public Action OnTimerRemoveCloakFeature(Handle hTimer, Handle hDP) {
    DataPack hData = view_as<DataPack>(hDP);
    hData.Reset();
    int item            = hData.ReadCell();
    int attribID        = hData.ReadCell();
    float attribValue     = hData.ReadFloat();
    
    delete hDP;
    
    if (TF2_IsPlayerInCondition(item, TFCond_Cloaked)) return Plugin_Stop;
    TF2Attrib_SetByDefIndex(item, attribID, attribValue);
    return Plugin_Stop;
}

public Action cheatEnable(Handle hTimer, any cheatType) {
    switch (cheatType) {
        case 0: mooEnabled = true;
        case 1: seeEnabled = true;
        case 2: ullapoolWarEnabled = false;
		case 3: BushmanRulesEnabled = false;
    }
}

public Action HeavyShokolad_OnUberNeed(Handle hTimer, any client) {
    if (IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iHealth") < 290 && GetRandomInt(0, 100) > 30 && GetAmmoNum(client, GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) < 1) {
        TF2_AddCondition(client, TFCond_Ubercharged, 7.0);
        TF2_AddCondition(client, TFCond_Kritzkrieged, 7.0);
    }
}

public Action OnBelatedDeleteAttribute(Handle hTimer, DataPack hPack) {
    hPack.Reset();
    int iEntity     = EntRefToEntIndex(hPack.ReadCell());
    int iAttribute  = hPack.ReadCell();

    if (iEntity > 0) {
        TF2Attrib_RemoveByDefIndex(iEntity, iAttribute);
    }
}

public Action OnBelatedChangeAttribute(Handle hTimer, DataPack hPack) {
    hPack.Reset();
    int iEntity     = EntRefToEntIndex(hPack.ReadCell());
    int iAttribute  = hPack.ReadCell();
    float flValue   = hPack.ReadFloat();

    if (iEntity > 0) {
        TF2Attrib_SetByDefIndex(iEntity, iAttribute, flValue);
    }
}

public Action CanBeTarget(Handle hTimer, any client)
{
    g_iFidovskiyFix[client] = 0;
    g_iTimerList[client] = null;
}

stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

public Action From255to30(Handle hTimer, any client)
{
    g_iAlphaSpys[client] = 255;
    
    g_bAlphaSpyDelay[client] = true;
    
    g_iTimerList_Alpha[client] = null;
    g_iTimerList_Switch[client] = null;
    
    if (g_iTimerList_Repeat[client][0] != null)
    {
        KillTimer(g_iTimerList_Repeat[client][0]);
        g_iTimerList_Repeat[client][0] = null;
    }
    
    if (g_iTimerList_Repeat[client][1] != null)
    {
        KillTimer(g_iTimerList_Repeat[client][1]);
        g_iTimerList_Repeat[client][1] = null;
    }
    
    if(!g_bAlphaSpysAllow[client][1]) 
    {
        g_bAlphaSpysAllow[client][0] = true;
        int clientid = GetClientUserId(client);
        g_iTimerList_Repeat[client][0] = CreateTimer(1.0/22.5, SetPlayerRenderAlpha_ActionTo30_0, clientid, TIMER_REPEAT);
    }
    
    if(!g_bAlphaSpysAllow[client][0])
    {
        g_bAlphaSpysAllow[client][1] = true;
        int clientid = GetClientUserId(client);
        g_iTimerList_Repeat[client][1] = CreateTimer(1.0/22.5, SetPlayerRenderAlpha_ActionTo30_1, clientid, TIMER_REPEAT);
    }
}

public Action SetPlayerRenderAlpha_ActionTo30_0(Handle hTimer, any clientid)
{
    int client = GetClientOfUserId(clientid);
    
    if(g_bAlphaSpysAllow[client][0] && client > 0 && g_iAlphaSpys[client] > 30) 
    {
        g_iAlphaSpys[client]--;
        return Plugin_Continue;
    }
    else
    {
        if(g_iTimerList_Repeat[client][0] != null)
        {
            KillTimer(g_iTimerList_Repeat[client][0]);
            g_iTimerList_Repeat[client][0] = null;
        }
        return Plugin_Continue;
    }
}

public Action SetPlayerRenderAlpha_ActionTo30_1(Handle hTimer, any clientid)
{
    int client = GetClientOfUserId(clientid);
    
    if(g_bAlphaSpysAllow[client][1] && g_iAlphaSpys[client] > 30 && client > 0)
    {
        g_iAlphaSpys[client]--;
        return Plugin_Continue;
    }
    else
    {
        if(g_iTimerList_Repeat[client][1] != null)
        {
            KillTimer(g_iTimerList_Repeat[client][1]);
            g_iTimerList_Repeat[client][1] = null;
        }
        return Plugin_Continue;
    }
}

public Action PhlogFreeze_reboot(Handle hTimer, any client)
{
    g_iFreezePhlogPar = 0;
    g_isVictimFrozen[client] = false;
    SetEntityRenderColor(client, 255, 255, 255);
}

public Action CatchSticky(Handle hTimer, any entity)
{
    char EntityName[64];
    GetEntityClassname(entity, EntityName, 64);
    
    if(StrEqual(EntityName, "tf_projectile_pipe_remote", true))
    {
        int iPlayer = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
        int iSecondary = GetIndexOfWeaponSlot(iPlayer, TFWeaponSlot_Secondary);
    
        if (g_bEnabled && ASHRoundState == ASHRState_Active && TF2_GetPlayerClass(iPlayer) == TFClass_DemoMan && iSecondary == 1150)
        {
            float EngineTime = GetEngineTime();
            float ChargeTime = 1.5; //GetEntPropFloat(weapon, Prop_Send, "m_flChargeBeginTime");
            float BeginExplodeTime = EngineTime + ChargeTime;
        
            /*PrintToChatAll("EngineTime: %f", EngineTime);
            PrintToChatAll("ChargeTime: %f", ChargeTime);
            PrintToChatAll("BeginExplodeTime: %f", BeginExplodeTime);
            */
            g_fStickyExplodeTime[entity] = BeginExplodeTime;
        }
    }
}

/*public Action AddPrimary(Handle hTimer)
{
    LoopPlayers(client)
    {
        if(client > 0 && client != Hale)
        {
            if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 40 || GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 1146)
            {   
                int iEnt = MaxClients + 1; 
                iEnt = FindEntityByClassname2(iEnt, "tf_weapon_flamethrower");
                if(GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(iEnt, Prop_Send, "m_iClip1") < 200)  
                {                       
                    SetEntProp(iEnt, Prop_Send, "m_iClip1", GetEntProp(iEnt, Prop_Send, "m_iClip1")+40); // +40 primary ammo
                }
            }
        }
    }
}*/

/*public Action From30to255(Handle hTimer, any client)
{
    g_iAlphaSpys[client] = 30;

    for(int i=1; i<=225; i++)
    {
        DataPack hPack;
        CreateDataTimer(float(i)/22.5, SetPlayerRenderAlpha_ActionFrom30, hPack);
        hPack.WriteCell(client);
        hPack.WriteCell(i);
    }
}

public Action SetPlayerRenderAlpha_ActionFrom30(Handle hTimer, DataPack hPack)
{
    hPack.Reset();
    int client = hPack.ReadCell();
    int i = hPack.ReadCell();
    
    g_iAlphaSpys[client] = i+30;
}*/

//public Action EquipDefault(int client, )

public void __EmitSoundToAll(const char[] szSound)
{
    EmitSoundToAll(szSound);
    EmitSoundToAll(szSound);
}

#include "ASH/API.sp"
#include "ASH/UTIL.sp"
#include "ASH/Logic.sp"
#include "ASH/Events.sp"
#include "ASH/Extension.sp"
#include "ASH/Ability/Agent.sp"

/**
 * Developing started: 18 July, 2015
 */
