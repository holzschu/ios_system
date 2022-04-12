From esr@locke.ccil.org Sat Jan 13 18:02 EST 1996
Received: from locke.ccil.org (esr@locke.ccil.org [205.164.136.88]) by mail.Clark.Net (8.7.3/8.6.5) with SMTP id SAA07403 for <dickey@clark.net>; Sat, 13 Jan 1996 18:02:54 -0500 (EST)
Received: (esr@localhost) by locke.ccil.org (8.6.9/8.6.10) id SAA23481; Sat, 13 Jan 1996 18:28:57 -0500
From: "Eric S. Raymond" <esr@locke.ccil.org>
Message-Id: <199601132328.SAA23481@locke.ccil.org>
Subject: patch #283 -- change line-breakout optimization logic
To: zmbenhal@netcom.com, dickey@clark.net, ncurses-list@netcom.com
Date: Sat, 13 Jan 1996 18:28:56 -0500 (EST)
X-Mailer: ELM [version 2.4 PL24]
Content-Type: text
Content-Length: 9395
Status: RO

This patch (#283) changes the logic for line-breakout optimization.

Daniel Barlow complained:
>According to curs_inopts(3), curses periodically looks at the keyboard
>while refreshing, and stops immediately if there is input pending.
>
>This works too well!  I was playing with emacs to see if it would like
>to use real ncurses routines to output to the screen instead of just
>using it as a glorified termcap library, and found that if I held down
>the `page down' key (which autorepeats), nothing displayed at all
>until I let go of it again.

This patch addresses the problem.   See the comment leading the lib_doupdate.c
patch band for details.

This patch also makes a minor change in lib_initscr() to allow the maximum
escape delay to be set from the environment.  Finally, it includes a
workaround for the ncurses 'p' test bug.  A real fix is next on my agenda.

Diffs between last version checked in and current workfile(s):

--- NEWS	1996/01/11 19:47:02	1.3
+++ NEWS	1996/01/12 17:10:09
@@ -6,6 +6,8 @@
 * fixed broken wsyncup()/wysncdown(), as a result wnoutrefresh() now has
   copy-changed-lines behavior.
 * added and documented wresize() code.
+* changed the line-breakout optimization code to allow some lines to be
+  emitted before the first check.
 
 ### ncurses-1.9.7 -> 1.9.8a
 
--- ncurses/lib_doupdate.c	1996/01/12 16:09:44	1.6
+++ ncurses/lib_doupdate.c	1996/01/12 16:50:21
@@ -43,6 +43,17 @@
 #include "term.h"
 
 /*
+ * This define controls the line-breakout optimization.  Every once in a
+ * while during screen refresh, we want to check for input and abort the
+ * update if there's some waiting.  CHECK_INTERVAL controls the number of
+ * changed lines to be emitted between input checks.
+ *
+ * Note: Input-check-and-abort is no longer done if the screen is being
+ * updated from scratch.  This is a feature, not a bug.
+ */
+#define CHECK_INTERVAL	6
+
+/*
  * Enable checking to see if doupdate and friends are tracking the true
  * cursor position correctly.  NOTE: this is a debugging hack which will
  * work ONLY on ANSI-compatible terminals!
@@ -146,6 +157,26 @@
 	}
 }
 
+static bool check_pending(void)
+/* check for pending input */
+{
+	if (SP->_checkfd >= 0) {
+	fd_set fdset;
+	struct timeval ktimeout;
+
+		ktimeout.tv_sec =
+		ktimeout.tv_usec = 0;
+
+		FD_ZERO(&fdset);
+		FD_SET(SP->_checkfd, &fdset);
+		if (select(SP->_checkfd+1, &fdset, NULL, NULL, &ktimeout) != 0)
+		{
+			fflush(SP->_ofp);
+			return OK;
+		}
+	}
+}
+
 /*
  * No one supports recursive inline functions.  However, gcc is quieter if we
  * instantiate the recursive part separately.
@@ -278,22 +309,6 @@
 		SP->_endwin = FALSE;
 	}
 
-	/* check for pending input */
-	if (SP->_checkfd >= 0) {
-	fd_set fdset;
-	struct timeval ktimeout;
-
-		ktimeout.tv_sec =
-		ktimeout.tv_usec = 0;
-
-		FD_ZERO(&fdset);
-		FD_SET(SP->_checkfd, &fdset);
-		if (select(SP->_checkfd+1, &fdset, NULL, NULL, &ktimeout) != 0) {
-			fflush(SP->_ofp);
-			return OK;
-		}
-	}
-
 	/* 
 	 * FIXME: Full support for magic-cookie terminals could go in here.
 	 * The theory: we scan the virtual screen looking for attribute
@@ -315,10 +330,15 @@
 			ClrUpdate(newscr);
 			newscr->_clear = FALSE;
 		} else {
+			int changedlines;
+
 		        _nc_scroll_optimize();
 
 			T(("Transforming lines"));
-			for (i = 0; i < min(screen_lines, newscr->_maxy + 1); i++) {
+			for (i = changedlines = 0;
+			     i < min(screen_lines,newscr->_maxy+1);
+			     i++)
+			{
 				/*
 				 * newscr->line[i].firstchar is normally set
 				 * by wnoutrefresh.  curscr->line[i].firstchar
@@ -327,17 +347,43 @@
 				 */
 				if (newscr->_line[i].firstchar != _NOCHANGE
 				    || curscr->_line[i].firstchar != _NOCHANGE)
+				{
 					TransformLine(i);
+					changedlines++;
+				}
+
+				/* mark line changed successfully */
+				if (i <= newscr->_maxy)
+				{
+					newscr->_line[i].firstchar = _NOCHANGE;
+					newscr->_line[i].lastchar = _NOCHANGE;
+					newscr->_line[i].oldindex = i;
+				}
+				if (i <= curscr->_maxy)
+				{
+					curscr->_line[i].firstchar = _NOCHANGE;
+					curscr->_line[i].lastchar = _NOCHANGE;
+					curscr->_line[i].oldindex = i;
+				}
+
+				/*
+				 * Here is our line-breakout optimization.
+				 */
+				if ((changedlines % CHECK_INTERVAL) == changedlines-1 && check_pending())
+					goto cleanup;
 			}
 		}
 	}
-	T(("marking screen as updated"));
-	for (i = 0; i <= newscr->_maxy; i++) {
+
+	/* this code won't be executed often */
+	for (i = screen_lines; i <= newscr->_maxy; i++)
+	{
 		newscr->_line[i].firstchar = _NOCHANGE;
 		newscr->_line[i].lastchar = _NOCHANGE;
 		newscr->_line[i].oldindex = i;
 	}
-	for (i = 0; i <= curscr->_maxy; i++) {
+	for (i = screen_lines; i <= curscr->_maxy; i++)
+	{
 		curscr->_line[i].firstchar = _NOCHANGE;
 		curscr->_line[i].lastchar = _NOCHANGE;
 		curscr->_line[i].oldindex = i;
@@ -346,10 +392,11 @@
 	curscr->_curx = newscr->_curx;
 	curscr->_cury = newscr->_cury;
 
+	GoTo(curscr->_cury, curscr->_curx);
+
+    cleanup:
 	if (curscr->_attrs != A_NORMAL)
 		vidattr(curscr->_attrs = A_NORMAL);
-
-	GoTo(curscr->_cury, curscr->_curx);
 
 	fflush(SP->_ofp);
 
--- ncurses/lib_initscr.c	1996/01/12 20:11:34	1.1
+++ ncurses/lib_initscr.c	1996/01/12 20:17:54
@@ -41,6 +41,10 @@
   		exit(1);
 	}
 
+	/* allow user to set maximum escape delay from the environment */
+	if ((name = getenv("ESCDELAY")))
+	    ESCDELAY = atoi(getenv("ESCDELAY"));
+
 	def_shell_mode();
 
 	/* follow the XPG4 requirement to turn echo off at this point */
--- ncurses/lib_pad.c	1995/12/29 15:34:11	1.2
+++ ncurses/lib_pad.c	1996/01/13 17:56:24
@@ -107,6 +107,7 @@
 short	m, n;
 short	pmaxrow;
 short	pmaxcol;
+bool	wide;
 
 	T(("pnoutrefresh(%p, %d, %d, %d, %d, %d, %d) called", 
 		win, pminrow, pmincol, sminrow, smincol, smaxrow, smaxcol));
@@ -140,20 +141,46 @@
 
 	T(("pad being refreshed"));
 
+	/*
+	 * For pure efficiency, we'd want to transfer scrolling information
+	 * from the pad to newscr whenever the window is wide enough that
+	 * its update will dominate the cost of the update for the horizontal
+	 * band of newscr that it occupies.  Unfortunately, this threshold
+	 * tends to be complex to estimate, and in any case scrolling the
+	 * whole band and rewriting the parts outside win's image would look
+	 * really ugly.  So.  What we do is consider the pad "wide" if it
+	 * either (a) occupies the whole width of newscr, or (b) occupies
+	 * all but at most one column on either vertical edge of the screen
+	 * (this caters to fussy people who put boxes around full-screen
+	 * windows).  Note that changing this formula will not break any code,
+	 * merely change the costs of various update cases.
+	 */
+	wide = (sminrow <= 1 && win->_maxx >= (newscr->_maxx - 1));
+
 	for (i = pminrow, m = sminrow; i <= pmaxrow; i++, m++) {
+		register struct ldat	*nline = &newscr->_line[m];
+		register struct ldat	*oline = &win->_line[i];
+
 		for (j = pmincol, n = smincol; j <= pmaxcol; j++, n++) {
-		    if (win->_line[i].text[j] != newscr->_line[m].text[n]) {
-			newscr->_line[m].text[n] = win->_line[i].text[j];
+	    		if (oline->text[j] != nline->text[n]) {
+				nline->text[n] = oline->text[j];
+
+				if (nline->firstchar == _NOCHANGE)
+		   			nline->firstchar = nline->lastchar = n;
+				else if (n < nline->firstchar)
+		   			nline->firstchar = n;
+				else if (n > nline->lastchar)
+		   			nline->lastchar = n;
+			}
+		}
+
+		if (wide) {
+		    int	oind = oline->oldindex;
 
-			if (newscr->_line[m].firstchar == _NOCHANGE)
-			    newscr->_line[m].firstchar = newscr->_line[m].lastchar = n;
-			else if (n < newscr->_line[m].firstchar)
-			    newscr->_line[m].firstchar = n;
-			else if (n > newscr->_line[m].lastchar)
-			    newscr->_line[m].lastchar = n;
-		    }
+		    nline->oldindex = (oind == _NEWINDEX) ? _NEWINDEX : sminrow + oind;
 		}
-		win->_line[i].firstchar = win->_line[i].lastchar = _NOCHANGE;
+		oline->firstchar = oline->lastchar = _NOCHANGE;
+		oline->oldindex = i;
 	}
 
 	win->_begx = smincol;
@@ -176,6 +203,7 @@
 		newscr->_cury = win->_cury - pminrow + win->_begy;
 		newscr->_curx = win->_curx - pmincol + win->_begx;
 	}
+	win->_flags &= ~_HASMOVED;
 	return OK;
 }
 
--- test/ncurses.c	1996/01/11 19:49:39	1.4
+++ test/ncurses.c	1996/01/13 23:00:26
@@ -1368,6 +1368,35 @@
         }
 
 	mvaddch(porty - 1, portx - 1, ACS_LRCORNER);
+
+	/*
+	 * FIXME: this touchwin should not be necessary!
+	 * There is something not quite right with the pad code
+	 * Thomas Dickey writes:
+	 *
+	 * In the ncurses 'p' test, if I (now) press '<', '>', '<', then the
+	 * right boundary of the box that outlines the pad is blanked.  That's
+	 * because
+	 *
+	 * + the value that marks the right boundary (porty) is incremented,
+	 *
+	 * + a new vertical line is written to stdscr
+	 *
+	 * + stdscr is flushed with wnoutrefresh, clearing its firstchar &
+	 *   lastchar markers.  This writes the change (the new vertical line)
+	 *   to newscr.
+	 *
+	 * => previously stdscr was written to newscr entirely
+	 *
+	 * + the pad is written using prefresh, which writes directly to 
+	 *   newscr, bypassing stdscr entirely.
+	 *
+	 * When I've pressed '>' (see above), this means that stdscr contains
+	 * two columns of ACS_VLINE characters.  The left one (column 79) is
+	 * shadowed by the pad that's written to newscr.
+	 */
+	touchwin(stdscr);
+
 	wnoutrefresh(stdscr);
 
 	prefresh(pad,

End of diffs.


