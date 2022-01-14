#include <X11/XF86keysym.h>

/* Constants */
#define TERMINAL "alacritty"
#define TERMCLASS "Alacritty"

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int swallowfloating    = 0;        /* 1 means swallow floating windows by default */
static const int scalepreview       = 4;        /* tag preview scaling */
static const unsigned int gappih    = 15;       /* horiz inner gap between windows */
static const unsigned int gappiv    = 15;       /* vert inner gap between windows */
static const unsigned int gappoh    = 15;       /* horiz outer gap between windows and screen edge */
static const unsigned int gappov    = 15;       /* vert outer gap between windows and screen edge */
static int smartgaps                = 0;        /* 1 means no outer gap when there is only one window */
static const unsigned int systraypinning = 1;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 1;   	/* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;        /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "Source Code Pro:size=11" };
static const char dmenufont[]       = "Source Code Pro:size=11";
static const char col_gray1[]       = "#2E3440";
static const char col_gray2[]       = "#4C566A";
static const char col_gray3[]       = "#D8DEE9";
static const char col_gray4[]       = "#ECEFF4";
static const char nord0[]           = "#2E3440";
static const char nord1[]           = "#3B4252";
static const char nord2[]           = "#434C5E";
static const char nord3[]           = "#4C566A";
static const char nord4[]           = "#D8DEE9";
static const char nord5[]           = "#E5E9F0";
static const char nord6[]           = "#ECEFF4";
static const char nord7[]           = "#8FBCBB";
static const char nord8[]           = "#88c0d0";
static const char nord9[]           = "#81A1C1";
static const char nord10[]          = "#5E81AC";
static const char nord11[]          = "#BF616A";
static const char nord12[]          = "#D08770";
static const char nord13[]          = "#EBCB8B";
static const char nord14[]          = "#A3BE8C";
static const char nord15[]          = "#B48EAD";

static const char *colors[][3]      = {
	/*               fg           bg            border   */
	[SchemeNorm] = { nord4,       nord0,       nord3},
	[NordRed]    = { nord11,      nord0,       nord0},
	[NordGreen]  = { nord14,      nord0,       nord0},
	[NordYellow] = { nord13,      nord0,       nord0},
	[NordBlue]   = { nord9,       nord0,       nord0},
	[SchemeSel]  = { nord0,       nord9,       nord9},
	[SchemeUrg]  = { nord0,      nord12,      nord12},  
	[SchemeSym]  = { nord0,       nord7,       nord7},  // symbol color nord 7
};


/* tagging */
static const char *tags[] = { "sys", "dev","web","4","5","6", "7", "chat", "vi" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
   *  WM_WINDOW_ROLE(STRING) = role
	 */
	/* class              role          instance         title            tags mask     isfloating    isterminal      noswallow       monitor */
	// { "firefox",          NULL,         "Navigator",     NULL,            0,            1,            0,              0,              -1 },
	{ "Arandr",           NULL,         "arandr",        NULL,            0,            1,            0,              0,              -1 }, // center this
	{ NULL,               "pop-up",     NULL,            NULL,            0,            1,            0,              0,              -1 },
	{ TERMCLASS,          NULL,         NULL,            NULL,            0,            0,            1,              0,              -1 },
	{ NULL,               NULL,         NULL,            "Event Tester",  0,            0,            0,              1,              -1 }, /* xev */

	// { "Google-chrome",    NULL,         "google-chrome", NULL,            1 << 2,       0,            0,              0,              -1 }, // tag 3
	// { "Google-chrome",    NULL,         NULL,            "chat - reddit", 1 << 7,       0,            0,              0,              -1 }, // tag 3
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "[M]",      monocle },
	{ "[\\]",     dwindle },
	{ "|M|",      centeredmaster },
	// { "HHH",      grid }    ,
	// { "[@]",      spiral },
	{ "H[]",      deck },
	// { "TTT",      bstack },
	// { "===",      bstackhoriz },
	{ "###",      nrowgrid },
	// { "---",      horizgrid },
	// { ":::",      gaplessgrid },
	// { ">M>",      centeredfloatingmaster },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

static const MonitorRule monrules[] = {
	/* monitor  tag  layout  mfact  nmaster  showbar  topbar */
	{   0,       4,  3,      -1,    -1,      -1,      -1     }, // use a different layout for the second monitor
	{   1,       1,  1,      -1,    -1,      -1,      -1     }, // use a different layout for the second monitor
	{  -1,      -1,  0,      -1,    -1,      -1,      -1     }, // default
};

/* key definitions */
#define MODKEY Mod4Mask
#define ALTKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

#define STATUSBAR "dwmblocks"

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", nord9, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { TERMINAL, NULL };
#include "movestack.c"
static const char scratchpadname[] = "scratchpad";
static const char *scratchpadcmd[] = { TERMINAL, "-t", scratchpadname, "-o", "window.dimensions.columns=160", "-o", "window.dimensions.lines=40", NULL };

static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_x,      spawn,          SHCMD("arandr") },
	{ MODKEY,                       XK_e,      spawn,          SHCMD("nautilus ~") },
	{ MODKEY,                 XK_backslash,    spawn,          SHCMD("dunstctl close-all") },
	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_grave,  togglescratch,  {.v = scratchpadcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_z,      zoom,           {0} },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask|Mod1Mask,    XK_k,      setcfact,       {.f = +0.25} },
	{ MODKEY|ShiftMask|Mod1Mask,    XK_j,      setcfact,       {.f = -0.25} },
	{ MODKEY|ShiftMask|Mod1Mask,    XK_r,      setcfact,       {.f =  0.00} },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_s,      spawn,          SHCMD("sc_printscreen") },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          SHCMD("nord_color_picker") },
	{ MODKEY|ShiftMask,             XK_d,      spawn,          SHCMD(TERMINAL " -e dotfiles_picker") },
	{ MODKEY|ShiftMask,             XK_k,      movestack,      {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_u,      incrgaps,       {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_u,      incrgaps,       {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_i,      incrigaps,      {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_i,      incrigaps,      {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_o,      incrogaps,      {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_o,      incrogaps,      {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_6,      incrihgaps,     {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_6,      incrihgaps,     {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_7,      incrivgaps,     {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_7,      incrivgaps,     {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_8,      incrohgaps,     {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_8,      incrohgaps,     {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_9,      incrovgaps,     {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_9,      incrovgaps,     {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_0,      togglegaps,     {0} },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_0,      defaultgaps,    {0} },
	{ MODKEY,                       XK_Tab,    swapfocus,      {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ MODKEY,                       XK_space,  spawn,          SHCMD("set_language") },
	{ MODKEY|ControlMask,           XK_space,  togglefloating, {0} },
	{ MODKEY|ControlMask,	  	      XK_comma,  cyclelayout,    {.i = -1 } },
	{ MODKEY|ControlMask,           XK_period, cyclelayout,    {.i = +1 } },
	{ MODKEY,                       XK_s,      togglesticky,   {0} },
	{ MODKEY,                       XK_m,      togglefullscr,  {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ 0,                            XF86XK_AudioLowerVolume, spawn, SHCMD("decrease_volume") },
	{ 0,                            XF86XK_AudioMute,        spawn, SHCMD("toggle_volume") } ,
	{ 0,                            XF86XK_AudioRaiseVolume, spawn, SHCMD("increase_volume") },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};
/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          SHCMD(TERMINAL " -e nvim ~/dwmblocks-async/config.h") },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
	{ ClkStatusText,        ShiftMask,      Button1,        sigstatusbar,   {.i = 6} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

