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

	isBot,
	isFurien,
	haveSuperKnife,
	haveSuperKnife2

// altele
new 
	bool:CanPlant, 
	C4_CountDownDelay,
	szPrefix [ ] = "^4[Furien XP Mod]^3 -",
	furienHealth,
	afurienHealth,
	nVaultSave

new const shop_furienHealth[] = "exhealth/zm_buyhealth.wav" 
new const shop_afurienHealth[] = "exhealth/hm_buyhealth.wav" 

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
	Float:knifeDmg
}

new serverClass[][serverClassE] = {
	{"Trainer", 1, "models/furien/knifes/v_combatknife.mdl", "models/furien/knifes/p_combatknife.mdl", 900.0, 0.7, 100, 0, TEAM_FURIEN, 1.0},
	{"Agnos", 5, "models/furien/knifes/v_infinity_knife1.mdl", "models/furien/knifes/p_infinity_knife1.mdl", 930.0, 0.6, 120, 60, TEAM_FURIEN, 1.5},
	{"XFother", 9, "models/furien/knifes/v_natad.mdl", "models/furien/knifes/p_natad.mdl", 1000.0, 0.6, 120, 60, TEAM_FURIEN, 2.0},	
	{"Samurai", 13, "models/furien/knifes/v_katana.mdl", "models/furien/knifes/p_katana.mdl", 500.0, 0.6, 135, 90, TEAM_FURIEN, 2.8},
	{"Extra Samurai", 17, "models/furien/knifes/v_double_katana.mdl", "models/furien/knifes/p_double_katana.mdl", 1050.0, 0.5, 145, 105, TEAM_FURIEN, 3.3},
	{"Ignes", 21, "models/furien/knifes/v_ignes.mdl", "", 1100.0, 0.5, 185, 150, TEAM_FURIEN, 4.0},
	{"Elf", 25, "models/furien/knifes/v_elf.mdl", "", 1150.0, 0.4, 185, 160, TEAM_FURIEN, 4.5},
	{"Alcadeias", 29, "models/furien/knifes/v_vipaxe.mdl", "models/furien/knifes/p_vipaxe.mdl", 1200.0, 0.4, 185, 160, TEAM_FURIEN, 5.3},

	{"Druid", 1, "weapon_xm1014", "weapon_usp", 320.0, 1.0, 105, 30, TEAM_ANTIFURIEN},
	{"Hunter", 5, "weapon_p90", "weapon_usp", 320.0, 1.0, 120, 60, TEAM_ANTIFURIEN},
	{"Mage", 9, "weapon_galil", "weapon_usp", 320.0, 0.7, 120, 60, TEAM_ANTIFURIEN},
	{"Rogue", 13, "weapon_famas", "weapon_usp", 320.0, 0.7, 120, 80, TEAM_ANTIFURIEN},
	{"Shaman", 17, "weapon_sg552", "weapon_usp", 320.0, 0.7, 145, 90, TEAM_ANTIFURIEN},
	{"Warlock", 21, "weapon_p90", "weapon_usp", 320.0, 0.6, 165, 105, TEAM_ANTIFURIEN},
	{"Warrior", 25, "weapon_p90", "weapon_usp", 320.0, 0.6, 180, 115, TEAM_ANTIFURIEN},
	{"Deklowaz", 29, "weapon_p90", "weapon_usp", 320.0, 0.6, 200, 130, TEAM_ANTIFURIEN},
}

enum
{
	MODEL_USP,
	MODEL_KNIFE_SHOP,
	MODEL_KNIFE_SHOP2,
	MODEL_HEGRENADE,
	MODEL_SMOKE,
	MODEL_FLASH
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

}

enum shopEnum 
{
	superKnife,
	defuseKit,
	heGrenade,
	priceHP,
	priceAP
}

new priceShop[shopEnum] = {
	8000, // super knife
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

	register_concmd("amx_givexp", "giveXPCmd", ADMIN_IMMUNITY, "<target / all> <amount>")
	register_concmd("amx_setxp", "setXPCmd", ADMIN_IMMUNITY, "<target / all> <amount>")

	for(i = 0; i < sizeof(weaponsList); i++)
		RegisterHam(Ham_Item_Deploy, weaponsList[i], "changeModel", 1)

	RegisterHam(Ham_Spawn, "player", "client_spawned")
	RegisterHam(Ham_Touch, "weaponbox", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "HAM_Touch_Weapon")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "C4_PrimaryAttack") 
	RegisterHam(Ham_TakeDamage, "player", "client_takeDamage")

	register_forward(FM_PlayerPreThink, "Player_PreThink")
	register_forward(FM_AddToFullPack, "FWD_AddToFullPack", 1)

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

public client_putinserver(id)
{
	if(is_user_bot(id))
		SetBit(isBot, id)

	set_task(1.0, "showHud", id, _, _, "b")
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
}

public client_disconnected(id)
{
	if(task_exists(id))
		remove_task(id)

	new 
		vaultkey[64],
		vaultdata[256]

	format(vaultkey, sizeof(vaultkey), "%s", pName[id])
	format(vaultdata, sizeof(vaultdata), "%d#%d#%d#%d", pLevel[id], pXP[id], pFurienClass[id], pAFurienClass[id])

	nvault_set(nVaultSave, vaultkey, vaultdata)
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
		formatex(string, sizeof(string), "\ySuper Knife \y[ \r%d $\y ]", priceShop[superKnife])
		menu_additem(menu, string)
	}
	else
	{
		formatex(string, sizeof(string), "\yDefuse Kit \y[ \r%d $\y ]", priceShop[defuseKit])
		menu_additem(menu, string)
	}

	formatex(string, sizeof(string), "\yHE Grenade \y[ \r%d $\y ]", priceShop[heGrenade])
	menu_additem(menu, string)

	formatex(string, sizeof(string), "\r+\y50 HP \y[ \r%d $\y ]", priceShop[priceHP])
	menu_additem(menu, string)

	formatex(string, sizeof(string), "\r+\y50 AP\r + \yHelmet \y[ \r%d $\y ]", priceShop[priceAP])
	menu_additem(menu, string)

	menu_display(id, menu)
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

		client_print_color(id, 0, "%s [DEBUG] Clasa ta este acum^4 %s^3 .", szPrefix, serverClass[class][name])
	#else
		client_print_color(id, 0, "%s Urmatoarea ta clasa va fii^4 %s^3 .", szPrefix, serverClass[class][name])
	#endif

	return PLUGIN_CONTINUE
}

public handlerShopMenu(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED

	new price = 0

	switch(item)
	{
		case 0:
		{
			if(GetBit(isFurien, id))
			{
				SetBit(haveSuperKnife, id)

				price = priceShop[superKnife]
			}
			else 
			{
				give_item(id, "item_thighpack")

				price = priceShop[defuseKit]
			}
		}
		case 1: give_item(id, "weapon_hegrenade"), price = priceShop[heGrenade]
		case 2:
		{
			price = priceShop[priceHP]

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
		case 3:
		{
			price = priceShop[priceAP]

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

	set_task(0.2, "resetweapons", id)
}

public resetweapons(id)
{
	for(new i = 0; i < 2; i++)
		strip_user_weapons(id)

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
	
		if(get_user_flags(id) & ADMIN_LEVEL_H) 
			cs_set_user_model(id, "WhiteMask")
		else
			cs_set_user_model(id, "antifurien2012")
	}
	give_item(id, "weapon_knife")
	give_item(id, "weapon_hegrenade")

	setUserAbilitesClass(id, pClass[id])
	giveUserWeaponsClass(id, pClass[id])

	showClassMenu(id)
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

	if(!GetBit(isFurien, attacker))
		return HAM_IGNORED

	if(GetBit(haveSuperKnife2, attacker))
		SetHamParamFloat(4, damage * 10.0)
	else if(GetBit(haveSuperKnife, attacker))
		SetHamParamFloat(4, damage * 6.0)
	else 
		SetHamParamFloat(4, damage * serverClass[pClass[attacker]][knifeDmg])


	return HAM_HANDLED
}

public Player_PreThink(id) 
{
	if(is_user_connected(id) && GetBit(isFurien, id)) 
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

public FWD_AddToFullPack(es, e, ent, host, host_flags, player, p_set) {
	if(is_user_connected(ent) && is_user_connected(host) && is_user_alive(ent)) {
		if(is_user_alive(host) && GetBit(isFurien, ent) && GetBit(isFurien, host) 
		|| !is_user_alive(host) && GetBit(isFurien, ent) && pev(host, pev_iuser2) == ent
		|| GetBit(isFurien, ent) && pev(ent, pev_maxspeed) <= 1.0) {
			set_es(es, ES_RenderFx, kRenderFxNone)
			set_es(es, ES_RenderMode, kRenderTransTexture)
			set_es(es, ES_RenderAmt, 255)
		}
		else if(GetBit(isFurien, ent)) {
			set_es(es, ES_RenderFx, kRenderFxNone)
			set_es(es, ES_RenderMode, kRenderTransTexture)
			static Float:Origin[3]
			pev(ent, pev_origin, Origin)
			
			if(get_user_weapon(ent) == CSW_KNIFE && fm_get_speed(ent) <= 5 || get_user_weapon(ent) == CSW_KNIFE && Origin[0] == Wallorigin[ent][0] && Origin[1] == Wallorigin[ent][1] && Origin[2] == Wallorigin[ent][2])
				set_es(es, ES_RenderAmt, 0)
			else
				set_es(es, ES_RenderAmt, 255)
		}
	}
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

	if(victim == killer)
		return PLUGIN_HANDLED

	new xpRecived = 0

	if(cs_get_user_team(killer) == TEAM_ANTIFURIEN)
	{
		xpRecived = XP_ANTIFURIEN

		if(headshot)
			xpRecived += get_user_flags(killer) & ADMIN_LEVEL_H ? XP_HS_ANTIFURIEN_VIP : XP_HS_ANTIFURIEN
	}

	if(cs_get_user_team(killer) == TEAM_FURIEN)
	{
		xpRecived = XP_FURIEN

		if(headshot && get_user_weapon(killer) == CSW_KNIFE)
		{
			xpRecived += get_user_flags(killer) & ADMIN_LEVEL_H ? XP_HS_FURIEN_VIP : XP_HS_FURIEN
			giveUserHealth(killer, get_user_flags(killer) & ADMIN_LEVEL_H ? HS_FURIEN_HEALTH_VIP : HS_FURIEN_HEALTH)
		} 

		if(equali(weapon, "grenade"))
		{
			xpRecived += get_user_flags(killer) & ADMIN_LEVEL_H ? XP_FURIEN_GRENADE_VIP : XP_FURIEN_GRENADE
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

	message_begin ( MSG_ONE_UNRELIABLE , get_user_msgid ( "ScreenFade" ) , {0,0,0} , victim );
	write_short ( (6<<10) ); // duration
	write_short ( (5<<10) ); // hold time
	write_short ( (1<<12) ); // fade type
	write_byte ( cs_get_user_team(victim) == TEAM_FURIEN ? 0 : 255 );
	write_byte ( 0 );
	write_byte ( cs_get_user_team(victim) == TEAM_FURIEN ? 255 : 0 );
	write_byte ( 170 );
	message_end ( );

	return PLUGIN_CONTINUE
}

public giveUserHealth(id, hp)
{
	set_user_health(id, get_user_health(id) + hp)

	set_dhudmessage(31, 201, 31, 0.02, 0.90, 0, 6.0, 1.0)
	show_dhudmessage(id, "+%d HP", hp)
}

public giveXP(id, xp)
{
	pXP[id] += xp

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

	switch(weaponid)
	{
		case CSW_KNIFE:
		{
			if(!GetBit(isFurien, id))
				return PLUGIN_HANDLED

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
	}

	return PLUGIN_CONTINUE
}

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