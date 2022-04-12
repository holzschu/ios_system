--- /dev/null	1.1 Sun Jul 17 19:46:18 1994
+++ ncurses-1.9.8a_960131_e285r/man/resizeterm.3x	Wed Jan 31 20:21:04 1996
@@ -0,0 +1,53 @@
+.\"*****************************************************************************
+.\" Testcase for "resizeterm"                                                  *
+.\"                                                                            *
+.\" A discussion of this file is found at:                                     *
+.\"    http://invisible-island.net/ncurses/ncurses-license.html#ncurses_1_9_3  *
+.\" A later version of this manpage is included as part of ncurses.            *
+.\"*****************************************************************************
+.TH resizeterm 3X ""
+.
+.SH NAME
+\fBresizeterm\fR - change the curses terminal size
+.
+.SH SYNOPSIS
+\fB#include <curses.h>\fR
+
+\fBint resizeterm(int lines, int columns);\fR
+.
+.SH DESCRIPTION
+This is an extension to the curses library.
+It provides callers with a hook into the \fBncurses\fR data to resize windows,
+primarily for use by programs running in an X Window terminal (e.g., xterm).
+The function \fBresizeterm\fR resizes the standard and current windows
+to the specified dimensions, and adjusts other bookkeeping data used by
+the \fBncurses\fR library that record the window dimensions.
+
+When resizing the windows, the function blank-fills the areas that are
+extended. The calling application should fill in these areas with
+appropriate data.
+
+The function does not resize other windows.
+.
+.SH RETURN VALUE
+The function returns the integer \fBERR\fR upon failure and \fBOK\fR on success.
+It will fail if either of the dimensions less than or equal to zero,
+or if an error occurs while (re)allocating memory for the windows. 
+.
+.SH NOTES
+While this function is intended to be used to support a signal handler
+(i.e., for SIGWINCH), care should be taken to avoid invoking it in a
+context where \fBmalloc\fR or \fBrealloc\fR may have been interrupted,
+since it uses those functions.
+.
+.SH SEE ALSO
+\fBwresize\fR(3x).
+.
+.SH AUTHOR
+Thomas Dickey (from an equivalent function written in 1988 for BSD curses).
+.\"#
+.\"# The following sets edit modes for GNU EMACS
+.\"# Local Variables:
+.\"# mode:nroff
+.\"# fill-column:79
+.\"# End:
--- /dev/null	Sun Jul 17 19:46:18 1994
+++ ncurses-1.9.8a_960131_e285r/man/wresize.3x	Wed Jan 31 20:21:04 1996
@@ -0,0 +1,47 @@
+.\"*****************************************************************************
+.\" Testcase for "wresize"                                                     *
+.\"                                                                            *
+.\" A discussion of this file is found at:                                     *
+.\"    http://invisible-island.net/ncurses/ncurses-license.html#ncurses_1_9_3  *
+.\" A later version of this manpage is included as part of ncurses.            *
+.\" Copyright 1995 by Thomas E. Dickey.  All Rights Reserved.                  *
+.\"*****************************************************************************
+.TH wresize 3X ""
+.
+.SH NAME
+\fBwresize\fR - resize a curses window
+.
+.SH SYNOPSIS
+\fB#include <curses.h>\fR
+
+\fBint wresize(WINDOW *win, int lines, int columns);\fR
+.
+.SH DESCRIPTION
+The \fBwresize\fR function reallocates storage for an \fBncurses\fR
+window to adjust its dimensions to the specified values.
+If either dimension is larger than the current values, the
+window's data is filled with blanks that have the current background rendition
+(as set by \fBwbkgndset\fR) merged into them.
+.
+.SH RETURN VALUE
+The function returns the integer \fBERR\fR upon failure and \fBOK\fR on success.
+It will fail if either of the dimensions less than or equal to zero,
+or if an error occurs while (re)allocating memory for the window.
+.
+.SH NOTES
+The only restriction placed on the dimensions is that they be greater than zero.
+The dimensions are not compared to \fBcurses\fR screen dimensions to
+simplify the logic of \fBresizeterm\fR.
+The caller must ensure that the window's dimensions fit within the
+actual screen dimensions.
+.
+.SH SEE ALSO
+\fBresizeterm\fR(3x).
+.
+.SH AUTHOR
+Thomas Dickey (from an equivalent function written in 1988 for BSD curses).
+.\"#
+.\"# The following sets edit modes for GNU EMACS
+.\"# Local Variables:
+.\"# mode:nroff
+.\"# fill-column:79
+.\"# End:
