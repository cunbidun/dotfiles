#ifndef _DWM_COMMAND_H_
#define _DWM_COMMAND_H_

#include <stdio.h>

#include "appearance.h"
#include "constant.h"

/* commands */
char dmenumon[2]              = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = {"dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", nord0, "-nf", nord4, "-sb", nord9, "-sf", nord6, NULL};
static const char *termcmd[]  = {TERMINAL, NULL};

#endif
