/* See LICENSE file for copyright and license details. */

/* appearance */
static const char font[]        = "Source Code Pro:size=10";
static const char* normbgcolor  = "#2E3440";
static const char* normfgcolor  = "#ECEFF4";
static const char* selbgcolor   = "#81A1C1";
static const char* selfgcolor   = "#2E3440";
static const char* urgbgcolor   = "#2E3440";
static const char* urgfgcolor   = "#BF616A";
static const char before[]      = "<";
static const char after[]       = ">";
static const char titletrim[]   = "...";
static const int  tabwidth      = 200;
static const Bool foreground    = True;
static       Bool urgentswitch  = True;

/*
 * Where to place a new tab when it is opened. When npisrelative is True,
 * then the current position is changed + newposition. If npisrelative
 * is False, then newposition is an absolute position.
 */
static int  newposition   = 1;
static Bool npisrelative  = True;

#define SETPROP(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
                "prop=\"$(xwininfo -children -id $1 | grep '^     0x' |" \
                "sed -e's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1 \\2@' |" \
                "tail -n +2 | dmenu -i -l 10 -p 'Switch to: ')\" &&" \
                "xprop -id $1 -f $0 8s -set $0 \"$prop\"", \
                p, winid, NULL \
        } \
}

/* Modify the following line to match your terminal and software list */
#define OPENTERMSOFT(p) { \
	.v = (char *[]){ "/bin/sh", "-c", \
		"term='alacritty' && titlearg='-t' && embedarg='--embed' &&" \
		"softlist=$(printf '%s\n' \"htop\" \"lvim\" \"ranger\" \"nmtui\") &&" \
		"printf '%s' \"$softlist\" |" \
		"dmenu -i -p 'Softwares to run: ' |" \
		"xargs -I {} $term $titlearg \"{}\" $embedarg $1 -e \"{}\"", \
		p, winid, NULL \
	} \
}

#define OPENTERM(p) { \
	.v = (char *[]){ "/bin/sh", "-c", "term='alacritty' && titlearg='-t' && embedarg='--embed' && $term $embedarg $1", p, winid, NULL } \
}


// /* Modify the following line to match your terminal*/
// #define OPENTERM(p) { \
// 	.v = (char *[]){ "/bin/sh", "-c", \
// 		"term='alacritty' && embedarg='--embed' &&" \
// 		"cd \"$(xwininfo -children -id $1 | grep '^     0x' |" \
//                 "sed -e's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1 \\2@' |" \
// 		"dmenu -i -l 10 -p 'New term path based on: ' |" \
// 		"cut -f 1 | xargs -I {} xprop -id \"{}\" | grep _NET_WM_PID |" \
// 		"cut -d ' ' -f 3 | xargs -I {} pstree -p \"{}\" |" \
// 		"cut -d '(' -f 3 | cut -d ')' -f 1 |" \
// 		"xargs -I {} readlink -e /proc/\"{}\"/cwd/)\" &&" \
// 		"$term $embedarg $1", \
// 		p, winid, NULL \
// 	} \
// }

/* deskid: id for current workspace */
/* rootid: id for root window */
/* window: data for chosen window by dmenu */
/* wid: chosen window's window id */
/* wname: chosen window's name */
/* cwid: chosen window's child window id (tabbed window only) */
#define ATTACHWIN(p) { \
	.v = (char *[]){ "/bin/sh", "-c", \
		"deskid=$(xdotool get_desktop) &&" \
		"rootid=\"$(xwininfo -root | grep \"Window id\" | cut -d ' ' -f 4)\" &&" \
		"window=\"$(wmctrl -x -l | grep -E \" $deskid \" |" \
		"grep -v $(printf '0x0%x' \"$1\") | dmenu -i -l 20 -p \"Attach: \")\" &&" \
		"wid=$(printf '%s' \"$window\" | cut -d ' ' -f 1) &&" \
		"wname=$(printf '%s' \"$window\" | cut -d ' ' -f 2) &&" \
		"[ \"$wname\" = \"tabbed.tabbed\" ] &&" \
		"cwid=$(xwininfo -children -id \"$wid\" | grep '^     0x' |" \
                "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@') &&" \
		"for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$rootid\"; done &&" \
		"for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$1\"; done ||" \
		"xdotool windowreparent \"$wid\" $1", \
		p, winid, NULL \
	} \
}

#define ATTACHSELECTWIN(p) { \
	.v = (char *[]){ "/bin/sh", "-c", \
		"rootid=\"$(xwininfo -root | grep \"Window id\" | cut -d ' ' -f 4)\" &&" \
		"wid=$(xdotool selectwindow) &&" \
		"wname=$(xwininfo -id \"$wid\" | grep 'Window id:' | cut -d ' ' -f 5-) &&" \
		"[ \"$wname\" = \"(has no name)\" ] &&" \
		"cwid=$(xwininfo -children -id \"$wid\" | grep '^     0x' |" \
                "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@') &&" \
		"for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$rootid\"; done &&" \
		"for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$1\"; done ||" \
		"xdotool windowreparent \"$wid\" $1", \
		p, winid, NULL \
	} \
}

#define ATTACHALL(p) { \
	.v = (char *[]){ "/bin/sh", "-c", \
		"deskid=$(xdotool get_desktop) &&" \
		"rootid=\"$(xwininfo -root | grep \"Window id\" | cut -d ' ' -f 4)\" &&" \
		"window=\"$(wmctrl -x -l | grep -E \" $deskid \" |" \
		"grep -v $(printf '0x0%x' \"$1\") | cut -d ' ' -f 1,4)\" &&" \
		"IFS=':' &&" \
		"for win in $(printf '%s' \"$window\" | tr '\n' ':'); do unset IFS &&" \
		    "wid=$(printf '%s' \"$win\" | cut -d ' ' -f 1) &&" \
		    "wname=$(printf '%s' \"$win\" | cut -d ' ' -f 2) &&" \
		    "[ \"$wname\" = \"tabbed.tabbed\" ] &&" \
		    "{ cwid=$(xwininfo -children -id \"$wid\" | grep '^     0x' |" \
		    "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@') &&" \
		    "for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$rootid\"; done &&" \
		    "for id in $(printf '%s' \"$cwid\"); do xdotool windowreparent \"$id\" \"$1\"; done; } ||" \
		"xdotool windowreparent \"$wid\" $1; done", \
		p, winid, NULL \
	} \
}

#define DETACHWIN(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
		"rootid=\"$(xwininfo -root | grep \"Window id\" | cut -d ' ' -f 4)\" &&" \
    "wid=\"$(xwininfo -children -id $1 | grep '^     0x' | head -n 1 | sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@')\" && " \
		"xwininfo -id $wid -stats | grep -q 'IsUnMapped' && xdotool windowmap $wid;" \
		"xdotool windowreparent \"$wid\" \"$rootid\" &&" \
		"xdotool windowactivate $1", \
                p, winid, NULL \
        } \
}

#define DETACHALL(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
		"rootid=\"$(xwininfo -root | grep \"Window id\" | cut -d ' ' -f 4)\" &&" \
                "wid=\"$(xwininfo -children -id $1 | grep '^     0x' |" \
                "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@')\" &&" \
		"IFS=':' &&" \
		"for id in $(printf '%s' \"$wid\" | tr '\n' ':'); do unset IFS &&" \
		    "xdotool windowreparent \"$id\" \"$rootid\" &&" \
		    "xwininfo -id $id -stats |" \
		    "grep -q 'IsUnMapped' &&" \
		    "xdotool windowmap $id; done", \
                p, winid, NULL \
        } \
}

#define SHOWHIDDEN(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
                "cwin=\"$(xwininfo -children -id $1 | grep '^     0x' |" \
                "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1 \\2@')\" &&" \
		"IFS=':' &&" \
		"for win in $(printf '%s' \"$cwin\" | tr '\n' ':'); do unset IFS &&" \
		    "cwid=$(printf '%s' \"$win\" | cut -d ' ' -f 1) &&" \
		    "xwininfo -id $cwid -stats |" \
		    "grep -q 'IsUnMapped' &&" \
		    "printf '%s\n' \"$win\"; done |" \
		"dmenu -i -l 5 -p \"Show hidden window:\" |" \
		"cut -d ' ' -f 1 |" \
		"xargs -I {} xdotool windowmap \"{}\"", \
                p, winid, NULL \
        } \
}

#define SHOWHIDDENALL(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
                "cwid=\"$(xwininfo -children -id $1 | grep '^     0x' |" \
                "sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@')\" &&" \
		"IFS=':' &&" \
		"for id in $(printf '%s' \"$cwid\" | tr '\n' ':'); do unset IFS &&" \
		    "xwininfo -id $id -stats | " \
		    "grep -q 'IsUnMapped' &&" \
		    "xdotool windowmap $id; done", \
                p, winid, NULL \
        } \
}

#define HIDEWINDOW(p) { \
        .v = (char *[]){ "/bin/sh", "-c", \
    "cwid=\"$(xwininfo -children -id $1 | grep '^     0x' | sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@')\" &&" \
		"IFS=':' && winnum=0 &&" \
		"for id in $(printf '%s' \"$cwid\" | tr '\n' ':'); do unset IFS &&" \
		    "xwininfo -id $id -stats | " \
		    "grep -q 'IsViewable' &&" \
		    "winnum=$(($winnum+1)); done;" \
    "[ $winnum -gt 1 ] && { xwininfo -children -id $1 | grep '^     0x' | head -n 1 | sed -e 's@^ *\\(0x[0-9a-f]*\\) \"\\([^\"]*\\)\".*@\\1@' | xargs -I {} xdotool windowunmap \"{}\"; }", \
                p, winid, NULL \
        } \
}


#define MODKEY Mod4Mask
#define ALTKEY Mod1Mask

static Key keys[] = {
	/* modifier                             key                              function                                       argument */
	{ MODKEY,                               XK_b,                             togglebar,                                     { 0 } },
  { MODKEY|ShiftMask,                     XK_c,                             killclient,                                    { 0 } },

	{ MODKEY,                               XK_l,                             rotate,                                        { .i = +1 } },
	{ MODKEY,                               XK_h,                             rotate,                                        { .i = -1 } },
	{ MODKEY|ShiftMask,                     XK_l,                             movetab,                                       { .i = +1 } },
	{ MODKEY|ShiftMask,                     XK_h,                             movetab,                                       { .i = -1 } },

  // Switching between the last 2 terminal
	{ MODKEY,                               XK_Tab,                           rotate,                                        { .i = 0 } },

  /* Move between tabs */                 
	{ MODKEY,                               XK_1,                             move,                                          { .i = 0 } },
	{ MODKEY,                               XK_2,                             move,                                          { .i = 1 } },
	{ MODKEY,                               XK_3,                             move,                                          { .i = 2 } },
	{ MODKEY,                               XK_4,                             move,                                          { .i = 3 } },
	{ MODKEY,                               XK_5,                             move,                                          { .i = 4 } },
	{ MODKEY,                               XK_6,                             move,                                          { .i = 5 } },
	{ MODKEY,                               XK_7,                             move,                                          { .i = 6 } },
	{ MODKEY,                               XK_8,                             move,                                          { .i = 7 } },
	{ MODKEY,                               XK_9,                             move,                                          { .i = 8 } },
	{ MODKEY,                               XK_0,                             move,                                          { .i = 9 } },

	{ MODKEY,                               XK_u,                             focusurgent,                                   { 0 } },
	{ MODKEY|ShiftMask,                     XK_u,                             toggle,                                        { .v = (void*) &urgentswitch } },

  // Attacth and Detach
	{ MODKEY,                               XK_Return,                        spawn,                                         OPENTERM("_TABBED_TERM") }, // Create new termminal
	{ MODKEY,                               XK_p,                             spawn,                                         OPENTERMSOFT("_TABBED_SELECT_TERMAPP") }, // open term app
	{ MODKEY|ShiftMask,                     XK_p,                             spawn,                                         SETPROP("_TABBED_SELECT_TAB") }, // dmenu picker for selecting other tab
	{ MODKEY,                               XK_a,	                            spawn,                                         ATTACHWIN("_TABBED_ATTACH_WIN") },
	{ MODKEY|ShiftMask,                     XK_a,                             spawn,                                         ATTACHALL("_TABBED_ATTACH_ALL") },
	{ MODKEY,                               XK_d,	                            spawn,                                         DETACHWIN("_TABBED_DETACH_WIN") },
	{ MODKEY|ShiftMask,                     XK_d,                             spawn,                                         DETACHALL("_TABBED_DETACH_ALL") },
	{ MODKEY|ShiftMask,                     XK_s,	                            spawn,                                         ATTACHSELECTWIN("_TABBED_ATTACH_WIN") },

  // Hide and unhide
	{ MODKEY|ShiftMask|ControlMask,         XK_c,                             spawn,                                         HIDEWINDOW("_TABBED_HIDE_WINDOW") },
	{ MODKEY,                               XK_o,                             spawn,                                         SHOWHIDDEN("_TABBED_SHOW_HIDDEN") },
	{ MODKEY|ShiftMask,                     XK_o,                             spawn,                                         SHOWHIDDENALL("_TABBED_SHOW_HIDDEN_ALL") },
};
