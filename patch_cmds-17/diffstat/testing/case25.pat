# vile 9.4m - patch 2004/12/15 - Thomas Dickey <dickey@his.com>
# ------------------------------------------------------------------------------
# $Header:                     |    1 
# CHANGES                      |   58 
# MANIFEST                     |    3 
# buffer.c                     |  208 ++-
# buglist                      |    7 
# builtflt.c                   |   68 +
# cmdtbl                       |   15 
# configure                    | 2652 ++++++++++++++++++++---------------------
# configure.in                 |   16 
# display.c                    |   80 -
# doc/filters.doc              |   34 
# doc/macros.doc               |   67 -
# edef.h                       |    5 
# estruct.h                    |   13 
# eval.c                       |  196 ++-
# filters/as-filt.l            |    6 
# filters/asm-filt.l           |    8 
# filters/au3-filt.l           |    8 
# filters/bat-filt.l           |    6 
# filters/c-filt.c             |   20 
# filters/filterio.c           |   33 
# filters/filters.c            |    3 
# filters/filters.h            |    7 
# filters/filters.rc           |   40 
# filters/htmlfilt.l           |    9 
# filters/imakeflt.l           |   19 
# filters/key-filt.c           |   11 
# filters/m4-filt.c            |    3 
# filters/makefilt.l           |   19 
# filters/pl-filt.c            |   24 
# filters/pot-filt.l           |    5 
# filters/ps-filt.l            |    5 
# filters/rb-filt.l            |    3 
# filters/rpm-filt.l           |   16 
# filters/rubyfilt.c           |   30 
# filters/sccsfilt.l           |    5 
# filters/sed-filt.c           |    3 
# filters/sh-filt.l            |   16 
# filters/spell.rc             |   36 
# filters/spellflt.l           |    8 
# filters/sql-filt.l           |    9 
# filters/tc-filt.l            |   12 
# filters/tcl-filt.l           |    4 
# filters/vilefilt.l           |   10 
# filters/vl-filt.l            |   20 
# filters/xml-filt.l           |   50 
# filters/xresfilt.l           |   11 
# input.c                      |    4 
# macros/gnugpg.rc             |    8 
# macros/which.rc              |  107 +
# main.c                       |    5 
# makefile.in                  |   17 
# makefile.wnt                 |    3 
# modes.c                      |  358 +++--
# modetbl                      |   22 
# ntconio.c                    |   51 
# ntwinio.c                    |   53 
# patchlev.h                   |    2 
# proto.h                      |   19 
# revlist                      |  129 +
# statevar.c                   |    8 
# tbuff.c                      |   14 
# tcap.c                       |    3 
# vile-9.4.spec                |    9 
# vile-9.4m/macros/showeach.rc |   78 +
# vile.hlp                     |   16 
# x11.c                        |  370 ++---
# 67 files changed, 3017 insertions(+), 2141 deletions(-)
# ------------------------------------------------------------------------------
Index: CHANGES
--- vile-9.4l+/CHANGES	2004-12-08 01:01:53.000000000 +0000
+++ vile-9.4m/CHANGES	2004-12-15 23:56:47.000000000 +0000
@@ -1,5 +1,63 @@
 Changes for vile 9.5 (released ??? ??? ?? ????)
 
+ 20041215 (m)
+ 	> Tom Dickey:
+	+ modify x11.c, ntconio.c and ntwinio.c to make modifiers work with tab
+	  key, e.g., to add shift-key as a back-tab key.
+	+ add macro show-each-buffer (file showeach.rc), which splits up the
+	  screen into equal chunks to display as many of the non-scratch
+	  buffers as possible.
+	+ modify macro parameter evaluation so it does not attempt to compute
+	  a value for function tokens or goto-labels.  Otherwise pathnames such
+	  as "~\foo" look like macro directives and produce an error.
+	+ correct slash/backslash translation (win32, etc) for some of the
+	  built-in functions; the translated result was not actually the return
+	  value:  &path and &pcat.
+	+ correct flags in modetbl used to annotate trace of &seq and a few
+	  other operators.
+	+ correct length computed for $bflags variable; an empty string was
+	  returned.
+	+ add a section on command-line options to doc/filters.doc
+	+ add macro which-filter to show which locations would be checked for
+	  an external filter.  If the filter happens to be built-in, this is
+	  also noted, in the message line.
+	+ improve 'eval' command, provide for mixture of functions and other
+	  tokens which are passed to the script interpreter.
+	+ modify SpellFilter macro to use the results from [Filter Messages]
+	  with the error-finder to step through the misspellings.
+	+ add macro show-filtermsgs to show syntax filter messages, setting the
+	  list to the error-buffer to provide simple stepping through the
+	  errors which are found.
+	+ add commands popup-buffer and popdown-buffer, which open/close
+	  windows for the given buffer rather than changing the current window
+	  to show a different buffer.  The popup-buffer command is a wrapper
+	  for the existing logic used for help and similar commands.  The
+	  popdown-buffer command differs from delete-window by closing all
+	  windows for the given buffer.
+	+ remove the pre-9.4e workarounds for set-highlighting and
+	  which-keywords macros.
+	+ modify kdb_reply() to shift the minibuffer left/right as needed after
+	  doing the initial tab of a name-completion, in case that left the
+	  cursor position past the end of the line (report by Paul Fox).
+	+ add new operators to make it simpler for macros to check for
+	  features: &isa, &classof and &mclass.
+	+ modify historical-buffer to allow tab/back-tab to cycle through the
+	  first 9 buffers, solves the problem of seeing more than the first
+	  few possibilities on the message line.  Toggling with the repeated
+	  '_' selects the first buffer shown.
+	+ add back-tab to termcap/terminfo driver as a bindable key.
+	+ modify configure script to make builtflt.h part of $(BUILTHDRS) to
+	  simplify "make sources" rule.
+	+ modify htmlfilt.l to match </script> in the middle of a line to
+	  accommodate pages where the script is given by a "src=".
+	+ add filtermsgs mode, for built-in filters to report syntax errors
+	  into [Filter Messages] buffer so that one may use the error finder to
+	  locate these (motivated by a 200,000 line xml file).
+	+ correct state manipulation in xml-filt.l, which was confused by
+	  CDATA pattern.
+	+ correct $CPPFLAGS for linting configurations with built-in filters.
+	+ correct typo in configure script from 9.4k fixes for iconv_open().
+
  20041207 (l)
 	> Clark Morgan:
 	+ modify special treatment of "#" which prevents it from being shifted
Index: MANIFEST
--- vile-9.4l+/MANIFEST	2004-12-08 01:48:52.000000000 +0000
+++ vile-9.4m/MANIFEST	2004-12-16 00:53:14.000000000 +0000
@@ -1,4 +1,4 @@
-MANIFEST for vile, version v9_4l
+MANIFEST for vile, version v9_4m
 --------------------------------------------------------------------------------
 MANIFEST                        this file
 CHANGES                         Change-log for VILE
@@ -332,6 +332,7 @@
 macros/pictmode.rc              macros to support "picture-mode" editing
 macros/search.rc                find a file in one of several locations
 macros/shifts.rc                macros to shift words left/right
+macros/showeach.rc              show-each-buffer
 macros/vile-pager               use vile as a pager
 macros/vileinit.rc              sample initialization file
 macros/vilemenu.rc              sample menu for xvile
Index: cmdtbl
Prereq:  1.230 
--- vile-9.4l+/cmdtbl	2004-12-07 01:28:55.000000000 +0000
+++ vile-9.4m/cmdtbl	2004-12-14 20:18:42.000000000 +0000
@@ -97,7 +97,7 @@
 #		in '!' listed, then the flag does nothing, and should be
 #		viewed simply as documentation.
 #
-# @Header: /usr/build/vile/vile/RCS/cmdtbl,v 1.230 2004/12/07 01:28:55 tom Exp @
+# @Header: /usr/build/vile/vile/RCS/cmdtbl,v 1.233 2004/12/14 20:18:42 tom Exp @
 #
 #
 
@@ -625,7 +625,7 @@
 firstbuffer	NONE
 	"rewind"
 	"rew!"
-	<go to first buffer in buffer list.  (does nothing if \"autobuffer\" set>
+	<go to first buffer in buffer list>
 firstnonwhite	MOTION|MINIBUF
 	"first-nonwhite"		!FEWNAMES
 	'^'
@@ -1686,13 +1686,22 @@
 edit_buffer	NONE
 	"B"
 	"edit-buffer"			!FEWNAMES
-	<make or switch to the given buffer; will not look for a file by that name>
+	<make or switch to the given buffer>
+popup_buffer	NONE			!SMALLER
+	"popup-buffer"
+	"open-window"			!FEWNAMES
+	<open window for the given buffer>
+popdown_buffer	NONE			!SMALLER
+	"popdown-buffer"
+	"close-windows"			!FEWNAMES
+	<open all windows for the given buffer>
 usekreg		REDO
 	"use-register"			!FEWNAMES
 	'"'
 	<name a register, for use with a following command which references it>
 userbeep	NONE			!SMALLER
 	"beep"
+	'FN-b'				KEY_BackTab
 	<force the terminal to ring (or flash, if \"set flash\" is active)>
 visual		NONE
 	"visual"
Index: configure.in
Prereq:  1.211 
--- vile-9.4l+/configure.in	2004-12-04 00:42:49.000000000 +0000
+++ vile-9.4m/configure.in	2004-12-10 22:52:59.000000000 +0000
@@ -1,12 +1,12 @@
 dnl Process this file with autoconf to produce a configure script.
-AC_REVISION(@Revision: 1.211 @)
+AC_REVISION(@Revision: 1.214 @)
 AC_PREREQ(2.13.20030927)
 rm -f config.cache
 
 ### Use "configure -with-screen" to override the default configuration, which is
 ### termcap-based on unix systems.
 
-dnl @Header: /usr/build/vile/vile/RCS/configure.in,v 1.211 2004/12/04 00:42:49 tom Exp @
+dnl @Header: /usr/build/vile/vile/RCS/configure.in,v 1.214 2004/12/10 22:52:59 tom Exp @
 
 define(MAKELIST, sh $srcdir/filters/makelist.sh $srcdir/filters/genmake.mak)
 
@@ -52,6 +52,10 @@
 CF_LIB_PREFIX
 
 ###	options to control how much we build
+BUILTHDRS="nebind.h neproto.h neexec.h nefunc.h nemode.h nename.h nevars.h nefkeys.h nefsms.h"
+BUILTLIBS=
+BUILTSRCS=
+
 AC_MSG_CHECKING(if you wish to build only core functions)
 CF_ARG_DISABLE(extensions,
 	[  --disable-extensions    test: build only core functions],
@@ -287,6 +291,7 @@
 	perl_lib_path=`$PERL -MConfig -e 'print $Config{privlib}'`
 	AC_DEFINE(OPT_PERL)
 	EXTRAOBJS="$EXTRAOBJS perl.o"
+	BUILTSRCS="$BUILTSRCS perl.c"
 	LINK_PREFIX=`$PERL -MConfig -e 'print $Config{shrpenv}'`
 	ac_link="$LINK_PREFIX $ac_link"
 	CF_CHECK_CFLAGS(`$PERL -MExtUtils::Embed -e ccopts`)
@@ -672,7 +677,7 @@
 	[cf_func_iconv="$withval"],
 	[cf_func_iconv=yes])
 AC_MSG_RESULT($cf_func_iconv)
-if test "$cf_func_iconv" == yes ; then
+if test "$cf_func_iconv" = yes ; then
 	AC_DEFINE(OPT_ICONV_FUNCS)
 	test "$cf_cv_func_iconv" != yes && LIBS="$cf_cv_func_iconv $LIBS"
 fi # test $cf_func_iconv" = yes
@@ -834,9 +839,10 @@
 
 if test "$cf_filter_libs" = yes ; then
 	EXTRAOBJS="$EXTRAOBJS builtflt.o"
-	CFLAGS="-I\$(srcdir)/filters $CFLAGS"
+	CPPFLAGS="-I\$(srcdir)/filters $CPPFLAGS"
 	FILTER_LIBS="-Lfilters -lvlflt"
 	LIBBUILTFLT="${LIB_PREFIX}vlflt.a"
+	BUILTHDRS="$BUILTHDRS builtflt.h"
 	BUILTLIBS="$BUILTLIBS filters/$LIBBUILTFLT"
 	AC_DEFINE(OPT_FILTER)
 else
@@ -846,7 +852,9 @@
 fi
 
 AC_SUBST(EXTRAOBJS)
+AC_SUBST(BUILTHDRS)
 AC_SUBST(BUILTLIBS)
+AC_SUBST(BUILTSRCS)
 AC_SUBST(FILTER_LIBS)
 AC_SUBST(LIBBUILTFLT)
 
Index: doc/filters.doc
Prereq:  1.32 
--- vile-9.4l+/doc/filters.doc	2004-11-11 00:47:06.000000000 +0000
+++ vile-9.4m/doc/filters.doc	2004-12-14 00:47:49.000000000 +0000
@@ -33,7 +33,7 @@
 
 	[ If $VILE_STARTUP_PATH is not defined, the filter checks the
 	"prefix" directory specified when all filters were compiled
-	(default path is /usr/local/share/vile/vile.keyords). ]
+	(default path is /usr/local/share/vile/vile.keywords). ]
 
 and then here:
 
@@ -146,6 +146,38 @@
 language keywords, if any.
 
 
+OPTIONS
+-------
+
+A few options are common to all filters:
+
+  -d	is recognized when the filters have been compiled with "DEBUG" defined.
+	This is used in the more complicated filters such as perl and ruby to
+	show the parsing.
+
+  -k FILE
+
+  -q	exits the filter before writing the marked-up output.  This happens
+	after processing the class definitions, so it is useful in combination
+	with the -v option to simply obtain the class information.
+
+  -t	holds the tabstop setting, which can be used in a filter for column
+	computations.
+
+  -v	verbose, turns on extra output which can be used for troubleshooting
+	configuration problems.
+
+The C syntax filter recognizes additional options to customize it for Java and
+JavaScript:
+
+  -j	Extend name- and literal-syntax to include Java.
+
+  -p	Disallow preprocessor lines.
+
+  -s	for JavaScript (to support jsmode).  This controls whether to allow
+	regular expressions in certain cases.
+
+
 PROGRAMS
 --------
 
@@ -230,4 +262,4 @@
 The lex filters have been well tested only with flex, which treats newlines
 differently.  Older versions of lex may not support the %x states.
 
--- @Header: /usr/build/vile/vile/doc/RCS/filters.doc,v 1.32 2004/11/11 00:47:06 tom Exp @
+-- @Header: /usr/build/vile/vile/doc/RCS/filters.doc,v 1.33 2004/12/14 00:47:49 tom Exp @
Index: doc/macros.doc
Prereq:  1.93 
--- vile-9.4l+/doc/macros.doc	2004-10-20 22:47:38.000000000 +0000
+++ vile-9.4m/doc/macros.doc	2004-12-12 20:29:24.000000000 +0000
@@ -774,7 +774,7 @@
 	    &mod    "N1" "N2"       Divide the "N1" by "N2", return remainder.
 	    &negate "N"             Return -(N).
 	    &ascii  "S"	            Return the ASCII code of the first
-					    character in "S"
+				    character in "S"
 	    &random "N"
 	    &rnd    "N"		    Random number between 1 and N
 	    &abs    "N"		    Absolute value of "N"
@@ -791,12 +791,12 @@
 	  The rest return strings:
 
 	    &bind   "S"		    Return the function name bound to the
-					key sequence "S".
+				    key sequence "S".
 	    &cat    "S1" "S2"	    Concatenate S1 and string "S".
 	    &chr    "N"		    Converts numeric "N" to an ASCII character.
 	    &cclass "S"		    Character class (see "show-printable")
 	    &env    "S"		    Return the value of the user's environment
-					variable named "S".
+				    variable named "S".
 	    &gtkey		    Get a single raw keystroke from the user.
 	    &gtsequence		    Get a complete vile key sequence from user.
 	    &left   "S" "N"	    Extract first "N" characters from "S"
@@ -805,8 +805,8 @@
 	    &middle "S" "N1" "N2"   Extract "N2" chars at position "N1".
 	    &upper  "S"		    Return uppercase version of "S".
 	    &trim   "S"		    Remove whitespace at either end of "S",
-					reduce multiple spaces within "S"
-					to just one space each.
+				    reduce multiple spaces within "S"
+				    to just one space each.
 
 	Boolean/logical functions --
 
@@ -820,6 +820,9 @@
 	    &geq    "N1" "N2"	    Is "N1" numerically not less than "N2"?
 	    &greater "N1" "N2"	    Is "N1" numerically greater than "N2"?
 	    &gt	    "N1" "N2"	    (same as &greater)
+	    &isa    "C"  "N"        Is "N" a member of class "C".  Classes
+				    include: buffer, color, mode, submode,
+				    Majormode.
 	    &leq    "N1" "N2"	    Is "N1" numerically not greater than "N2"?
 	    &lessthan "N1" "N2"     Is "N1" numerically less than "N2"?
 	    &lt	    "N1" "N2"	    (same as &lessthan)
@@ -860,19 +863,26 @@
 
 	  These all return string values:
 
+	    &classof "N"	    Retrieves the class(es) to which the given
+	    			    name may return.  Usually this is a single
+				    name, e.g., one of those checked by &isa.
+				    If multiple matches are found, the result
+				    contains each classname separated by a
+				    space.
+
 	    &default "MODENAME"     Retrieves initial/default value for the
-					given mode or state variable.
+				    given mode or state variable.
 
 	    &global "MODENAME"	    Retrieves universal/global mode setting.
 
-	    &indirect "S"	    Evaluate value of "S" as a
-					macro language variable itself.
-					Thus if %foo has value "HOME",
-					then &env &indirect %foo will
-					return the home directory pathname.
+	    &indirect "S"	    Evaluate value of "S" as a macro language
+				    variable itself.  Thus if %foo has value
+				    "HOME", then
+					&env &indirect %foo
+				    will return the home directory pathname.
 
 	    &local  "MODENAME"	    Retrieves local mode setting (for
-					current buffer).
+				    current buffer).
 
 	    &lookup   "N" "P"	    The "N" keyword tells which field to use
 				    looking for the file "P":
@@ -890,25 +900,31 @@
 				    bin, startup, path, libdir.  Note that
 				    the directory lists may overlap.
 
+	    &mclass "M"		    Retrieve the class to which the given
+	    			    mode belongs.  This is different from
+				    &mclass since it distinguishes the modes
+				    Return values include:  universal buffer
+				    window submode Majormode.
+
 	    &qpasswd  "S"	    Present "S" to the user and return their
-					response.  Each typed character is
-					echoed as '*'.  The response is not
-					recallable via the editor's history
-					mechanism.
+				    response.  Each typed character is
+				    echoed as '*'.  The response is not
+				    recallable via the editor's history
+				    mechanism.
 
 	    &query  "S"		    Present "S" to the user, and return
-					their typed response.
+				    their typed response.
 
 	    &date "F" "T"	    If strftime() is found, format the time "T"
-					using the "F" format.  Otherwise, use
-					ctime() to format the time.  Times are
-					numbers (see &ftime and &stime).
+				    using the "F" format.  Otherwise, use
+				    ctime() to format the time.  Times are
+				    numbers (see &ftime and &stime).
 
 	    &dquery  "S" "D"	    Present "S" to the user, and return
-					their typed response.  If "D" is given,
-					use that as the default response.
-					Otherwise use the previous response
-					as the default.
+				    their typed response.  If "D" is given,
+				    use that as the default response.
+				    Otherwise use the previous response
+				    as the default.
 
 	    &path   "N" "P"	    The "N" keyword tells which field to extract
 				    from the pathname "P":
@@ -1056,7 +1072,6 @@
 	The ~break directive allows early termination of an enclosing
 	while-loop.  Extending the above example:
 
-
 	       ; count the occurrences of a pattern in all buffers
 	       set nowrapscan
 	       set noautobuffer
@@ -1465,6 +1480,6 @@
 	========================= end vile.rc =======================
 
 -----------------------------------
-  @Header: /usr/build/vile/vile/doc/RCS/macros.doc,v 1.93 2004/10/20 22:47:38 tom Exp @
+  @Header: /usr/build/vile/vile/doc/RCS/macros.doc,v 1.94 2004/12/12 20:29:24 tom Exp @
 -----------------------------------
 
