#ifndef _DWM_KEY_H_
#define _DWM_KEY_H_

#include "dwm.h"
#include "appearance.h"
#include "scratchpad.h"
#include "command.h"
#include <X11/X.h>

static const Key keys[] = {
	/* modifier                         key                               function                          argument */
	{ MODKEY,                           XK_grave,                         togglescratch,                    {.v = scratchpadcmd } },
	{ MODKEY,                           XK_n,                             togglescratch,                    {.v = scratchpadnotecmd } },
	{ MODKEY,                           XK_c,                             togglescratch,                    {.v = scratchpadchatcmd } },
	{ MODKEY,                           XK_s,                             togglescratch,                    {.v = scratchpadsignalcmd } },
	{ MODKEY,                           XK_m,                             togglescratch,                    {.v = scratchpadspotifycmd} },

  { MODKEY|ControlMask|ShiftMask,     XK_b,                             toggleborder,                     {0} },
	{ MODKEY|ShiftMask,                 XK_b,                             spawn,                            SHCMD("sc_toggle_picom") },

	{ MODKEY,                           XK_o,                             show,                             {0} },
	{ MODKEY|ShiftMask,                 XK_o,                             showall,                          {0} },
  { MODKEY|ControlMask|ShiftMask,     XK_c,                             hide,                             {0} },

	{ MODKEY,                           XK_x,                             spawn,                            SHCMD("arandr") },
	{ MODKEY,                           XK_t,                             spawn,                            SHCMD("tabbedize") },
	{ MODKEY,                           XK_e,                             spawn,                            SHCMD("thunar ~") },
	{ MODKEY,                           XK_backslash,                     spawn,                            SHCMD("dunstctl close-all") },
	{ MODKEY,                           XK_p,                             spawn,                            {.v = dmenucmd } },
	{ MODKEY|ShiftMask,                 XK_p,                             spawn,                            SHCMD("sc_window_picker") },
	{ MODKEY,                           XK_Return,                        spawn,                            {.v = termcmd } },
	{ MODKEY,                           XK_b,                             togglebar,                        {0} },

	{ MODKEY,                           XK_j,                             focusstackvis,                    {.i = +1 } },
	{ MODKEY,                           XK_k,                             focusstackvis,                    {.i = -1 } },
	{ MODKEY|ControlMask|ShiftMask,     XK_j,                             focusstackhid,                    {.i = +1 } },
	{ MODKEY|ControlMask|ShiftMask,     XK_k,                             focusstackhid,                    {.i = -1 } },

	{ MODKEY,                           XK_i,                             incnmaster,                       {.i = +1 } },
	{ MODKEY,                           XK_d,                             incnmaster,                       {.i = -1 } },
	{ MODKEY,                           XK_z,                             zoom,                             {0} },
	{ MODKEY,                           XK_h,                             setmfact,                         {.f = -0.05} },
	{ MODKEY,                           XK_l,                             setmfact,                         {.f = +0.05} },
	{ MODKEY|ShiftMask,                 XK_j,                             movestack,                        {.i = +1 } },
	{ MODKEY|ShiftMask,                 XK_k,                             movestack,                        {.i = -1 } },
	{ MODKEY|ShiftMask,                 XK_x,                             spawn,                            SHCMD("sc_prompt 'Do you want to shutdown?' 'shutdown -h now'") },
	{ MODKEY|ShiftMask,                 XK_r,                             spawn,                            SHCMD("sc_prompt 'Do you want to reboot?' 'reboot'") },
	{ MODKEY|ShiftMask,                 XK_e,                             spawn,                            SHCMD("sc_prompt 'Do you want to exit dwm?' 'pkill dwm'") },
	{ MODKEY|ShiftMask,                 XK_l,                             spawn,                            SHCMD("slock") },
	{ MODKEY|ControlMask|ShiftMask,     XK_l,                             spawn,                            SHCMD("sc_prompt 'Do you want to suspend?' 'slock systemctl suspend -i'") },
	{ MODKEY|ShiftMask,                 XK_s,                             spawn,                            SHCMD("sc_printscreen quick") },
	{ 0,                                XK_Print,                         spawn,                            SHCMD("sc_printscreen") },
	{ MODKEY|ShiftMask,                 XK_n,                             spawn,                            SHCMD("nord_color_picker") },
	{ MODKEY|ShiftMask,                 XK_d,                             spawn,                            SHCMD("dotfiles_picker") },
	{ MODKEY|ShiftMask,                 XK_m,                             spawn,                            SHCMD("sc_open_man_page_dmenu") },
	{ MODKEY|ShiftMask,                 XK_comma,                         tagmon,                           {.i = -1 } },
	{ MODKEY|ShiftMask,                 XK_period,                        tagmon,                           {.i = +1 } },
	{ MODKEY|ShiftMask,                 XK_q,                             quit,                             {1} },
	// { MODKEY|ShiftMask|ALTKEY,          XK_k,                             setcfact,                         {.f = +0.25} },
	// { MODKEY|ShiftMask|ALTKEY,          XK_j,                             setcfact,                         {.f = -0.25} },
	// { MODKEY|ShiftMask|ALTKEY,          XK_r,                             setcfact,                         {.f =  0.00} },
	// { MODKEY|ALTKEY,                    XK_u,                             incrgaps,                         {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_u,                             incrgaps,                         {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_i,                             incrigaps,                        {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_i,                             incrigaps,                        {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_o,                             incrogaps,                        {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_o,                             incrogaps,                        {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_6,                             incrihgaps,                       {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_6,                             incrihgaps,                       {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_7,                             incrivgaps,                       {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_7,                             incrivgaps,                       {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_8,                             incrohgaps,                       {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_8,                             incrohgaps,                       {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_9,                             incrovgaps,                       {.i = +1 } },
	// { MODKEY|ALTKEY|ShiftMask,          XK_9,                             incrovgaps,                       {.i = -1 } },
	// { MODKEY|ALTKEY,                    XK_0,                             togglegaps,                       {0} },
	// { MODKEY|ALTKEY|ShiftMask,          XK_0,                             defaultgaps,                      {0} },
	{ MODKEY|ControlMask,               XK_h,                             focusdir,                         {.i = 0 } }, // left
	{ MODKEY|ControlMask,               XK_l,                             focusdir,                         {.i = 1 } }, // right
	{ MODKEY|ControlMask,               XK_k,                             focusdir,                         {.i = 2 } }, // up
	{ MODKEY|ControlMask,               XK_j,                             focusdir,                         {.i = 3 } }, // down
	{ MODKEY,                           XK_Tab,                           swapfocus,                        {0} },
	{ MODKEY|ShiftMask,                 XK_c,                             killclient,                       {0} },
	{ MODKEY,                           XK_space,                         spawn,                            SHCMD("set_language") },
	{ MODKEY|ControlMask,               XK_space,                         togglefloating,                   {0} },
	{ MODKEY|ControlMask,	  	          XK_comma,                         cyclelayout,                      {.i = -1 } },
	{ MODKEY|ControlMask,               XK_period,                        cyclelayout,                      {.i = +1 } },
	{ MODKEY|ControlMask|ShiftMask,     XK_s,                             togglesticky,                     {0} },
	{ MODKEY,                           XK_f,                             togglefullscreen,                 {0} },
	{ MODKEY|ShiftMask,                 XK_f,                             togglefakefullscreen,             {0} },
	{ MODKEY,                           XK_0,                             view,                             {.ui = ~0 } },
	{ MODKEY|ShiftMask,                 XK_0,                             tag,                              {.ui = ~0 } },
	{ MODKEY,                           XK_comma,                         focusmon,                         {.i = -1 } },
	{ MODKEY,                           XK_period,                        focusmon,                         {.i = +1 } },
	{ 0,                                XF86XK_AudioLowerVolume,          spawn,                            SHCMD("decrease_volume") },
	{ 0,                                XF86XK_AudioMute,                 spawn,                            SHCMD("toggle_volume") } ,
	{ 0,                                XF86XK_AudioRaiseVolume,          spawn,                            SHCMD("increase_volume") },
	{ 0,                                XK_F10,                           spawn,                            SHCMD("toggle_volume") } ,
	{ 0,                                XK_F11,                           spawn,                            SHCMD("decrease_volume") },
	{ 0,                                XK_F12,                           spawn,                            SHCMD("increase_volume") },
	{ 0,                                XK_F1,                            spawn,                            SHCMD("sc_brightness_change decrease 5") },
	{ 0,                                XK_F2,                            spawn,                            SHCMD("sc_brightness_change increase 5") },
	TAGKEYS(                            XK_1,                             0)
	TAGKEYS(                            XK_2,                             1)
	TAGKEYS(                            XK_3,                             2)
	TAGKEYS(                            XK_4,                             3)
	TAGKEYS(                            XK_w,                             4)
	TAGKEYS(                            XK_v,                             5)
	TAGKEYS(                            XK_a,                             6)
	TAGKEYS(                            XK_8,                             7)
	TAGKEYS(                            XK_9,                             8)
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
/* Button1 left click */
/* Button2 middle click */
/* Button3 right click */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          SHCMD(TERMINAL " -e lvim ~/dwmblocks-async/config.h") },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} }, /* left click*/
	{ ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} }, /* middle click*/
	{ ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} }, /* right click*/
	{ ClkStatusText,        ShiftMask,      Button1,        sigstatusbar,   {.i = 6} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
  { ClkWinTitle,          0,              Button1,        togglewin,      {0} },
};
#endif 
