#include "appearance.h"
#include "dwm.h"
#include "log.h"

extern Atom netatom[NetLast], wmatom[WMLast], xatom[XLast];
extern Display *dpy;
extern Monitor *selmon;
extern Clr **scheme;
extern Window root;

void unfocus(Client *c, int setfocus) {
  if (!c)
    return;

  if (1 << (selmon->pertag->curtag - 1) == c->tags) {
    log_info("Setting prevclient for tag %d to %s", c->tags, c->name);
    selmon->pertag->prevclient[c->tags] = c;
  }
  grabbuttons(c, 0);
  updateborderonunfocus(c);
  if (setfocus) {
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
    XDeleteProperty(dpy, root, netatom[NetActiveWindow]);
  }
  updatecurrentdesktop();
}

void updateborderonfocus(Client *c) {
  if (c->fakefullscreen == 1)
    XSetWindowBorder(dpy, c->win, scheme[SchemeGreen][ColBorder].pixel);
  else if (c->issticky == 1)
    XSetWindowBorder(dpy, c->win, scheme[SchemeRed][ColBorder].pixel);
  else if (c->scratchkey != 0)
    XSetWindowBorder(dpy, c->win, scheme[SchemeYellow][ColBorder].pixel);
  else
    XSetWindowBorder(dpy, c->win, scheme[SchemeSel][ColBorder].pixel);
}

void updateborderonunfocus(Client *c) {
  if (c->scratchkey != 0)
    XSetWindowBorder(dpy, c->win, scheme[SchemeYellow][ColBorder].pixel);
  else
    XSetWindowBorder(dpy, c->win, scheme[SchemeNorm][ColBorder].pixel);
}

void focus(Client *c) {
  if (!c || !ISVISIBLE(c))
    for (c = selmon->stack; c && (!ISVISIBLE(c) || HIDDEN(c)); c = c->snext)
      ;
  if (selmon->sel && selmon->sel != c) {
    losefullscreen(c);
    unfocus(selmon->sel, 0);

    if (selmon->hidsel) {
      hidewin(selmon->sel);
      if (c)
        arrange(c->mon);
      selmon->hidsel = 0;
    }
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

void focusdir(const Arg *arg) {
  Client *s = selmon->sel, *f = NULL;
  if (!s)
    return;
  f = getdir(arg);

  if (f && f != s) {
    focus(f);
    restack(f->mon);
  }
}
