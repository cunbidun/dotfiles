#ifndef _DWM_LAYOUT_H_
#define _DWM_LAYOUT_H_

#include "appearance.h"
#include "constant.h"
#include "dwm.h"

void bstack(Monitor *m);
void bstackhoriz(Monitor *m);
void centeredmaster(Monitor *m);
void centeredfloatingmaster(Monitor *m);
void deck(Monitor *m);
void dwindle(Monitor *m);
void fibonacci(Monitor *m, int s);
void grid(Monitor *m);
void monocle(Monitor *m);
void nrowgrid(Monitor *m);
void spiral(Monitor *m);
void tile(Monitor *m);
void tatami(Monitor *m);

#endif
