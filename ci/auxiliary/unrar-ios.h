#include "ios_error.h"
#undef stdin
#undef stdout
#undef stderr
#define stdin thread_stdin
#define stdout thread_stdout
#define stderr thread_stderr
#define printf(...) fprintf(thread_stdout, __VA_ARGS__)
#define wprintf(...) fwprintf(thread_stdout, __VA_ARGS__)
