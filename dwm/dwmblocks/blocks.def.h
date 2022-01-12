//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
    /*Icon*/          /*Command*/                     /*Update Interval*/ /*Update Signal*/
    {"",  "get_cpu",                     10,                   0},
    {"",  "get_memory",                  10,                   0},
    {"",  "get_internet",                10,                   0},
    {"",  "get_doge",                    10,                   0},
    // {"\x09MM: ",   "mm", 10, 0},
    {"",  "get_battery",                   5,                   12},
    {"",  "get_volume",                   30,                  10},
    {"",  "get_temp",                     10,                   0},
    {"",  "get_language",                 30,                  11},
    {"",  "date '+%a %b %d, %H:%M:%S'",    1,                    0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " │ ";
static unsigned int delimLen = 5;
