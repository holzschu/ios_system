
Prereq: public-patch-25

*** /tmp/da20646	Wed Nov  3 20:04:26 1993
--- mit/bug-report	Wed Nov  3 20:04:25 1993
***************
*** 2,8 ****
  Subject: [area]: [synopsis]   [replace with actual area and short description]
  
  VERSION:
!     R5, public-patch-25
      [MIT public patches will edit this line to indicate the patch level]
  
  CLIENT MACHINE and OPERATING SYSTEM:
--- 2,8 ----
  Subject: [area]: [synopsis]   [replace with actual area and short description]
  
  VERSION:
!     R5, public-patch-26
      [MIT public patches will edit this line to indicate the patch level]
  
  CLIENT MACHINE and OPERATING SYSTEM:
*** /tmp/da21897	Thu Nov  4 08:57:24 1993
--- mit/clients/xterm/misc.c	Thu Nov  4 08:57:23 1993
***************
*** 1,5 ****
  /*
!  *	$XConsortium: misc.c,v 1.92 92/03/13 17:02:08 gildea Exp $
   */
  
  /*
--- 1,5 ----
  /*
!  *	$XConsortium: misc.c,v 1.95.1.1 93/11/04 08:56:48 gildea Exp $
   */
  
  /*
***************
*** 444,449 ****
--- 444,518 ----
  	}
  }
  
+ #if defined(ALLOWLOGGING) || defined(DEBUG)
+ 
+ #ifndef X_NOT_POSIX
+ #define HAS_WAITPID
+ #endif
+ 
+ /*
+  * create a file only if we could with the permissions of the real user id.
+  * We could emulate this with careful use of access() and following
+  * symbolic links, but that is messy and has race conditions.
+  * Forking is messy, too, but we can't count on setreuid() or saved set-uids
+  * being available.
+  */
+ void
+ creat_as(uid, gid, pathname, mode)
+     int uid;
+     int gid;
+     char *pathname;
+     int mode;
+ {
+     int fd;
+     int waited;
+     int pid;
+ #ifndef HAS_WAITPID
+     int (*chldfunc)();
+ 
+     chldfunc = signal(SIGCHLD, SIG_DFL);
+ #endif
+     pid = fork();
+     switch (pid)
+     {
+     case 0:			/* child */
+ 	setgid(gid);
+ 	setuid(uid);
+ 	fd = open(pathname, O_WRONLY|O_CREAT|O_APPEND, mode);
+ 	if (fd >= 0) {
+ 	    close(fd);
+ 	    _exit(0);
+ 	} else
+ 	    _exit(1);
+     case -1:			/* error */
+ 	return;
+     default:			/* parent */
+ #ifdef HAS_WAITPID
+ 	waitpid(pid, NULL, 0);
+ #else
+ 	waited = wait(NULL);
+ 	signal(SIGCHLD, chldfunc);
+ 	/*
+ 	  Since we had the signal handler uninstalled for a while,
+ 	  we might have missed the termination of our screen child.
+ 	  If we can check for this possibility without hanging, do so.
+ 	*/
+ 	do
+ 	    if (waited == term->screen.pid)
+ 		Cleanup(0);
+ 	while ( (waited=nonblocking_wait()) > 0);
+ #endif
+     }
+ }
+ #endif
+ 
+ #ifdef ALLOWLOGGING
+ /*
+  * logging is a security hole, since it allows a setuid program to
+  * write arbitrary data to an arbitrary file.  So it is disabled
+  * by default.
+  */ 
+ 
  StartLog(screen)
  register TScreen *screen;
  {
***************
*** 530,551 ****
  		return;
  #endif
  	} else {
! 		if(access(screen->logfile, F_OK) == 0) {
! 			if(access(screen->logfile, W_OK) < 0)
! 				return;
! 		} else if(cp = rindex(screen->logfile, '/')) {
! 			*cp = 0;
! 			i = access(screen->logfile, W_OK);
! 			*cp = '/';
! 			if(i < 0)
! 				return;
! 		} else if(access(".", W_OK) < 0)
  			return;
! 		if((screen->logfd = open(screen->logfile, O_WRONLY | O_APPEND |
! 		 O_CREAT, 0644)) < 0)
! 			return;
! 		chown(screen->logfile, screen->uid, screen->gid);
  
  	}
  	screen->logstart = screen->TekEmu ? Tbptr : bptr;
  	screen->logging = TRUE;
--- 599,618 ----
  		return;
  #endif
  	} else {
! 		if(access(screen->logfile, F_OK) != 0) {
! 		    if (errno == ENOENT)
! 			creat_as(screen->uid, screen->gid,
! 				 screen->logfile, 0644);
! 		    else
  			return;
! 		}
  
+ 		if(access(screen->logfile, F_OK) != 0
+ 		   || access(screen->logfile, W_OK) != 0)
+ 		    return;
+ 		if((screen->logfd = open(screen->logfile, O_WRONLY | O_APPEND,
+ 					 0644)) < 0)
+ 			return;
  	}
  	screen->logstart = screen->TekEmu ? Tbptr : bptr;
  	screen->logging = TRUE;
***************
*** 587,592 ****
--- 654,660 ----
  		CloseLog(screen);
  }
  #endif /* ALLOWLOGFILEEXEC */
+ #endif /* ALLOWLOGGING */
  
  
  do_osc(func)
***************
*** 626,631 ****
--- 694,700 ----
  		Changetitle(buf);
  		break;
  
+ #ifdef ALLOWLOGGING
  	 case 46:	/* new log file */
  #ifdef ALLOWLOGFILECHANGES
  		/*
***************
*** 643,648 ****
--- 712,718 ----
  		Bell();
  #endif
  		break;
+ #endif /* ALLOWLOGGING */
  
  	case 50:
  		SetVTFont (fontMenu_fontescape, True, buf, NULL);
***************
*** 903,912 ****
--- 973,984 ----
      register TScreen *screen = &term->screen;
  
      if (screen->TekEmu) {
+ #ifdef ALLOWLOGGING
  	if (screen->logging) {
  	    FlushLog (screen);
  	    screen->logstart = buffer;
  	}
+ #endif
  	longjmp(Tekend, 1);
      } 
      return;
***************
*** 917,926 ****
--- 989,1000 ----
      register TScreen *screen = &term->screen;
  
      if (!screen->TekEmu) {
+ #ifdef ALLOWLOGGING
  	if(screen->logging) {
  	    FlushLog(screen);
  	    screen->logstart = Tbuffer;
  	}
+ #endif
  	screen->TekEmu = TRUE;
  	longjmp(VTend, 1);
      } 
*** /tmp/da17839	Wed Nov  3 18:16:38 1993
--- mit/clients/xterm/Tekproc.c	Wed Nov  3 18:16:37 1993
***************
*** 1,5 ****
  /*
!  * $XConsortium: Tekproc.c,v 1.107 91/06/25 19:49:48 gildea Exp $
   *
   * Warning, there be crufty dragons here.
   */
--- 1,5 ----
  /*
!  * $XConsortium: Tekproc.c,v 1.112 93/02/25 17:17:40 gildea Exp $
   *
   * Warning, there be crufty dragons here.
   */
***************
*** 46,51 ****
--- 46,52 ----
  #include <stdio.h>
  #include <errno.h>
  #include <setjmp.h>
+ #include <signal.h>
  
  /*
   * Check for both EAGAIN and EWOULDBLOCK, because some supposedly POSIX
***************
*** 74,80 ****
  
  #define TekColormap DefaultColormap( screen->display, \
  				    DefaultScreen(screen->display) )
! #define DefaultGCID DefaultGC(screen->display, DefaultScreen(screen->display))->gid
  
  /* Tek defines */
  
--- 75,81 ----
  
  #define TekColormap DefaultColormap( screen->display, \
  				    DefaultScreen(screen->display) )
! #define DefaultGCID XGContextFromGC(DefaultGC(screen->display, DefaultScreen(screen->display)))
  
  /* Tek defines */
  
***************
*** 188,194 ****
--- 189,197 ----
      /* menu actions */
      { "allow-send-events",	HandleAllowSends },
      { "set-visual-bell",	HandleSetVisualBell },
+ #ifdef ALLOWLOGGING
      { "set-logging",		HandleLogging },
+ #endif
      { "redraw",			HandleRedraw },
      { "send-signal",		HandleSendSignal },
      { "quit",			HandleQuit },
***************
*** 335,342 ****
  	register int c, x, y;
  	char ch;
  
! 	for( ; ; )
! 		switch(Tparsestate[c = input()]) {
  		 case CASE_REPORT:
  			/* report address */
  			if(screen->TekGIN) {
--- 338,346 ----
  	register int c, x, y;
  	char ch;
  
! 	for( ; ; ) {
! 	    c = input();
! 	    switch(Tparsestate[c]) {
  		 case CASE_REPORT:
  			/* report address */
  			if(screen->TekGIN) {
***************
*** 356,365 ****
--- 360,371 ----
  			/* special return to vt102 mode */
  			Tparsestate = curstate;
  			TekRecord->ptr[-1] = NAK; /* remove from recording */
+ #ifdef ALLOWLOGGING
  			if(screen->logging) {
  				FlushLog(screen);
  				screen->logstart = buffer;
  			}
+ #endif
  			return;
  
  		 case CASE_SPT_STATE:
***************
*** 626,631 ****
--- 632,638 ----
  			Tparsestate = curstate;
  			break;
  		}
+ 	}
  }			
  
  static int rcnt;
***************
*** 667,675 ****
  				       (int *) NULL, &crocktimeout);
  #endif
  			if(Tselect_mask & pty_mask) {
  				if(screen->logging)
  					FlushLog(screen);
! 				Tbcnt = read(screen->respond, Tbptr = Tbuffer, BUF_SIZE);
  				if(Tbcnt < 0) {
  					if(errno == EIO)
  						Cleanup (0);
--- 674,684 ----
  				       (int *) NULL, &crocktimeout);
  #endif
  			if(Tselect_mask & pty_mask) {
+ #ifdef ALLOWLOGGING
  				if(screen->logging)
  					FlushLog(screen);
! #endif
! 				Tbcnt = read(screen->respond, (char *)(Tbptr = Tbuffer), BUF_SIZE);
  				if(Tbcnt < 0) {
  					if(errno == EIO)
  						Cleanup (0);
***************
*** 1150,1157 ****
   * The following is called the create the tekWidget
   */
  
! static void TekInitialize(request, new)
      Widget request, new;
  {
      /* look for focus related events on the shell, because we need
       * to care about the shell's border being part of our focus.
--- 1159,1168 ----
   * The following is called the create the tekWidget
   */
  
! static void TekInitialize(request, new, args, num_args)
      Widget request, new;
+     ArgList args;
+     Cardinal *num_args;
  {
      /* look for focus related events on the shell, because we need
       * to care about the shell's border being part of our focus.
***************
*** 1549,1565 ****
  }
  
  
  /* write copy of screen to a file */
  
  TekCopy()
  {
- 	register TekLink *Tp;
- 	register int tekcopyfd;
  	register TScreen *screen = &term->screen;
  	register struct tm *tp;
  	long l;
  	char buf[32];
  
  	time(&l);
  	tp = localtime(&l);
  	sprintf(buf, "COPY%02d-%02d-%02d.%02d:%02d:%02d", tp->tm_year,
--- 1560,1585 ----
  }
  
  
+ #ifndef X_NOT_POSIX
+ #define HAS_WAITPID
+ #endif
+ 
  /* write copy of screen to a file */
  
  TekCopy()
  {
  	register TScreen *screen = &term->screen;
  	register struct tm *tp;
  	long l;
  	char buf[32];
+ 	int waited;
+ 	int pid;
+ #ifndef HAS_WAITPID
+ 	int (*chldfunc)();
  
+ 	chldfunc = signal(SIGCHLD, SIG_DFL);
+ #endif
+ 
  	time(&l);
  	tp = localtime(&l);
  	sprintf(buf, "COPY%02d-%02d-%02d.%02d:%02d:%02d", tp->tm_year,
***************
*** 1573,1593 ****
  		Bell();
  		return;
  	}
! 	if((tekcopyfd = open(buf, O_WRONLY | O_CREAT | O_TRUNC, 0644)) < 0) {
! 		Bell();
! 		return;
! 	}
! 	chown(buf, screen->uid, screen->gid);
! 	sprintf(buf, "\033%c\033%c", screen->page.fontsize + '8',
! 	 screen->page.linetype + '`');
! 	write(tekcopyfd, buf, 4);
! 	Tp = &Tek0; 
! 	do {
  		write(tekcopyfd, (char *)Tp->data, Tp->count);
  		Tp = Tp->next;
! 	} while(Tp);
! 	close(tekcopyfd);
  }
- 
- 
- 
--- 1593,1645 ----
  		Bell();
  		return;
  	}
! 
! 	/* Write the file in an unprivileged child process because
! 	   using access before the open still leaves a small window
! 	   of opportunity. */
! 	pid = fork();
! 	switch (pid)
! 	{
! 	case 0:			/* child */
! 	{
! 	    register int tekcopyfd;
! 	    char initbuf[5];
! 	    register TekLink *Tp;
! 
! 	    setgid(screen->gid);
! 	    setuid(screen->uid);
! 	    tekcopyfd = open(buf, O_WRONLY | O_CREAT | O_TRUNC, 0666);
! 	    if (tekcopyfd < 0)
! 		_exit(1);
! 	    sprintf(initbuf, "\033%c\033%c", screen->page.fontsize + '8',
! 		    screen->page.linetype + '`');
! 	    write(tekcopyfd, initbuf, 4);
! 	    Tp = &Tek0; 
! 	    do {
  		write(tekcopyfd, (char *)Tp->data, Tp->count);
  		Tp = Tp->next;
! 	    } while(Tp);
! 	    close(tekcopyfd);
! 	    _exit(0);
! 	}
! 	case -1:		/* error */
! 	    Bell();
! 	    return;
! 	default:		/* parent */
! #ifdef HAS_WAITPID
! 	    waitpid(pid, NULL, 0);
! #else
! 	    waited = wait(NULL);
! 	    signal(SIGCHLD, chldfunc);
! 	    /*
! 	      Since we had the signal handler uninstalled for a while,
! 	      we might have missed the termination of our screen child.
! 	      If we can check for this possibility without hanging, do so.
! 	      */
! 	    do
! 		if (waited == term->screen.pid)
! 		    Cleanup(0);
! 	    while ( (waited=nonblocking_wait()) > 0);
! #endif
! 	}
  }
