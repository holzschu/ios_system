/* $OpenBSD: xmalloc.c,v 1.33 2016/02/15 09:47:49 dtucker Exp $ */
/*
 * Author: Tatu Ylonen <ylo@cs.hut.fi>
 * Copyright (c) 1995 Tatu Ylonen <ylo@cs.hut.fi>, Espoo, Finland
 *                    All rights reserved
 * Versions of malloc and friends that check their results, and never return
 * failure (they call fatal if they encounter an error).
 *
 * As far as I am concerned, the code I have written for this software
 * can be used freely for any purpose.  Any derived versions of this
 * software must be clearly marked as such, and if the derived work is
 * incompatible with the protocol description in the RFC file, it must be
 * called by a name other than "ssh" or "Secure Shell".
 */

#include "includes.h"

#include <stdarg.h>
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "xmalloc.h"
#include "log.h"
#include "ios_error.h"

void
ssh_malloc_init(void)
{
#if defined(__OpenBSD__)
	extern char *malloc_options;

	malloc_options = "S";
#endif /* __OpenBSD__ */
}

void *
xmalloc(size_t size)
{
    void *ptr;
    
    if (size == 0) {
        fprintf(thread_stderr, "xmalloc: zero size");
        pthread_exit(NULL);
    }
    ptr = malloc(size);
    if (ptr == NULL) {
        fprintf(thread_stderr, "xmalloc: out of memory (allocating %zu bytes)", size);
        pthread_exit(NULL);
    }
    return ptr;
}

void *
xcalloc(size_t nmemb, size_t size)
{
	void *ptr;

    if (size == 0 || nmemb == 0) {
		fprintf(thread_stderr, "xcalloc: zero size");
        pthread_exit(NULL);
    }
    if (SIZE_MAX / nmemb < size) {
        fprintf(thread_stderr, "xcalloc: nmemb * size > SIZE_MAX");
        pthread_exit(NULL);
    }
    ptr = calloc(nmemb, size);
    if (ptr == NULL) {
        fprintf(thread_stderr, "xcalloc: out of memory (allocating %zu bytes)",
                size * nmemb);
        pthread_exit(NULL);
    }
    return ptr;
}

void *
xreallocarray(void *ptr, size_t nmemb, size_t size)
{
	void *new_ptr;

	new_ptr = reallocarray(ptr, nmemb, size);
    if (new_ptr == NULL) {
		fprintf(thread_stderr, "xreallocarray: out of memory (%zu elements of %zu bytes)",
		    nmemb, size);
        pthread_exit(NULL);
    }
    return new_ptr;
}

char *
xstrdup(const char *str)
{
	size_t len;
	char *cp;

	len = strlen(str) + 1;
	cp = xmalloc(len);
	strlcpy(cp, str, len);
	return cp;
}

int
xasprintf(char **ret, const char *fmt, ...)
{
	va_list ap;
	int i;

	va_start(ap, fmt);
	i = vasprintf(ret, fmt, ap);
	va_end(ap);

    if (i < 0 || *ret == NULL) {
        fprintf(thread_stderr, "xasprintf: could not allocate memory");
        pthread_exit(NULL);
    }
	return (i);
}
