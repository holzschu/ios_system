//
//  error.h
//  shell_cmds_ios
//
//  Created by Nicolas Holzschuch on 16/06/2017.
//  Copyright © 2017 Nicolas Holzschuch. All rights reserved.
//

#ifndef ios_error_h
#define ios_error_h

#ifdef __cplusplus
extern "C" {
#endif

#include <unistd.h>
#include <stdarg.h>
#include <stdio.h>
#include <pthread.h>
#include <sys/signal.h>

/* #define errx compileError
#define err compileError
#define warn compileError
#define warnx compileError
#ifndef printf
#define printf(...) fprintf (thread_stdout, ##__VA_ARGS__)
#endif */

#define putchar(a) fputc(a, thread_stdout)
#define getchar() fgetc(thread_stdin)
// these functions are defined differently in C++. The #define approach breaks things.
#ifndef __cplusplus
  #define getwchar() fgetwc(thread_stdin)
  #define putwchar(a) fputwc(a, thread_stdout)
  // iswprint depends on the given locale, and setlocale() fails on iOS:
  #define iswprint(a) 1
  #define write ios_write
  #define fwrite ios_fwrite
  #define puts ios_puts
  #define fputs ios_fputs
  #define fputc ios_fputc
  #define putw ios_putw
  #define putp ios_putp
  #define fflush ios_fflush
  #define abort() ios_exit(1)
#endif

// Thread-local input and output streams
extern __thread FILE* thread_stdin;
extern __thread FILE* thread_stdout;
extern __thread FILE* thread_stderr;

#define exit ios_exit
#define _exit ios_exit
#define kill ios_killpid
#define _kill ios_killpid
#define killpg ios_killpid
#define popen ios_popen
#define pclose fclose
#define system ios_system
#define execv ios_execv
#define execvp ios_execv
#define execve ios_execve
#define dup2 ios_dup2
#define getenv ios_getenv
#define setenv ios_setenv
#define unsetenv ios_unsetenv
#define putenv ios_putenv
#define fchdir ios_fchdir
#define signal ios_signal

extern int ios_executable(const char* cmd); // is this command part of the "shell" commands?
extern int ios_system(const char* inputCmd); // execute this command (executable file or builtin command)
extern FILE *ios_popen(const char *command, const char *type); // Execute this command and pipe the result
extern int ios_kill(void); // kill the current running command
extern int ios_killpid(pid_t pid, int sig); // kill the current running command

extern void ios_exit(int errorCode) __dead2; // set error code and exits from the thread.
extern int ios_execv(const char *path, char* const argv[]);
extern int ios_execve(const char *path, char* const argv[], char** envlist);
extern int ios_dup2(int fd1, int fd2);
extern char * ios_getenv(const char *name);
extern int ios_setenv(const char* variableName, const char* value, int overwrite);
int ios_unsetenv(const char* variableName);
extern int ios_putenv(char *string);
extern char** environmentVariables(pid_t pid);

extern int ios_isatty(int fd);
extern pthread_t ios_getLastThreadId(void);  // deprecated
extern pthread_t ios_getThreadId(pid_t pid);
extern void ios_storeThreadId(pthread_t thread);
extern void ios_releaseThread(pthread_t thread);
extern void ios_releaseThreadId(pid_t pid);
extern pid_t ios_currentPid(void);
extern int ios_getCommandStatus(void);
extern const char* ios_progname(void);
extern pid_t ios_fork(void);
extern void ios_waitpid(pid_t pid);
extern pid_t ios_full_waitpid(pid_t pid, int *stat_loc, int options);

// Catch signal definition:
extern int canSetSignal(void);
extern sig_t ios_signal(int signal, sig_t function);


extern int ios_fchdir(const int fd);
extern ssize_t ios_write(int fildes, const void *buf, size_t nbyte);
extern size_t ios_fwrite(const void *ptr, size_t size, size_t nitems, FILE *stream);
extern int ios_puts(const char *s);
extern int ios_fputs(const char* s, FILE *stream);
extern int ios_fputc(int c, FILE *stream);
extern int ios_putw(int w, FILE *stream);
extern int ios_fflush(FILE *stream);
extern int ios_getstdin(void);
extern int ios_gettty(void);
extern int ios_opentty(void);
extern void ios_closetty(void);
extern void ios_stopInteractive(void);
extern void ios_startInteractive(void);
extern int ios_storeInteractive(void);
// Communication between dash and ios_system:
extern const char* ios_expandtilde(const char *login);
extern void ios_activateChildStreams(FILE** old_stdin, FILE** old_stdout,  FILE ** old_stderr);
extern const char* ios_getBookmarkedVersion(const char* p);

#ifdef __cplusplus
}
#endif
#endif /* ios_error_h */
