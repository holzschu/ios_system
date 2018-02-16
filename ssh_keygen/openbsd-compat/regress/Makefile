# $Id: Makefile.in,v 1.5 2014/06/17 13:06:08 dtucker Exp $

sysconfdir=${prefix}/etc
piddir=/var/run
srcdir=.
top_srcdir=../..


CC=gcc
LD=gcc
CFLAGS=-g -O2 -Qunused-arguments -Wunknown-warning-option -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wsizeof-pointer-memaccess -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -ftrapv -fno-builtin-memset -fstack-protector-strong -fPIE 
CPPFLAGS=-I. -I.. -I$(srcdir) -I$(srcdir)/..  -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.Internal.sdk/usr/local/include/sshcrypto   -DHAVE_CONFIG_H
EXEEXT=
LIBCOMPAT=../libopenbsd-compat.a
LIBS=-lcrypto -lbsm -lz  -lresolv
LDFLAGS= -fstack-protector-strong -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.Internal.sdk/usr/local/lib/sshcrypto -pie $(LIBCOMPAT)

TESTPROGS=closefromtest$(EXEEXT) snprintftest$(EXEEXT) strduptest$(EXEEXT) \
	strtonumtest$(EXEEXT) opensslvertest$(EXEEXT)

all:	t-exec ${OTHERTESTS}

%$(EXEEXT):	%.c $(LIBCOMPAT)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $< $(LIBCOMPAT) $(LIBS)

t-exec:	$(TESTPROGS)
	@echo running compat regress tests
	@for TEST in ""$?; do \
		echo "run test $${TEST}" ... 1>&2; \
		./$${TEST}$(EXEEXT) || exit $$? ; \
	done
	@echo finished compat regress tests

clean:
	rm -f *.o *.a core $(TESTPROGS) valid.out

distclean: clean
	rm -f Makefile *~
