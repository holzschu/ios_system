diff -Nru /tmp/8FTwAYJlot/flwm-1.00/config.h /tmp/KfNDqvamm0/flwm-1.01/config.h
--- /tmp/8FTwAYJlot/flwm-1.00/config.h	1999-08-24 22:59:35.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/config.h	2002-03-24 02:02:33.000000000 +0100
@@ -25,6 +25,12 @@
 // nothing is done if this is not defined:
 //#define AUTO_RAISE 0.5
 
+// Perform "smart" autoplacement.
+// New windows are put at positions where they cover as few existing windows
+// as possible. A brute force algorithm is used, so it consumes quite a bit
+// of CPU time.
+#define SMART_PLACEMENT 1
+
 // set this to zero to remove the multiple-desktop code.  This will
 // make flwm about 20K smaller
 #define DESKTOPS 1
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/changelog /tmp/KfNDqvamm0/flwm-1.01/debian/changelog
--- /tmp/8FTwAYJlot/flwm-1.00/debian/changelog	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/changelog	2006-06-30 11:01:41.000000000 +0200
@@ -1,3 +1,15 @@
+flwm (1.01-1) unstable; urgency=low
+
+  * New upstream release
+    + This release catch the release of the Alt key again. Closes: #246089.
+    + The following patches were applied upstream (Thanks Bill Spitzak).
+      100_fl_filename_name 101_visible_focus 102_charstruct 103_man_typo
+      104_g++-4.1_warning 105_double_ampersand 201_background_color
+    + Add 100_double_ampersand to fix atypo in this release.
+  * debian/watch: added.
+
+ -- Bill Allombert <ballombe@debian.org>  Fri, 30 Jun 2006 01:17:06 +0200
+
 flwm (1.00-10) unstable; urgency=low
 
   * Add patch 104_g++-4.1_warning that fix five warnings.
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/100_double_ampersand.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/100_double_ampersand.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/100_double_ampersand.dpatch	1970-01-01 01:00:00.000000000 +0100
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/100_double_ampersand.dpatch	2006-06-30 11:01:41.000000000 +0200
@@ -0,0 +1 @@
+patching file Menu.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/100_fl_filename_name.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/100_fl_filename_name.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/100_fl_filename_name.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/100_fl_filename_name.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,2 +0,0 @@
-patching file main.C
-Hunk #1 succeeded at 351 (offset -1 lines).
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/101_visible_focus.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/101_visible_focus.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/101_visible_focus.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/101_visible_focus.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1 +0,0 @@
-patching file main.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/102_charstruct.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/102_charstruct.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/102_charstruct.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/102_charstruct.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1 +0,0 @@
-patching file Rotated.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/103_man_typo.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/103_man_typo.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/103_man_typo.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/103_man_typo.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1 +0,0 @@
-patching file flwm.1
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/104_g++-4.1_warning.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/104_g++-4.1_warning.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/104_g++-4.1_warning.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/104_g++-4.1_warning.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,3 +0,0 @@
-patching file Frame.C
-patching file Menu.C
-patching file Rotated.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/105_double_ampersand.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/105_double_ampersand.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/105_double_ampersand.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/105_double_ampersand.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1 +0,0 @@
-patching file Menu.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patched/201_background_color.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patched/201_background_color.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patched/201_background_color.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patched/201_background_color.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,2 +0,0 @@
-patching file Frame.C
-patching file Menu.C
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/00list /tmp/KfNDqvamm0/flwm-1.01/debian/patches/00list
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/00list	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/00list	2006-06-30 11:01:41.000000000 +0200
@@ -1,8 +1,2 @@
-100_fl_filename_name
-101_visible_focus
-102_charstruct
-103_man_typo
-104_g++-4.1_warning
-105_double_ampersand
+100_double_ampersand
 200_Debian_menu
-201_background_color
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/100_double_ampersand.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/100_double_ampersand.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/100_double_ampersand.dpatch	1970-01-01 01:00:00.000000000 +0100
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/100_double_ampersand.dpatch	2006-06-30 11:01:41.000000000 +0200
@@ -0,0 +1,19 @@
+#! /bin/sh /usr/share/dpatch/dpatch-run
+## 100_double_ampersand.dpatch by  <ballombe@debian.org>
+##
+## All lines beginning with `## DP:' are a description of the patch.
+## DP: fix handling of ampersand in titles in windows list.
+
+@DPATCH@
+diff -urNad flwm-1.01~/Menu.C flwm-1.01/Menu.C
+--- flwm-1.01~/Menu.C	2006-06-30 10:52:34.000000000 +0200
++++ flwm-1.01/Menu.C	2006-06-30 10:54:31.000000000 +0200
+@@ -98,7 +98,7 @@
+     char* t = buf;
+     while (t < buf+254 && *l) {
+       if (*l=='&') *t++ = *l;
+-      *t++ = *l;
++      *t++ = *l++;
+     }
+     *t = 0;
+     l = buf;
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/100_fl_filename_name.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/100_fl_filename_name.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/100_fl_filename_name.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/100_fl_filename_name.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,20 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 100_fl_filename_name.dpatch by Tommi Virtanen <tv@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Transition from fltk-1.0 to fltk-1.1.
-## DP: Applied upstream.
-
-@DPATCH@
-diff -urNad flwm-1.00~/main.C flwm-1.00/main.C
---- flwm-1.00~/main.C	2006-02-23 21:41:10.000000000 +0100
-+++ flwm-1.00/main.C	2006-02-23 21:41:39.000000000 +0100
-@@ -352,7 +352,7 @@
- }
- 
- int main(int argc, char** argv) {
--  program_name = filename_name(argv[0]);
-+  program_name = fl_filename_name(argv[0]);
-   int i; if (Fl::args(argc, argv, i, arg) < argc) Fl::error(
- "options are:\n"
- " -d[isplay] host:#.#\tX display & screen to use\n"
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/101_visible_focus.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/101_visible_focus.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/101_visible_focus.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/101_visible_focus.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,19 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 101_visible_focus.dpatch by Bill Allombert <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Restore fltk-1.0 focus behaviour
-## DP: (Applied upstream)
-
-@DPATCH@
-diff -urNad flwm-1.00~/main.C flwm-1.00/main.C
---- flwm-1.00~/main.C	2006-02-23 21:41:57.000000000 +0100
-+++ flwm-1.00/main.C	2006-02-23 21:42:21.000000000 +0100
-@@ -298,6 +298,7 @@
-   XFree((void *)wins);
- 
- #endif
-+  Fl::visible_focus(0);
- }
- 
- ////////////////////////////////////////////////////////////////
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/102_charstruct.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/102_charstruct.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/102_charstruct.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/102_charstruct.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,45 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 102_charstruct.dpatch by Tommi Virtanen <tv@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Support fonts for which fontstruct->per_char is NULL.
-## DP: (Applied upstream).
-
-@DPATCH@
-diff -urNad flwm-1.00~/Rotated.C flwm-1.00/Rotated.C
---- flwm-1.00~/Rotated.C	2006-02-23 21:42:31.000000000 +0100
-+++ flwm-1.00/Rotated.C	2006-02-23 21:43:03.000000000 +0100
-@@ -116,20 +116,27 @@
-     /* font needs rotation ... */
-     /* loop through each character ... */
-     for (ichar = min_char; ichar <= max_char; ichar++) {
-+      XCharStruct *charstruct;
- 
-       index = ichar-fontstruct->min_char_or_byte2;
-- 
-+
-+      if (fontstruct->per_char) {
-+	charstruct = &fontstruct->per_char[index];
-+      } else {
-+	charstruct = &fontstruct->min_bounds;
-+      }
-+
-       /* per char dimensions ... */
-       ascent =   rotfont->per_char[ichar].ascent = 
--	fontstruct->per_char[index].ascent;
-+	charstruct->ascent;
-       descent =  rotfont->per_char[ichar].descent = 
--	fontstruct->per_char[index].descent;
-+	charstruct->descent;
-       lbearing = rotfont->per_char[ichar].lbearing = 
--	fontstruct->per_char[index].lbearing;
-+	charstruct->lbearing;
-       rbearing = rotfont->per_char[ichar].rbearing = 
--	fontstruct->per_char[index].rbearing;
-+	charstruct->rbearing;
-       rotfont->per_char[ichar].width = 
--	fontstruct->per_char[index].width;
-+	charstruct->width;
- 
-       /* some space chars have zero body, but a bitmap can't have ... */
-       if (!ascent && !descent)   
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/103_man_typo.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/103_man_typo.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/103_man_typo.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/103_man_typo.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,19 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 103_man_typo.dpatch by  Bill Allombert <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Fix typo in man page.
-
-@DPATCH@
-diff -urNad flwm-1.00~/flwm.1 flwm-1.00/flwm.1
---- flwm-1.00~/flwm.1	2006-02-23 21:54:54.000000000 +0100
-+++ flwm-1.00/flwm.1	2006-02-23 21:55:39.000000000 +0100
-@@ -78,7 +78,7 @@
- 
- .SH MENU ITEMS
- 
--Flwm can launch programs from it's menu.  This is controlled by files
-+Flwm can launch programs from its menu.  This is controlled by files
- in the directory
- .B ~/.wmx
- (this was chosen to be compatible with wmx and wm2).
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/104_g++-4.1_warning.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/104_g++-4.1_warning.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/104_g++-4.1_warning.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/104_g++-4.1_warning.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,58 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 104_g++-4.1-warning.dpatch by Bill Allombert <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Fix 5 g++ -4.1 warnings
-
-@DPATCH@
-diff -urNad flwm-1.00~/Frame.C flwm-1.00/Frame.C
---- flwm-1.00~/Frame.C	2006-06-10 13:41:04.000000000 +0200
-+++ flwm-1.00/Frame.C	2006-06-10 13:41:08.000000000 +0200
-@@ -1681,15 +1681,15 @@
-   int format;
-   unsigned long n, extra;
-   int status;
--  void* prop;
-+  uchar* prop;
-   status = XGetWindowProperty(fl_display, w,
- 			      a, 0L, 256L, False, type, &realType,
--			      &format, &n, &extra, (uchar**)&prop);
-+			      &format, &n, &extra, &prop);
-   if (status != Success) return 0;
-   if (!prop) return 0;
-   if (!n) {XFree(prop); return 0;}
-   if (np) *np = (int)n;
--  return prop;
-+  return (void *)prop;
- }
- 
- int Frame::getIntProperty(Atom a, Atom type, int deflt) const {
-diff -urNad flwm-1.00~/Menu.C flwm-1.00/Menu.C
---- flwm-1.00~/Menu.C	2006-06-10 13:41:04.000000000 +0200
-+++ flwm-1.00/Menu.C	2006-06-10 13:41:08.000000000 +0200
-@@ -246,8 +246,8 @@
-   if (fork() == 0) {
-     if (fork() == 0) {
-       close(ConnectionNumber(fl_display));
--      if (name == xtermname) execlp(name, name, "-ut", 0);
--      else execl(name, name, 0);
-+      if (name == xtermname) execlp(name, name, "-ut", NULL);
-+      else execl(name, name, NULL);
-       fprintf(stderr, "flwm: can't run %s, %s\n", name, strerror(errno));
-       XBell(fl_display, 70);
-       exit(1);
-diff -urNad flwm-1.00~/Rotated.C flwm-1.00/Rotated.C
---- flwm-1.00~/Rotated.C	2006-06-10 13:41:07.000000000 +0200
-+++ flwm-1.00/Rotated.C	2006-06-10 13:41:41.000000000 +0200
-@@ -242,9 +242,9 @@
-   }
-   
-   for (ichar = 0; ichar < min_char; ichar++)
--    rotfont->per_char[ichar] = rotfont->per_char['?'];
-+    rotfont->per_char[ichar] = rotfont->per_char[(int)'?'];
-   for (ichar = max_char+1; ichar < 256; ichar++)
--    rotfont->per_char[ichar] = rotfont->per_char['?'];
-+    rotfont->per_char[ichar] = rotfont->per_char[(int)'?'];
- 
-   /* free pixmap and GC ... */
-   XFreePixmap(dpy, canvas);
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/105_double_ampersand.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/105_double_ampersand.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/105_double_ampersand.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/105_double_ampersand.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,48 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 105_double_ampersand.dpatch by Bill Allombert <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Handle & in window titles correctly in the windows list.
-
-@DPATCH@
-diff -urNad flwm-1.00~/Menu.C flwm-1.00/Menu.C
---- flwm-1.00~/Menu.C	2006-03-24 00:02:57.000000000 +0100
-+++ flwm-1.00/Menu.C	2006-03-24 00:03:18.000000000 +0100
-@@ -20,6 +20,24 @@
- #include <dirent.h>
- #include <sys/stat.h>
- 
-+static char *double_ampersand(const char *s)
-+{
-+  long i,l;
-+  for(i=0,l=0;s[i];i++)
-+    if (s[i]=='&')
-+      l++;
-+  char *c = new (char [l+i+1]);
-+  for(i=0,l=0;s[i];i++)
-+  {
-+    c[l++]=s[i];
-+    if (s[i]=='&')
-+      c[l++]=s[i];
-+  }
-+  c[l]=0;
-+  return c;
-+}
-+
-+
- // it is possible for the window to be deleted or withdrawn while
- // the menu is up.  This will detect that case (with reasonable
- // reliability):
-@@ -90,8 +108,11 @@
-   }
-   fl_font(o->font, o->size);
-   fl_color((Fl_Color)o->color);
--  const char* l = f->label(); if (!l) l = "unnamed";
-+  const char* l = f->label(); 
-+  if (!l) l = "unnamed";
-+  else l = double_ampersand(f->label());
-   fl_draw(l, X+MENU_ICON_W+3, Y, W-MENU_ICON_W-3, H, align);
-+  delete l;
- }
- 
- static void
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/200_Debian_menu.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/200_Debian_menu.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/200_Debian_menu.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/200_Debian_menu.dpatch	2006-06-30 11:01:41.000000000 +0200
@@ -5,10 +5,10 @@
 ## DP: Add Debian menu support.
 
 @DPATCH@
-diff -urNad flwm-1.00~/Menu.C flwm-1.00/Menu.C
---- flwm-1.00~/Menu.C	2006-06-10 22:22:59.000000000 +0200
-+++ flwm-1.00/Menu.C	2006-06-10 22:23:00.000000000 +0200
-@@ -395,7 +395,11 @@
+diff -urNad flwm-1.01~/Menu.C flwm-1.01/Menu.C
+--- flwm-1.01~/Menu.C	2006-06-30 09:02:01.000000000 +0200
++++ flwm-1.01/Menu.C	2006-06-30 09:02:05.000000000 +0200
+@@ -393,7 +393,11 @@
    strcpy(path, home);
    if (path[strlen(path)-1] != '/') strcat(path, "/");
    strcat(path, ".wmx/");
@@ -21,9 +21,9 @@
    if (st.st_mtime == wmx_time) return;
    wmx_time = st.st_mtime;
    num_wmx = 0;
-diff -urNad flwm-1.00~/flwm.1 flwm-1.00/flwm.1
---- flwm-1.00~/flwm.1	2006-06-10 22:22:59.000000000 +0200
-+++ flwm-1.00/flwm.1	2006-06-10 22:23:00.000000000 +0200
+diff -urNad flwm-1.01~/flwm.1 flwm-1.01/flwm.1
+--- flwm-1.01~/flwm.1	2006-06-30 09:02:01.000000000 +0200
++++ flwm-1.01/flwm.1	2006-06-30 09:02:05.000000000 +0200
 @@ -102,10 +102,13 @@
  chmod +x !*
  .fi
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/201_background_color.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/201_background_color.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/201_background_color.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/201_background_color.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,57 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 201_background_color.dpatch by Bill Allombert <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: Fix -fg and -bg options
-
-@DPATCH@
-diff -urNad flwm-1.00~/Frame.C flwm-1.00/Frame.C
---- flwm-1.00~/Frame.C	2006-06-10 22:24:58.000000000 +0200
-+++ flwm-1.00/Frame.C	2006-06-10 22:25:00.000000000 +0200
-@@ -88,6 +88,7 @@
-   min_w_button.callback(button_cb_static);
-   end();
-   box(FL_NO_BOX); // relies on background color erasing interior
-+  labelcolor(FL_FOREGROUND_COLOR);
-   next = first;
-   first = this;
- 
-@@ -674,7 +675,7 @@
-     XSetWindowAttributes a;
-     a.background_pixel = fl_xpixel(FL_SELECTION_COLOR);
-     XChangeWindowAttributes(fl_display, fl_xid(this), CWBackPixel, &a);
--    labelcolor(contrast(FL_BLACK, FL_SELECTION_COLOR));
-+    labelcolor(contrast(FL_FOREGROUND_COLOR, FL_SELECTION_COLOR));
-     XClearArea(fl_display, fl_xid(this), 2, 2, w()-4, h()-4, 1);
- #else
- #if defined(SHOW_CLOCK)
-@@ -694,7 +695,7 @@
-     XSetWindowAttributes a;
-     a.background_pixel = fl_xpixel(FL_GRAY);
-     XChangeWindowAttributes(fl_display, fl_xid(this), CWBackPixel, &a);
--    labelcolor(FL_BLACK);
-+    labelcolor(FL_FOREGROUND_COLOR);
-     XClearArea(fl_display, fl_xid(this), 2, 2, w()-4, h()-4, 1);
- #else
- #if defined(SHOW_CLOCK)
-diff -urNad flwm-1.00~/Menu.C flwm-1.00/Menu.C
---- flwm-1.00~/Menu.C	2006-06-10 22:24:59.000000000 +0200
-+++ flwm-1.00/Menu.C	2006-06-10 22:25:00.000000000 +0200
-@@ -99,7 +99,7 @@
-       if (h < 3) h = 3;
-       if (y+h > SCREEN_H) y = SCREEN_H-h;
-       if (y < 0) y = 0;
--      fl_color(FL_BLACK);
-+      fl_color(FL_FOREGROUND_COLOR);
-       if (c->state() == ICONIC)
- 	fl_rect(X+x+SCREEN_DX, Y+y+SCREEN_DX, w, h);
-       else
-@@ -304,7 +304,7 @@
-   m.shortcut(0);
-   m.labelfont(MENU_FONT_SLOT);
-   m.labelsize(MENU_FONT_SIZE);
--  m.labelcolor(FL_BLACK);
-+  m.labelcolor(FL_FOREGROUND_COLOR);
- }
- 
- #if WMX_MENU_ITEMS
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/patches/202_background_color_2.dpatch /tmp/KfNDqvamm0/flwm-1.01/debian/patches/202_background_color_2.dpatch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/patches/202_background_color_2.dpatch	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/patches/202_background_color_2.dpatch	1970-01-01 01:00:00.000000000 +0100
@@ -1,92 +0,0 @@
-#! /bin/sh /usr/share/dpatch/dpatch-run
-## 203_background_color.dpatch by  <ballombe@debian.org>
-##
-## All lines beginning with `## DP:' are a description of the patch.
-## DP: fix the -fg -bg, -bg2 options.
-
-@DPATCH@
-diff -urNad flwm-1.00~/Menu.C flwm-1.00/Menu.C
---- flwm-1.00~/Menu.C	2006-02-23 21:32:53.000000000 +0100
-+++ flwm-1.00/Menu.C	2006-02-23 21:36:32.000000000 +0100
-@@ -172,10 +172,14 @@
-     new_desktop_input = new Fl_Input(10,30,170,25,"New desktop name:");
-     new_desktop_input->align(FL_ALIGN_TOP_LEFT);
-     new_desktop_input->labelfont(FL_BOLD);
-+    new_desktop_input->labelcolor(FL_FOREGROUND_COLOR);
-+      
-     Fl_Return_Button* b = new Fl_Return_Button(100,60,80,20,"OK");
-     b->callback(new_desktop_ok_cb);
-+    b->labelcolor(FL_FOREGROUND_COLOR);
-     Fl_Button* b2 = new Fl_Button(10,60,80,20,"Cancel");
-     b2->callback(cancel_cb);
-+    b2->labelcolor(FL_FOREGROUND_COLOR);
-     w->set_non_modal();
-     w->end();
-   }
-@@ -217,10 +221,13 @@
-     w = new FrameWindow(190,90);
-     Fl_Box* l = new Fl_Box(0, 0, 190, 60, "Really log out?");
-     l->labelfont(FL_BOLD);
-+    l->labelcolor(FL_FOREGROUND_COLOR);
-     Fl_Return_Button* b = new Fl_Return_Button(100,60,80,20,"OK");
-     b->callback(exit_cb);
-+    b->labelcolor(FL_FOREGROUND_COLOR);
-     Fl_Button* b2 = new Fl_Button(10,60,80,20,"Cancel");
-     b2->callback(cancel_cb);
-+    b2->labelcolor(FL_FOREGROUND_COLOR);
-     w->set_non_modal();
-     w->end();
-   }
-@@ -280,10 +287,10 @@
-   m.label(data);
-   m.flags = 0;
-   m.labeltype(FL_NORMAL_LABEL);
-+  m.labelcolor(FL_FOREGROUND_COLOR);
-   m.shortcut(0);
-   m.labelfont(MENU_FONT_SLOT);
-   m.labelsize(MENU_FONT_SIZE);
--  m.labelcolor(FL_FOREGROUND_COLOR);
- }
- 
- #if WMX_MENU_ITEMS
-@@ -513,6 +520,7 @@
-       if (c->state() == UNMAPPED || c->transient_for()) continue;
-       init(menu[n],(char*)c);
-       menu[n].labeltype(FRAME_LABEL);
-+      menu[n].labelcolor(FL_FOREGROUND_COLOR);
-       menu[n].callback(frame_callback, c);
-       if (is_active_frame(c)) preset = menu+n;
-       n++;
-@@ -542,6 +550,7 @@
- 	if (c->desktop() == d || !c->desktop() && d == Desktop::current()) {
- 	  init(menu[n],(char*)c);
- 	  menu[n].labeltype(FRAME_LABEL);
-+	  menu[n].labelcolor(FL_FOREGROUND_COLOR);
- 	  menu[n].callback(d == Desktop::current() ?
- 			   frame_callback : move_frame_callback, c);
- 	  if (d == Desktop::current() && is_active_frame(c)) preset = menu+n;
-@@ -589,7 +598,10 @@
-       if (one_desktop)
- #endif
- 	if (!level)
-+        {
- 	  menu[n].labeltype(TEXT_LABEL);
-+	  menu[n].labelcolor(FL_FOREGROUND_COLOR);
-+        }
- 
-       int	nextlev = (i==num_wmx-1)?0:strspn(wmxlist[i+1], "/")-1;
-       if (nextlev < level) {
-@@ -621,8 +633,11 @@
-   if (one_desktop)
- #endif
-     // fix the menus items so they are indented to align with window names:
--    while (menu[n].label()) menu[n++].labeltype(TEXT_LABEL);
--
-+    while (menu[n].label()) 
-+    {
-+      menu[n].labelcolor(FL_FOREGROUND_COLOR);
-+      menu[n++].labeltype(TEXT_LABEL);
-+    }
-   const Fl_Menu_Item* picked =
-     menu->popup(Fl::event_x(), Fl::event_y(), 0, preset);
-   if (picked && picked->callback()) picked->do_callback(0);
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/debian/watch /tmp/KfNDqvamm0/flwm-1.01/debian/watch
--- /tmp/8FTwAYJlot/flwm-1.00/debian/watch	1970-01-01 01:00:00.000000000 +0100
+++ /tmp/KfNDqvamm0/flwm-1.01/debian/watch	2006-06-30 11:01:41.000000000 +0200
@@ -0,0 +1,3 @@
+# Site				Directory	Pattern		Version	Script
+version=2
+http://flwm.sourceforge.net/flwm-(.*)\.tgz debian uupdate
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/flwm.1 /tmp/KfNDqvamm0/flwm-1.01/flwm.1
--- /tmp/8FTwAYJlot/flwm-1.00/flwm.1	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/flwm.1	2006-06-30 11:01:41.000000000 +0200
@@ -184,14 +184,14 @@
 the keyboard, use left arrow to go to the desktop names, move up and
 down to the other desktop).
 
-If a desktop is empty you can delete it.  It's sub menu will show
+If a desktop is empty you can delete it.  Its sub menu will show
 .B delete this desktop.
 Pick that and the desktop is gone.
 
 .B Sticky
 is a special "desktop": windows on it appear on all desktops.  To make
 a window "sticky" switch to the Sticky desktop and pick the window off
-it's current desktop (thus "moving" it to the Sticky desktop).  To
+its current desktop (thus "moving" it to the Sticky desktop).  To
 "unstick" a window go to another desktop and pick the window off the
 sticky desktop menu.
 
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/flwm_wmconfig /tmp/KfNDqvamm0/flwm-1.01/flwm_wmconfig
--- /tmp/8FTwAYJlot/flwm-1.00/flwm_wmconfig	1999-04-26 21:09:10.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/flwm_wmconfig	2000-09-19 18:38:37.000000000 +0200
@@ -16,7 +16,9 @@
 	set name ""
 	set exec ""
 	while {[gets $f list]>=0} {
-	    if [llength $list]<3 continue
+	    set n 0
+	    catch {set n [llength $list]}
+	    if $n<3 continue
 	    set tag [lindex $list 1]
 	    set value [lrange $list 2 1000]
 	    if [llength $value]==1 {set value [lindex $value 0]}
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Frame.C /tmp/KfNDqvamm0/flwm-1.01/Frame.C
--- /tmp/8FTwAYJlot/flwm-1.00/Frame.C	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Frame.C	2006-06-29 08:08:35.000000000 +0200
@@ -8,6 +8,7 @@
 #include <FL/fl_draw.H>
 #include "Rotated.H"
 
+
 static Atom wm_state = 0;
 static Atom wm_change_state;
 static Atom wm_protocols;
@@ -63,7 +64,7 @@
 // passed for an already-existing window when the window manager is
 // starting up.  If so we don't want to alter the state, size, or
 // position.  If null than this is a MapRequest of a new window.
-Frame::Frame(Window window, XWindowAttributes* existing) :
+Frame::Frame(XWindow window, XWindowAttributes* existing) :
   Fl_Window(0,0),
   window_(window),
   state_flags_(0),
@@ -78,6 +79,9 @@
   max_w_button(BUTTON_LEFT,BUTTON_TOP+BUTTON_H,BUTTON_W,BUTTON_H,"w"),
   min_w_button(BUTTON_LEFT,BUTTON_TOP+2*BUTTON_H,BUTTON_W,BUTTON_H,"W")
 {
+#if FL_MAJOR_VERSION > 1
+  clear_double_buffer();
+#endif
   close_button.callback(button_cb_static);
   iconize_button.callback(button_cb_static);
   max_h_button.type(FL_TOGGLE_BUTTON);
@@ -224,20 +228,9 @@
   show_hide_buttons();
 
   if (autoplace && !existing && !(transient_for() && (x() || y()))) {
-    // autoplacement (stupid version for now)
-    x(Root->x()+(Root->w()-w())/2);
-    y(Root->y()+(Root->h()-h())/2);
-    // move it until it does not hide any existing windows:
-    const int delta = TITLE_WIDTH+LEFT;
-    for (Frame* f = next; f; f = f->next) {
-      if (f->x()+delta > x() && f->y()+delta > y() &&
-	  f->x()+f->w()-delta < x()+w() && f->y()+f->h()-delta < y()+h()) {
-	x(max(x(),f->x()+delta));
-	y(max(y(),f->y()+delta));
-	f = this;
-      }
-    }
+    place_window();
   }
+
   // move window so contents and border are visible:
   x(force_x_onscreen(x(), w()));
   y(force_y_onscreen(y(), h()));
@@ -261,7 +254,8 @@
   sattr.bit_gravity = NorthWestGravity;
   sattr.override_redirect = 1;
   sattr.background_pixel = fl_xpixel(FL_GRAY);
-  Fl_X::set_xid(this, XCreateWindow(fl_display, fl_xid(Root),
+  Fl_X::set_xid(this, XCreateWindow(fl_display,
+				    RootWindow(fl_display,fl_screen),
 			     x(), y(), w(), h(), 0,
 			     fl_visual->depth,
 			     InputOutput,
@@ -278,15 +272,140 @@
   sendConfigureNotify(); // many apps expect this even if window size unchanged
 
 #if CLICK_RAISES || CLICK_TO_TYPE
-  XGrabButton(fl_display, AnyButton, AnyModifier, window, False,
-	      ButtonPressMask, GrabModeSync, GrabModeAsync, None, None);
+  if (!dont_set_event_mask)
+    XGrabButton(fl_display, AnyButton, AnyModifier, window, False,
+		ButtonPressMask, GrabModeSync, GrabModeAsync, None, None);
 #endif
 
   if (state_ == NORMAL) {
     XMapWindow(fl_display, fl_xid(this));
     if (!existing) activate_if_transient();
   }
+  set_visible();
+}
+
+#if SMART_PLACEMENT
+// Helper functions for "smart" window placement.
+int overlap1(int p1, int l1, int p2, int l2) {
+  int ret = 0;
+  if(p1 <= p2 && p2 <= p1 + l1) {
+    ret = min(p1 + l1 - p2, l2);
+  } else if (p2 <= p1 && p1 <= p2 + l2) {
+    ret = min(p2 + l2 - p1, l1);
+  } 
+  return ret;
+}
+
+int overlap(int x1, int y1, int w1, int h1, int x2, int y2, int w2, int h2) {
+  return (overlap1(x1, w1, x2, w2) * overlap1(y1, h1, y2, h2));
+}
+
+// Compute the overlap with existing windows.
+// For normal windows the overlapping area is taken into account plus a 
+// constant value for every overlapping window.
+// The active window counts twice.
+// For iconic windows half the overlapping area is taken into account.
+int getOverlap(int x, int y, int w, int h, Frame *first, Frame *self) {
+  int ret = 0;
+  short state;
+  for (Frame* f = first; f; f = f->next) {
+    if (f != self) {
+      state = f->state();
+      if (state == NORMAL || state == ICONIC) {
+	int o = overlap(x, y, w, h, f->x(), f->y(), f->w(), f->h());
+	if (state == NORMAL) {
+	  ret = ret + o + (o>0?40000:0) + (o * f->active());
+	} else if (state == ICONIC) {
+	  ret = ret + o/2;
+	}
+      }
+    }
+  }
+  return ret;
+}
+
+// autoplacement (brute force version for now)
+void Frame::place_window() {
+  int min_overlap = -1;
+  int tmp_x, tmp_y, tmp_o;
+  int best_x = 0;
+  int best_y = 0;
+  int _w = w();
+  int _h = h();
+  int max_x = Root->x() + Root->w();
+  int max_y = Root->y() + Root->h();
+  
+  Frame *f1 = Frame::first;
+  for(int i=0;; i++) {
+    if (i==0) {
+      tmp_x = 0;
+    } else if (i==1) {
+      tmp_x = max_x - _w;
+    } else {
+      if (f1 == this) {
+	f1 = f1->next;
+      }
+      if (!f1) {
+	break;
+      }
+      tmp_x = f1->x() + f1->w();
+      f1 = f1->next;
+    }
+    Frame *f2 = Frame::first;
+    for(int j=0;; j++) {
+      if (j==0) {
+	tmp_y = 0;
+      } else if (j==1) {
+	tmp_y = max_y - _h;
+      } else {
+	if (f2 == this) {
+	  f2 = f2->next;
+	}
+	if (!f2) {
+	  break;
+	}
+	tmp_y = f2->y() + f2->h();
+	f2 = f2->next;
+      }
+
+      if ((tmp_x + _w <= max_x) && (tmp_y + _h <= max_y)) {
+	tmp_o = getOverlap(tmp_x, tmp_y, _w, _h, Frame::first, this);
+	if(tmp_o < min_overlap || min_overlap < 0) {
+	  best_x = tmp_x;
+	  best_y = tmp_y;
+	  min_overlap = tmp_o;
+	  if (min_overlap == 0) {
+	    break;
+	  }
+	}
+      }
+    }
+    if (min_overlap == 0) {
+      break;
+    } 
+  }
+  x(best_x);
+  y(best_y);
+}
+
+#else
+
+// autoplacement (stupid version for now)
+void Frame::place_window() {
+  x(Root->x()+(Root->w()-w())/2);
+  y(Root->y()+(Root->h()-h())/2);
+  // move it until it does not hide any existing windows:
+  const int delta = TITLE_WIDTH+LEFT;
+    for (Frame* f = next; f; f = f->next) {
+      if (f->x()+delta > x() && f->y()+delta > y() &&
+	  f->x()+f->w()-delta < x()+w() && f->y()+f->h()-delta < y()+h()) {
+	x(max(x(),f->x()+delta));
+	y(max(y(),f->y()+delta));
+	f = this;
+      }
+    }
 }
+#endif
 
 // modify the passed X & W to a legal horizontal window position
 int Frame::force_x_onscreen(int X, int W) {
@@ -334,10 +453,12 @@
   // a legal state value to this location:
   state_ = UNMAPPED;
 
+#if FL_MAJOR_VERSION < 2
   // fix fltk bug:
   fl_xfocus = 0;
   fl_xmousewin = 0;
   Fl::focus_ = 0;
+#endif
 
   // remove any pointers to this:
   Frame** cp; for (cp = &first; *cp; cp = &((*cp)->next))
@@ -555,7 +676,7 @@
   // see if they set "input hint" to non-zero:
   // prop[3] should be nonzero but the only example of this I have
   // found is Netscape 3.0 and it sets it to zero...
-  if (!shown() && (prop[0]&4) /*&& prop[3]*/) set_flag(MODAL);
+  if (!shown() && (prop[0]&4) /*&& prop[3]*/) set_flag(::MODAL);
 
   // see if it is forcing the iconize button back on.  This makes
   // transient_for act like group instead...
@@ -579,7 +700,7 @@
     delete[] window_Colormaps;
   }
   int n;
-  Window* cw = (Window*)getProperty(wm_colormap_windows, XA_WINDOW, &n);
+  XWindow* cw = (XWindow*)getProperty(wm_colormap_windows, XA_WINDOW, &n);
   if (cw) {
     colormapWinCount = n;
     colormapWindows = cw;
@@ -645,7 +766,7 @@
 int Frame::activate(int warp) {
   // see if a modal & newer window is up:
   for (Frame* c = first; c && c != this; c = c->next)
-    if (c->flag(MODAL) && c->transient_for() == this)
+    if (c->flag(::MODAL) && c->transient_for() == this)
       if (c->activate(warp)) return 1;
   // ignore invisible windows:
   if (state() != NORMAL || w() <= dwidth) return 0;
@@ -671,14 +792,14 @@
   if (active_ != this) {
     if (active_) active_->deactivate();
     active_ = this;
-#if defined(ACTIVE_COLOR)
+#ifdef ACTIVE_COLOR
     XSetWindowAttributes a;
     a.background_pixel = fl_xpixel(FL_SELECTION_COLOR);
     XChangeWindowAttributes(fl_display, fl_xid(this), CWBackPixel, &a);
     labelcolor(contrast(FL_FOREGROUND_COLOR, FL_SELECTION_COLOR));
     XClearArea(fl_display, fl_xid(this), 2, 2, w()-4, h()-4, 1);
 #else
-#if defined(SHOW_CLOCK)
+#ifdef SHOW_CLOCK
     redraw();
 #endif
 #endif
@@ -691,14 +812,14 @@
 // this private function should only be called by constructor and if
 // the window is active():
 void Frame::deactivate() {
-#if defined(ACTIVE_COLOR)
+#ifdef ACTIVE_COLOR
     XSetWindowAttributes a;
     a.background_pixel = fl_xpixel(FL_GRAY);
     XChangeWindowAttributes(fl_display, fl_xid(this), CWBackPixel, &a);
     labelcolor(FL_FOREGROUND_COLOR);
     XClearArea(fl_display, fl_xid(this), 2, 2, w()-4, h()-4, 1);
 #else
-#if defined(SHOW_CLOCK)
+#ifdef SHOW_CLOCK
     redraw();
 #endif
 #endif
@@ -738,9 +859,9 @@
   switch (newstate) {
   case UNMAPPED:
     throw_focus();
-    set_state_flag(IGNORE_UNMAP);
     XUnmapWindow(fl_display, fl_xid(this));
-    XUnmapWindow(fl_display, window_);
+    //set_state_flag(IGNORE_UNMAP);
+    //XUnmapWindow(fl_display, window_);
     XRemoveFromSaveSet(fl_display, window_);
     break;
   case NORMAL:
@@ -754,9 +875,9 @@
       XAddToSaveSet(fl_display, window_);
     } else if (oldstate == NORMAL) {
       throw_focus();
-      set_state_flag(IGNORE_UNMAP);
       XUnmapWindow(fl_display, fl_xid(this));
-      XUnmapWindow(fl_display, window_);
+      //set_state_flag(IGNORE_UNMAP);
+      //XUnmapWindow(fl_display, window_);
     } else {
       return; // don't setStateProperty IconicState multiple times
     }
@@ -906,10 +1027,10 @@
     int minh = (nh < h()) ? nh : h();
     XClearArea(fl_display, fl_xid(this), 0, minh-BOTTOM, w(), BOTTOM, 1);
     // see if label or close box moved, erase the minimum area:
-    int old_label_y = label_y;
-    int old_label_h = label_h;
+//     int old_label_y = label_y;
+//     int old_label_h = label_h;
     h(nh); show_hide_buttons();
-#ifdef SHOW_CLOCK
+#if 1 //def SHOW_CLOCK
     int t = label_y + 3; // we have to clear the entire label area
 #else
     int t = nh;
@@ -1076,6 +1197,12 @@
 
 // make sure fltk does not try to set the window size:
 void Frame::resize(int, int, int, int) {}
+// For fltk2.0:
+void Frame::layout() {
+#if FL_MAJOR_VERSION>1 
+  layout_damage(0); // actually this line is not needed in newest cvs fltk2.0
+#endif
+}
 
 ////////////////////////////////////////////////////////////////
 
@@ -1111,19 +1238,28 @@
 
 ////////////////////////////////////////////////////////////////
 // Drawing code:
+#if FL_MAJOR_VERSION>1
+# include <fltk/Box.h>
+#endif
 
 void Frame::draw() {
   if (flag(NO_BORDER)) return;
   if (!flag(THIN_BORDER)) Fl_Window::draw();
   if (damage() != FL_DAMAGE_CHILD) {
-#if ACTIVE_COLOR
+#ifdef ACTIVE_COLOR
     fl_frame2(active() ? "AAAAJJWW" : "AAAAJJWWNNTT",0,0,w(),h());
     if (active()) {
       fl_color(FL_GRAY_RAMP+('N'-'A'));
       fl_xyline(2, h()-3, w()-3, 2);
     }
 #else
+# if FL_MAJOR_VERSION>1
+    static fltk::FrameBox framebox(0,"AAAAJJWWNNTT");
+    drawstyle(style(),fltk::INVISIBLE); // INVISIBLE = draw edge only
+    framebox.draw(Rectangle(w(),h()));
+# else
     fl_frame("AAAAWWJJTTNN",0,0,w(),h());
+# endif
 #endif
     if (!flag(THIN_BORDER) && label_h > 3) {
 #ifdef SHOW_CLOCK
@@ -1169,39 +1305,48 @@
 #endif
 
 void FrameButton::draw() {
+#if FL_MAJOR_VERSION>1
+  const int x = value()?1:0;
+  const int y = x;
+  drawstyle(style(),flags()|fltk::OUTPUT);
+  FL_UP_BOX->draw(Rectangle(w(),h()));
+#else
+  const int x = this->x();
+  const int y = this->y();
   Fl_Widget::draw_box(value() ? FL_DOWN_FRAME : FL_UP_FRAME, FL_GRAY);
+#endif
   fl_color(parent()->labelcolor());
   switch (label()[0]) {
   case 'W':
 #if MINIMIZE_ARROW
-    fl_line (x()+2,y()+(h())/2,x()+w()-4,y()+h()/2);
-    fl_line (x()+2,y()+(h())/2,x()+2+4,y()+h()/2+4);
-    fl_line (x()+2,y()+(h())/2,x()+2+4,y()+h()/2-4);
+    fl_line (x+2,y+(h())/2,x+w()-4,y+h()/2);
+    fl_line (x+2,y+(h())/2,x+2+4,y+h()/2+4);
+    fl_line (x+2,y+(h())/2,x+2+4,y+h()/2-4);
 #else
-    fl_rect(x()+(h()-7)/2,y()+3,2,h()-6);
+    fl_rect(x+(h()-7)/2,y+3,2,h()-6);
 #endif
     return;
   case 'w':
-    fl_rect(x()+2,y()+(h()-7)/2,w()-4,7);
+    fl_rect(x+2,y+(h()-7)/2,w()-4,7);
     return;
   case 'h':
-    fl_rect(x()+(h()-7)/2,y()+2,7,h()-4);
+    fl_rect(x+(h()-7)/2,y+2,7,h()-4);
     return;
   case 'X':
 #if CLOSE_X
-    fl_line(x()+2,y()+3,x()+w()-5,y()+h()-4);
-    fl_line(x()+3,y()+3,x()+w()-4,y()+h()-4);
-    fl_line(x()+2,y()+h()-4,x()+w()-5,y()+3);
-    fl_line(x()+3,y()+h()-4,x()+w()-4,y()+3);
+    fl_line(x+2,y+3,x+w()-5,y+h()-4);
+    fl_line(x+3,y+3,x+w()-4,y+h()-4);
+    fl_line(x+2,y+h()-4,x+w()-5,y+3);
+    fl_line(x+3,y+h()-4,x+w()-4,y+3);
 #endif
 #if CLOSE_HITTITE_LIGHTNING
-    fl_arc(x()+3,y()+3,w()-6,h()-6,0,360);
-    fl_line(x()+7,y()+3, x()+7,y()+11);
+    fl_arc(x+3,y+3,w()-6,h()-6,0,360);
+    fl_line(x+7,y+3, x+7,y+11);
 #endif
     return;
   case 'i':
 #if ICONIZE_BOX
-    fl_rect(x()+w()/2-1,y()+h()/2-1,3,3);
+    fl_rect(x+w()/2-1,y+h()/2-1,3,3);
 #endif
     return;
   }
@@ -1320,6 +1465,9 @@
     c = FL_CURSOR_NESW;
     break;
   }
+#if FL_MAJOR_VERSION>1
+  cursor(c);
+#else
   static Frame* previous_frame;
   static Fl_Cursor previous_cursor;
   if (this != previous_frame || c != previous_cursor) {
@@ -1327,6 +1475,7 @@
     previous_cursor = c;
     cursor(c, CURSOR_FG_SLOT, CURSOR_BG_SLOT);
   }
+#endif
 }
 
 #ifdef AUTO_RAISE
@@ -1348,10 +1497,17 @@
 int Frame::handle(int e) {
   static int what, dx, dy, ix, iy, iw, ih;
   // see if child widget handles event:
-  if (Fl_Window::handle(e) && e != FL_ENTER && e != FL_MOVE) {
+#if FL_MAJOR_VERSION > 1
+  if (fltk::Group::handle(e) && e != FL_ENTER && e != FL_MOVE) {
+    if (e == FL_PUSH) set_cursor(-1);
+    return 1;
+  }
+#else
+  if (Fl_Group::handle(e) && e != FL_ENTER && e != FL_MOVE) {
     if (e == FL_PUSH) set_cursor(-1);
     return 1;
   }
+#endif
   switch (e) {
 
   case FL_SHOW:
@@ -1381,42 +1537,33 @@
 #endif
     goto GET_CROSSINGS;
 
-  case 0:
+  case FL_MOVE:
   GET_CROSSINGS:
     // set cursor_inside to true when the mouse is inside a window
     // set it false when mouse is on a frame or outside a window.
     // fltk mangles the X enter/leave events, we need the original ones:
 
     switch (fl_xevent->type) {
-    case EnterNotify:
+    case LeaveNotify:
+      if (fl_xevent->xcrossing.detail == NotifyInferior) {
+	// cursor moved from frame to interior
+	cursor_inside = this;
+	break;
+      } else {
+	// cursor moved to another window
+	return 1;
+      }
 
+    case EnterNotify:
       // see if cursor skipped over frame and directly to interior:
       if (fl_xevent->xcrossing.detail == NotifyVirtual ||
 	  fl_xevent->xcrossing.detail == NotifyNonlinearVirtual)
 	cursor_inside = this;
-
       else {
 	// cursor is now pointing at frame:
 	cursor_inside = 0;
       }
-
-      // fall through to FL_MOVE:
-      break;
-
-    case LeaveNotify:
-      if (fl_xevent->xcrossing.detail == NotifyInferior) {
-	// cursor moved from frame to interior
-	cursor_inside = this;
-	set_cursor(-1);
-	return 1;
-      }
-      return 1;
-
-    default:
-      return 0; // other X event we don't understand
     }
-
-  case FL_MOVE:
     if (Fl::belowmouse() != this || cursor_inside == this)
       set_cursor(-1);
     else
@@ -1578,9 +1725,10 @@
 
   case UnmapNotify: {
     const XUnmapEvent* e = &(ei->xunmap);
-    if (e->from_configure);
-    else if (state_flags_&IGNORE_UNMAP) clear_state_flag(IGNORE_UNMAP);
-    else state(UNMAPPED);
+    if (e->window == window_ && !e->from_configure) {
+      if (state_flags_&IGNORE_UNMAP) clear_state_flag(IGNORE_UNMAP);
+      else state(UNMAPPED);
+    }
     return 1;}
 
   case DestroyNotify: {
@@ -1677,7 +1825,7 @@
   return ::getProperty(window_, a, type, np);
 }
 
-void* getProperty(Window w, Atom a, Atom type, int* np) {
+void* getProperty(XWindow w, Atom a, Atom type, int* np) {
   Atom realType;
   int format;
   unsigned long n, extra;
@@ -1690,14 +1838,14 @@
   if (!prop) return 0;
   if (!n) {XFree(prop); return 0;}
   if (np) *np = (int)n;
-  return (void *)prop;
+  return (void*)prop;
 }
 
 int Frame::getIntProperty(Atom a, Atom type, int deflt) const {
   return ::getIntProperty(window_, a, type, deflt);
 }
 
-int getIntProperty(Window w, Atom a, Atom type, int deflt) {
+int getIntProperty(XWindow w, Atom a, Atom type, int deflt) {
   void* prop = getProperty(w, a, type);
   if (!prop) return deflt;
   int r = int(*(long*)prop);
@@ -1705,7 +1853,7 @@
   return r;
 }
 
-void setProperty(Window w, Atom a, Atom type, int v) {
+void setProperty(XWindow w, Atom a, Atom type, int v) {
   long prop = v;
   XChangeProperty(fl_display, w, a, type, 32, PropModeReplace, (uchar*)&prop,1);
 }
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Frame.H /tmp/KfNDqvamm0/flwm-1.01/Frame.H
--- /tmp/8FTwAYJlot/flwm-1.00/Frame.H	1999-08-24 22:59:35.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Frame.H	2003-12-16 16:15:40.000000000 +0100
@@ -9,6 +9,9 @@
 #include <FL/Fl_Window.H>
 #include <FL/Fl_Button.H>
 #include <FL/x.H>
+#if FL_MAJOR_VERSION<2
+# define XWindow Window
+#endif
 
 // The state is an enumeration of reasons why the window may be invisible.
 // Only if it is NORMAL is the window visible.
@@ -58,7 +61,7 @@
 
 class Frame : public Fl_Window {
 
-  Window window_;
+  XWindow window_;
 
   short state_;		// X server state: iconic, withdrawn, normal
   short state_flags_;	// above state flags
@@ -79,14 +82,14 @@
   int label_y, label_h; // location of label
   int label_w;		// measured width of printed label
 
-  Window transient_for_xid; // value from X
+  XWindow transient_for_xid; // value from X
   Frame* transient_for_; // the frame for that xid, if found
 
   Frame* revert_to;	// probably the xterm this was run from
 
   Colormap colormap;	// this window's colormap
   int colormapWinCount; // list of other windows to install colormaps for
-  Window *colormapWindows;
+  XWindow *colormapWindows;
   Colormap *window_Colormaps; // their colormaps
 
   Desktop* desktop_;
@@ -101,6 +104,7 @@
   int maximize_height();
   int force_x_onscreen(int X, int W);
   int force_y_onscreen(int Y, int H);
+  void place_window();
 
   void sendMessage(Atom, Atom) const;
   void sendConfigureNotify() const;
@@ -122,6 +126,7 @@
 
   void set_size(int,int,int,int, int warp=0);
   void resize(int,int,int,int);
+  void layout();
   void show_hide_buttons();
 
   int handle(int);	// handle fltk events
@@ -151,10 +156,10 @@
   static Frame* first;
   Frame* next;		// stacking order, top to bottom
 
-  Frame(Window, XWindowAttributes* = 0);
+  Frame(XWindow, XWindowAttributes* = 0);
   ~Frame();
 
-  Window window() const {return window_;}
+  XWindow window() const {return window_;}
   Frame* transient_for() const {return transient_for_;}
   int is_transient_for(const Frame*) const;
 
@@ -185,8 +190,8 @@
 };
 
 // handy wrappers for those ugly X routines:
-void* getProperty(Window, Atom, Atom = AnyPropertyType, int* length = 0);
-int getIntProperty(Window, Atom, Atom = AnyPropertyType, int deflt = 0);
-void setProperty(Window, Atom, Atom, int);
+void* getProperty(XWindow, Atom, Atom = AnyPropertyType, int* length = 0);
+int getIntProperty(XWindow, Atom, Atom = AnyPropertyType, int deflt = 0);
+void setProperty(XWindow, Atom, Atom, int);
 
 #endif
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Hotkeys.C /tmp/KfNDqvamm0/flwm-1.01/Hotkeys.C
--- /tmp/8FTwAYJlot/flwm-1.00/Hotkeys.C	2000-09-22 18:53:05.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Hotkeys.C	2006-06-29 09:18:08.000000000 +0200
@@ -149,6 +149,36 @@
 #endif
   {0}};
 
+#if FL_MAJOR_VERSION > 1
+// Define missing function, this should get put in fltk2.0:
+namespace fltk {
+int test_shortcut(int shortcut) {
+  if (!shortcut) return 0;
+
+  int shift = Fl::event_state();
+  // see if any required shift flags are off:
+  if ((shortcut&shift) != (shortcut&0x7fff0000)) return 0;
+  // record shift flags that are wrong:
+  int mismatch = (shortcut^shift)&0x7fff0000;
+  // these three must always be correct:
+  if (mismatch&(FL_META|FL_ALT|FL_CTRL)) return 0;
+
+  int key = shortcut & 0xffff;
+
+  // if shift is also correct, check for exactly equal keysyms:
+  if (!(mismatch&(FL_SHIFT)) && unsigned(key) == Fl::event_key()) return 1;
+
+  // try matching ascii, ignore shift:
+  if (key == event_text()[0]) return 1;
+
+  // kludge so that Ctrl+'_' works (as opposed to Ctrl+'^_'):
+  if ((shift&FL_CTRL) && key >= 0x3f && key <= 0x5F
+      && event_text()[0]==(key^0x40)) return 1;
+  return 0;
+}
+}
+#endif
+
 int Handle_Hotkey() {
   for (int i = 0; keybindings[i].key; i++) {
     if (Fl::test_shortcut(keybindings[i].key) ||
@@ -165,7 +195,7 @@
 extern Fl_Window* Root;
 
 void Grab_Hotkeys() {
-  Window root = fl_xid(Root);
+  XWindow root = fl_xid(Root);
   for (int i = 0; keybindings[i].key; i++) {
     int k = keybindings[i].key;
     int keycode = XKeysymToKeycode(fl_display, k & 0xFFFF);
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/logo.fl /tmp/KfNDqvamm0/flwm-1.01/logo.fl
--- /tmp/8FTwAYJlot/flwm-1.00/logo.fl	1970-01-01 01:00:00.000000000 +0100
+++ /tmp/KfNDqvamm0/flwm-1.01/logo.fl	2006-04-13 18:06:59.000000000 +0200
@@ -0,0 +1,19 @@
+# data file for the FLTK User Interface Designer (FLUID)
+version 2.0100 
+header_name {.h} 
+code_name {.cxx} 
+gridx 5 
+gridy 5 
+snap 3
+Function {make_window()} {open
+} {
+  {fltk::Window} {} {
+    label flwm open
+    xywh {990 285 265 115} visible
+  } {
+    {fltk::Group} {} {
+      label {The Fast Light Window Manager} open selected
+      xywh {0 0 265 115} align 128 box PLASTIC_UP_BOX labelfont 1 labeltype ENGRAVED_LABEL color 0x7d9dae00 textcolor 0x979b9700 labelcolor 0x393a3900 labelsize 27
+    } {}
+  }
+} 
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/main.C /tmp/KfNDqvamm0/flwm-1.01/main.C
--- /tmp/8FTwAYJlot/flwm-1.00/main.C	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/main.C	2006-06-29 09:17:24.000000000 +0200
@@ -43,10 +43,15 @@
 class Fl_Root : public Fl_Window {
   int handle(int);
 public:
-  Fl_Root() : Fl_Window(0,0,Fl::w(),Fl::h()) {}
+  Fl_Root() : Fl_Window(0,0,Fl::w(),Fl::h()) {
+#if FL_MAJOR_VERSION > 1
+    clear_double_buffer();
+#endif
+  }
   void show() {
     if (!shown()) Fl_X::set_xid(this, RootWindow(fl_display, fl_screen));
   }
+  void flush() {}
 };
 Fl_Window *Root;
 
@@ -69,7 +74,7 @@
 // fltk calls this for any events it does not understand:
 static int flwm_event_handler(int e) {
   if (!e) { // XEvent that fltk did not understand.
-    Window window = fl_xevent->xany.window;
+    XWindow window = fl_xevent->xany.window;
     // unfortunately most of the redirect events put the interesting
     // window id in a different place:
     switch (fl_xevent->type) {
@@ -107,18 +112,31 @@
       const XMapRequestEvent* e = &(fl_xevent->xmaprequest);
       (void)new Frame(e->window);
       return 1;}
-    case KeyRelease: {
+#if FL_MAJOR_VERSION<2
+    // this was needed for *some* earlier versions of fltk
+    case KeyRelease:
       if (!Fl::grab()) return 0;
-      // see if they released the alt key:
-      unsigned long keysym =
+      Fl::e_keysym =
 	XKeycodeToKeysym(fl_display, fl_xevent->xkey.keycode, 0);
-      if (keysym == FL_Alt_L || keysym == FL_Alt_R) {
-	Fl::e_keysym = FL_Enter;
-	return Fl::grab()->handle(FL_KEYBOARD);
-      }
-      return 0;}
+      goto KEYUP;
+#endif
+    }
+  } else if (e == FL_KEYUP) {
+#if FL_MAJOR_VERSION<2
+  KEYUP:
+#endif
+    if (!Fl::grab()) return 0;
+    // when alt key released, pretend they hit enter & pick menu item
+    if (Fl::event_key()==FL_Alt_L || Fl::event_key()==FL_Alt_R) {
+      Fl::e_keysym = FL_Enter;
+#if FL_MAJOR_VERSION>1
+      return Fl::modal()->handle(FL_KEYBOARD);
+#else
+      return Fl::grab()->handle(FL_KEYBOARD);
+#endif
     }
-  } else if (e == FL_SHORTCUT) {
+    return 0;
+  } else if (e == FL_SHORTCUT || e == FL_KEYBOARD) {
 #if FL_MAJOR_VERSION == 1 && FL_MINOR_VERSION == 0 && FL_PATCH_VERSION < 3
     // make the tab keys work in the menus in older fltk's:
     // (they do not cycle around however, so a new fltk is a good idea)
@@ -189,28 +207,26 @@
 #endif
 
 static const char* cfg, *cbg;
+#if FL_MAJOR_VERSION>1
+static fltk::Cursor* cursor = FL_CURSOR_ARROW;
+extern FL_API fltk::Color fl_cursor_fg;
+extern FL_API fltk::Color fl_cursor_bg;
+#else
 static int cursor = FL_CURSOR_ARROW;
-
-static void color_setup(Fl_Color slot, const char* arg, ulong value) {
-  if (arg) {
-    XColor x;
-    if (XParseColor(fl_display, fl_colormap, arg, &x))
-      value = ((x.red>>8)<<24)|((x.green>>8)<<16)|((x.blue));
-  }
-  Fl::set_color(slot, value);
-}
+#endif
 
 static void initialize() {
 
   Display* d = fl_display;
 
 #ifdef TEST
-  Window w = XCreateSimpleWindow(d, root,
+  XWindow w = XCreateSimpleWindow(d, RootWindow(d, fl_screen),
 				 100, 100, 200, 300, 10,
 				 BlackPixel(fl_display, 0),
 //				 WhitePixel(fl_display, 0));
 				 0x1234);
   Frame* frame = new Frame(w);
+  frame->label("flwm test window");
   XSelectInput(d, w,
 	       ExposureMask | StructureNotifyMask |
 	       KeyPressMask | KeyReleaseMask | FocusChangeMask |
@@ -230,9 +246,12 @@
 	       ButtonPressMask | ButtonReleaseMask | 
 	       EnterWindowMask | LeaveWindowMask |
 	       KeyPressMask | KeyReleaseMask | KeymapStateMask);
-  color_setup(CURSOR_FG_SLOT, cfg, CURSOR_FG_COLOR<<8);
-  color_setup(CURSOR_BG_SLOT, cbg, CURSOR_BG_COLOR<<8);
+#if FL_MAJOR_VERSION>1
+  Root->cursor(cursor);
+#else
   Root->cursor((Fl_Cursor)cursor, CURSOR_FG_SLOT, CURSOR_BG_SLOT);
+#endif
+  Fl::visible_focus(0);
 
 #ifdef TITLE_FONT
   Fl::set_font(TITLE_FONT_SLOT, TITLE_FONT);
@@ -247,7 +266,7 @@
   // Gnome crap:
   // First create a window that can be watched to see if wm dies:
   Atom a = XInternAtom(d, "_WIN_SUPPORTING_WM_CHECK", False);
-  Window win = XCreateSimpleWindow(d, fl_xid(Root), -200, -200, 5, 5, 0, 0, 0);
+  XWindow win = XCreateSimpleWindow(d, fl_xid(Root), -200, -200, 5, 5, 0, 0, 0);
   CARD32 val = win;
   XChangeProperty(d, fl_xid(Root), a, XA_CARDINAL, 32, PropModeReplace, (uchar*)&val, 1);
   XChangeProperty(d, win, a, XA_CARDINAL, 32, PropModeReplace, (uchar*)&val, 1);
@@ -287,7 +306,7 @@
 
   // find all the windows and create a Frame for each:
   unsigned int n;
-  Window w1, w2, *wins;
+  XWindow w1, w2, *wins;
   XWindowAttributes attr;
   XQueryTree(d, fl_xid(Root), &w1, &w2, &wins, &n);
   for (i = 0; i < n; ++i) {
@@ -298,7 +317,6 @@
   XFree((void *)wins);
 
 #endif
-  Fl::visible_focus(0);
 }
 
 ////////////////////////////////////////////////////////////////
@@ -329,8 +347,10 @@
     cfg = v;
   } else if (!strcmp(s, "cbg")) {
     cbg = v;
+#if FL_MAJOR_VERSION < 2
   } else if (*s == 'c') {
     cursor = atoi(v);
+#endif
   } else if (*s == 'v') {
     int visid = atoi(v);
     fl_open_display();
@@ -351,6 +371,17 @@
   return 2;
 }
 
+#if FL_MAJOR_VERSION<2
+static void color_setup(Fl_Color slot, const char* arg, ulong value) {
+  if (arg) {
+    XColor x;
+    if (XParseColor(fl_display, fl_colormap, arg, &x))
+      value = ((x.red>>8)<<24)|((x.green>>8)<<16)|((x.blue));
+  }
+  Fl::set_color(slot, value);
+}
+#endif
+
 int main(int argc, char** argv) {
   program_name = fl_filename_name(argv[0]);
   int i; if (Fl::args(argc, argv, i, arg) < argc) Fl::error(
@@ -370,8 +401,22 @@
 #ifndef FL_NORMAL_SIZE // detect new versions of fltk where this is a variable
   FL_NORMAL_SIZE = 12;
 #endif
+#if FL_MAJOR_VERSION>1
+  if (cfg) fl_cursor_fg = fltk::color(cfg);
+  if (cbg) fl_cursor_bg = fltk::color(cbg);
+#else
+  fl_open_display();
+  color_setup(CURSOR_FG_SLOT, cfg, CURSOR_FG_COLOR<<8);
+  color_setup(CURSOR_BG_SLOT, cbg, CURSOR_BG_COLOR<<8);
   Fl::set_color(FL_SELECTION_COLOR,0,0,128);
-  Root = new Fl_Root();
+#endif
+  Fl_Root root;
+  Root = &root;
+#if FL_MAJOR_VERSION>1
+  // show() is not a virtual function in fltk2.0, this fools it:
+  fltk::load_theme();
+  root.show();
+#endif
   Root->show(argc,argv); // fools fltk into using -geometry to set the size
   XSetErrorHandler(xerror_handler);
   initialize();
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Makefile /tmp/KfNDqvamm0/flwm-1.01/Makefile
--- /tmp/8FTwAYJlot/flwm-1.00/Makefile	2000-09-22 18:53:04.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Makefile	2006-06-30 00:11:16.000000000 +0200
@@ -1,7 +1,7 @@
 SHELL=/bin/sh
 
 PROGRAM = flwm
-VERSION = 1.00
+VERSION = 1.01
 
 CXXFILES = main.C Frame.C Rotated.C Menu.C FrameWindow.C Desktop.C Hotkeys.C
 
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Menu.C /tmp/KfNDqvamm0/flwm-1.01/Menu.C
--- /tmp/8FTwAYJlot/flwm-1.00/Menu.C	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Menu.C	2006-06-30 11:01:41.000000000 +0200
@@ -20,24 +20,6 @@
 #include <dirent.h>
 #include <sys/stat.h>
 
-static char *double_ampersand(const char *s)
-{
-  long i,l;
-  for(i=0,l=0;s[i];i++)
-    if (s[i]=='&')
-      l++;
-  char *c = new (char [l+i+1]);
-  for(i=0,l=0;s[i];i++)
-  {
-    c[l++]=s[i];
-    if (s[i]=='&')
-      c[l++]=s[i];
-  }
-  c[l]=0;
-  return c;
-}
-
-
 // it is possible for the window to be deleted or withdrawn while
 // the menu is up.  This will detect that case (with reasonable
 // reliability):
@@ -79,6 +61,7 @@
 
 extern Fl_Window* Root;
 
+#if FL_MAJOR_VERSION < 2
 static void
 frame_label_draw(const Fl_Label* o, int X, int Y, int W, int H, Fl_Align align)
 {
@@ -108,11 +91,19 @@
   }
   fl_font(o->font, o->size);
   fl_color((Fl_Color)o->color);
-  const char* l = f->label(); 
-  if (!l) l = "unnamed";
-  else l = double_ampersand(f->label());
+  const char* l = f->label(); if (!l) l = "unnamed";
+  // double any ampersands to turn off the underscores:
+  char buf[256];
+  if (strchr(l,'&')) {
+    char* t = buf;
+    while (t < buf+254 && *l) {
+      if (*l=='&') *t++ = *l;
+      *t++ = *l++;
+    }
+    *t = 0;
+    l = buf;
+  }
   fl_draw(l, X+MENU_ICON_W+3, Y, W-MENU_ICON_W-3, H, align);
-  delete l;
 }
 
 static void
@@ -152,6 +143,8 @@
 #define FRAME_LABEL FL_FREE_LABELTYPE
 #define TEXT_LABEL Fl_Labeltype(FL_FREE_LABELTYPE+1)
 
+#endif // FL_MAJOR_VERSION < 2
+
 ////////////////////////////////////////////////////////////////
 
 static void
@@ -176,7 +169,7 @@
 
 #if ASK_FOR_NEW_DESKTOP_NAME
 
-static Fl_Input* new_desktop_input;
+static Fl_Input* new_desktop_input = 0;
 
 static void
 new_desktop_ok_cb(Fl_Widget* w, void*)
@@ -226,6 +219,7 @@
 static void
 exit_cb(Fl_Widget*, void*)
 {
+  printf("exit_cb\n");
   Frame::save_protocol();
   exit(0);
 }
@@ -233,7 +227,7 @@
 static void
 logout_cb(Fl_Widget*, void*)
 {
-  static FrameWindow* w;
+  static FrameWindow* w = 0;
   if (!w) {
     w = new FrameWindow(190,90);
     Fl_Box* l = new Fl_Box(0, 0, 190, 60, "Really log out?");
@@ -267,8 +261,8 @@
   if (fork() == 0) {
     if (fork() == 0) {
       close(ConnectionNumber(fl_display));
-      if (name == xtermname) execlp(name, name, "-ut", NULL);
-      else execl(name, name, NULL);
+      if (name == xtermname) execlp(name, name, "-ut", (void*)0);
+      else execl(name, name, (void*)0);
       fprintf(stderr, "flwm: can't run %s, %s\n", name, strerror(errno));
       XBell(fl_display, 70);
       exit(1);
@@ -299,7 +293,11 @@
   m.style = 0;
 #endif
   m.label(data);
+#if FL_MAJOR_VERSION > 2
+  m.flags = fltk::RAW_LABEL;
+#else
   m.flags = 0;
+#endif
   m.labeltype(FL_NORMAL_LABEL);
   m.shortcut(0);
   m.labelfont(MENU_FONT_SLOT);
@@ -444,8 +442,10 @@
   static char beenhere;
   if (!beenhere) {
     beenhere = 1;
+#if FL_MAJOR_VERSION < 2
     Fl::set_labeltype(FRAME_LABEL, frame_label_draw, frame_label_measure);
     Fl::set_labeltype(TEXT_LABEL, label_draw, label_measure);
+#endif
     if (exit_flag) {
       Fl_Menu_Item* m = other_menu_items+num_other_items-2;
       m->label("Exit");
@@ -532,8 +532,12 @@
 #endif
     for (c = Frame::first; c; c = c->next) {
       if (c->state() == UNMAPPED || c->transient_for()) continue;
+#if FL_MAJOR_VERSION < 2
       init(menu[n],(char*)c);
       menu[n].labeltype(FRAME_LABEL);
+#else
+      init(menu[n],c->label());
+#endif
       menu[n].callback(frame_callback, c);
       if (is_active_frame(c)) preset = menu+n;
       n++;
@@ -562,7 +566,12 @@
 	if (c->state() == UNMAPPED || c->transient_for()) continue;
 	if (c->desktop() == d || !c->desktop() && d == Desktop::current()) {
 	  init(menu[n],(char*)c);
+#if FL_MAJOR_VERSION < 2
+	  init(menu[n],(char*)c);
 	  menu[n].labeltype(FRAME_LABEL);
+#else
+	  init(menu[n],c->label());
+#endif
 	  menu[n].callback(d == Desktop::current() ?
 			   frame_callback : move_frame_callback, c);
 	  if (d == Desktop::current() && is_active_frame(c)) preset = menu+n;
@@ -606,13 +615,14 @@
       cmd = wmxlist[i];
       cmd += strspn(cmd, "/")-1;
       init(menu[n], cmd+pathlen[level]);
+#if FL_MAJOR_VERSION < 2
 #if DESKTOPS
       if (one_desktop)
 #endif
 	if (!level)
 	  menu[n].labeltype(TEXT_LABEL);
-
-      int	nextlev = (i==num_wmx-1)?0:strspn(wmxlist[i+1], "/")-1;
+#endif
+      int nextlev = (i==num_wmx-1)?0:strspn(wmxlist[i+1], "/")-1;
       if (nextlev < level) {
 	menu[n].callback(spawn_cb, cmd);
 	// Close 'em off
@@ -638,15 +648,19 @@
 #endif
 #endif
     memcpy(menu+n, other_menu_items, sizeof(other_menu_items));
+#if FL_MAJOR_VERSION < 2
 #if DESKTOPS
   if (one_desktop)
 #endif
     // fix the menus items so they are indented to align with window names:
     while (menu[n].label()) menu[n++].labeltype(TEXT_LABEL);
+#endif
 
   const Fl_Menu_Item* picked =
     menu->popup(Fl::event_x(), Fl::event_y(), 0, preset);
+#if FL_MAJOR_VERSION < 2
   if (picked && picked->callback()) picked->do_callback(0);
+#endif
 }
 
 void ShowMenu() {ShowTabMenu(0);}
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/patch-stamp /tmp/KfNDqvamm0/flwm-1.01/patch-stamp
--- /tmp/8FTwAYJlot/flwm-1.00/patch-stamp	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/patch-stamp	2006-06-30 11:01:41.000000000 +0200
@@ -1,29 +1,8 @@
 Patches applied in the Debian version of :
 
-debian/patches/100_fl_filename_name.dpatch (Tommi Virtanen <tv@debian.org>):
-  Transition from fltk-1.0 to fltk-1.1.
-  Applied upstream.
-
-debian/patches/101_visible_focus.dpatch (Bill Allombert <ballombe@debian.org>):
-  Restore fltk-1.0 focus behaviour
-  (Applied upstream)
-
-debian/patches/102_charstruct.dpatch (Tommi Virtanen <tv@debian.org>):
-  Support fonts for which fontstruct->per_char is NULL.
-  (Applied upstream).
-
-debian/patches/103_man_typo.dpatch (Bill Allombert <ballombe@debian.org>):
-  Fix typo in man page.
-
-debian/patches/104_g++-4.1_warning.dpatch (Bill Allombert <ballombe@debian.org>):
-  Fix 5 g++ -4.1 warnings
-
-debian/patches/105_double_ampersand.dpatch (Bill Allombert <ballombe@debian.org>):
-  Handle & in window titles correctly in the windows list.
+debian/patches/100_double_ampersand.dpatch (<ballombe@debian.org>):
+  fix handling of ampersand in titles in windows list.
 
 debian/patches/200_Debian_menu.dpatch (Tommi Virtanen <tv@debian.org>):
   Add Debian menu support.
 
-debian/patches/201_background_color.dpatch (Bill Allombert <ballombe@debian.org>):
-  Fix -fg and -bg options
-
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/README /tmp/KfNDqvamm0/flwm-1.01/README
--- /tmp/8FTwAYJlot/flwm-1.00/README	1999-08-24 22:59:35.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/README	2001-04-13 17:40:54.000000000 +0200
@@ -5,7 +5,7 @@
 ----------------------------------------------------------------
 
 You need fltk.  If you do not have it yet, download it from
-http://fltk.easysw.com, and compile and install it.
+http://www.fltk.org, and compile and install it.
 
 To customize flwm (for instance to turn on click-to-type), edit the
 config.h file.
@@ -22,21 +22,21 @@
 How to run flwm:
 ----------------------------------------------------------------
 
-Flwm should be run by X when it logs you in.  This is done by putting
-a call to flwm into the file ~/.xinitrc.  With any luck you already
-have this file.  If not try copying /usr/X11/lib/X11/xinit/xinitrc.
-Edit the file and try to remove any call to another window manager
-(these are usually near the end). 
+To run flwm as your login script, you need to create or replace
+~/.xinitrc or ~/.xsession (or both).  Newer Linux systems with a login
+panel use .xsession, older systems where X was started after login
+use .xinitrc.  You may also have to pick "default" from the "type of
+session" popup in your login window.
 
-Recommended contents of ~/.xinitrc:
+The .xinitrc or .xsession file should look like this:
 
 #!/bin/sh
 xsetroot -solid \#006060
 xrdb .Xresources
-# <xset, xmodmap, other configuration programs>
+# xset, xmodmap, other configuration programs
 flwm &
 WindowManager=$!
-# <xterm, other automatically-launched programs>
+# xterm, other automatically-launched programs
 wait $WindowManager
 
 ALLOWING THE WINDOW MANAGER TO EXIT W/O LOGOUT:
diff -Nru /tmp/8FTwAYJlot/flwm-1.00/Rotated.C /tmp/KfNDqvamm0/flwm-1.01/Rotated.C
--- /tmp/8FTwAYJlot/flwm-1.00/Rotated.C	2006-06-30 11:01:38.000000000 +0200
+++ /tmp/KfNDqvamm0/flwm-1.01/Rotated.C	2005-09-19 06:29:11.000000000 +0200
@@ -27,6 +27,9 @@
 /* ********************************************************************** */
 
 #include <FL/x.H>
+#if FL_MAJOR_VERSION < 2
+# define XWindow Window
+#endif
 #include <FL/fl_draw.H>
 #include "Rotated.H"
 #include <stdlib.h>
@@ -67,7 +70,7 @@
   char val;
   XImage *I1, *I2;
   Pixmap canvas;
-  Window root;
+  XWindow root;
   int screen;
   GC font_gc;
   char text[3];/*, errstr[300];*/
@@ -116,27 +119,21 @@
     /* font needs rotation ... */
     /* loop through each character ... */
     for (ichar = min_char; ichar <= max_char; ichar++) {
-      XCharStruct *charstruct;
 
       index = ichar-fontstruct->min_char_or_byte2;
 
-      if (fontstruct->per_char) {
-	charstruct = &fontstruct->per_char[index];
-      } else {
+      XCharStruct* charstruct;
+      if (fontstruct->per_char)
+	charstruct = fontstruct->per_char+index;
+      else
 	charstruct = &fontstruct->min_bounds;
-      }
 
       /* per char dimensions ... */
-      ascent =   rotfont->per_char[ichar].ascent = 
-	charstruct->ascent;
-      descent =  rotfont->per_char[ichar].descent = 
-	charstruct->descent;
-      lbearing = rotfont->per_char[ichar].lbearing = 
-	charstruct->lbearing;
-      rbearing = rotfont->per_char[ichar].rbearing = 
-	charstruct->rbearing;
-      rotfont->per_char[ichar].width = 
-	charstruct->width;
+      ascent =   rotfont->per_char[ichar].ascent   = charstruct->ascent;
+      descent =  rotfont->per_char[ichar].descent  = charstruct->descent;
+      lbearing = rotfont->per_char[ichar].lbearing = charstruct->lbearing;
+      rbearing = rotfont->per_char[ichar].rbearing = charstruct->rbearing;
+                 rotfont->per_char[ichar].width    = charstruct->width;
 
       /* some space chars have zero body, but a bitmap can't have ... */
       if (!ascent && !descent)   
@@ -242,9 +239,9 @@
   }
   
   for (ichar = 0; ichar < min_char; ichar++)
-    rotfont->per_char[ichar] = rotfont->per_char[(int)'?'];
+    rotfont->per_char[ichar] = rotfont->per_char[int('?')];
   for (ichar = max_char+1; ichar < 256; ichar++)
-    rotfont->per_char[ichar] = rotfont->per_char[(int)'?'];
+    rotfont->per_char[ichar] = rotfont->per_char[int('?')];
 
   /* free pixmap and GC ... */
   XFreePixmap(dpy, canvas);
@@ -358,23 +355,25 @@
 
 static XRotFontStruct* font;
 
-void draw_rotated(const char* text, int n, int x, int y, int angle) {
-  if (!text || !*text) return;
+static void setrotfont(int angle) {
   /* make angle positive ... */
   if (angle < 0) do angle += 360; while (angle < 0);
   /* get nearest vertical or horizontal direction ... */
   int dir = ((angle+45)/90)%4;
-
-  if (font && font->xfontstruct == fl_xfont && font->dir == dir) {
-    ;
-  } else {
-    if (font) XRotUnloadFont(fl_display, font);
-    font = XRotLoadFont(fl_display, fl_xfont, dir);
+  if (font) {
+    if (font->xfontstruct == fl_xfont && font->dir == dir) return;
+    XRotUnloadFont(fl_display, font);
   }
+  font = XRotLoadFont(fl_display, fl_xfont, dir);
+}
+
+void draw_rotated(const char* text, int n, int x, int y, int angle) {
+  if (!text || !*text) return;
+  setrotfont(angle);
   XRotDrawString(fl_display, font, fl_window, fl_gc, x, y, text, n);
 }
 
-#ifndef FLWM
+#if !defined(FLWM) || FL_MAJOR_VERSION>=2
 void draw_rotated(const char* text, int x, int y, int angle) {
   if (!text || !*text) return;
   draw_rotated(text, strlen(text), x, y, angle);
@@ -391,12 +390,20 @@
   if (!str || !*str) return;
   if (w && h && !fl_not_clipped(x, y, w, h)) return;
   if (align & FL_ALIGN_CLIP) fl_clip(x, y, w, h);
+#if FL_MAJOR_VERSION>1
+  setrotfont(90);
+  int a = font->xfontstruct->ascent;
+  int d = font->xfontstruct->descent;
+  XRotDrawString(fl_display, font, fl_window, fl_gc,
+		 x+(w+a-d+1)/2, y+h, str, strlen(str));
+#else
   int a1 = align&(-16);
   if (align & FL_ALIGN_LEFT) a1 |= FL_ALIGN_TOP;
   if (align & FL_ALIGN_RIGHT) a1 |= FL_ALIGN_BOTTOM;
   if (align & FL_ALIGN_TOP) a1 |= FL_ALIGN_RIGHT;
   if (align & FL_ALIGN_BOTTOM) a1 |= FL_ALIGN_LEFT;
   fl_draw(str, -(y+h), x, h, w, (Fl_Align)a1, draw_rot90);
+#endif
   if (align & FL_ALIGN_CLIP) fl_pop_clip();
 }
 
