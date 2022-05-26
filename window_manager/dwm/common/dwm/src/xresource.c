#include "appearance.h"
#include "config.h"
#include "dwm.h"

extern char scheme_fg[];
extern char scheme_bg[];
extern char scheme_norm[];
extern char scheme_sym_bg[];
extern char scheme_sel[];
extern char scheme_urg[];

ResourcePref resources[] = {
    {"scheme_fg", STRING, &scheme_fg},
    {"scheme_bg", STRING, &scheme_bg},
    {"scheme_norm", STRING, &scheme_norm},
    {"scheme_sym_bg", STRING, &scheme_sym_bg},
    {"scheme_sym_fg", STRING, &scheme_sym_fg},
    {"scheme_sel", STRING, &scheme_sel},
    {"scheme_urg", STRING, &scheme_urg},

    /* Color */
    {"schemered", STRING, &schemered},
    {"schemeyellow", STRING, &schemeyellow},
    {"schemegreen", STRING, &schemegreen},
    {"schemeblue", STRING, &schemeblue},

    {"borderpx", INTEGER, &borderpx},
    // { "snap",          		        INTEGER,            &snap },
    // { "showbar",          	      INTEGER,            &showbar },
    // { "topbar",          	        INTEGER,            &topbar },
    // { "nmaster",          	      INTEGER,            &nmaster },
    // { "resizehints",       	      INTEGER,            &resizehints },
    // { "mfact",      	 	          FLOAT,              &mfact },
};
void resource_load(XrmDatabase db, char *name, enum resource_type rtype, void *dst) {
  char *sdst  = NULL;
  int *idst   = NULL;
  float *fdst = NULL;

  sdst = dst;
  idst = dst;
  fdst = dst;

  char fullname[256];
  char *type;
  XrmValue ret;

  snprintf(fullname, sizeof(fullname), "%s.%s", "dwm", name);
  fullname[sizeof(fullname) - 1] = '\0';

  XrmGetResource(db, fullname, "*", &type, &ret);
  if (!(ret.addr == NULL || strncmp("String", type, 64))) {
    switch (rtype) {
    case STRING:
      strcpy(sdst, ret.addr);
      break;
    case INTEGER:
      *idst = strtoul(ret.addr, NULL, 10);
      break;
    case FLOAT:
      *fdst = strtof(ret.addr, NULL);
      break;
    }
  }
}

void load_xresources(void) {
  Display *display;
  char *resm;
  XrmDatabase db;
  ResourcePref *p;

  display = XOpenDisplay(NULL);
  resm    = XResourceManagerString(display);
  if (!resm)
    return;

  db = XrmGetStringDatabase(resm);
  for (p = resources; p < resources + LENGTH(resources); p++)
    resource_load(db, p->name, p->type, p->dst);
  XCloseDisplay(display);
}
