#ifndef _DWM_COMMAND_H_
#define _DWM_COMMAND_H_

#include <stdio.h>

#include "constant.h"
#include "appearance.h"

/* commands */
char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", nord9, "-sf", col_gray4, NULL };
const char *termcmd[]  = { TERMINAL, NULL };
const char *scratchpadcmd[] = { "s", TERMINAL, "-t", "scratchpad", "-o", "window.dimensions.columns=160", "-o", "window.dimensions.lines=40", NULL };
const char *scratchpadnotecmd[] = { "n", "logseq", NULL };
const char *scratchpadchatcmd[] = { "c", "caprine", NULL };

#endif
