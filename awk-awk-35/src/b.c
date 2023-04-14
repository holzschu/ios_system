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

/* lasciate ogne speranza, voi ch'intrate. */

#define	DEBUG

#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <xlocale.h>
#include <wchar.h>
#include "awk.h"
#include "awkgram.tab.h"
#include "ios_error.h"

#define MAXLIN 22

#define type(v)		(v)->nobj	/* badly overloaded here */
#define info(v)		(v)->ntype	/* badly overloaded here */
#define left(v)		(v)->narg[0]
#define right(v)	(v)->narg[1]
#define parent(v)	(v)->nnext

#define LEAF	case CCL: case NCCL: case CHAR: case HAT: case DOLLAR: case DOT: case FINAL: case ALL:
#define ELEAF	case EMPTYRE:		/* empty string in regexp */
#define UNARY	case STAR: case PLUS: case QUEST:

/* Private libc function - see collate.h */
void __collate_lookup_l(wchar_t *, int *, int *, int *, locale_t);

/* encoding in tree Nodes:
	leaf (CCL, NCCL, CHAR, HAT, DOLLAR, DOT, FINAL, ALL, EMPTYRE):
		left is index, right contains value or pointer to value
	unary (STAR, PLUS, QUEST): left is child, right is null
	binary (CAT, OR): left and right are children
	parent contains pointer to parent
*/


__thread int	*setvec;
__thread int	*tmpset;
int	__thread maxsetvec = 0;

__thread int	rtok;		/* next token in current re */
__thread wchar_t	rlxval;
static __thread const wchar_t	*rlxwcs;
static __thread const uschar	*prestr;	/* current position in current re */
static __thread const uschar	*lastre;	/* origin of last re */
static __thread const uschar	*lastatom;	/* origin of last Atom */
static __thread const uschar	*starttok;
static __thread const uschar 	*basestr;	/* starts with original, replaced during
				   repetition processing */
static __thread const uschar 	*firstbasestr;

static __thread FILE * replogfile = 0;

static	__thread int setcnt;
static	__thread int poscnt;

__thread const char	*patbeg;
__thread int	patlen;

#define	NFA	128	/* cache this many dynamic fa's */
__thread fa	*fatab[NFA];
__thread int	nfatab	= 0;	/* entries in fatab */

static int *
intalloc(size_t n, const char *f)
{
	void *p = calloc(n, sizeof(int));
	if (p == NULL)
		overflo(f);
	return p;
}

static void
resizesetvec(const char *f)
{
	if (maxsetvec == 0)
		maxsetvec = MAXLIN;
	else
		maxsetvec *= 4;
	setvec = realloc(setvec, maxsetvec * sizeof(*setvec));
	tmpset = realloc(tmpset, maxsetvec * sizeof(*tmpset));
	if (setvec == NULL || tmpset == NULL)
		overflo(f);
}

static void
resize_state(fa *f, int state)
{
	void *p;
	int i, new_count;

	if (++state < f->state_count)
		return;

	new_count = state + 10; /* needs to be tuned */

	p = realloc(f->gototab, new_count * sizeof(f->gototab[0]));
	if (p == NULL)
		goto out;
	f->gototab = p;

	p = realloc(f->out, new_count * sizeof(f->out[0]));
	if (p == NULL)
		goto out;
	f->out = p;

	p = realloc(f->posns, new_count * sizeof(f->posns[0]));
	if (p == NULL)
		goto out;
	f->posns = p;

	for (i = f->state_count; i < new_count; ++i) {
		/*
		 * It is impossible to track state transitions for every possible character in a multibyte locale (utf-8).
		 * Therefore, the gototable will remain capable of tracking transitions for single-byte characters as a fast
		 * path in the C/POSIX locales (as well as ISO Latin-1 locales), but cgoto will be called for every
		 * multibyte character in multibyte locales.
		 */
		f->gototab[i] = calloc(NCHARS, sizeof(**f->gototab));
		if (f->gototab[i] == NULL)
			goto out;
		f->out[i]  = 0;
		f->posns[i] = NULL;
	}
	f->state_count = new_count;
	return;
out:
	overflo(__func__);
}

fa *makedfa(const char *s, bool anchor)	/* returns dfa for reg expr s */
{
	int i, use, nuse;
	fa *pfa;
	static __thread int now = 1;

	if (setvec == NULL) {	/* first time through any RE */
		resizesetvec(__func__);
	}

	if (compile_time != RUNNING)	/* a constant for sure */
		return mkdfa(s, anchor);
	for (i = 0; i < nfatab; i++)	/* is it there already? */
		if (fatab[i]->anchor == anchor
		  && strcmp((const char *) fatab[i]->restr, s) == 0) {
			fatab[i]->use = now++;
			return fatab[i];
		}
	pfa = mkdfa(s, anchor);
	if (nfatab < NFA) {	/* room for another */
		fatab[nfatab] = pfa;
		fatab[nfatab]->use = now++;
		nfatab++;
		return pfa;
	}
	use = fatab[0]->use;	/* replace least-recently used */
	nuse = 0;
	for (i = 1; i < nfatab; i++)
		if (fatab[i]->use < use) {
			use = fatab[i]->use;
			nuse = i;
		}
	freefa(fatab[nuse]);
	fatab[nuse] = pfa;
	pfa->use = now++;
	return pfa;
}

fa *mkdfa(const char *s, bool anchor)	/* does the real work of making a dfa */
				/* anchor = true for anchored matches, else false */
{
	Node *p, *p1;
	fa *f;

	firstbasestr = (const uschar *) s;
	basestr = firstbasestr;
	if (replogfile==0) {
		/*	disabled
		replogfile = fopen("/tmp/repeatlog", "a");
		*/
	}
	p = reparse(s);
	p1 = op2(CAT, op2(STAR, op2(ALL, NIL, NIL), NIL), p);
		/* put ALL STAR in front of reg.  exp. */
	p1 = op2(CAT, p1, op2(FINAL, NIL, NIL));
		/* put FINAL after reg.  exp. */

	poscnt = 0;
	penter(p1);	/* enter parent pointers and leaf indices */
	if ((f = calloc(1, sizeof(fa) + poscnt * sizeof(rrow))) == NULL)
		overflo(__func__);
	f->accept = poscnt-1;	/* penter has computed number of positions in re */
	cfoll(f, p1);	/* set up follow sets */
	freetr(p1);
	resize_state(f, 1);
	f->posns[0] = intalloc(*(f->re[0].lfollow), __func__);
	f->posns[1] = intalloc(1, __func__);
	*f->posns[1] = 0;
	f->initstat = makeinit(f, anchor);
	f->anchor = anchor;
	f->restr = (uschar *) tostring(s);
	if (replogfile) {
		fflush(replogfile);
		fclose(replogfile);
		replogfile=0;
	}
	if (firstbasestr != basestr) {
		if (basestr)
			xfree(basestr);
	}
	return f;
}

int makeinit(fa *f, bool anchor)
{
	int i, k;

	f->curstat = 2;
	f->out[2] = 0;
	k = *(f->re[0].lfollow);
	xfree(f->posns[2]);
	f->posns[2] = intalloc(k + 1,  __func__);
	for (i = 0; i <= k; i++) {
		(f->posns[2])[i] = (f->re[0].lfollow)[i];
	}
	if ((f->posns[2])[1] == f->accept)
		f->out[2] = 1;
	for (i = 0; i < NCHARS; i++)
		f->gototab[2][i] = 0;
	f->curstat = cgoto(f, 2, 0, HAT_CTRL);
	if (anchor) {
		*f->posns[2] = k-1;	/* leave out position 0 */
		for (i = 0; i < k; i++) {
			(f->posns[0])[i] = (f->posns[2])[i];
		}

		f->out[0] = f->out[2];
		if (f->curstat != 2)
			--(*f->posns[f->curstat]);
	}
	return f->curstat;
}

void penter(Node *p)	/* set up parent pointers and leaf indices */
{
	switch (type(p)) {
	ELEAF
	LEAF
		info(p) = poscnt;
		poscnt++;
		break;
	UNARY
		penter(left(p));
		parent(left(p)) = p;
		break;
	case CAT:
	case OR:
		penter(left(p));
		penter(right(p));
		parent(left(p)) = p;
		parent(right(p)) = p;
		break;
	case ZERO:
		break;
	default:	/* can't happen */
		FATAL("can't happen: unknown type %d in penter", type(p));
		break;
	}
}

void freetr(Node *p)	/* free parse tree */
{
	switch (type(p)) {
	ELEAF
	LEAF
		xfree(p);
		break;
	UNARY
	case ZERO:
		freetr(left(p));
		xfree(p);
		break;
	case CAT:
	case OR:
		freetr(left(p));
		freetr(right(p));
		xfree(p);
		break;
	default:	/* can't happen */
		FATAL("can't happen: unknown type %d in freetr", type(p));
		break;
	}
}

void freetr_iOS(Node *p)    /* free parse tree at the end */
{
    // fprintf(stderr, "freetr_iOS: u= %x type= %d\n", p, type(p)); fflush(stderr);
    switch (type(p)) {
    ELEAF
    LEAF
        xfree(p);
        break;
    UNARY
    case ZERO:
        freetr_iOS(left(p));
        xfree(p);
        break;
    case CAT:
    case OR:
        freetr_iOS(left(p));
        freetr_iOS(right(p));
        xfree(p);
        break;
    case 0:
    case INDIRECT:  // do nothing
        break;
    default:
        // malloc-error: memory freed that shouldn't be.
        freeTree(p, 1);
        break;
    }
}
/* in the parsing of regular expressions, metacharacters like . have */
/* to be seen literally;  \056 is not a metacharacter. */

wchar_t wchexstr(const wchar_t **pp)	/* find and eval hex string at pp, return new p */
{			/* only pick up one 8-bit byte (2 chars) */
	const wchar_t *p;
	int n = 0;
	int i;

	for (i = 0, p = *pp; i < 2 && isxdigit(*p); i++, p++) {
		if (isdigit(*p))
			n = 16 * n + *p - '0';
		else if (*p >= 'a' && *p <= 'f')
			n = 16 * n + *p - 'a' + 10;
		else if (*p >= 'A' && *p <= 'F')
			n = 16 * n + *p - 'A' + 10;
	}
	*pp = p;
	return n;
}

#define isoctdigit(c) ((c) >= '0' && (c) <= '7')	/* multiple use of arg */
wchar_t wcquoted(const wchar_t **pp)	/* pick up next character after a \\ */
			/* and increment *pp */
{
	const wchar_t *p = *pp;
	int c;

	if ((c = *p++) == 't')
		c = '\t';
	else if (c == 'n')
		c = '\n';
	else if (c == 'f')
		c = '\f';
	else if (c == 'r')
		c = '\r';
	else if (c == 'b')
		c = '\b';
	else if (c == 'v')
		c = '\v';
	else if (c == 'a')
		c = '\a';
	else if (c == '\\')
		c = '\\';
	else if (c == 'x') {	/* hexadecimal goo follows */
		c = wchexstr(&p);	/* this adds a null if number is invalid */
	} else if (isoctdigit(c)) {	/* \d \dd \ddd */
		int n = c - '0';
		if (isoctdigit(*p)) {
			n = 8 * n + *p++ - '0';
			if (isoctdigit(*p))
				n = 8 * n + *p++ - '0';
		}
		c = n;
	} /* else */
		/* c = c; */
	*pp = p;
	return c;
}

int hexstr(const uschar **pp)	/* find and eval hex string at pp, return new p */
{			/* only pick up one 8-bit byte (2 chars) */
	const uschar *p;
	int n = 0;
	int i;

	for (i = 0, p = *pp; i < 2 && isxdigit(*p); i++, p++) {
		if (isdigit(*p))
			n = 16 * n + *p - '0';
		else if (*p >= 'a' && *p <= 'f')
			n = 16 * n + *p - 'a' + 10;
		else if (*p >= 'A' && *p <= 'F')
			n = 16 * n + *p - 'A' + 10;
	}
	*pp = p;
	return n;
}

int quoted(const uschar **pp)	/* pick up next single byte character after a \\ */
			/* and increment *pp */
{
	const uschar *p = *pp;
	int c;

	if ((c = *p++) == 't')
		c = '\t';
	else if (c == 'n')
		c = '\n';
	else if (c == 'f')
		c = '\f';
	else if (c == 'r')
		c = '\r';
	else if (c == 'b')
		c = '\b';
	else if (c == 'v')
		c = '\v';
	else if (c == 'a')
		c = '\a';
	else if (c == '\\')
		c = '\\';
	else if (c == 'x') {	/* hexadecimal goo follows */
		c = hexstr(&p);	/* this adds a null if number is invalid */
	} else if (isoctdigit(c)) {	/* \d \dd \ddd */
		int n = c - '0';
		if (isoctdigit(*p)) {
			n = 8 * n + *p++ - '0';
			if (isoctdigit(*p))
				n = 8 * n + *p++ - '0';
		}
		c = n;
	} /* else */
		/* c = c; */
	*pp = p;
	return c;
}

wchar_t *cclenter(const wchar_t *wcs)	/* add a character class */
{
	int i;
	wchar_t wc, wc2;
	wchar_t *bp;
	wchar_t *buf = NULL;
	int bufc = 100;
	const wchar_t *wcp = wcs;

	if ((buf = malloc(bufc * sizeof(wchar_t))) == NULL) {
		FATAL("out of space for character class [%.10ls...] 1", wcp);
	}

	bp = buf;
	for (i = 0; (wc = *wcp++) != 0; ) {
		if (wc == '\\') {
			wc = wcquoted(&wcp);
		} else if (wc == '-' && i > 0 && bp[-1] != 0) {
			/* Expand out a-z to abcdef...xyz */
			if (*wcp != 0) {
				wc = bp[-1];
				wc2 = *wcp++;
				if (wc2 == '\\')
					wc2 = wcquoted(&wcp);
				if (wc > wc2) {   /* empty; ignore */
					bp--; /* erase starting character */
					i--;
					continue;
				}
				/* WARNING: This could cause buf to become huge */
				while (wc < wc2) {
					if (!wcadjbuf(&buf, &bufc, bp-buf+2, 100, &bp, "cclenter1"))
						FATAL("out of space for character class [%.10ls...] 2", wcp);
					*bp++ = ++wc;
					i++;
				}
				continue;
			}
		}
		if (!wcadjbuf(&buf, &bufc, bp-buf+2, 100,  &bp, "cclenter2"))
			FATAL("out of space for character class [%.10ls...] 3", wcp);
		*bp++ = wc;
		i++;
	}
	*bp++ = L'\0';

	DPRINTF("cclenter   : in = |%ls|, out = |%ls|\n", wcs, buf);
	xfree(wcs);

	return buf;
}

void overflo(const char *s)
{
	FATAL("regular expression too big: out of space in %.30s...", s);
}

void cfoll(fa *f, Node *v)	/* enter follow set of each leaf of vertex v into lfollow[leaf] */
{
	int i;
	int *p;

	switch (type(v)) {
	ELEAF
	LEAF
		f->re[info(v)].ltype = type(v);
		f->re[info(v)].lval.np = right(v);
		while (f->accept >= maxsetvec) {	/* guessing here! */
			resizesetvec(__func__);
		}
		for (i = 0; i <= f->accept; i++)
			setvec[i] = 0;
		setcnt = 0;
		follow(v);	/* computes setvec and setcnt */
		p = intalloc(setcnt + 1, __func__);
		f->re[info(v)].lfollow = p;
		*p = setcnt;
		for (i = f->accept; i >= 0; i--)
			if (setvec[i] == 1)
				*++p = i;
		break;
	UNARY
		cfoll(f,left(v));
		break;
	case CAT:
	case OR:
		cfoll(f,left(v));
		cfoll(f,right(v));
		break;
	case ZERO:
		break;
	default:	/* can't happen */
		FATAL("can't happen: unknown type %d in cfoll", type(v));
	}
}

int first(Node *p)	/* collects initially active leaves of p into setvec */
			/* returns 0 if p matches empty string */
{
	int b, lp;

	switch (type(p)) {
	ELEAF
	LEAF
		lp = info(p);	/* look for high-water mark of subscripts */
		while (setcnt >= maxsetvec || lp >= maxsetvec) {	/* guessing here! */
			resizesetvec(__func__);
		}
		if (type(p) == EMPTYRE) {
			setvec[lp] = 0;
			return(0);
		}
		if (setvec[lp] != 1) {
			setvec[lp] = 1;
			setcnt++;
		}
		if (type(p) == CCL && (*(char *) right(p)) == '\0')
			return(0);		/* empty CCL */
		return(1);
	case PLUS:
		if (first(left(p)) == 0)
			return(0);
		return(1);
	case STAR:
	case QUEST:
		first(left(p));
		return(0);
	case CAT:
		if (first(left(p)) == 0 && first(right(p)) == 0) return(0);
		return(1);
	case OR:
		b = first(right(p));
		if (first(left(p)) == 0 || b == 0) return(0);
		return(1);
	case ZERO:
		return 0;
	}
	FATAL("can't happen: unknown type %d in first", type(p));	/* can't happen */
	return(-1);
}

void follow(Node *v)	/* collects leaves that can follow v into setvec */
{
	Node *p;

	if (type(v) == FINAL)
		return;
	p = parent(v);
	switch (type(p)) {
	case STAR:
	case PLUS:
		first(v);
		follow(p);
		return;

	case OR:
	case QUEST:
		follow(p);
		return;

	case CAT:
		if (v == left(p)) {	/* v is left child of p */
			if (first(right(p)) == 0) {
				follow(p);
				return;
			}
		} else		/* v is right child */
			follow(p);
		return;
	}
}

int member(wchar_t wc, const wchar_t *wcs)	/* is wc in wcs? */
{
	while (*wcs)
		if (wc == *wcs++)
			return(1);
	return(0);
}

int match(fa *f, const char *p0)	/* shortest match ? */
{
	int s, ns;
	const uschar *p = (const uschar *) p0;

	s = f->initstat;
	assert (s < f->state_count);

	if (f->out[s])
		return(1);
	int p_read = 0;
	size_t p_len = strlen((const char*)p);
	do {
		wchar_t p_wc = towc(&p_read, (const char*)p, p_len);
		p_len -= p_read;

		/* assert(*p < NCHARS); */
		if (p_read == 1 && (ns = f->gototab[s][*p]) != 0)
			s = ns;
		else
			s = cgoto(f, s, p_wc, 0);
		if (f->out[s])
			return(1);
	} while (p += p_read, *(p - p_read) != 0);
	return(0);
}

int pmatch(fa *f, const char *p0)	/* longest match, for sub */
{
	int s, ns;
	const uschar *p = (const uschar *) p0;
	const uschar *q;

	s = f->initstat;
	assert(s < f->state_count);

	patbeg = (const char *)p;
	patlen = -1;
	size_t p_len = strlen((const char*)p);
	int p_read = 0;
	do {
		wchar_t p_wc = towc(&p_read, (const char*)p, p_len);
		size_t q_len = p_len;
		p_len -= p_read;

		q = p;
		int q_read = 0;
		do {
			wchar_t q_wc = towc(&q_read, (const char*)q, q_len);
			q_len -= q_read;

			/* Lots of debug in here as this is the path awk.ex{69,639,640} take */
			DPRINTF("pmatch: checking wc: %d\n", q_wc);
			if (f->out[s]) {		/* final state */
				patlen = q-p;
				DPRINTF("pmatch: f->out[s] is %d. patlen: %d\n", f->out[s], patlen);
			}

			/* assert(*q < NCHARS); */
			if (q_read == 1 && (ns = f->gototab[s][*q]) != 0)
				s = ns;
			else
				s = cgoto(f, s, q_wc, 0);

			assert(s < f->state_count);
			if (s == 1) {	/* no transition */
				if (patlen >= 0) {
					patbeg = (const char *) p;
					DPRINTF("pmatch: RETURN 1: patlen: %d patbeg: %s\n", patlen, patbeg);
					return(1);
				} else {
					DPRINTF("pmatch: nextin\n");
					goto nextin;	/* no match */
				}
			}

			DPRINTF("pmatch: q: advanced %d: %c\n", q_read, *(q + q_read));
		} while (q += q_read, *(q - q_read) != 0);;

		DPRINTF("pmatch: out of loop\n");
		if (f->out[s]) {
			DPRINTF("pmatch: patlen: f->out[s]: p: %s (%p), q: %s (%p), \n", p, p, q, q);
			patlen = q-p-1;	/* don't count $ */
		}
		if (patlen >= 0) {
			DPRINTF("pmatch: patlen: %d begin: %s\n", patlen, p);
			patbeg = (const char *) p;
			return(1);
		}
	nextin:
		s = 2;
	} while (p += p_read, *(p - p_read) != 0);
	return (0);
}

int nematch(fa *f, const char *p0)	/* non-empty match, for sub */
{
	int s, ns;
	const uschar *p = (const uschar *) p0;
	const uschar *q;

	s = f->initstat;
	assert(s < f->state_count);

	patbeg = (const char *)p;
	patlen = -1;
	size_t p_len = strlen((const char *)p);
	while (*p) {
		int p_read = 0;
		wchar_t p_wc = towc(&p_read, (const char*)p, p_len);
		size_t q_len = p_len;
		p_len -= p_read;

		q = p;
		int q_read = 0;
		do {
			wchar_t q_wc = towc(&q_read, (const char*)q, q_len);
			q_len -= q_read;
			if (f->out[s])		/* final state */
				patlen = q-p;
			/* assert(*q < NCHARS); */
			if (q_read == 1 && (ns = f->gototab[s][*q]) != 0)
				s = ns;
			else
				s = cgoto(f, s, q_wc, 0);
			if (s == 1) {	/* no transition */
				if (patlen > 0) {
					patbeg = (const char *) p;
					return(1);
				} else
					goto nnextin;	/* no nonempty match */
			}
		} while (q += q_read, *(q - q_read) != 0);;
		if (f->out[s])
			patlen = q-p-1;	/* don't count $ */
		if (patlen > 0 ) {
			patbeg = (const char *) p;
			return(1);
		}
	nnextin:
		s = 2;
		p += p_read;
	}
	return (0);
}


/*
 * NAME
 *     fnematch
 *
 * DESCRIPTION
 *     A stream-fed version of nematch which transfers characters to a
 *     null-terminated buffer. All characters up to and including the last
 *     character of the matching text or EOF are placed in the buffer. If
 *     a match is found, patbeg and patlen are set appropriately.
 *
 * RETURN VALUES
 *     false    No match found.
 *     true     Match found.
 */

bool fnematch(fa *pfa, FILE *f, char **pbuf, int *pbufsize, int quantum)
{
	char *buf = *pbuf;
	int bufsize = *pbufsize;
	int c, i, j, k, ns, s;

	s = pfa->initstat;
	patlen = 0;
	/* FUTURE: Wide Character Support - we can easily use fgetwc, but we really need to update callers to handle
	 * a wchar_t pbuf
	 */
	/*
	 * All indices relative to buf.
	 * i <= j <= k <= bufsize
	 *
	 * i: origin of active substring
	 * j: current character
	 * k: destination of next getc()
	 */
	i = -1, k = 0;
        do {
		j = i++;
		do {
			if (++j == k) {
				if (k == bufsize)
					if (!adjbuf((char **) &buf, &bufsize, bufsize+1, quantum, 0, "fnematch"))
						FATAL("stream '%.30s...' too long", buf);
				buf[k++] = (c = getc(f)) != EOF ? c : 0;
			}
			c = (uschar)buf[j];
			/* assert(c < NCHARS); */

			if ((ns = pfa->gototab[s][c]) != 0)
				s = ns;
			else
				s = cgoto(pfa, s, c, 0);

			if (pfa->out[s]) {	/* final state */
				patlen = j - i + 1;
				if (c == 0)	/* don't count $ */
					patlen--;
			}
		} while (buf[j] && s != 1);
		s = 2;
	} while (buf[i] && !patlen);

	/* adjbuf() may have relocated a resized buffer. Inform the world. */
	*pbuf = buf;
	*pbufsize = bufsize;

	if (patlen) {
		patbeg = (char *) buf + i;
		/*
		 * Under no circumstances is the last character fed to
		 * the automaton part of the match. It is EOF's nullbyte,
		 * or it sent the automaton into a state with no further
		 * transitions available (s==1), or both. Room for a
		 * terminating nullbyte is guaranteed.
		 *
		 * ungetc any chars after the end of matching text
		 * (except for EOF's nullbyte, if present) and null
		 * terminate the buffer.
		 */
		do
			if (buf[--k] && ungetc(buf[k], f) == EOF)
				FATAL("unable to ungetc '%c'", buf[k]);
		while (k > i + patlen);
		buf[k] = '\0';
		return true;
	}
	else
		return false;
}

Node *reparse(const char *p)	/* parses regular expression pointed to by p */
{			/* uses relex() to scan regular expression */
	Node *np;

	DPRINTF("reparse <%s>\n", p);
	lastre = prestr = (const uschar *) p;	/* prestr points to string to be parsed */
	rtok = relex();
	/* GNU compatibility: an empty regexp matches anything */
	if (rtok == '\0') {
		/* FATAL("empty regular expression"); previous */
		return(op2(EMPTYRE, NIL, NIL));
	}
	np = regexp();
	if (rtok != '\0')
		FATAL("syntax error in regular expression %s at %s", lastre, prestr);
	return(np);
}

Node *regexp(void)	/* top-level parse of reg expr */
{
	return (alt(concat(primary())));
}

Node *primary(void)
{
	Node *np;
	int savelastatom;

	switch (rtok) {
	case CHAR:
		lastatom = starttok;
		np = op2(CHAR, NIL, itonp(rlxval));
		rtok = relex();
		return (unary(np));
	case ALL:
		rtok = relex();
		return (unary(op2(ALL, NIL, NIL)));
	case EMPTYRE:
		if (replogfile) {
			fprintf(replogfile,
				"returned EMPTYRE from primary\n");
			fflush(replogfile);
		}
		rtok = relex();
		return (unary(op2(EMPTYRE, NIL, NIL)));
	case DOT:
		lastatom = starttok;
		rtok = relex();
		return (unary(op2(DOT, NIL, NIL)));
	case CCL:
		np = op2(CCL, NIL, (Node*) cclenter(rlxwcs));
		lastatom = starttok;
		rtok = relex();
		return (unary(np));
	case NCCL:
		np = op2(NCCL, NIL, (Node *) cclenter(rlxwcs));
		lastatom = starttok;
		rtok = relex();
		return (unary(np));
	case '^':
		rtok = relex();
		return (unary(op2(HAT, NIL, NIL)));
	case '$':
		rtok = relex();
		return (unary(op2(CHAR, NIL, NIL)));
	case '(':
		lastatom = starttok;
		savelastatom = starttok - basestr; /* Retain over recursion */
		rtok = relex();
		if (rtok == ')') {	/* special pleading for () */
			rtok = relex();
			return unary(op2(CCL, NIL, (Node *) tostring("")));
		}
		np = regexp();
		if (rtok == ')') {
			lastatom = basestr + savelastatom; /* Restore */
			rtok = relex();
			return (unary(np));
		}
		else
			FATAL("syntax error in regular expression %s at %s", lastre, prestr);
	default:
		FATAL("illegal primary in regular expression %s at %s", lastre, prestr);
	}
	return 0;	/*NOTREACHED*/
}

Node *concat(Node *np)
{
	switch (rtok) {
	case CHAR: case DOT: case ALL: case CCL: case NCCL: case '$': case '(':
		return (concat(op2(CAT, np, primary())));
	case EMPTYRE:
		if (replogfile) {
			fprintf(replogfile,
				"returned EMPTYRE to concat\n");
			fflush(replogfile);
		}
		rtok = relex();
		return (concat(op2(CAT, op2(CCL, NIL, (Node *) tostring("")),
				primary())));
	}
	return (np);
}

Node *alt(Node *np)
{
	if (rtok == OR) {
		rtok = relex();
		return (alt(op2(OR, np, concat(primary()))));
	}
	return (np);
}

Node *unary(Node *np)
{
	switch (rtok) {
	case STAR:
		rtok = relex();
		return (unary(op2(STAR, np, NIL)));
	case PLUS:
		rtok = relex();
		return (unary(op2(PLUS, np, NIL)));
	case QUEST:
		rtok = relex();
		return (unary(op2(QUEST, np, NIL)));
	case ZERO:
		rtok = relex();
		return (unary(op2(ZERO, np, NIL)));
	default:
		return (np);
	}
}

#define REPEAT_SIMPLE		0
#define REPEAT_PLUS_APPENDED	1
#define REPEAT_WITH_Q		2
#define REPEAT_ZERO		3

static int
replace_repeat(const uschar *reptok, int reptoklen, const uschar *atom,
	       int atomlen, int firstnum, int secondnum, int special_case)
{
	int i, j;
	uschar *buf = 0;
	int ret = 1;
	int init_q = (firstnum == 0);		/* first added char will be ? */
	int n_q_reps = secondnum-firstnum;	/* m>n, so reduce until {1,m-n} left  */
	int prefix_length = reptok - basestr;	/* prefix includes first rep	*/
	int suffix_length = strlen((const char *) reptok) - reptoklen;	/* string after rep specifier	*/
	int size = prefix_length +  suffix_length;

	if (firstnum > 1) {	/* add room for reps 2 through firstnum */
		size += atomlen*(firstnum-1);
	}

	/* Adjust size of buffer for special cases */
	if (special_case == REPEAT_PLUS_APPENDED) {
		size++;		/* for the final + */
	} else if (special_case == REPEAT_WITH_Q) {
		size += init_q + (atomlen+1)* n_q_reps;
	} else if (special_case == REPEAT_ZERO) {
		size += 2;	/* just a null ERE: () */
	}
	if ((buf = malloc(size + 1)) == NULL)
		FATAL("out of space in reg expr %.10s..", lastre);
	if (replogfile) {
		fprintf(replogfile, "re before: len=%zd,%s\n"
				    "         : init_q=%d,n_q_reps=%d\n",
				strlen((char*)basestr),basestr,
				init_q,n_q_reps);
		fprintf(replogfile, "re prefix_length=%d,atomlen=%d\n",
				prefix_length,atomlen);
/*
		fprintf(replogfile, " new buf size: %d, atom=%s, atomlen=%d\n",
				size, atom, atomlen);
*/
		fflush(replogfile);
	}
	memcpy(buf, basestr, prefix_length);	/* copy prefix	*/
	j = prefix_length;
	if (special_case == REPEAT_ZERO) {
		j -= atomlen;
		buf[j++] = '(';
		buf[j++] = ')';
	}
	for (i = 1; i < firstnum; i++) {	/* copy x reps 	*/
		memcpy(&buf[j], atom, atomlen);
		j += atomlen;
	}
	if (special_case == REPEAT_PLUS_APPENDED) {
		buf[j++] = '+';
	} else if (special_case == REPEAT_WITH_Q) {
		if (init_q)
			buf[j++] = '?';
		for (i = init_q; i < n_q_reps; i++) {	/* copy x? reps */
			memcpy(&buf[j], atom, atomlen);
			j += atomlen;
			buf[j++] = '?';
		}
	}
	memcpy(&buf[j], reptok+reptoklen, suffix_length);
	if (special_case == REPEAT_ZERO) {
		buf[j+suffix_length] = '\0';
	} else {
		buf[size] = '\0';
	}
	if (replogfile) {
		fprintf(replogfile, "re after : len=%zd,%s\n",strlen((char*)buf),buf);
		fflush(replogfile);
	}
	/* free old basestr */
	if (firstbasestr != basestr) {
		if (basestr)
			xfree(basestr);
	}
	basestr = buf;
	prestr  = buf + prefix_length;
	if (special_case == REPEAT_ZERO) {
		prestr  -= atomlen;
		ret++;
	}
	return ret;
}

static int repeat(const uschar *reptok, int reptoklen, const uschar *atom,
		  int atomlen, int firstnum, int secondnum)
{
	/*
	   In general, the repetition specifier or "bound" is replaced here
	   by an equivalent ERE string, repeating the immediately previous atom
	   and appending ? and + as needed. Note that the first copy of the
	   atom is left in place, except in the special_case of a zero-repeat
	   (i.e., {0}).
	 */
	if (secondnum < 0) {	/* means {n,} -> repeat n-1 times followed by PLUS */
		if (firstnum < 2) {
			/* 0 or 1: should be handled before you get here */
			if (replogfile) {
				fprintf(replogfile,
					"{%d, %d}, shouldn't be here\n",
					firstnum, secondnum);
				fflush(replogfile);
			}
			FATAL("internal error");
		} else {
			return replace_repeat(reptok, reptoklen, atom, atomlen,
				firstnum, secondnum, REPEAT_PLUS_APPENDED);
		}
	} else if (firstnum == secondnum) {	/* {n} or {n,n} -> simply repeat n-1 times */
		if (firstnum == 0) {	/* {0} or {0,0} */
			/* This case is unusual because the resulting
			   replacement string might actually be SMALLER than
			   the original ERE */
			return replace_repeat(reptok, reptoklen, atom, atomlen,
					firstnum, secondnum, REPEAT_ZERO);
		} else {		/* (firstnum >= 1) */
			return replace_repeat(reptok, reptoklen, atom, atomlen,
					firstnum, secondnum, REPEAT_SIMPLE);
		}
	} else if (firstnum < secondnum) {	/* {n,m} -> repeat n-1 times then alternate  */
		/*  x{n,m}  =>  xx...x{1, m-n+1}  =>  xx...x?x?x?..x?	*/
		return replace_repeat(reptok, reptoklen, atom, atomlen,
					firstnum, secondnum, REPEAT_WITH_Q);
	} else {	/* Error - shouldn't be here (n>m) */
		if (replogfile) {
			fprintf(replogfile,
				"illegal ERE {%d,%d} shouldn't be here!\n",
				firstnum,secondnum);
			fflush(replogfile);
		}
		FATAL("internal error");
	}
	return 0;
}

/* Converts a wide character and advances the input string pointer sp */
static wchar_t wcadvance(int *outlen, const uschar **sp, int max) {
	wchar_t wc = L'\0';
	int ret = mbtowc(&wc, (char*)*sp, max);

	if (ret < 0) {
		FATAL("multibyte conversion failure at %.20s...", *sp);
	} else {
		*sp += ret;
		if (outlen) {
			*outlen = ret;
		}
	}
	return wc;
}

static int cclex(void) {
	int i, len;
	wchar_t wc;
	static wchar_t *buf = NULL;
	static int bufc = 100;
	wchar_t *bp;

	if (buf == NULL && (buf = malloc(bufc * sizeof(wchar_t))) == NULL)
		FATAL("out of space in reg expr %.10s..", lastre);

	bp = buf;

	int cflag = 0;
	if (*prestr == '^') {
		cflag = 1;
		prestr++;
	}

	/* start with a buffer that can hold 2x length of prestr in wchar_ts */
	int n = 2 * strlen((const char *) prestr)+1;
	if (!wcadjbuf(&buf, &bufc, n, n, &bp, "relex1"))
		FATAL("out of space for reg expr %.10s...", lastre);

	for (; ; ) {
		wc = wcadvance(NULL, &prestr, MB_CUR_MAX);
		DPRINTF("loop wc: '%c'\n", wc);

		if (wc == L'\\') {
			*bp++ = L'\\';
			if ((wc = wcadvance(NULL, &prestr, MB_CUR_MAX)) == '\0')
				FATAL("nonterminated character class %.20s...", lastre);
			*bp++ = wc;
		/* } else if (c == '\n') { */
		/* 	FATAL("newline in character class %.20s...", lastre); */
		} else if (wc == L'[' && *prestr == ':') {
			prestr++;

			/* 9.3.5 RE Bracket Expression specifies that we must support locale
			 * specific character classes present in the current LC_CTYPE.
			 * https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_03_05 */
			int ccnamec = 64;
			char *ccname = malloc(ccnamec);
			char *ccnamep = ccname;

			/* Read in the character class name */
			while (*prestr) {
				if (!adjbuf(&ccname, &ccnamec, ccnamep-ccname+1, 32, &ccnamep, "relex2"))
					FATAL("out of space for reg expr %.10s...", lastre);

				*ccnamep++ = *prestr++;
				if (*prestr == ':' && prestr[1] == ']') {
					prestr += 2;
					break;
				}
			}
			*ccnamep++ = '\0';

			wctype_t wc_type = wctype(ccname);
			DPRINTF("character class %s is wctype %d\n", ccname, wc_type);
			if (wc_type) {
				/*
				 * BUG: We begin at 1, instead of 0, since we
				 * would otherwise prematurely terminate the
				 * string for classes like [[:cntrl:]]. This
				 * means that we can't match the NUL character,
				 * not without first adapting the entire
				 * program to track each string's length.
				 */
				for (i = 1; i <= UCHAR_MAX; i++) {
					if (!wcadjbuf(&buf, &bufc, bp-buf+2, 100, &bp, "relex2"))
						FATAL("out of space for reg expr %.10s...", lastre);

					if (iswctype((wchar_t)i, wc_type)) {
						/* escape backslash */
						if (i == L'\\') {
							*bp++ = (wchar_t)i;
							n++;
						}

						*bp++ = (wchar_t)i;
						n++;
					}
				}
			} else {
				WARNING("unknown character class: %s", ccname);
				*bp++ = wc;
			}
		} else if (wc == '[' && *prestr == '.') {
			wchar_t collate_char;
			prestr++;
			collate_char = wcadvance(NULL, &prestr, MB_LEN_MAX);
			if (*prestr == '.' && prestr[1] == ']') {
				prestr += 2;
				/* Found it: map via locale TBD: for
				   now, simply return this char.  This
				   is sufficient to pass conformance
				   test awk.ex 156
				 */
				if (*prestr == ']') {
					prestr++;
					rlxval = collate_char;
					if (replogfile) {
						fprintf(replogfile,
							"[..] collate char=%c\n",
							collate_char);
						fflush(replogfile);
					}
					/* FIXME: this should really be a CCL with 1 character for now, otherwise ^ / NCCL won't work */
					return CHAR;
				}
			}
		} else if (wc == '[' && *prestr == '=') {
			/* Read opening '=' */
			prestr++;

			wchar_t collate_elem = wcadvance(NULL, &prestr, MB_CUR_MAX);

			if (*prestr == '=' && prestr[1] == ']') {
				wchar_t wc2;
				int prim1, prim2, sec1, sec2, len;

				len = 1;
				prestr += 2;

				__collate_lookup_l(&collate_elem, &len, &prim1, &sec1, LC_GLOBAL_LOCALE);
				DPRINTF("collate_elem: 0x%x p: %d s:%d\n", collate_elem, prim1, sec1);

				/* Lookup all ISO wide characters (0 -> 255) for primary weights */
				/* FUTURE: like ranges (a-z) we should just store collate_elem and perform lookups in member() */
				for (wc2 = 1; wc2 < UCHAR_MAX; wc2++) {
					if (!wcadjbuf(&buf, &bufc, bp-buf+1, 100, &bp, "relex2"))
						FATAL("out of space for reg expr %.10s...", lastre);

					len = 1;
					__collate_lookup_l(&wc2, &len, &prim2, &sec2, LC_GLOBAL_LOCALE);

					DPRINTF("compare_char: (0x%x) p: %d s:%d\n", wc2, prim2, sec2);
					if (prim1 == prim2) {
						DPRINTF("                -> Primary weights match @ %p\n", bp);
						if (wc2 == L'\\') {
							*bp++ = wc2;
							n++;
						}

						*bp++ = wc2;
						n++;
					}
				}
			}
		} else if (wc == '\0') {
			FATAL("nonterminated character class %.20s", lastre);
		} else if (bp == buf) {
			/* 1st char is special */
			/* NOTE/BUG: If [:name:], [=a=], or others expand to an empty set,
			 * the next character will still be considered "first".
			 */
			*bp++ = wc;
		} else if (wc == L']') {
			*bp++ = L'\0';
			rlxwcs = wcsdup(buf);
			if (replogfile) {
				fprintf(replogfile,
				"detecting []: cflag=%d, len=%zd,%ls\n",
					cflag,wcslen(rlxwcs),rlxwcs);
				fflush(replogfile);
			}
			if (cflag == 0)
				return CCL;
			else
				return NCCL;
		} else {
			/* just a simple character in the class: [abc] */
			*bp++ = wc;
		}
	}
}

int relex(void)		/* lexical analyzer for reparse */
{
	int c, n;
	static __thread uschar *buf = NULL;
	static __thread int bufsz = 100;
	uschar *bp;
	int i;
	int num, m;
	bool commafound, digitfound;
	const uschar *startreptok;
	static int parens = 0;

rescan:
	starttok = prestr;

	switch (c = *prestr++) {
	case '|': return OR;
	case '*': return STAR;
	case '+': return PLUS;
	case '?': return QUEST;
	case '.': return DOT;
	case '\0': prestr--; return '\0';
	case '^':
	case '$':
		return c;
	case '(':
		parens++;
		return c;
	case ')':
		if (parens) {
			parens--;
			return c;
		}
		/* unmatched close parenthesis; per POSIX, treat as literal */
		rlxval = c;
		return CHAR;
	case '\\':
		/* FUTURE: prestr is not a wchar_t, when it is, use wcquoted() * */
		rlxval = quoted(&prestr);
		return CHAR;
	default:
		{
			/* put us back at `c` for a multibyte conversion */
			prestr--;

			rlxval = wcadvance(NULL, &prestr, MB_CUR_MAX);

			return CHAR;
		}
	case '[':
		return cclex();
	case '{':
		if (isdigit(*(prestr))) {
			num = 0;	/* Process as a repetition */
			n = -1; m = -1;
			commafound = false;
			digitfound = false;
			startreptok = prestr-1;
			/* Remember start of previous atom here ? */
		} else {        	/* just a { char, not a repetition */
			rlxval = c;
			return CHAR;
                }
		for (; ; ) {
			if ((c = *prestr++) == '}') {
				if (commafound) {
					if (digitfound) { /* {n,m} */
						m = num;
						if (m < n)
							FATAL("illegal repetition expression: class %.20s",
								lastre);
						if (n == 0 && m == 1) {
							return QUEST;
						}
					} else {	/* {n,} */
						if (n == 0)
							return STAR;
						else if (n == 1)
							return PLUS;
					}
				} else {
					if (digitfound) { /* {n} same as {n,n} */
						n = num;
						m = num;
					} else {	/* {} */
						FATAL("illegal repetition expression: class %.20s",
							lastre);
					}
				}
				if (repeat(starttok, prestr-starttok, lastatom,
					   startreptok - lastatom, n, m) > 0) {
					if (n == 0 && m == 0) {
						return ZERO;
					}
					/* must rescan input for next token */
					goto rescan;
				}
				/* Failed to replace: eat up {...} characters
				   and treat like just PLUS */
				return PLUS;
			} else if (c == '\0') {
				FATAL("nonterminated character class %.20s",
					lastre);
			} else if (isdigit(c)) {
				num = 10 * num + c - '0';
				digitfound = true;
			} else if (c == ',') {
				if (commafound)
					FATAL("illegal repetition expression: class %.20s",
						lastre);
				/* looking for {n,} or {n,m} */
				commafound = true;
				n = num;
				digitfound = false; /* reset */
				num = 0;
			} else {
				FATAL("illegal repetition expression: class %.20s",
					lastre);
			}
		}
		break;
	}
}

int cgoto(fa *f, int s, wchar_t wc, int ctrl)
{
	int *p, *q;
	int i, j, k;

	DPRINTF("cgoto: wc: %d ctrl: %d\n", wc, ctrl);

	/* The ctrl replaces cases where cgoto was called w/ a special int like HAT to indicate the beginning of input */
	if (ctrl != 0 && wc != 0) {
		FATAL("cgoto: non-zero ctrl instruction passed with wc: ctrl: %d wc: %d", ctrl, wc);
	}

	while (f->accept >= maxsetvec) {	/* guessing here! */
		resizesetvec(__func__);
	}
	for (i = 0; i <= f->accept; i++)
		setvec[i] = 0;
	setcnt = 0;
	resize_state(f, s);
	/* compute positions of gototab[s,c] into setvec */
	p = f->posns[s];
	for (i = 1; i <= *p; i++) {
		if ((k = f->re[p[i]].ltype) != FINAL) {
			DPRINTF("cgoto: k: %d wc: %d ctrl: %d\n", k, wc, ctrl);
			if ((k == CHAR && wc == ptoi(f->re[p[i]].lval.np) && ctrl == 0)
			 || (k == HAT && ctrl == HAT_CTRL)
			 || (k == DOT && wc != 0)
			 || (k == ALL && (wc != 0 || ctrl == HAT_CTRL)) /* ALL should match the initial makeinit call */
			 || (k == EMPTYRE && wc != 0)
			 || (k == CCL && member(wc, (wchar_t *) f->re[p[i]].lval.up))
			 || (k == NCCL && wc != 0 && !member(wc, (wchar_t *) f->re[p[i]].lval.up))) {
				DPRINTF("cgoto: match\n");

				q = f->re[p[i]].lfollow;
				for (j = 1; j <= *q; j++) {
					if (q[j] >= maxsetvec) {
						resizesetvec(__func__);
					}
					if (setvec[q[j]] == 0) {
						setcnt++;
						setvec[q[j]] = 1;
					}
				}
			}
		}
	}
	DPRINTF("cgoto: out loop\n");
	/* determine if setvec is a previous state */
	tmpset[0] = setcnt;
	j = 1;
	for (i = f->accept; i >= 0; i--)
		if (setvec[i]) {
			tmpset[j++] = i;
		}
	resize_state(f, f->curstat > s ? f->curstat : s);
	/* tmpset == previous state? */
	for (i = 1; i <= f->curstat; i++) {
		p = f->posns[i];
		if ((k = tmpset[0]) != p[0])
			goto different;
		for (j = 1; j <= k; j++)
			if (tmpset[j] != p[j])
				goto different;
		/* setvec is state i */
		if (ctrl != HAT_CTRL && wc < NCHARS) {
			f->gototab[s][(int)wc] = i;
		}

		return i;
	  different:;
	}

	/* add tmpset to current set of states */
	++(f->curstat);
	resize_state(f, f->curstat);
	for (i = 0; i < NCHARS; i++)
		f->gototab[f->curstat][i] = 0;
	xfree(f->posns[f->curstat]);
	p = intalloc(setcnt + 1, __func__);

	f->posns[f->curstat] = p;
	if (ctrl != HAT_CTRL && wc < NCHARS) {
		f->gototab[s][(int)wc] = f->curstat;
	}

	for (i = 0; i <= setcnt; i++)
		p[i] = tmpset[i];
	if (setvec[f->accept])
		f->out[f->curstat] = 1;
	else
		f->out[f->curstat] = 0;
	return f->curstat;
}


void freefa(fa *f)	/* free a finite automaton */
{
	int i;

	if (f == NULL)
		return;
	for (i = 0; i < f->state_count; i++)
		xfree(f->gototab[i])
	for (i = 0; i <= f->curstat; i++)
		xfree(f->posns[i]);
	for (i = 0; i <= f->accept; i++) {
		xfree(f->re[i].lfollow);
		if (f->re[i].ltype == CCL || f->re[i].ltype == NCCL)
			xfree(f->re[i].lval.np);
	}
	xfree(f->restr);
	xfree(f->out);
	xfree(f->posns);
	xfree(f->gototab);
	xfree(f);
}
