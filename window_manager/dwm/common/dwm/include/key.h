#ifndef _DWM_KEY_H_
#define _DWM_KEY_H_

#include "dwm.h"
#include "appearance.h"
#include "scratchpad.h"
#include "command.h"
#include <X11/X.h>

static const Key keys[] = {
	/* modifier                         key                               function                          argument                                      submap*/
  // Set th current submap bit to 0 - 4. All the key binding with the current submask bit turned on will be enabled
	{ MODKEY|ShiftMask,                 XK_r,                             change_submask,                   {.i = 1},                                     1 }, // submap 1: resize
	{ MODKEY|ShiftMask,                 XK_g,                             change_submask,                   {.i = 2},                                     1 }, // submap 2: gaps
	{ MODKEY,                           XK_q,                             change_submask,                   {.i = 3},                                     1 }, // submap 3: window property 
	{ MODKEY|ControlMask,               XK_p,                             change_submask,                   {.i = 4},                                     1 }, // submap 4: power
	{ 0,                                XK_Escape,                        change_submask,                   {.i = 0},                                     30 }, // 11110: all except of 0

  // +-------------------------------------------------+
  // | Window focus navigation, resize, move, and swap |
  // +-------------------------------------------------+
	{ MODKEY,                           XK_h,                             focusdir,                         {.i = 0 },                                    3 }, // left
	{ MODKEY,                           XK_l,                             focusdir,                         {.i = 1 },                                    3 }, // right
	{ MODKEY,                           XK_k,                             focusdir,                         {.i = 2 },                                    3 }, // up
	{ MODKEY,                           XK_j,                             focusdir,                         {.i = 3 },                                    3 }, // down
	{ MODKEY|ShiftMask,                 XK_h,                             swapdir,                          {.i = 0 },                                    3 },
	{ MODKEY|ShiftMask,                 XK_l,                             swapdir,                          {.i = 1 },                                    3 },
	{ MODKEY|ShiftMask,                 XK_k,                             swapdir,                          {.i = 2 },                                    3 },
	{ MODKEY|ShiftMask,                 XK_j,                             swapdir,                          {.i = 3 },                                    3 }, // 00011
	{ 0,                                XK_h,                             setmfact,                         {.f = -0.05},                                 2 },
	{ 0,                                XK_l,                             setmfact,                         {.f = +0.05},                                 2 },
	{ 0,                                XK_k,                             setcfact,                         {.f = +0.25},                                 2 },
	{ 0,                                XK_j,                             setcfact,                         {.f = -0.25},                                 2 },
	{ 0,                                XK_r,                             setcfact,                         {.f =  0.00},                                 2 },
	{ 0,                                XK_c,                             movecenter,                       {},                                           2 }, // 00010

  // +--------------------+
  // | Scratchpad windows |
  // +--------------------+
	{ MODKEY,                           XK_grave,                         togglescratch,                    {.v = scratchpadcmd },                        1 },
	{ MODKEY,                           XK_n,                             togglescratch,                    {.v = scratchpadnotecmd },                    1 },
	{ MODKEY,                           XK_c,                             togglescratch,                    {.v = scratchpadchatcmd },                    1 },
	{ MODKEY,                           XK_s,                             togglescratch,                    {.v = scratchpadsignalcmd },                  1 },
	{ MODKEY,                           XK_m,                             togglescratch,                    {.v = scratchpadspotifycmd},                  1 },

  // +------+
  // | Gaps |
  // +------+
	{ ShiftMask,                        XK_equal,                         incrgaps,                         {.i = +1 },                                   4 }, // increase all gaps
	{ 0,                                XK_minus,                         incrgaps,                         {.i = -1 },                                   4 }, // decrease all gaps
	{ 0,                                XK_i,                             incrigaps,                        {.i = +1 },                                   4 }, // increase inner gaps
  { ShiftMask,                        XK_i,                             incrigaps,                        {.i = -1 },                                   4 }, // decrease inner gaps
	{ 0,                                XK_o,                             incrogaps,                        {.i = +1 },                                   4 }, // increase outer gaps
	{ ShiftMask,                        XK_o,                             incrogaps,                        {.i = -1 },                                   4 }, // decrease outer gaps
	// { MODKEY|ALTKEY,                    XK_6,                             incrihgaps,                       {.i = +1 },                                   4 },
	// { MODKEY|ALTKEY|ShiftMask,          XK_6,                             incrihgaps,                       {.i = -1 },                                   4 },
	// { MODKEY|ALTKEY,                    XK_7,                             incrivgaps,                       {.i = +1 },                                   4 },
	// { MODKEY|ALTKEY|ShiftMask,          XK_7,                             incrivgaps,                       {.i = -1 },                                   4 },
	// { MODKEY|ALTKEY,                    XK_8,                             incrohgaps,                       {.i = +1 },                                   4 },
	// { MODKEY|ALTKEY|ShiftMask,          XK_8,                             incrohgaps,                       {.i = -1 },                                   4 },
	// { MODKEY|ALTKEY,                    XK_9,                             incrovgaps,                       {.i = +1 },                                   4 },
	// { MODKEY|ALTKEY|ShiftMask,          XK_9,                             incrovgaps,                       {.i = -1 },                                   4 },
	{ 0,                                XK_t,                             togglegaps,                       {0},                                          4 },
	{ 0,                                XK_r,                             defaultgaps,                      {0},                                          4 },

  // +-------------------------+
  // | Window property control |
  // +-------------------------+
	{ 0,                                XK_s,                             togglesticky,                     {0},                                          8 },
	{ 0,                                XK_f,                             togglefullscreen,                 {0},                                          8 },
	{ ShiftMask,                        XK_f,                             togglefakefullscreen,             {0},                                          8 },
  { 0,                                XK_b,                             toggleborder,                     {0},                                          8 },

  // +---------------+
  // | Power/Session |
  // +---------------+
	{ 0,                                XK_s,                             spawn,                            SHCMD("sc_prompt 'Do you want to shutdown?' 'shutdown -h now'"),                 16 },
	{ 0,                                XK_r,                             spawn,                            SHCMD("sc_prompt 'Do you want to reboot?' 'reboot'"),                            16 },
	{ 0,                                XK_e,                             spawn,                            SHCMD("sc_prompt 'Do you want to exit dwm?' 'pkill dwm'"),                       16 },
	{ 0,                                XK_l,                             spawn,                            SHCMD("slock"),                                                                  16 },
	{ ShiftMask,                        XK_l,                             spawn,                            SHCMD("sc_prompt 'Do you want to suspend?' 'slock systemctl suspend -i'"),       16 },

	{ MODKEY|ShiftMask,                 XK_b,                             spawn,                            SHCMD("sc_toggle_picom"),                     1 },
	{ MODKEY,                           XK_o,                             show,                             {0},                                          1 },
	{ MODKEY|ShiftMask,                 XK_o,                             showall,                          {0},                                          1 },
  { MODKEY|ControlMask|ShiftMask,     XK_c,                             hide,                             {0},                                          1 },

	{ MODKEY,                           XK_x,                             spawn,                            SHCMD("arandr"),                              1 },
	{ MODKEY,                           XK_t,                             spawn,                            SHCMD("tabbedize"),                           1 },
	{ MODKEY,                           XK_e,                             spawn,                            SHCMD("thunar ~"),                            1 },
	{ MODKEY,                           XK_backslash,                     spawn,                            SHCMD("dunstctl close-all"),                  1 },
	{ MODKEY,                           XK_p,                             spawn,                            {.v = dmenucmd },                             1 },
	{ MODKEY|ShiftMask,                 XK_p,                             spawn,                            SHCMD("sc_window_picker"),                    1 },
	{ MODKEY,                           XK_Return,                        spawn,                            {.v = termcmd },                              1 },
	{ MODKEY,                           XK_b,                             togglebar,                        {0},                                          1 },

	{ MODKEY|ControlMask|ShiftMask,     XK_j,                             focusstackhid,                    {.i = +1 },                                   1 },
	{ MODKEY|ControlMask|ShiftMask,     XK_k,                             focusstackhid,                    {.i = -1 },                                   1 },

  // Window movement and swap

	{ MODKEY,                           XK_i,                             incnmaster,                       {.i = +1 },                                   1 },
	{ MODKEY,                           XK_d,                             incnmaster,                       {.i = -1 },                                   1 },
	{ MODKEY,                           XK_z,                             zoom,                             {0},                                          1 },
	{ MODKEY|ShiftMask,                 XK_s,                             spawn,                            SHCMD("sc_printscreen quick"),                1 },
	{ MODKEY|ShiftMask,                 XK_n,                             spawn,                            SHCMD("nord_color_picker"),                   1 },
	{ MODKEY|ShiftMask,                 XK_d,                             spawn,                            SHCMD("dotfiles_picker"),                     1 },
	{ MODKEY|ShiftMask,                 XK_m,                             spawn,                            SHCMD("sc_open_man_page_dmenu"),              1 },
	{ MODKEY|ShiftMask,                 XK_comma,                         tagmon,                           {.i = -1 },                                   1 },
	{ MODKEY|ShiftMask,                 XK_period,                        tagmon,                           {.i = +1 },                                   1 },
	{ MODKEY|ShiftMask,                 XK_q,                             quit,                             {1},                                          1 },
	{ MODKEY,                           XK_Tab,                           swapfocus,                        {0},                                          1 },
	{ MODKEY|ShiftMask,                 XK_c,                             killclient,                       {0},                                          1 },
	{ MODKEY,                           XK_space,                         spawn,                            SHCMD("set_language"),                        1 },
	{ MODKEY|ControlMask,               XK_space,                         togglefloating,                   {0},                                          1 },
	{ MODKEY|ControlMask,	  	          XK_comma,                         cyclelayout,                      {.i = -1 },                                   1 },
	{ MODKEY|ControlMask,               XK_period,                        cyclelayout,                      {.i = +1 },                                   1 },
	{ MODKEY,                           XK_0,                             view,                             {.ui = ~0 },                                  1 },
	{ MODKEY|ShiftMask,                 XK_0,                             tag,                              {.ui = ~0 },                                  1 },
	{ MODKEY,                           XK_comma,                         focusmon,                         {.i = -1 },                                   1 },
	{ MODKEY,                           XK_period,                        focusmon,                         {.i = +1 },                                   1 },

  // +------------+
  // | Media Keys |
  // +------------+
	{ 0,                                XK_Print,                         spawn,                            SHCMD("sc_printscreen"),                      1 },
	{ 0,                                XF86XK_AudioLowerVolume,          spawn,                            SHCMD("decrease_volume"),                     1 },
	{ 0,                                XF86XK_AudioMute,                 spawn,                            SHCMD("toggle_volume"),                       1 },
	{ 0,                                XF86XK_AudioRaiseVolume,          spawn,                            SHCMD("increase_volume"),                     1 },
	{ 0,                                XK_F10,                           spawn,                            SHCMD("toggle_volume"),                       1 },
	{ 0,                                XK_F11,                           spawn,                            SHCMD("decrease_volume"),                     1 },
	{ 0,                                XK_F12,                           spawn,                            SHCMD("increase_volume"),                     1 },
	{ 0,                                XK_F1,                            spawn,                            SHCMD("sc_brightness_change decrease 5"),     1 },
	{ 0,                                XK_F2,                            spawn,                            SHCMD("sc_brightness_change increase 5"),     1 },

  // +----------+
  // | Tag Keys |
  // +----------+
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
