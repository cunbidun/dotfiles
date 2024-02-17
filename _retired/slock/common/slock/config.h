/* user and group to drop privileges to */
static const char *user = "nobody";
static const char *group = "nobody";

static const char *colorname[NUMCOLS] = {
    [INIT] = "#2E3440",   /* after initialization BG*/
    [INPUT] = "#5E81AC",  /* during input BLUE */
    [FAILED] = "#BF616A", /* wrong password RED*/
    [CAPS] = "#88C0D0",   /* CapsLock on Clear Ice*/
};

/* lock screen opacity */
static const float alpha = 0.5;

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 0;

/* default message */
static const char *message = "Enter password to unlock";

/* text color */
static const char *text_color = "#ECEFF4";

/* text size (must be a valid size) */
static const char *text_size =
    "-*-saucecodepro nf-medium-*-*--17-*-*-*-*-*-*-*";
