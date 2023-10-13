#include "dwm.h"
#include "command.h"
#include "config.h"
#include "constant.h"
#include "key.h"
#include "log.h"
#include "util.h"

/* appearance default values */
unsigned int borderpx = 2; /* border pixel of windows */
char scheme_bg[]      = "#2E3440";
char scheme_fg[]      = "#ECEFF4";
char scheme_norm[]    = "#4C566A";
char scheme_sel[]     = "#81A1C1";
char scheme_sym_bg[]  = "#8FBCBB";
char scheme_sym_fg[]  = "#2E3440";
char scheme_urg[]     = "#D08770";
char schemered[]      = "#BF616A";
char schemegreen[]    = "#A3BE8C";
char schemeyellow[]   = "#EBCB8B";
char schemeblue[]     = "#81A1C1";

/* variables */
const char autostartblocksh[] = "autostart_blocking.sh";
const char autostartsh[]      = "autostart.sh";
Client *prevclient            = NULL;
Systray *systray              = NULL;
const char broken[]           = "broken";
const char dwmdir[]           = "dwm";
const char localshare[]       = ".local/share";
char stext[1024];
int statussig;
int statusw;
pid_t statuspid = -1;
int screen;
int sw, sh; /* X display screen geometry width, height */
int bh = 0; /* bar geometry */
int lrpad;  /* sum of left and right padding for text */
int (*xerrorxlib)(Display *, XErrorEvent *);
unsigned int numlockmask             = 0;
void (*handler[LASTEvent])(XEvent *) = {[ButtonPress]      = buttonpress,
                                        [ClientMessage]    = clientmessage,
                                        [ConfigureRequest] = configurerequest,
                                        [ConfigureNotify]  = configurenotify,
                                        [DestroyNotify]    = destroynotify,
                                        [EnterNotify]      = enternotify,
                                        [Expose]           = expose,
                                        [FocusIn]          = focusin,
                                        [KeyPress]         = keypress,
                                        [MappingNotify]    = mappingnotify,
                                        [MapRequest]       = maprequest,
                                        [MotionNotify]     = motionnotify,
                                        [PropertyNotify]   = propertynotify,
                                        [ResizeRequest]    = resizerequest,
                                        [UnmapNotify]      = unmapnotify};
Atom wmatom[WMLast], netatom[NetLast], xatom[XLast];
int restart = 0;
int running = 1;
Cur *cursor[CurLast];
Clr **scheme;
Display *dpy;
Drw *drw;
Monitor *mons, *selmon;
Window root, wmcheckwin;
xcb_connection_t *xcon;

/* function implementations */
void applyrules(Client *c) {
  const char *class, *instance;
  char role[64];
  unsigned int i;
  const Rule *r;
  Monitor *m;
  XClassHint ch = {NULL, NULL};

  /* rule matching */
  c->isfloating = 0;
  c->tags       = 0;
  c->scratchkey = 0;
  XGetClassHint(dpy, c->win, &ch);
  class    = ch.res_class ? ch.res_class : broken;
  instance = ch.res_name ? ch.res_name : broken;
  gettextprop(c->win, wmatom[WMWindowRole], role, sizeof(role));

  if (strstr(class, "Steam") || strstr(class, "steam_app_"))
    c->issteam = 1;

  if (strstr(class, "dota2") || strstr(class, "dota2")) {
    log_info("[In applyrules] got dota2 client. Setting to issteam");
    c->issteam = 1;
  }

  if (strstr(class, "tabbed"))
    c->istabbed = 1;

  for (i = 0; i < LENGTH(rules); i++) {
    r = &rules[i];
    if ((!r->title || strstr(c->name, r->title)) && (!r->class || strstr(class, r->class)) && (!r->role || strstr(role, r->role)) &&

        (!r->instance || strstr(instance, r->instance))) {
      c->isterminal = r->isterminal;
      c->noswallow  = r->noswallow;
      c->isfloating = r->isfloating;
      c->tags |= r->tags;
      c->scratchkey = r->scratchkey;
      for (m = mons; m && m->num != r->monitor; m = m->next)
        ;
      if (m)
        c->mon = m;
    }
  }
  if (ch.res_class)
    XFree(ch.res_class);
  if (ch.res_name)
    XFree(ch.res_name);
  c->tags = c->tags & TAGMASK ? c->tags & TAGMASK : c->mon->tagset[c->mon->seltags];
}

int applysizehints(Client *c, int *x, int *y, int *w, int *h, int interact) {
  int baseismin;
  Monitor *m = c->mon;

  /* set minimum possible */
  *w = MAX(1, *w);
  *h = MAX(1, *h);
  if (interact) {
    if (*x > sw)
      *x = sw - WIDTH(c);
    if (*y > sh)
      *y = sh - HEIGHT(c);
    if (*x + *w + 2 * c->bw < 0)
      *x = 0;
    if (*y + *h + 2 * c->bw < 0)
      *y = 0;
  } else {
    if (*x >= m->wx + m->ww)
      *x = m->wx + m->ww - WIDTH(c);
    if (*y >= m->wy + m->wh)
      *y = m->wy + m->wh - HEIGHT(c);
    if (*x + *w + 2 * c->bw <= m->wx)
      *x = m->wx;
    if (*y + *h + 2 * c->bw <= m->wy)
      *y = m->wy;
  }
  if (*h < bh)
    *h = bh;
  if (*w < bh)
    *w = bh;
  if (resizehints || c->isfloating || !c->mon->lt[c->mon->sellt]->arrange) {
    if (!c->hintsvalid)
      updatesizehints(c);
    /* see last two sentences in ICCCM 4.1.2.3 */
    baseismin = c->basew == c->minw && c->baseh == c->minh;
    if (!baseismin) { /* temporarily remove base dimensions */
      *w -= c->basew;
      *h -= c->baseh;
    }
    /* adjust for aspect limits */
    if (c->mina > 0 && c->maxa > 0) {
      if (c->maxa < (float)*w / *h)
        *w = *h * c->maxa + 0.5;
      else if (c->mina < (float)*h / *w)
        *h = *w * c->mina + 0.5;
    }
    if (baseismin) { /* increment calculation requires this */
      *w -= c->basew;
      *h -= c->baseh;
    }
    /* adjust for increment value */
    if (c->incw)
      *w -= *w % c->incw;
    if (c->inch)
      *h -= *h % c->inch;
    /* restore base dimensions */
    *w = MAX(*w + c->basew, c->minw);
    *h = MAX(*h + c->baseh, c->minh);
    if (c->maxw)
      *w = MIN(*w, c->maxw);
    if (c->maxh)
      *h = MIN(*h, c->maxh);
  }
  return *x != c->x || *y != c->y || *w != c->w || *h != c->h;
}

void arrange(Monitor *m) {
  if (m)
    showhide(m->stack);
  else
    for (m = mons; m; m = m->next)
      showhide(m->stack);
  if (m) {
    arrangemon(m);
    restack(m);
  } else
    for (m = mons; m; m = m->next)
      arrangemon(m);
}

void arrangemon(Monitor *m) {
  strncpy(m->ltsymbol, m->lt[m->sellt]->symbol, sizeof m->ltsymbol);
  if (m->lt[m->sellt]->arrange)
    m->lt[m->sellt]->arrange(m);
}

void attach(Client *c) {
  c->next         = c->mon->clients;
  c->mon->clients = c;
  log_info("[In attach] attaching client '%s'", c->name);
}

void attachbottom(Client *c) {
  Client **tc;
  c->next = NULL;
  for (tc = &c->mon->clients; *tc; tc = &(*tc)->next)
    ;
  *tc = c;
  log_info("[In attachbottom] attaching client '%s'", c->name);
}

void attachstack(Client *c) {
  c->snext      = c->mon->stack;
  c->mon->stack = c;
  log_info("[In attachstack] attaching client '%s'", c->name);
}

void buttonpress(XEvent *e) {
  log_info("[In buttonpress handler] got even num '%d' with button '%s", e->type, e->xbutton);
  unsigned int i, x, click, occ = 0;
  Arg arg = {0};
  Client *c;
  Monitor *m;
  XButtonPressedEvent *ev = &e->xbutton;

  click = ClkRootWin;
  /* focus monitor if necessary */
  if ((m = wintomon(ev->window)) && m != selmon) {
    unfocus(selmon->sel, 1);
    selmon = m;
    focus(NULL);
  }
  if (ev->window == selmon->barwin) {
    if (selmon->previewshow) {
      XUnmapWindow(dpy, selmon->tagwin);
      selmon->previewshow = 0;
    }
    i = x = 0;
    for (c = m->clients; c; c = c->next)
      occ |= c->tags == 255 ? 0 : c->tags;
    do {
      /* do not reserve space for vacant tags */
      if (!(occ & 1 << i || m->tagset[m->seltags] & 1 << i))
        continue;
      x += TEXTW(tags[i]);
    } while (ev->x >= x && ++i < LENGTH(tags));
    if (i < LENGTH(tags)) {
      click  = ClkTagBar;
      arg.ui = 1 << i;
    } else if (ev->x < x + TEXTW(selmon->ltsymbol))
      click = ClkLtSymbol;
    else if (ev->x > selmon->ww - statusw + lrpad - 2) {
      /* 2px right padding */

      x     = selmon->ww - statusw;
      click = ClkStatusText;

      char *text, *s, ch;
      statussig = 0;
      for (text = s = stext; *s && x <= ev->x; s++) {
        if ((unsigned char)(*s) < ' ') {
          ch = *s;
          *s = '\0';
          x += TEXTW(text) - lrpad;
          *s   = ch;
          text = s + 1;
          if (x >= ev->x)
            break;
          statussig = ch;
        } else if (*s == '^') {
          *s = '\0';
          x += TEXTW(text) - lrpad;
          *s = '^';
          if (*(++s) == 'f')
            x += atoi(++s);
          while (*(s++) != '^')
            ;
          text = s;
          s--;
        }
      }
    } else {
      x += TEXTW(selmon->ltsymbol);
      c = m->clients;

      if (c) {
        do {
          if (!ISVISIBLE(c))
            continue;
          else
            x += (1.0 / (double)m->bt) * m->btw;
        } while (ev->x > x && (c = c->next));

        click = ClkWinTitle;
        arg.v = c;
      }
    }
  } else if ((c = wintoclient(ev->window))) {
    focus(c);
    restack(selmon);
    XAllowEvents(dpy, ReplayPointer, CurrentTime);
    click = ClkClientWin;
  }
  for (i = 0; i < LENGTH(buttons); i++)
    if (click == buttons[i].click && buttons[i].func && buttons[i].button == ev->button && CLEANMASK(buttons[i].mask) == CLEANMASK(ev->state))
      buttons[i].func((click == ClkTagBar || click == ClkWinTitle) && buttons[i].arg.i == 0 ? &arg : &buttons[i].arg);
}

void checkotherwm(void) {
  xerrorxlib = XSetErrorHandler(xerrorstart);
  /* this causes an error if some other window manager is running */
  XSelectInput(dpy, DefaultRootWindow(dpy), SubstructureRedirectMask);
  XSync(dpy, False);
  XSetErrorHandler(xerror);
  XSync(dpy, False);
}

void cleanup(void) {
  Arg a      = {.ui = ~0};
  Layout foo = {"", NULL};
  Monitor *m;
  size_t i;

  view(&a);
  selmon->lt[selmon->sellt] = &foo;
  for (m = mons; m; m = m->next)
    while (m->stack)
      unmanage(m->stack, 0);
  XUngrabKey(dpy, AnyKey, AnyModifier, root);
  while (mons)
    cleanupmon(mons);
  if (showsystray) {
    XUnmapWindow(dpy, systray->win);
    XDestroyWindow(dpy, systray->win);
    free(systray);
  }
  for (i = 0; i < CurLast; i++)
    drw_cur_free(drw, cursor[i]);
  for (i = 0; i < LENGTH(colors) + 1; i++)
    free(scheme[i]);
  free(scheme);
  XDestroyWindow(dpy, wmcheckwin);
  drw_free(drw);
  XSync(dpy, False);
  XSetInputFocus(dpy, PointerRoot, RevertToPointerRoot, CurrentTime);
  XDeleteProperty(dpy, root, netatom[NetActiveWindow]);
}

void cleanupmon(Monitor *mon) {
  Monitor *m;
  size_t i;

  if (mon == mons)
    mons = mons->next;
  else {
    for (m = mons; m && m->next != mon; m = m->next)
      ;
    m->next = mon->next;
  }
  for (i = 0; i < LENGTH(tags); i++)
    if (mon->tagmap[i])
      XFreePixmap(dpy, mon->tagmap[i]);
  XUnmapWindow(dpy, mon->barwin);
  XDestroyWindow(dpy, mon->barwin);
  XUnmapWindow(dpy, mon->tagwin);
  XDestroyWindow(dpy, mon->tagwin);
  free(mon);
}

void clientmessage(XEvent *e) {
  XWindowAttributes wa;
  XSetWindowAttributes swa;
  XClientMessageEvent *cme = &e->xclient;
  Client *c                = wintoclient(cme->window);
  unsigned int i;

  if (showsystray && cme->window == systray->win && cme->message_type == netatom[NetSystemTrayOP]) {
    /* add systray icons */
    if (cme->data.l[1] == SYSTEM_TRAY_REQUEST_DOCK) {
      if (!(c = (Client *)calloc(1, sizeof(Client))))
        die("fatal: could not malloc() %u bytes\n", sizeof(Client));
      if (!(c->win = cme->data.l[2])) {
        free(c);
        return;
      }
      c->mon         = selmon;
      c->next        = systray->icons;
      systray->icons = c;
      if (!XGetWindowAttributes(dpy, c->win, &wa)) {
        /* use sane defaults */
        wa.width        = bh;
        wa.height       = bh;
        wa.border_width = 0;
      }
      c->x = c->oldx = c->y = c->oldy = 0;
      c->w = c->oldw = wa.width;
      c->h = c->oldh = wa.height;
      c->oldbw       = wa.border_width;
      c->bw          = 0;
      c->isfloating  = True;
      /* reuse tags field as mapped status */
      c->tags = 1;
      updatesizehints(c);
      updatesystrayicongeom(c, wa.width, wa.height);
      XAddToSaveSet(dpy, c->win);
      XSelectInput(dpy, c->win, StructureNotifyMask | PropertyChangeMask | ResizeRedirectMask);
      XReparentWindow(dpy, c->win, systray->win, 0, 0);
      /* use parents background color */
      swa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
      XChangeWindowAttributes(dpy, c->win, CWBackPixel, &swa);
      sendevent(c->win, netatom[Xembed], StructureNotifyMask, CurrentTime, XEMBED_EMBEDDED_NOTIFY, 0, systray->win, XEMBED_EMBEDDED_VERSION);
      /* FIXME not sure if I have to send these events, too */
      sendevent(c->win, netatom[Xembed], StructureNotifyMask, CurrentTime, XEMBED_FOCUS_IN, 0, systray->win, XEMBED_EMBEDDED_VERSION);
      sendevent(c->win, netatom[Xembed], StructureNotifyMask, CurrentTime, XEMBED_WINDOW_ACTIVATE, 0, systray->win, XEMBED_EMBEDDED_VERSION);
      sendevent(c->win, netatom[Xembed], StructureNotifyMask, CurrentTime, XEMBED_MODALITY_ON, 0, systray->win, XEMBED_EMBEDDED_VERSION);
      XSync(dpy, False);
      resizebarwin(selmon);
      updatesystray();
      setclientstate(c, NormalState);
    }
    return;
  }
  if (!c)
    return;
  if (cme->message_type == netatom[NetWMState]) {
    if (cme->data.l[1] == netatom[NetWMFullscreen] || cme->data.l[2] == netatom[NetWMFullscreen]) {
      if (c->fakefullscreen == 2 && c->isfullscreen)
        c->fakefullscreen = 3;
      setfullscreen(c, (cme->data.l[0] == 1 /* _NET_WM_STATE_ADD    */
                        || (cme->data.l[0] == 2 /* _NET_WM_STATE_TOGGLE */ && !c->isfullscreen)));
    }
    if (cme->data.l[1] == netatom[NetWMSticky] || cme->data.l[2] == netatom[NetWMSticky])
      setsticky(c, (cme->data.l[0] == 1 || (cme->data.l[0] == 2 && !c->issticky)));
  } else if (cme->message_type == netatom[NetActiveWindow]) {
    for (i = 0; i < LENGTH(tags) && !((1 << i) & c->tags); i++)
      ;
    if (i < LENGTH(tags)) {
      const Arg a = {.ui = 1 << i};
      selmon      = c->mon;
      view(&a);
      focus(c);
      restack(selmon);
    }
  }
}

void configure(Client *c) {
  XConfigureEvent ce;

  ce.type              = ConfigureNotify;
  ce.display           = dpy;
  ce.event             = c->win;
  ce.window            = c->win;
  ce.x                 = c->x;
  ce.y                 = c->y;
  ce.width             = c->w;
  ce.height            = c->h;
  ce.border_width      = c->bw;
  ce.above             = None;
  ce.override_redirect = False;
  XSendEvent(dpy, c->win, False, StructureNotifyMask, (XEvent *)&ce);
}

void configurenotify(XEvent *e) {
  Monitor *m;
  Client *c;
  XConfigureEvent *ev = &e->xconfigure;
  int dirty;
  /* TODO: updategeom handling sucks, needs to be simplified */
  if (ev->window == root) {
    dirty = (sw != ev->width || sh != ev->height);
    sw    = ev->width;
    sh    = ev->height;
    if (updategeom() || dirty) {
      drw_resize(drw, sw, bh);
      updatebars();
      for (m = mons; m; m = m->next) {
        for (c = m->clients; c; c = c->next)
          if (c->isfullscreen && c->fakefullscreen != 1)
            resizeclient(c, m->mx, m->my, m->mw, m->mh);
        resizebarwin(m);
      }
      focus(NULL);
      arrange(NULL);
    }
  } else {
    log_info("[In configurenotify] got even num '%d' for none root window. Do nothing", e->type);
  }
}

void configurerequest(XEvent *e) {
  Client *c;
  Monitor *m;
  XConfigureRequestEvent *ev = &e->xconfigurerequest;
  XWindowChanges wc;

  if ((c = wintoclient(ev->window))) {
    if (ev->value_mask & CWBorderWidth)
      c->bw = ev->border_width;
    else if (c->isfloating || !selmon->lt[selmon->sellt]->arrange) {
      if (c->ignorecfgreqpos && c->ignorecfgreqsize)
        return;

      m = c->mon;
      if (!c->issteam) {
        if (!c->ignorecfgreqpos) {
          if (ev->value_mask & CWX) {
            c->oldx = c->x;
            c->x    = m->mx + ev->x;
          }
          if (ev->value_mask & CWY) {
            c->oldy = c->y;
            c->y    = m->my + ev->y;
          }
        }
      }
      if (!c->ignorecfgreqsize) {
        if (ev->value_mask & CWWidth) {
          c->oldw = c->w;
          c->w    = ev->width;
        }
        if (ev->value_mask & CWHeight) {
          c->oldh = c->h;
          c->h    = ev->height;
        }
      }
      if ((c->x + c->w) > m->mx + m->mw && c->isfloating)
        c->x = m->mx + (m->mw / 2 - WIDTH(c) / 2); /* center in x direction */
      if ((c->y + c->h) > m->my + m->mh && c->isfloating)
        c->y = m->my + (m->mh / 2 - HEIGHT(c) / 2); /* center in y direction */
      if ((ev->value_mask & (CWX | CWY)) && !(ev->value_mask & (CWWidth | CWHeight)))
        configure(c);
      if (ISVISIBLE(c))
        XMoveResizeWindow(dpy, c->win, c->x, c->y, c->w, c->h);
    } else
      configure(c);
  } else {
    wc.x            = ev->x;
    wc.y            = ev->y;
    wc.width        = ev->width;
    wc.height       = ev->height;
    wc.border_width = ev->border_width;
    wc.sibling      = ev->above;
    wc.stack_mode   = ev->detail;
    XConfigureWindow(dpy, ev->window, ev->value_mask, &wc);
  }
  XSync(dpy, False);
}

Monitor *createmon(void) {
  Monitor *m, *mon;
  int i, mi, j, layout;
  const MonitorRule *mr;

  m            = ecalloc(1, sizeof(Monitor));
  m->tagset[0] = m->tagset[1] = 1;
  m->mfact                    = mfact;
  m->nmaster                  = nmaster;
  m->showbar                  = showbar;
  m->topbar                   = topbar;
  m->gappih                   = gappih;
  m->gappiv                   = gappiv;
  m->gappoh                   = gappoh;
  m->gappov                   = gappov;
  m->pertag                   = ecalloc(1, sizeof(Pertag));

  for (mi = 0, mon = mons; mon; mon = mon->next, mi++)
    ;
  for (j = 0; j < LENGTH(monrules); j++) {
    mr = &monrules[j];
    if ((mr->monitor == -1 || mr->monitor == mi) && (mr->tag <= 0 || (m->tagset[0] & (1 << (mr->tag - 1))))) {
      layout   = MAX(mr->layout, 0);
      layout   = MIN(layout, LENGTH(layouts) - 1);
      m->lt[0] = &layouts[layout];
      m->lt[1] = &layouts[1 % LENGTH(layouts)];
      strncpy(m->ltsymbol, layouts[layout].symbol, sizeof m->ltsymbol);

      if (mr->mfact > -1)
        m->mfact = mr->mfact;
      if (mr->nmaster > -1)
        m->nmaster = mr->nmaster;
      if (mr->showbar > -1)
        m->showbar = mr->showbar;
      if (mr->topbar > -1)
        m->topbar = mr->topbar;
      break;
    }
  }

  if (!(m->pertag = (Pertag *)calloc(1, sizeof(Pertag))))
    die("fatal: could not malloc() %u bytes\n", sizeof(Pertag));
  m->pertag->curtag = m->pertag->prevtag = 1;

  for (i = 0; i <= LENGTH(tags); i++) {
    /* init layouts */
    m->pertag->enablegaps[i] = 1;
    m->pertag->sellts[i]     = m->sellt;
    m->pertag->showbars[i]   = m->showbar;
#if ZOOMSWAP_PATCH
    m->pertag->prevzooms[i] = NULL;
#endif // ZOOMSWAP_PATCH

    for (j = 0; j < LENGTH(monrules); j++) {
      mr = &monrules[j];
      if ((mr->monitor == -1 || mr->monitor == mi) && (mr->tag == -1 || mr->tag == i)) {
        layout                  = MAX(mr->layout, 0);
        layout                  = MIN(layout, LENGTH(layouts) - 1);
        m->pertag->ltidxs[i][0] = &layouts[layout];
        m->pertag->ltidxs[i][1] = m->lt[0];
        m->pertag->nmasters[i]  = (mr->nmaster > -1 ? mr->nmaster : m->nmaster);
        m->pertag->mfacts[i]    = (mr->mfact > -1 ? mr->mfact : m->mfact);
        m->pertag->showbars[i]  = (mr->showbar > -1 ? mr->showbar : m->showbar);
        break;
      }
    }
  }

  return m;
}

void cyclelayout(const Arg *arg) {
  Layout *l;
  for (l = (Layout *)layouts; l != selmon->lt[selmon->sellt]; l++)
    ;
  if (arg->i > 0) {
    if (l->symbol && (l + 1)->symbol)
      setlayout(&((Arg){.v = (l + 1)}));
    else
      setlayout(&((Arg){.v = layouts}));
  } else {
    if (l != layouts && (l - 1)->symbol)
      setlayout(&((Arg){.v = (l - 1)}));
    else
      setlayout(&((Arg){.v = &layouts[LENGTH(layouts) - 2]}));
  }
}

void destroynotify(XEvent *e) {
  Client *c;
  XDestroyWindowEvent *ev = &e->xdestroywindow;

  if ((c = wintoclient(ev->window)))
    unmanage(c, 1);
  else if ((c = swallowingclient(ev->window)))
    unmanage(c->swallowing, 1);
  else if ((c = wintosystrayicon(ev->window))) {
    removesystrayicon(c);
    resizebarwin(selmon);
    updatesystray();
  }
}

void detach(Client *c) {
  Client **tc;

  for (tc = &c->mon->clients; *tc && *tc != c; tc = &(*tc)->next)
    ;
  *tc = c->next;
}

void detachstack(Client *c) {
  Client **tc, *t;

  for (tc = &c->mon->stack; *tc && *tc != c; tc = &(*tc)->snext)
    ;
  *tc = c->snext;

  if (c == c->mon->sel) {
    for (t = c->mon->stack; t && !ISVISIBLE(t); t = t->snext)
      ;
    c->mon->sel = t;
  }
}

Monitor *dirtomon(int dir) {
  Monitor *m = NULL;

  if (dir > 0) {
    if (!(m = selmon->next))
      m = mons;
  } else if (selmon == mons)
    for (m = mons; m->next; m = m->next)
      ;
  else
    for (m = mons; m->next != selmon; m = m->next)
      ;
  return m;
}

int drawstatusbar(Monitor *m, int bh, char *stext, int stw) {
  int ret, i, j, w, x, len;
  short isCode = 0;
  char *text;
  char *p;

  len = strlen(stext) + 1;
  if (!(text = (char *)malloc(sizeof(char) * len)))
    die("malloc");
  p = text;

  i = -1, j = 0;
  while (stext[++i])
    if ((unsigned char)stext[i] >= ' ')
      text[j++] = stext[i];
  text[j] = '\0';

  /* compute width of the status text */
  w = 0;
  i = -1;
  while (text[++i]) {
    if (text[i] == '^') {
      if (!isCode) {
        isCode  = 1;
        text[i] = '\0';
        w += TEXTW(text) - lrpad;
        text[i] = '^';
        if (text[++i] == 'f')
          w += atoi(text + ++i);
      } else {
        isCode = 0;
        text   = text + i + 1;
        i      = -1;
      }
    }
  }
  if (!isCode)
    w += TEXTW(text) - lrpad;
  else
    isCode = 0;
  text = p;

  w += 2; /* 1px padding on both sides */
  ret = x = m->ww - w;

  drw_setscheme(drw, scheme[LENGTH(colors)]);
  drw->scheme[ColFg] = scheme[SchemeNorm][ColFg];
  drw->scheme[ColBg] = scheme[SchemeNorm][ColBg];
  drw_rect(drw, x, 0, w, bh, 1, 1);
  x++;

  /* process status text */
  i = -1;
  while (text[++i]) {
    if (text[i] == '^' && !isCode) {
      isCode = 1;

      text[i] = '\0';
      w       = TEXTW(text) - lrpad;
      drw_text(drw, x - stw, 0, w, bh, 0, text, 0);

      x += w;

      /* process code */
      while (text[++i] != '^') {
        if (text[i] == 'c') {
          char buf[8];
          memcpy(buf, (char *)text + i + 1, 7);
          buf[7] = '\0';
          drw_clr_create(drw, &drw->scheme[ColFg], buf);
          i += 7;
        } else if (text[i] == 'b') {
          char buf[8];
          memcpy(buf, (char *)text + i + 1, 7);
          buf[7] = '\0';
          drw_clr_create(drw, &drw->scheme[ColBg], buf);
          i += 7;
        } else if (text[i] == 'd') {
          drw->scheme[ColFg] = scheme[SchemeNorm][ColFg];
          drw->scheme[ColBg] = scheme[SchemeNorm][ColBg];
        } else if (text[i] == 'r') {
          int rx = atoi(text + ++i);
          while (text[++i] != ',')
            ;
          int ry = atoi(text + ++i);
          while (text[++i] != ',')
            ;
          int rw = atoi(text + ++i);
          while (text[++i] != ',')
            ;
          int rh = atoi(text + ++i);

          drw_rect(drw, rx + x, ry, rw, rh, 1, 0);
        } else if (text[i] == 'f') {
          x += atoi(text + ++i);
        }
      }

      text   = text + i + 1;
      i      = -1;
      isCode = 0;
    }
  }

  if (!isCode) {
    w = TEXTW(text) - lrpad;
    drw_text(drw, x - stw, 0, w, bh, 0, text, 0);
  }

  drw_setscheme(drw, scheme[SchemeNorm]);
  free(p);

  return ret;
}

void drawbar(Monitor *m) {
  // drw_text(
  //    drw,        - the drawable
  //    m->ww - tw, - the x position
  //    0,          - the y position
  //    tw,         - the width
  //    bh,         - the height
  //    0,          - left padding (typically lrpad / 2)
  //    stext,      - the text to be drawn
  //    0           - inverted (swaps foreground and background colours)
  // );
  
  // system_tray_width or stw
  int x, w, sw = 0, system_tray_width = 0, n = 0, scm;
  int boxs = drw->fonts->h / 9;
  int boxw = drw->fonts->h / 6 + 2;
  int tab_pad = 20;
  unsigned int i, occ = 0, urg = 0;
  Client *c;

  if (showsystray && m == systraytomon(m))
    system_tray_width = getsystraywidth();

  if (!m->showbar)
    return;
  /* draw status first so it can be overdrawn by tags later */
  if (m == selmon) { /* status is only drawn on selected monitor */
    statusw = sw = m->ww - drawstatusbar(m, bh, stext, system_tray_width) - 1;
  }

  resizebarwin(m);
  for (c = m->clients; c; c = c->next) {
    if (ISVISIBLE(c))
      n++;
    occ |= c->tags == 255 ? 0 : c->tags;
    if (c->isurgent)
      urg |= c->tags;
  }
  x = 0;
  // Draw tags
  for (i = 0; i < LENGTH(tags); i++) {
    /* do not draw vacant tags */
    if (!(occ & 1 << i || m->tagset[m->seltags] & 1 << i))
      continue;

    w = TEXTW(tags[i]);

    /* draw color based on urgent windows */
    if (m->tagset[m->seltags] & 1 << i) {
      drw_setscheme(drw, scheme[SchemeSel]);
    } else if (urg & 1 << i) {
      drw_setscheme(drw, scheme[SchemeUrg]);
    } else {
      drw_setscheme(drw, scheme[SchemeNorm]);
    }
    drw_text(drw, x, 0, w, bh, lrpad / 2, tags[i], 0);
    x += w;
  }
  w = TEXTW(m->ltsymbol);
  drw_setscheme(drw, scheme[SchemeSym]);
  x = drw_text(drw, x, 0, w, bh, 0, m->ltsymbol, 0);

  drw_setscheme(drw, scheme[SchemeNorm]);
  drw_text(drw, x, 0, tab_pad, bh, lrpad / 2, "", 0);
  x += tab_pad;

  if ((w = m->ww - sw - system_tray_width - x) > bh) {
    if (n > 0) {
      int remainder = w % n;
      int tabw      = (1.0 / (double)n) * w + 1;
      tabw -= tab_pad;
      for (c = m->clients; c; c = c->next) {
        if (!ISVISIBLE(c))
          continue;
        if (m->sel == c)
          scm = SchemeSel;
        else if (HIDDEN(c))
          scm = SchemeHid;
        else
          scm = SchemeTab;
        drw_setscheme(drw, scheme[scm]);

        if (remainder >= 0) {
          if (remainder == 0) {
            tabw--;
          }
          remainder--;
        }
        drw_text(drw, x, 0, tabw, bh, lrpad / 2, c->name, 0);
        x += tabw;

        drw_setscheme(drw, scheme[SchemeNorm]);
        drw_text(drw, x, 0, tab_pad, bh, 0, "", 0);
        x += tab_pad;
      }
    } else {
      drw_setscheme(drw, scheme[SchemeNorm]);
      drw_rect(drw, x, 0, w, bh, 1, 1);
    }
  }
  m->bt  = n;
  m->btw = w;
  drw_map(drw, m->barwin, 0, 0, m->ww - system_tray_width, bh);
}

void drawbars(void) {
  Monitor *m;

  for (m = mons; m; m = m->next)
    drawbar(m);
}

void enternotify(XEvent *e) {
  Client *c;
  Monitor *m;
  XCrossingEvent *ev = &e->xcrossing;

  if ((ev->mode != NotifyNormal || ev->detail == NotifyInferior) && ev->window != root)
    return;
  c = wintoclient(ev->window);
  m = c ? c->mon : wintomon(ev->window);
  if (m != selmon) {
    unfocus(selmon->sel, 1);
    selmon = m;
  } else if (!c || c == selmon->sel)
    return;
  focus(c);
}

void expose(XEvent *e) {
  Monitor *m;
  XExposeEvent *ev = &e->xexpose;

  if (ev->count == 0 && (m = wintomon(ev->window))) {
    drawbar(m);
    if (m == selmon)
      updatesystray();
  }
}

/* there are some broken focus acquiring clients needing extra handling */
void focusin(XEvent *e) {
  XFocusChangeEvent *ev = &e->xfocus;

  if (selmon->sel && ev->window != selmon->sel->win)
    setfocus(selmon->sel);
}

void focusmon(const Arg *arg) {
  Monitor *m;

  if (!mons->next)
    return;
  if ((m = dirtomon(arg->i)) == selmon)
    return;
  unfocus(selmon->sel, 0);
  selmon = m;
  focus(NULL);
  warp(selmon->sel);
}

focusstackvis(const Arg *arg) { focusstack(arg->i, 0); }

void focusstackhid(const Arg *arg) { focusstack(arg->i, 1); }

void focusstack(int inc, int hid) {
  Client *c = NULL, *i;

  // if no client selected AND exclude hidden client; if client selected but fullscreened
  if ((!selmon->sel && !hid) || (selmon->sel && selmon->sel->isfullscreen && lockfullscreen))
    return;
  if (!selmon->clients)
    return;
  if (inc > 0) {
    if (selmon->sel)
      for (c = selmon->sel->next; c && (!ISVISIBLE(c) || (!hid && HIDDEN(c))); c = c->next)
        ;
    if (!c)
      for (c = selmon->clients; c && (!ISVISIBLE(c) || (!hid && HIDDEN(c))); c = c->next)
        ;
  } else {
    if (selmon->sel) {
      for (i = selmon->clients; i != selmon->sel; i = i->next)
        if (ISVISIBLE(i) && !(!hid && HIDDEN(i)))
          c = i;
    } else
      c = selmon->clients;
    if (!c)
      for (; i; i = i->next)
        if (ISVISIBLE(i) && !(!hid && HIDDEN(i)))
          c = i;
  }
  if (c) {
    focus(c);
    restack(selmon);
    if (HIDDEN(c)) {
      showwin(c);
      c->mon->hidsel = 1;
    }
  }
}

Atom getatomprop(Client *c, Atom prop) {
  int di;
  unsigned long dl;
  unsigned char *p = NULL;
  Atom da, atom = None;
  /* FIXME getatomprop should return the number of items and a pointer to
   * the stored data instead of this workaround */
  Atom req = XA_ATOM;
  if (prop == xatom[XembedInfo])
    req = xatom[XembedInfo];

  if (XGetWindowProperty(dpy, c->win, prop, 0L, sizeof atom, False, req, &da, &di, &dl, &dl, &p) == Success && p) {
    atom = *(Atom *)p;
    if (da == xatom[XembedInfo] && dl == 2)
      atom = ((Atom *)p)[1];
    XFree(p);
  }
  return atom;
}

pid_t getstatusbarpid() {
  char buf[32], *str = buf, *c;
  FILE *fp;

  if (statuspid > 0) {
    snprintf(buf, sizeof(buf), "/proc/%u/cmdline", statuspid);
    if ((fp = fopen(buf, "r"))) {
      fgets(buf, sizeof(buf), fp);
      while ((c = strchr(str, '/')))
        str = c + 1;
      fclose(fp);
      if (!strcmp(str, "dwmblock"))
        return statuspid;
    }
  }
  if (!(fp = popen("pgrep -o dwmblock", "r")))
    return -1;
  fgets(buf, sizeof(buf), fp);
  pclose(fp);
  return strtoul(buf, NULL, 10);
}

int getrootptr(int *x, int *y) {
  int di;
  unsigned int dui;
  Window dummy;

  return XQueryPointer(dpy, root, &dummy, &dummy, x, y, &di, &di, &dui);
}

long getstate(Window w) {
  int format;
  long result      = -1;
  unsigned char *p = NULL;
  unsigned long n, extra;
  Atom real;

  if (XGetWindowProperty(dpy, w, wmatom[WMState], 0L, 2L, False, wmatom[WMState], &real, &format, &n, &extra, (unsigned char **)&p) != Success)
    return -1;
  if (n != 0)
    result = *p;
  XFree(p);
  return result;
}

unsigned int getsystraywidth() {
  unsigned int w = 0;
  Client *i;
  if (showsystray)
    for (i = systray->icons; i; w += i->w + systrayspacing, i = i->next)
      ;
  return w ? w + systrayspacing : 1;
}

int gettextprop(Window w, Atom atom, char *text, unsigned int size) {
  char **list = NULL;
  int n;
  XTextProperty name;

  if (!text || size == 0)
    return 0;
  text[0] = '\0';
  if (!XGetTextProperty(dpy, w, &name, atom) || !name.nitems)
    return 0;
  if (name.encoding == XA_STRING)
    strncpy(text, (char *)name.value, size - 1);
  else {
    if (XmbTextPropertyToTextList(dpy, &name, &list, &n) >= Success && n > 0 && *list) {
      strncpy(text, *list, size - 1);
      XFreeStringList(list);
    }
  }
  text[size - 1] = '\0';
  XFree(name.value);
  return 1;
}

void grabbuttons(Client *c, int focused) {
  updatenumlockmask();
  {
    unsigned int i, j;
    unsigned int modifiers[] = {0, LockMask, numlockmask, numlockmask | LockMask};
    XUngrabButton(dpy, AnyButton, AnyModifier, c->win);
    if (!focused)
      XGrabButton(dpy, AnyButton, AnyModifier, c->win, False, BUTTONMASK, GrabModeSync, GrabModeSync, None, None);
    for (i = 0; i < LENGTH(buttons); i++)
      if (buttons[i].click == ClkClientWin)
        for (j = 0; j < LENGTH(modifiers); j++)
          XGrabButton(dpy, buttons[i].button, buttons[i].mask | modifiers[j], c->win, False, BUTTONMASK, GrabModeAsync, GrabModeSync, None, None);
  }
}

void grabkeys(void) {
  updatenumlockmask();
  {
    unsigned int i, j, k;
    unsigned int modifiers[] = {0, LockMask, numlockmask, numlockmask | LockMask};
    int start, end, skip;
    KeySym *syms;

    XUngrabKey(dpy, AnyKey, AnyModifier, root);
    XDisplayKeycodes(dpy, &start, &end);
    syms = XGetKeyboardMapping(dpy, start, end - start + 1, &skip);
    if (!syms)
      return;
    for (k = start; k <= end; k++)
      for (i = 0; i < LENGTH(keys); i++)
        /* skip modifier codes, we do that ourselves */
        if (keys[i].keysym == syms[(k - start) * skip])
          for (j = 0; j < LENGTH(modifiers); j++)
            XGrabKey(dpy, k, keys[i].mod | modifiers[j], root, True, GrabModeAsync, GrabModeAsync);
    XFree(syms);
  }
}

void incnmaster(const Arg *arg) {
  selmon->nmaster = selmon->pertag->nmasters[selmon->pertag->curtag] = MAX(selmon->nmaster + arg->i, 0);
  arrange(selmon);
}

#ifdef XINERAMA
int isuniquegeom(XineramaScreenInfo *unique, size_t n, XineramaScreenInfo *info) {
  while (n--)
    if (unique[n].x_org == info->x_org && unique[n].y_org == info->y_org && unique[n].width == info->width && unique[n].height == info->height)
      return 0;
  return 1;
}
#endif /* XINERAMA */

void keypress(XEvent *e) {
  unsigned int i;
  KeySym keysym;
  XKeyEvent *ev;

  log_info("[In keypress] Got keypress event");
  ev     = &e->xkey;
  keysym = XKeycodeToKeysym(dpy, (KeyCode)ev->keycode, 0);
  log_info("[In keypress] Got key code = %ld", keysym);
  for (i = 0; i < LENGTH(keys); i++)
    if (keysym == keys[i].keysym && CLEANMASK(keys[i].mod) == CLEANMASK(ev->state) && keys[i].func)
      keys[i].func(&(keys[i].arg));
}

void killclient(const Arg *arg) {
  if (!selmon->sel)
    return;
  if (!sendevent(selmon->sel->win, wmatom[WMDelete], NoEventMask, wmatom[WMDelete], CurrentTime, 0, 0, 0)) {
    XGrabServer(dpy);
    XSetErrorHandler(xerrordummy);
    XSetCloseDownMode(dpy, DestroyAll);
    XKillClient(dpy, selmon->sel->win);
    XSync(dpy, False);
    XSetErrorHandler(xerror);
    XUngrabServer(dpy);
  }
}

void manage(Window w, XWindowAttributes *wa) {
  Client *c, *t = NULL, *term = NULL;
  Window trans = None;
  XWindowChanges wc;
  int focusclient = 1;
  log_info("[In manage] got request to manage windwow %ld", w);

  c      = ecalloc(1, sizeof(Client));
  c->win = w;
  c->pid = winpid(w);
  /* geometry */
  c->x = c->oldx = wa->x;
  c->y = c->oldy = wa->y;
  c->w = c->oldw = wa->width;
  c->h = c->oldh = wa->height;
  c->oldbw       = wa->border_width;
  c->cfact       = 1.0;

  updatetitle(c);
  if (XGetTransientForHint(dpy, w, &trans) && (t = wintoclient(trans))) {
    c->mon  = t->mon;
    c->tags = t->tags;
  } else {
    c->mon = selmon;
    applyrules(c);
    term = termforwin(c);
  }
  if (c->x + WIDTH(c) > c->mon->wx + c->mon->ww)
    c->x = c->mon->wx + c->mon->ww - WIDTH(c);
  if (c->y + HEIGHT(c) > c->mon->wy + c->mon->wh)
    c->y = c->mon->wy + c->mon->wh - HEIGHT(c);
  c->x  = MAX(c->x, c->mon->wx);
  c->y  = MAX(c->y, c->mon->wy);
  c->bw = borderpx;
  if (c->issteam) {
    c->bw = 0;
  }

  wc.border_width = c->bw;
  XConfigureWindow(dpy, w, CWBorderWidth, &wc);
  XSetWindowBorder(dpy, w, scheme[SchemeNorm][ColBorder].pixel);
  configure(c); /* propagates border_width, if size doesn't change */
  updatewindowtype(c);
  updatesizehints(c);
  updatewmhints(c);
  c->x = c->mon->mx + (c->mon->mw - WIDTH(c)) / 2;
  c->y = c->mon->my + (c->mon->mh - HEIGHT(c)) / 2;
  XSelectInput(dpy, w, EnterWindowMask | FocusChangeMask | PropertyChangeMask | StructureNotifyMask);
  grabbuttons(c, 0);
  if (!c->isfloating)
    c->isfloating = c->oldstate = trans != None || c->isfixed;
  if (c->isfloating)
    XRaiseWindow(dpy, c->win);

  /* Do not attach client if it is being swallowed */
  if (term && swallow(term, c)) {
    /* Do not let swallowed client steal focus unless the terminal has focus */
    focusclient = (term == selmon->sel);
  } else {
    attachbottom(c);

    if (focusclient || !c->mon->sel || !c->mon->stack)
      attachstack(c);
    else {
      c->snext           = c->mon->sel->snext;
      c->mon->sel->snext = c;
    }
  }

  XChangeProperty(dpy, root, netatom[NetClientList], XA_WINDOW, 32, PropModeAppend, (unsigned char *)&(c->win), 1);
  XMoveResizeWindow(dpy, c->win, c->x + 2 * sw, c->y, c->w, c->h); /* some windows require this */
  if (!HIDDEN(c))
    setclientstate(c, NormalState);
  if (focusclient) {
    if (c->mon == selmon) {
      unfocus(selmon->sel, 0);
      losefullscreen(c);
    }
    c->mon->sel = c;
  }
  arrange(c->mon);
  if (!HIDDEN(c))
    XMapWindow(dpy, c->win);
  if (focusclient)
    focus(NULL);
}

void mappingnotify(XEvent *e) {
  XMappingEvent *ev = &e->xmapping;

  XRefreshKeyboardMapping(ev);
  if (ev->request == MappingKeyboard)
    grabkeys();
}

void maprequest(XEvent *e) {
  XWindowAttributes wa;
  XMapRequestEvent *ev = &e->xmaprequest;
  Client *i;
  if ((i = wintosystrayicon(ev->window))) {
    sendevent(i->win, netatom[Xembed], StructureNotifyMask, CurrentTime, XEMBED_WINDOW_ACTIVATE, 0, systray->win, XEMBED_EMBEDDED_VERSION);
    resizebarwin(selmon);
    updatesystray();
  }

  if (!XGetWindowAttributes(dpy, ev->window, &wa))
    return;
  if (wa.override_redirect)
    return;
  if (!wintoclient(ev->window))
    manage(ev->window, &wa);
}

void motionnotify(XEvent *e) {
  Monitor *mon = NULL;
  Monitor *m;
  Client *c;
  XMotionEvent *ev = &e->xmotion;
  unsigned int i, x, occ = 0;

  if ((m = recttomon(ev->x_root, ev->y_root, 1, 1)) != mon && mon) {
    unfocus(selmon->sel, 1);
    selmon = m;
    focus(NULL);
  }
  mon = m;

  if (ev->window == selmon->barwin) {
    i = x = 0;
    for (c = m->clients; c; c = c->next)
      occ |= c->tags == 255 ? 0 : c->tags;
    do {
      /* do not reserve space for vacant tags */
      if (!(occ & 1 << i || m->tagset[m->seltags] & 1 << i))
        continue;
      x += TEXTW(tags[i]);
    } while (ev->x >= x && ++i < LENGTH(tags));

    if (i < LENGTH(tags)) {
      if ((i + 1) != selmon->previewshow && !(selmon->tagset[selmon->seltags] & 1 << i)) {
        selmon->previewshow = i + 1;
        showtagpreview(i);
      } else if (selmon->tagset[selmon->seltags] & 1 << i) {
        selmon->previewshow = 0;
        showtagpreview(0);
      }
    } else if (selmon->previewshow != 0) {
      selmon->previewshow = 0;
      showtagpreview(0);
    }
  } else if (selmon->previewshow != 0) {
    selmon->previewshow = 0;
    showtagpreview(0);
  }
  if (ev->window != root)
    return;
}

void movemouse(const Arg *arg) {
  int x, y, ocx, ocy, nx, ny;
  Client *c;
  Monitor *m;
  XEvent ev;
  Time lasttime = 0;

  if (!(c = selmon->sel))
    return;
  if (c->isfullscreen && c->fakefullscreen != 1) /* no support moving fullscreen windows by mouse */
    return;
  restack(selmon);
  ocx = c->x;
  ocy = c->y;
  if (XGrabPointer(dpy, root, False, MOUSEMASK, GrabModeAsync, GrabModeAsync, None, cursor[CurMove]->cursor, CurrentTime) != GrabSuccess)
    return;
  if (!getrootptr(&x, &y))
    return;
  do {
    XMaskEvent(dpy, MOUSEMASK | ExposureMask | SubstructureRedirectMask, &ev);
    switch (ev.type) {
    case ConfigureRequest:
    case Expose:
    case MapRequest:
      handler[ev.type](&ev);
      break;
    case MotionNotify:
      if ((ev.xmotion.time - lasttime) <= (1000 / 60))
        continue;
      lasttime = ev.xmotion.time;

      nx = ocx + (ev.xmotion.x - x);
      ny = ocy + (ev.xmotion.y - y);
      if (abs(selmon->wx - nx) < snap)
        nx = selmon->wx;
      else if (abs((selmon->wx + selmon->ww) - (nx + WIDTH(c))) < snap)
        nx = selmon->wx + selmon->ww - WIDTH(c);
      if (abs(selmon->wy - ny) < snap)
        ny = selmon->wy;
      else if (abs((selmon->wy + selmon->wh) - (ny + HEIGHT(c))) < snap)
        ny = selmon->wy + selmon->wh - HEIGHT(c);
      if (!c->isfloating && selmon->lt[selmon->sellt]->arrange && (abs(nx - c->x) > snap || abs(ny - c->y) > snap))
        togglefloating(NULL);
      if (!selmon->lt[selmon->sellt]->arrange || c->isfloating)
        resize(c, nx, ny, c->w, c->h, 1);
      break;
    }
  } while (ev.type != ButtonRelease);
  XUngrabPointer(dpy, CurrentTime);
  if ((m = recttomon(c->x, c->y, c->w, c->h)) != selmon) {
    sendmon(c, m);
    selmon = m;
    focus(NULL);
  }
}

void movestack(const Arg *arg) {
  if (!selmon->sel)
    return;

  Client *c = NULL, *p = NULL, *pc = NULL, *i;

  if (arg->i > 0) {
    /* find the client after selmon->sel */
    for (c = selmon->sel->next; c && (!ISVISIBLE(c) || c->isfloating); c = c->next)
      ;
    if (!c)
      for (c = selmon->clients; c && (!ISVISIBLE(c) || c->isfloating); c = c->next)
        ;
  } else {
    /* find the client before selmon->sel */
    for (i = selmon->clients; i != selmon->sel; i = i->next)
      if (ISVISIBLE(i) && !i->isfloating)
        c = i;
    if (!c)
      for (; i; i = i->next)
        if (ISVISIBLE(i) && !i->isfloating)
          c = i;
  }
  /* find the client before selmon->sel and c */
  for (i = selmon->clients; i && (!p || !pc); i = i->next) {
    if (i->next == selmon->sel)
      p = i;
    if (i->next == c)
      pc = i;
  }

  /* swap c and selmon->sel selmon->clients in the selmon->clients list */
  if (c && c != selmon->sel) {
    Client *temp      = selmon->sel->next == c ? selmon->sel : selmon->sel->next;
    selmon->sel->next = c->next == selmon->sel ? c : c->next;
    c->next           = temp;

    if (p && p != c)
      p->next = c;
    if (pc && pc != selmon->sel)
      pc->next = selmon->sel;

    if (selmon->sel == selmon->clients)
      selmon->clients = c;
    else if (c == selmon->clients)
      selmon->clients = selmon->sel;

    arrange(selmon);
  }
}

Client *nexttiled(Client *c) {
  for (; c && (c->isfloating || !ISVISIBLE(c) || HIDDEN(c)); c = c->next)
    ;
  return c;
}

void pop(Client *c) {
  detach(c);
  attach(c);
  focus(c);
  arrange(c->mon);
}

void propertynotify(XEvent *e) {
  Client *c;
  Window trans;
  XPropertyEvent *ev = &e->xproperty;
  if (ev->window != root) {
    log_info("[In propertynotifyhandler] got even num=%d for window=%d", e->type, ev->window, ev->window);
  }

  if ((c = wintosystrayicon(ev->window))) {
    if (ev->atom == XA_WM_NORMAL_HINTS) {
      updatesizehints(c);
      updatesystrayicongeom(c, c->w, c->h);
    } else
      updatesystrayiconstate(c, ev);
    resizebarwin(selmon);
    updatesystray();
  }
  if ((ev->window == root) && (ev->atom == XA_WM_NAME))
    updatestatus();
  else if (ev->state == PropertyDelete)
    return; /* ignore */
  else if ((c = wintoclient(ev->window))) {
    log_info("[In propertynotifyhandler] got even num=%d client name='%s'", e->type, c->name);
    switch (ev->atom) {
    default:
      log_info("[In propertynotifyhandler] atom DEFAULT for client name='%s'", c->name);
      break;
    case XA_WM_TRANSIENT_FOR:
      log_info("[In propertynotifyhandler] atom XA_WM_TRANSIENT_FOR for client name='%s'", c->name);
      if (!c->isfloating && (XGetTransientForHint(dpy, c->win, &trans)) && (c->isfloating = (wintoclient(trans)) != NULL))
        arrange(c->mon);
      break;
    case XA_WM_NORMAL_HINTS:
      log_info("[In propertynotifyhandler] atom XA_WM_NORMAL_HINTS for client name='%s'", c->name);
      c->hintsvalid = 0;
      break;
    case XA_WM_HINTS:
      log_info("[In propertynotifyhandler] atom XA_WM_HINTS for client name='%s'", c->name);
      updatewmhints(c);
      drawbars();
      break;
    }
    if (ev->atom == XA_WM_NAME || ev->atom == netatom[NetWMName]) {
      log_info("[In propertynotifyhandler] atom XA_WM_NAME or NetWMName for client name='%s'", c->name);
      updatetitle(c);
      if (c == c->mon->sel)
        drawbar(c->mon);
    }
    if (ev->atom == netatom[NetWMWindowType]) {
      log_info("[In propertynotifyhandler] atom NetWMWindowType for client name='%s'", c->name);
      updatewindowtype(c);
    }
  }
}

void saveSession(void) {
  FILE *fw = fopen(SESSION_FILE, "w");
  for (Client *c = selmon->clients; c != NULL; c = c->next) { // get all the clients with their tags and write them to the file
    fprintf(fw, "%lu %u\n", c->win, c->tags);
  }
  fclose(fw);
}

void restoreSession(void) {
  // restore session
  FILE *fr = fopen(SESSION_FILE, "r");
  if (!fr)
    return;

  char *str = malloc(23 * sizeof(char));      // allocate enough space for excepted input from text file
  while (fscanf(fr, "%[^\n] ", str) != EOF) { // read file till the end
    long unsigned int winId;
    unsigned int tagsForWin;
    int check = sscanf(str, "%lu %u", &winId, &tagsForWin); // get data
    if (check != 2)                                         // break loop if data wasn't read correctly
      break;

    for (Client *c = selmon->clients; c; c = c->next) { // add tags to every window by winId
      if (c->win == winId) {
        c->tags = tagsForWin;
        break;
      }
    }
  }

  for (Client *c = selmon->clients; c; c = c->next) { // refocus on windows
    focus(c);
    restack(c->mon);
  }

  for (Monitor *m = selmon; m; m = m->next) // rearrange all monitors
    arrange(m);

  free(str);
  fclose(fr);

  // delete a file
  // remove(SESSION_FILE);
}

void quit(const Arg *arg) {
  if (arg->i)
    restart = 1;

  // fix: reloading dwm keeps all the hidden clients hidden
  Monitor *m;
  Client *c;
  for (m = mons; m; m = m->next) {
    if (m) {
      for (c = m->stack; c; c = c->next)
        if (c && HIDDEN(c))
          showwin(c);
    }
  }

  running = 0;

  if (restart == 1)
    saveSession();
}

Monitor *recttomon(int x, int y, int w, int h) {
  Monitor *m, *r = selmon;
  int a, area    = 0;

  for (m = mons; m; m = m->next)
    if ((a = INTERSECT(x, y, w, h, m)) > area) {
      area = a;
      r    = m;
    }
  return r;
}

void replaceclient(Client *old, Client *new) {
  Client *c    = NULL;
  Monitor *mon = old->mon;

  new->mon        = mon;
  new->tags       = old->tags;
  new->isfloating = old->isfloating;

  new->next  = old->next;
  new->snext = old->snext;

  if (old == mon->clients)
    mon->clients = new;
  else {
    for (c = mon->clients; c && c->next != old; c = c->next)
      ;
    c->next = new;
  }

  if (old == mon->stack)
    mon->stack = new;
  else {
    for (c = mon->stack; c && c->snext != old; c = c->snext)
      ;
    c->snext = new;
  }

  old->next  = NULL;
  old->snext = NULL;

  XMoveWindow(dpy, old->win, WIDTH(old) * -2, old->y);

  if (ISVISIBLE(new) && !new->isfullscreen) {
    if (new->isfloating)
      resize(new, old->x, old->y, new->w, new->h, 0);
    else
      resize(new, old->x, old->y, old->w, old->h, 0);
  }
}

void removesystrayicon(Client *i) {
  Client **ii;

  if (!showsystray || !i)
    return;
  for (ii = &systray->icons; *ii && *ii != i; ii = &(*ii)->next)
    ;
  if (ii)
    *ii = i->next;
  free(i);
}

void resize(Client *c, int x, int y, int w, int h, int interact) {
  if (applysizehints(c, &x, &y, &w, &h, interact))
    resizeclient(c, x, y, w, h);
}

void resizebarwin(Monitor *m) {
  unsigned int w = m->ww;
  if (showsystray && m == systraytomon(m))
    w -= getsystraywidth();
  XMoveResizeWindow(dpy, m->barwin, m->wx, m->by, w, bh);
}

void resizeclient(Client *c, int x, int y, int w, int h) {
  XWindowChanges wc;

  c->oldx = c->x;
  c->x = wc.x = x;
  c->oldy     = c->y;
  c->y = wc.y = y;
  c->oldw     = c->w;
  c->w = wc.width = w;
  c->oldh         = c->h;
  c->h = wc.height = h;
  wc.border_width  = c->bw;
  log_info("Resize client %s", c->name);
  if (((nexttiled(c->mon->clients) == c && !nexttiled(c->next)) || &monocle == c->mon->lt[c->mon->sellt]->arrange) && !c->isfullscreen && !c->isfloating &&
      NULL != c->mon->lt[c->mon->sellt]->arrange) {

    log_info("Got single client %s", c->name);
    if (!c->issticky && !c->fakefullscreen) {
      log_info("Got single client %s. Client is not sticky nor fakefullscreen, removing border...", c->name);
      c->w            = wc.width += c->bw * 2;
      c->h            = wc.height += c->bw * 2;
      wc.border_width = 0;
    } else {
      log_info("Got single client %s. Client is sticky or fakefullscreen, keeping border", c->name);
    }
  }
  XConfigureWindow(dpy, c->win, CWX | CWY | CWWidth | CWHeight | CWBorderWidth, &wc);
  configure(c);
  XSync(dpy, False);
}

void resizemouse(const Arg *arg) {
  int ocx, ocy, nw, nh;
  Client *c;
  Monitor *m;
  XEvent ev;
  Time lasttime = 0;

  if (!(c = selmon->sel))
    return;
  if (c->isfullscreen && c->fakefullscreen != 1) /* no support resizing fullscreen windows by mouse */
    return;
  restack(selmon);
  ocx = c->x;
  ocy = c->y;
  if (XGrabPointer(dpy, root, False, MOUSEMASK, GrabModeAsync, GrabModeAsync, None, cursor[CurResize]->cursor, CurrentTime) != GrabSuccess)
    return;
  XWarpPointer(dpy, None, c->win, 0, 0, 0, 0, c->w + c->bw - 1, c->h + c->bw - 1);
  do {
    XMaskEvent(dpy, MOUSEMASK | ExposureMask | SubstructureRedirectMask, &ev);
    switch (ev.type) {
    case ConfigureRequest:
    case Expose:
    case MapRequest:
      handler[ev.type](&ev);
      break;
    case MotionNotify:
      if ((ev.xmotion.time - lasttime) <= (1000 / 60))
        continue;
      lasttime = ev.xmotion.time;

      nw = MAX(ev.xmotion.x - ocx - 2 * c->bw + 1, 1);
      nh = MAX(ev.xmotion.y - ocy - 2 * c->bw + 1, 1);
      if (c->mon->wx + nw >= selmon->wx && c->mon->wx + nw <= selmon->wx + selmon->ww && c->mon->wy + nh >= selmon->wy &&
          c->mon->wy + nh <= selmon->wy + selmon->wh) {
        if (!c->isfloating && selmon->lt[selmon->sellt]->arrange && (abs(nw - c->w) > snap || abs(nh - c->h) > snap))
          togglefloating(NULL);
      }
      if (!selmon->lt[selmon->sellt]->arrange || c->isfloating)
        resize(c, c->x, c->y, nw, nh, 1);
      break;
    }
  } while (ev.type != ButtonRelease);
  XWarpPointer(dpy, None, c->win, 0, 0, 0, 0, c->w + c->bw - 1, c->h + c->bw - 1);
  XUngrabPointer(dpy, CurrentTime);
  while (XCheckMaskEvent(dpy, EnterWindowMask, &ev))
    ;
  if ((m = recttomon(c->x, c->y, c->w, c->h)) != selmon) {
    sendmon(c, m);
    selmon = m;
    focus(NULL);
  }
}

void resizerequest(XEvent *e) {
  XResizeRequestEvent *ev = &e->xresizerequest;
  Client *i;

  if ((i = wintosystrayicon(ev->window))) {
    updatesystrayicongeom(i, ev->width, ev->height);
    resizebarwin(selmon);
    updatesystray();
  }
}

void restack(Monitor *m) {
  Client *c;
  XEvent ev;
  XWindowChanges wc;

  drawbar(m);
  if (!m->sel)
    return;
  if (m->sel->isfloating || !m->lt[m->sellt]->arrange)
    XRaiseWindow(dpy, m->sel->win);
  if (m->lt[m->sellt]->arrange) {
    wc.stack_mode = Below;
    wc.sibling    = m->barwin;
    for (c = m->stack; c; c = c->snext)
      if (!c->isfloating && ISVISIBLE(c)) {
        XConfigureWindow(dpy, c->win, CWSibling | CWStackMode, &wc);
        wc.sibling = c->win;
      }
  }
  XSync(dpy, False);
  while (XCheckMaskEvent(dpy, EnterWindowMask, &ev))
    ;
  if (m == selmon && (m->tagset[m->seltags] & m->sel->tags) && selmon->lt[selmon->sellt] != &layouts[2])
    warp(m->sel);
}

void run(void) {
  XEvent ev;
  /* main event loop */
  XSync(dpy, False);
  while (running && !XNextEvent(dpy, &ev)) {
    if (handler[ev.type]) {
      handler[ev.type](&ev); /* call handler */
    }
  }
}

void runautostart(void) {
  char *pathpfx;
  char *path;
  char *xdgdatahome;
  char *home;
  struct stat sb;

  if ((home = getenv("HOME")) == NULL)
    /* this is almost impossible */
    return;

  /* if $XDG_DATA_HOME is set and not empty, use $XDG_DATA_HOME/dwm,
   * otherwise use ~/.local/share/dwm as autostart script directory
   */
  xdgdatahome = getenv("XDG_DATA_HOME");
  if (xdgdatahome != NULL && *xdgdatahome != '\0') {
    /* space for path segments, separators and nul */
    pathpfx = ecalloc(1, strlen(xdgdatahome) + strlen(dwmdir) + 2);

    if (sprintf(pathpfx, "%s/%s", xdgdatahome, dwmdir) <= 0) {
      free(pathpfx);
      return;
    }
  } else {
    /* space for path segments, separators and nul */
    pathpfx = ecalloc(1, strlen(home) + strlen(localshare) + strlen(dwmdir) + 3);

    if (sprintf(pathpfx, "%s/%s/%s", home, localshare, dwmdir) < 0) {
      free(pathpfx);
      return;
    }
  }

  /* check if the autostart script directory exists */
  if (!(stat(pathpfx, &sb) == 0 && S_ISDIR(sb.st_mode))) {
    /* the XDG conformant path does not exist or is no directory
     * so we try ~/.dwm instead
     */
    char *pathpfx_new = realloc(pathpfx, strlen(home) + strlen(dwmdir) + 3);
    if (pathpfx_new == NULL) {
      free(pathpfx);
      return;
    }
    pathpfx = pathpfx_new;

    if (sprintf(pathpfx, "%s/.%s", home, dwmdir) <= 0) {
      free(pathpfx);
      return;
    }
  }

  /* try the blocking script first */
  path = ecalloc(1, strlen(pathpfx) + strlen(autostartblocksh) + 2);
  if (sprintf(path, "%s/%s", pathpfx, autostartblocksh) <= 0) {
    free(path);
    free(pathpfx);
  }

  if (access(path, X_OK) == 0)
    system(path);

  /* now the non-blocking script */
  if (sprintf(path, "%s/%s", pathpfx, autostartsh) <= 0) {
    free(path);
    free(pathpfx);
  }

  if (access(path, X_OK) == 0)
    system(strcat(path, " &"));

  free(pathpfx);
  free(path);
}

void scan(void) {
  unsigned int i, num;
  Window d1, d2, *wins = NULL;
  XWindowAttributes wa;

  if (XQueryTree(dpy, root, &d1, &d2, &wins, &num)) {
    for (i = 0; i < num; i++) {
      if (!XGetWindowAttributes(dpy, wins[i], &wa) || wa.override_redirect || XGetTransientForHint(dpy, wins[i], &d1))
        continue;
      if (wa.map_state == IsViewable || getstate(wins[i]) == IconicState)
        manage(wins[i], &wa);
    }
    for (i = 0; i < num; i++) { /* now the transients */
      if (!XGetWindowAttributes(dpy, wins[i], &wa))
        continue;
      if (XGetTransientForHint(dpy, wins[i], &d1) && (wa.map_state == IsViewable || getstate(wins[i]) == IconicState))
        manage(wins[i], &wa);
    }
    if (wins)
      XFree(wins);
  }
}

void sendmon(Client *c, Monitor *m) {
  if (c->mon == m)
    return;
  unfocus(c, 1);
  detach(c);
  detachstack(c);
  c->mon  = m;
  c->tags = m->tagset[m->seltags];                         /* assign tags of target monitor */
  c->x    = c->mon->mx + (c->mon->mw / 2 - WIDTH(c) / 2);  /* center in x direction */
  c->y    = c->mon->my + (c->mon->mh / 2 - HEIGHT(c) / 2); /* center in y direction */
  attachbottom(c);
  attachstack(c);
  focus(NULL);
  arrange(NULL);
}

void setclientstate(Client *c, long state) {
  long data[] = {state, None};

  XChangeProperty(dpy, c->win, wmatom[WMState], wmatom[WMState], 32, PropModeReplace, (unsigned char *)data, 2);
}
void setcurrentdesktop(void) {
  long data[] = {0};
  XChangeProperty(dpy, root, netatom[NetCurrentDesktop], XA_CARDINAL, 32, PropModeReplace, (unsigned char *)data, 1);
}
void setdesktopnames(void) {
  XTextProperty text;
  Xutf8TextListToTextProperty(dpy, tags, TAGSLENGTH, XUTF8StringStyle, &text);
  XSetTextProperty(dpy, root, &text, netatom[NetDesktopNames]);
}

int sendevent(Window w, Atom proto, int mask, long d0, long d1, long d2, long d3, long d4) {
  int n;
  Atom *protocols, mt;
  int exists = 0;
  XEvent ev;

  if (proto == wmatom[WMTakeFocus] || proto == wmatom[WMDelete]) {
    mt = wmatom[WMProtocols];
    if (XGetWMProtocols(dpy, w, &protocols, &n)) {
      while (!exists && n--)
        exists = protocols[n] == proto;
      XFree(protocols);
    }
  } else {
    exists = True;
    mt     = proto;
  }
  if (exists) {
    ev.type                 = ClientMessage;
    ev.xclient.window       = w;
    ev.xclient.message_type = mt;
    ev.xclient.format       = 32;
    ev.xclient.data.l[0]    = d0;
    ev.xclient.data.l[1]    = d1;
    ev.xclient.data.l[2]    = d2;
    ev.xclient.data.l[3]    = d3;
    ev.xclient.data.l[4]    = d4;
    XSendEvent(dpy, w, False, mask, &ev);
  }
  return exists;
}

void setnumdesktops(void) {
  long data[] = {TAGSLENGTH};
  XChangeProperty(dpy, root, netatom[NetNumberOfDesktops], XA_CARDINAL, 32, PropModeReplace, (unsigned char *)data, 1);
}

void setfocus(Client *c) {
  if (!c->neverfocus) {
    Bool needfocus = True;

    if (c->istabbed) {
      int dummy;
      Window focused, root_return, parent_return, *ch;
      unsigned int nch;
      XGetInputFocus(dpy, &focused, &dummy);
      XQueryTree(dpy, focused, &root_return, &parent_return, &ch, &nch);
      if (parent_return == c->win) {
        needfocus = False;
      }
    }
    if (needfocus) {
      XSetInputFocus(dpy, c->win, RevertToPointerRoot, CurrentTime);
      XChangeProperty(dpy, root, netatom[NetActiveWindow], XA_WINDOW, 32, PropModeReplace, (unsigned char *)&(c->win), 1);
    }
  }
  if (c->issteam)
    setclientstate(c, NormalState);
  sendevent(c->win, wmatom[WMTakeFocus], NoEventMask, wmatom[WMTakeFocus], CurrentTime, 0, 0, 0);
}

void setlayout(const Arg *arg) {
  if (!arg || !arg->v || arg->v != selmon->lt[selmon->sellt])
    selmon->sellt = selmon->pertag->sellts[selmon->pertag->curtag] ^= 1;
  if (arg && arg->v)
    selmon->lt[selmon->sellt] = selmon->pertag->ltidxs[selmon->pertag->curtag][selmon->sellt] = (Layout *)arg->v;
  strncpy(selmon->ltsymbol, selmon->lt[selmon->sellt]->symbol, sizeof selmon->ltsymbol);
  if (selmon->sel)
    arrange(selmon);
  else
    drawbar(selmon);
}

void setcfact(const Arg *arg) {
  float f;
  Client *c;

  c = selmon->sel;

  if (!arg || !c || !selmon->lt[selmon->sellt]->arrange)
    return;
  f = arg->f + c->cfact;
  if (arg->f == 0.0)
    f = 1.0;
  else if (f < 0.25 || f > 4.0)
    return;
  c->cfact = f;
  arrange(selmon);
}

/* arg > 1.0 will set mfact absolutely */
void setmfact(const Arg *arg) {
  float f;

  if (!arg || !selmon->lt[selmon->sellt]->arrange)
    return;
  f = arg->f < 1.0 ? arg->f + selmon->mfact : arg->f - 1.0;
  if (f < 0.05 || f > 0.95)
    return;
  selmon->mfact = selmon->pertag->mfacts[selmon->pertag->curtag] = f;
  arrange(selmon);
}

void setup(void) {
  int i;
  XSetWindowAttributes wa;
  Atom utf8string;
  struct sigaction sa;

  /* do not transform children into zombies when they terminate */
  sigemptyset(&sa.sa_mask);
  sa.sa_flags   = SA_NOCLDSTOP | SA_NOCLDWAIT | SA_RESTART;
  sa.sa_handler = SIG_IGN;
  sigaction(SIGCHLD, &sa, NULL);

  /* clean up any zombies (inherited from .xinitrc etc) immediately */
  while (waitpid(-1, NULL, WNOHANG) > 0)
    ;

  /* init screen */
  screen = DefaultScreen(dpy);
  sw     = DisplayWidth(dpy, screen);
  sh     = DisplayHeight(dpy, screen);
  root   = RootWindow(dpy, screen);
  drw    = drw_create(dpy, screen, root, sw, sh);
  if (!drw_fontset_create(drw, fonts, LENGTH(fonts)))
    die("no fonts could be loaded.");
  lrpad = drw->fonts->h;
  bh    = drw->fonts->h + 2;
  updategeom();
  /* init atoms */
  utf8string                            = XInternAtom(dpy, "UTF8_STRING", False);
  wmatom[WMProtocols]                   = XInternAtom(dpy, "WM_PROTOCOLS", False);
  wmatom[WMDelete]                      = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  wmatom[WMState]                       = XInternAtom(dpy, "WM_STATE", False);
  wmatom[WMTakeFocus]                   = XInternAtom(dpy, "WM_TAKE_FOCUS", False);
  wmatom[WMWindowRole]                  = XInternAtom(dpy, "WM_WINDOW_ROLE", False);
  netatom[NetActiveWindow]              = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);
  netatom[NetSupported]                 = XInternAtom(dpy, "_NET_SUPPORTED", False);
  netatom[NetSystemTray]                = XInternAtom(dpy, "_NET_SYSTEM_TRAY_S0", False);
  netatom[NetSystemTrayOP]              = XInternAtom(dpy, "_NET_SYSTEM_TRAY_OPCODE", False);
  netatom[NetSystemTrayOrientation]     = XInternAtom(dpy, "_NET_SYSTEM_TRAY_ORIENTATION", False);
  netatom[NetSystemTrayOrientationHorz] = XInternAtom(dpy, "_NET_SYSTEM_TRAY_ORIENTATION_HORZ", False);
  netatom[NetWMName]                    = XInternAtom(dpy, "_NET_WM_NAME", False);
  netatom[NetWMState]                   = XInternAtom(dpy, "_NET_WM_STATE", False);
  netatom[NetWMCheck]                   = XInternAtom(dpy, "_NET_SUPPORTING_WM_CHECK", False);
  netatom[NetWMFullscreen]              = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", False);
  netatom[NetWMSticky]                  = XInternAtom(dpy, "_NET_WM_STATE_STICKY", False);
  netatom[NetWMWindowType]              = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", False);
  netatom[NetWMWindowTypeDialog]        = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", False);
  netatom[NetClientList]                = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
  xatom[Manager]                        = XInternAtom(dpy, "MANAGER", False);
  xatom[Xembed]                         = XInternAtom(dpy, "_XEMBED", False);
  xatom[XembedInfo]                     = XInternAtom(dpy, "_XEMBED_INFO", False);
  /* init cursors */
  cursor[CurNormal]            = drw_cur_create(drw, XC_left_ptr);
  cursor[CurResize]            = drw_cur_create(drw, XC_sizing);
  netatom[NetDesktopViewport]  = XInternAtom(dpy, "_NET_DESKTOP_VIEWPORT", False);
  netatom[NetNumberOfDesktops] = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", False);
  netatom[NetCurrentDesktop]   = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);
  netatom[NetDesktopNames]     = XInternAtom(dpy, "_NET_DESKTOP_NAMES", False);
  /* init cursors */
  cursor[CurNormal] = drw_cur_create(drw, XC_left_ptr);
  cursor[CurResize] = drw_cur_create(drw, XC_sizing);
  cursor[CurMove]   = drw_cur_create(drw, XC_fleur);
  /* init appearance */
  scheme                 = ecalloc(LENGTH(colors) + 1, sizeof(Clr *));
  scheme[LENGTH(colors)] = drw_scm_create(drw, colors[0], 3);
  for (i = 0; i < LENGTH(colors); i++)
    scheme[i] = drw_scm_create(drw, colors[i], 3);
  /* init system tray */
  updatesystray();
  /* init bars */
  updatebars();
  updatestatus();
  updatepreview();
  /* supporting window for NetWMCheck */
  wmcheckwin = XCreateSimpleWindow(dpy, root, 0, 0, 1, 1, 0, 0, 0);
  XChangeProperty(dpy, wmcheckwin, netatom[NetWMCheck], XA_WINDOW, 32, PropModeReplace, (unsigned char *)&wmcheckwin, 1);
  XChangeProperty(dpy, wmcheckwin, netatom[NetWMName], utf8string, 8, PropModeReplace, (unsigned char *)"dwm", 3);
  XChangeProperty(dpy, root, netatom[NetWMCheck], XA_WINDOW, 32, PropModeReplace, (unsigned char *)&wmcheckwin, 1);
  /* EWMH support per view */
  XChangeProperty(dpy, root, netatom[NetSupported], XA_ATOM, 32, PropModeReplace, (unsigned char *)netatom, NetLast);
  setnumdesktops();
  setcurrentdesktop();
  setdesktopnames();
  setviewport();
  XDeleteProperty(dpy, root, netatom[NetClientList]);
  /* select events */
  wa.cursor     = cursor[CurNormal]->cursor;
  wa.event_mask = SubstructureRedirectMask | SubstructureNotifyMask | ButtonPressMask | PointerMotionMask | EnterWindowMask | LeaveWindowMask |
                  StructureNotifyMask | PropertyChangeMask;
  XChangeWindowAttributes(dpy, root, CWEventMask | CWCursor, &wa);
  XSelectInput(dpy, root, wa.event_mask);
  grabkeys();
  focus(NULL);
}
void setviewport(void) {
  long data[] = {0, 0};
  XChangeProperty(dpy, root, netatom[NetDesktopViewport], XA_CARDINAL, 32, PropModeReplace, (unsigned char *)data, 2);
}

void seturgent(Client *c, int urg) {
  XWMHints *wmh;

  c->isurgent = urg;
  if (!(wmh = XGetWMHints(dpy, c->win)))
    return;
  wmh->flags = urg ? (wmh->flags | XUrgencyHint) : (wmh->flags & ~XUrgencyHint);
  XSetWMHints(dpy, c->win, wmh);
  XFree(wmh);
}

void showhide(Client *c) {
  if (!c)
    return;
  if (ISVISIBLE(c)) {
    /* show clients top down */
    XMoveWindow(dpy, c->win, c->x, c->y);
    if ((!c->mon->lt[c->mon->sellt]->arrange || c->isfloating) && !c->isfullscreen)
      resize(c, c->x, c->y, c->w, c->h, 0);
    showhide(c->snext);
  } else {
    /* hide clients bottom up */
    showhide(c->snext);
    XMoveWindow(dpy, c->win, WIDTH(c) * -2, c->y);
  }
}

void showtagpreview(int tag) {
  if (!selmon->previewshow) {
    XUnmapWindow(dpy, selmon->tagwin);
    return;
  }

  if (selmon->tagmap[tag]) {
    XSetWindowBackgroundPixmap(dpy, selmon->tagwin, selmon->tagmap[tag]);
    XCopyArea(dpy, selmon->tagmap[tag], selmon->tagwin, drw->gc, 0, 0, selmon->mw / scalepreview, selmon->mh / scalepreview, 0, 0);
    XSync(dpy, False);
    XMapWindow(dpy, selmon->tagwin);
  } else
    XUnmapWindow(dpy, selmon->tagwin);
}

void sigstatusbar(const Arg *arg) {
  union sigval sv;

  if (!statussig)
    return;
  sv.sival_int = arg->i;
  if ((statuspid = getstatusbarpid()) <= 0)
    return;

  sigqueue(statuspid, SIGRTMIN + statussig, sv);
}

void spawn(const Arg *arg) {
  struct sigaction sa;

  if (arg->v == dmenucmd)
    dmenumon[0] = '0' + selmon->num;
  if (fork() == 0) {
    if (dpy)
      close(ConnectionNumber(dpy));
    setsid();

    sigemptyset(&sa.sa_mask);
    sa.sa_flags   = 0;
    sa.sa_handler = SIG_DFL;
    sigaction(SIGCHLD, &sa, NULL);
    execvp(((char **)arg->v)[0], (char **)arg->v);
    die("dwm: execvp '%s' failed:", ((char **)arg->v)[0]);
  }
}

void swapfocus() {
  Client *c;
  for (c = selmon->clients; c && c != prevclient; c = c->next)
    ;
  if (c == prevclient) {
    focus(prevclient);
    restack(prevclient->mon);
  }
}

void switchtag(void) {
  int i;
  unsigned int occ = 0;
  Client *c;
  Imlib_Image image;

  for (c = selmon->clients; c; c = c->next)
    occ |= c->tags;
  for (i = 0; i < LENGTH(tags); i++) {
    if (selmon->tagset[selmon->seltags] & 1 << i) {
      if (selmon->tagmap[i] != 0) {
        XFreePixmap(dpy, selmon->tagmap[i]);
        selmon->tagmap[i] = 0;
      }
      if (occ & 1 << i) {
        image = imlib_create_image(sw, sh);
        imlib_context_set_image(image);
        imlib_context_set_display(dpy);
        imlib_context_set_visual(DefaultVisual(dpy, screen));
        imlib_context_set_drawable(RootWindow(dpy, screen));
        // uncomment the following line and comment the other imlin_copy.. line
        // if you don't want the bar showing on the preview
        // imlib_copy_drawable_to_image(0, selmon->wx, selmon->wy, selmon->ww
        // ,selmon->wh, 0, 0, 1);
        imlib_copy_drawable_to_image(0, selmon->mx, selmon->my, selmon->mw, selmon->mh, 0, 0, 1);
        selmon->tagmap[i] = XCreatePixmap(dpy, selmon->tagwin, selmon->mw / scalepreview, selmon->mh / scalepreview, DefaultDepth(dpy, screen));
        imlib_context_set_drawable(selmon->tagmap[i]);
        imlib_render_image_part_on_drawable_at_size(0, 0, selmon->mw, selmon->mh, 0, 0, selmon->mw / scalepreview, selmon->mh / scalepreview);
        imlib_free_image();
      }
    }
  }
}

int swallow(Client *t, Client *c) {
  if (c->noswallow || c->isterminal)
    return 0;
  if (!swallowfloating && c->isfloating)
    return 0;

  if (t->isfullscreen)
    setfullscreen(c, 1);

  replaceclient(t, c);
  c->ignorecfgreqpos = 1;
  c->swallowing      = t;

  return 1;
}

void unswallow(Client *c) {
  replaceclient(c, c->swallowing);
  c->swallowing = NULL;
}

void tag(const Arg *arg) {
  if (selmon->sel && arg->ui & TAGMASK) {
    selmon->sel->tags = arg->ui & TAGMASK;
    focus(NULL);
    arrange(selmon);
  }
}

void tagmon(const Arg *arg) {
  // if (!selmon->sel || !mons->next)
  //   return;
  // sendmon(selmon->sel, dirtomon(arg->i));
  Client *c = selmon->sel;
  if (!c || !mons->next)
    return;
  if (c->isfullscreen) {
    c->isfullscreen = 0;
    sendmon(c, dirtomon(arg->i));
    c->isfullscreen = 1;
    if (c->fakefullscreen != 1) {
      resizeclient(c, c->mon->mx, c->mon->my, c->mon->mw, c->mon->mh);
      XRaiseWindow(dpy, c->win);
    }
  } else
    sendmon(c, dirtomon(arg->i));
}

void togglebar(const Arg *arg) {
  selmon->showbar = selmon->pertag->showbars[selmon->pertag->curtag] = !selmon->showbar;
  updatebarpos(selmon);
  resizebarwin(selmon);
  if (showsystray) {
    XWindowChanges wc;
    if (!selmon->showbar)
      wc.y = -bh;
    else if (selmon->showbar) {
      wc.y = 0;
      if (!selmon->topbar)
        wc.y = selmon->mh - bh;
    }
    XConfigureWindow(dpy, systray->win, CWY, &wc);
  }
  arrange(selmon);
}

void togglefloating(const Arg *arg) {
  Client *c = selmon->sel;
  if (!c)
    return;
  if (c->isfullscreen && c->fakefullscreen != 1) /* no support for fullscreen windows */
    return;
  c->isfloating = !c->isfloating || c->isfixed;
  if (selmon->sel->isfloating)
    resize(c, c->x, c->y, c->w, c->h, 0);
  arrange(c->mon);
}

void setsticky(Client *c, int sticky) {
  if (sticky && !c->issticky) {
    XChangeProperty(dpy, c->win, netatom[NetWMState], XA_ATOM, 32, PropModeReplace, (unsigned char *)&netatom[NetWMSticky], 1);
    c->issticky = 1;
  } else if (!sticky && c->issticky) {
    XChangeProperty(dpy, c->win, netatom[NetWMState], XA_ATOM, 32, PropModeReplace, (unsigned char *)0, 0);
    c->issticky = 0;
    arrange(c->mon);
  }
}

void togglesticky(const Arg *arg) {
  if (!selmon->sel)
    return;
  setsticky(selmon->sel, !selmon->sel->issticky);
  arrange(selmon);
  Client *c = selmon->sel;
  resizeclient(c, c->x, c->y, c->w, c->h);
  updateborderonfocus(selmon->sel);
}

void toggletag(const Arg *arg) {
  unsigned int newtags;

  if (!selmon->sel)
    return;
  newtags = selmon->sel->tags ^ (arg->ui & TAGMASK);
  if (newtags) {
    selmon->sel->tags = newtags;
    focus(NULL);
    arrange(selmon);
  }
}

void toggleview(const Arg *arg) {
  unsigned int newtagset = selmon->tagset[selmon->seltags] ^ (arg->ui & TAGMASK);
  int i;

  if (newtagset) {
    switchtag();
    selmon->tagset[selmon->seltags] = newtagset;

    if (newtagset == ~0) {
      selmon->pertag->prevtag = selmon->pertag->curtag;
      selmon->pertag->curtag  = 0;
    }

    /* test if the user did not select the same tag */
    if (!(newtagset & 1 << (selmon->pertag->curtag - 1))) {
      selmon->pertag->prevtag = selmon->pertag->curtag;
      for (i = 0; !(newtagset & 1 << i); i++)
        ;
      selmon->pertag->curtag = i + 1;
    }

    /* apply settings for this view */
    selmon->nmaster               = selmon->pertag->nmasters[selmon->pertag->curtag];
    selmon->mfact                 = selmon->pertag->mfacts[selmon->pertag->curtag];
    selmon->sellt                 = selmon->pertag->sellts[selmon->pertag->curtag];
    selmon->lt[selmon->sellt]     = selmon->pertag->ltidxs[selmon->pertag->curtag][selmon->sellt];
    selmon->lt[selmon->sellt ^ 1] = selmon->pertag->ltidxs[selmon->pertag->curtag][selmon->sellt ^ 1];

    if (selmon->showbar != selmon->pertag->showbars[selmon->pertag->curtag])
      togglebar(NULL);

    focus(NULL);
    arrange(selmon);
  }
  updatecurrentdesktop();
}

void unmanage(Client *c, int destroyed) {
  Client *s;
  Monitor *m = c->mon;
  XWindowChanges wc;

  if (c->swallowing)
    unswallow(c);

  s = swallowingclient(c->win);
  if (s)
    s->swallowing = NULL;

  detach(c);
  detachstack(c);
  if (!destroyed) {
    wc.border_width = c->oldbw;
    XGrabServer(dpy); /* avoid race conditions */
    XSetErrorHandler(xerrordummy);
    XSelectInput(dpy, c->win, NoEventMask);
    XConfigureWindow(dpy, c->win, CWBorderWidth, &wc); /* restore border */
    XUngrabButton(dpy, AnyButton, AnyModifier, c->win);
    setclientstate(c, WithdrawnState);
    XSync(dpy, False);
    XSetErrorHandler(xerror);
    XUngrabServer(dpy);
  }
  free(c);
  focus(NULL);
  updateclientlist();
  arrange(m);
}

void unmapnotify(XEvent *e) {
  Client *c;
  XUnmapEvent *ev = &e->xunmap;

  if ((c = wintoclient(ev->window))) {
    if (ev->send_event)
      setclientstate(c, WithdrawnState);
    else
      unmanage(c, 0);
  } else if ((c = wintosystrayicon(ev->window))) {
    /* KLUDGE! sometimes icons occasionally unmap their windows, but do
     * _not_ destroy them. We map those windows back */
    XMapRaised(dpy, c->win);
    updatesystray();
  }
}

void updatebars(void) {
  unsigned int w;
  Monitor *m;
  XSetWindowAttributes wa = {.override_redirect = True, .background_pixmap = ParentRelative, .event_mask = ButtonPressMask | ExposureMask | PointerMotionMask};
  XClassHint ch           = {"dwm", "dwm"};
  for (m = mons; m; m = m->next) {
    if (m->barwin)
      continue;
    w = m->ww;
    if (showsystray && m == systraytomon(m))
      w -= getsystraywidth();
    m->barwin = XCreateWindow(dpy, root, m->wx, m->by, w, bh, 0, DefaultDepth(dpy, screen), CopyFromParent, DefaultVisual(dpy, screen),
                              CWOverrideRedirect | CWBackPixmap | CWEventMask, &wa);
    XDefineCursor(dpy, m->barwin, cursor[CurNormal]->cursor);
    if (showsystray && m == systraytomon(m))
      XMapRaised(dpy, systray->win);
    XMapRaised(dpy, m->barwin);
    XSetClassHint(dpy, m->barwin, &ch);
  }
}

void updatebarpos(Monitor *m) {
  m->wy = m->my;
  m->wh = m->mh;
  if (m->showbar) {
    m->wh -= bh;
    m->by = m->topbar ? m->wy : m->wy + m->wh;
    m->wy = m->topbar ? m->wy + bh : m->wy;
  } else
    m->by = -bh;
}

void updateclientlist() {
  Client *c;
  Monitor *m;

  XDeleteProperty(dpy, root, netatom[NetClientList]);
  for (m = mons; m; m = m->next)
    for (c = m->clients; c; c = c->next)
      XChangeProperty(dpy, root, netatom[NetClientList], XA_WINDOW, 32, PropModeAppend, (unsigned char *)&(c->win), 1);
}
void updatecurrentdesktop(void) {
  long rawdata[] = {selmon->tagset[selmon->seltags]};
  int i          = 0;
  while (*rawdata >> (i + 1)) {
    i++;
  }
  long data[] = {i};
  XChangeProperty(dpy, root, netatom[NetCurrentDesktop], XA_CARDINAL, 32, PropModeReplace, (unsigned char *)data, 1);
}

int updategeom(void) {
  log_info("[In updategeom] called");
  int dirty = 0;

#ifdef XINERAMA
  if (XineramaIsActive(dpy)) {
    int i, j, n, nn;
    Client *c;
    Monitor *m;
    XineramaScreenInfo *info   = XineramaQueryScreens(dpy, &nn);
    XineramaScreenInfo *unique = NULL;

    for (n = 0, m = mons; m; m = m->next, n++)
      ;
    /* only consider unique geometries as separate screens */
    unique = ecalloc(nn, sizeof(XineramaScreenInfo));
    for (i = 0, j = 0; i < nn; i++)
      if (isuniquegeom(unique, j, &info[i]))
        memcpy(&unique[j++], &info[i], sizeof(XineramaScreenInfo));
    XFree(info);
    nn = j;
    /* new monitors if nn > n */
    for (i = n; i < nn; i++) {
      for (m = mons; m && m->next; m = m->next)
        ;
      if (m)
        m->next = createmon();
      else
        mons = createmon();
    }
    for (i = 0, m = mons; i < nn && m; m = m->next, i++)
      if (i >= n || unique[i].x_org != m->mx || unique[i].y_org != m->my || unique[i].width != m->mw || unique[i].height != m->mh) {
        dirty  = 1;
        m->num = i;
        m->mx = m->wx = unique[i].x_org;
        m->my = m->wy = unique[i].y_org;
        m->mw = m->ww = unique[i].width;
        m->mh = m->wh = unique[i].height;
        updatebarpos(m);
      }

    /* removed monitors if n > nn */
    for (i = nn; i < n; i++) {
      for (m = mons; m && m->next; m = m->next)
        ;
      while ((c = m->clients)) {
        dirty      = 1;
        m->clients = c->next;
        detachstack(c);
        c->mon = mons;
        attach(c);
        attachstack(c);
      }
      if (m == selmon)
        selmon = mons;
      cleanupmon(m);
    }

    free(unique);
  } else
#endif /* XINERAMA */
  {    /* default monitor setup */
    if (!mons)
      mons = createmon();
    if (mons->mw != sw || mons->mh != sh) {
      dirty    = 1;
      mons->mw = mons->ww = sw;
      mons->mh = mons->wh = sh;
      updatebarpos(mons);
    }
  }
  if (dirty) {
    selmon = mons;
    selmon = wintomon(root);
  }
  return dirty;
}

void updatenumlockmask(void) {
  unsigned int i, j;
  XModifierKeymap *modmap;

  numlockmask = 0;
  modmap      = XGetModifierMapping(dpy);
  for (i = 0; i < 8; i++)
    for (j = 0; j < modmap->max_keypermod; j++)
      if (modmap->modifiermap[i * modmap->max_keypermod + j] == XKeysymToKeycode(dpy, XK_Num_Lock))
        numlockmask = (1 << i);
  XFreeModifiermap(modmap);
}

void updatesizehints(Client *c) {
  long msize;
  XSizeHints size;

  if (!XGetWMNormalHints(dpy, c->win, &size, &msize))
    /* size is uninitialized, ensure that size.flags aren't used */
    size.flags = PSize;
  if (size.flags & PBaseSize) {
    c->basew = size.base_width;
    c->baseh = size.base_height;
  } else if (size.flags & PMinSize) {
    c->basew = size.min_width;
    c->baseh = size.min_height;
  } else
    c->basew = c->baseh = 0;
  if (size.flags & PResizeInc) {
    c->incw = size.width_inc;
    c->inch = size.height_inc;
  } else
    c->incw = c->inch = 0;
  if (size.flags & PMaxSize) {
    c->maxw = size.max_width;
    c->maxh = size.max_height;
  } else
    c->maxw = c->maxh = 0;
  if (size.flags & PMinSize) {
    c->minw = size.min_width;
    c->minh = size.min_height;
  } else if (size.flags & PBaseSize) {
    c->minw = size.base_width;
    c->minh = size.base_height;
  } else
    c->minw = c->minh = 0;
  if (size.flags & PAspect) {
    c->mina = (float)size.min_aspect.y / size.min_aspect.x;
    c->maxa = (float)size.max_aspect.x / size.max_aspect.y;
  } else
    c->maxa = c->mina = 0.0;
  c->isfixed    = (c->maxw && c->maxh && c->maxw == c->minw && c->maxh == c->minh);
  c->hintsvalid = 1;
}

void updatestatus(void) {
  if (!gettextprop(root, XA_WM_NAME, stext, sizeof(stext)))
    strcpy(stext, "dwm-" VERSION);
  drawbar(selmon);
  updatesystray();
}

void updatesystrayicongeom(Client *i, int w, int h) {
  if (i) {
    i->h = bh;
    if (w == h)
      i->w = bh;
    else if (h == bh)
      i->w = w;
    else
      i->w = (int)((float)bh * ((float)w / (float)h));
    applysizehints(i, &(i->x), &(i->y), &(i->w), &(i->h), False);
    /* force icons into the systray dimensions if they don't want to */
    if (i->h > bh) {
      if (i->w == i->h)
        i->w = bh;
      else
        i->w = (int)((float)bh * ((float)i->w / (float)i->h));
      i->h = bh;
    }
  }
}

void updatesystrayiconstate(Client *i, XPropertyEvent *ev) {
  long flags;
  int code = 0;

  if (!showsystray || !i || ev->atom != xatom[XembedInfo] || !(flags = getatomprop(i, xatom[XembedInfo])))
    return;

  if (flags & XEMBED_MAPPED && !i->tags) {
    i->tags = 1;
    code    = XEMBED_WINDOW_ACTIVATE;
    XMapRaised(dpy, i->win);
    setclientstate(i, NormalState);
  } else if (!(flags & XEMBED_MAPPED) && i->tags) {
    i->tags = 0;
    code    = XEMBED_WINDOW_DEACTIVATE;
    XUnmapWindow(dpy, i->win);
    setclientstate(i, WithdrawnState);
  } else
    return;
  sendevent(i->win, xatom[Xembed], StructureNotifyMask, CurrentTime, code, 0, systray->win, XEMBED_EMBEDDED_VERSION);
}

void updatesystray(void) {
  XSetWindowAttributes wa;
  XWindowChanges wc;
  Client *i;
  Monitor *m     = systraytomon(NULL);
  unsigned int x = m->mx + m->mw;
  unsigned int w = 1;

  if (!showsystray)
    return;
  if (!systray) {
    /* init systray */
    if (!(systray = (Systray *)calloc(1, sizeof(Systray))))
      die("fatal: could not malloc() %u bytes\n", sizeof(Systray));
    systray->win         = XCreateSimpleWindow(dpy, root, x, m->by, w, bh, 0, 0, scheme[SchemeSel][ColBg].pixel);
    wa.event_mask        = ButtonPressMask | ExposureMask;
    wa.override_redirect = True;
    wa.background_pixel  = scheme[SchemeNorm][ColBg].pixel;
    XSelectInput(dpy, systray->win, SubstructureNotifyMask);
    XChangeProperty(dpy, systray->win, netatom[NetSystemTrayOrientation], XA_CARDINAL, 32, PropModeReplace,
                    (unsigned char *)&netatom[NetSystemTrayOrientationHorz], 1);
    XChangeWindowAttributes(dpy, systray->win, CWEventMask | CWOverrideRedirect | CWBackPixel, &wa);
    XMapRaised(dpy, systray->win);
    XSetSelectionOwner(dpy, netatom[NetSystemTray], systray->win, CurrentTime);
    if (XGetSelectionOwner(dpy, netatom[NetSystemTray]) == systray->win) {
      sendevent(root, xatom[Manager], StructureNotifyMask, CurrentTime, netatom[NetSystemTray], systray->win, 0, 0);
      XSync(dpy, False);
    } else {
      fprintf(stderr, "dwm: unable to obtain system tray.\n");
      free(systray);
      systray = NULL;
      return;
    }
  }
  for (w = 0, i = systray->icons; i; i = i->next) {
    /* make sure the background color stays the same */
    wa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
    XChangeWindowAttributes(dpy, i->win, CWBackPixel, &wa);
    XMapRaised(dpy, i->win);
    w += systrayspacing;
    i->x = w;
    XMoveResizeWindow(dpy, i->win, i->x, 0, i->w, i->h);
    w += i->w;
    if (i->mon != m)
      i->mon = m;
  }
  w = w ? w + systrayspacing : 1;
  x -= w;
  XMoveResizeWindow(dpy, systray->win, x, m->by, w, bh);
  wc.x          = x;
  wc.y          = m->by;
  wc.width      = w;
  wc.height     = bh;
  wc.stack_mode = Above;
  wc.sibling    = m->barwin;
  XConfigureWindow(dpy, systray->win, CWX | CWY | CWWidth | CWHeight | CWSibling | CWStackMode, &wc);
  XMapWindow(dpy, systray->win);
  XMapSubwindows(dpy, systray->win);
  /* redraw background */
  XSetForeground(dpy, drw->gc, scheme[SchemeNorm][ColBg].pixel);
  XFillRectangle(dpy, systray->win, drw->gc, 0, 0, w, bh);
  XSync(dpy, False);
}

void updatetitle(Client *c) {
  if (!gettextprop(c->win, netatom[NetWMName], c->name, sizeof c->name))
    gettextprop(c->win, XA_WM_NAME, c->name, sizeof c->name);
  if (c->name[0] == '\0') /* hack to mark broken clients */
    strcpy(c->name, broken);
}

void updatepreview(void) {
  Monitor *m;

  XSetWindowAttributes wa = {.override_redirect = True, .background_pixmap = ParentRelative, .event_mask = ButtonPressMask | ExposureMask};
  for (m = mons; m; m = m->next) {
    m->tagwin = XCreateWindow(dpy, root, m->wx, m->by + bh, m->mw / scalepreview, m->mh / scalepreview, 0, DefaultDepth(dpy, screen), CopyFromParent,
                              DefaultVisual(dpy, screen), CWOverrideRedirect | CWBackPixmap | CWEventMask, &wa);
    XDefineCursor(dpy, m->tagwin, cursor[CurNormal]->cursor);
    XMapRaised(dpy, m->tagwin);
    XUnmapWindow(dpy, m->tagwin);
  }
}

void updatewindowtype(Client *c) {
  Atom state = getatomprop(c, netatom[NetWMState]);
  Atom wtype = getatomprop(c, netatom[NetWMWindowType]);

  if (state == netatom[NetWMFullscreen])
    setfullscreen(c, 1);
  if (state == netatom[NetWMSticky]) {
    setsticky(c, 1);
  }
  if (wtype == netatom[NetWMWindowTypeDialog])
    c->isfloating = 1;
  if (wtype == netatom[NetWMWindowTypeDialog])
    c->isfloating = 1;
}

void updatewmhints(Client *c) {
  XWMHints *wmh;

  if ((wmh = XGetWMHints(dpy, c->win))) {
    if (c == selmon->sel && wmh->flags & XUrgencyHint) {
      wmh->flags &= ~XUrgencyHint;
      XSetWMHints(dpy, c->win, wmh);
    } else {
      c->isurgent = (wmh->flags & XUrgencyHint) ? 1 : 0;
      if (c->isurgent)
        XSetWindowBorder(dpy, c->win, scheme[SchemeUrg][ColBorder].pixel);
    }
    if (wmh->flags & InputHint)
      c->neverfocus = !wmh->input;
    else
      c->neverfocus = 0;
    XFree(wmh);
  }
}

void view(const Arg *arg) {
  int i;
  unsigned int tmptag;

  if ((arg->ui & TAGMASK) == selmon->tagset[selmon->seltags])
    return;
  switchtag();
  selmon->seltags ^= 1; /* toggle sel tagset */
  if (arg->ui & TAGMASK) {
    selmon->tagset[selmon->seltags] = arg->ui & TAGMASK;
    selmon->pertag->prevtag         = selmon->pertag->curtag;

    if (arg->ui == ~0)
      selmon->pertag->curtag = 0;
    else {
      for (i = 0; !(arg->ui & 1 << i); i++)
        ;
      selmon->pertag->curtag = i + 1;
    }
  } else {
    tmptag                  = selmon->pertag->prevtag;
    selmon->pertag->prevtag = selmon->pertag->curtag;
    selmon->pertag->curtag  = tmptag;
  }

  selmon->nmaster               = selmon->pertag->nmasters[selmon->pertag->curtag];
  selmon->mfact                 = selmon->pertag->mfacts[selmon->pertag->curtag];
  selmon->sellt                 = selmon->pertag->sellts[selmon->pertag->curtag];
  selmon->lt[selmon->sellt]     = selmon->pertag->ltidxs[selmon->pertag->curtag][selmon->sellt];
  selmon->lt[selmon->sellt ^ 1] = selmon->pertag->ltidxs[selmon->pertag->curtag][selmon->sellt ^ 1];

  if (selmon->showbar != selmon->pertag->showbars[selmon->pertag->curtag])
    togglebar(NULL);

  focus(NULL);
  arrange(selmon);
  updatecurrentdesktop();
}

void warp(const Client *c) {
  int x, y;

  if (!c) {
    XWarpPointer(dpy, None, root, 0, 0, 0, 0, selmon->wx + selmon->ww / 2, selmon->wy + selmon->wh / 2);
    return;
  }

  if (!getrootptr(&x, &y) || (x > c->x - c->bw && y > c->y - c->bw && x < c->x + c->w + c->bw * 2 && y < c->y + c->h + c->bw * 2) ||
      (y > c->mon->by && y < c->mon->by + bh) || (c->mon->topbar && !y))
    return;

  XWarpPointer(dpy, None, c->win, 0, 0, 0, 0, c->w / 2, c->h / 2);
}

pid_t winpid(Window w) {
  pid_t result = 0;

  xcb_res_client_id_spec_t spec = {0};
  spec.client                   = w;
  spec.mask                     = XCB_RES_CLIENT_ID_MASK_LOCAL_CLIENT_PID;

  xcb_generic_error_t *e              = NULL;
  xcb_res_query_client_ids_cookie_t c = xcb_res_query_client_ids(xcon, 1, &spec);
  xcb_res_query_client_ids_reply_t *r = xcb_res_query_client_ids_reply(xcon, c, &e);

  if (!r)
    return (pid_t)0;

  xcb_res_client_id_value_iterator_t i = xcb_res_query_client_ids_ids_iterator(r);
  for (; i.rem; xcb_res_client_id_value_next(&i)) {
    spec = i.data->spec;
    if (spec.mask & XCB_RES_CLIENT_ID_MASK_LOCAL_CLIENT_PID) {
      uint32_t *t = xcb_res_client_id_value_value(i.data);
      result      = *t;
      break;
    }
  }

  free(r);

  if (result == (pid_t)-1)
    result = 0;

  return result;
}

pid_t getparentprocess(pid_t p) {
  unsigned int v = 0;

  FILE *f;
  char buf[256];
  snprintf(buf, sizeof(buf) - 1, "/proc/%u/stat", (unsigned)p);

  if (!(f = fopen(buf, "r")))
    return 0;

  fscanf(f, "%*u %*s %*c %u", &v);
  fclose(f);

  return (pid_t)v;
}

int isdescprocess(pid_t p, pid_t c) {
  while (p != c && c != 0)
    c = getparentprocess(c);

  return (int)c;
}

Client *termforwin(const Client *w) {
  Client *c;
  Monitor *m;

  if (!w->pid || w->isterminal)
    return NULL;

  for (m = mons; m; m = m->next) {
    for (c = m->clients; c; c = c->next) {
      if (c->isterminal && !c->swallowing && c->pid && isdescprocess(c->pid, w->pid))
        return c;
    }
  }

  return NULL;
}

Client *swallowingclient(Window w) {
  Client *c;
  Monitor *m;

  for (m = mons; m; m = m->next) {
    for (c = m->clients; c; c = c->next) {
      if (c->swallowing && c->swallowing->win == w)
        return c;
    }
  }

  return NULL;
}

Client *wintoclient(Window w) {
  Client *c;
  Monitor *m;

  for (m = mons; m; m = m->next)
    for (c = m->clients; c; c = c->next)
      if (c->win == w)
        return c;
  return NULL;
}

Client *wintosystrayicon(Window w) {
  Client *i = NULL;

  if (!showsystray || !w)
    return i;
  for (i = systray->icons; i && i->win != w; i = i->next)
    ;
  return i;
}

Monitor *wintomon(Window w) {
  int x, y;
  Client *c;
  Monitor *m;

  if (w == root && getrootptr(&x, &y))
    return recttomon(x, y, 1, 1);
  for (m = mons; m; m = m->next)
    if (w == m->barwin)
      return m;
  if ((c = wintoclient(w)))
    return c->mon;
  return selmon;
}

/* There's no way to check accesses to destroyed windows, thus those cases are
 * ignored (especially on UnmapNotify's). Other types of errors call Xlibs
 * default error handler, which may call exit. */
int xerror(Display *dpy, XErrorEvent *ee) {
  if (ee->error_code == BadWindow || (ee->request_code == X_SetInputFocus && ee->error_code == BadMatch) ||
      (ee->request_code == X_PolyText8 && ee->error_code == BadDrawable) || (ee->request_code == X_PolyFillRectangle && ee->error_code == BadDrawable) ||
      (ee->request_code == X_PolySegment && ee->error_code == BadDrawable) || (ee->request_code == X_ConfigureWindow && ee->error_code == BadMatch) ||
      (ee->request_code == X_GrabButton && ee->error_code == BadAccess) || (ee->request_code == X_GrabKey && ee->error_code == BadAccess) ||
      (ee->request_code == X_CopyArea && ee->error_code == BadDrawable))
    return 0;
  fprintf(stderr, "dwm: fatal error: request code=%d, error code=%d\n", ee->request_code, ee->error_code);
  return xerrorxlib(dpy, ee); /* may call exit */
}

int xerrordummy(Display *dpy, XErrorEvent *ee) { return 0; }

/* Startup Error handler to check if another window manager
 * is already running. */
int xerrorstart(Display *dpy, XErrorEvent *ee) {
  die("dwm: another window manager is already running");
  return -1;
}

Monitor *systraytomon(Monitor *m) {
  Monitor *t;
  int i, n;
  if (!systraypinning) {
    if (!m)
      return selmon;
    return m == selmon ? m : NULL;
  }
  for (n = 1, t = mons; t && t->next; n++, t = t->next)
    ;
  for (i = 1, t = mons; t && t->next && i < systraypinning; i++, t = t->next)
    ;
  if (systraypinningfailfirst && n < systraypinning)
    return mons;
  return t;
}

void zoom(const Arg *arg) {
  Client *c  = selmon->sel;
  prevclient = nexttiled(selmon->clients);

  if (!selmon->lt[selmon->sellt]->arrange || (selmon->sel && selmon->sel->isfloating))
    return;
  if (c == nexttiled(selmon->clients))
    if (!c || !(c = prevclient = nexttiled(c->next)))
      return;
  pop(c);
}

void setgaps(int oh, int ov, int ih, int iv) {
  if (oh < 0)
    oh = 0;
  if (ov < 0)
    ov = 0;
  if (ih < 0)
    ih = 0;
  if (iv < 0)
    iv = 0;

  selmon->gappoh = oh;
  selmon->gappov = ov;
  selmon->gappih = ih;
  selmon->gappiv = iv;
  arrange(selmon);
}

void togglegaps(const Arg *arg) {
  selmon->pertag->enablegaps[selmon->pertag->curtag] = !selmon->pertag->enablegaps[selmon->pertag->curtag];
  arrange(NULL);
}

void defaultgaps(const Arg *arg) { setgaps(gappoh, gappov, gappih, gappiv); }

void incrgaps(const Arg *arg) { setgaps(selmon->gappoh + arg->i, selmon->gappov + arg->i, selmon->gappih + arg->i, selmon->gappiv + arg->i); }

void incrigaps(const Arg *arg) { setgaps(selmon->gappoh, selmon->gappov, selmon->gappih + arg->i, selmon->gappiv + arg->i); }

void incrogaps(const Arg *arg) { setgaps(selmon->gappoh + arg->i, selmon->gappov + arg->i, selmon->gappih, selmon->gappiv); }

void incrohgaps(const Arg *arg) { setgaps(selmon->gappoh + arg->i, selmon->gappov, selmon->gappih, selmon->gappiv); }

void incrovgaps(const Arg *arg) { setgaps(selmon->gappoh, selmon->gappov + arg->i, selmon->gappih, selmon->gappiv); }

void incrihgaps(const Arg *arg) { setgaps(selmon->gappoh, selmon->gappov, selmon->gappih + arg->i, selmon->gappiv); }

void incrivgaps(const Arg *arg) { setgaps(selmon->gappoh, selmon->gappov, selmon->gappih, selmon->gappiv + arg->i); }

void getgaps(Monitor *m, int *oh, int *ov, int *ih, int *iv, unsigned int *nc) {
  unsigned int n, oe, ie;
  oe = ie = selmon->pertag->enablegaps[selmon->pertag->curtag];
  Client *c;

  for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), n++)
    ;
  if (smartgaps && n == 1) {
    oe = 0; // outer gaps disabled when only one client
  }

  *oh = m->gappoh * oe; // outer horizontal gap
  *ov = m->gappov * oe; // outer vertical gap
  *ih = m->gappih * ie; // inner horizontal gap
  *iv = m->gappiv * ie; // inner vertical gap
  *nc = n;              // number of clients
}

void getfacts(Monitor *m, int msize, int ssize, float *mf, float *sf, int *mr, int *sr) {
  unsigned int n;
  float mfacts = 0, sfacts = 0;
  int mtotal = 0, stotal = 0;
  Client *c;

  for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), n++)
    if (n < m->nmaster)
      mfacts += c->cfact;
    else
      sfacts += c->cfact;

  for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), n++)
    if (n < m->nmaster)
      mtotal += msize * (c->cfact / mfacts);
    else
      stotal += ssize * (c->cfact / sfacts);

  *mf = mfacts;         // total factor of master area
  *sf = sfacts;         // total factor of stack area
  *mr = msize - mtotal; // the remainder (rest) of pixels after a cfacts master split
  *sr = ssize - stotal; // the remainder (rest) of pixels after a cfacts stack split
}

void toggleborder(const Arg *arg) {
  selmon->sel->bw = (selmon->sel->bw == borderpx ? 0 : borderpx);
  arrange(selmon);
}

int main(int argc, char *argv[]) {
  FILE *log_file;
  log_file = fopen("/tmp/dwm-log", "w+");
  log_add_fp(log_file, 0);
  log_info("Starting dwm");
  if (argc == 2 && !strcmp("-v", argv[1]))
    die("dwm-" VERSION);
  else if (argc != 1)
    die("usage: dwm [-v]");
  if (!setlocale(LC_CTYPE, "") || !XSupportsLocale())
    fputs("warning: no locale support\n", stderr);
  if (!(dpy = XOpenDisplay(NULL)))
    die("dwm: cannot open display");
  if (!(xcon = XGetXCBConnection(dpy)))
    die("dwm: cannot get xcb connection\n");
  checkotherwm();
  XrmInitialize();
  load_xresources();
  setup();
  scan();
  restoreSession();
  runautostart();
  run();
  cleanup();
  XCloseDisplay(dpy);

  // Close the log file
  fclose(log_file);
  return EXIT_SUCCESS;
}
