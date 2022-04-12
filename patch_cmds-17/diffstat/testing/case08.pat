Index: Imakefile
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/Imakefile	Fri Jan 26 11:43:22 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/Imakefile	Sun Jan 28 20:45:35 1996
***************
*** 10,15 ****
--- 10,30 ----
  XCOMM
  
  /*
+  * Fixes to allow compile with X11R5
+  */
+ #ifndef XkbClientDefines
+ #define XkbClientDefines /**/
+ #endif
+ 
+ #ifndef XkbClientDepLibs
+ #define XkbClientDepLibs /**/
+ #endif
+ 
+ #ifndef XkbClientLibs
+ #define XkbClientLibs /**/
+ #endif
+ 
+ /*
   * add -DWTMP and -DLASTLOG if you want them; make sure that bcopy can
   * handle overlapping copies before using it.
   */
Index: Tekproc.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/Tekproc.c	Tue Jan 16 15:43:01 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/Tekproc.c	Sun Jan 28 20:45:35 1996
***************
*** 64,70 ****
--- 64,77 ----
  #include <X11/StringDefs.h>
  #include <X11/Shell.h>
  #include <X11/Xmu/CharSet.h>
+ 
+ #if XtSpecificationRelease >= 6
  #include <X11/Xpoll.h>
+ #else
+ #define Select(n,r,w,e,t) select(0,(fd_set*)r,(fd_set*)w,(fd_set*)e,(struct timeval *)t)
+ #define XFD_COPYSET(src,dst) bcopy((src)->fds_bits, (dst)->fds_bits, sizeof(fd_set))
+ #endif
+ 
  #include <stdio.h>
  #include <errno.h>
  #include <setjmp.h>
Index: charproc.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/charproc.c	Fri Jan 26 11:43:22 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/charproc.c	Sun Jan 28 20:45:35 1996
***************
*** 63,70 ****
--- 63,77 ----
  #include <X11/Xmu/Atoms.h>
  #include <X11/Xmu/CharSet.h>
  #include <X11/Xmu/Converters.h>
+ 
+ #if XtSpecificationRelease >= 6
  #include <X11/Xaw/XawImP.h>
  #include <X11/Xpoll.h>
+ #else
+ #define Select(n,r,w,e,t) select(0,(fd_set*)r,(fd_set*)w,(fd_set*)e,(struct timeval *)t)
+ #define XFD_COPYSET(src,dst) bcopy((src)->fds_bits, (dst)->fds_bits, sizeof(fd_set))
+ #endif
+ 
  #include <stdio.h>
  #include <errno.h>
  #include <setjmp.h>
***************
*** 572,577 ****
--- 579,585 ----
  {"font6", "Font6", XtRString, sizeof(String),
  	XtOffsetOf(XtermWidgetRec, screen.menu_font_names[fontMenu_font6]),
  	XtRString, (XtPointer) NULL},
+ #if XtSpecificationRelease >= 6
  {XtNinputMethod, XtCInputMethod, XtRString, sizeof(char*),
  	XtOffsetOf(XtermWidgetRec, misc.input_method),
  	XtRString, (XtPointer)NULL},
***************
*** 581,586 ****
--- 589,595 ----
  {XtNopenIm, XtCOpenIm, XtRBoolean, sizeof(Boolean),
  	XtOffsetOf(XtermWidgetRec, misc.open_im),
  	XtRImmediate, (XtPointer)TRUE},
+ #endif
  {XtNcolor0, XtCForeground, XtRPixel, sizeof(Pixel),
  	XtOffsetOf(XtermWidgetRec, screen.colors[COLOR_0]),
  	XtRString, "XtDefaultForeground"},
***************
*** 1153,1158 ****
--- 1162,1172 ----
  						  ? 8 : 0));
  					}
  					break;
+ 				 case 39:
+ 					if( screen->colorMode ) {
+ 					  SGR_Foreground(-1);
+ 					}
+ 					break;
  				 case 40:
  				 case 41:
  				 case 42:
***************
*** 1165,1170 ****
--- 1179,1189 ----
  					  SGR_Background(param[row] - 40);
  					}
  					break;
+ 				 case 49:
+ 					if( screen->colorMode ) {
+ 					  SGR_Background(-1);
+ 					}
+ 					break;
  				 case 100:
  					if( screen->colorMode ) {
  					  if (term->flags & FG_COLOR)
***************
*** 2639,2644 ****
--- 2658,2666 ----
     for (i = 0; i < MAXCOLORS; i++) {
         new->screen.colors[i] = request->screen.colors[i];
     }
+ 
+    new->cur_foreground = 0;
+    new->cur_background = 0;
  
      /*
       * The definition of -rv now is that it changes the definition of 
Index: data.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/data.c	Sat Jan  6 08:11:01 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/data.c	Sun Jan 28 20:45:35 1996
***************
*** 26,32 ****
--- 26,36 ----
   */
  
  #include "ptyx.h"		/* gets Xt stuff, too */
+ 
+ #if XtSpecificationRelease >= 6
  #include <X11/Xpoll.h>
+ #endif
+ 
  #include "data.h"
  #include <setjmp.h>
  
Index: main.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/main.c	Thu Jan 11 14:01:01 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/main.c	Sun Jan 28 20:45:35 1996
***************
*** 75,82 ****
--- 75,87 ----
  #include <X11/Xos.h>
  #include <X11/cursorfont.h>
  #include <X11/Xaw/SimpleMenu.h>
+ 
+ #if XtSpecificationRelease >= 6
  #include <X11/Xpoll.h>
+ #endif
+ 
  #include <X11/Xlocale.h>
+ 
  #include <pwd.h>
  #include <ctype.h>
  #include "data.h"
***************
*** 127,132 ****
--- 132,138 ----
  #endif
  
  #ifdef SVR4
+ #undef  SYSV			/* predefined on Solaris 2.4 */
  #define SYSV			/* SVR4 is (approx) superset of SVR3 */
  #define ATT
  #define USE_SYSV_UTMP
***************
*** 453,459 ****
  #endif
  
  #ifdef SYSV
! extern char *ptsname();
  #endif
  
  #include "xterm.h"
--- 459,465 ----
  #endif
  
  #ifdef SYSV
! extern char *ptsname PROTO((int));
  #endif
  
  #include "xterm.h"
***************
*** 1293,1303 ****
  
  	    if (setegid(rgid) == -1)
  		(void) fprintf(stderr, "setegid(%d): %s\n",
! 			       rgid, strerror(errno));
  
  	    if (seteuid(ruid) == -1)
  		(void) fprintf(stderr, "seteuid(%d): %s\n",
! 			       ruid, strerror(errno));
  #endif
  
  	    XtSetErrorHandler(xt_error);
--- 1299,1309 ----
  
  	    if (setegid(rgid) == -1)
  		(void) fprintf(stderr, "setegid(%d): %s\n",
! 			       (int) rgid, strerror(errno));
  
  	    if (seteuid(ruid) == -1)
  		(void) fprintf(stderr, "seteuid(%d): %s\n",
! 			       (int) ruid, strerror(errno));
  #endif
  
  	    XtSetErrorHandler(xt_error);
***************
*** 1317,1327 ****
  #ifdef HAS_POSIX_SAVED_IDS
  	    if (seteuid(euid) == -1)
  		(void) fprintf(stderr, "seteuid(%d): %s\n",
! 			       euid, strerror(errno));
  
  	    if (setegid(egid) == -1)
  		(void) fprintf(stderr, "setegid(%d): %s\n",
! 			       egid, strerror(errno));
  #endif
  	}
  
--- 1323,1333 ----
  #ifdef HAS_POSIX_SAVED_IDS
  	    if (seteuid(euid) == -1)
  		(void) fprintf(stderr, "seteuid(%d): %s\n",
! 			       (int) euid, strerror(errno));
  
  	    if (setegid(egid) == -1)
  		(void) fprintf(stderr, "setegid(%d): %s\n",
! 			       (int) egid, strerror(errno));
  #endif
  	}
  
***************
*** 1985,1992 ****
  	register TScreen *screen = &term->screen;
  #ifdef USE_HANDSHAKE
  	handshake_t handshake;
- #else
- 	int fds[2];
  #endif
  	int tty = -1;
  	int done;
--- 1991,1996 ----
***************
*** 2458,2464 ****
  	{ 
  #include <grp.h>
  		struct group *ttygrp;
! 		if (ttygrp = getgrnam("tty")) {
  			/* change ownership of tty to real uid, "tty" gid */
  			chown (ttydev, screen->uid, ttygrp->gr_gid);
  			chmod (ttydev, 0620);
--- 2462,2468 ----
  	{ 
  #include <grp.h>
  		struct group *ttygrp;
! 		if ((ttygrp = getgrnam("tty")) != 0) {
  			/* change ownership of tty to real uid, "tty" gid */
  			chown (ttydev, screen->uid, ttygrp->gr_gid);
  			chmod (ttydev, 0620);
Index: menu.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/menu.c	Tue Jan 16 15:43:01 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/menu.c	Sun Jan 28 20:45:35 1996
***************
*** 397,411 ****
      XtPointer closure, data;
  {
      register TScreen *screen = &term->screen;
!     Time time = CurrentTime;		/* XXX - wrong */
  
      if (screen->grabbedKbd) {
! 	XUngrabKeyboard (screen->display, time);
  	ReverseVideo (term);
  	screen->grabbedKbd = FALSE;
      } else {
  	if (XGrabKeyboard (screen->display, term->core.window,
! 			   True, GrabModeAsync, GrabModeAsync, time)
  	    != GrabSuccess) {
  	    Bell(XkbBI_MinorError, 100);
  	} else {
--- 397,411 ----
      XtPointer closure, data;
  {
      register TScreen *screen = &term->screen;
!     Time now = CurrentTime;		/* XXX - wrong */
  
      if (screen->grabbedKbd) {
! 	XUngrabKeyboard (screen->display, now);
  	ReverseVideo (term);
  	screen->grabbedKbd = FALSE;
      } else {
  	if (XGrabKeyboard (screen->display, term->core.window,
! 			   True, GrabModeAsync, GrabModeAsync, now)
  	    != GrabSuccess) {
  	    Bell(XkbBI_MinorError, 100);
  	} else {
Index: misc.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/misc.c	Fri Jan 26 11:43:22 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/misc.c	Sun Jan 28 20:45:35 1996
***************
*** 50,55 ****
--- 50,61 ----
  
  #include "xterm.h"
  
+ #if XtSpecificationRelease < 6
+ #ifndef X_GETTIMEOFDAY
+ #define X_GETTIMEOFDAY(t) gettimeofday(t,(struct timezone *)0)
+ #endif
+ #endif
+ 
  #ifdef AMOEBA
  #include "amoeba.h"
  #include "module/proc.h"
Index: scrollbar.c
*** /build/x11r6/XFree86-3.1.2Bn/xc/programs/xterm/scrollbar.c	Tue Jan 16 15:43:01 1996
--- /build/x11r6/XFree86-current/xc/programs/xterm/scrollbar.c	Sun Jan 28 20:45:35 1996
***************
*** 221,227 ****
  	register Widget scrollWidget;
  {
  	Arg args[4];
! 	int nargs = XtNumber(args);
  	unsigned long bg, fg, bdr;
  	Pixmap bdpix;
  
--- 221,227 ----
  	register Widget scrollWidget;
  {
  	Arg args[4];
! 	Cardinal nargs = XtNumber(args);
  	unsigned long bg, fg, bdr;
  	Pixmap bdpix;
  
