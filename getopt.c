/*-
 * See the file LICENSE for redistribution information.
 *
 * Copyright (c) 1996,2008 Oracle.  All rights reserved.
 */
/*
 * Copyright (c) 1987, 1993, 1994
 *    The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
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
 *
 * $Id: getopt.c,v 12.8 2008/03/12 17:50:25 mbrey Exp $
 */

// #include "db_config.h"

// #include "db_int.h"
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "ios_error.h"

__thread int    __db_getopt_reset;    /* global reset for VxWorks. */

// The per-thread variables. ios_error.h maps optind & co to functions that return their addresses; in this file
// the names stand for the variables themselves.
#undef optind
#undef opterr
#undef optopt
#undef optreset
#undef optarg
#define optind ios_optind
#define opterr ios_opterr
#define optopt ios_optopt
#define optreset ios_optreset
#define optarg ios_optarg
__thread int    opterr = 1,        /* if error message should be printed */
optind = 1,        /* index into parent argv vector */
optopt,            /* character checked for validity */
optreset;        /* reset getopt */
__thread char    *optarg;        /* argument associated with option */

// Frameworks built before this change import getopt, getopt_long, optind and optarg from ios_system and read
// the results from the shared variables. getopt and getopt_long below keep serving them from these.
__attribute__((used)) int ios_shared_opterr __asm__("_opterr") = 1;
__attribute__((used)) int ios_shared_optind __asm__("_optind") = 1;
__attribute__((used)) int ios_shared_optopt __asm__("_optopt");
__attribute__((used)) int ios_shared_optreset __asm__("_optreset");
__attribute__((used)) char *ios_shared_optarg __asm__("_optarg");

#undef    BADCH
#define    BADCH    (int)'?'
#undef    BADARG
#define    BADARG    (int)':'
#undef    EMSG
#define    EMSG    ""

/*
 * getopt --
 *    Parse argc/argv argument vector.
 *
 * PUBLIC: #ifndef HAVE_GETOPT
 * PUBLIC: int getopt __P((int, char * const *, const char *));
 * PUBLIC: #endif
 */
int
ios_getopt(nargc, nargv, ostr)
int nargc;
char * const *nargv;
const char *ostr;
{
    static __thread char *progname;
    static __thread char *place = EMSG;        /* option letter processing */
    char *oli;                /* option letter list index */
    
    /*
     * VxWorks needs to be able to repeatedly call getopt from multiple
     * programs within its global name space. And so does iOS.
     */
    if (__db_getopt_reset) {
        __db_getopt_reset = 0;
        
        opterr = optind = 1;
        optopt = optreset = 0;
        optarg = NULL;
        progname = NULL;
        place = EMSG;
    }
    if (!progname) {
        // if ((progname = __db_rpath(*nargv)) == NULL)
            progname = *nargv;
        // else
        //    ++progname;
    }
    
    if (optreset || !*place) {        /* update scanning pointer */
        optreset = 0;
        if (optind >= nargc || *(place = nargv[optind]) != '-') {
            place = EMSG;
            return (EOF);
        }
        if (place[1] && *++place == '-') {    /* found "--" */
            ++optind;
            place = EMSG;
            return (EOF);
        }
    }                    /* option letter okay? */
    if ((optopt = (int)*place++) == (int)':' ||
        !(oli = strchr(ostr, optopt))) {
        /*
         * if the user didn't specify '-' as an option,
         * assume it means EOF.
         */
        if (optopt == (int)'-')
            return (EOF);
        if (!*place)
            ++optind;
        if (opterr && *ostr != ':')
            (void)fprintf(thread_stderr,
                          "%s: illegal option -- %c\n", progname, optopt);
        return (BADCH);
    }
    if (*++oli != ':') {            /* don't need argument */
        optarg = NULL;
        if (!*place)
            ++optind;
    }
    else {                    /* need an argument */
        if (*place)            /* no white space */
            optarg = place;
        else if (nargc <= ++optind) {    /* no arg */
            place = EMSG;
            if (*ostr == ':')
                return (BADARG);
            if (opterr)
                (void)fprintf(thread_stderr,
                              "%s: option requires an argument -- %c\n",
                              progname, optopt);
            return (BADCH);
        }
        else                /* white space */
            optarg = nargv[optind];
        place = EMSG;
        ++optind;
    }
    return (optopt);            /* dump back option letter */
}

// Exported names for callers built without ios_error.h: they parse with the per-thread state, while the shared
// variables stay the ones they read and write.
static void legacy_enter(void) {
    ios_optind = ios_shared_optind;
    ios_opterr = ios_shared_opterr;
    ios_optopt = ios_shared_optopt;
    ios_optreset = ios_shared_optreset;
    ios_optarg = ios_shared_optarg;
}

static void legacy_leave(void) {
    ios_shared_optind = ios_optind;
    ios_shared_opterr = ios_opterr;
    ios_shared_optopt = ios_optopt;
    ios_shared_optreset = ios_optreset;
    ios_shared_optarg = ios_optarg;
}

#undef getopt
int getopt(int nargc, char * const *nargv, const char *ostr) {
    legacy_enter();
    int result = ios_getopt(nargc, nargv, ostr);
    legacy_leave();
    return result;
}

#undef getopt_long
int getopt_long(int nargc, char * const *nargv, const char *options, const struct option *long_options, int *idx) {
    legacy_enter();
    int result = ios_getopt_long(nargc, nargv, options, long_options, idx);
    legacy_leave();
    return result;
}

#undef getopt_long_only
int getopt_long_only(int nargc, char * const *nargv, const char *options, const struct option *long_options, int *idx) {
    legacy_enter();
    int result = ios_getopt_long_only(nargc, nargv, options, long_options, idx);
    legacy_leave();
    return result;
}

// Called when a command starts: its option parsing begins at argv[1], for the per-thread state and for the shared
// variables that callers built without ios_error.h read. The shared stores are atomic because every command
// thread makes them.
void ios_getoptReset(void) {
    ios_optind = ios_opterr = ios_optreset = 1;
    __atomic_store_n(&ios_shared_optind, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&ios_shared_opterr, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&ios_shared_optreset, 1, __ATOMIC_RELAXED);
}

int *ios_optind_ref(void) { return &ios_optind; }
int *ios_opterr_ref(void) { return &ios_opterr; }
int *ios_optopt_ref(void) { return &ios_optopt; }
int *ios_optreset_ref(void) { return &ios_optreset; }
char **ios_optarg_ref(void) { return &ios_optarg; }
