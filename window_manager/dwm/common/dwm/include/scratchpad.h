
#ifndef _DWM_SCRATCHPAD_H
#define _DWM_SCRATCHPAD_H

#include "constant.h"
#include "dwm.h"

static const char *scratchpadcmd[]       = {"d", TERMINAL, "-t", "scratchpad", "-o", "window.dimensions.columns=320", "-o", "window.dimensions.lines=80", NULL};
static const char *scratchpadnotecmd[]   = {"n", "obsidian", NULL};
static const char *scratchpadchatcmd[]   = {"c", "caprine", NULL};
static const char *scratchpadsignalcmd[] = {"s", "signal-desktop", NULL};
static const char *scratchpadspotifycmd[] = {"m", "spotify", NULL};

void togglescratch(const Arg *arg);
void spawnscratch(const Arg *arg);
#endif
