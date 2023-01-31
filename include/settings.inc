#define SetBit(%1,%2)      %1 |= (1<<(%2&31))
#define ClearBit(%1,%2)    %1 &= ~(1 <<(%2&31))
#define GetBit(%1,%2)    (%1 & (1<<(%2&31)))

#define FURIEN_GRAVITY		0.4 // default gravity
#define FURIEN_SPEED		750.0 // default speed
#define TEAM_FURIEN CS_TEAM_T           
#define TEAM_ANTIFURIEN CS_TEAM_CT

#define DEBUG

#if cellbits == 32
#define OFFSET_BZ 235
#else
#define OFFSET_BZ 268
#endif