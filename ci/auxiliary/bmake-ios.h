#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <signal.h>
#include <sys/wait.h>
#include "ios_error.h"
#undef stdin
#undef stdout
#undef stderr
#define stdin thread_stdin
#define stdout thread_stdout
#define stderr thread_stderr
#define printf(...) fprintf(thread_stdout, __VA_ARGS__)

/* Public ios_system.h API; that header also imports Objective-C types. */
extern void storeEnvironment(char *envp[]);
