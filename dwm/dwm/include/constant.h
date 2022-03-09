#ifndef _DWM_CONST_H_
#define _DWM_CONST_H_

/**
 *  Patches
 */
#define FORCE_VSPLIT 1 // nrowgrid layout: force two clients to always split vertically
#define STATUSBAR "dwmblocks"

/**
 *  Variables 
 */
#define TERMINAL "alacritty"
#define TERMCLASS "Alacritty"
#define EDITOR "lvim"

/**
 * Keys 
 */
#define MODKEY Mod4Mask
#define ALTKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#endif