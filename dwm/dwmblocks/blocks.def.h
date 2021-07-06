//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
    /*Icon*/ /*Command*/ /*Update Interval*/ /*Update Signal*/
    {"CPU: ", "get_cpu", 10, 0},
    {"MEM: ", "get_memory", 10, 0},
    {"NET: ", "get_internet", 10, 0},
    {"DOGE: ", "get_doge", 10, 0},
    {"BAT: ", "get_battery", 5, 12},
    {"VOL: " , "get_volume", 30, 10},
    {"TEMP: ", "get_temp", 10, 0},
    {"LANG: " , "get_language", 30, 11},
    {"", "date '+%a %b %d, %H:%M:%S'", 1, 0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " │ ";
static unsigned int delimLen = 5;
