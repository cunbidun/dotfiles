#ifndef _DWM_CONST_H_
#define _DWM_CONST_H_

/**
 *  Variables 
 */
#define TERMINAL "alacritty"
#define TERMCLASS "Alacritty"
#define EDITOR "lvim"
#define SESSION_FILE "/tmp/dwm-session"


/**
 * Keys 
 */
// On linux:
// #define MODKEY Mod4Mask
// #define ALTKEY Mod1Mask
 
// On M1 linux:
#define MODKEY Mod1Mask
#define ALTKEY Mod4Mask

#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#endif
