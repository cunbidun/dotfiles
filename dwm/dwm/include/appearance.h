#ifndef _DWM_APPEARANCE_H_
#define _DWM_APPEARANCE_H_

#include "dwm.h"

/* Appearance */
const unsigned int borderpx  = 2;        /* border pixel of windows */
const unsigned int snap      = 32;       /* snap pixel */
const int swallowfloating    = 0;        /* 1 means swallow floating windows by default */
const int scalepreview       = 4;        /* tag preview scaling */
const unsigned int gappih    = 15;       /* horiz inner gap between windows */
const unsigned int gappiv    = 15;       /* vert inner gap between windows */
const unsigned int gappoh    = 15;       /* horiz outer gap between windows and screen edge */
const unsigned int gappov    = 15;       /* vert outer gap between windows and screen edge */
const unsigned int smartgaps = 0;        /* 1 means no outer gap when there is only one window */
const unsigned int systraypinning = 1;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
const unsigned int systrayonleft = 1;   	/* 0: systray in the right corner, >0: systray on left of status text */
const unsigned int systrayspacing = 2;   /* systray spacing */
const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
const int showsystray        = 1;        /* 0 means no systray */
const int showbar            = 1;        /* 0 means no bar */
const int topbar             = 1;        /* 0 means bottom bar */
const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
const int nmaster     = 1;    /* number of clients in master area */
const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

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

static const char *fonts[]          = { "Source Code Pro:size=11" };
static const char dmenufont[]       = "Source Code Pro:size=11";

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

#endif
