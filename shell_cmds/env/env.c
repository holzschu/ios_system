/*
 * Copyright (c) 1988, 1993, 1994
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef lint
static const char copyright[] =
"@(#) Copyright (c) 1988, 1993, 1994\n\
	The Regents of the University of California.  All rights reserved.\n";
#endif /* not lint */

#if 0
#ifndef lint
static char sccsid[] = "@(#)env.c	8.3 (Berkeley) 4/2/94";
#endif /* not lint */
#endif

#include <sys/cdefs.h>
__FBSDID("$FreeBSD$");

#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "envopts.h"
#include <TargetConditionals.h>
#include "ios_error.h"

extern char **environ;

__thread int	 env_verbosity;

static void usage(void);



int
env_main(int argc, char **argv)
{
	char *altpath, **ep, *p, **parg;
	char *cleanenv[1];
	int ch, want_clear;
	int rtrn;

	altpath = NULL;
	want_clear = 0;
    optind = 1; opterr = 1; optreset = 1;
	while ((ch = getopt(argc, argv, "-iP:S:u:v")) != -1)
		switch(ch) {
		case '-':
		case 'i':
			want_clear = 1;
			break;
		case 'P':
			altpath = strdup(optarg);
			break;
		case 'S':
			/*
			 * The -S option, for "split string on spaces, with
			 * support for some simple substitutions"...
			 */
			split_spaces(optarg, &optind, &argc, &argv);
			break;
		case 'u':
			if (env_verbosity)
				fprintf(thread_stderr, "#env unset:\t%s\n", optarg);
			rtrn = unsetenv(optarg);
            if (rtrn == -1) {
				err(EXIT_FAILURE, "unsetenv %s", optarg);
            }
			break;
		case 'v':
			env_verbosity++;
			if (env_verbosity > 1)
				fprintf(thread_stderr, "#env verbosity now at %d\n",
				    env_verbosity);
			break;
		case '?':
		default:
			usage();
		}
	if (want_clear) {
		environ = cleanenv;
		cleanenv[0] = NULL;
		if (env_verbosity)
			fprintf(thread_stderr, "#env clearing environ\n");
	}
	for (argv += optind; *argv && (p = strchr(*argv, '=')); ++argv) {
		if (env_verbosity)
			fprintf(thread_stderr, "#env setenv:\t%s\n", *argv);
		*p = '\0';
		rtrn = setenv(*argv, p + 1, 1);
		*p = '=';
        if (rtrn == -1) {
			err(EXIT_FAILURE, "setenv %s", *argv);
        }
	}
	if (*argv) {
		if (altpath)
			search_paths(altpath, argv);
		if (env_verbosity) {
			fprintf(thread_stderr, "#env executing:\t%s\n", *argv);
			for (parg = argv, argc = 0; *parg; parg++, argc++)
				fprintf(thread_stderr, "#env    arg[%d]=\t'%s'\n",
				    argc, *parg);
			if (env_verbosity > 1)
				sleep(1);
		}
        execvp(*argv, argv);
        err(errno == ENOENT ? 127 : 126, "%s", *argv);
	}
#if !TARGET_OS_IPHONE
        for (ep = environ; *ep != NULL; ep++)
#else
        for (ep = environmentVariables(ios_currentPid()); *ep != NULL; ep++)
#endif
		(void)fprintf(thread_stdout, "%s\n", *ep);
	exit(0);
}

static void
usage(void)
{
	(void)fprintf(thread_stderr,
	    "usage: env [-iv] [-P utilpath] [-S string] [-u name]\n"
	    "           [name=value ...] [utility [argument ...]]\n");
	exit(1);
}

#undef setenv
#undef unsetenv

int setenv_main(int argc, char** argv) {
    if (argc <= 1) return env_main(argc, argv);
    if (argc > 3) {
        fprintf(thread_stderr, "setenv: Too many arguments. Usage: setenv variable value\n"); fflush(thread_stderr);
        return 0;
    }
    // setenv VARIABLE value
    // First in the process environment (if it exists):
    if (argv[2] != NULL) ios_setenv(argv[1], argv[2], 1);
    else ios_setenv(argv[1], "", 1); // if there's no value, pass an empty string instead of a null pointer
    // and also in the main environment:
    if (argv[2] != NULL) setenv(argv[1], argv[2], 1);
    else setenv(argv[1], "", 1); // if there's no value, pass an empty string instead of a null pointer
    return 0;
}

int export_main(int argc, char** argv) {
    if ((argc <= 1) || (argc > 3)) {
        fprintf(thread_stderr, "usage: export variable=value\n"); fflush(thread_stderr);
        return 0;
    }
    char* argument = strdup(argv[1]);
    char* position = strstr(argument,"=");
    if (position == NULL) {
        fprintf(thread_stderr, "export: can't find '='. Usage: export variable=value\n"); fflush(thread_stderr);
        return 0;
    }
    *position = 0;
    // First in the process environment (if it exists):
    ios_setenv(argument, position+1, 1);
    // and also in the main environment:
    int returnValue = setenv(argument, position+1, 1);
    free(argument);
    return returnValue;
}

int unsetenv_main(int argc, char** argv) {
    if (argc <= 1) {
        fprintf(thread_stderr, "unsetenv: Too few arguments. Usage: unsetenv variable\n"); fflush(thread_stderr);
        return 0;
    }
    // unsetenv acts on all parameters. First in the process environment:
    for (int i = 1; i < argc; i++) ios_unsetenv(argv[i]);
    // also unset in the main environment:
    for (int i = 1; i < argc; i++) unsetenv(argv[i]);
    return 0;
}


