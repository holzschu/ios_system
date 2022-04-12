/* $Id: system.h,v 1.1 2002/11/22 22:36:56 tom Exp $ */

#ifdef HAVE_CONFIG_H

# include "config.h"
# define SYS_UNIX 1

#else
	/* provide values for non-UNIX systems */
# if defined(vms)
#  include <stsdef.h>
#  define SYS_VMS 1
#  define EXIT_SUCCESS (STS$M_INHIB_MSG | STS$K_SUCCESS)
#  define EXIT_FAILURE (STS$M_INHIB_MSG | STS$K_ERROR)
# endif

# if defined(MSDOS) || defined(__MSDOS__)
#  define SYS_MSDOS 1
# endif

# if !defined(SYS_VMS) || !defined(SYS_MSDOS) || defined(WIN32)
#  define SYS_UNIX 1		/* assume we're autoconfiguring */
# endif

#define HAVE_STRCHR 1

#endif /* HAVE_CONFIG_H */

#ifndef HAVE_GETOPT_H
#define HAVE_GETOPT_H 0
#endif

#ifndef HAVE_MALLOC_H
#define HAVE_MALLOC_H 0
#endif

#ifndef HAVE_STDLIB_H
#define HAVE_STDLIB_H 1
#endif

#ifndef HAVE_STRING_H
#define HAVE_STRING_H 1
#endif

#ifndef SYS_MSDOS
#define SYS_MSDOS 0
#endif

#ifndef SYS_UNIX
#define SYS_UNIX 0
#endif

#ifndef SYS_VMS
#define SYS_VMS 0
#endif

#ifndef HAVE_GETOPT_HEADER
#define HAVE_GETOPT_HEADER 0
#endif

#ifndef PRINT_ROUNDS_DOWN
#define PRINT_ROUNDS_DOWN 0
#endif

#ifdef lint
#define typeCalloc(type,elts) (type *)(elts)
#else
#define typeCalloc(type,elts) (type *)calloc(elts,sizeof(type))
#endif

#ifndef TRUE
#define TRUE  (1)
#define FALSE (0)
#endif

#undef EOS
#define EOS	'\0'

	/* On VMS and MSDOS we can fake wildcards by embedding a directory
	 * scanning loop...
	 */
#if !SYS_UNIX
extern int has_wildcard(char *);
extern int expand_wildcard(char *, int);
#endif
