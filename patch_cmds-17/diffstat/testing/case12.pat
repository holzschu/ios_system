Index: xc/programs/xterm/main.c
diff -u xc/programs/xterm/main.c:1.1.1.22 xc/programs/xterm/main.c:1.2
--- xc/programs/xterm/main.c:1.1.1.22	Tue Mar 19 07:36:38 1996
+++ xc/programs/xterm/main.c	Sun Mar 24 01:10:29 1996
@@ -182,6 +182,10 @@
 #undef CAPS_LOCK
 #endif
 
+#ifdef CSRG_BASED
+#define USE_POSIX_TERMIOS
+#endif
+
 #include <sys/ioctl.h>
 #include <sys/stat.h>
 
@@ -199,6 +203,9 @@
 #endif
 #endif
 
+#ifdef USE_POSIX_TERMIOS
+#include <termios.h>
+#else
 #ifdef USE_TERMIOS
 #include <termios.h>
 /* this hacked termios support only works on SYSV */
@@ -3143,11 +3197,11 @@
 		shname_minus = malloc(strlen(shname) + 2);
 		(void) strcpy(shname_minus, "-");
 		(void) strcat(shname_minus, shname);
-#ifndef USE_SYSV_TERMIO
+#if !defined(USE_SYSV_TERMIO) && !defined(USE_POSIX_TERMIOS)
 		ldisc = XStrCmp("csh", shname + strlen(shname) - 3) == 0 ?
 		 NTTYDISC : 0;
 		ioctl(0, TIOCSETD, (char *)&ldisc);
-#endif	/* !USE_SYSV_TERMIO */
+#endif	/* !USE_SYSV_TERMIO && !USE_POSIX_TERMIOS */
 
 #ifdef USE_LOGIN_DASH_P
 		if (term->misc.login_shell && pw && added_utmp_entry)
Index: xc/programs/xterm/resize.c
diff -u xc/programs/xterm/resize.c:1.1.1.9 xc/programs/xterm/resize.c:1.2
--- xc/programs/xterm/resize.c:1.1.1.9	Wed Feb 14 21:58:14 1996
+++ xc/programs/xterm/resize.c	Sun Mar 24 01:10:32 1996
@@ -87,19 +87,19 @@
 #define USE_TERMINFO
 #endif
 
-#ifdef MINIX
+#if defined(CSRG_BASED)
 #define USE_TERMIOS
 #endif
 
 #include <sys/ioctl.h>
 #ifdef USE_SYSV_TERMIO
-#include <sys/termio.h>
+# include <sys/termio.h>
 #else /* else not USE_SYSV_TERMIO */
-#ifdef MINIX
-#include <termios.h>
-#else /* !MINIX */
-#include <sgtty.h>
-#endif /* MINIX */
+# ifdef USE_TERMIOS
+#  include <termios.h>
+# else /* not USE_TERMIOS */
+#  include <sgtty.h>
+# endif /* USE_TERMIOS */
 #endif	/* USE_SYSV_TERMIO */
 
 #ifdef USE_USG_PTYS
@@ -127,8 +127,9 @@
 #define	bzero(s, n)	memset(s, 0, n)
 #endif	/* USE_SYSV_TERMIO */
 
-#ifdef USE_TERMIOS
+#ifdef MINIX
 #define USE_SYSV_TERMIO
+#include <sys/termios.h>
 #define termio termios
 #define TCGETA TCGETS
 #define TCSETAW TCSETSW
@@ -190,7 +191,11 @@
 #ifdef USE_SYSV_TERMIO
 struct termio tioorig;
 #else /* not USE_SYSV_TERMIO */
+# ifdef USE_TERMIOS
+struct termios tioorig;
+# else /* not USE_TERMIOS */
 struct sgttyb sgorig;
+# endif /* USE_TERMIOS */
 #endif /* USE_SYSV_TERMIO */
 char *size[EMULATIONS] = {
 	"\033[%d;%dR",
@@ -244,7 +249,11 @@
 #ifdef USE_SYSV_TERMIO
 	struct termio tio;
 #else /* not USE_SYSV_TERMIO */
+#ifdef USE_TERMIOS
+	struct termios tio;
+#else /* not USE_TERMIOS */
 	struct sgttyb sg;
+#endif /* USE_TERMIOS */
 #endif /* USE_SYSV_TERMIO */
 #ifdef USE_TERMCAP
 	char termcap [1024];
@@ -366,10 +375,20 @@
 	tio.c_cc[VMIN] = 6;
 	tio.c_cc[VTIME] = 1;
 #else	/* else not USE_SYSV_TERMIO */
+#if defined(USE_TERMIOS)
+	tcgetattr(tty, &tioorig);
+	tio = tioorig;
+	tio.c_iflag &= ~ICRNL;
+	tio.c_lflag &= ~(ICANON | ECHO);
+	tio.c_cflag |= CS8;
+	tio.c_cc[VMIN] = 6;
+	tio.c_cc[VTIME] = 1;
+#else	/* not USE_TERMIOS */
  	ioctl (tty, TIOCGETP, &sgorig);
 	sg = sgorig;
 	sg.sg_flags |= RAW;
 	sg.sg_flags &= ~ECHO;
+#endif  /* USE_TERMIOS */
 #endif	/* USE_SYSV_TERMIO */
 	signal(SIGINT, onintr);
 	signal(SIGQUIT, onintr);
@@ -377,7 +396,11 @@
 #ifdef USE_SYSV_TERMIO
 	ioctl (tty, TCSETAW, &tio);
 #else	/* not USE_SYSV_TERMIO */
+#ifdef USE_TERMIOS
+	tcsetattr(tty, TCSADRAIN, &tio);
+#else   /* not USE_TERMIOS */
 	ioctl (tty, TIOCSETP, &sg);
+#endif  /* USE_TERMIOS */
 #endif	/* USE_SYSV_TERMIO */
 
 	if (argc == 2) {
@@ -434,7 +457,11 @@
 #ifdef USE_SYSV_TERMIO
 	ioctl (tty, TCSETAW, &tioorig);
 #else	/* not USE_SYSV_TERMIO */
+#ifdef USE_TERMIOS
+	tcsetattr(tty, TCSADRAIN, &tioorig);
+#else   /* not USE_TERMIOS */
 	ioctl (tty, TIOCSETP, &sgorig);
+#endif  /* USE_TERMIOS */
 #endif	/* USE_SYSV_TERMIO */
 	signal(SIGINT, SIG_DFL);
 	signal(SIGQUIT, SIG_DFL);
@@ -595,7 +622,11 @@
 #ifdef USE_SYSV_TERMIO
 	ioctl (tty, TCSETAW, &tioorig);
 #else	/* not USE_SYSV_TERMIO */
+#ifdef USE_TERMIOS
+	tcsetattr (tty, TCSADRAIN, &tioorig);
+#else   /* not USE_TERMIOS */
 	ioctl (tty, TIOCSETP, &sgorig);
+#endif  /* use TERMIOS */
 #endif	/* USE_SYSV_TERMIO */
 	exit(1);
 }

