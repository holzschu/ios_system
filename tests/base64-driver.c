// Host CLI adapter: compile the real command and option parser, supplying only ios_system's stream boundary.
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

__thread FILE *thread_stdin, *thread_stdout, *thread_stderr;
extern int base64_main(int, char **);
int ios_fputc(int c, FILE *f) { return fputc(c, f); }
int ios_fputs(const char *s, FILE *f) { return fputs(s, f); }
size_t ios_fwrite(const void *p, size_t s, size_t n, FILE *f) { return fwrite(p, s, n, f); }
int ios_fflush(FILE *f) { return fflush(f); }
char *ios_getenv(const char *s) { return getenv(s); }
void ios_exit(int status) { exit(status); }

int main(int argc, char **argv) {
    thread_stdin = stdin;
    thread_stdout = stdout;
    thread_stderr = stderr;
    return base64_main(argc, argv);
}
