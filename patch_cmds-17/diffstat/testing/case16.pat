
                             PDCurses 2.5
            (Public Domain Curses for DOS, OS/2, X11 and Win32)


INTRODUCTION:

This release of PDCurses includes the following changes:

- full support of X11 selection handling
- removed the need for the cursos2.h file
- enabled the "shifted" key on the numeric keypad
- added native clipboard support for X11, Win32 and OS/2
- added extra functions for obtaining internal PDCUrses status
- added clipboard and key modifier tests in testcurs.c
- fixes for panel library
- key modifiers pressed by themselves are now returned as keys
- Added X11 shared library support
- Added extra slk formats supported by ncurses
- Fixed bug with resizing the terminal when slk were on.
- Changed behaviour of slk_attrset(), slk_attron() alk_attroff()
  functions to work more like ncurses.

BUGS FIXED:

some minor bug and portability fixes were included in this release

NEW FUNCTIONS:

PDC_getclipboard() and PDC_setclipboard() for accessing the native
clipboard.
PDC_set_title() for setting the title of the window (X11 and Win32 only)
PDC_get_input_fd() for getting the file handle of the PDCurses input
PDC_get_key_modifiers() for getting the keyboard modifier settings at the
time of the last (w)getch()
initscrX() (only for X11 port) which allows standard X11 switches to 
be passed to the application


NEW COMPILER SUPPORT:

- MingW32 GNU compiler under Win95/NT
- Cygnus Win32 GNU compiler under Win95/NT
- Borland C++ for OS/2 1.0+
- lcc-win32 compiler under Win95/NT

Makefiles for each platform/compiler option reside in the platform
directory.  These all have an extension of .mak.


ACKNOWLEGEMENTS: (for this release)

Georg Fuchs for various changes.
Juan David Palomar for pointing out getnstr() was not implemented.
William McBrine for fix to allow black/black as valid color pair.
Peter Preus for pointing out the missing bccos2.mak file.
Laura Michaels for a couple of bug fixes and changes required to support
   Mingw32 compiler.
Frank Heckenbach for PDC_get_input_fd() and some portability fixes and
   the fixes for panel library.
Matthias Burian for the lcc-win32 compiler support.

Cheers, Mark
------------------------------------------------------------------------
 Mark Hessling                       Email:       M.Hessling@qut.edu.au
 PO Box 203                          http://www.lightlink.com/hessling/
 Bellara                                AUTHOR of  |  MAINTAINER of
 QLD 4507                                 THE      |    PDCurses
 Australia                              Rexx/SQL   |     Regina
                Member of RexxLA: http://www.rexxla.org/
------------------------------------------------------------------------

                                Module: PDCurses                                
                  Detailed differences between 2_4 and Latest                   

--------------------------------------------------------------------------------

Index: PDCurses/Makefile.in
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/Makefile.in,v
retrieving revision 1.1
retrieving revision 1.3
diff -b -w -r1.1 -r1.3
7,8c7,8
< VER=24
< VER_DOT=2.4
---
> VER=25
> VER_DOT=2.5
18,19c18
< INSTALL		=@INSTALL@
< INSTALL_DATA	=@INSTALL_DATA@
---
> INSTALL		=$(srcdir)/install-sh
20a20,22
> RXLIBPRE = @RXLIBPRE@
> RXLIBPST = @RXLIBPST@
> SHLFILE = XCurses
35,42c37,46
< 	$(INSTALL_DATA) $(srcdir)/curses.h $(includedir)/xcurses.h
< 	sed -e 's/#include <curses.h>/#include<xcurses.h>/' < panel.h > xpanel.h
< 	$(INSTALL_DATA) $(srcdir)/xpanel.h $(includedir)/panel.h
< 	$(INSTALL_DATA) pdcurses/libXCurses.a $(libdir)/libXCurses.a
< 	$(INSTALL_DATA) pdcurses/$(RXLIBPRE)$(SHLFILE)$(RXLIBPST) $(libdir)/$(RXLIBPRE)$(SHLFILE)$(RXLIBPST)
< 	$(RANLIB) $(libdir)/libXCurses.a
< 	$(INSTALL_DATA) panel/libpanel.a $(libdir)/libpanel.a
< 	$(RANLIB) $(libdir)/libpanel.a
---
> 	$(INSTALL) -d -m 755 $(libdir)
> 	$(INSTALL) -d -m 755 $(includedir)
> 	$(INSTALL) -c -m 644 $(srcdir)/curses.h $(includedir)/xcurses.h
> 	sed -e 's/#include <curses.h>/#include <xcurses.h>/' < $(srcdir)/panel.h > ./xpanel.h
> 	$(INSTALL) -m 644 ./xpanel.h $(includedir)/xpanel.h
> 	$(INSTALL) -c -m 644 pdcurses/libXCurses.a $(libdir)/libXCurses.a
> 	-$(RANLIB) $(libdir)/libXCurses.a
> 	$(INSTALL) -c -m 555 pdcurses/$(RXLIBPRE)$(SHLFILE)$(RXLIBPST) $(libdir)/$(RXLIBPRE)$(SHLFILE)$(RXLIBPST)
> 	$(INSTALL) -c -m 644 panel/libpanel.a $(libdir)/libpanel.a
> 	-$(RANLIB) $(libdir)/libpanel.a
57c61
< 	curses.h xcurses.h curspriv.h panel.h x11.h maintain.er readme.* makezip.cmd \
---
> 	curses.h xcurses.h curspriv.h panel.h maintain.er readme.* makezip.cmd \
63c67,68
< 	x11/README x11/*.c x11/*.xbm x11/*.def x11/*.h \
---
> 	x11/README x11/*.c x11/*.xbm x11/*.def x11/*.h x11/process/*.c x11/*.exp \
> 	x11/process/*.c x11/process/*.h x11/thread/*.c x11/thread/*.h \
66c71
< 	pdcurses/Makefile.in demos/Makefile.in panel/Makefile.in tools/Makefile.in
---
> 	pdcurses/Makefile.in pdcurses/Makefile.aix.in demos/Makefile.in panel/Makefile.in tools/Makefile.in
69c74
< 	(cd ..; tar cvf - $(PDC_DIR)/README $(PDC_DIR)/INSTALL $(PDC_DIR)/README $(PDC_DIR)/Makefile.in \
---
> 	(cd ..; tar cvf - $(PDC_DIR)/README $(PDC_DIR)/INSTALL $(PDC_DIR)/TODO $(PDC_DIR)/Makefile.in \
71c76
< 	$(PDC_DIR)/config.sub $(PDC_DIR)/install-sh $(PDC_DIR)/curses.h $(PDC_DIR)/xcurses.h \
---
> 	$(PDC_DIR)/config.sub $(PDC_DIR)/configure.in $(PDC_DIR)/install-sh $(PDC_DIR)/curses.h $(PDC_DIR)/xcurses.h \
73c78
< 	$(PDC_DIR)/x11.h $(PDC_DIR)/maintain.er $(PDC_DIR)/readme.* $(PDC_DIR)/makezip.cmd \
---
> 	$(PDC_DIR)/maintain.er $(PDC_DIR)/readme.* $(PDC_DIR)/makezip.cmd \
75c80
< 	$(PDC_DIR)/panel/README $(PDC_DIR)/panel/*.c \
---
> 	$(PDC_DIR)/panel/README $(PDC_DIR)/panel/*.c $(PDC_DIR)/*.spec \
79c84,85
< 	$(PDC_DIR)/x11/README $(PDC_DIR)/x11/*.c $(PDC_DIR)/x11/*.xbm $(PDC_DIR)/x11/*.def $(PDC_DIR)/x11/*.h \
---
> 	$(PDC_DIR)/x11/README $(PDC_DIR)/x11/*.c $(PDC_DIR)/x11/*.xbm $(PDC_DIR)/x11/*.def $(PDC_DIR)/x11/*.h $(PDC_DIR)/x11/*.exp \
> 	$(PDC_DIR)/x11/process/*.c $(PDC_DIR)/x11/process/*.h $(PDC_DIR)/x11/thread/*.c $(PDC_DIR)/x11/thread/*.h \
82c88
< 	$(PDC_DIR)/pdcurses/Makefile.in $(PDC_DIR)/demos/Makefile.in $(PDC_DIR)/tools/Makefile.in \
---
> 	$(PDC_DIR)/pdcurses/Makefile.in $(PDC_DIR)/pdcurses/Makefile.aix.in $(PDC_DIR)/demos/Makefile.in $(PDC_DIR)/tools/Makefile.in \
86c92
< 	(cd ..; tar cvf - $(PDC_DIR)/README $(PDC_DIR)/INSTALL $(PDC_DIR)/README $(PDC_DIR)/Makefile.in \
---
> 	(cd ..; tar cvf - $(PDC_DIR)/README $(PDC_DIR)/INSTALL $(PDC_DIR)/TODO $(PDC_DIR)/Makefile.in \
88c94
< 	$(PDC_DIR)/config.sub $(PDC_DIR)/install-sh $(PDC_DIR)/curses.h $(PDC_DIR)/xcurses.h \
---
> 	$(PDC_DIR)/config.sub $(PDC_DIR)/configure.in $(PDC_DIR)/install-sh $(PDC_DIR)/curses.h $(PDC_DIR)/xcurses.h \
90c96
< 	$(PDC_DIR)/x11.h $(PDC_DIR)/maintain.er $(PDC_DIR)/readme.* $(PDC_DIR)/makezip.cmd \
---
> 	$(PDC_DIR)/maintain.er $(PDC_DIR)/readme.* $(PDC_DIR)/makezip.cmd \
92c98
< 	$(PDC_DIR)/panel/README $(PDC_DIR)/panel/*.c \
---
> 	$(PDC_DIR)/panel/README $(PDC_DIR)/panel/*.c $(PDC_DIR)/*.spec \
96c102,103
< 	$(PDC_DIR)/x11/README $(PDC_DIR)/x11/*.c $(PDC_DIR)/x11/*.xbm $(PDC_DIR)/x11/*.def $(PDC_DIR)/x11/*.h \
---
> 	$(PDC_DIR)/x11/README $(PDC_DIR)/x11/*.c $(PDC_DIR)/x11/*.xbm $(PDC_DIR)/x11/*.def $(PDC_DIR)/x11/*.h $(PDC_DIR)/x11/*.exp \
> 	$(PDC_DIR)/x11/process/*.c $(PDC_DIR)/x11/process/*.h $(PDC_DIR)/x11/thread/*.c $(PDC_DIR)/x11/thread/*.h \
99c106
< 	$(PDC_DIR)/pdcurses/Makefile.in $(PDC_DIR)/demos/Makefile.in $(PDC_DIR)/tools/Makefile.in \
---
> 	$(PDC_DIR)/pdcurses/Makefile.in $(PDC_DIR)/pdcurses/Makefile.aix.in $(PDC_DIR)/demos/Makefile.in $(PDC_DIR)/tools/Makefile.in \

Index: PDCurses/README
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/README,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
21,22c21,23
<  PDCurses has been ported to DOS, OS/2, X11, WIN32 and Flexos. A
<  directory containing the port-specific source files exists for each
---
>  PDCurses has been ported to DOS, OS/2, X11, WIN32 and Amiga. A port
>  to Flexos is also included, but likely to be out of date.
>  A directory containing the port-specific source files exists for each

Index: PDCurses/aclocal.m4
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/aclocal.m4,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
329c329,334
< 		LD_RXLIB1="${CC} -Wl,-shared"
---
> 		LD_RXLIB1="${CC} -shared"
> 		RXLIBPRE="lib"
> 		RXLIBPST=".so"
> 		;;
> 	*nto-qnx*)
> 		LD_RXLIB1="${CC} -shared"

Index: PDCurses/config.h.in
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/config.h.in,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
127a128,133
> /* Define if you want to build XCurses with threads */
> #undef USE_THREADS
> 
> /* Define if you want to build XCurses with processes */
> #undef USE_PROCESSES
> 

Index: PDCurses/configure
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/configure,v
retrieving revision 1.1
retrieving revision 1.4
diff -b -w -r1.1 -r1.4
4c4
< # Generated automatically using autoconf version 2.12 
---
> # Generated automatically using autoconf version 2.13 
18a19,20
>   --with-threads          build XCurses with threads"
> ac_help="$ac_help
59a62
> SHELL=${CONFIG_SHELL-/bin/sh}
343c346
<     echo "configure generated by autoconf version 2.12"
---
>     echo "configure generated by autoconf version 2.13"
513c516
< ac_link='${CC-cc} -o conftest $CFLAGS $CPPFLAGS $LDFLAGS conftest.$ac_ext $LIBS 1>&5'
---
> ac_link='${CC-cc} -o conftest${ac_exeext} $CFLAGS $CPPFLAGS $LDFLAGS conftest.$ac_ext $LIBS 1>&5'
515a519,520
> ac_exeext=
> ac_objext=o
537c542
< echo "configure:538: checking for one of the following C compilers: $all_words" >&5
---
> echo "configure:543: checking for one of the following C compilers: $all_words" >&5
576c581
< echo "configure:577: checking for $ac_word" >&5
---
> echo "configure:582: checking for $ac_word" >&5
583,584c588,590
<   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
<   for ac_dir in $PATH; do
---
>   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS=":"
>   ac_dummy="$PATH"
>   for ac_dir in $ac_dummy; do
605c611
< echo "configure:606: checking for $ac_word" >&5
---
> echo "configure:612: checking for $ac_word" >&5
612c618
<   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
---
>   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS=":"
614c620,621
<   for ac_dir in $PATH; do
---
>   ac_dummy="$PATH"
>   for ac_dir in $ac_dummy; do
648a656,689
>   if test -z "$CC"; then
>     case "`uname -s`" in
>     *win32* | *WIN32*)
>       # Extract the first word of "cl", so it can be a program name with args.
> set dummy cl; ac_word=$2
> echo $ac_n "checking for $ac_word""... $ac_c" 1>&6
> echo "configure:663: checking for $ac_word" >&5
> if eval "test \"`echo '$''{'ac_cv_prog_CC'+set}'`\" = set"; then
>   echo $ac_n "(cached) $ac_c" 1>&6
> else
>   if test -n "$CC"; then
>   ac_cv_prog_CC="$CC" # Let the user override the test.
> else
>   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS=":"
>   ac_dummy="$PATH"
>   for ac_dir in $ac_dummy; do
>     test -z "$ac_dir" && ac_dir=.
>     if test -f $ac_dir/$ac_word; then
>       ac_cv_prog_CC="cl"
>       break
>     fi
>   done
>   IFS="$ac_save_ifs"
> fi
> fi
> CC="$ac_cv_prog_CC"
> if test -n "$CC"; then
>   echo "$ac_t""$CC" 1>&6
> else
>   echo "$ac_t""no" 1>&6
> fi
>  ;;
>     esac
>   fi
653c694
< echo "configure:654: checking whether the C compiler ($CC $CFLAGS $LDFLAGS) works" >&5
---
> echo "configure:695: checking whether the C compiler ($CC $CFLAGS $LDFLAGS) works" >&5
659c700
< ac_link='${CC-cc} -o conftest $CFLAGS $CPPFLAGS $LDFLAGS conftest.$ac_ext $LIBS 1>&5'
---
> ac_link='${CC-cc} -o conftest${ac_exeext} $CFLAGS $CPPFLAGS $LDFLAGS conftest.$ac_ext $LIBS 1>&5'
663c704,705
< #line 664 "configure"
---
> 
> #line 706 "configure"
664a707
> 
667c710
< if { (eval echo configure:668: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:711: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
680a724,729
> ac_ext=c
> # CFLAGS is not in ac_cpp because -g, -O, etc. are not valid cpp options.
> ac_cpp='$CPP $CPPFLAGS'
> ac_compile='${CC-cc} -c $CFLAGS $CPPFLAGS conftest.$ac_ext 1>&5'
> ac_link='${CC-cc} -o conftest${ac_exeext} $CFLAGS $CPPFLAGS $LDFLAGS conftest.$ac_ext $LIBS 1>&5'
> cross_compiling=$ac_cv_prog_cc_cross
687c736
< echo "configure:688: checking whether the C compiler ($CC $CFLAGS $LDFLAGS) is a cross-compiler" >&5
---
> echo "configure:737: checking whether the C compiler ($CC $CFLAGS $LDFLAGS) is a cross-compiler" >&5
692c741
< echo "configure:693: checking whether we are using GNU C" >&5
---
> echo "configure:742: checking whether we are using GNU C" >&5
701c750
< if { ac_try='${CC-cc} -E conftest.c'; { (eval echo configure:702: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }; } | egrep yes >/dev/null 2>&1; then
---
> if { ac_try='${CC-cc} -E conftest.c'; { (eval echo configure:751: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }; } | egrep yes >/dev/null 2>&1; then
711a761,764
> else
>   GCC=
> fi
> 
716c769
< echo "configure:717: checking whether ${CC-cc} accepts -g" >&5
---
> echo "configure:770: checking whether ${CC-cc} accepts -g" >&5
733a787
>   if test "$GCC" = yes; then
736c790
<     CFLAGS="-O2"
---
>     CFLAGS="-g"
739,740c793,797
<   GCC=
<   test "${CFLAGS+set}" = set || CFLAGS="-g"
---
>   if test "$GCC" = yes; then
>     CFLAGS="-O2"
>   else
>     CFLAGS=
>   fi
744c801
< echo "configure:745: checking for POSIXized ISC" >&5
---
> echo "configure:802: checking for POSIXized ISC" >&5
808c865
< if $ac_config_sub sun4 >/dev/null 2>&1; then :
---
> if ${CONFIG_SHELL-/bin/sh} $ac_config_sub sun4 >/dev/null 2>&1; then :
813c870
< echo "configure:814: checking host system type" >&5
---
> echo "configure:871: checking host system type" >&5
820c877
<     if host_alias=`$ac_config_guess`; then :
---
>     if host_alias=`${CONFIG_SHELL-/bin/sh} $ac_config_guess`; then :
827c884
< host=`$ac_config_sub $host_alias`
---
> host=`${CONFIG_SHELL-/bin/sh} $ac_config_sub $host_alias`
834c891
< echo "configure:835: checking target system type" >&5
---
> echo "configure:892: checking target system type" >&5
845c902
< target=`$ac_config_sub $target_alias`
---
> target=`${CONFIG_SHELL-/bin/sh} $ac_config_sub $target_alias`
852c909
< echo "configure:853: checking build system type" >&5
---
> echo "configure:910: checking build system type" >&5
863c920
< build=`$ac_config_sub $build_alias`
---
> build=`${CONFIG_SHELL-/bin/sh} $ac_config_sub $build_alias`
874a932
> mymakefile="Makefile"
881a940
> 		mymakefile="Makefile.aix"
894a954,955
> 	*nto-qnx*)
> 		;;
907c968
< echo "configure:908: checking for maximum signal specifier:" >&5
---
> echo "configure:969: checking for maximum signal specifier:" >&5
914c975
< #line 915 "configure"
---
> #line 976 "configure"
921c982
< if { (eval echo configure:922: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:983: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
953c1014
< echo "configure:954: checking for main in -l$mh_lib" >&5
---
> echo "configure:1015: checking for main in -l$mh_lib" >&5
961c1022
< #line 962 "configure"
---
> #line 1023 "configure"
968c1029
< if { (eval echo configure:969: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:1030: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
1002c1063
< echo "configure:1003: checking for $ac_word" >&5
---
> echo "configure:1064: checking for $ac_word" >&5
1009,1010c1070,1072
<   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
<   for ac_dir in $PATH; do
---
>   IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS=":"
>   ac_dummy="$PATH"
>   for ac_dir in $ac_dummy; do
1034a1097
> # AIX 4 /usr/bin/installbsd, which doesn't work without a -g flag
1039c1102
< echo "configure:1040: checking for a BSD compatible install" >&5
---
> echo "configure:1103: checking for a BSD compatible install" >&5
1044c1107
<     IFS="${IFS= 	}"; ac_save_IFS="$IFS"; IFS="${IFS}:"
---
>     IFS="${IFS= 	}"; ac_save_IFS="$IFS"; IFS=":"
1051c1114,1116
<       for ac_prog in ginstall installbsd scoinst install; do
---
>       # Don't use installbsd from OSF since it installs stuff as root
>       # by default.
>       for ac_prog in ginstall scoinst install; do
1056d1120
< 	    # OSF/1 installbsd also uses dspmsg, but is usable.
1085a1150,1151
> test -z "$INSTALL_SCRIPT" && INSTALL_SCRIPT='${INSTALL_PROGRAM}'
> 
1089c1155
< echo "configure:1090: checking whether ${MAKE-make} sets \${MAKE}" >&5
---
> echo "configure:1156: checking whether ${MAKE-make} sets \${MAKE}" >&5
1117c1183
< echo "configure:1118: checking how to run the C preprocessor" >&5
---
> echo "configure:1184: checking how to run the C preprocessor" >&5
1132c1198
< #line 1133 "configure"
---
> #line 1199 "configure"
1138,1139c1204,1205
< { (eval echo configure:1139: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:1205: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
1149c1215
< #line 1150 "configure"
---
> #line 1216 "configure"
1155,1156c1221,1239
< { (eval echo configure:1156: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:1222: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
> if test -z "$ac_err"; then
>   :
> else
>   echo "$ac_err" >&5
>   echo "configure: failed program was:" >&5
>   cat conftest.$ac_ext >&5
>   rm -rf conftest*
>   CPP="${CC-cc} -nologo -E"
>   cat > conftest.$ac_ext <<EOF
> #line 1233 "configure"
> #include "confdefs.h"
> #include <assert.h>
> Syntax Error
> EOF
> ac_try="$ac_cpp conftest.$ac_ext >/dev/null 2>conftest.out"
> { (eval echo configure:1239: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
1168a1252,1253
> fi
> rm -f conftest*
1179c1264
< echo "configure:1180: checking for System V IPC support" >&5
---
> echo "configure:1265: checking for System V IPC support" >&5
1182c1267
< echo "configure:1183: checking for sys/ipc.h" >&5
---
> echo "configure:1268: checking for sys/ipc.h" >&5
1187c1272
< #line 1188 "configure"
---
> #line 1273 "configure"
1192,1193c1277,1278
< { (eval echo configure:1193: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:1278: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
1220c1305
< echo "configure:1221: checking for ANSI C header files" >&5
---
> echo "configure:1306: checking for ANSI C header files" >&5
1225c1310
< #line 1226 "configure"
---
> #line 1311 "configure"
1233,1234c1318,1319
< { (eval echo configure:1234: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:1319: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
1250c1335
< #line 1251 "configure"
---
> #line 1336 "configure"
1268c1353
< #line 1269 "configure"
---
> #line 1354 "configure"
1289c1374
< #line 1290 "configure"
---
> #line 1375 "configure"
1300c1385
< if { (eval echo configure:1301: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest && (./conftest; exit) 2>/dev/null
---
> if { (eval echo configure:1386: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext} && (./conftest; exit) 2>/dev/null
1339c1424
< echo "configure:1340: checking for $ac_hdr" >&5
---
> echo "configure:1425: checking for $ac_hdr" >&5
1344c1429
< #line 1345 "configure"
---
> #line 1430 "configure"
1349,1350c1434,1435
< { (eval echo configure:1350: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:1435: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
1377c1462
< echo "configure:1378: checking if compiler supports ANSI prototypes" >&5
---
> echo "configure:1463: checking if compiler supports ANSI prototypes" >&5
1380c1465
< #line 1381 "configure"
---
> #line 1466 "configure"
1387c1472
< if { (eval echo configure:1388: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:1473: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
1405c1490
< echo "configure:1406: checking for working const" >&5
---
> echo "configure:1491: checking for working const" >&5
1410c1495
< #line 1411 "configure"
---
> #line 1496 "configure"
1459c1544
< if { (eval echo configure:1460: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:1545: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
1480c1565
< echo "configure:1481: checking for size_t" >&5
---
> echo "configure:1566: checking for size_t" >&5
1485c1570
< #line 1486 "configure"
---
> #line 1571 "configure"
1494c1579
<   egrep "size_t[^a-zA-Z_0-9]" >/dev/null 2>&1; then
---
>   egrep "(^|[^a-zA-Z_0-9])size_t[^a-zA-Z_0-9]" >/dev/null 2>&1; then
1513c1598
< echo "configure:1514: checking whether time.h and sys/time.h may both be included" >&5
---
> echo "configure:1599: checking whether time.h and sys/time.h may both be included" >&5
1518c1603
< #line 1519 "configure"
---
> #line 1604 "configure"
1527c1612
< if { (eval echo configure:1528: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:1613: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
1548c1633
< echo "configure:1549: checking whether struct tm is in sys/time.h or time.h" >&5
---
> echo "configure:1634: checking whether struct tm is in sys/time.h or time.h" >&5
1553c1638
< #line 1554 "configure"
---
> #line 1639 "configure"
1561c1646
< if { (eval echo configure:1562: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:1647: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
1586c1671
< echo "configure:1587: checking for main in -l$mh_lib" >&5
---
> echo "configure:1672: checking for main in -l$mh_lib" >&5
1594c1679
< #line 1595 "configure"
---
> #line 1680 "configure"
1601c1686
< if { (eval echo configure:1602: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:1687: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
1633c1718
< echo "configure:1634: checking whether $CC understand -c and -o together" >&5
---
> echo "configure:1719: checking whether $CC understand -c and -o together" >&5
1644c1729
< if { (eval echo configure:__oline__: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; } && test -f conftest.ooo && { (eval echo configure:1645: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; };
---
> if { (eval echo configure:__oline__: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; } && test -f conftest.ooo && { (eval echo configure:1730: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; };
1647c1732
<   if { (eval echo configure:__oline__: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; } && test -f conftest.ooo && { (eval echo configure:1648: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; };
---
>   if { (eval echo configure:__oline__: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; } && test -f conftest.ooo && { (eval echo configure:1733: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; };
1672c1757
< echo "configure:1673: checking whether ${CC-cc} needs -traditional" >&5
---
> echo "configure:1758: checking whether ${CC-cc} needs -traditional" >&5
1678c1763
< #line 1679 "configure"
---
> #line 1764 "configure"
1696c1781
< #line 1697 "configure"
---
> #line 1782 "configure"
1718c1803
< echo "configure:1719: checking for 8-bit clean memcmp" >&5
---
> echo "configure:1804: checking for 8-bit clean memcmp" >&5
1726c1811
< #line 1727 "configure"
---
> #line 1812 "configure"
1736c1821
< if { (eval echo configure:1737: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest && (./conftest; exit) 2>/dev/null
---
> if { (eval echo configure:1822: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext} && (./conftest; exit) 2>/dev/null
1751c1836
< test $ac_cv_func_memcmp_clean = no && LIBOBJS="$LIBOBJS memcmp.o"
---
> test $ac_cv_func_memcmp_clean = no && LIBOBJS="$LIBOBJS memcmp.${ac_objext}"
1754c1839
< echo "configure:1755: checking return type of signal handlers" >&5
---
> echo "configure:1840: checking return type of signal handlers" >&5
1759c1844
< #line 1760 "configure"
---
> #line 1845 "configure"
1776c1861
< if { (eval echo configure:1777: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:1862: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
1795c1880
< echo "configure:1796: checking for vprintf" >&5
---
> echo "configure:1881: checking for vprintf" >&5
1800c1885
< #line 1801 "configure"
---
> #line 1886 "configure"
1823c1908
< if { (eval echo configure:1824: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:1909: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
1847c1932
< echo "configure:1848: checking for _doprnt" >&5
---
> echo "configure:1933: checking for _doprnt" >&5
1852c1937
< #line 1853 "configure"
---
> #line 1938 "configure"
1875c1960
< if { (eval echo configure:1876: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:1961: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
1902c1987
< echo "configure:1903: checking for $ac_func" >&5
---
> echo "configure:1988: checking for $ac_func" >&5
1907c1992
< #line 1908 "configure"
---
> #line 1993 "configure"
1930c2015
< if { (eval echo configure:1931: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest; then
---
> if { (eval echo configure:2016: \"$ac_link\") 1>&5; (eval $ac_link) 2>&5; } && test -s conftest${ac_exeext}; then
1957c2042
< echo "configure:1958: checking for location of X headers" >&5
---
> echo "configure:2043: checking for location of X headers" >&5
2052c2137
< echo "configure:2053: checking for location of X libraries" >&5
---
> echo "configure:2138: checking for location of X libraries" >&5
2187c2272
< echo "configure:2188: checking for $ac_hdr" >&5
---
> echo "configure:2273: checking for $ac_hdr" >&5
2192c2277
< #line 2193 "configure"
---
> #line 2278 "configure"
2197,2198c2282,2283
< { (eval echo configure:2198: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
< ac_err=`grep -v '^ *+' conftest.out`
---
> { (eval echo configure:2283: \"$ac_try\") 1>&5; (eval $ac_try) 2>&5; }
> ac_err=`grep -v '^ *+' conftest.out | grep -v "^conftest.${ac_ext}\$"`
2232c2317
< echo "configure:2233: checking for $mh_keydef in keysym.h" >&5
---
> echo "configure:2318: checking for $mh_keydef in keysym.h" >&5
2235c2320
< #line 2236 "configure"
---
> #line 2321 "configure"
2242c2327
< if { (eval echo configure:2243: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
---
> if { (eval echo configure:2328: \"$ac_compile\") 1>&5; (eval $ac_compile) 2>&5; }; then
2316a2402,2424
> # Check whether --with-threads or --without-threads was given.
> if test "${with_threads+set}" = set; then
>   withval="$with_threads"
>   with_threads=$withval
> else
>   with_threads=no
> fi
> 
> if test "$with_threads" = yes; then
> 	cat >> confdefs.h <<\EOF
> #define USE_THREADS 1
> EOF
> 
> 	x11type="thread"
> else
> 	cat >> confdefs.h <<\EOF
> #define USE_PROCESSES 1
> EOF
> 
> 	x11type="process"
> fi
> 
> 
2397c2505
< echo "configure:2398: checking compiler flags for a dynamic object" >&5
---
> echo "configure:2506: checking compiler flags for a dynamic object" >&5
2400c2508
< #line 2401 "configure"
---
> #line 2509 "configure"
2412c2520
< 		if { (eval echo configure:2413: \"$mh_compile\") 1>&5; (eval $mh_compile) 2>&5; }; then
---
> 		if { (eval echo configure:2521: \"$mh_compile\") 1>&5; (eval $mh_compile) 2>&5; }; then
2500c2608
< 		LD_RXLIB1="ld"
---
> 		LD_RXLIB1="ld -assert pure-text"
2510c2618,2623
< 		LD_RXLIB1="${CC} -Wl,-shared"
---
> 		LD_RXLIB1="${CC} -shared"
> 		RXLIBPRE="lib"
> 		RXLIBPST=".so"
> 		;;
> 	*nto-qnx*)
> 		LD_RXLIB1="${CC} -shared"
2524c2637
< #line 2525 "configure"
---
> #line 2638 "configure"
2530c2643
< if { (eval echo configure:2531: \"$mh_compile\") 1>&5; (eval $mh_compile) 2>&5; } && test -s conftest.o; then
---
> if { (eval echo configure:2644: \"$mh_compile\") 1>&5; (eval $mh_compile) 2>&5; } && test -s conftest.o; then
2532c2645
< 	if { (eval echo configure:2533: \"$mh_dyn_link\") 1>&5; (eval $mh_dyn_link) 2>&5; } && test -s conftest.rxlib; then
---
> 	if { (eval echo configure:2646: \"$mh_dyn_link\") 1>&5; (eval $mh_dyn_link) 2>&5; } && test -s conftest.rxlib; then
2538c2651
< 		if { (eval echo configure:2539: \"$mh_dyn_link\") 1>&5; (eval $mh_dyn_link) 2>&5; } && test -s conftest.rxlib; then
---
> 		if { (eval echo configure:2652: \"$mh_dyn_link\") 1>&5; (eval $mh_dyn_link) 2>&5; } && test -s conftest.rxlib; then
2606c2719
<   case `(ac_space=' '; set) 2>&1` in
---
>   case `(ac_space=' '; set | grep ac_space) 2>&1` in
2673c2786
<     echo "$CONFIG_STATUS generated by autoconf version 2.12"
---
>     echo "$CONFIG_STATUS generated by autoconf version 2.13"
2684c2797
< trap 'rm -fr `echo "Makefile pdcurses/Makefile demos/Makefile panel/Makefile tools/Makefile saa/Makefile config.h" | sed "s/:[^ ]*//g"` conftest*; exit 1' 1 2 15
---
> trap 'rm -fr `echo "Makefile pdcurses/$mymakefile demos/Makefile panel/Makefile tools/Makefile saa/Makefile config.h" | sed "s/:[^ ]*//g"` conftest*; exit 1' 1 2 15
2692a2806
> s%@SHELL@%$SHELL%g
2695a2810
> s%@FFLAGS@%$FFLAGS%g
2732a2848
> s%@INSTALL_SCRIPT@%$INSTALL_SCRIPT%g
2739a2856
> s%@x11type@%$x11type%g
2802c2919
< CONFIG_FILES=\${CONFIG_FILES-"Makefile pdcurses/Makefile demos/Makefile panel/Makefile tools/Makefile saa/Makefile"}
---
> CONFIG_FILES=\${CONFIG_FILES-"Makefile pdcurses/$mymakefile demos/Makefile panel/Makefile tools/Makefile saa/Makefile"}
2979a3097,3105
> 
> case "$target" in
>         *ibm-aix*)
>                 mv pdcurses/Makefile.aix pdcurses/Makefile
>                 echo "$ac_t""renaming pdcurses/Makefile.aix to pdcurses/Makefile" 1>&6
>                 ;;
>         *)
>                 ;;
> esac

Index: PDCurses/curses.h
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/curses.h,v
retrieving revision 1.2
retrieving revision 1.5
diff -b -w -r1.2 -r1.5
21c21
< @Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @
---
> @Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @
172c172
< #define PDC_BUILD	2401
---
> #define PDC_BUILD	2501
970a971,972
> 	short	line_color;	/* Color of line attributes - default white */
> 
1044,1045d1045
< #define A_STANDOUT		  0x00A00000L
< #define A_BOLD		      0x00800000L
1048a1049,1050
> # define A_BOLD          0x00800000L
> # define A_RIGHTLINE     0x00010000L
1050,1051d1051
< #define A_INVIS		     0x00080000L
< #define A_PROTECT		   0x00010000L
1052a1053
> # define A_INVIS         0x00080000L
1056a1058,1062
> # define A_LEFTLINE      A_DIM
> # define A_ITALIC        A_INVIS
> # define A_STANDOUT      ( A_BOLD | A_REVERSE )
> # define A_PROTECT       ( A_UNDERLINE | A_LEFTLINE | A_RIGHTLINE )
> 
1059c1065
< #define A_NORMAL	(chtype)0x0000		/* SysV */
---
> # define A_NORMAL      (chtype)0x0000                  /* System V */
1499c1505,1507
< # define KEY_MAX         0x222   /* Maximum curses key            */
---
> # define KEY_SUP         0x223   /* Shifted up arrow              */
> # define KEY_SDOWN       0x224   /* Shifted down arrow            */
> # define KEY_MAX         0x224   /* Maximum curses key            */
1712a1721
> int     PDC_CDECL	PDC_curs_set( int );
1714a1724,1728
> int     PDC_CDECL	PDC_wunderline( WINDOW*, int, bool );
> int     PDC_CDECL	PDC_wleftline( WINDOW*, int, bool );
> int     PDC_CDECL	PDC_wrightline( WINDOW*, int, bool );
> int     PDC_CDECL	PDC_set_line_color( short );
> 
1914a1929
> int     PDC_CDECL	PDC_curs_set( /* int */ );
1916a1932,1936
> int     PDC_CDECL	PDC_wunderline( /* WINDOW*, int, bool */ );
> int     PDC_CDECL	PDC_wleftline( /* WINDOW*, int, bool */ );
> int     PDC_CDECL	PDC_wrightline( /* WINDOW*, int, bool */ );
> int     PDC_CDECL	PDC_set_line_color( /* short */ );
> 
1954a1975
> #define getbkgd(w)              ((w)->_bkgd)

Index: PDCurses/curspriv.h
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/curspriv.h,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3
21c21
< @Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @
---
> @Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @
370,371c370,371
< int             XCurses_display_cursor(int,int,int,int);
< int             XCurses_rawgetch(void);
---
> int             XCurses_display_cursor(int,int,int,int,int);
> int             XCurses_rawgetch(int);
385d384
< void            XCurses_set_title(char *);
490,491c489,490
< int             XCurses_display_cursor( /*int,int,int,int*/ );
< int             XCurses_rawgetch( /*void*/ );
---
> int             XCurses_display_cursor( /*int,int,int,int,int*/ );
> int             XCurses_rawgetch( /*int*/ );
577a577
> #define CURSES_DISPLAY_CURSOR      999986

Index: PDCurses/demos/testcurs.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/demos/testcurs.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
36c36
< char *rcsid_testcurs  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_testcurs  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
826c826,830
<  attrset(A_NORMAL);
---
> #ifdef XCURSES
>  attrset(A_PROTECT);
> #else
>  attrset(A_BOLD);
> #endif
827a832
>  attrset(A_NORMAL);

Index: PDCurses/doc/intro.man
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/doc/intro.man,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
366,376c366,376
< 	***	slk_attroff               slk
< 	***	slk_attron                slk
< 	***	slk_attrset               slk
< 	***	slk_clear                 slk
< 	***	slk_init                  slk
< 	***	slk_label                 slk
< 	***	slk_noutrefresh           slk
< 	***	slk_refresh               slk
< 	***	slk_restore               slk
< 	***	slk_set                   slk
< 	***	slk_touch                 slk
---
> 		slk_attroff              slk
> 		slk_attron               slk
> 		slk_attrset              slk
> 		slk_clear                slk
> 		slk_init                 slk
> 		slk_label                slk
> 		slk_noutrefresh          slk
> 		slk_refresh              slk
> 		slk_restore              slk
> 		slk_set                  slk
> 		slk_touch                slk
497a498,499
> 		PDC_get_input_fd         pdckbd
> 		PDC_get_key_modifiers    pdckbd
499a502
> 		PDC_getclipboard         pdcclip
519a523,524
> 		PDC_set_title            pdcsetsc
> 		PDC_setclipboard         pdcclip

Index: PDCurses/doc/x11.man
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/doc/x11.man,v
retrieving revision 1.1
retrieving revision 1.3
diff -b -w -r1.1 -r1.3
11,12c11,12
<  To use XCurses with an existing curses program, you need to make two
<  changes to your code.
---
>  To use XCurses with an existing curses program, you need to make one
>  change to your code:
14,25c14
<  The first is the addition of a definition of the program name as a
<  global char pointer. eg.
< 
< #ifdef XCURSES
<  char *XCursesProgramName="sample";
< #endif
< 
<  This name is used as the title of the X window, and for defining X
<  resources specific to your program.
< 
<  The second is a call to XCursesExit() just before exiting from your
<  program. eg.
---
>  Call XCursesExit() just before exiting from your program. eg.
35c24,26
<  When compiling your curses application, you need to add -DXCURSES.
---
>  When compiling your curses application, you need to add -DXCURSES, and
>  include the <curses.h> or <xcurses.h> that comes with XCurses. You also
>  need to link your code with the XCurses library.
47a39,45
>  To get the most out of XCurses in your curses application you need
>  to call Xinitscr() rather than initscr(). This allows you to pass
>  your program name and resource overrides to XCurses.
> 
>  The program name is used as the title of the X window, and for defining X
>  resources specific to your program.
> 
70c68
<     boldFont
---
>     italicFont
82a81,88
>     colorBoldBlack
>     colorBoldRed
>     colorBoldGreen
>     colorBoldYellow
>     colorBoldBlue
>     colorBoldMagenta
>     colorBoldCyan
>     colorBoldWhite
104c110
< normalFont:        the name of a fixed width font, used for A_NORMAL attribute
---
> normalFont:        the name of a fixed width font
107,110c113,116
< boldFont:          the name of a fixed width font, used for A_BOLD attribute
<                    Default:        7x13bold
< 
<                    NB. The dimensions of font and boldFont MUST be the same.
---
> italicFont:        the name of a fixed width font to be used for
>                    characters with A_ITALIC attributes. Must have the same
>                    cell size as normalFont
>                    Default:        7x13 (obviously not an italic font)
125a132
>                    Default: Black
126a134
>                    Default: red3
127a136
>                    Default: green3
128a138
>                    Default: yellow3
129a140
>                    Default: blue3
130a142
>                    Default: magenta3
131a144
>                    Default: cyan3
133c146,162
<                    Defaults are obvious :)
---
>                    Default: Grey
> colorBoldBlack:    the color of the COLOR_BLACK attribute combined with A_BOLD
>                    Default: grey40
> colorBoldRed       the color of the COLOR_RED attribute combined with A_BOLD
>                    Default: red1
> colorBoldGreen     the color of the COLOR_GREEN attribute combined with A_BOLD
>                    Default: green1
> colorBoldYellow    the color of the COLOR_YELLOW attribute combined with A_BOLD
>                    Default: yellow1
> colorBoldBlue      the color of the COLOR_BLUE attribute combined with A_BOLD
>                    Default: blue1
> colorBoldMagenta   the color of the COLOR_MAGENTA attribute combined with A_BOLD
>                    Default: magenta1
> colorBoldCyan      the color of the COLOR_CYAN attribute combined with A_BOLD
>                    Default: cyan1
> colorBoldWhite     the color of the COLOR_WHITE attribute combined with A_BOLD
>                    Default: White
222d250
< XCurses*boldFont:       9x13bold
236,242c264,276
< the.normalFont: 9x15
< the.boldFont:   9x15bold
< the.lines:      40
< the.cols:       86
< the.pointer:    xterm
< the.pointerForeColor: black
< the.pointerBackColor: black
---
> ! resources with the * wildcard can be overridden by a parameter passed
> ! to initscr()
> !
> the*normalFont: 9x15
> the*lines:      40
> the*cols:       86
> the*pointer:    xterm
> the*pointerForeColor: white
> the*pointerBackColor: black
> !
> ! resources with the . format can not be overridden by a parameter passed
> ! to Xinitscr()
> !
243a278,283
> 
> Resources may also be passed as a parameter to the Xinitscr() function.
> The parameter is a string in the form of switches. eg. to set the color
> "red" to "indianred", and the number of lines to 30, the string passed to 
> Xinitscr would be:
> "-colorRed indianred -lines 30"

Index: PDCurses/dos/pdckbd.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/dos/pdckbd.c,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3
35c35
< char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
56a57,62
>  /* Shifted Keypad		 */
>  0xb0, KEY_SHOME, 0xb1, KEY_SUP,   0xb2, KEY_SPREVIOUS,
>  0xb3, KEY_SLEFT, 0xb4, KEY_SRIGHT,
>  0xb5, KEY_SEND,  0xb6, KEY_SDOWN, 0xb7, KEY_SNEXT,
>  0xb8, KEY_SIC,   0xb9, KEY_SDC,
> 
338a345,364
> 	if (ascii == 0xe0 && scan == 0x47 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Home */
> 		return ((int) (0xb0 << 8));
> 	if (ascii == 0xe0 && scan == 0x48 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Up */
> 		return ((int) (0xb1 << 8));
> 	if (ascii == 0xe0 && scan == 0x49 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift PgUp */
> 		return ((int) (0xb2 << 8));
> 	if (ascii == 0xe0 && scan == 0x4b && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Left */
> 		return ((int) (0xb3 << 8));
> 	if (ascii == 0xe0 && scan == 0x4d && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Right */
> 		return ((int) (0xb4 << 8));
> 	if (ascii == 0xe0 && scan == 0x4f && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift End */
> 		return ((int) (0xb5 << 8));
> 	if (ascii == 0xe0 && scan == 0x50 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Down */
> 		return ((int) (0xb6 << 8));
> 	if (ascii == 0xe0 && scan == 0x51 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift PgDn */
> 		return ((int) (0xb7 << 8));
> 	if (ascii == 0xe0 && scan == 0x52 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Ins */
> 		return ((int) (0xb8 << 8));
> 	if (ascii == 0xe0 && scan == 0x53 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Del */
> 		return ((int) (0xb9 << 8));

Index: PDCurses/dos/wccdos.lrf
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/dos/wccdos.lrf,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3

Index: PDCurses/dos/wccdos16.mak
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/dos/wccdos16.mak,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3

Index: PDCurses/dos/wccdos4g.mak
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/dos/wccdos4g.mak,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3

Index: PDCurses/install-sh
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/install-sh,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
4c4,16
< # This comes from X11R5.
---
> # This comes from X11R5 (mit/util/scripts/install.sh).
> #
> # Copyright 1991 by the Massachusetts Institute of Technology
> #
> # Permission to use, copy, modify, distribute, and sell this software and its
> # documentation for any purpose is hereby granted without fee, provided that
> # the above copyright notice appear in all copies and that both that
> # copyright notice and this permission notice appear in supporting
> # documentation, and that the name of M.I.T. not be used in advertising or
> # publicity pertaining to distribution of the software without specific,
> # written prior permission.  M.I.T. makes no representations about the
> # suitability of this software for any purpose.  It is provided "as is"
> # without express or implied warranty.
11,12c23,24
< # from scratch.
< #
---
> # from scratch.  It can only install one file at a time, a restriction
> # shared with many OS's install programs.
17a30,32
> #
> # Modified 1 Feb 2000 MHES to cater for mkdir -p
> #
32c47
< tranformbasename=""
---
> transformbasename=""
40a56
> mkdircmd="$mkdirprog -p"
171c187
< 		$mkdirprog "${pathcomp}"
---
>                 $mkdircmd "${pathcomp}"

Index: PDCurses/os2/gccos2.mak
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/os2/gccos2.mak,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3
18c18
< PDCURSES_HOME		=c:\curses
---
> PDCURSES_HOME		=e:\curses
50c50
< 	DLLTARGET = pdcurses.dll
---
> 	DLLTARGET = curses.dll
62c62
< DLLCURSES = pdcurses_dll.lib
---
> DLLCURSES = curses.lib
206,209c206,209
< pdcurses.dll : $(DLLOBJS) $(PDCDLOS)
< 	$(LINK) $(DLLFLAGS) -o pdcurses.dll $(DLLOBJS) $(PDCDLOS) $(osdir)\pdcurses.def
< 	emximp -o pdcurses_dll.lib $(osdir)\pdcurses.def
< 	emximp -o pdcurses_dll.a pdcurses_dll.lib
---
> curses.dll : $(DLLOBJS) $(PDCDLOS)
> 	$(LINK) $(DLLFLAGS) -o curses.dll $(DLLOBJS) $(PDCDLOS) $(osdir)\pdcurses.def
> 	emximp -o curses.lib $(osdir)\pdcurses.def
> 	emximp -o curses.a curses.lib

Index: PDCurses/os2/pdckbd.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/os2/pdckbd.c,v
retrieving revision 1.2
retrieving revision 1.3
diff -b -w -r1.2 -r1.3
36c36
< char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
57a58,63
>  /* Shifted Keypad		 */
>  0xb0, KEY_SHOME, 0xb1, KEY_SUP,   0xb2, KEY_SPREVIOUS,
>  0xb3, KEY_SLEFT, 0xb4, KEY_SRIGHT,
>  0xb5, KEY_SEND,  0xb6, KEY_SDOWN, 0xb7, KEY_SNEXT,
>  0xb8, KEY_SIC,   0xb9, KEY_SDC,
> 
358a365,384
> 	if (ascii == 0xe0 && scan == 0x47 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Home */
> 		return ((int) (0xb0 << 8));
> 	if (ascii == 0xe0 && scan == 0x48 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Up */
> 		return ((int) (0xb1 << 8));
> 	if (ascii == 0xe0 && scan == 0x49 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift PgUp */
> 		return ((int) (0xb2 << 8));
> 	if (ascii == 0xe0 && scan == 0x4b && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Left */
> 		return ((int) (0xb3 << 8));
> 	if (ascii == 0xe0 && scan == 0x4d && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Right */
> 		return ((int) (0xb4 << 8));
> 	if (ascii == 0xe0 && scan == 0x4f && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift End */
> 		return ((int) (0xb5 << 8));
> 	if (ascii == 0xe0 && scan == 0x50 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Down */
> 		return ((int) (0xb6 << 8));
> 	if (ascii == 0xe0 && scan == 0x51 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift PgDn */
> 		return ((int) (0xb7 << 8));
> 	if (ascii == 0xe0 && scan == 0x52 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Ins */
> 		return ((int) (0xb8 << 8));
> 	if (ascii == 0xe0 && scan == 0x53 && pdc_key_modifiers & PDC_KEY_MODIFIER_SHIFT) /* Shift Del */
> 		return ((int) (0xb9 << 8));

Index: PDCurses/os2/pdcurses.def
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/os2/pdcurses.def,v
retrieving revision 1.2
retrieving revision 1.4
diff -b -w -r1.2 -r1.4
1c1
< LIBRARY     PDCURSES
---
> LIBRARY     CURSES
95a96,98
>             slk_attroff
>             slk_attron
>             slk_attrset
97a101
>             slk_label
98a103,104
>             slk_refresh
>             slk_restore

Index: PDCurses/pdcurses/Makefile.in
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/Makefile.in,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
13c13,14
< x11dir		= $(srcdir)/../x11
---
> x11basedir		= $(srcdir)/../x11
> x11dir		= $(x11basedir)/@x11type@
26c27
< PDCURSES_X11_H		=$(PDCURSES_HOME)/x11.h
---
> PDCURSES_X11_H		=$(x11basedir)/pdcx11.h
47c48
< CPPFLAGS	= -I$(INCDIR) -I$(srcdir)/.. -I.. @DEFS@ -DXCURSES @SYS_DEFS@
---
> CPPFLAGS	= -I$(INCDIR) -I$(srcdir)/.. -I.. @DEFS@ -DXCURSES @SYS_DEFS@ -I$(x11basedir) -I$(x11dir)
129a131,133
> pdcx11.o    \
> x11curses.o \
> x11common.o \
185a190,192
> pdcx11.sho    \
> x11curses.sho \
> x11common.sho \
311,312c318,319
< pdcclip.o: $(x11dir)/pdcclip.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcclip.c
---
> pdcclip.o: $(x11basedir)/pdcclip.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcclip.c
317,318c324,325
< pdcdisp.o: $(x11dir)/pdcdisp.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcdisp.c
---
> pdcdisp.o: $(x11basedir)/pdcdisp.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcdisp.c
320,321c327,328
< pdcgetsc.o: $(x11dir)/pdcgetsc.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcgetsc.c
---
> pdcgetsc.o: $(x11basedir)/pdcgetsc.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcgetsc.c
323,324c330,331
< pdckbd.o: $(x11dir)/pdckbd.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdckbd.c
---
> pdckbd.o: $(x11basedir)/pdckbd.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdckbd.c
326,327c333,334
< pdcprint.o: $(x11dir)/pdcprint.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcprint.c
---
> pdcprint.o: $(x11basedir)/pdcprint.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcprint.c
329,330c336,337
< pdcscrn.o: $(x11dir)/pdcscrn.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcscrn.c
---
> pdcscrn.o: $(x11basedir)/pdcscrn.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcscrn.c
332,333c339,340
< pdcsetsc.o: $(x11dir)/pdcsetsc.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/pdcsetsc.c
---
> pdcsetsc.o: $(x11basedir)/pdcsetsc.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcsetsc.c
341,342c348,355
< x11.o: $(x11dir)/x11.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/x11.c
---
> pdcx11.o: $(x11basedir)/pdcx11.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/pdcx11.c
> 
> ScrollBox.o: $(x11basedir)/ScrollBox.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/ScrollBox.c
> 
> sb.o: $(x11basedir)/sb.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11basedir)/sb.c
344,345c357,361
< ScrollBox.o: $(x11dir)/ScrollBox.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/ScrollBox.c
---
> x11common.o: $(x11dir)/x11common.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/x11common.c
> 
> x11.o: $(x11dir)/x11.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/x11.c
347,348c363,364
< sb.o: $(x11dir)/sb.c $(PDCURSES_HEADERS)
< 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/sb.c
---
> x11curses.o: $(x11dir)/x11curses.c $(PDCURSES_HEADERS)
> 	$(CC) $(CCFLAGS) -o $@ $(x11dir)/x11curses.c
574c590
< pdcclip.sho: $(x11dir)/pdcclip.c $(PDCURSES_HEADERS)
---
> pdcclip.sho: $(x11basedir)/pdcclip.c $(PDCURSES_HEADERS)
576c592
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcclip.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcclip.c
586c602
< pdcdisp.sho: $(x11dir)/pdcdisp.c $(PDCURSES_HEADERS)
---
> pdcdisp.sho: $(x11basedir)/pdcdisp.c $(PDCURSES_HEADERS)
588c604
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcdisp.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcdisp.c
592c608
< pdcgetsc.sho: $(x11dir)/pdcgetsc.c $(PDCURSES_HEADERS)
---
> pdcgetsc.sho: $(x11basedir)/pdcgetsc.c $(PDCURSES_HEADERS)
594c610
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcgetsc.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcgetsc.c
598c614
< pdckbd.sho: $(x11dir)/pdckbd.c $(PDCURSES_HEADERS)
---
> pdckbd.sho: $(x11basedir)/pdckbd.c $(PDCURSES_HEADERS)
600c616
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdckbd.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdckbd.c
604c620
< pdcprint.sho: $(x11dir)/pdcprint.c $(PDCURSES_HEADERS)
---
> pdcprint.sho: $(x11basedir)/pdcprint.c $(PDCURSES_HEADERS)
606c622
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcprint.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcprint.c
610c626
< pdcscrn.sho: $(x11dir)/pdcscrn.c $(PDCURSES_HEADERS)
---
> pdcscrn.sho: $(x11basedir)/pdcscrn.c $(PDCURSES_HEADERS)
612c628
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcscrn.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcscrn.c
616c632
< pdcsetsc.sho: $(x11dir)/pdcsetsc.c $(PDCURSES_HEADERS)
---
> pdcsetsc.sho: $(x11basedir)/pdcsetsc.c $(PDCURSES_HEADERS)
618c634
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/pdcsetsc.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcsetsc.c
634c650
< x11.sho: $(x11dir)/x11.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
---
> pdcx11.sho: $(x11basedir)/pdcx11.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
636c652,658
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/x11.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/pdcx11.c
> 	$(O2SHO)
> 	$(SAVE2O)
> 
> ScrollBox.sho: $(x11basedir)/ScrollBox.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
> 	$(O2SAVE)
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/ScrollBox.c
640c662
< ScrollBox.sho: $(x11dir)/ScrollBox.c $(PDCURSES_HEADERS) $(PDCURSES_X11_H)
---
> sb.sho: $(x11basedir)/sb.c $(PDCURSES_HEADERS)
642c664,676
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/ScrollBox.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11basedir)/sb.c
> 	$(O2SHO)
> 	$(SAVE2O)
> 
> x11common.sho: $(x11dir)/x11common.c $(PDCURSES_HEADERS)
> 	$(O2SAVE)
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/x11common.c
> 	$(O2SHO)
> 	$(SAVE2O)
> 
> x11.sho: $(x11dir)/x11.c $(PDCURSES_HEADERS)
> 	$(O2SAVE)
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/x11.c
646c680
< sb.sho: $(x11dir)/sb.c $(PDCURSES_HEADERS)
---
> x11curses.sho: $(x11dir)/x11curses.c $(PDCURSES_HEADERS)
648c682
< 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/sb.c
---
> 	$(CC) $(CCFLAGS) $(DYN_COMP) $(CC2O) $(x11dir)/x11curses.c

Index: PDCurses/pdcurses/border.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/border.c,v
retrieving revision 1.1
retrieving revision 1.3
diff -b -w -r1.1 -r1.3
33a34,36
> #undef	PDC_wunderline
> #undef	PDC_leftline
> #undef	PDC_rightline
40c43
< char *rcsid_border  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_border  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
56a60,62
>   	int PDC_wunderline(WINDOW *win, int n, bool state);
>   	int PDC_wleftline(WINDOW *win, int n, bool state);
>   	int PDC_wrightline(WINDOW *win, int n, bool state);
90c96
<   Portability                             X/Open    BSD    SYS V
---
>   Portability                             X/Open    BSD    SYS V  PDCurses
92,98c98,107
<       border                                -        -      4.0
<       wborder                               -        -      4.0
<       box                                   Y        Y       Y
<       hline                                 -        -      4.0
<       whline                                -        -      4.0
<       vline                                 -        -      4.0
<       wvline                                -        -      4.0
---
>       border                                -        -      4.0      Y
>       wborder                               -        -      4.0      Y
>       box                                   Y        Y       Y       Y
>       hline                                 -        -      4.0      Y
>       whline                                -        -      4.0      Y
>       vline                                 -        -      4.0      Y
>       wvline                                -        -      4.0      Y
>       PDC_wunderline                        -        -       -       Y
>       PDC_wleftline                         -        -       -       Y
>       PDC_wrightline                        -        -       -       Y
415a425,565
> 
> 		if (win->_firstch[n] == _NO_CHANGE)
> 		{
> 			win->_firstch[n] = win->_curx;
> 			win->_lastch[n] = win->_curx;
> 		}
> 		else
> 		{
> 			win->_firstch[n] = min(win->_firstch[n], win->_curx);
> 			win->_lastch[n] = max(win->_lastch[n], win->_curx);
> 		}
> 	}
> 
> 	PDC_sync(win);
> 	return (OK);
> }
> /***********************************************************************/
> #ifdef HAVE_PROTO
> int	PDC_CDECL	PDC_wunderline(WINDOW *win, int n, bool state)
> #else
> int	PDC_CDECL	PDC_wunderline(win,n,state)
> WINDOW *win;
> int n;
> bool state;
> #endif
> /***********************************************************************/
> {
> 	int	endpos;
> 
> #ifdef PDCDEBUG
> 	if (trace_on) PDC_debug("PDC_wunderline() - called\n");
> #endif
> 
> 	if (win == (WINDOW *)NULL)
> 		return( ERR );
> 
> 	if (n < 1)
> 		return( ERR );
> 
> 	endpos = min(win->_cury + n -1, win->_maxy);
> 
> 	for (n = win->_cury; n <= endpos; n++)
> 	{
> 		if ( state ) 
> 			win->_y[n][win->_curx] |= A_UNDERLINE; /* Turn ON A_UNDERLINE */
> 		else
> 			win->_y[n][win->_curx] |= ~A_UNDERLINE; /* Turn OFF A_UNDERLINE */
> 
> 		if (win->_firstch[n] == _NO_CHANGE)
> 		{
> 			win->_firstch[n] = win->_curx;
> 			win->_lastch[n] = win->_curx;
> 		}
> 		else
> 		{
> 			win->_firstch[n] = min(win->_firstch[n], win->_curx);
> 			win->_lastch[n] = max(win->_lastch[n], win->_curx);
> 		}
> 	}
> 
> 	PDC_sync(win);
> 	return (OK);
> }
> /***********************************************************************/
> #ifdef HAVE_PROTO
> int	PDC_CDECL	PDC_wleftline(WINDOW *win, int n, bool state)
> #else
> int	PDC_CDECL	PDC_wleftline(win,n,state)
> WINDOW *win;
> int n;
> bool state;
> #endif
> /***********************************************************************/
> {
> 	int	endpos;
> 
> #ifdef PDCDEBUG
> 	if (trace_on) PDC_debug("PDC_wleftline() - called\n");
> #endif
> 
> 	if (win == (WINDOW *)NULL)
> 		return( ERR );
> 
> 	if (n < 1)
> 		return( ERR );
> 
> 	endpos = min(win->_cury + n -1, win->_maxy);
> 
> 	for (n = win->_cury; n <= endpos; n++)
> 	{
> 		if ( state ) 
> 			win->_y[n][win->_curx] |= A_LEFTLINE; /* Turn ON A_LEFTLINE */
> 		else
> 			win->_y[n][win->_curx] |= ~A_LEFTLINE; /* Turn OFF A_LEFTLINE */
> 
> 		if (win->_firstch[n] == _NO_CHANGE)
> 		{
> 			win->_firstch[n] = win->_curx;
> 			win->_lastch[n] = win->_curx;
> 		}
> 		else
> 		{
> 			win->_firstch[n] = min(win->_firstch[n], win->_curx);
> 			win->_lastch[n] = max(win->_lastch[n], win->_curx);
> 		}
> 	}
> 
> 	PDC_sync(win);
> 	return (OK);
> }
> /***********************************************************************/
> #ifdef HAVE_PROTO
> int	PDC_CDECL	PDC_wrightline(WINDOW *win, int n, bool state)
> #else
> int	PDC_CDECL	PDC_wrightline(win,n,state)
> WINDOW *win;
> int n;
> bool state;
> #endif
> /***********************************************************************/
> {
> 	int	endpos;
> 
> #ifdef PDCDEBUG
> 	if (trace_on) PDC_debug("PDC_wrightline() - called\n");
> #endif
> 
> 	if (win == (WINDOW *)NULL)
> 		return( ERR );
> 
> 	if (n < 1)
> 		return( ERR );
> 
> 	endpos = min(win->_cury + n -1, win->_maxy);
> 
> 	for (n = win->_cury; n <= endpos; n++)
> 	{
> 		if ( state ) 
> 			win->_y[n][win->_curx] |= A_RIGHTLINE; /* Turn ON A_RIGHTLINE */
> 		else
> 			win->_y[n][win->_curx] |= ~A_RIGHTLINE; /* Turn OFF A_RIGHTLINE */

Index: PDCurses/pdcurses/color.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/color.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
38a39
> #undef	PDC_set_line_color
51c52
< char *rcsid_color  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_color  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
65a67
>   	int PDC_set_line_color(short color);
101a104,107
>  	PDC_set_line_color() is used to set the color, globally, for the
>  	color of the lines drawn for the attributes: A_UNDERLINE, A_OVERLINE, 
>  	A_LEFTLINE and A_RIGHTLINE.  PDCurses only feature.
> 
111c117
<   Portability                             X/Open    BSD    SYS V
---
>   Portability                             X/Open    BSD    SYS V   PDCurses
119a126
>       PDC_set_line_color                    -        -       -       Y
349a357,371
>  return(OK);
> }
> /***********************************************************************/
> #ifdef HAVE_PROTO
> int	PDC_CDECL	PDC_set_line_color(short color)
> #else
> int	PDC_CDECL	PDC_set_line_color(color)
> short color;
> #endif
> /***********************************************************************/
> {
> 
>  if (color >= COLORS || color < 0)
>     return(ERR);
>  SP->line_color = color;

Index: PDCurses/pdcurses/getch.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/getch.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
42c42
< char *rcsid_getch  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_getch  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
163c163
< 	int waitingtenths = SP->delaytenths;
---
> 	int waitingtenths = 0;
171a172,174
> 	if ( SP->delaytenths )
> 		waitingtenths = 10*SP->delaytenths;
> 
282c285,286
< 					napms(100);
---
> 					napms(10);
> 					continue;
304c308
< 		if (SP->raw_inp || SP->cbreak)
---
> 		if ( (SP->raw_inp || SP->cbreak) )

Index: PDCurses/pdcurses/initscr.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/initscr.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
64c64
< char *rcsid_initscr  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_initscr  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
324,325c324,325
< ACS_SBSS = (chtype)21|A_ALTCHARSET;
< ACS_SSSB = (chtype)22|A_ALTCHARSET;
---
> ACS_SBSS = (chtype)22|A_ALTCHARSET;
> ACS_SSSB = (chtype)21|A_ALTCHARSET;

Index: PDCurses/pdcurses/util.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/pdcurses/util.c,v
retrieving revision 1.1
retrieving revision 1.3
diff -b -w -r1.1 -r1.3
68c68
< char *rcsid_util  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_util  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
237c237
<  "KEY_RESIZE"
---
>  "KEY_RESIZE", "KEY_SUP", "KEY_SDOWN"
352c352
< 		(void)XCurses_rawgetch();
---
> 		(void)XCurses_rawgetch(0);

Index: PDCurses/win32/curses.def
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/win32/curses.def,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
2a3,5
> ; used for Win32 port as well as AIX port
> ; each entry point MUST be on a seperate line prefixed
> ; by EXPORTS in column 1

Index: PDCurses/win32/pdckbd.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/win32/pdckbd.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
28c28
< char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
318c318
<  {KEY_UP,     SHF_UP,         CTL_UP,      ALT_UP      }, /* 38 */
---
>  {KEY_UP,     KEY_SUP,        CTL_UP,      ALT_UP      }, /* 38 */
320,322c320,322
<  {KEY_DOWN,   SHF_DOWN,       CTL_DOWN,    ALT_DOWN    }, /* 40 */
<  {KEY_IC,     SHF_IC,         CTL_INS,     ALT_INS     }, /* 45 */
<  {KEY_DC,     SHF_DC,         CTL_DEL,     ALT_DEL     }, /* 46 */
---
>  {KEY_DOWN,   KEY_SDOWN,      CTL_DOWN,    ALT_DOWN    }, /* 40 */
>  {KEY_IC,     KEY_SIC,        CTL_INS,     ALT_INS     }, /* 45 */
>  {KEY_DC,     KEY_SDC,        CTL_DEL,     ALT_DEL     }, /* 46 */

Index: PDCurses/x11/README
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/README,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
12c12
<  The files in this directory are copyright Mark Hessling 1995-1999.
---
>  The files in this directory are copyright Mark Hessling 1995-2000.
26a27,39
> 
> Structure
> ---------
> 
> x11.c           - contains functions that are X11 specific functions that are
>                   used by both the process and thread implementations
> x11.h           - #defines and includes for the X11 process/thread
> x11_proc.c      - contains functions that are used by the X11 (child) process
>                   in the process implementation
> curses_proc.c   - contains functions that are used by the curses (parent)
>                   process in the process implementation
> x11_thread.c    -
> curses_thread.c -

Index: PDCurses/x11/ScrollBox.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/ScrollBox.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
124c124
< 	Widget main, vscroll, hscroll;
---
> 	Widget wmain, vscroll, hscroll;
130a131
> #if 0
132a134
> #endif
151c153
< 	main = sbw->composite.children[0];
---
> 	wmain = sbw->composite.children[0];
161c163
< 		(2 * main->core.border_width);
---
> 		(2 * wmain->core.border_width);
165c167
< 		(2 * main->core.border_width);
---
> 		(2 * wmain->core.border_width);
167c169
< 	vx = main->core.x + mw + sbw->scrollBox.h_space + main->core.border_width + vscroll->core.border_width; 
---
> 	vx = wmain->core.x + mw + sbw->scrollBox.h_space + wmain->core.border_width + vscroll->core.border_width; 
169c171
< 	hy = main->core.y + mh + sbw->scrollBox.v_space + main->core.border_width + hscroll->core.border_width; 
---
> 	hy = wmain->core.y + mh + sbw->scrollBox.v_space + wmain->core.border_width + hscroll->core.border_width; 
175c177
< 		XtResizeWidget(main, mw, mh, 1);
---
> 		XtResizeWidget(wmain, mw, mh, 1);
177c179
< 	tw = main->core.width + (2 * sbw->scrollBox.h_space) +
---
> 	tw = wmain->core.width + (2 * sbw->scrollBox.h_space) +
179c181
< 		(2 * main->core.border_width);
---
> 		(2 * wmain->core.border_width);
181c183
< 	th = main->core.height + (2 * sbw->scrollBox.v_space) +
---
> 	th = wmain->core.height + (2 * sbw->scrollBox.v_space) +
183c185
< 		(2 * main->core.border_width);
---
> 		(2 * wmain->core.border_width);
185,186c187,188
< 	hw = mw = main->core.width;
< 	vh = mh = main->core.height;
---
> 	hw = mw = wmain->core.width;
> 	vh = mh = wmain->core.height;
188c190
< 	vx = main->core.x + mw + sbw->scrollBox.h_space + main->core.border_width + vscroll->core.border_width; 
---
> 	vx = wmain->core.x + mw + sbw->scrollBox.h_space + wmain->core.border_width + vscroll->core.border_width; 
190c192
< 	hy = main->core.y + mh + sbw->scrollBox.v_space + main->core.border_width + hscroll->core.border_width; 
---
> 	hy = wmain->core.y + mh + sbw->scrollBox.v_space + wmain->core.border_width + hscroll->core.border_width; 

Index: PDCurses/x11/pdcdisp.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/pdcdisp.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
37c37
< char *rcsid_PDCdisp  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCdisp  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
201c201
< 	XCurses_display_cursor(SP->cursrow,SP->curscol,row,col);
---
> 	XCurses_display_cursor(SP->cursrow,SP->curscol,row,col,SP->visibility);

Index: PDCurses/x11/pdckbd.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/pdckbd.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
28c28
< char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCkbd  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
243c243
< 	c = XCurses_rawgetch();
---
> 	c = XCurses_rawgetch( SP->delaytenths );

Index: PDCurses/x11/pdcscrn.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/pdcscrn.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
27c27
< char *rcsid_PDCscrn  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCscrn  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
179a180
> 	internal->line_color = COLOR_WHITE;

Index: PDCurses/x11/pdcsetsc.c
===================================================================
RCS file: /usr/local/cvsroot/PDCurses/x11/pdcsetsc.c,v
retrieving revision 1.1
retrieving revision 1.2
diff -b -w -r1.1 -r1.2
27c27
< char *rcsid_PDCsetsc  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
---
> char *rcsid_PDCsetsc  = "@Id: case16.pat,v 1.1 2001/04/22 23:30:04 tom Exp @";
123c123
<  int ret_vis;
---
>    int ret_vis = SP->visibility;
129c129,130
< 	ret_vis = SP->visibility;
---
>    if ( visibility != -1 )
>    {
131,132c132,133
< 
< 	XCurses_display_cursor(SP->cursrow,SP->curscol,SP->cursrow,SP->curscol);
---
>    }
>    XCurses_display_cursor(SP->cursrow,SP->curscol,SP->cursrow,SP->curscol,visibility);
