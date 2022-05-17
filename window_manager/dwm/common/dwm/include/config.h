#ifndef _DWM_CONFIG_H_
#define _DWM_CONFIG_H_

#include "constant.h"
#include "layout.h"

/* tagging */
static const char *tags[] = {"sys", "dev", "web", "4", "5", "6", "7", "chat", "vi"};

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
   *  WM_WINDOW_ROLE(STRING) = role
   *
   * Note that, rules will override others. The below will overwrite the previous!
	 */
	/* class         role          instance       title               tags mask   isfloating   isterminal   noswallow   monitor   scratch key*/
	{ "Arandr",      NULL,         "arandr",      NULL,               0,          1,           0,           0,          -1,       0          }, // center this

	{ NULL,          "pop-up",     NULL,          NULL,               0,          1,           0,           0,          -1,       0          },

  
	{ TERMCLASS,     NULL,         NULL,          NULL,               0,          0,           1,           0,          -1,       0          },

	{ NULL,          NULL,         NULL,          "audioconfig",      0,          1,           0,           0,          -1,       0          }, // center this
	{ NULL,          NULL,         NULL,          "editdwmblock",     0,          1,           0,           0,          -1,       0          },

	{ NULL,          NULL,         NULL,          "scratchpad",       0,          1,           0,           0,          -1,       'd'        },
	{ "Logseq",      NULL,         "logseq",      NULL,               0,          1,           0,           0,          -1,       'n'        },
	{ "Caprine",     NULL,         "caprine",     NULL,               0,          1,           0,           0,          -1,       'c'        },
	{ "Signal",      NULL,         "signal",      NULL,               0,          1,           0,           0,          -1,       's'        },

	{ NULL,          NULL,         NULL,          "Event Tester",     0,          0,           0,           1,          -1,       0          }, /* xev */
};


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
  { "|+|",      tatami },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

static const MonitorRule monrules[] = {
	/* monitor  tag  layout  mfact  nmaster  showbar  topbar */
	// {   0,       4,  3,      -1,    -1,      -1,      -1     }, // use centeredmaster different layout on tag 4 for first monitor
	// {   1,       1,  1,      -1,    -1,      -1,      -1     }, // use monocle on tag 1 for second monitor
	{  -1,      -1,  0,      -1,    -1,      -1,      -1     }, // default
};
#endif
