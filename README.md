# Advanced Saxton Hale
RUUUUNN!! COWAAAARRDSS!

Advanced Saxton Hale - fork of Versus Saxton Hale Mode. Authors of the original: Dr.Eggman, FlaminSarge, Chdata, nergal.

Authors of the fork:

- [**NITROYUASH**](http://steamcommunity.com/profiles/76561198045687452). Almost all ideas, balance, new item abilities and initial startup.
- [**CrazyHackGUT aka Kruzya**](https://kruzya.me). Main programmer. Wrote more than half of the current code base.
- [**FeedBlack**](http://steamcommunity.com/profiles/76561198278138597). Programmer. Helps a lot with the last updates.

Great Thanks, **community**! We love you!

## Requirements
- [**SourceMod**](https://www.sourcemod.net/downloads.php?branch=stable) 1.9 or higher.
- [**TF2Items**](https://builds.limetech.io/?project=tf2items). Used for modifying weapons before initial equipping, for creating weapon for bosses.
- [**TF2Attributes**](https://forums.alliedmods.net/showthread.php?t=210221). Used for modifying weapons "on-the-fly", when players already plays on map and can damage.
- [**TF2Attributes Gamedata**](https://raw.githubusercontent.com/FlaminSarge/tf2attributes/master/tf2.attributes.txt). Install this on **tf2/addons/sourcemod/gamedata**
- [**SteamWorks**](https://forums.alliedmods.net/showthread.php?t=229556). _Optional_. Used for changing game name in server browser. 1.3.2+ or higher.

## Additional Modules
ASH contains 2 default modules with the main plugin. If you don't need them, just put those plugins to "Disabled" folder or delete.
- [**ASH_HudDamage.smx**] Players can see each other's hale damage on HUD.
- [**ASH_Timer.smx**] Start round limit timer in Player VS Boss (1-vs-1) situations.

## Recommended Plugins:
- [**sm_observerpoint.smx**](https://forums.alliedmods.net/showthread.php?p=724109) This will fix observer_point error on many community maps when server is empty.
- [**Anti-Arena Latespawn**](https://forums.alliedmods.net/showthread.php?t=316597) Stops players from spawning during the round in arena mode.
- [**Arena Spectator Anti-Stuck**](https://github.com/jobggun/Sourcemod-Anti-Unassigned-Stuck) This is useful when people gets stuck in _Spectator_ or _Unassigned_ team.
- [**Third Person**](https://forums.alliedmods.net/showthread.php?p=1694178) Access to third person mode for everyone.
- [**Class Restriction**](https://forums.alliedmods.net/showthread.php?p=642353) Limiting maximum amount of single class. A very important to prevent _12 snipers vs hale_ moments.
- [**VSH Health Bar**](https://forums.alliedmods.net/showpost.php?p=2106597&postcount=4200) Works through _VSH->ASH Backwards Compatibility_ feature.

## New Cvars:
You can configure cvars in tf/cfg/sourcemod/AdvancedSaxtonHale.cfg

- hale_boss_secret_1 (Default: 1) - Enable First Secret Boss
- hale_enable_jumper (Default: 1) - Enable rocket jumper and sticky jumper
- hale_enable_sapper (Default: 1) - Enable passive attributes of spy's sappers
- hale_enable_secret_cheats (Default: 1) - Enable secret cheats
- hale_tryhard_directhit (Default: 0) - Enable Direct Hit stun
- hale_tryhard_machina (Default: 1) - Enable Machina stun
