/****************************************************************
Copyright (C) Lucent Technologies 1997
All Rights Reserved

Permission to use, copy, modify, and distribute this software and
its documentation for any purpose and without fee is hereby
granted, provided that the above copyright notice appear in all
copies and that both that the copyright notice and this
permission notice and warranty disclaimer appear in supporting
documentation, and that the name Lucent Technologies or any of
its entities not be used in advertising or publicity pertaining
to distribution of the software without specific, written prior
permission.

LUCENT DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
IN NO EVENT SHALL LUCENT OR ANY OF ITS ENTITIES BE LIABLE FOR ANY
SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER
IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
****************************************************************/

const char	*version = "version 20200816";

#define DEBUG
#include <stdio.h>
#include <ctype.h>
#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include "awk.h"

// #ifdef __APPLE__
// #include "get_compat.h"
// #else
#define COMPAT_MODE(func, mode) 1
// #endif
#include <TargetConditionals.h>
#include "ios_error.h"

extern	char	**environ;
extern	__thread int	nfields;

__thread int	dbg	= 0;
__thread Awkfloat	srand_seed = 1;
__thread char	*cmdname;	/* gets argv[0] for error messages */
extern	__thread FILE	*yyin;	/* lex input file */
__thread char	*lexprog;	/* points to program argument if it exists */
extern	__thread int errorflag;	/* non-zero if any syntax errors; set by yyerror */
__thread enum compile_states	compile_time = ERROR_PRINTING;

static __thread char	**pfile;	/* program filenames from -f's */
static __thread size_t	maxpfile;	/* max program filename */
static __thread size_t	npfile;		/* number of filenames */
static __thread size_t	curpfile;	/* current filename */

__thread bool	safe = false;	/* true => "safe" mode */
__thread int	Unix2003_compat;

static void initializeVariables() {
    // initialize all flags:
    cmdname = NULL;
    extern __thread int    infunc;
    infunc = 0;    /* = 1 if in arglist or body of func */
    extern __thread int    inloop;
    inloop = 0;    /* = 1 if in while, for, do */

    extern __thread int    *setvec;
    extern __thread int    *tmpset;
    if (setvec != 0) {    /* first time through any RE */
        free(setvec); setvec = 0;
        free(tmpset); tmpset = 0;
    }
    yyin = 0;
    nfields    = 2; // MAXFLD
    npfile = 0;
    curpfile = 0;
    compile_time = 2;
    errorflag = 0;
    lexprog = 0;
    extern __thread int firsttime;
    firsttime = 1;
    
    extern __thread int lastfld;
    lastfld    = 0;    /* last used field */
    extern __thread int argno;
    argno    = 1;    /* current input argument number */
    if (symtab != NULL) {
        free(symtab->tab);
        free(symtab);
        symtab = NULL;
    }
    // Variables from lib.c
    if (record) { free(record); record = NULL;}
    recsize    = RECSIZE;
    extern __thread char    *fields;
    if (fields) { free(fields); fields = NULL; }
    extern __thread int fieldssize;
    fieldssize = RECSIZE;
    extern __thread Cell    **fldtab;    /* pointers to Cells */
    if (fldtab) { free(fldtab); fldtab = NULL; }
}

static noreturn void fpecatch(int n
#ifdef SA_SIGINFO
	, siginfo_t *si, void *uc
#endif
)
{
#ifdef SA_SIGINFO
	static const char *emsg[] = {
		[0] = "Unknown error",
		[FPE_INTDIV] = "Integer divide by zero",
		[FPE_INTOVF] = "Integer overflow",
		[FPE_FLTDIV] = "Floating point divide by zero",
		[FPE_FLTOVF] = "Floating point overflow",
		[FPE_FLTUND] = "Floating point underflow",
		[FPE_FLTRES] = "Floating point inexact result",
		[FPE_FLTINV] = "Invalid Floating point operation",
		[FPE_FLTSUB] = "Subscript out of range",
	};
#endif
	FATAL("floating point exception"
#ifdef SA_SIGINFO
		": %s", (size_t)si->si_code < sizeof(emsg) / sizeof(emsg[0]) &&
		emsg[si->si_code] ? emsg[si->si_code] : emsg[0]
#endif
	    );
}

/* Can this work with recursive calls?  I don't think so.
void segvcatch(int n)
{
	FATAL("segfault.  Do you have an unbounded recursive call?", n);
}
*/

static const char *
setfs(char *p)
{
	/* wart: t=>\t */
	if (p[0] == 't' && p[1] == '\0')
		return "\t";
	else if (p[0] != '\0')
		return p;
	return NULL;
}

static char *
getarg(int *argc, char ***argv, const char *msg)
{
	if ((*argv)[1][2] != '\0') {	/* arg is -fsomething */
		return &(*argv)[1][2];
	} else {			/* arg is -f something */
		(*argc)--; (*argv)++;
		if (*argc <= 1)
			FATAL("%s", msg);
		return (*argv)[1];
	}
}

int awk_main(int argc, char *argv[])
{
	const char *fs = NULL;
	char *fn, *vn;
    initializeVariables();

	setlocale(LC_CTYPE, "");
	setlocale(LC_COLLATE, "");
	setlocale(LC_NUMERIC, "C"); /* for parsing cmdline & prog */
	cmdname = argv[0];
	if (argc == 1) {
		fprintf(thread_stderr,
		  "usage: %s [-F fs] [-v var=value] [-f progfile | 'prog'] [file ...]\n",
		  cmdname);
		exit(1);
	}
	Unix2003_compat = COMPAT_MODE("bin/awk", "unix2003");
#ifdef SA_SIGINFO
	{
		struct sigaction sa;
		sa.sa_sigaction = fpecatch;
		sa.sa_flags = SA_SIGINFO;
		sigemptyset(&sa.sa_mask);
		(void)sigaction(SIGFPE, &sa, NULL);
	}
#else
	(void)signal(SIGFPE, fpecatch);
#endif
	/*signal(SIGSEGV, segvcatch); experiment */

	/* Set and keep track of the random seed */
	srand_seed = 1;
	srandom((unsigned long) srand_seed);

	yyin = NULL;
	symtab = makesymtab(NSYMTAB/NSYMTAB);
	while (argc > 1 && argv[1][0] == '-' && argv[1][1] != '\0') {
		if (strcmp(argv[1], "-version") == 0 || strcmp(argv[1], "--version") == 0) {
			fprintf(thread_stdout, "awk %s\n", version);
			return 0;
		}
		if (strcmp(argv[1], "--") == 0) {	/* explicit end of args */
			argc--;
			argv++;
			break;
		}
		switch (argv[1][1]) {
		case 's':
			if (strcmp(argv[1], "-safe") == 0)
				safe = true;
			break;
		case 'f':	/* next argument is program filename */
			fn = getarg(&argc, &argv, "no program filename");
			if (npfile >= maxpfile) {
				maxpfile += 20;
				pfile = realloc(pfile, maxpfile * sizeof(*pfile));
				if (pfile == NULL)
					FATAL("error allocating space for -f options");
 			}
			pfile[npfile++] = fn;
 			break;
		case 'F':	/* set field separator */
			fs = setfs(getarg(&argc, &argv, "no field separator"));
			if (fs == NULL)
				WARNING("field separator FS is empty");
			break;
		case 'v':	/* -v a=1 to be done NOW.  one -v for each */
			vn = getarg(&argc, &argv, "no variable name");
			if (isclvar(vn))
				setclvar(vn);
			else
				FATAL("invalid -v option argument: %s", vn);
			break;
		case 'd':
			dbg = atoi(&argv[1][2]);
			if (dbg == 0)
				dbg = 1;
			fprintf(thread_stdout, "awk %s\n", version);
			break;
		default:
			WARNING("unknown option %s ignored", argv[1]);
			break;
		}
		argc--;
		argv++;
	}
	/* argv[1] is now the first argument */
	if (npfile == 0) {	/* no -f; first argument is program */
		if (argc <= 1) {
			if (dbg)
				exit(0);
			FATAL("no program given");
		}
		DPRINTF("program = |%s|\n", argv[1]);
		lexprog = argv[1];
		argc--;
		argv++;
	}
	recinit(recsize);
	syminit();
	compile_time = COMPILING;
	argv[0] = cmdname;	/* put prog name at front of arglist */
	DPRINTF("argc=%d, argv[0]=%s\n", argc, argv[0]);
	arginit(argc, argv);
	if (!safe)
#if !TARGET_OS_IPHONE
		envinit(environ);
#else
        envinit(environmentVariables(ios_currentPid()));
#endif
	yyparse();
	setlocale(LC_NUMERIC, ""); /* back to whatever it is locally */
	if (fs)
		*FS = qstring(fs, '\0');
	DPRINTF("errorflag=%d\n", errorflag);
	if (errorflag == 0) {
		compile_time = RUNNING;
		run(winner);
        winner = NULL;
	} else
		bracecheck();
	return(errorflag);
}

int pgetc(void)		/* get 1 character from awk program */
{
	int c;

	for (;;) {
		if (yyin == NULL) {
			if (curpfile >= npfile)
				return EOF;
			if (strcmp(pfile[curpfile], "-") == 0)
				yyin = thread_stdin;
			else if ((yyin = fopen(pfile[curpfile], "r")) == NULL)
				FATAL("can't open file %s", pfile[curpfile]);
			lineno = 1;
		}
		if ((c = getc(yyin)) != EOF)
			return c;
		if (yyin != thread_stdin)
			fclose(yyin);
		yyin = NULL;
		curpfile++;
	}
}

char *cursource(void)	/* current source file name */
{
	if (npfile > 0)
		return pfile[curpfile < npfile ? curpfile : curpfile - 1];
	else
		return NULL;
}
