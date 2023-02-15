#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <nvault>

#include <settings>

#define PLUGIN "Furien CSO"
#define VERSION "1.0"
#define AUTHOR "Filiq_"

// players
new 
	Float:Wallorigin[MAX_PLAYERS + 1][3],
	pClass[MAX_PLAYERS + 1],
	pFurienClass[MAX_PLAYERS + 1],
	pAFurienClass[MAX_PLAYERS + 1],

	pXP[MAX_PLAYERS + 1],
	pLevel[MAX_PLAYERS + 1],

	pName[MAX_PLAYERS + 1][33],

	jumpnum[MAX_PLAYERS + 1] = 0,
	bool:dojump[MAX_PLAYERS + 1] = false,

	Float:powerCooldown[MAX_PLAYERS + 1],

	isBot,
	isFurien,
	haveSuperKnife,
	haveSuperKnife2,
	haveSuperKnifeVIP,
	haveSuperKnifeGOD,
	dualmp5, // 4 vip
	
	isVIP,
	isGOD,

	isWithAvaliableWeapons,
	isWallHang,

	isFrozen

// altele
new 
	bool:CanPlant, 
	C4_CountDownDelay,
	szPrefix [ ] = "^4[Furien XP Mod]^3 -",
	furienHealth,
	afurienHealth,
	nVaultSave,

	Float:t_time,
	gEnt,

	spriteFreeze

new const shop_furienHealth[] = "exhealth/zm_buyhealth.wav" 
new const shop_afurienHealth[] = "exhealth/hm_buyhealth.wav" 

enum 
{
	powerNone,
	powerTeleport,
	powerFreeze,
	powerDrop,
	powerDrag,
	powerRecoil
}

new powerDescription[][] = {
	{""},
	{"^4Teleportare"},
	{"a ^4Ingheata jucatorul"},
	{"a ^4Dropeaza arma inamicului"},
	{"a ^4Atrage jucatorul spre tine"},
	{"a ^4Tintii mai bine"}
}

enum serverClassE
{
	name[30],
	level,
	v_weapon[50],
	p_weapon[50],
	Float:speed,
	Float:gravity,
	health,
	armor,
	CsTeams:tteam,
	Float:knifeDmg,
	cPower
}

enum
{
	trainer,
	agnos,
	xfother,
	samurai,
	esamurai,
	ignes,
	elf,
	alcadeias,

	druid,
	hunter,
	mage,
	rogue,
	shaman,
	warlock,
	warrior,
	deklowaz
}

new serverClass[][serverClassE] = {
	{
		"Trainer", // nume clasa
		1,  // nivelul clasei
		"models/furien/knifes/v_combatknife.mdl", // v _knife
		"models/furien/knifes/p_combatknife.mdl", // p_knife
		900.0, // viteza
		0.7, // gravitatia
		100, // viata
		0, // armura
		TEAM_FURIEN, // echipa clasei 
		1.0, // dmg * x puterea knifeului, x reprezentant 1.0 de ex. adica nu schimba cu nimic
		powerNone
	},
	{
		"Agnos", 
		5, 
		"models/furien/knifes/v_infinity_knife1.mdl", 
		"models/furien/knifes/p_infinity_knife1.mdl", 
		930.0, 
		0.6, 
		120, 
		60, 
		TEAM_FURIEN, 
		1.5,
		powerNone
	},
	{
		"XFother", 
		9, 
		"models/furien/knifes/v_natad.mdl", 
		"models/furien/knifes/p_natad.mdl", 
		1000.0, 
		0.6, 
		120, 
		60, 
		TEAM_FURIEN, 
		2.0,
		powerNone
	},	
	{
		"Samurai", 
		13, 
		"models/furien/knifes/v_katana.mdl", 
		"models/furien/knifes/p_katana.mdl", 
		1010.0, 
		0.6, 
		135, 
		90, 
		TEAM_FURIEN, 
		2.8,
		powerNone
	},
	{
		"Extra Samurai", 
		17, 
		"models/furien/knifes/v_double_katana.mdl", 
		"models/furien/knifes/p_double_katana.mdl", 
		1050.0, 
		0.5, 
		145, 
		105, 
		TEAM_FURIEN, 
		3.3,
		powerNone
	},
	{
		"Ignes", 
		21, 
		"models/furien/knifes/v_ignes.mdl", 
		"", 
		1100.0, 
		0.5, 
		185, 
		150, 
		TEAM_FURIEN, 
		4.0,
		powerFreeze,
	},
	{
		"Elf", 
		25, 
		"models/furien/knifes/v_elf.mdl", 
		"", 
		1150.0, 
		0.4, 
		185, 
		160, 
		TEAM_FURIEN, 
		4.5,
		powerTeleport
	},
	{
		"Alcadeias", 
		29, 
		"models/furien/knifes/v_vipaxe.mdl", 
		"models/furien/knifes/p_vipaxe.mdl", 
		1200.0, 
		0.4, 
		185, 
		160, 
		TEAM_FURIEN, 
		5.3,
		powerTeleport,
	},

	// anti furien
	{
		"Druid", 
		1, 
		"weapon_xm1014", 
		"weapon_usp", 
		320.0, 
		1.0, 
		105, 
		30, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerNone
	},
	{
		"Hunter", 
		5, 
		"weapon_p90", 
		"weapon_usp", 
		320.0, 
		1.0, 
		120, 
		60, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerNone
	},
	{
		"Mage", 
		9, 
		"weapon_galil", 
		"weapon_usp", 
		320.0, 
		0.7, 
		120, 
		60, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerNone
	},
	{
		"Rogue", 
		13, 
		"weapon_famas", 
		"weapon_usp", 
		320.0, 
		0.7, 
		120, 
		80, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerDrag 
	},
	{
		"Shaman", 
		17, 
		"weapon_sg552", 
		"weapon_usp", 
		320.0, 
		0.7, 
		145, 
		90, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerDrag
	},
	{
		"Warlock", 
		21, 
		"weapon_p90", 
		"weapon_usp", 
		320.0, 
		0.6, 
		165, 
		105, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerRecoil
	},
	{
		"Warrior", 
		25, 
		"weapon_p90", 
		"weapon_usp", 
		320.0, 
		0.6, 
		180, 
		115, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerRecoil
	},
	{
		"Deklowaz", 
		29, 
		"weapon_p90", 
		"weapon_usp", 
		320.0, 
		0.6, 
		200, 
		130, 
		TEAM_ANTIFURIEN, 
		0.0, 
		powerTeleport
	},
}

enum
{
	MODEL_USP,
	MODEL_KNIFE_SHOP,
	MODEL_KNIFE_SHOP2,
	MODEL_HEGRENADE,
	MODEL_SMOKE,
	MODEL_FLASH,
	MODEL_DUALMP5,
	MODEL_DUALKRISS,
	MODEL_THOMPSON,
	MODEL_TAR21,
	MODEL_SVDEX,
	MODEL_FNC,
	MODEL_F2000,
	MODEL_KNIFE_VIP,
	MODEL_KNIFE_GOD,
	MODEL_KNIFE_AF
}

enum cModelsE
{
	v_wpn[50],
	p_wpn[50]
}
new customModels[][cModelsE] = {
	{"models/furien/weapons/v_uspx.mdl", "models/furien/weapons/p_uspx.mdl"},
	{"models/furien/knifes/v_superknife_shop.mdl", ""},
	{"models/furien/knifes/v_superknife_shop2.mdl", "models/furien/knifes/p_superknife_shop2.mdl"},
	{"models/furien/v_he.mdl", ""},
	{"models/furien/v_smoke.mdl", ""},
	{"models/furien/v_flash.mdl", ""},
	{"models/furien/weapons/v_dualmp5.mdl", "models/furien/weapons/p_dualmp5.mdl"},
	{"models/furien/weapons/v_dualkriss.mdl", "models/furien/weapons/p_dualkriss.mdl"},
	{"models/furien/weapons/v_thompson.mdl", "models/furien/weapons/p_thompson.mdl"},
	{"models/furien/weapons/v_tar21.mdl", "models/furien/weapons/p_tar21.mdl"},
	{"models/furien/weapons/v_svdex.mdl", "models/furien/weapons/p_svdex.mdl"},
	{"models/furien/weapons/v_fnc.mdl", "models/furien/weapons/p_fnc.mdl"},
	{"models/furien/weapons/v_f2000.mdl", "models/furien/weapons/p_f2000.mdl"},
	{"models/furien/knifes/v_vipaxe2.mdl", ""},
	{"models/furien/knifes/v_GodVipAxe.mdl", ""},
	{"models/furien/knifes/v_Ice.mdl", ""}
}

enum shopEnum 
{
	superKnifeVIP,
	superKnifeGOD,
	superKnife,
	dualmp5vip,
	defuseKit,
	heGrenade,
	priceHP,
	priceAP
}

new priceShop[shopEnum] = {
	9000,
	10000,
	8000, // super knife
	5000,
	300, // defuse kit
	2500, // he grenade
	3000, // hp
	2000 // ap
}

new Levels[30] =  {
	70, //1
	150, //2
	200, //3
	300, //4
	380, //5
	500, //6
	550, //7
	650, //8
	800, //9
	900, //10
	1000, //11
	1200, //12
	1400, //13
	1650, //14
	1800, //15
	2000, //16
	2300, //17
	2600, //18
	3000, //19
	3300, //20
	3600, //21
	4000, //22
	4300, //23
	4900, //24
	5400, //25
	6000, //26
	6500, //27
	7000, //28
	7700, //29
	8000 //30
}

// bonus box
new bool:HasSpeed[MAX_PLAYERS + 1], bool:HasTeleport[MAX_PLAYERS + 1]
new Model[2][] = {
	"models/furien/cadout_new.mdl",
	"models/furien/cadouct.mdl"
}

// new Model_Yellow[2][] = {
// 	"models/furien/cadout_galben.mdl",
// 	"models/furien/cadouct_galben.mdl"
// }

public plugin_natives()
{

}

public plugin_precache()
{
	precache_sound(shop_furienHealth)
	precache_sound(shop_afurienHealth)

	furienHealth = precache_model("sprites/exhealth/health_zombie.spr") 
	afurienHealth = precache_model("sprites/exhealth/health_human.spr") 
	
	precache_model("models/player/furienmodel/furienmodel.mdl")
	precache_model("models/player/antifurien2012/antifurien2012.mdl")
	precache_model("models/player/WhiteMask/WhiteMask.mdl")

	spriteFreeze = precache_model("sprites/laserbeam.spr")

	static i

	for(i = 0; i < sizeof(serverClass); i++)
	{
		if(strfind(serverClass[i][v_weapon], "weapon_") != -1)
			break

		precache_model(serverClass[i][v_weapon])
		
		if(strlen(serverClass[i][p_weapon]) > 2)
			precache_model(serverClass[i][p_weapon])
	}

	for(i = 0; i < sizeof(customModels); i++)
	{
		precache_model(customModels[i][v_wpn])

		if(strlen(customModels[i][p_wpn]) > 2)
			precache_model(customModels[i][p_wpn])
	}

	for (i = 0; i < sizeof Model; i++)
		precache_model(Model[i])
	
	// for (i = 0; i < sizeof Model_Yellow; i++)
	// 	precache_model(Model_Yellow[i])

	remove_entity_name("info_map_parameters")
	remove_entity_name("func_buyzone")
	
	new Entity = create_entity("info_map_parameters")
	
	DispatchKeyValue(Entity, "buying", "3")
	DispatchSpawn(Entity)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	static blockcmds[][] = {
		"jointeam", "jointeam 1", "jointeam 2", "jointeam 3", "chooseteam",
		"radio1", "radio2", "radio3"
	}

	static weaponsList[][] = {
		"weapon_glock18", "weapon_usp", "weapon_deagle", "weapon_p228", "weapon_elite", "weapon_fiveseven", "weapon_m3", "weapon_xm1014", "weapon_mp5navy",
		"weapon_mac10", "weapon_tmp", "weapon_p90", "weapon_ump45", "weapon_galil", "weapon_famas",
		"weapon_ak47", "weapon_m4a1", "weapon_sg552", "weapon_aug", "weapon_g3sg1", "weapon_sg550",
		"weapon_scout", "weapon_awp", "weapon_m249", "weapon_knife", "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade"
	}

	static i;

	for(i = 0; i < sizeof(blockcmds); i++)
		register_clcmd(blockcmds[i], "blockCmds")

	register_clcmd("say /class", "classCmd")
	register_clcmd("say /shop", "shopCmd")
	register_clcmd("say /xp", "showXPCmd")
	register_clcmd("say /level", "showLevel")

	register_clcmd("power", "cmdPower")

	register_concmd("amx_givexp", "giveXPCmd", ADMIN_IMMUNITY, "<target / all> <amount>")
	register_concmd("amx_setxp", "setXPCmd", ADMIN_IMMUNITY, "<target / all> <amount>")

	for(i = 0; i < sizeof(weaponsList); i++)
		RegisterHam(Ham_Item_Deploy, weaponsList[i], "changeModel", 1)

	RegisterHam(Ham_Spawn, "player", "client_spawned")
	RegisterHam(Ham_Touch, "player", "fw_PlayerTouch", 1)
	RegisterHam(Ham_Touch, "weaponbox", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "HAM_Touch_Weapon")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "C4_PrimaryAttack") 
	RegisterHam(Ham_TakeDamage, "player", "client_takeDamage")

	register_forward(FM_PlayerPreThink, "Player_PreThink")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink")
	register_forward(FM_CmdStart, "CmdStart")
	register_forward(FM_Touch, "Touch")

	gEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(pev_valid(gEnt))
	{
		set_pev(gEnt, pev_classname, "invisibility")
		global_get(glb_time, t_time)
		set_pev(gEnt, pev_nextthink, t_time + 0.1)
		register_think("invisibility", "makeFurienInvisible")
	} 
	else 
	{
		set_task(0.1, "makeFurienInvisible", .flags="b")
	}

	register_event("DeathMsg", "client_killed", "a")
	register_event("SendAudio", "EVENT_SwitchTeam", "a", "1=0", "2=%!MRAD_ctwin")
	register_event("HLTV", "EVENT_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "blockCmds", "b", "2&#Game_radio", "4&#Fire_in_the_hole")
	register_event("TextMsg", "blockCmds", "b", "3&#Game_radio", "5&#Fire_in_the_hole")	

	register_message(get_user_msgid("StatusIcon"), "MSG_StatusIcon")
	register_message(get_user_msgid("TextMsg"), "MSG_TextMessage")
	register_message(get_user_msgid("SendAudio"), "MSG_SendAudio")

	nVaultSave = nvault_open("furienxpmod")
}

public plugin_end()
{
	nvault_close(nVaultSave)
}

public client_authorized(id)
{
	if(is_user_bot(id))
		SetBit(isBot, id)

	if(get_user_flags(id) & ADMIN_LEVEL_H)
		SetBit(isVIP, id)

	if(get_user_flags(id) & ADMIN_LEVEL_G)
	{
		SetBit(isVIP, id)
		SetBit(isGOD, id)
	}

	#if defined HUD_SYSTEM 
		set_task(1.0, "showHud", id, _, _, "b")
	#endif 

	get_user_name(id, pName[id], 31)

	new 
		vaultkey[64],
		vaultdata[256]

	format(vaultkey, sizeof(vaultkey), "%s", pName[id])
	format(vaultdata, sizeof(vaultdata), "%d#%d#%d#%d", pLevel[id], pXP[id], pFurienClass[id], pAFurienClass[id])

	nvault_get(nVaultSave, vaultkey, vaultdata, sizeof(vaultdata))
	replace_all(vaultdata, sizeof(vaultdata), "#", " ")

	new lvl[32], xp[32], fclass[32], afclass[32]

	parse(vaultdata, lvl, sizeof(lvl), xp, sizeof(xp), fclass, sizeof(fclass), afclass, sizeof(afclass))

	pLevel[id] = str_to_num(lvl)
	pXP[id] = str_to_num(xp)

	pClass[id] = 0
	pFurienClass[id] = str_to_num(fclass)
	pAFurienClass[id] = str_to_num(afclass)

	if(pLevel[id] == 0)
		pLevel[id] = 1

	client_cmd(id, "bind f power")
}

public client_disconnected(id)
{
	#if defined HUD_SYSTEM 
		if(task_exists(id))
			remove_task(id)
	#endif 

	ClearBit(isBot, id)
	ClearBit(isVIP, id)
	ClearBit(isGOD, id)

	ClearBit(haveSuperKnife, id)
	ClearBit(haveSuperKnife2, id)
	ClearBit(haveSuperKnifeVIP, id)
	ClearBit(haveSuperKnifeGOD, id)

	ClearBit(isFrozen, id)

	new 
		vaultkey[64],
		vaultdata[256]

	format(vaultkey, sizeof(vaultkey), "%s", pName[id])
	format(vaultdata, sizeof(vaultdata), "%d#%d#%d#%d", pLevel[id], pXP[id], pFurienClass[id], pAFurienClass[id])

	nvault_set(nVaultSave, vaultkey, vaultdata)
}

public client_PreThink(id)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED

	if(GetBit(isFrozen, id))
	{
		set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
		set_pev(id, pev_maxspeed, 1.0)
	}

	if(get_user_button(id) & IN_USE)
	{
		if(!GetBit(isFurien, id))
			useParachute(id)
	}

	if((get_user_button(id) & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(get_user_oldbutton(id) & IN_JUMP))
	{
		if(!GetBit(isFurien, id) && jumpnum[id] < 2)
		{
			dojump[id] = true
			jumpnum[id]++
		}
		if(GetBit(isFurien, id) && jumpnum[id] < 1)
		{
			dojump[id] = true
			jumpnum[id]++
		}
	}
	if((get_user_button(id) & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
	}

	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(dojump[id] == true)
	{
		new Float:velocity[3]	
		entity_get_vector(id,EV_VEC_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,velocity)
		dojump[id] = false
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}	

public blockCmds() {
	return PLUGIN_HANDLED
}

public classCmd(id)
{
	showClassMenu(id)

	return PLUGIN_HANDLED_MAIN
}

public shopCmd(id)
{
	showShopMenu(id)

	return PLUGIN_HANDLED_MAIN
}

public showXPCmd(id)
{
	client_print_color(id, 0, "%s Ai ^4%d^3 XP, iar levelul tau este ^4%d^3.", szPrefix, pXP[id], pLevel[id])

	return PLUGIN_HANDLED_MAIN
}

public showLevel(id)
{
	client_print_color(id, 0, "%s Levelul tau este ^4%d^3.", szPrefix, pLevel[id])

	return PLUGIN_HANDLED_MAIN
}

public cmdPower(id)
{
	if(serverClass[pClass[id]][cPower] == powerNone)
		return PLUGIN_HANDLED
	
	if(get_gametime() - powerCooldown[id] < 30)
		return client_print_color(id, 0, "%s Puterea iti va reveni in^4 %.1f^3 secunde.", szPrefix, get_gametime() - powerCooldown[id])

	switch(serverClass[pClass[id]][cPower])
	{
		case powerNone:
			return PLUGIN_HANDLED

		case powerTeleport: teleportPower(id)
		case powerFreeze: freezePower(id)
		case powerDrop: dropPower(id)
		case powerDrag: dragPower(id)
		case powerRecoil: recoilPower(id)
	}

	powerCooldown[id] = get_gametime()

	return PLUGIN_CONTINUE
}

public giveXPCmd(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3)) 
		return PLUGIN_HANDLED

	new 
		target[32], 
		amount[21], 
		gplayers[32], 
		players, num, i
	
	read_argv(1, target, 31)
	read_argv(2, amount, 20)
	
	new player = cmd_target(id, target, 8);
	
	if(!player)  
		return PLUGIN_HANDLED;

	new 
		admin_name[32], 
		player_name[32]

	get_user_name(id, admin_name, 31)
	get_user_name(player, player_name, 31)

	new expnum = str_to_num(amount)

	client_print_color(id, 0, "^4ADMIN ^3%s^1: ^1give ^4%s ^1xp to ^3%s", admin_name, amount, player_name)

	giveXP(player, expnum)

	if(equali(target, "@All") || equali(target, "all"))
	{
		get_players(gplayers, num, "a")
		for(i = 0; i < num; i++) 
		{
			players = gplayers[i];
			if(!is_user_connected(players))
				continue

			giveXP(players, expnum)
		}
	}

	return PLUGIN_CONTINUE
}

public setXPCmd(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3)) 
		return PLUGIN_HANDLED

	new 
		target[32], 
		amount[21], 
		gplayers[32], 
		players, num, i
	
	read_argv(1, target, 31)
	read_argv(2, amount, 20)
	
	new player = cmd_target(id, target, 8);
	
	if(!player)  
		return PLUGIN_HANDLED;

	new 
		admin_name[32], 
		player_name[32]

	get_user_name(id, admin_name, 31)
	get_user_name(player, player_name, 31)

	new expnum = str_to_num(amount)

	client_print_color(id, 0, "^4ADMIN ^3%s^1: ^1set ^4%s ^1xp to ^3%s", admin_name, amount, player_name)

	setXP(player, expnum)

	if(equali(target, "@All") || equali(target, "all"))
	{
		get_players(gplayers, num, "a")
		for(i = 0; i < num; i++) 
		{
			players = gplayers[i];
			if(!is_user_connected(players))
				continue

			setXP(players, expnum)
		}
	}

	return PLUGIN_CONTINUE
}

public showClassMenu(id)
{
	new 
		string[70],
		str[3]

	formatex(string, sizeof(string), "\r%sFurien Class \yMenu", GetBit(isFurien, id) ? "" : "Anti-")
	new menu = menu_create(string, "handlerClassMenu")

	for(new i = 0; i < sizeof(serverClass); i++)
	{
		if(cs_get_user_team(id) != serverClass[i][tteam])
			continue

		if(pLevel[id] >= serverClass[i][level])
			formatex(string, sizeof(string), "\y%s", serverClass[i][name])
		else
			formatex(string, sizeof(string), "\y%s [ \rLOCEKD \y]", serverClass[i][name])

		num_to_str(i, str, 2)
		menu_additem(menu, string, str)
	}

	menu_display(id, menu)

	return PLUGIN_HANDLED_MAIN		
}

public showShopMenu(id)
{
	new 
		menu = menu_create("Shop Menu", "handlerShopMenu"),
		string[50]

	if(GetBit(isFurien, id))
	{
		formatex(string, sizeof(string), "\yHorse Axe VIP \y[ \r%d $\y ]%s", priceShop[superKnifeVIP], GetBit(isVIP, id) ? "" : "\r[LOCKED]")
		menu_additem(menu, string, "0")

		formatex(string, sizeof(string), "\yDevil Axe GOD \y[ \r%d $\y ]%s", priceShop[superKnifeGOD], GetBit(isGOD, id) ? "" : "\r[LOCKED]")
		menu_additem(menu, string, "1")

		formatex(string, sizeof(string), "\ySuper Knife \y[ \r%d $\y ]", priceShop[superKnife])
		menu_additem(menu, string, "2")
	}
	else
	{
		formatex(string, sizeof(string), "\yDual Mp5 VIP  \y[ \r%d $\y ]%s", priceShop[dualmp5vip], GetBit(isVIP, id) ? "" : "\r[LOCKED]")
		menu_additem(menu, string, "3")

		formatex(string, sizeof(string), "\yDefuse Kit \y[ \r%d $\y ]", priceShop[defuseKit])
		menu_additem(menu, string, "4")
	}

	formatex(string, sizeof(string), "\yHE Grenade \y[ \r%d $\y ]", priceShop[heGrenade])
	menu_additem(menu, string, "5")

	formatex(string, sizeof(string), "\r+\y50 HP \y[ \r%d $\y ]", priceShop[priceHP])
	menu_additem(menu, string, "6")

	formatex(string, sizeof(string), "\r+\y50 AP\r + \yHelmet \y[ \r%d $\y ]", priceShop[priceAP])
	menu_additem(menu, string, "7")

	menu_display(id, menu)

	return PLUGIN_HANDLED
}

public handlerClassMenu(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED

	new 
		data[6], szName[64],
		access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback)
	new class = str_to_num(data)

	if(pLevel[id] < serverClass[class][level])
	{
		showClassMenu(id)

		return PLUGIN_HANDLED
	}


	if(GetBit(isFurien, id)) 
		pFurienClass[id] = class
	else 
		pAFurienClass[id] = class

	#if defined DEBUG
		if(GetBit(isFurien, id)) 
			pClass[id] = pFurienClass[id]
		else 
			pClass[id] = pAFurienClass[id]

		setUserAbilitesClass(id, class)
		giveUserWeaponsClass(id, class)

		client_print_color(id, 0, "%s [DEBUG] Clasa ta este acum^4 %s^3.", szPrefix, serverClass[class][name])
	#else
		if(serverClass[class][cPower] == powerNone)
			client_print_color(id, 0, "%s Urmatoarea ta clasa va fii^4 %s^3.", szPrefix, serverClass[class][name])
		else
		{	
			client_print_color(id, 0, "%s Urmatoarea ta clasa va fii^4 %s^3, + puterea de %s.", szPrefix, serverClass[class][name], powerDescription[serverClass[class][cPower]])
			client_print_color(id, 0, "%s Pentru activarea puterii apasa tasta ^4F sau bind tasta ^"power^" in consola ^3.", szPrefix)
		}
		
	#endif

	return PLUGIN_CONTINUE
}

public handlerShopMenu(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id))
		return PLUGIN_HANDLED

	new 
		data[6], szName[64],
		access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback)
	new 
		itm = str_to_num(data),
		price = 0,
		money = cs_get_user_money(id)

	switch(itm)
	{
		case 0: 
		{
			if(!GetBit(isVIP, id))
				return showShopMenu(id)

			if(money - priceShop[superKnifeVIP] <= 0)
				return showShopMenu(id)

			if(GetBit(isFurien, id))
				SetBit(haveSuperKnifeVIP, id)

			ClearBit(haveSuperKnife, id)
			ClearBit(haveSuperKnife2, id)
			ClearBit(haveSuperKnifeGOD, id)

			cs_set_user_money(id, money - priceShop[superKnifeVIP])
		}
		case 1:
		{
			if(!GetBit(isGOD, id))
				return showShopMenu(id)

			if(money - priceShop[superKnifeGOD] <= 0)
				return showShopMenu(id)

			if(GetBit(isFurien, id))
				SetBit(haveSuperKnifeGOD, id)

			ClearBit(haveSuperKnife, id)
			ClearBit(haveSuperKnife2, id)
			ClearBit(haveSuperKnifeVIP, id)

			cs_set_user_money(id, money - priceShop[superKnifeGOD])
		}
		case 2:
		{
			if(!GetBit(isFurien, id))
				return showShopMenu(id)

			if(money - priceShop[superKnife] <= 0)
				return showShopMenu(id)

			if(pLevel[id] >= 15) 
			{
				SetBit(haveSuperKnife2, id)

				ClearBit(haveSuperKnife, id)
				ClearBit(haveSuperKnifeVIP, id)
				ClearBit(haveSuperKnifeGOD, id)
			}
			else 
			{
				SetBit(haveSuperKnife, id)
			
				ClearBit(haveSuperKnife2, id)
				ClearBit(haveSuperKnifeVIP, id)
				ClearBit(haveSuperKnifeGOD, id)
			}

			cs_set_user_money(id, money - priceShop[superKnife])
		}
		case 3:
		{
			if(!GetBit(isVIP, id))
				return showShopMenu(id)
			
			if(GetBit(isFurien, id))
				return showShopMenu(id)

			if(money - priceShop[dualmp5vip] <= 0)
				return showShopMenu(id)

			SetBit(dualmp5, id)
			give_item(id, "weapon_mp5navy")

			cs_set_user_money(id, money - priceShop[dualmp5vip])
		}
		case 4:
		{
			if(money - priceShop[defuseKit] <= 0)
				return showShopMenu(id)

			cs_set_user_money(id, money - priceShop[defuseKit])
			give_item(id, "item_thighpack")
		}
		case 5: 
		{
			if(money - priceShop[heGrenade] <= 0)
				return showShopMenu(id)

			if(user_has_weapon(id, CSW_HEGRENADE)) 
				return showShopMenu(id)

			cs_set_user_money(id, money - priceShop[heGrenade])
			give_item(id, "weapon_hegrenade")
		}
		case 6:
		{
			if(money - priceShop[priceHP] <= 0)
				return showShopMenu(id)

			cs_set_user_money(id, money - priceShop[priceHP])

			set_dhudmessage(31, 201, 31, 0.02, 0.90, 0, 6.0, 1.0)
			show_dhudmessage(id, "+50 HP")

			set_user_health(id, get_user_health(id) + 50)

			if(GetBit(isFurien, id))
				emit_sound(id, CHAN_ITEM, shop_furienHealth, 0.6, ATTN_NORM, 0, PITCH_NORM)
			else 
				emit_sound(id, CHAN_ITEM, shop_afurienHealth, 0.6, ATTN_NORM, 0, PITCH_NORM)
		
			static origin[3] 
			get_user_origin(id, origin) 

			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_SPRITE) 
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]+=30) 

			if(GetBit(isFurien, id))
				write_short(furienHealth) 
			else 
				write_short(afurienHealth) 
			
			write_byte(8) 
			write_byte(255) 
			message_end() 
		}
		case 7:
		{
			if(money - priceShop[priceAP] <= 0)
				return showShopMenu(id)

			cs_set_user_money(id, money - priceShop[priceAP])

			set_dhudmessage(31, 201, 31, 0.20, 0.90, 0, 6.0, 1.0)
			show_dhudmessage(id, "+50 AP")

			set_user_armor(id, get_user_armor(id) + 50)
		}
	}

	cs_set_user_money(id, cs_get_user_money(id) - price)

	return PLUGIN_CONTINUE
}

public changeModel(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED

	new id = get_pdata_cbase(id, 41, 4)
	
	change_weapon_model(id, cs_get_user_weapon(id))

	return HAM_IGNORED
}

public client_spawned(id) {
	if(is_user_connected(id) && is_user_alive(id))
		set_user_footsteps(id, cs_get_user_team(id) == TEAM_ANTIFURIEN ? 0 : 1)

	ClearBit(isFurien, id)

	set_task(0.2, "spawned", id)
}

public spawned(id)
{
	for(new i = 0; i < 2; i++)
		strip_user_weapons(id)

	cs_reset_user_model(id)

	if(cs_get_user_team(id) == TEAM_FURIEN) 
	{
		pClass[id] = pFurienClass[id]
		
		give_item(id, "weapon_flashbang")

		SetBit(isFurien, id)

		cs_set_user_model(id, "furienxp")
	}
	else 
	{
		pClass[id] = pAFurienClass[id]
	
		if(GetBit(isVIP, id)) 
			cs_set_user_model(id, "WhiteMask")
		else
			cs_set_user_model(id, "antifurien2012")

		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	}
	give_item(id, "weapon_knife")
	give_item(id, "weapon_hegrenade")

	setUserAbilitesClass(id, pClass[id])
	giveUserWeaponsClass(id, pClass[id])

	showClassMenu(id)

	if(GetBit(isFrozen, id)) 
		remove_freeze(id)
}

public fw_PlayerTouch(id, world)
{
	if(is_user_alive(id) && GetBit(isFurien, id))
	{	
		new ClassName[32]
		pev(world, pev_classname, ClassName,(32-1))
 
		if(equal(ClassName, "worldspawn") || equal(ClassName, "func_wall") || equal(ClassName, "func_breakable"))
			pev(id, pev_origin, Wallorigin[id])
	}
 
	return HAM_SUPERCEDE
}

public HAM_Touch_Weapon(ent, id) {
	if(is_user_alive(id) && GetBit(isFurien, id) && !(get_pdata_cbase(ent, 39, 4) > 0))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public C4_PrimaryAttack(Ent) {
	if(!CanPlant) 
		return HAM_SUPERCEDE
		
	return HAM_IGNORED
}

public client_takeDamage(victim, inflictor, attacker, Float:damage, damageBits)
{
	if(inflictor != attacker)
		return HAM_IGNORED

	if(GetBit(isFurien, attacker))
	{
		if(get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_IGNORED

		if(GetBit(haveSuperKnife2, attacker))
			SetHamParamFloat(4, damage * 2.5)
		else if(GetBit(haveSuperKnife, attacker))
			SetHamParamFloat(4, damage * 2.0)
		else if(GetBit(haveSuperKnifeVIP, attacker))
			SetHamParamFloat(4, damage * 3.0)
		else if(GetBit(haveSuperKnifeGOD, attacker))
			SetHamParamFloat(4, damage * 5.0)
		else 
			SetHamParamFloat(4, damage * serverClass[pClass[attacker]][knifeDmg])
	}
	else
	{
		if(GetBit(dualmp5, attacker) && get_user_weapon(attacker) == CSW_MP5NAVY)
			SetHamParamFloat(4, damage * 2.0)

		if(pClass[attacker] == deklowaz && get_user_weapon(attacker) == CSW_P90)
			SetHamParamFloat(4, damage * 3.0)

		if(pClass[attacker] == warlock && get_user_weapon(attacker) == CSW_P90)
			SetHamParamFloat(4, damage * 3.0)

		if(pClass[attacker] == shaman && get_user_weapon(attacker) == CSW_SG552)
			SetHamParamFloat(4, damage * 2.5)

		if(pClass[attacker] == rogue && get_user_weapon(attacker) == CSW_FAMAS)
			SetHamParamFloat(4, damage * 2.0)

		if(pClass[attacker] == mage && get_user_weapon(attacker) == CSW_GALIL)
			SetHamParamFloat(4, damage * 1.5)

		if(pClass[attacker] == hunter && get_user_weapon(attacker) == CSW_P90)
			SetHamParamFloat(4, damage * 1.2)
	}

	return HAM_HANDLED
}

public Player_PreThink(id) 
{
	if(is_user_connected(id)) 
	{
		if(pClass[id] != -1)
		{
			if(pev(id, pev_maxspeed) < serverClass[pClass[id]][speed] && pev(id, pev_maxspeed) > 1.0) 
				set_pev(id, pev_maxspeed, serverClass[pClass[id]][speed])
		
			if(pev(id, pev_gravity) > serverClass[pClass[id]][gravity] && pev(id, pev_gravity) > 0.1)
				set_pev(id, pev_gravity, serverClass[pClass[id]][gravity])
		}
	}
}

// ty aragon i think, furien 3.0
public fw_PlayerPostThink(id) 
{
	if(is_user_alive(id) && GetBit(isFurien, id))
	{
		static Float:Origin[3];
		pev(id, pev_origin, Origin);
 
		static Button;
		Button = pev(id, pev_button);
 
		if(Button & IN_USE && get_distance_f(Origin, Wallorigin[id]) <= 5.0 && !(pev(id, pev_flags) & FL_ONGROUND))
		{
			new Float:Velocity[3];
			new ClimbSpeed = floatround(pev(id, pev_maxspeed) / 2.0);
 
			if(Button & IN_FORWARD)
			{
				velocity_by_aim(id, ClimbSpeed, Velocity);
				fm_set_user_velocity(id, Velocity);

				if(!GetBit(isWallHang, id))
					SetBit(isWallHang, id)
			}
			else if(Button & IN_BACK)
			{
				velocity_by_aim(id, - ClimbSpeed, Velocity);
				fm_set_user_velocity(id, Velocity);

				if(!GetBit(isWallHang, id))
					SetBit(isWallHang, id)
			}
			else
			{
				set_pev(id, pev_origin, Wallorigin[id]);
				velocity_by_aim(id, 0, Velocity);
				fm_set_user_velocity(id, Velocity);

				if(GetBit(isWallHang, id))
					ClearBit(isWallHang, id)
			}

			
		}
	}
}

public CmdStart(id, uc_handle, seed) 
{
	new ent = fm_find_ent_by_class(id, "BonusBox")
	if(is_valid_ent(ent)) {
		new classname[32]	
		pev(ent, pev_classname, classname, 31)
		if (equal(classname, "BonusBox")) {
			
			if (pev(ent, pev_frame) >= 120)
				set_pev(ent, pev_frame, 0.0)
			else
				set_pev(ent, pev_frame, pev(ent, pev_frame) + 1.0)
			
			switch(pev(ent, pev_team))
			{
				case 1: 
				{ 	
				}	
				case 2: 
				{ 
				}
			}
		}
	}
}

public Touch(toucher, touched)
{
	if (!is_user_alive(toucher) || !pev_valid(touched))
		return FMRES_IGNORED
	
	new classname[32]	
	pev(touched, pev_classname, classname, 31)
	if (!equal(classname, "BonusBox"))
		return FMRES_IGNORED
	
	if(get_user_team(toucher) == pev(touched, pev_team))
	{
		GiveBonus(toucher)
		set_pev(touched, pev_effects, EF_NODRAW)
		set_pev(touched, pev_solid, SOLID_NOT)
		remove_entity(touched);
	}
	return FMRES_IGNORED
}

// o metoda proasta, trb refacuta
// // ty EFFx
public makeFurienInvisible(ent) 
{
	if(gEnt != ent)
		return FMRES_IGNORED

	t_time += 0.1
	entity_set_float(ent, EV_FL_nextthink, t_time)

	new id

	for(new i = 1; i < MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i)|| !GetBit(isFurien, i) || !is_user_alive(i))
			continue

		id = i
		
		if(!GetBit(isWallHang, id))
		{
			if(GetBit(isWithAvaliableWeapons, id))
			{
				new Float:fVec[3], iSpeed
				entity_get_vector(id, EV_VEC_velocity, fVec)
				iSpeed = floatround(vector_length(fVec))
						
				if(iSpeed < 255)
				{
					set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, iSpeed) 
				}
				else 
				{
					set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				}
			} 
			else 
			{
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
			}
		}
		else
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, GetBit(isWithAvaliableWeapons, id) ? kRenderTransAlpha : kRenderNormal, 0)
	}

	return FMRES_IGNORED
}

public client_killed()
{
	new 
		killer = read_data(1),
		victim = read_data(2),
		headshot = read_data(3),
		weapon[32]

	read_data(4, weapon, sizeof(weapon))

	if(GetBit(haveSuperKnife, victim)) ClearBit(haveSuperKnife, victim)
	if(GetBit(haveSuperKnife2, victim)) ClearBit(haveSuperKnife2, victim)
	if(GetBit(haveSuperKnifeVIP, victim)) ClearBit(haveSuperKnifeVIP, victim)
	if(GetBit(haveSuperKnifeGOD, victim)) ClearBit(haveSuperKnifeGOD, victim)

	if(victim == killer)
		return PLUGIN_HANDLED

	new xpRecived = 0

	if(cs_get_user_team(killer) == TEAM_ANTIFURIEN)
	{
		xpRecived = XP_ANTIFURIEN

		if(headshot)
			xpRecived += GetBit(isVIP, killer) ? XP_HS_ANTIFURIEN_VIP : XP_HS_ANTIFURIEN
	}

	if(cs_get_user_team(killer) == TEAM_FURIEN)
	{
		xpRecived = XP_FURIEN

		if(headshot && get_user_weapon(killer) == CSW_KNIFE)
		{
			xpRecived += GetBit(isVIP, killer) ? XP_HS_FURIEN_VIP : XP_HS_FURIEN
			
			if(GetBit(isVIP, killer))
				giveVIPbonus(killer)
		} 

		if(equali(weapon, "grenade"))
		{
			xpRecived += GetBit(isVIP, killer) ? XP_FURIEN_GRENADE_VIP : XP_FURIEN_GRENADE
		}
	}

	new hsstring[20]

	if(headshot)
		formatex(hsstring, sizeof(hsstring), "^4[ HeadSot ]")

	else if(equali(weapon, "grenade"))
		formatex(hsstring, sizeof(hsstring), "^4[ He Grenade ]")
		
	else
		hsstring[0] = (EOS)

	client_print_color(killer, 0, "%s Ai primit ^4%d ^3XP%s", szPrefix, xpRecived, hsstring)

	giveXP(killer, xpRecived)

	AddBonusBox(victim)

	return PLUGIN_CONTINUE
}

public giveVIPbonus(id)
{
	set_user_health(id, get_user_health(id) + GetBit(isGOD, id) ? HS_FURIEN_HEALTH_GOD : HS_FURIEN_HEALTH_VIP)
	set_user_armor(id, get_user_armor(id) + GetBit(isGOD, id) ? HS_FURIEN_ARMOR_GOD : HS_FURIEN_ARMOR_VIP)
	cs_set_user_money(id, cs_get_user_money(id) + GetBit(isGOD, id) ? HS_FURIEN_MONEY_GOD : HS_FURIEN_MONEY_VIP)

	set_dhudmessage(31, 201, 31, 0.02, 0.90, 0, 6.0, 1.0)
	show_dhudmessage(id, "+%d HP +%d AP +%d$", GetBit(isGOD, id) ? HS_FURIEN_HEALTH_GOD : HS_FURIEN_HEALTH_VIP, GetBit(isGOD, id) ? HS_FURIEN_ARMOR_GOD : HS_FURIEN_ARMOR_VIP, GetBit(isGOD, id) ? HS_FURIEN_MONEY_GOD : HS_FURIEN_MONEY_VIP)
}

public giveXP(id, xp)
{
	pXP[id] += xp

	if(pLevel[id] != sizeof(Levels))
		while(pXP[id] > Levels[pLevel[id]])
		{
			pLevel[id] ++

			client_print_color(id, 0, "%s Felicitari ! Acum ai levelul ^4%d^3, cu ^4%d^3 XP.", szPrefix, pLevel[id], pXP[id])
		}
}

public setXP(id, xp)
{
	pXP[id] = xp

	while(pXP[id] > Levels[pLevel[id]])
	{
		pLevel[id] ++

		client_print_color(id, 0, "%s Felicitari ! Acum ai levelul ^4%d^3, cu ^4%d^3 XP.", szPrefix, pLevel[id], pXP[id])
	}

	while(pXP[id] < Levels[pLevel[id]])
	{
		pLevel[id] --

		// client_print_color(id, 0, "%s Felicitari ! Acum ai levelul ^4%d^3, cu ^4%d^3 XP.", szPrefix, pLevel[id], pXP[id])
	}
}

public EVENT_SwitchTeam() {
	new Players[32], PlayersNum, id
	get_players(Players, PlayersNum)

	if(PlayersNum) {
		for(new i; i < PlayersNum; i++) {
			id = Players[i]
			BeginDelay(id)
		}
	}
}

public EVENT_NewRound() {
	CanPlant = false;
	new Float:FloatTime = get_cvar_num("mp_freezetime") + (get_cvar_num("mp_roundtime") * 60) - 60.0
	set_task(FloatTime, "TASK_CanPlant")
	
	if(task_exists(5858))
		remove_task(5858)

	new ent = FM_NULLENT
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "BonusBox"))) 
		set_pev(ent, pev_flags, FL_KILLME)
	
	for(new id = 1; id < get_maxplayers();id++) {
		HasSpeed[id] = false
		HasTeleport[id] = false	
	}
}

public MSG_StatusIcon(msg_id, msg_dest, id) {
	static Attrib 
	Attrib = get_msg_arg_int(2)
	
	if(Attrib == (1<<1))
		set_msg_arg_int(2, ARG_BYTE, 0)
	
	new Icon[8];
	get_msg_arg_string(2, Icon, 7);
	static const BuyZone[] = "buyzone";
	
	if(equal(Icon, BuyZone)) {
		set_pdata_int(id, OFFSET_BZ, get_pdata_int(id, OFFSET_BZ, 5) & ~(1 << 0), 5);
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public MSG_TextMessage() {
	static TextMsg[22];
	get_msg_arg_string(2, TextMsg, charsmax(TextMsg))
	if(equal(TextMsg, "#Terrorists_Win")) {
		client_print(0, print_center, "The Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#CTs_Win")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Bomb_Defused")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Target_Bombed")) {
		client_print(0, print_center, "The Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Target_Saved")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Fire_in_the_hole"))
		return PLUGIN_HANDLED
	else if(equal(TextMsg, "#C4_Plant_At_Bomb_Spot")) {
		if(!CanPlant)
			return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE;
}

public MSG_SendAudio() {
	static Sound[17]
	get_msg_arg_string(2, Sound, sizeof Sound - 1)
	
	if(equal(Sound, "terwin") || equal(Sound, "ctwin") || equal(Sound, "rounddraw") || equal(Sound, "bombpl") || equal(Sound, "bombdef"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public GiveBonus(id)
{	
	if(cs_get_user_team(id) == CS_TEAM_T) 
	{
		switch (random_num(1,7)) 
		{
			case 1: 
			{
				new Health = 25
				fm_set_user_health(id, get_user_health(id) + Health)
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 viata^4.")
			}
			case 2:
			{
				if(!user_has_weapon(id, CSW_HEGRENADE)) {
					fm_give_item(id, "weapon_hegrenade")
				}
				else {
					cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada HE^4.")
			}
			case 3:
			{
				if(!user_has_weapon(id, CSW_FLASHBANG)) {
					fm_give_item(id, "weapon_flashbang")
				}
				else {
					cs_set_user_bpammo(id, CSW_FLASHBANG, cs_get_user_bpammo(id, CSW_FLASHBANG) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada FB^4.")
			}
			case 4:
			{
				if(!user_has_weapon(id, CSW_SMOKEGRENADE)) {
					fm_give_item(id, "weapon_smokegrenade")
				}
				else {
					cs_set_user_bpammo(id, CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada SG^4.")
			}
			case 5:
			{
				HasSpeed[id] = true;
				// client_cmd(id, "cl_sidespeed %d",get_pcvar_float(CvarFurienSpeed))
				// client_cmd(id, "cl_forwardspeed %d",get_pcvar_float(CvarFurienSpeed))
				// client_cmd(id, "cl_backspeed %d",get_pcvar_float(CvarFurienSpeed))
				// set_user_maxspeed(id, get_pcvar_float(CvarFurienSpeed));
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 viteza^4.")
				
			}
			// case 6:
			// {
			// 	if(!is_user_admin(id)) {
			// 	HasTeleport[id] = true;
			// 	client_cmd(id, "bind alt power2");
			// 	client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 puterea de a te putea teleporta.^4.")
			// 	}
			// 	else GiveBonus(id)
			// }	
			case 7:
			{
				new Money = 3000
				cs_set_user_money(id, cs_get_user_money(id) + Money)
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 $^4.")
			}
		}
	}
	else
	{
		switch (random_num(1,6)) 
		{
			
			case 1: 
			{
				new Health = 50
				fm_set_user_health(id, get_user_health(id) + Health)
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 viata^4.")
			}
			case 2:
			{
				if(!user_has_weapon(id, CSW_HEGRENADE)) {
					fm_give_item(id, "weapon_hegrenade")
				}
				else {
					cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada HE^4.")
			}
			case 3:
			{
				if(!user_has_weapon(id, CSW_FLASHBANG)) {
					fm_give_item(id, "weapon_flashbang")
				}
				else {
					cs_set_user_bpammo(id, CSW_FLASHBANG, cs_get_user_bpammo(id, CSW_FLASHBANG) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada FB^4.")
			}
			case 4:
			{
				if(!user_has_weapon(id, CSW_SMOKEGRENADE)) {
					fm_give_item(id, "weapon_smokegrenade")
				}
				else {
					cs_set_user_bpammo(id, CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1);
				}
				client_print_color(id, 0, "^3[Furien]^4 Ai primit o^3 grenada SG^4.")
			}
			case 5:
			{
				HasSpeed[id] = true;
				// client_cmd(id, "cl_sidespeed %d",get_pcvar_float(CvarAntiFurienSpeed))
				// client_cmd(id, "cl_forwardspeed %d",get_pcvar_float(CvarAntiFurienSpeed))
				// client_cmd(id, "cl_backspeed %d",get_pcvar_float(CvarAntiFurienSpeed))
				// set_user_maxspeed(id, get_pcvar_float(CvarAntiFurienSpeed));
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 viteza^4.")
				
			}
			case 6:
			{
				new Money = 3000
				cs_set_user_money(id, cs_get_user_money(id) + Money)
				client_print_color(id, 0, "^3[Furien]^4 Ai primit^3 $^4.")
			}
		}
		
	}
	
}

public AddBonusBox(id)
{
	if(is_user_connected(id) && cs_get_user_team(id) != CS_TEAM_SPECTATOR) {
		new ent = fm_create_entity("info_target")
		new origin[3]
		get_user_origin(id, origin, 0)
		set_pev(ent,pev_classname, "BonusBox")
		switch(cs_get_user_team(id))
		{
			case CS_TEAM_T: { 
				engfunc(EngFunc_SetModel,ent, Model[1])
				set_pev(ent,pev_team, 2)
			}
			
			case CS_TEAM_CT: {
				engfunc(EngFunc_SetModel,ent, Model[0])	
				set_pev(ent,pev_team, 1)
			}
		}
		set_pev(ent,pev_mins,Float:{-10.0,-10.0,0.0})
		set_pev(ent,pev_maxs,Float:{10.0,10.0,25.0})
		set_pev(ent,pev_size,Float:{-10.0,-10.0,0.0,10.0,10.0,25.0})
		engfunc(EngFunc_SetSize,ent,Float:{-10.0,-10.0,0.0},Float:{10.0,10.0,25.0})
		
		set_pev(ent,pev_solid,SOLID_BBOX)
		set_pev(ent,pev_movetype,MOVETYPE_TOSS)
		
		new Float:fOrigin[3]
		IVecFVec(origin, fOrigin)
		set_pev(ent, pev_origin, fOrigin)
	}
}

public setUserAbilitesClass(id, class)
{
	if(!is_user_connected(id) && !is_user_alive(id))
		return PLUGIN_HANDLED

	set_user_health(id, serverClass[class][health])
	cs_set_user_armor(id, serverClass[class][armor], CS_ARMOR_VESTHELM)
	set_user_gravity(id, serverClass[class][gravity])

	return PLUGIN_CONTINUE
}

public giveUserWeaponsClass(id, class)
{
	if(!is_user_connected(id) && !is_user_alive(id))
		return PLUGIN_HANDLED

	if(GetBit(isFurien, id))
		return PLUGIN_HANDLED

	give_item(id, serverClass[class][v_weapon])
	give_item(id, serverClass[class][p_weapon])

	return PLUGIN_CONTINUE
}

public change_weapon_model(id, weaponid)
{
	static class 

	if(GetBit(isFurien, id) && weaponid != CSW_KNIFE)
		ClearBit(isWithAvaliableWeapons, id) // for invisibilty

	switch(weaponid)
	{
		case CSW_KNIFE:
		{
			
			if(!GetBit(isFurien, id))
			{
				
				set_pev(id, pev_viewmodel2, customModels[MODEL_KNIFE_AF][v_wpn])
				if(strlen(customModels[MODEL_KNIFE_AF][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_KNIFE_AF][p_wpn])
				
				return PLUGIN_HANDLED
			}

			SetBit(isWithAvaliableWeapons, id)

			if(GetBit(haveSuperKnife, id))
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_KNIFE_SHOP][v_wpn])
				if(strlen(customModels[MODEL_KNIFE_SHOP][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_KNIFE_SHOP][p_wpn])

				return PLUGIN_HANDLED
			}

			if(GetBit(haveSuperKnife2, id))
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_KNIFE_SHOP2][v_wpn])
				if(strlen(customModels[MODEL_KNIFE_SHOP2][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_KNIFE_SHOP2][p_wpn])

				return PLUGIN_HANDLED
			}

			if(GetBit(haveSuperKnifeVIP, id))
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_KNIFE_VIP][v_wpn])
				if(strlen(customModels[MODEL_KNIFE_VIP][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_KNIFE_VIP][p_wpn])

				return PLUGIN_HANDLED
			}

			if(GetBit(haveSuperKnifeGOD, id))
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_KNIFE_GOD][v_wpn])
				if(strlen(customModels[MODEL_KNIFE_GOD][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_KNIFE_GOD][p_wpn])

				return PLUGIN_HANDLED
			}

			class = pClass[id]

			if(strfind(serverClass[class][v_weapon], "weapon_") != -1)
				return PLUGIN_HANDLED

			if(strfind(serverClass[class][p_weapon], "weapon_") != -1)
				return PLUGIN_HANDLED

			set_pev(id, pev_viewmodel2, serverClass[class][v_weapon])
			if(strlen(serverClass[class][p_weapon]) > 2)
				set_pev(id, pev_weaponmodel2, serverClass[class][p_weapon])
		}

		case CSW_USP: 
		{
			set_pev(id, pev_viewmodel2, customModels[MODEL_USP][v_wpn])
			if(strlen(customModels[MODEL_USP][p_wpn]) > 2)
				set_pev(id, pev_weaponmodel2, customModels[MODEL_USP][p_wpn])
		}

		case CSW_HEGRENADE:
		{
			set_pev(id, pev_viewmodel2, customModels[MODEL_HEGRENADE][v_wpn])
			if(strlen(customModels[MODEL_HEGRENADE][p_wpn]) > 2)
				set_pev(id, pev_weaponmodel2, customModels[MODEL_HEGRENADE][p_wpn])
		}
		case CSW_SMOKEGRENADE:
		{
			set_pev(id, pev_viewmodel2, customModels[MODEL_SMOKE][v_wpn])
			if(strlen(customModels[MODEL_SMOKE][p_wpn]) > 2)
				set_pev(id, pev_weaponmodel2, customModels[MODEL_SMOKE][p_wpn])
		}
		case CSW_FLASHBANG:
		{
			set_pev(id, pev_viewmodel2, customModels[MODEL_FLASH][v_wpn])
			if(strlen(customModels[MODEL_FLASH][p_wpn]) > 2)
				set_pev(id, pev_weaponmodel2, customModels[MODEL_FLASH][p_wpn])
		}
		case CSW_MP5NAVY:
		{
			if(GetBit(dualmp5, id))
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_DUALMP5][v_wpn])
				
				if(strlen(customModels[MODEL_DUALMP5][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_DUALMP5][p_wpn])
			}
		}

		case CSW_P90:
		{
			client_print_color(id, 0, "test")
			if(pClass[id] == deklowaz)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_DUALKRISS][v_wpn])
				
				if(strlen(customModels[MODEL_DUALKRISS][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_DUALKRISS][p_wpn])
			}

			if(pClass[id] == warlock)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_THOMPSON][v_wpn])
				
				if(strlen(customModels[MODEL_THOMPSON][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_THOMPSON][p_wpn])
			}

			if(pClass[id] == hunter)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_F2000][v_wpn])
				
				if(strlen(customModels[MODEL_F2000][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_F2000][p_wpn])
			}
		}

		case CSW_SG552:
		{
			if(pClass[id] == shaman)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_TAR21][v_wpn])
				
				if(strlen(customModels[MODEL_TAR21][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_TAR21][p_wpn])
			}
		}

		case CSW_FAMAS:
		{
			if(pClass[id] == rogue)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_SVDEX][v_wpn])
				
				if(strlen(customModels[MODEL_SVDEX][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_SVDEX][p_wpn])
			}
		}

		case CSW_GALIL:
		{
			if(pClass[id] == mage)
			{
				set_pev(id, pev_viewmodel2, customModels[MODEL_FNC][v_wpn])
				
				if(strlen(customModels[MODEL_FNC][p_wpn]) > 2)
					set_pev(id, pev_weaponmodel2, customModels[MODEL_FNC][p_wpn])
			}
		}
	}

	return PLUGIN_CONTINUE
}

#if defined HUD_SYSTEM
	public showHud(id)
	{
		if (!is_user_alive(id))
		{
			static idspec
			idspec = pev(id, pev_iuser2)
			
			if(is_user_alive(idspec)) 
				showLevelInfo(id, idspec)
		} 
		else 
			showLevelInfo(id, id)
	}

	public showLevelInfo(id, specid)
	{
		set_dhudmessage(255, 255, 0, -1.0, 0.80, 0, 6.0, 1.1)
		show_dhudmessage(id, "Viata: %d | Armura: %d | Level: %d/%d | XP: %d | Clasa: %s", get_user_health(specid), get_user_armor(specid), pLevel[specid], sizeof(Levels), pXP[specid], serverClass[pClass[specid]][name])
	}
#endif

public bomb_planted(planter) {
	C4_CountDownDelay = get_cvar_num("mp_c4timer") - 1
	TASK_C4_CountDown();
	set_hudmessage(random(255), random(255), random(255), -1.0, -1.0, 1, 3.1, 3.0)
	show_hudmessage(0, "Furienii au plantat bomba!")
}

public BeginDelay(id) {
	if(is_user_connected(id)) {
		switch(id) {
			case 1..7: set_task(0.1, "BeginTeamSwap", id)
			case 8..15: set_task(0.2, "BeginTeamSwap", id)
			case 16..23: set_task(0.3, "BeginTeamSwap", id)
			case 24..32: set_task(0.4, "BeginTeamSwap", id)
		}
	}
}

public BeginTeamSwap(id) {
	if(is_user_connected(id)) {
		switch(get_user_team(id)) {
			case TEAM_FURIEN: cs_set_user_team(id, CS_TEAM_CT)
			case TEAM_ANTIFURIEN: cs_set_user_team(id, CS_TEAM_T)
		}
	}
}	

public TASK_CanPlant() {
	CanPlant = true;
	set_hudmessage(random(255), random(255), random(255), -1.0, -1.0, 1, 3.1, 3.0)
	show_hudmessage(0, "Furienii pot planta bomba!")
}

public TASK_C4_CountDown() {
	new Red, Green, Blue
	if(C4_CountDownDelay > 10)
		Red = 0, Green = 255, Blue = 0;
	else if(C4_CountDownDelay > 5)
		Red = 255, Green = 200, Blue = 0;
	else if(C4_CountDownDelay <= 5)
		Red = 255, Green = 0, Blue = 0;
	
	if(C4_CountDownDelay) {
		new Message[256];
		formatex(Message,sizeof(Message)-1,"----------^n| C4: %d |^n----------", C4_CountDownDelay);

		set_hudmessage(Red, Green, Blue, -1.0, 0.78, 0, 6.0, 1.0)
		show_hudmessage(0, "%s", Message)
		set_task(1.0, "TASK_C4_CountDown", 5858);
		C4_CountDownDelay--;
	}
	else if(!C4_CountDownDelay)
		C4_CountDownDelay = 0;
}

public useParachute(id)
{
	new Float:velocity[3]
	entity_get_vector(id, EV_VEC_velocity, velocity)
	if (velocity[2] < 0.0) 
	{
		entity_set_int(id, EV_INT_sequence, 3)
		entity_set_int(id, EV_INT_gaitsequence, 1)
		entity_set_float(id, EV_FL_frame, 1.0)
		entity_set_float(id, EV_FL_framerate, 1.0)

		velocity[2] = (velocity[2] + 40.0 < (100.0 * -1.0)) ? velocity[2] + 40.0 : (100.0 * -1.0)
		entity_set_vector(id, EV_VEC_velocity, velocity)
	}
}

public teleportPower(id)
{
	powerCooldown[id] = get_gametime() + 30.0

	// https://forums.alliedmods.net/showpost.php?p=2427517&postcount=5
	new Float:playerOrigin[3], Float:playerViewOffset[3]
	pev(id, pev_origin, playerOrigin)
	pev(id, pev_view_ofs, playerViewOffset)
	xs_vec_add(playerOrigin, playerViewOffset, playerOrigin)
	
	new Float:playerViewAngle[3]
	pev(id, pev_v_angle, playerViewAngle)
	engfunc(EngFunc_MakeVectors, playerViewAngle)
	global_get(glb_v_forward, playerViewAngle)
	
	xs_vec_mul_scalar(playerViewAngle, 9999.0, playerViewAngle)
	xs_vec_add(playerOrigin, playerViewAngle, playerViewAngle)

	new handleTraceLine, Float:traceLineEndPos[3], Float:traceFraction
	engfunc(EngFunc_TraceLine, playerOrigin, playerViewAngle, DONT_IGNORE_MONSTERS, id, handleTraceLine)
	get_tr2(0, TR_vecEndPos, traceLineEndPos)
	
	new startDistance = 5
	if(validSpotFound(id, traceLineEndPos)) 
	{
		set_pev(id, pev_origin, traceLineEndPos)
	}
	else
	{
		new restrictMaxSearches = 150, i, Float:foundOrigin[3]
		while(--restrictMaxSearches > 0)
		{
			for(i = 0; i < 3; i++)
			{
				foundOrigin[i] = random_float(traceLineEndPos[i] - startDistance , traceLineEndPos[i] + startDistance)
			}
			
			engfunc(EngFunc_TraceLine, playerOrigin, foundOrigin, DONT_IGNORE_MONSTERS, id, handleTraceLine)
			get_tr2(handleTraceLine, TR_flFraction, traceFraction)
			free_tr2(handleTraceLine)
			
			if(traceFraction == 1.0)
			{
				if(validSpotFound(id, foundOrigin))
				{
					set_pev(id, pev_origin, foundOrigin)
					break
				}
			} 
			
			startDistance = startDistance + 1
		}
	}
}

public bool:validSpotFound(id, Float:Origin[3])
{
	new handleTraceHull 
	engfunc(EngFunc_TraceHull, Origin, Origin, DONT_IGNORE_MONSTERS, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id, handleTraceHull)    
	if(get_tr2(handleTraceHull, TR_InOpen) && !(get_tr2(handleTraceHull, TR_StartSolid) || get_tr2(handleTraceHull, TR_AllSolid))) 
	{
		return true
	}    
	
	return false
}

public freezePower(id)
{
	powerCooldown[id] = get_gametime() + 30.0

	static target

	get_user_aiming(id, target, _, 5000)

	if(is_user_alive(target) && GetBit(isFurien, id) != GetBit(isFurien, target))
	{
		freezePlayer(target)
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000)
		write_byte(0)
		write_byte(100)
		write_byte(200)
		write_byte(50)
		message_end()

		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, target)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000)
		write_byte(0)
		write_byte(100)
		write_byte(200)
		write_byte(50)
		message_end()
	}

	static 
		Float:start[3],
		Float:aim[3]

	pev(id, pev_origin, start)
	fm_get_aim_origin(id, aim)

	start[2] += 16.0 // raise
	aim[2] += 16.0 // raise

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(0);
	engfunc(EngFunc_WriteCoord,start[0]);
	engfunc(EngFunc_WriteCoord,start[1]);
	engfunc(EngFunc_WriteCoord,start[2]);
	engfunc(EngFunc_WriteCoord,aim[0]);
	engfunc(EngFunc_WriteCoord,aim[1]);
	engfunc(EngFunc_WriteCoord,aim[2]);
	write_short(spriteFreeze); // sprite index
	write_byte(0); // start frame
	write_byte(30); // frame rate in 0.1's
	write_byte(20); // life in 0.1's
	write_byte(50); // line width in 0.1's
	write_byte(50); // noise amplititude in 0.01's
	write_byte(0); // red
	write_byte(100); // green
	write_byte(200); // blue
	write_byte(100); // brightness
	write_byte(50); // scroll speed in 0.1's
	message_end();

	set_user_health ( target, get_user_health ( target ) - 5 )
	set_dhudmessage ( 255, 0, 0, 0.02, 0.90, 0, 6.0, 1.0 )
	show_dhudmessage ( id, "-5 HP" )

	return PLUGIN_CONTINUE
}

public freezePlayer(id)
{
	if (!is_user_alive(id) || GetBit(isFrozen, id)) return;

	SetBit(isFrozen, id)
	
	// pev(id, pev_maxspeed, TempSpeed[id]); //get temp speed
	// pev(id, pev_gravity, TempGravity[id]); //get temp speed
	fm_set_rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25);
	// engfunc(EngFunc_EmitSound, id, CHAN_BODY, FROSTPLAYER_SND[random_num(0, sizeof FROSTPLAYER_SND - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12)*1);
	write_short(floatround((1<<12)*3.0));
	write_short(0x0000);
	write_byte(0);
	write_byte(50);
	write_byte(200);
	write_byte(100);
	message_end();

	if (pev(id, pev_flags) & FL_ONGROUND)
		set_pev(id, pev_gravity, 999999.9);
	else
		set_pev(id, pev_gravity, 0.000001);
	
	set_task(3.0, "remove_freeze", id);
}

public remove_freeze(id)
{
	if(!GetBit(isFrozen, id) || !is_user_alive(id)) return;
	
	ClearBit(isFrozen, id)

	// engfunc(EngFunc_EmitSound, id, CHAN_BODY, FROSTBREAK_SND[random_num(0, sizeof FROSTBREAK_SND - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	fm_set_rendering(id);
	static Float:origin2F[3];
	pev(id, pev_origin, origin2F);
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin2F, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, origin2F[0]);
	engfunc(EngFunc_WriteCoord, origin2F[1]);
	engfunc(EngFunc_WriteCoord, origin2F[2]+24.0);
	write_coord(16);
	write_coord(16);
	write_coord(16);
	write_coord(random_num(-50, 50));
	write_coord(random_num(-50, 50));
	write_coord(25);
	write_byte(10);
	write_short(spriteFreeze);
	write_byte(10);
	write_byte(25);
	write_byte(0x01);
	message_end();
}

public dropPower(id)
{

}

public dragPower(id)
{

}

public recoilPower(id)
{

}