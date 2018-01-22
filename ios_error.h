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
#define printf compileError
#endif

#define exit(a) pthread_exit(NULL)
#define _exit(a) pthread_exit(NULL)
#define putchar(a) fputc(a, thread_stdout)
#define getchar() fgetc(thread_stdin)
#define getwchar() fgetwc(thread_stdin)

// Thread-local input and output streams
extern __thread FILE* thread_stdin;
extern __thread FILE* thread_stdout;
extern __thread FILE* thread_stderr;

#endif /* ios_error_h */
