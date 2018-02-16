# $Id: Makefile.in,v 1.56 2014/09/30 23:43:08 djm Exp $

sysconfdir=${prefix}/etc
piddir=/var/run
srcdir=.
top_srcdir=..


CC=gcc
LD=gcc
CFLAGS=-g -O2 -Qunused-arguments -Wunknown-warning-option -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wsizeof-pointer-memaccess -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -ftrapv -fno-builtin-memset -fstack-protector-strong -fPIE 
CPPFLAGS=-I. -I.. -I$(srcdir) -I$(srcdir)/..  -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.Internal.sdk/usr/local/include/sshcrypto   -DHAVE_CONFIG_H
LIBS=-lcrypto -lbsm -lz  -lresolv
AR=ar
RANLIB=ranlib
INSTALL=/usr/bin/install -c
LDFLAGS=-L.  -fstack-protector-strong -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.Internal.sdk/usr/local/lib/sshcrypto -pie

OPENBSD=base64.o basename.o bcrypt_pbkdf.o bindresvport.o blowfish.o daemon.o dirname.o fmt_scaled.o getcwd.o getgrouplist.o getopt_long.o getrrsetbyname.o glob.o inet_aton.o inet_ntoa.o inet_ntop.o mktemp.o pwcache.o readpassphrase.o reallocarray.o realpath.o rresvport.o setenv.o setproctitle.o sha1.o sha2.o rmd160.o md5.o sigact.o strcasestr.o strlcat.o strlcpy.o strmode.o strnlen.o strptime.o strsep.o strtonum.o strtoll.o strtoul.o strtoull.o timingsafe_bcmp.o vis.o blowfish.o bcrypt_pbkdf.o explicit_bzero.o

COMPAT=arc4random.o bsd-asprintf.o bsd-closefrom.o bsd-cray.o bsd-cygwin_util.o bsd-getpeereid.o getrrsetbyname-ldns.o bsd-err.o bsd-misc.o bsd-nextstep.o bsd-openpty.o bsd-poll.o bsd-setres_id.o bsd-snprintf.o bsd-statvfs.o bsd-waitpid.o fake-rfc2553.o openssl-compat.o xcrypt.o kludge-fd_set.o

PORTS=port-aix.o port-irix.o port-linux.o port-solaris.o port-tun.o port-uw.o

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $<

all: libopenbsd-compat.a

$(COMPAT): ../config.h
$(OPENBSD): ../config.h
$(PORTS): ../config.h

libopenbsd-compat.a:  $(COMPAT) $(OPENBSD) $(PORTS)
	$(AR) rv $@ $(COMPAT) $(OPENBSD) $(PORTS)
	$(RANLIB) $@

clean:
	rm -f *.o *.a core

distclean: clean
	rm -f Makefile *~
