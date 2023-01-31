#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>

#include <settings>

#define PLUGIN "Furien CSO"
#define VERSION "1.0"
#define AUTHOR "Filiq_"

// players
new 
	bool:MakeVisible[MAX_PLAYERS + 1], 
	Float:Wallorigin[MAX_PLAYERS + 1][3]

// cvars
new 
	cvar_autojoin_class, 
	cvar_autojoin_team

// altele
new 
	bool:CanPlant, 
	C4_CountDownDelay

public plugin_natives()
{

}

public plugin_precache()
{
	remove_entity_name("info_map_parameters")
	remove_entity_name("func_buyzone")
	
	new Entity = create_entity("info_map_parameters")
	
	DispatchKeyValue(Entity, "buying", "3")
	DispatchSpawn(Entity)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	cvar_autojoin_team = register_cvar("cso_autojoin", "5")
	cvar_autojoin_class = register_cvar("furien_class", "5")

	static blockcmds[][] = {
		"jointeam", "jointeam 1", "jointeam 2", "jointeam 3", "chooseteam",
		"radio1", "radio2", "radio3"
	}

	for(new i = 0; i < sizeof(blockcmds); i++)
		register_clcmd(blockcmds[i], "blockCmds")

	RegisterHam(Ham_Spawn, "player", "Ham_Spawn_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "HAM_Touch_Weapon")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "C4_PrimaryAttack") 

	register_forward(FM_PlayerPreThink, "Player_PreThink")
	register_forward(FM_AddToFullPack, "FWD_AddToFullPack", 1)	

	register_event("SendAudio", "EVENT_SwitchTeam", "a", "1=0", "2=%!MRAD_ctwin")
	register_event("HLTV", "EVENT_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "blockCmds", "b", "2&#Game_radio", "4&#Fire_in_the_hole")
	register_event("TextMsg", "blockCmds", "b", "3&#Game_radio", "5&#Fire_in_the_hole")	

	register_message(get_user_msgid("StatusIcon"), "MSG_StatusIcon")
	register_message(get_user_msgid("TextMsg"), "MSG_TextMessage")
	register_message(get_user_msgid("ShowMenu"), "MSG_ShowMenu")
	register_message(get_user_msgid("VGUIMenu"), "MSG_VGUIMenu")
	register_message(get_user_msgid("SendAudio"), "MSG_SendAudio")
}

public blockCmds() {
	return PLUGIN_HANDLED
}

public Ham_Spawn_Post(id) {
	if(is_user_connected(id) && is_user_alive(id))
		set_user_footsteps(id, cs_get_user_team(id) == TEAM_ANTIFURIEN ? 0 : 1)
}

public HAM_Touch_Weapon(ent, id) {
	if(is_user_alive(id) && cs_get_user_team(id) == TEAM_FURIEN && !(get_pdata_cbase(ent, 39, 4) > 0))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public C4_PrimaryAttack(Ent) {
	if(!CanPlant) 
		return HAM_SUPERCEDE
		
	return HAM_IGNORED
}

public Player_PreThink(id) {
	if(is_user_connected(id)) {
		if(cs_get_user_team(id) == TEAM_FURIEN) {
			// if(pev(id, pev_gravity) > FURIEN_GRAVITY && pev(id, pev_gravity) > 0.1)
			// 	set_pev(id, pev_gravity, FURIEN_GRAVITY)
		
			// if(pev(id, pev_maxspeed) < FURIEN_SPEED && pev(id, pev_maxspeed) > 1.0) {
			// 	set_pev(id, pev_maxspeed, FURIEN_SPEED)
			// 	set_user_footsteps(id, 1)
			// }
		}
	}
}

public FWD_AddToFullPack(es, e, ent, host, host_flags, player, p_set) {
	if(is_user_connected(ent) && is_user_connected(host) && is_user_alive(ent)) {
		if(is_user_alive(host) && cs_get_user_team(ent) == TEAM_FURIEN && cs_get_user_team(host) == TEAM_FURIEN 
		|| !is_user_alive(host) && cs_get_user_team(ent) == TEAM_FURIEN && pev(host, pev_iuser2) == ent
		|| cs_get_user_team(ent) == TEAM_FURIEN && pev(ent, pev_maxspeed) <= 1.0) {
			set_es(es, ES_RenderFx, kRenderFxNone)
			set_es(es, ES_RenderMode, kRenderTransTexture)
			set_es(es, ES_RenderAmt, 255)
		}
		else if(cs_get_user_team(ent) == TEAM_FURIEN) {
			set_es(es, ES_RenderFx, kRenderFxNone)
			set_es(es, ES_RenderMode, kRenderTransTexture)
			static Float:Origin[3]
			pev(ent, pev_origin, Origin)
			
			if(get_user_weapon(ent) == CSW_KNIFE && !MakeVisible[ent] && fm_get_speed(ent) <= 5 || get_user_weapon(ent) == CSW_KNIFE && !MakeVisible[ent] && Origin[0] == Wallorigin[ent][0] && Origin[1] == Wallorigin[ent][1] && Origin[2] == Wallorigin[ent][2])
				set_es(es, ES_RenderAmt, 0)
			else
				set_es(es, ES_RenderAmt, 255)
		}
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

public MSG_ShowMenu(msgid, dest, id) {
	if(!Should_AutoJoin(id))
		return PLUGIN_CONTINUE
	
	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if(!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE
	
	JoinTeam_Task(id, msgid)
	
	return PLUGIN_HANDLED
}

public MSG_VGUIMenu(msgid, dest, id) {
	if(get_msg_arg_int(1) != 2 || !Should_AutoJoin(id))
		return PLUGIN_CONTINUE
	
	JoinTeam_Task(id, msgid)
	
	return PLUGIN_HANDLED
}

public MSG_SendAudio() {
	static Sound[17]
	get_msg_arg_string(2, Sound, sizeof Sound - 1)
	
	if(equal(Sound, "terwin") || equal(Sound, "ctwin") || equal(Sound, "rounddraw") || equal(Sound, "bombpl") || equal(Sound, "bombdef"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public bool:Should_AutoJoin(id) {
	return(get_pcvar_num(cvar_autojoin_team) && !get_user_team(id) && !task_exists(id))
}

public JoinTeam_Task(id, menu_msgid) {
	static param_menu_msgid[2]
	param_menu_msgid[0] = menu_msgid
	
	set_task(0.1, "Force_JoinTeam", id, param_menu_msgid, sizeof param_menu_msgid)
}

public Force_JoinTeam(menu_msgid[], id) {
	if(get_user_team(id))
		return
	
	static team[2], class[2]
	get_pcvar_string(cvar_autojoin_team, team, sizeof team - 1)
	get_pcvar_string(cvar_autojoin_class, class, sizeof class - 1)
	Force_Team_Join(id, menu_msgid[0], team, class)
}

stock Force_Team_Join(id, menu_msgid,  team[] = "5", class[] = "0") {
	static jointeam[] = "jointeam"
	if(class[0] == '0') {
		engclient_cmd(id, jointeam, team)
		return
	}
	
	static msg_block, joinclass[] = "joinclass"
	msg_block = get_msg_block(menu_msgid)
	set_msg_block(menu_msgid, BLOCK_SET)
	engclient_cmd(id, jointeam, team)
	engclient_cmd(id, joinclass, class)
	set_msg_block(menu_msgid, msg_block)
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