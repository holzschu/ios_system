diff -c 'vile-9.3+/README' 'vile-9.3j+/README'
Index: ./README
Prereq:  1.88 
*** ./README	Tue Jun 25 20:25:57 2002
--- ./README	Sun Jun 30 16:27:52 2002
***************
*** 23,41 ****
  impatient?  just type "./configure; make", and get a cup of coffee, decaf
  if necessary.
  
  want X11 support?  you'd better look at doc/config.doc, although
  "./configure --with-screen=x11"; make" may well do what you want.
  
  want PC support?  look for precompiled binaries at the various ftp sites.
  
  want to build vile on a PC host?  refer to the file README.PC .
  
! want VMS support?  you'll need to build vile yourself. refer to the
! file README.VMS .
! 
! if you like vile, and wish to be informed of new releases, let me
! know -- i maintain a mailing list for that purpose.  don't worry -- the
! volume won't fill your inbox.
  
  paul fox, pgf@foxharp.boston.ma.us (original author)
  kevin buettner, kev@primenet.com
--- 23,49 ----
  impatient?  just type "./configure; make", and get a cup of coffee, decaf
  if necessary.
  
+ want to know more about configure options?  type "./configure --help"
+ and then read doc/config.doc for further details.
+ 
  want X11 support?  you'd better look at doc/config.doc, although
  "./configure --with-screen=x11"; make" may well do what you want.
  
+ want syntax coloring?  add "--with-builtin-filters" to your configure
+ options and then read the topics "Color basics" and "Syntax coloring" in
+ the file vile.hlp.
+ 
  want PC support?  look for precompiled binaries at the various ftp sites.
  
  want to build vile on a PC host?  refer to the file README.PC .
  
! want VMS support?  some precompiled binaries are available at
! ftp://ftp.phred.org/pub/vile.  otherwise, you'll need to build vile
! yourself.  In either case, refer to the file README.VMS .
! 
! if you like vile, and wish to be informed of new releases, let me know -- i
! maintain a mailing list for that purpose (scroll down a bit for details). 
! don't worry -- the volume won't fill your inbox.
  
  paul fox, pgf@foxharp.boston.ma.us (original author)
  kevin buettner, kev@primenet.com
***************
*** 628,632 ****
      + add $prompt variable, to allow changing the command-line prompt.
  
  -------------------------------
! @Header: /users/tom/src/diffstat/testing/RCS/case20.pat,v 1.1 2003/01/04 18:59:35 tom Exp @
  -------------------------------
--- 636,640 ----
      + add $prompt variable, to allow changing the command-line prompt.
  
  -------------------------------
! @Header: /users/tom/src/diffstat/testing/RCS/case20.pat,v 1.1 2003/01/04 18:59:35 tom Exp @
  -------------------------------
diff -c 'vile-9.3+/README.PC' 'vile-9.3j+/README.PC'
Index: ./README.PC
Prereq:  1.29 
*** ./README.PC	Tue Jun 25 20:25:57 2002
--- ./README.PC	Sun Jun 30 16:27:52 2002
***************
*** 198,208 ****
      install it in a directory located in your PATH and add the following
      command-line option:
  
!         nmake -f makefile.wnt <OPTIONS_FROM_ABOVE> LEX=flex   # or LEX=lex
  
      take note that flex is a component of cygwin's GNU emulation package
      and works quite well for this purpose.  cygwin can be obtained from
!     Redhat at http://sources.redhat.com/cygwin.
  
  [2] this option requires prior installation of perl.  refer to the section
      entitled "Perl preconditions" below.
--- 198,209 ----
      install it in a directory located in your PATH and add the following
      command-line option:
  
!         nmake -f makefile.wnt <OPTIONS_FROM_ABOVE> FLT=1 LEX=flex  # or LEX=lex
  
      take note that flex is a component of cygwin's GNU emulation package
      and works quite well for this purpose.  cygwin can be obtained from
!     Redhat at http://sources.redhat.com/cygwin.  the FLT option binds
!     all syntax coloring filters into the resultant [win]vile executable.
  
  [2] this option requires prior installation of perl.  refer to the section
      entitled "Perl preconditions" below.
***************
*** 263,267 ****
  paul fox, pgf@foxharp.boston.ma.us (home)
  
  ------------------------
! @Header: /users/tom/src/diffstat/testing/RCS/case20.pat,v 1.1 2003/01/04 18:59:35 tom Exp @
  ------------------------
--- 264,268 ----
  paul fox, pgf@foxharp.boston.ma.us (home)
  
  ------------------------
! @Header: /users/tom/src/diffstat/testing/RCS/case20.pat,v 1.1 2003/01/04 18:59:35 tom Exp @
  ------------------------
