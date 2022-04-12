diff -r -c diffstat/config.cache diffstat.orig/config.cache
*** diffstat/config.cache	Fri Mar 15 19:27:13 1996
--- diffstat.orig/config.cache	Fri Mar 15 19:51:02 1996
***************
*** 13,28 ****
  # --recheck option to rerun configure.
  #
  ac_cv_c_const=${ac_cv_c_const='yes'}
! ac_cv_c_cross=${ac_cv_c_cross='yes'}
  ac_cv_header_getopt_h=${ac_cv_header_getopt_h='yes'}
  ac_cv_header_malloc_h=${ac_cv_header_malloc_h='yes'}
! ac_cv_header_stdc=${ac_cv_header_stdc='no'}
  ac_cv_header_stdlib_h=${ac_cv_header_stdlib_h='yes'}
  ac_cv_header_string_h=${ac_cv_header_string_h='yes'}
  ac_cv_header_unistd_h=${ac_cv_header_unistd_h='yes'}
  ac_cv_path_install=${ac_cv_path_install='/home/tom/com/install -c'}
! ac_cv_prog_CC=${ac_cv_prog_CC='atacCC'}
! ac_cv_prog_CPP=${ac_cv_prog_CPP='atacCC -E'}
  ac_cv_prog_gcc=${ac_cv_prog_gcc='yes'}
  ac_cv_prog_gcc_g=${ac_cv_prog_gcc_g='yes'}
  ac_cv_prog_gcc_traditional=${ac_cv_prog_gcc_traditional='no'}
--- 13,28 ----
  # --recheck option to rerun configure.
  #
  ac_cv_c_const=${ac_cv_c_const='yes'}
! ac_cv_c_cross=${ac_cv_c_cross='no'}
  ac_cv_header_getopt_h=${ac_cv_header_getopt_h='yes'}
  ac_cv_header_malloc_h=${ac_cv_header_malloc_h='yes'}
! ac_cv_header_stdc=${ac_cv_header_stdc='yes'}
  ac_cv_header_stdlib_h=${ac_cv_header_stdlib_h='yes'}
  ac_cv_header_string_h=${ac_cv_header_string_h='yes'}
  ac_cv_header_unistd_h=${ac_cv_header_unistd_h='yes'}
  ac_cv_path_install=${ac_cv_path_install='/home/tom/com/install -c'}
! ac_cv_prog_CC=${ac_cv_prog_CC='gcc'}
! ac_cv_prog_CPP=${ac_cv_prog_CPP='gcc -E'}
  ac_cv_prog_gcc=${ac_cv_prog_gcc='yes'}
  ac_cv_prog_gcc_g=${ac_cv_prog_gcc_g='yes'}
  ac_cv_prog_gcc_traditional=${ac_cv_prog_gcc_traditional='no'}
diff -r -c diffstat/config.h diffstat.orig/config.h
*** diffstat/config.h	Fri Mar 15 19:27:15 1996
--- diffstat.orig/config.h	Fri Mar 15 19:51:04 1996
***************
*** 6,11 ****
--- 6,12 ----
   */
  
  
+ #define STDC_HEADERS	1
  #define HAVE_STDLIB_H	1
  #define HAVE_UNISTD_H	1
  #define HAVE_GETOPT_H	1
diff -r -c diffstat/config.log diffstat.orig/config.log
*** diffstat/config.log	Fri Mar 15 19:26:59 1996
--- diffstat.orig/config.log	Fri Mar 15 19:50:58 1996
***************
*** 2,27 ****
  running configure, to aid debugging if configure makes a mistake.
  
  configure:607: sgtty.h: No such file or directory
! /usr/tmp/atacCC17934/conftest.c:30: warning: missing braces around initializer for `ZUmain[0]'
! /usr/tmp/atacCC17934/conftest.c:66: warning: function declaration isn't a prototype
! /usr/tmp/atacCC17934/conftest.c: In function `main':
! /usr/tmp/atacCC17934/conftest.c:67: warning: implicit declaration of function `aTaC'
! /usr/tmp/atacCC17934/conftest.c: At top level:
! /usr/tmp/atacCC17934/conftest.c:76: warning: function declaration isn't a prototype
! /usr/tmp/atacCC17934/conftest.c: In function `t':
! /usr/tmp/atacCC17934/conftest.c:97: warning: declaration of `t' shadows global declaration
! /usr/tmp/atacCC17934/conftest.c:98: warning: unused variable `s'
! /usr/tmp/atacCC17934/conftest.c:104: warning: declaration of `x' shadows previous local
! /usr/tmp/atacCC17934/conftest.c:111: warning: declaration of `p' shadows previous local
! /usr/tmp/atacCC17934/conftest.c:125: warning: unused variable `foo'
! /usr/tmp/atacCC17934/conftest.c:86: warning: unused variable `zero'
! /usr/tmp/atacCC17934/conftest.c:80: warning: unused variable `x'
! /usr/tmp/atacCC17934/conftest.c: At top level:
! /usr/tmp/atacCC17934/conftest.c:1: warning: `ZIDENT' defined but not used
! /usr/tmp/atacCC17972/conftest.c:30: warning: missing braces around initializer for `ZUmain[0]'
! /usr/tmp/atacCC17972/conftest.c:39: warning: return-type defaults to `int'
! /usr/tmp/atacCC17972/conftest.c:39: warning: function declaration isn't a prototype
! /usr/tmp/atacCC17972/conftest.c: In function `main':
! /usr/tmp/atacCC17972/conftest.c:40: warning: implicit declaration of function `aTaC'
! /usr/tmp/atacCC17972/conftest.c: At top level:
! /usr/tmp/atacCC17972/conftest.c:1: warning: `ZIDENT' defined but not used
--- 2,19 ----
  running configure, to aid debugging if configure makes a mistake.
  
  configure:607: sgtty.h: No such file or directory
! configure:659: warning: function declaration isn't a prototype
! configure:660: warning: function declaration isn't a prototype
! configure: In function `t':
! configure:680: warning: declaration of `t' shadows global declaration
! configure:681: warning: unused variable `s'
! configure:686: warning: declaration of `x' shadows previous local
! configure:692: warning: declaration of `p' shadows previous local
! configure:701: warning: unused variable `foo'
! configure:669: warning: unused variable `zero'
! configure:663: warning: unused variable `x'
! configure:680: warning: `t' might be used uninitialized in this function
! configure:698: warning: `b' might be used uninitialized in this function
! configure:735: warning: return-type defaults to `int'
! configure:735: warning: function declaration isn't a prototype
! configure:821: warning: function declaration isn't a prototype
diff -r -c diffstat/config.status diffstat.orig/config.status
*** diffstat/config.status	Fri Mar 15 19:27:14 1996
--- diffstat.orig/config.status	Fri Mar 15 19:51:03 1996
***************
*** 4,10 ****
  # This directory was configured as follows,
  # on host dickey-ppp:
  #
! # ./configure 
  #
  # Compiler output produced by configure, useful for debugging
  # configure, is in ./config.log if it exists.
--- 4,10 ----
  # This directory was configured as follows,
  # on host dickey-ppp:
  #
! # ./configure  --verbose --disable-echo --enable-warnings --with-warnings
  #
  # Compiler output produced by configure, useful for debugging
  # configure, is in ./config.log if it exists.
***************
*** 14,21 ****
  do
    case "$ac_option" in
    -recheck | --recheck | --rechec | --reche | --rech | --rec | --re | --r)
!     echo "running ${CONFIG_SHELL-/bin/sh} ./configure  --no-create --no-recursion"
!     exec ${CONFIG_SHELL-/bin/sh} ./configure  --no-create --no-recursion ;;
    -version | --version | --versio | --versi | --vers | --ver | --ve | --v)
      echo "./config.status generated by autoconf version 2.3"
      exit 0 ;;
--- 14,21 ----
  do
    case "$ac_option" in
    -recheck | --recheck | --rechec | --reche | --rech | --rec | --re | --r)
!     echo "running ${CONFIG_SHELL-/bin/sh} ./configure  --verbose --disable-echo --enable-warnings --with-warnings --no-create --no-recursion"
!     exec ${CONFIG_SHELL-/bin/sh} ./configure  --verbose --disable-echo --enable-warnings --with-warnings --no-create --no-recursion ;;
    -version | --version | --versio | --versi | --vers | --ver | --ve | --v)
      echo "./config.status generated by autoconf version 2.3"
      exit 0 ;;
***************
*** 38,53 ****
  s%@CFLAGS@%-O -Wall -Wshadow -Wconversion -Wstrict-prototypes -Wmissing-prototypes%g
  s%@CPPFLAGS@%%g
  s%@CXXFLAGS@%%g
! s%@DEFS@% -DHAVE_STDLIB_H=1 -DHAVE_UNISTD_H=1 -DHAVE_GETOPT_H=1 -DHAVE_STRING_H=1 -DHAVE_MALLOC_H=1 %g
  s%@LDFLAGS@%%g
  s%@LIBS@%%g
  s%@exec_prefix@%${prefix}%g
  s%@prefix@%/usr/local%g
  s%@program_transform_name@%s,x,x,%g
! s%@CC@%atacCC%g
  s%@INSTALL_PROGRAM@%${INSTALL}%g
  s%@INSTALL_DATA@%${INSTALL} -m 644%g
! s%@CPP@%atacCC -E%g
  
  CEOF
  
--- 38,53 ----
  s%@CFLAGS@%-O -Wall -Wshadow -Wconversion -Wstrict-prototypes -Wmissing-prototypes%g
  s%@CPPFLAGS@%%g
  s%@CXXFLAGS@%%g
! s%@DEFS@% -DSTDC_HEADERS=1 -DHAVE_STDLIB_H=1 -DHAVE_UNISTD_H=1 -DHAVE_GETOPT_H=1 -DHAVE_STRING_H=1 -DHAVE_MALLOC_H=1 %g
  s%@LDFLAGS@%%g
  s%@LIBS@%%g
  s%@exec_prefix@%${prefix}%g
  s%@prefix@%/usr/local%g
  s%@program_transform_name@%s,x,x,%g
! s%@CC@%gcc%g
  s%@INSTALL_PROGRAM@%${INSTALL}%g
  s%@INSTALL_DATA@%${INSTALL} -m 644%g
! s%@CPP@%gcc -E%g
  
  CEOF
  
Only in diffstat.orig: configure.out
Binary files diffstat/diffstat and diffstat.orig/diffstat differ
Binary files diffstat/diffstat.o and diffstat.orig/diffstat.o differ
diff -r -c diffstat/makefile diffstat.orig/makefile
*** diffstat/makefile	Fri Mar 15 19:27:15 1996
--- diffstat.orig/makefile	Fri Mar 15 19:51:04 1996
***************
*** 7,13 ****
  
  srcdir = .
  
! CC		= atacCC
  LINK		= $(CC)
  INSTALL		= /home/tom/com/install -c
  INSTALL_PROGRAM	= ${INSTALL}
--- 7,13 ----
  
  srcdir = .
  
! CC		= gcc
  LINK		= $(CC)
  INSTALL		= /home/tom/com/install -c
  INSTALL_PROGRAM	= ${INSTALL}
Only in diffstat/testing: Xlib-1.patch-
Only in diffstat/testing: Xlib-1.ref
Only in diffstat/testing: Xlib-2.patch-
Only in diffstat/testing: Xlib-2.ref
Only in diffstat/testing: Xlib-3.patch-
Only in diffstat/testing: Xlib-3.ref
Only in diffstat/testing: config-1.ref
Only in diffstat/testing: nugent.ref
Only in diffstat/testing: xserver-1.ref
Only in diffstat/testing: xserver-2.patch-
Only in diffstat/testing: xserver-2.ref
Only in diffstat/testing: xterm-1.patch-
Only in diffstat/testing: xterm-1.ref
Only in diffstat/testing: xterm-10.patch-
Only in diffstat/testing: xterm-10.ref
Only in diffstat/testing: xterm-11.patch-
Only in diffstat/testing: xterm-11.ref
Only in diffstat/testing: xterm-2.patch-
Only in diffstat/testing: xterm-2.ref
Only in diffstat/testing: xterm-3.patch-
Only in diffstat/testing: xterm-3.ref
Only in diffstat/testing: xterm-4.patch-
Only in diffstat/testing: xterm-4.ref
Only in diffstat/testing: xterm-5.patch-
Only in diffstat/testing: xterm-5.ref
Only in diffstat/testing: xterm-6.patch-
Only in diffstat/testing: xterm-6.ref
Only in diffstat/testing: xterm-7.ref
Only in diffstat/testing: xterm-8.patch-
Only in diffstat/testing: xterm-8.ref
Only in diffstat/testing: xterm-9.patch-
Only in diffstat/testing: xterm-9.ref
diff -r diffstat/config.cache diffstat.orig/config.cache
16c16
< ac_cv_c_cross=${ac_cv_c_cross='yes'}
---
> ac_cv_c_cross=${ac_cv_c_cross='no'}
19c19
< ac_cv_header_stdc=${ac_cv_header_stdc='no'}
---
> ac_cv_header_stdc=${ac_cv_header_stdc='yes'}
24,25c24,25
< ac_cv_prog_CC=${ac_cv_prog_CC='atacCC'}
< ac_cv_prog_CPP=${ac_cv_prog_CPP='atacCC -E'}
---
> ac_cv_prog_CC=${ac_cv_prog_CC='gcc'}
> ac_cv_prog_CPP=${ac_cv_prog_CPP='gcc -E'}
diff -r diffstat/config.h diffstat.orig/config.h
8a9
> #define STDC_HEADERS	1
diff -r diffstat/config.log diffstat.orig/config.log
5,27c5,19
< /usr/tmp/atacCC17934/conftest.c:30: warning: missing braces around initializer for `ZUmain[0]'
< /usr/tmp/atacCC17934/conftest.c:66: warning: function declaration isn't a prototype
< /usr/tmp/atacCC17934/conftest.c: In function `main':
< /usr/tmp/atacCC17934/conftest.c:67: warning: implicit declaration of function `aTaC'
< /usr/tmp/atacCC17934/conftest.c: At top level:
< /usr/tmp/atacCC17934/conftest.c:76: warning: function declaration isn't a prototype
< /usr/tmp/atacCC17934/conftest.c: In function `t':
< /usr/tmp/atacCC17934/conftest.c:97: warning: declaration of `t' shadows global declaration
< /usr/tmp/atacCC17934/conftest.c:98: warning: unused variable `s'
< /usr/tmp/atacCC17934/conftest.c:104: warning: declaration of `x' shadows previous local
< /usr/tmp/atacCC17934/conftest.c:111: warning: declaration of `p' shadows previous local
< /usr/tmp/atacCC17934/conftest.c:125: warning: unused variable `foo'
< /usr/tmp/atacCC17934/conftest.c:86: warning: unused variable `zero'
< /usr/tmp/atacCC17934/conftest.c:80: warning: unused variable `x'
< /usr/tmp/atacCC17934/conftest.c: At top level:
< /usr/tmp/atacCC17934/conftest.c:1: warning: `ZIDENT' defined but not used
< /usr/tmp/atacCC17972/conftest.c:30: warning: missing braces around initializer for `ZUmain[0]'
< /usr/tmp/atacCC17972/conftest.c:39: warning: return-type defaults to `int'
< /usr/tmp/atacCC17972/conftest.c:39: warning: function declaration isn't a prototype
< /usr/tmp/atacCC17972/conftest.c: In function `main':
< /usr/tmp/atacCC17972/conftest.c:40: warning: implicit declaration of function `aTaC'
< /usr/tmp/atacCC17972/conftest.c: At top level:
< /usr/tmp/atacCC17972/conftest.c:1: warning: `ZIDENT' defined but not used
---
> configure:659: warning: function declaration isn't a prototype
> configure:660: warning: function declaration isn't a prototype
> configure: In function `t':
> configure:680: warning: declaration of `t' shadows global declaration
> configure:681: warning: unused variable `s'
> configure:686: warning: declaration of `x' shadows previous local
> configure:692: warning: declaration of `p' shadows previous local
> configure:701: warning: unused variable `foo'
> configure:669: warning: unused variable `zero'
> configure:663: warning: unused variable `x'
> configure:680: warning: `t' might be used uninitialized in this function
> configure:698: warning: `b' might be used uninitialized in this function
> configure:735: warning: return-type defaults to `int'
> configure:735: warning: function declaration isn't a prototype
> configure:821: warning: function declaration isn't a prototype
diff -r diffstat/config.status diffstat.orig/config.status
7c7
< # ./configure 
---
> # ./configure  --verbose --disable-echo --enable-warnings --with-warnings
17,18c17,18
<     echo "running ${CONFIG_SHELL-/bin/sh} ./configure  --no-create --no-recursion"
<     exec ${CONFIG_SHELL-/bin/sh} ./configure  --no-create --no-recursion ;;
---
>     echo "running ${CONFIG_SHELL-/bin/sh} ./configure  --verbose --disable-echo --enable-warnings --with-warnings --no-create --no-recursion"
>     exec ${CONFIG_SHELL-/bin/sh} ./configure  --verbose --disable-echo --enable-warnings --with-warnings --no-create --no-recursion ;;
41c41
< s%@DEFS@% -DHAVE_STDLIB_H=1 -DHAVE_UNISTD_H=1 -DHAVE_GETOPT_H=1 -DHAVE_STRING_H=1 -DHAVE_MALLOC_H=1 %g
---
> s%@DEFS@% -DSTDC_HEADERS=1 -DHAVE_STDLIB_H=1 -DHAVE_UNISTD_H=1 -DHAVE_GETOPT_H=1 -DHAVE_STRING_H=1 -DHAVE_MALLOC_H=1 %g
47c47
< s%@CC@%atacCC%g
---
> s%@CC@%gcc%g
50c50
< s%@CPP@%atacCC -E%g
---
> s%@CPP@%gcc -E%g
Only in diffstat.orig: configure.out
Binary files diffstat/diffstat and diffstat.orig/diffstat differ
Binary files diffstat/diffstat.o and diffstat.orig/diffstat.o differ
diff -r diffstat/makefile diffstat.orig/makefile
10c10
< CC		= atacCC
---
> CC		= gcc
Only in diffstat/testing: Xlib-1.patch-
Only in diffstat/testing: Xlib-1.ref
Only in diffstat/testing: Xlib-2.patch-
Only in diffstat/testing: Xlib-2.ref
Only in diffstat/testing: Xlib-3.patch-
Only in diffstat/testing: Xlib-3.ref
Only in diffstat/testing: config-1.ref
Only in diffstat/testing: nugent.ref
Only in diffstat/testing: xserver-1.ref
Only in diffstat/testing: xserver-2.patch-
Only in diffstat/testing: xserver-2.ref
Only in diffstat/testing: xterm-1.patch-
Only in diffstat/testing: xterm-1.ref
Only in diffstat/testing: xterm-10.patch-
Only in diffstat/testing: xterm-10.ref
Only in diffstat/testing: xterm-11.patch-
Only in diffstat/testing: xterm-11.ref
Only in diffstat/testing: xterm-2.patch-
Only in diffstat/testing: xterm-2.ref
Only in diffstat/testing: xterm-3.patch-
Only in diffstat/testing: xterm-3.ref
Only in diffstat/testing: xterm-4.patch-
Only in diffstat/testing: xterm-4.ref
Only in diffstat/testing: xterm-5.patch-
Only in diffstat/testing: xterm-5.ref
Only in diffstat/testing: xterm-6.patch-
Only in diffstat/testing: xterm-6.ref
Only in diffstat/testing: xterm-7.ref
Only in diffstat/testing: xterm-8.patch-
Only in diffstat/testing: xterm-8.ref
Only in diffstat/testing: xterm-9.patch-
Only in diffstat/testing: xterm-9.ref
