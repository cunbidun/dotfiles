#define CMDLENGTH 50
#define DELIMITER " │ "
// #define LEADING_DELIMITER
// #define CLICKABLE_BLOCKS

const Block blocks[] = {
  //    command            update time im sec             signal
  BLOCK("get_cpu",                      10,                   0)
  BLOCK("get_memory",                   10,                   0)
  BLOCK("get_internet",                 10,                   0)
  BLOCK("get_doge",                     10,                   0)
  BLOCK("get_battery",                   5,                  12)
  BLOCK("get_volume",                    0,                  10)
  BLOCK("get_temp",                     10,                   0)
  BLOCK("get_language",                  0,                  11)
	BLOCK("date '+%a %b %d, %H:%M:%S'",    1,                   0)
};
