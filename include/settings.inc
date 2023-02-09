#define SetBit(%1,%2)      %1 |= (1<<(%2&31))
#define ClearBit(%1,%2)    %1 &= ~(1 <<(%2&31))
#define GetBit(%1,%2)    (%1 & (1<<(%2&31)))

#define XP_ANTIFURIEN           10     // cat xp sa primeasca pe kill normal
#define XP_HS_ANTIFURIEN        10     // cat xp primeste anti furien ul pe un headshot
#define XP_HS_ANTIFURIEN_VIP    20     // xp primit pt cei cu vip

#define XP_FURIEN               10
#define XP_HS_FURIEN            10
#define XP_HS_FURIEN_VIP        20
#define XP_FURIEN_GRENADE       15
#define XP_FURIEN_GRENADE_VIP       30

#define HS_FURIEN_HEALTH_VIP     30
#define HS_FURIEN_ARMOR_VIP     30
#define HS_FURIEN_MONEY_VIP     3000
#define HS_FURIEN_HEALTH_GOD    40
#define HS_FURIEN_ARMOR_GOD    40
#define HS_FURIEN_MONEY_GOD    4000

#define FURIEN_GRAVITY		0.4 // default gravity
#define FURIEN_SPEED		750.0 // default speed
#define TEAM_FURIEN CS_TEAM_T           
#define TEAM_ANTIFURIEN CS_TEAM_CT

// #define DEBUG

//#define HUD_SYSTEM // activeaza linia asta daca vrei hud-ul ala in centru

#if cellbits == 32
#define OFFSET_BZ 235
#else
#define OFFSET_BZ 268
#endif