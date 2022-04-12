--- nvi-1.79.orig/build/Makefile.in
+++ nvi-1.79/build/Makefile.in
@@ -95,15 +95,15 @@
 	    ($(mkdir) $(mandir)/cat1 && $(chmod) $(dmode) $(mandir)/cat1)
 	@echo "Installing man pages: $(mandir) ..."
 	cd $(mandir)/cat1 && $(rm) -f `echo vi.0 | sed '$(transform)'`
-	$(cp) $(srcdir)/docs/USD.doc/vi.man/vi.0 \
-	    $(mandir)/cat1/`echo vi.0 | sed '$(transform)'`
-	cd $(mandir)/cat1 && $(chmod) $(fmode) `echo vi.0 | sed '$(transform)'`
-	cd $(mandir)/cat1 && $(rm) -f `echo ex.0 | sed '$(transform)'`
-	cd $(mandir)/cat1 && $(rm) -f `echo view.0 | sed '$(transform)'`
-	cd $(mandir)/cat1 && $(ln) \
-	    `echo vi.0 | sed '$(transform)'` `echo ex.0 | sed '$(transform)'`
-	cd $(mandir)/cat1 && $(ln) \
-	    `echo vi.0 | sed '$(transform)'` `echo view.0 | sed '$(transform)'`
+	#$(cp) $(srcdir)/docs/USD.doc/vi.man/vi.0 \
+	    #$(mandir)/cat1/`echo vi.0 | sed '$(transform)'`
+	#cd $(mandir)/cat1 && $(chmod) $(fmode) `echo vi.0 | sed '$(transform)'`
+	#cd $(mandir)/cat1 && $(rm) -f `echo ex.0 | sed '$(transform)'`
+	#cd $(mandir)/cat1 && $(rm) -f `echo view.0 | sed '$(transform)'`
+	#cd $(mandir)/cat1 && $(ln) \
+	    #`echo vi.0 | sed '$(transform)'` `echo ex.0 | sed '$(transform)'`
+	#cd $(mandir)/cat1 && $(ln) \
+	    #`echo vi.0 | sed '$(transform)'` `echo view.0 | sed '$(transform)'`
 	[ -d $(mandir)/man1 ] || \
 	    ($(mkdir) $(mandir)/man1 && $(chmod) $(dmode) $(mandir)/man1)
 	cd $(mandir)/man1 && $(rm) -f `echo vi.1 | sed '$(transform)'`
@@ -137,16 +137,16 @@
 	    $(chmod) $(dmode) $(datadir)/vi/catalog
 	(cd $(srcdir)/catalog && $(cp) $(cat) $(datadir)/vi/catalog && \
 	    cd $(datadir)/vi/catalog && $(chmod) $(fmode) *)
-	@echo "Installing Perl scripts: $(datadir)/vi/perl ..."
-	$(mkdir) $(datadir)/vi/perl && $(chmod) $(dmode) $(datadir)/vi/perl
-	[ -f VI.pm ] && $(cp) VI.pm $(datadir)/vi/perl && \
-	    cd $(datadir)/vi/perl && $(chmod) $(fmode) VI.pm)
-	(cd $(srcdir)/perl_scripts && $(cp) *.pl $(datadir)/vi/perl && \
-	    cd $(datadir)/vi/perl && $(chmod) $(fmode) *.pl)
-	@echo "Installing Tcl scripts: $(datadir)/vi/tcl ..."
-	$(mkdir) $(datadir)/vi/tcl && $(chmod) $(dmode) $(datadir)/vi/tcl
-	(cd $(srcdir)/tcl_scripts && $(cp) *.tcl $(datadir)/vi/tcl && \
-	    cd $(datadir)/vi/tcl && $(chmod) $(fmode) *.tcl)
+	#@echo "Installing Perl scripts: $(datadir)/vi/perl ..."
+	#$(mkdir) $(datadir)/vi/perl && $(chmod) $(dmode) $(datadir)/vi/perl
+	#[ -f VI.pm ] && $(cp) VI.pm $(datadir)/vi/perl && \
+	#    cd $(datadir)/vi/perl && $(chmod) $(fmode) VI.pm)
+	#(cd $(srcdir)/perl_scripts && $(cp) *.pl $(datadir)/vi/perl && \
+	#    cd $(datadir)/vi/perl && $(chmod) $(fmode) *.pl)
+	#@echo "Installing Tcl scripts: $(datadir)/vi/tcl ..."
+	#$(mkdir) $(datadir)/vi/tcl && $(chmod) $(dmode) $(datadir)/vi/tcl
+	#(cd $(srcdir)/tcl_scripts && $(cp) *.tcl $(datadir)/vi/tcl && \
+	#    cd $(datadir)/vi/tcl && $(chmod) $(fmode) *.tcl)
 	@echo "Installing recover script: $(datadir)/vi/recover ..."
 	($(cp) recover $(datadir)/vi/recover && \
 	    $(chmod) $(emode) $(datadir)/vi/recover)
--- nvi-1.79.orig/build/recover
+++ nvi-1.79/build/recover
@@ -0,0 +1,49 @@
+#!/bin/sh -
+#
+#	@(#)recover.in	8.8 (Berkeley) 10/10/96
+#
+# Script to recover nvi edit sessions.
+
+RECDIR="/var/tmp/vi.recover"
+SENDMAIL="/usr/sbin/sendmail"
+
+echo 'Recovering nvi editor sessions.'
+
+# Check editor backup files.
+vibackup=`echo $RECDIR/vi.*`
+if [ "$vibackup" != "$RECDIR/vi.*" ]; then
+	for i in $vibackup; do
+		# Only test files that are readable.
+		if test ! -r $i; then
+			continue
+		fi
+
+		# Unmodified nvi editor backup files either have the
+		# execute bit set or are zero length.  Delete them.
+		if test -x $i -o ! -s $i; then
+			rm $i
+		fi
+	done
+fi
+
+# It is possible to get incomplete recovery files, if the editor crashes
+# at the right time.
+virecovery=`echo $RECDIR/recover.*`
+if [ "$virecovery" != "$RECDIR/recover.*" ]; then
+	for i in $virecovery; do
+		# Only test files that are readable.
+		if test ! -r $i; then
+			continue
+		fi
+
+		# Delete any recovery files that are zero length, corrupted,
+		# or that have no corresponding backup file.  Else send mail
+		# to the user.
+		recfile=`awk '/^X-vi-recover-path:/{print $2}' < $i`
+		if test -n "$recfile" -a -s "$recfile"; then
+			$SENDMAIL -t < $i
+		else
+			rm $i
+		fi
+	done
+fi
--- nvi-1.79.orig/debian/README.debian
+++ nvi-1.79/debian/README.debian
@@ -0,0 +1,14 @@
+nvi for DEBIAN
+----------------------
+
+This package was debianized by Steve Greenland
+<stevegr@master.debian.org> on Tue, 29 Oct 1996, using
+the new source format. Much of it is based on previous work by Robert
+Sanders <Robert.Sanders@linux.org> or <rsanders@mindspring.com>, and
+Ian Murdock <imurdock@debian.org>.
+
+It was downloaded from ftp://mongoose.bostic.com/pub/nvi.tar.gz,
+which seems to be the new home site: ftp.cs.berkeley.edu no longer
+archives nvi.
+
+Steve Greenland <stevegr@master.debian.org>, Sat, 15 Nov 1997
--- nvi-1.79.orig/debian/changelog
+++ nvi-1.79/debian/changelog
@@ -0,0 +1,53 @@
+nvi (1.79-5) frozen unstable; urgency=low
+
+  * Fixed removal of editor alternative in prerm (reported by Dale Scheetz)
+
+ -- Steve Greenland <stevegr@master.debian.org>  Sun, 10 May 1998 18:54:02 -0500
+
+nvi (1.79-4) unstable; urgency=low
+
+  * fixed uncompressed alternatives links (closes:Bug#16171)
+  * fixed build problem (clean failed when already clean) (closes:Bug#15263)
+
+ -- Steve Greenland <stevegr@master.debian.org>  Sun,  5 Apr 1998 13:31:46 -0500
+
+nvi (1.79-3) frozen unstable; urgency=low
+
+  * Rebuilt with clean md5sum file. (closes:Bug#19377,Bug#18683)
+
+ -- Steve Greenland <stevegr@master.debian.org>  Thu, 19 Mar 1998 22:14:12 -0600
+
+nvi (1.79-2) unstable; urgency=low
+
+  * Fixed build (actually clean) procedure (Bug#15263)
+
+ -- Steve Greenland <stevegr@master.debian.org>  Fri, 28 Nov 1997 13:58:17 -0600
+
+nvi (1.79-1) unstable; urgency=low
+
+  * Removed cleanup of nvi-1.34-4 from postinst, shouldn't be necessary
+  any longer (Bug #6563)
+  * Removed /usr/man/cat1 from package (Bug #6240, #8226)
+  * Fixed permissions on executables (and man pages) (Bug #5998)
+  * New upstream version (Bug #14086)
+  * Compiled for libc6 (Bug #11709)
+  * debian/rules calls 'make distclean' on clean to remove configuration stuff
+  * Added update-alternatve calls to support Debian's /usr/bin/editor.
+
+ -- Steve Greenland <stevegr@master.debian.org>  Sat, 15 Nov 1997 17:50:02 -0600
+
+nvi (1.76-1) unstable; urgency=low
+
+  * New upstream version. (Fixes Bugs 2825, 3967, 4511)
+  * Modified Makefile.in permissions.
+  * New source package format, using debstd (from debmake package). 
+  * Modified Makefile.in to not install pre-formatted man pages.
+  * Cleaned up postinst to avoid dangling links from update alternatives.
+  * Modified Makefile.in to not install Perl, Tcl, and Tk stuff. (Will
+  probably add back later as a separate package.)
+
+ -- Steve Greenland <stevegr@master.debian.org>  Sun, 1 Dec 1996 22:03:37 -0600
+
+Local variables:
+mode: debian-changelog
+End:
--- nvi-1.79.orig/debian/conffiles
+++ nvi-1.79/debian/conffiles
@@ -0,0 +1 @@
+/etc/rc.boot/nvi
--- nvi-1.79.orig/debian/control
+++ nvi-1.79/debian/control
@@ -0,0 +1,19 @@
+Source: nvi
+Section: editors
+Priority: important
+Maintainer: Steve Greenland <stevegr@master.debian.org>
+Standards-Version: 2.4.0.0
+
+Package: nvi
+Architecture: any
+Depends: ${shlibs:Depends}
+Description: 4.4BSD re-implementation of vi.
+ Vi is the original screen based text editor for Unix systems.
+ It is considered the standard text editor, and is available on 
+ almost all Unix systems. 
+ . 
+ Nvi is intended as a "bug-for-bug compatible" clone of the original
+ BSD vi editor. As such, it doesn't have a lot of snazzy features as do
+ some of the other vi clones such as elvis and vim. However, if all
+ you want is vi, this is the one to get.
+
--- nvi-1.79.orig/debian/postinst
+++ nvi-1.79/debian/postinst
@@ -0,0 +1,21 @@
+#! /bin/sh
+
+# Remove the old view link (nvi-1.34-14, maybe earlier)
+# Don't bother the user with it.
+update-alternatives --remove view /usr/bin/nvi >/dev/null
+
+update-alternatives --install /usr/bin/ex ex /usr/bin/nex 30 \
+  --slave /usr/man/man1/ex.1.gz ex.1.gz /usr/man/man1/nex.1.gz
+update-alternatives --install /usr/bin/vi vi /usr/bin/nvi 30 \
+  --slave /usr/man/man1/vi.1.gz vi.1.gz /usr/man/man1/nvi.1.gz
+update-alternatives --install /usr/bin/view view /usr/bin/nview 30 \
+  --slave /usr/man/man1/view.1.gz view.1.gz /usr/man/man1/nview.1.gz
+
+# These are for the generic editor links
+
+update-alternatives --install /usr/bin/editor editor /usr/bin/nvi 100 \
+  --slave /usr/man/man1/editor.1.gz editor.1.gz /usr/man/man1/nvi.1.gz
+
+
+
+exit 0
--- nvi-1.79.orig/debian/prerm
+++ nvi-1.79/debian/prerm
@@ -0,0 +1,11 @@
+#! /bin/sh
+
+if [ "$1" != "upgrade" ]
+then
+  update-alternatives --remove editor /usr/bin/nvi
+  update-alternatives --remove ex /usr/bin/nex
+  update-alternatives --remove vi /usr/bin/nvi
+  update-alternatives --remove view /usr/bin/nview
+fi
+
+exit 0
--- nvi-1.79.orig/debian/rc.boot
+++ nvi-1.79/debian/rc.boot
@@ -0,0 +1,58 @@
+#!/bin/sh
+#	@(#)recover.script	8.7 (Berkeley) 8/16/94
+#
+# Script to recover nvi edit sessions.
+#
+RECDIR=/var/tmp/vi.recover
+SENDMAIL=/usr/lib/sendmail
+
+case "$1" in
+  start)
+    echo -n 'Recovering nvi editor sessions... '
+
+    # Check editor backup files.
+    vibackup=`echo $RECDIR/vi.*`
+    if [ "$vibackup" != "$RECDIR/vi.*" ]; then
+    	for i in $vibackup; do
+    		# Only test files that are readable.
+    		if test ! -r $i; then
+    			continue
+    		fi
+
+    		# Unmodified nvi editor backup files either have the
+    		# execute bit set or are zero length.  Delete them.
+    		if test -x $i -o ! -s $i; then
+    			rm $i
+    		fi
+    	done
+    fi
+
+    # It is possible to get incomplete recovery files, if the editor crashes
+    # at the right time.
+    virecovery=`echo $RECDIR/recover.*`
+    if [ "$virecovery" != "$RECDIR/recover.*" ]; then
+    	for i in $virecovery; do
+    		# Only test files that are readable.
+    		if test ! -r $i; then
+    			continue
+    		fi
+
+    		# Delete any recovery files that are zero length, corrupted,
+    		# or that have no corresponding backup file.  Else send mail
+    		# to the user.
+    		recfile=`awk '/^X-vi-recover-path:/{print $2}' < $i`
+    		if test -n "$recfile" -a -s "$recfile"; then
+    			$SENDMAIL -t < $i
+    		else
+    			rm $i
+    		fi
+    	done
+    fi
+
+    echo "done."
+    ;;
+  stop)
+    ;;
+esac
+
+exit 0
--- nvi-1.79.orig/debian/rules
+++ nvi-1.79/debian/rules
@@ -0,0 +1,89 @@
+#!/usr/bin/make -f
+# Sample debian.rules file - for GNU Hello (1.3).
+# Copyright 1994,1995 by Ian Jackson.
+# I hereby give you perpetual unlimited permission to copy,
+# modify and relicense this file, provided that you do not remove
+# my name from the file itself.  (I assert my moral right of
+# paternity under the Copyright, Designs and Patents Act 1988.)
+# This file may have to be extensively modified
+
+# There used to be `source' and `diff' targets in this file, and many
+# packages also had `changes' and `dist' targets.  These functions
+# have been taken over by dpkg-source, dpkg-genchanges and
+# dpkg-buildpackage in a package-independent way, and so these targets
+# are obsolete.
+
+package=nvi
+
+# This is needed for the install target
+curdir=$(shell pwd)
+
+# This bit with build.deb is because the nvi package has a
+# 'build' directory, and the normal use of 'touch build' won't
+# work.
+
+build: build.deb
+
+build.deb:
+	$(checkdir)
+	(cd ./build && CC=gcc ADDCPPFLAGS="-O2 -g" ./configure --prefix=/usr --disable-curses --datadir=/usr/lib --program-prefix=n)
+	(cd ./build && make)
+	touch build.deb
+
+
+clean:
+	$(checkdir)
+	-rm -f build.deb
+	(cd ./build && make distclean || /bin/true )
+	-rm -rf *~ debian/tmp debian/*~ debian/files*
+
+binary-indep:	checkroot build.deb
+	$(checkdir)
+# There are no architecture-independent files to be uploaded
+# generated by this package.  If there were any they would be
+# made here.
+
+binary-arch:	checkroot build.deb
+	$(checkdir)
+	-rm -rf debian/tmp
+	install -d debian/tmp/usr/bin debian/tmp/etc
+	(cd build && make install prefix=$(curdir)/debian/tmp/usr)
+	-rmdir debian/tmp/usr/man/cat1
+	chmod u+w debian/tmp/usr/bin/* debian/tmp/usr/man/man1/nvi.*
+	cp LICENSE debian/copyright
+	# Compress the man pages -- debstd can't do this because they
+        # are all links. Also, make them soft links instead of hard links
+	(cd debian/tmp/usr/man/man1 && \
+	        rm {nex,nview}.1 && gzip -9 nvi.1 && \
+		ln -s nvi.1.gz nex.1.gz && ln -s nvi.1.gz nview.1.gz)
+# Must have debmake installed for this to work. Otherwise please copy
+# /usr/bin/debstd into the debian directory and change debstd to debian/debstd
+	debstd -m  docs/changelog README FAQ
+	#
+	# Compress the changelogs if debstd didn't
+	#
+	( set -e && cd debian/tmp/usr/doc/nvi && \
+	   if [ -f changelog ] ; then gzip -9 changelog ; fi &&\
+	   if [ -f changelog.Debian ] ; then gzip -9 changelog.Debian;fi)
+	dpkg-gencontrol
+	chown -R root.root debian/tmp
+	chmod -R g-ws debian/tmp
+	dpkg --build debian/tmp ..
+
+
+define checkdir
+	test -f debian/rules
+endef
+
+# Below here is fairly generic really
+
+binary:		binary-indep binary-arch
+
+source diff:
+	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false
+
+checkroot:
+	$(checkdir)
+	test root = "`whoami`"
+
+.PHONY: binary binary-arch binary-indep clean checkroot
--- nvi-1.79.orig/debian/substvars
+++ nvi-1.79/debian/substvars
@@ -0,0 +1 @@
+shlibs:Depends=libc6, ncurses3.4
--- nvi-1.79.orig/debian/copyright
+++ nvi-1.79/debian/copyright
@@ -0,0 +1,40 @@
+The vi program is freely redistributable.  You are welcome to copy, modify
+and share it with others under the conditions listed in this file.  If any
+company (not any individual!) finds vi sufficiently useful that you would
+have purchased it, or if any company wishes to redistribute it, contributions
+to the authors would be appreciated.
+
+/*-
+ * Copyright (c) 1991, 1992, 1993, 1994
+ *      The Regents of the University of California.  All rights reserved.
+ *  Copyright (c) 1991, 1992, 1993, 1994, 1995, 1996
+ *	Keith Bostic.  All rights reserved.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions
+ * are met:
+ * 1. Redistributions of source code must retain the above copyright
+ *    notice, this list of conditions and the following disclaimer.
+ * 2. Redistributions in binary form must reproduce the above copyright
+ *    notice, this list of conditions and the following disclaimer in the
+ *    documentation and/or other materials provided with the distribution.
+ * 3. All advertising materials mentioning features or use of this software
+ *    must display the following acknowledgement:
+ *	This product includes software developed by the University of
+ *	California, Berkeley and its contributors.
+ * 4. Neither the name of the University nor the names of its contributors
+ *    may be used to endorse or promote products derived from this software
+ *    without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
+ * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
+ * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
+ * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
+ * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
+ * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
+ * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
+ * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
+ * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
+ * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
+ * SUCH DAMAGE.
+ */
