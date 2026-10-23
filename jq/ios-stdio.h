/* Bind jq's standard C streams to its ios_system command thread. */
#ifndef JQ_IOS_STDIO_H
#define JQ_IOS_STDIO_H
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern __thread FILE *thread_stdin;
extern __thread FILE *thread_stdout;
extern __thread FILE *thread_stderr;
extern void ios_exit(int status) __attribute__((noreturn));
extern char *ios_getenv(const char *name);

static inline int jq_ios_isatty(int fd) {
    if (fd == STDIN_FILENO) fd = fileno(thread_stdin);
    else if (fd == STDOUT_FILENO) fd = fileno(thread_stdout);
    else if (fd == STDERR_FILENO) fd = fileno(thread_stderr);
    return isatty(fd);
}

static inline void jq_ios_perror(const char *message) {
    int error = errno;
    fprintf(thread_stderr, "%s: %s\n", message, strerror(error));
}

#undef stdin
#undef stdout
#undef stderr
#define stdin thread_stdin
#define stdout thread_stdout
#define stderr thread_stderr
#define printf(...) fprintf(thread_stdout, __VA_ARGS__)
#define perror jq_ios_perror
#define isatty jq_ios_isatty
#define getenv ios_getenv
#define exit ios_exit
#endif
