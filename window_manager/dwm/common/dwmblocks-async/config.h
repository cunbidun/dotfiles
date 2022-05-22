#define CMDLENGTH 50
#define DELIMITER " │ "
#define CLICKABLE_BLOCKS

const Block blocks[] = {
  //    command            update time im sec             signal
  BLOCK("get_cpu",                      10,                   1),
  BLOCK("get_memory",                   10,                   2),
  BLOCK("get_internet",                 10,                   3),
  // BLOCK("get_doge",                     10,                   4),
  BLOCK("get_battery",                   5,                  12),
  BLOCK("get_volume",                    0,                  10),
  BLOCK("get_temp",                     10,                  13),
  BLOCK("get_language",                  0,                  11),
	// BLOCK("sc_task",                       0,                  15),
  BLOCK("sc_weather",                    0,                  20),
	BLOCK("clock",                         1,                  14),
};
