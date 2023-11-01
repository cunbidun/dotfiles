#include "scratchpad.h"
#include "config.h"

void spawnscratch(const Arg *arg);

extern Monitor *mons, *selmon;
extern Display *dpy;

void togglescratch(const Arg *arg) {
  Client *target = NULL;
  for (Monitor *m = mons; m; m = m->next) {
    for (Client *c = m->clients; c; c = c->next) {
      if (c->scratchkey == ((char **)arg->v)[0][0]) {
        target = c;
      } else if (c->scratchkey) {
        c->tags = 0;
        arrange(m);
      }
    }
  }
  if (!target) {
    spawnscratch(arg);
  } else {
    if (ISVISIBLE(target) && target->mon == selmon) {
      target->tags = 0;
    } else {
      sendmon(target, selmon);
      target->tags = selmon->tagset[selmon->seltags];
    }
    updateclientdesktop(target);
    focus(NULL);
    arrange(selmon);
    if (ISVISIBLE(target)) {
      focus(target);
      restack(selmon);
    }
  }
}

void spawnscratch(const Arg *arg) {
  if (fork() == 0) {
    if (dpy)
      close(ConnectionNumber(dpy));
    setsid();
    execvp(((char **)arg->v)[1], ((char **)arg->v) + 1);
    fprintf(stderr, "dwm: execvp %s", ((char **)arg->v)[1]);
    perror(" failed");
    exit(EXIT_SUCCESS);
  }
}
