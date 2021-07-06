//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
    /*Icon*/ /*Command*/ /*Update Interval*/ /*Update Signal*/
    {"MEM: ", "free -h | awk '/^Mem/ { print $3\"/\"$2 }' | sed s/i//g", 20, 0},
    {"NET: ", "get_internet", 30, 0},
    {"DOGE: ", "get_doge", 30, 0},
    {"BAT: ", "get_battery", 10, 0},
    {"VOL: " , "get_volume", 30, 10},
    {"TEMP: ", "get_temp", 10, 0},
    {"LANG: " , "get_language", 30, 11},
    {"", "date '+%a %b %d, %H:%M:%S'", 1, 0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " │ ";
static unsigned int delimLen = 5;
