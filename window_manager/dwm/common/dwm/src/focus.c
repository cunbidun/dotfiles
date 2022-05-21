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

void focusdir(const Arg *arg) {
  Client *s = selmon->sel, *f = NULL, *c, *next;

  if (!s)
    return;

  unsigned int score = -1;
  unsigned int client_score;
  int dist;
  int dirweight  = 20;
  int isfloating = s->isfloating;

  next = s->next;
  if (!next)
    next = s->mon->clients;
  for (c = next; c != s; c = next) {

    next = c->next;
    if (!next)
      next = s->mon->clients;

    if (!ISVISIBLE(c) || c->isfloating != isfloating) // || HIDDEN(c)
      continue;

    switch (arg->i) {
    case 0: // left
      dist         = s->x - c->x - c->w;
      client_score = dirweight * MIN(abs(dist), abs(dist + s->mon->ww)) + abs(s->y - c->y);
      break;
    case 1: // right
      dist         = c->x - s->x - s->w;
      client_score = dirweight * MIN(abs(dist), abs(dist + s->mon->ww)) + abs(c->y - s->y);
      break;
    case 2: // up
      dist         = s->y - c->y - c->h;
      client_score = dirweight * MIN(abs(dist), abs(dist + s->mon->wh)) + abs(s->x - c->x);
      break;
    default:
    case 3: // down
      dist         = c->y - s->y - s->h;
      client_score = dirweight * MIN(abs(dist), abs(dist + s->mon->wh)) + abs(c->x - s->x);
      break;
    }

    if (((arg->i == 0 || arg->i == 2) && client_score <= score) || client_score < score) {
      score = client_score;
      f     = c;
    }
  }
  if (f && f != s) {
    focus(f);
    restack(f->mon);
  }
}
