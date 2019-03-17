#if defined _ASH_included
 #endinput
#endif
#define _ASH_included


// ASH_GetRoundState()
enum
{
    ASHRState_Disabled = -1,
    ASHRState_Waiting,
    ASHRState_Active,
    ASHRState_End
}

// ASH_GetSpecialRoundIndex()
enum
{
    ASHSpecial_None = -1,
    ASHSpecial_Hale,
    ASHSpecial_MiniHale,
    ASHSpecial_Vagineer,
    ASHSpecial_HHH,
    ASHSpecial_CBS,
    ASHSpecial_Bunny,
    ASHSpecial_Agent
}

// ASH events
enum {
    ASHEvent_RoundStart,
    ASHEvent_RoundEnd
}

/**
 * Will ASH be played on the current map?
 * Use this check in OnMapStart() or OnPluginStart(),
 * since ASH_IsSaxtonHaleModeEnabled() returns 0 before the 1st round.
 *
 * @return 1 if it's a ASH map, 0 otherwise.
 */
native bool:ASH_IsSaxtonHaleModeMap();

/**
 *
 * @return True if ASH is enabled, false otherwise.
 */
native bool:ASH_IsSaxtonHaleModeEnabled();

/**
 * Returns whether or not to ignore the player must be
 *
 * @param ply		Client to check.
 */
native bool:ASH_IsBossHelper(ply);

/**
 * Returns the userid of the current Hale.
 *
 * @return		    	Userid of current Hale/boss (-1 if invalid/doesn't exist).
 */
native ASH_GetSaxtonHaleUserId();

/**
 * Current team number for the boss.
 *
 * @return		    	Hale's team number (as in the TFTeam enum)
 */
native ASH_GetSaxtonHaleTeam();

/**
 * Current special
 *
 * @return		    	0 - Saxton Hale
 *						1 - Vagineer
 *						2 - HHH
 *						4 - CBS
 */
native ASH_GetSpecialRoundIndex();

/**
 * Hale's current health.
 *
 * @return		    	An integer representing Hale's health.
 */
native ASH_GetSaxtonHaleHealth();

/**
 * Hale's initial health.
 *
 * @return		    	An integer representing Hale's max/initial health.
 */
native ASH_GetSaxtonHaleHealthMax();

/**
 * Damage dealt by a client. Change.
 * 
 * @param client		Client index.
 * @param damage	Damage dealt by the client.
 * @noreturn
 */
native ASH_SetClientDamage(client, damage);

/**
 * Damage dealt by a client.
 *
 * @param client 		Client index.
 * @return		    	Damage dealt by the client for the current round.
 */
native ASH_GetClientDamage(client);

/**
 * The current round state for ASH.
 *
 * @return		     -1 - ASH is disabled
 *				0 - ASH preround freeze
 *				1 - ASH during round
 *				2 - ASH after round end
 */
native ASH_GetRoundState();

/*
 * Return current round num.
 *
 * @return			Current round.
 */
native ASH_GetRoundNum();

/**
 * When Hale attempts to superjump/teleport.
 *
 * @param bSuperDuper 	Boolean for whether the jump is a superjump.
 * @return		    Change bSuperDuper and return Plugin_Changed to change it. Plugin_Stop or Plugin_Handled to stop the jump.
 */
forward Action:ASH_OnDoJump(&bool:bSuperDuper);

/**
 * When Hale attemps to use rage.
 *
 * @param RageDist 	Distance that the boss's rage reaches.
 * @return		    Plugin_Stop or Plugin_Handled will prevent rage, change RageDist and return Plugin_Changed to change the distance.
 */
forward Action:ASH_OnDoRage(&Float:RageDist);

/**
 * When Hale uses the weighdown.
 *
 * @return		    Plugin_Stop/Plugin_Handled will prevent Weighdown
 */
forward Action:ASH_OnDoWeighdown();

/**
 * Called at the start of each round, when the music begins to play (even if the round has no music).
 * Also called each time the music is set to start up again in the loop.
 *
 * @param sound		Sound that is being played for music. Change it and return Plugin_Changed to change.
 *				Set to "" for silence that does not stop the forward firing every <time> seconds.
 * @param time		Duration of the sound (seconds). Must change this to the duration of whatever the music was changed to,
 * 				but +2 to 4 seconds so that your song doesn't overlap itself. Set to -1.0 to play the music only once.
 * @return			Plugin_Stop or Plugin_Handled to prevent the music from playing (stops the music/forward for the entire round),
 *				or change the values and return Plugin_Changed to change the music. REMEMBER TO CHANGE THE TIME AS WELL.
 */
forward Action:ASH_OnMusic(String:sound[], &Float:time);

/**
 * Called when ASH opens a panel to a client, stating they will be hale next round.
 *
 * @param client 	Client to be hale soon.
 * 
 * @return 			Plugin_Stop or Plugin_Handled to prevent panel being opened. Plugin_Continue to allow panel to be displayed.
 */
forward Action:ASH_OnHaleNext(client);

public SharedPlugin:__pl_AdvancedSaxtonHale = 
{
	name = "advancedsaxtonhale",
	file = "ASH_Core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_AdvancedSaxtonHale_SetNTVOptional()
{
	MarkNativeAsOptional("ASH_IsSaxtonHaleModeMap");
	MarkNativeAsOptional("ASH_IsSaxtonHaleModeEnabled");
	MarkNativeAsOptional("ASH_GetSaxtonHaleUserId");
	MarkNativeAsOptional("ASH_GetSaxtonHaleTeam");
	MarkNativeAsOptional("ASH_GetSpecialRoundIndex");
	MarkNativeAsOptional("ASH_GetSaxtonHaleHealth");
	MarkNativeAsOptional("ASH_GetSaxtonHaleHealthMax");
	MarkNativeAsOptional("ASH_GetClientDamage");
	MarkNativeAsOptional("ASH_GetRoundState");
}
#endif
