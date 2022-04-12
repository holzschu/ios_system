diff -r -c diffstat/config.cache diffstat.orig/config.cache
*** 1.1				Fri Mar 15 19:27:13 1996
--- diffstat.orig/config.cache	Fri Mar 15 19:51:02 1996
***************
*** 13,28 ****
  # --recheck option to rerun configure.
  #
  ac_cv_c_const=${ac_cv_c_const='yes'}
! ac_cv_c_cross=${ac_cv_c_cross='yes'}
  ac_cv_header_getopt_h=${ac_cv_header_getopt_h='yes'}
  ac_cv_header_malloc_h=${ac_cv_header_malloc_h='yes'}
--- 13,28 ----
  # --recheck option to rerun configure.
  #
  ac_cv_c_const=${ac_cv_c_const='yes'}
  ac_cv_header_getopt_h=${ac_cv_header_getopt_h='yes'}
  ac_cv_header_malloc_h=${ac_cv_header_malloc_h='yes'}
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
Only in diffstat.orig: configure.out
Binary files diffstat/diffstat and diffstat.orig/diffstat differ
< nothing
> nothing again
Binary files diffstat/diffstat.o and diffstat.orig/diffstat.o differ
