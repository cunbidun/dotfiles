/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1; /* -b  option; if 0, dmenu appears at bottom     */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {"Source Code Pro:size=10"};

static const char nord0[] = "#2E3440";
static const char nord1[] = "#3B4252";
static const char nord2[] = "#434C5E";
static const char nord3[] = "#4C566A";
static const char nord4[] = "#D8DEE9";
static const char nord5[] = "#E5E9F0";
static const char nord6[] = "#ECEFF4";
static const char nord7[] = "#8FBCBB";
static const char nord8[] = "#88c0d0";
static const char nord9[] = "#81A1C1";
static const char nord10[] = "#5E81AC";
static const char nord11[] = "#BF616A";
static const char nord12[] = "#D08770";
static const char nord13[] = "#EBCB8B";
static const char nord14[] = "#A3BE8C";
static const char nord15[] = "#B48EAD";

static const char *prompt =
    NULL; /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
    /*     fg         bg       */
    [SchemeNorm] = {nord4, nord0},
    [SchemeSel] = {nord0, nord9},
    [SchemeOut] = {nord4, nord0},
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
