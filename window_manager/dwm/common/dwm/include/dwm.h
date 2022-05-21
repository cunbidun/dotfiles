#ifndef _DWM_HEADER_H_
#define _DWM_HEADER_H_

#include <X11/XF86keysym.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xproto.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>
#include <X11/keysym.h>
#include <errno.h>
#include <locale.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#ifdef XINERAMA
#include <X11/extensions/Xinerama.h>
#endif /* XINERAMA */
#include <Imlib2.h>
#include <X11/Xft/Xft.h>
#include <X11/Xlib-xcb.h>
#include <xcb/res.h>

#include "drw.h"
#include "util.h"

/* macros */
#define BUTTONMASK (ButtonPressMask | ButtonReleaseMask)
#define CLEANMASK(mask)                                                        \
  (mask & ~(numlockmask | LockMask) &                                          \
   (ShiftMask | ControlMask | Mod1Mask | Mod2Mask | Mod3Mask | Mod4Mask |      \
    Mod5Mask))
#define INTERSECT(x, y, w, h, m)                                               \
  (MAX(0, MIN((x) + (w), (m)->wx + (m)->ww) - MAX((x), (m)->wx)) *             \
   MAX(0, MIN((y) + (h), (m)->wy + (m)->wh) - MAX((y), (m)->wy)))
#define ISVISIBLE(C)                                                           \
  ((C->tags & C->mon->tagset[C->mon->seltags]) || C->issticky)
#define LENGTH(X) (sizeof X / sizeof X[0])
#define MOUSEMASK (BUTTONMASK | PointerMotionMask)
#define WIDTH(X) ((X)->w + 2 * (X)->bw)
#define HEIGHT(X) ((X)->h + 2 * (X)->bw)
#define TAGMASK ((1 << LENGTH(tags)) - 1)
#define TAGSLENGTH (LENGTH(tags))
#define TEXTW(X) (drw_fontset_getwidth(drw, (X)) + lrpad)

#define SYSTEM_TRAY_REQUEST_DOCK 0

/* XEMBED messages */
#define XEMBED_EMBEDDED_NOTIFY 0
#define XEMBED_WINDOW_ACTIVATE 1
#define XEMBED_FOCUS_IN 4
#define XEMBED_MODALITY_ON 10

#define XEMBED_MAPPED (1 << 0)
#define XEMBED_WINDOW_ACTIVATE 1
#define XEMBED_WINDOW_DEACTIVATE 2

#define VERSION_MAJOR 0
#define VERSION_MINOR 0
#define XEMBED_EMBEDDED_VERSION (VERSION_MAJOR << 16) | VERSION_MINOR

/* Enums */
enum { CurNormal, CurResize, CurMove, CurLast }; /* cursor */

/* EWMH atoms */
enum {
  NetSupported,
  NetWMName,
  NetWMState,
  NetWMCheck,
  NetSystemTray,
  NetSystemTrayOP,
  NetSystemTrayOrientation,
  NetSystemTrayOrientationHorz,
  NetWMFullscreen,
  NetActiveWindow,
  NetWMWindowType,
  NetWMWindowTypeDialog,
  NetClientList,
  NetDesktopNames,
  NetDesktopViewport,
  NetNumberOfDesktops,
  NetCurrentDesktop,
  NetLast
};

/* Xembed atoms */
enum { Manager, Xembed, XembedInfo, XLast };

/* Default atoms */
enum { WMProtocols, WMDelete, WMState, WMTakeFocus, WMWindowRole, WMLast };

/* Clicks */
enum {
  ClkTagBar,
  ClkLtSymbol,
  ClkStatusText,
  ClkWinTitle,
  ClkClientWin,
  ClkRootWin,
  ClkLast
};

typedef struct Monitor Monitor;
typedef struct Client Client;
typedef struct Pertag Pertag;
typedef struct Systray Systray;

typedef union {
  int i;
  unsigned int ui;
  float f;
  const void *v;
} Arg;

typedef struct {
  unsigned int click;
  unsigned int mask;
  unsigned int button;
  void (*func)(const Arg *arg);
  const Arg arg;
} Button;

typedef struct {
  unsigned int mod;
  KeySym keysym;
  void (*func)(const Arg *);
  const Arg arg;
} Key;

typedef struct {
  const char *symbol;
  void (*arrange)(Monitor *);
} Layout;

typedef struct {
  const char *class;
  const char *role;
  const char *instance;
  const char *title;
  unsigned int tags;
  int isfloating;
  int isterminal;
  int noswallow;
  int monitor;
  const char scratchkey;
} Rule;

typedef struct {
  int monitor;
  int tag;
  int layout;
  float mfact;
  int nmaster;
  int showbar;
  int topbar;
} MonitorRule;

struct Client {
  char name[256];
  float mina, maxa;
  float cfact;
  int x, y, w, h;
  int oldx, oldy, oldw, oldh;
  int basew, baseh, incw, inch, maxw, maxh, minw, minh, hintsvalid;
  int bw, oldbw;
  unsigned int tags;
  int isfixed, isfloating, isurgent, neverfocus, oldstate, isfullscreen,
      issticky, isterminal, noswallow;
  int fakefullscreen;
  char scratchkey;
  int ignorecfgreqpos, ignorecfgreqsize;
  pid_t pid;
  Client *next;
  Client *snext;
  Client *swallowing;
  Monitor *mon;
  Window win;
};

/* We only move this here to get the length of the `tags` array, which probably
 * will generate compatibility issues with other patches. To avoid it, I
 * reccomend patching this at the end or continue with the comment below */
struct Monitor {
  char ltsymbol[16];
  float mfact;
  int nmaster;
  int num;
  int by;             /* bar geometry */
  int mx, my, mw, mh; /* screen size */
  int wx, wy, ww, wh; /* window area  */
  int gappih;         /* horizontal gap between windows */
  int gappiv;         /* vertical gap between windows */
  int gappoh;         /* horizontal outer gaps */
  int gappov;         /* vertical outer gaps */
  unsigned int seltags;
  unsigned int sellt;
  unsigned int tagset[2];
  int previewshow;
  int showbar;
  int topbar;
  Client *clients;
  Client *sel;
  Client *stack;
  Monitor *next;
  Window barwin;
  Window tagwin;
  Pixmap tagmap[9];
  const Layout *lt[2];
  Pertag *pertag;
};

struct Pertag {
  unsigned int curtag, prevtag; /* current and previous tag */
  int nmasters[10];             /* number of windows in master area */
  float mfacts[10];             /* mfacts per tag */
  unsigned int sellts[10];      /* selected layouts */
  const Layout *ltidxs[10][2];  /* matrix of tags and layouts indexes  */
  int showbars[10];             /* display bar for the current tag */
  int enablegaps[10];           /* display bar for the current tag */
};

struct Systray {
  Window win;
  Client *icons;
};

/* Function declarations */
void applyrules(Client *c);
int applysizehints(Client *c, int *x, int *y, int *w, int *h, int interact);
void arrange(Monitor *m);
void arrangemon(Monitor *m);
void attach(Client *c);
void attachbottom(Client *c);
void attachstack(Client *c);
void buttonpress(XEvent *e);
void checkotherwm(void);
void cleanup(void);
void cleanupmon(Monitor *mon);
void clientmessage(XEvent *e);
void configure(Client *c);
void configurenotify(XEvent *e);
void configurerequest(XEvent *e);
Monitor *createmon(void);
void cyclelayout(const Arg *arg);
void destroynotify(XEvent *e);
void detach(Client *c);
void detachstack(Client *c);
Monitor *dirtomon(int dir);
void drawbar(Monitor *m);
void drawbars(void);
int drawstatusbar(Monitor *m, int bh, char *text, int stw);
void enternotify(XEvent *e);
void expose(XEvent *e);
void focus(Client *c);
void focusin(XEvent *e);
void focusmon(const Arg *arg);
void focusstack(const Arg *arg);
Atom getatomprop(Client *c, Atom prop);
int getrootptr(int *x, int *y);
long getstate(Window w);
unsigned int getsystraywidth();
pid_t getstatusbarpid();
int gettextprop(Window w, Atom atom, char *text, unsigned int size);
void grabbuttons(Client *c, int focused);
void grabkeys(void);
void incnmaster(const Arg *arg);
void keypress(XEvent *e);
void killclient(const Arg *arg);
void losefullscreen(Client *next);
void manage(Window w, XWindowAttributes *wa);
void mappingnotify(XEvent *e);
void maprequest(XEvent *e);
void motionnotify(XEvent *e);
void movemouse(const Arg *arg);
void movestack(const Arg *arg);
Client *nexttiled(Client *c);
void pop(Client *);
void propertynotify(XEvent *e);
void quit(const Arg *arg);
Monitor *recttomon(int x, int y, int w, int h);
void removesystrayicon(Client *i);
void replaceclient(Client *old, Client *new);
void resize(Client *c, int x, int y, int w, int h, int interact);
void resizebarwin(Monitor *m);
void resizeclient(Client *c, int x, int y, int w, int h);
void resizemouse(const Arg *arg);
void resizerequest(XEvent *e);
void restack(Monitor *m);
void run(void);
void runautostart(void);
void scan(void);
int sendevent(Window w, Atom proto, int m, long d0, long d1, long d2, long d3,
              long d4);
void sendmon(Client *c, Monitor *m);
void setclientstate(Client *c, long state);
void setcurrentdesktop(void);
void setdesktopnames(void);
void setfocus(Client *c);
void setfullscreen(Client *c, int fullscreen);
void setlayout(const Arg *arg);
void setcfact(const Arg *arg);
void setmfact(const Arg *arg);
void setnumdesktops(void);
void setup(void);
void setviewport(void);
void seturgent(Client *c, int urg);
void showhide(Client *c);
void showtagpreview(int tag);
void sigchld(int unused);
void sigstatusbar(const Arg *arg);
void spawn(const Arg *arg);
int swallow(Client *p, Client *c);
void swapfocus();
Monitor *systraytomon(Monitor *m);
void switchtag(void);
void tag(const Arg *arg);
void tagmon(const Arg *arg);
void togglebar(const Arg *arg);
void togglesticky(const Arg *arg);
void togglefullscr(const Arg *arg);
void togglefakefullscreen(const Arg *arg);
void togglefloating(const Arg *arg);
void togglefullscreen(const Arg *arg);
void toggletag(const Arg *arg);
void toggleview(const Arg *arg);
void unfocus(Client *c, int setfocus);
void unmanage(Client *c, int destroyed);
void unmapnotify(XEvent *e);
void updatecurrentdesktop(void);
void updatebarpos(Monitor *m);
void updatebars(void);
void updateborderonfocus(Client *c);
void updateborderonunfocus(Client *c);
void updateclientlist(void);
int updategeom(void);
void updatenumlockmask(void);
void updatesizehints(Client *c);
void updatestatus(void);
void updatesystray(void);
void updatesystrayicongeom(Client *i, int w, int h);
void updatesystrayiconstate(Client *i, XPropertyEvent *ev);
void updatetitle(Client *c);
void updatepreview(void);
void updatewindowtype(Client *c);
void updatewmhints(Client *c);
void view(const Arg *arg);
void warp(const Client *c);
Client *wintoclient(Window w);
Monitor *wintomon(Window w);
Client *wintosystrayicon(Window w);
int xerror(Display *dpy, XErrorEvent *ee);
int xerrordummy(Display *dpy, XErrorEvent *ee);
int xerrorstart(Display *dpy, XErrorEvent *ee);
void zoom(const Arg *arg);

void unswallow(Client *c);
pid_t getparentprocess(pid_t p);
int isdescprocess(pid_t p, pid_t c);
Client *swallowingclient(Window w);
Client *termforwin(const Client *c);
pid_t winpid(Window w);

// vanitygaps
/* Key binding functions */
void defaultgaps(const Arg *arg);
void incrgaps(const Arg *arg);
void incrigaps(const Arg *arg);
void incrogaps(const Arg *arg);
void incrohgaps(const Arg *arg);
void incrovgaps(const Arg *arg);
void incrihgaps(const Arg *arg);
void incrivgaps(const Arg *arg);
void togglegaps(const Arg *arg);

/* Internals */
void getgaps(Monitor *m, int *oh, int *ov, int *ih, int *iv, unsigned int *nc);
void getfacts(Monitor *m, int msize, int ssize, float *mf, float *sf, int *mr,
              int *sr);
void setgaps(int oh, int ov, int ih, int iv);

#endif
