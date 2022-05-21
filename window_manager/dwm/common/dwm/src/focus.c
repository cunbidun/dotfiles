#include "appearance.h"
#include "dwm.h"

extern Atom netatom[NetLast], wmatom[WMLast], xatom[XLast];
extern Display *dpy;
extern Monitor *selmon;
extern Clr **scheme;
extern Client *prevclient;
extern Window root;

void unfocus(Client *c, int setfocus) {
  if (!c)
    return;
  prevclient = c;
  grabbuttons(c, 0);
  updateborderonunfocus(c);
  if (setfocus) {
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
    XDeleteProperty(dpy, root, netatom[NetActiveWindow]);
  }
  updatecurrentdesktop();
}

void updateborderonunfocus(Client *c) {
  if (c->scratchkey != 0)
    XSetWindowBorder(dpy, c->win, scheme[NordYellow][ColFg].pixel);
  else
    XSetWindowBorder(dpy, c->win, scheme[SchemeNorm][ColBorder].pixel);
}

void focus(Client *c) {
  if (!c || !ISVISIBLE(c))
    for (c = selmon->stack; c && !ISVISIBLE(c); c = c->snext)
      ;
  if (selmon->sel && selmon->sel != c) {
    losefullscreen(c);
    unfocus(selmon->sel, 0);
  }
  if (c) {
    if (c->mon != selmon)
      selmon = c->mon;
    if (c->isurgent)
      seturgent(c, 0);
    detachstack(c);
    attachstack(c);
    grabbuttons(c, 1);
    updateborderonfocus(c);
    setfocus(c);
  } else {
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
    XDeleteProperty(dpy, root, netatom[NetActiveWindow]);
  }
  selmon->sel = c;
  drawbars();
}

void updateborderonfocus(Client *c) {
  if (c->fakefullscreen == 1)
    XSetWindowBorder(dpy, c->win, scheme[NordGreen][ColFg].pixel);
  else if (c->scratchkey != 0)
    XSetWindowBorder(dpy, c->win, scheme[NordYellow][ColFg].pixel);
  else
    XSetWindowBorder(dpy, c->win, scheme[SchemeSel][ColBorder].pixel);
}
