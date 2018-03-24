//
//  error.h
//  shell_cmds_ios
//
//  Created by Nicolas Holzschuch on 16/06/2017.
//  Copyright © 2017 Nicolas Holzschuch. All rights reserved.
//

#ifndef ios_error_h
#define ios_error_h

#include <stdarg.h>
#include <stdio.h>
#include <pthread.h>

#define errx compileError
#define err compileError
#define warn compileError
#define warnx compileError
#ifndef printf
#define printf(...) fprintf (thread_stdout, ##__VA_ARGS__)
#endif

#define putchar(a) fputc(a, thread_stdout)
#define getchar() fgetc(thread_stdin)
#define getwchar() fgetwc(thread_stdin)
// iswprint depends on the given locale, and setlocale() fails on iOS:
#define iswprint(a) 1


// Thread-local input and output streams
extern __thread FILE* thread_stdin;
extern __thread FILE* thread_stdout;
extern __thread FILE* thread_stderr;

#define exit ios_exit
#define _exit ios_exit
#define popen ios_popen
#define pclose fclose
#define system ios_system
#define execv ios_execv
#define execve ios_execve
#define dup2 ios_dup2

extern int ios_executable(char* cmd); // is this command part of the "shell" commands?
extern int ios_system(const char* inputCmd); // execute this command (executable file or builtin command)
extern FILE *ios_popen(const char *command, const char *type); // Execute this command and pipe the result
extern int ios_kill(FILE* stream); // kill the current running command

extern void ios_exit(int errorCode) __dead2; // set error code and exits from the thread.
extern int ios_execv(const char *path, char* const argv[]);
extern int ios_execve(const char *path, char* const argv[], const char** envlist);
extern int ios_dup2(int fd1, int fd2);

#endif /* ios_error_h */
