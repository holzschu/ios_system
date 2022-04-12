--------------------------------------------------------------------------------
--- /build/x11r6/XFree86-3.1.2Cf/xc/config/cf/hp.cf	Sat Feb 10 13:55:35 1996
+++ /build/x11r6/XFree86-current/xc/config/cf/hp.cf	Mon Feb 19 19:10:15 1996
@@ -59,9 +59,16 @@
 #define Malloc0ReturnsNull     YES
 
 #ifdef __hp9000s800
+#if HasGcc2
+#define OptimizedCDebugFlags   -O
+#define DefaultCCOptions
+#define SharedLibraryCCOptions	-fPIC
+#define PositionIndependentCFlags -fPIC
+#else
 #define OptimizedCDebugFlags   +O1
 #define DefaultCCOptions       -Ae +ESlit
 #define SharedLibraryCCOptions -Ae
+#endif
 #define StandardDefines        -Dhpux -DSYSV
 #define ServerExtraDefines -DXOS -DBSTORE -DSOFTWARE_CURSOR -DNO_ALLOCA -DSCREEN_PIXMAPS -DMERGE_SAVE_UNDERS -DHAS_IFREQ -DFORCE_SEPARATE_PRIVATE
 
--- /build/x11r6/XFree86-3.1.2Cf/xc/config/cf/hpLib.rules	Sat Jan  6 08:11:01 1996
+++ /build/x11r6/XFree86-current/xc/config/cf/hpLib.rules	Mon Feb 19 19:11:14 1996
@@ -29,8 +29,10 @@
 #define InstLibFlags -m 0555
 #endif
 #ifndef UseInstalled
+#ifndef HasGcc2
 /* assert: LdPostLib pulls in -L$(USRLIBDIR), so it doesn't need to be here */
 #define ExtraLoadFlags -Wl,+s,+b,$(USRLIBDIR)
+#endif
 #endif
 
 /*
--- /build/x11r6/XFree86-3.1.2Cf/xc/config/imake/imakemdep.h	Sat Jan  6 08:11:01 1996
+++ /build/x11r6/XFree86-current/xc/config/imake/imakemdep.h	Mon Feb 19 19:15:01 1996
@@ -41,6 +41,10 @@
  *     These will be passed to the compile along with the contents of the
  *     make variable BOOTSTRAPCFLAGS.
  */
+#if defined(clipper) || defined(__clipper__)
+#define imake_ccflags "-O -DSYSV -DBOOTSTRAPCFLAGS=-DSYSV"
+#endif
+
 #ifdef hpux
 #ifdef hp9000s800
 #define imake_ccflags "-DSYSV"
@@ -224,6 +228,9 @@
 #ifdef apollo
 #define DEFAULT_CPP "/usr/lib/cpp"
 #endif
+#if defined(clipper) || defined(__clipper__)
+#define DEFAULT_CPP "/usr/lib/cpp"
+#endif
 #if defined(_IBMR2) && !defined(DEFAULT_CPP)
 #define DEFAULT_CPP "/usr/lpp/X11/Xamples/util/cpp/cpp"
 #endif
@@ -529,6 +536,12 @@
 struct symtab	predefs[] = {
 #ifdef apollo
 	{"apollo", "1"},
+#endif
+#if defined(clipper) || defined(__clipper__)
+	{"clipper", "1"},
+	{"__clipper__", "1"},
+	{"clix", "1"},
+	{"__clix__", "1"},
 #endif
 #ifdef ibm032
 	{"ibm032", "1"},
--- /build/x11r6/XFree86-3.1.2Cf/xc/config/makedepend/main.c	Fri Jan 26 11:43:22 1996
+++ /build/x11r6/XFree86-current/xc/config/makedepend/main.c	Mon Feb 19 19:16:06 1996
@@ -570,7 +570,7 @@
 	return(file);
 }
 
-#if defined(USG) && !defined(CRAY) && !defined(SVR4) && !defined(__EMX__)
+#if defined(USG) && !defined(CRAY) && !defined(SVR4) && !defined(__EMX__) && !defined(clipper) && !defined(__clipper__)
 int rename (from, to)
     char *from, *to;
 {
--- /build/x11r6/XFree86-3.1.2Cf/xc/include/Xos.h	Fri Jan 26 11:43:22 1996
+++ /build/x11r6/XFree86-current/xc/include/Xos.h	Mon Feb 19 19:18:23 1996
@@ -77,6 +77,7 @@
 
 #ifndef X_NOT_STDC_ENV
 
+#if !(defined(sun) && !defined(SVR4))	/* 'index' is problem with K&R */
 #include <string.h>
 #ifndef index
 #define index(s,c) (strchr((s),(c)))
@@ -84,10 +85,14 @@
 #ifndef rindex
 #define rindex(s,c) (strrchr((s),(c)))
 #endif
+#endif
 
 #else
 
 #ifdef SYSV
+#if defined(clipper) || defined(__clipper__)
+#include <malloc.h>
+#endif
 #include <string.h>
 #define index strchr
 #define rindex strrchr
@@ -149,7 +154,7 @@
 #ifdef CRAY
 #undef word
 #endif /* CRAY */
-#if defined(USG) && !defined(CRAY) && !defined(MOTOROLA) && !defined(uniosu) && !defined(__sxg__)
+#if defined(USG) && !defined(CRAY) && !defined(MOTOROLA) && !defined(uniosu) && !defined(__sxg__) && !defined(clipper) && !defined(__clipper__)
 struct timeval {
     long tv_sec;
     long tv_usec;
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/XIE/mixie/import/mijpeg.c	Sun Apr 17 20:34:54 1994
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/XIE/mixie/import/mijpeg.c	Mon Feb 19 18:48:31 1996
@@ -114,7 +114,7 @@
 
 /*
  *  routines referenced by other DDXIE modules
-/*
+ */
 int CreateIPhotoJpegBase();
 int InitializeIPhotoJpegBase();
 int InitializeICPhotoJpegBase();
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/XIE/mixie/process/mpgeomaa.c	Sun Apr 17 20:35:19 1994
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/XIE/mixie/process/mpgeomaa.c	Mon Feb 19 18:49:43 1996
@@ -242,7 +242,7 @@
     }
 }
 /*------------------------------------------------------------------------
-/*------------------------------------------------------------------------
+--------------------------------------------------------------------------
 ---------------------------- initialize peTex . . . ----------------------
 ------------------------------------------------------------------------*/
 static int InitializeGeomAA(flo,ped)
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/XIE/mixie/process/mpgeomnn.c	Sat Jan  6 08:11:01 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/XIE/mixie/process/mpgeomnn.c	Mon Feb 19 18:50:29 1996
@@ -259,7 +259,7 @@
 }
 
 /*------------------------------------------------------------------------
-/*------------------------------------------------------------------------
+--------------------------------------------------------------------------
 ---------------------------- initialize peTex . . . ----------------------
 ------------------------------------------------------------------------*/
 static int InitializeGeomNN(flo,ped)
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/hp/input/drivers/hil_driver.c	Mon Jan 30 23:07:07 1995
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/hp/input/drivers/hil_driver.c	Mon Feb 19 18:51:11 1996
@@ -431,7 +431,7 @@
     return FALSE;
 
   id = describe[0];
-/* printf("fd is %d errno is %d id is %x\n", fd, errno, id);	/*  */
+/* printf("fd is %d errno is %d id is %x\n", fd, errno, id);	*/
 
   num_axes = (describe[1] & HIL_NUM_AXES);
   if (id == NINE_KNOB_ID && num_axes != 3) id = QUAD_ID;
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/hp/input/hpKeyMap.c	Mon Jan 30 23:06:55 1995
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/hp/input/hpKeyMap.c	Mon Feb 19 18:52:20 1996
@@ -85,7 +85,7 @@
  /* code values in comments at line end are actual value reported on HIL.
     REMEMBER, there is an offset of MIN_KEYCODE+2 applied to this table!
     The PS2 keyboard table begins at offset 0, the 46021A table begins with
-    the third row. *./
+    the third row. */
 	/* Extend Char Right -- a.k.a. Kanji? */	
 	XK_Control_R,		NoSymbol,		NoSymbol,	NoSymbol,	/* 0x00 */
 	NoSymbol,		NoSymbol,		NoSymbol,	NoSymbol,	/* 0x01 */
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/accel/i128/i128scrin.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/accel/i128/i128scrin.c	Mon Feb 19 18:53:02 1996
@@ -348,7 +348,7 @@
   pScreen->DestroyColormap = (DestroyColormapProcPtr)NoopDDA;
   pScreen->ResolveColor = cfbResolveColor;
   pScreen->BitmapToRegion = mfbPixmapToRegion;
-#if 0  /* What's this for?!  /* *TO*DO* */
+#if 0  /* What's this for?!  *TO*DO* */
   pScreen->BlockHandler = i128BlockHandler;
 #endif
 
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/accel/p9000/p9000scrin.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/accel/p9000/p9000scrin.c	Mon Feb 19 18:53:37 1996
@@ -351,7 +351,7 @@
   pScreen->DestroyColormap = (DestroyColormapProcPtr)NoopDDA;
   pScreen->ResolveColor = cfbResolveColor;
   pScreen->BitmapToRegion = mfbPixmapToRegion;
-#if 0  /* What's this for?!  /* *TO*DO* */
+#if 0  /* What's this for?!  *TO*DO* */
   pScreen->BlockHandler = p9000BlockHandler;
 #endif
 
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/drivers/apollo/apolloHW.h	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/drivers/apollo/apolloHW.h	Mon Feb 19 18:54:57 1996
@@ -8,7 +8,7 @@
  * Hamish Coleman 11/93 hamish@zot.apana.org.au 
  *
  * derived from:
- * bdm2/hgc1280/*
+ * bdm2/hgc1280/...
  * Pascal Haible 8/93, haible@izfm.uni-stuttgart.de
  *
  * see mono/COPYRIGHT for copyright and disclaimers.
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/drivers/apollo/apollodriv.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/drivers/apollo/apollodriv.c	Mon Feb 19 18:55:33 1996
@@ -8,12 +8,12 @@
  * Hamish Coleman 11/93 hamish@zot.apana.org.au
  *
  * derived from:
- * bdm2/hgc1280/*
+ * bdm2/hgc1280/...
  * Pascal Haible 8/93, haible@izfm.uni-stuttgart.de
- * hga2/*
+ * hga2/...
  * Author:  Davor Matic, dmatic@athena.mit.edu
  * and
- * vga256/*
+ * vga256/...
  * Copyright 1990,91 by Thomas Roell, Dinkelscherben, Germany.
  *
  * Thanks to Herb Peyerl (hpeyerl@novatel.ca) for the information on 
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/drivers/hgc1280/hgc1280driv.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/drivers/hgc1280/hgc1280driv.c	Mon Feb 19 18:55:54 1996
@@ -6,10 +6,10 @@
  * mono/driver/hgc1280/hgc1280driv.c
  *
  * derived from:
- * hga2/*
+ * hga2/...
  * Author:  Davor Matic, dmatic@athena.mit.edu
  * and
- * vga256/*
+ * vga256/...
  * Copyright 1990,91 by Thomas Roell, Dinkelscherben, Germany.
  *
  * see mono/COPYRIGHT for copyright and disclaimers.
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/drivers/sigma/sigmadriv.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/drivers/sigma/sigmadriv.c	Mon Feb 19 18:56:15 1996
@@ -7,10 +7,10 @@
  * mono/driver/sigma/sigmadriv.c
  *
  * Parts derived from:
- * hga2/*
+ * hga2/...
  * Author:  Davor Matic, dmatic@athena.mit.edu
  * and
- * vga256/*
+ * vga256/...
  * Copyright 1990,91 by Thomas Roell, Dinkelscherben, Germany.
  *
  * see mono/COPYRIGHT for copyright and disclaimers.
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/mono/mono.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/mono/mono.c	Mon Feb 19 18:56:58 1996
@@ -6,10 +6,10 @@
  * mono/mono/mono.c
  *
  * derived from:
- * hga2/*
+ * hga2/...
  * Author:  Davor Matic, dmatic@athena.mit.edu
  * and
- * vga256/*
+ * vga256/...
  * Copyright 1990,91 by Thomas Roell, Dinkelscherben, Germany.
  *
  * see mono/COPYRIGHT for copyright and disclaimers.
@@ -512,7 +512,7 @@
     DDXPointRec pixPt;	/* Point: upper left corner */
     PixmapPtr   pspix;	/* Pointer to the pixmap of the saved screen */
     ScreenPtr   pScreen = savepScreen;	/* This is the 'old' Screen:
-				/* real screen on leave, dummy on enter */
+				real screen on leave, dummy on enter */
 
     /* Set up pointer to the saved pixmap (pspix) only if not resetting
 						and not exiting */
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/mono/mono/mono.h	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/mono/mono/mono.h	Mon Feb 19 18:57:19 1996
@@ -6,10 +6,10 @@
  * mono/mono/mono.h
  *
  * derived from:
- * hga2/*
+ * hga2/...
  * Author:  Davor Matic, dmatic@athena.mit.edu
  * and
- * vga256/*
+ * vga256/...
  * Copyright 1990,91 by Thomas Roell, Dinkelscherben, Germany.
  *
  * see mono/COPYRIGHT for copyright and disclaimers.
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/vga16/ibm/vgaImages.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/vga16/ibm/vgaImages.c	Mon Feb 19 18:57:57 1996
@@ -27,7 +27,7 @@
 
 #include "OScompiler.h"
 
-/* #include "ibmIOArch.h" /* GJA */
+/* #include "ibmIOArch.h" -- GJA */
 
 #include "vgaVideo.h"
 
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/vga256/drivers/ati/regati.h	Fri Feb  9 13:08:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/vga256/drivers/ati/regati.h	Mon Feb 19 18:58:43 1996
@@ -679,7 +679,7 @@
 #define GEN_TEST_CNT_VALUE		0x3f000000	/* Mach64CT/ET */
 #define GEN_TEST_CC_EN			0x40000000	/* Mach64GX/CX */
 #define GEN_TEST_CC_STROBE		0x80000000	/* Mach64GX/CX */
-/*	?				0xc0000000	/* Mach64CT/ET */
+/*	?				0xc0000000 */	/* Mach64CT/ET */
 #define CONFIG_CNTL		0x6aec
 #define CFG_MEM_AP_SIZE			0x00000003
 #define CFG_MEM_VGA_AP_EN		0x00000004
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/vga256/drivers/cirrus/cir_blitter.c	Fri Feb  9 13:08:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/vga256/drivers/cirrus/cir_blitter.c	Mon Feb 19 18:59:33 1996
@@ -126,7 +126,7 @@
     /* For the lower byte of the 32-bit color registers, there is no safe
      * invalid value. We just set them to a specific value (making sure
      * we don't write to non-existant color registers).
-     * 
+     */ 
     cirrusBackgroundColorShadow = 0xffffffff;	/* Defeat the macros. */
     cirrusForegroundColorShadow = 0xffffffff;
     if (cirrusChip >= CLGD5422 && cirrusChip <= CLGD5430) {
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/vga256/drivers/cirrus/cir_cursor.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/vga256/drivers/cirrus/cir_cursor.c	Mon Feb 19 19:00:02 1996
@@ -22,7 +22,7 @@
  * PERFORMANCE OF THIS SOFTWARE.
  *
  * Author:  Simon P. Cooper, <scooper@vizlab.rutgers.edu>
- *
+ */
 /* $XConsortium: cir_cursor.c /main/8 1995/11/13 08:20:54 kaleb $ */
 
 #define CIRRUS_DEBUG_CURSOR
--- /build/x11r6/XFree86-3.1.2Cf/xc/programs/Xserver/hw/xfree86/vga256/drivers/oak/oak_driver.c	Mon Feb  5 12:03:00 1996
+++ /build/x11r6/XFree86-current/xc/programs/Xserver/hw/xfree86/vga256/drivers/oak/oak_driver.c	Mon Feb 19 19:00:52 1996
@@ -1402,7 +1402,7 @@
     case OTI37C:
     default:
 #ifndef MONOVGA
-      /* new->std.CRTC[19] = vga256InfoRec.virtualX >> 3; /* 3 in byte mode */
+      /* new->std.CRTC[19] = vga256InfoRec.virtualX >> 3; -- 3 in byte mode */
       /* much clearer as 0x01 than 0x41, seems odd though... */
       new->std.Attribute[16] = 0x01; 
       if ( new->std.NoClock >= 0 ) 
--- /build/x11r6/XFree86-3.1.2Cf/xc/test/xsuite/xtest/src/bin/mc/files.c	Sun Apr 17 21:00:20 1994
+++ /build/x11r6/XFree86-current/xc/test/xsuite/xtest/src/bin/mc/files.c	Mon Feb 19 19:02:49 1996
@@ -95,7 +95,7 @@
 char 	buf[BUFSIZ];
 
 	/*
-	 * Look for a corresponding file with name lib/mc/*.mc .
+	 * Look for a corresponding file with name lib/mc/{*}.mc .
 	 */
 	(void) sprintf(buf, "mc/%s", file);
 	file = buf;
--- /build/x11r6/XFree86-3.1.2Cf/xc/util/patch/malloc.c	Wed Aug 15 01:13:33 1990
+++ /build/x11r6/XFree86-current/xc/util/patch/malloc.c	Mon Feb 19 19:04:28 1996
@@ -30,10 +30,8 @@
  * go in the first int of the block, and the returned pointer will point
  * to the second.
  *
-#ifdef MSTATS
  * nmalloc[i] is the difference between the number of mallocs and frees
  * for a given block size.
-#endif /* MSTATS */
  */
 
 #define ISALLOC ((char) 0xf7)	/* magic byte that implies allocation */
@@ -208,7 +206,7 @@
 		if (--nblks <= 0) break;
 		CHAIN ((struct mhead *) cp) = (struct mhead *) (cp + siz);
 		cp += siz;}
-/*	CHAIN ((struct mhead *) cp) = 0;	/* since sbrk() returns cleared core, this is already set */
+/*	CHAIN ((struct mhead *) cp) = 0;	-- since sbrk() returns cleared core, this is already set */
 	}
 
 static
@@ -449,10 +447,10 @@
 	return (1 << (p -> mh_index + 3)) - sizeof *p;
 /**/
 /*	if (p -> mh_index >= 13)
-/*	    return (1 << (p -> mh_index + 3)) - sizeof *p;
-/*	else
-/*	    return p -> mh_size;
-/**/
+ *	    return (1 << (p -> mh_index + 3)) - sizeof *p;
+ *	else
+ *	    return p -> mh_size;
+ */
 #endif /* rcheck */
 	}
 
--- /build/x11r6/XFree86-3.1.2Cf/xc/util/patch/pch.c	Sat Jan  6 08:11:01 1996
+++ /build/x11r6/XFree86-current/xc/util/patch/pch.c	Mon Feb 19 19:05:12 1996
@@ -1,5 +1,5 @@
 /* oldHeader: pch.c,v 2.0.1.7 88/06/03 15:13:28 lwall Locked $
-/* $XConsortium: pch.c,v 3.3 94/09/14 21:22:55 gildea Exp $
+ * $XConsortium: pch.c,v 3.3 94/09/14 21:22:55 gildea Exp $
  *
  * Revision 2.0.2.0  90/05/01  22:17:51  davison
  * patch12u: unidiff support added
--- /build/x11r6/XFree86-3.1.2Cf/xc/config/cf/Imake.cf	Fri Jan 26 11:43:22 1996
+++ /build/x11r6/XFree86-current/xc/config/cf/Imake.cf	Mon Feb 19 19:13:58 1996
@@ -19,6 +19,13 @@
  *     4.  Create a .cf file with the name given by MacroFile.
  */
 
+#if defined(clipper) || defined(__clipper__)
+# undef clipper
+# define MacroIncludeFile <ingr.cf>
+# define MacroFile ingr.cf
+# define IngrArchitecture
+#endif /* clipper */
+
 #ifdef ultrix
 # define MacroIncludeFile <ultrix.cf>
 # define MacroFile ultrix.cf
