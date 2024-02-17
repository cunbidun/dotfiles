#include "dwm.h"

extern Monitor *mons, *selmon;
extern Display *dpy;
extern Window root, wmcheckwin;

void hide(const Arg *arg) {
  hidewin(selmon->sel);
  focus(NULL);
  arrange(selmon);
}

void hidewin(Client *c) {
  if (!c || HIDDEN(c))
    return;

  Window w = c->win;
  static XWindowAttributes ra, ca;

  // more or less taken directly from blackbox's hide() function
  XGrabServer(dpy);
  XGetWindowAttributes(dpy, root, &ra);
  XGetWindowAttributes(dpy, w, &ca);
  // prevent UnmapNotify events
  XSelectInput(dpy, root, ra.your_event_mask & ~SubstructureNotifyMask);
  XSelectInput(dpy, w, ca.your_event_mask & ~StructureNotifyMask);
  XUnmapWindow(dpy, w);
  setclientstate(c, IconicState);
  XSelectInput(dpy, root, ra.your_event_mask);
  XSelectInput(dpy, w, ca.your_event_mask);
  XUngrabServer(dpy);
}

void show(const Arg *arg) {
  if (selmon->hidsel)
    selmon->hidsel = 0;
  showwin(selmon->sel);
}

void showall(const Arg *arg) {
  Client *c      = NULL;
  selmon->hidsel = 0;
  for (c = selmon->clients; c; c = c->next) {
    if (ISVISIBLE(c))
      showwin(c);
  }
  if (!selmon->sel) {
    for (c = selmon->clients; c && !ISVISIBLE(c); c = c->next)
      ;
    if (c)
      focus(c);
  }
  restack(selmon);
}

void showwin(Client *c) {
  if (!c || !HIDDEN(c))
    return;

  XMapWindow(dpy, c->win);
  setclientstate(c, NormalState);
  arrange(c->mon);
}

void togglewin(const Arg *arg) {
  Client *c = (Client *)arg->v;

  if (c == selmon->sel) {
    hidewin(c);
    focus(NULL);
    arrange(c->mon);
  } else {
    if (HIDDEN(c))
      showwin(c);
    focus(c);
    restack(selmon);
  }
}
