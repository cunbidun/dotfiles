#include "appearance.h"
#include "dwm.h"

extern Atom netatom[NetLast];
extern Display *dpy;
extern Monitor *mons, *selmon;
extern Clr **scheme;

void losefullscreen(Client *next) {
  Client *sel = selmon->sel;
  if (!sel || !next)
    return;
  if (sel->isfullscreen && sel->fakefullscreen != 1 && ISVISIBLE(sel) && sel->mon == next->mon && !next->isfloating)
    setfullscreen(sel, 0);
}

void setfullscreen(Client *c, int fullscreen) {
  XEvent ev;
  int savestate = 0, restorestate = 0, restorefakefullscreen = 0;

  if ((c->fakefullscreen == 0 && fullscreen && !c->isfullscreen)      // normal fullscreen
      || (c->fakefullscreen == 2 && fullscreen))                      // fake fullscreen --> actual fullscreen
    savestate = 1;                                                    // go actual fullscreen
  else if ((c->fakefullscreen == 0 && !fullscreen && c->isfullscreen) // normal fullscreen exit
           || (c->fakefullscreen >= 2 && !fullscreen))                // fullscreen exit --> fake fullscreen
    restorestate = 1;                                                 // go back into tiled

  /* If leaving fullscreen and the window was previously fake fullscreen (2), then restore
   * that while staying in fullscreen. The exception to this is if we are in said state, but
   * the client itself disables fullscreen (3) then we let the client go out of fullscreen
   * while keeping fake fullscreen enabled (as otherwise there will be a mismatch between the
   * client and the window manager's perception of the client's fullscreen state). */
  if (c->fakefullscreen == 2 && !fullscreen && c->isfullscreen) {
    restorefakefullscreen = 1;
    fullscreen            = 1;
  }
  if (fullscreen != c->isfullscreen) { // only send property change if necessary
    if (fullscreen)
      XChangeProperty(dpy, c->win, netatom[NetWMState], XA_ATOM, 32, PropModeReplace, (unsigned char *)&netatom[NetWMFullscreen], 1);
    else
      XChangeProperty(dpy, c->win, netatom[NetWMState], XA_ATOM, 32, PropModeReplace, (unsigned char *)0, 0);
  }

  c->isfullscreen = fullscreen;

  /* Some clients, e.g. firefox, will send a client message informing the window manager
   * that it is going into fullscreen after receiving the above signal. This has the side
   * effect of this function (setfullscreen) sometimes being called twice when toggling
   * fullscreen on and off via the window manager as opposed to the application itself.
   * To protect against obscure issues where the client settings are stored or restored
   * when they are not supposed to we add an additional bit-lock on the old state so that
   * settings can only be stored and restored in that precise order. */
  if (savestate && !(c->oldstate & (1 << 1))) {
    c->oldbw      = c->bw;
    c->oldstate   = c->isfloating | (1 << 1);
    c->bw         = 0;
    c->isfloating = 1;
    resizeclient(c, c->mon->mx, c->mon->my, c->mon->mw, c->mon->mh);
    XRaiseWindow(dpy, c->win);

  } else if (restorestate && (c->oldstate & (1 << 1))) {
    c->bw         = c->oldbw;
    c->isfloating = c->oldstate = c->oldstate & 1;
    if (restorefakefullscreen || c->fakefullscreen == 3)
      c->fakefullscreen = 1;
    /* The client may have been moved to another monitor whilst in fullscreen which if tiled
     * we address by doing a full arrange of tiled clients. If the client is floating then the
     * height and width may be larger than the monitor's window area, so we cap that by
     * ensuring max / min values. */
    if (c->isfloating) {
      c->x = MAX(c->mon->wx, c->oldx);
      c->y = MAX(c->mon->wy, c->oldy);
      c->w = MIN(c->mon->ww - c->x - 2 * c->bw, c->oldw);
      c->h = MIN(c->mon->wh - c->y - 2 * c->bw, c->oldh);
      resizeclient(c, c->x, c->y, c->w, c->h);
      restack(c->mon);
    } else
      arrange(c->mon);
  } else {
    arrange(c->mon);
    resizeclient(c, c->x, c->y, c->w, c->h);
  }

  /* Exception: if the client was in actual fullscreen and we exit out to fake fullscreen
   * mode, then the focus would sometimes drift to whichever window is under the mouse cursor
   * at the time. To avoid this we ask X for all EnterNotify events and just ignore them.
   */
  if (!c->isfullscreen)
    while (XCheckMaskEvent(dpy, EnterWindowMask, &ev))
      ;
}

void togglefakefullscreen(const Arg *arg) {
  Client *c = selmon->sel;
  if (!c)
    return;

  if (c->fakefullscreen != 1 && c->isfullscreen) { // exit fullscreen --> fake fullscreen
    c->fakefullscreen = 2;
    setfullscreen(c, 0);
  } else if (c->fakefullscreen == 1) {
    c->fakefullscreen = 0;
    setfullscreen(c, 0);
  } else {
    c->fakefullscreen = 1;
    setfullscreen(c, 1);
  }
  updateborderonfocus(c);
}

void togglefullscreen(const Arg *arg) {
  Client *c = selmon->sel;
  if (!c)
    return;

  if (c->fakefullscreen == 1) { // fake fullscreen --> fullscreen
    c->fakefullscreen = 2;
    setfullscreen(c, 1);
  } else
    setfullscreen(c, !c->isfullscreen);
}
