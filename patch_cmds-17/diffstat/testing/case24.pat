# ncurses 5.4 - patch 20040821 - T.Dickey
#
# ------------------------------------------------------------------------------
#
# Ncurses 5.4 is at
# 	ftp.gnu.org:/pub/gnu
#
# Patches for ncurses 5.4 are in the subdirectory
# 	ftp://invisible-island.net/ncurses/5.4
#
# ------------------------------------------------------------------------------
Index: Ada95/gen/gen.c
--- ncurses-5.4-20040814+/Ada95/gen/gen.c	2003-10-25 15:39:18.000000000 +0000
+++ ncurses-5.4-20040821/Ada95/gen/gen.c	2004-08-21 20:37:13.000000000 +0000
@@ -1,5 +1,5 @@
 /****************************************************************************
- * Copyright (c) 1998,2000 Free Software Foundation, Inc.                   *
+ * Copyright (c) 1998,2000,2004 Free Software Foundation, Inc.              *
  *                                                                          *
  * Permission is hereby granted, free of charge, to any person obtaining a  *
  * copy of this software and associated documentation files (the            *
@@ -32,7 +32,7 @@
 
 /*
     Version Control
-    @Revision: 1.36 @
+    @Id: gen.c,v 1.38 2004/08/21 20:37:13 tom Exp @
   --------------------------------------------------------------------------*/
 /*
   This program generates various record structures and constants from the
@@ -131,7 +131,6 @@
       printf("         %-*s : Boolean;\n",width,nap[i].name);
     }
   printf("      end record;\n");
-  printf("   pragma Pack (%s);\n",name);
   printf("   pragma Convention (C, %s);\n\n",name);
 
   printf("   for %s use\n",name);
Index: Ada95/gen/terminal_interface-curses-mouse.ads.m4
--- ncurses-5.4-20040814+/Ada95/gen/terminal_interface-curses-mouse.ads.m4	2003-10-25 15:39:18.000000000 +0000
+++ ncurses-5.4-20040821/Ada95/gen/terminal_interface-curses-mouse.ads.m4	2004-08-21 21:37:00.000000000 +0000
@@ -10,7 +10,7 @@
 --                                 S P E C                                  --
 --                                                                          --
 ------------------------------------------------------------------------------
--- Copyright (c) 1998 Free Software Foundation, Inc.                        --
+-- Copyright (c) 1998,2004 Free Software Foundation, Inc.                   --
 --                                                                          --
 -- Permission is hereby granted, free of charge, to any person obtaining a  --
 -- copy of this software and associated documentation files (the            --
@@ -38,7 +38,8 @@
 ------------------------------------------------------------------------------
 --  Author:  Juergen Pfeifer, 1996
 --  Version Control:
---  @Revision: 1.22 @
+--  @Revision: 1.25 @
+--  @Date: 2004/08/21 21:37:00 @
 --  Binding Version 01.00
 ------------------------------------------------------------------------------
 include(`Mouse_Base_Defs')
@@ -169,7 +170,6 @@
          Bstate  : Event_Mask;
       end record;
    pragma Convention (C, Mouse_Event);
-   pragma Pack (Mouse_Event);
 
 include(`Mouse_Event_Rep')
    Generation_Bit_Order : constant System.Bit_Order := System.M4_BIT_ORDER;
Index: Ada95/gen/terminal_interface-curses.ads.m4
--- ncurses-5.4-20040814+/Ada95/gen/terminal_interface-curses.ads.m4	2003-10-25 15:39:18.000000000 +0000
+++ ncurses-5.4-20040821/Ada95/gen/terminal_interface-curses.ads.m4	2004-08-21 21:37:00.000000000 +0000
@@ -9,7 +9,7 @@
 --                                 S P E C                                  --
 --                                                                          --
 ------------------------------------------------------------------------------
--- Copyright (c) 1998 Free Software Foundation, Inc.                        --
+-- Copyright (c) 1998,2004 Free Software Foundation, Inc.                   --
 --                                                                          --
 -- Permission is hereby granted, free of charge, to any person obtaining a  --
 -- copy of this software and associated documentation files (the            --
@@ -37,7 +37,8 @@
 ------------------------------------------------------------------------------
 --  Author:  Juergen Pfeifer, 1996
 --  Version Control:
---  @Revision: 1.31 @
+--  @Revision: 1.35 @
+--  @Date: 2004/08/21 21:37:00 @
 --  Binding Version 01.00
 ------------------------------------------------------------------------------
 include(`Base_Defs')
@@ -59,11 +60,12 @@
    subtype Column_Count is Column_Position range 1 .. Column_Position'Last;
    --  Type to count columns. We do not allow null windows, so must be positive
 
-   type Key_Code is new Natural;
+   type Key_Code is new Integer;
    --  That is anything including real characters, special keys and logical
    --  request codes.
 
-   subtype Real_Key_Code is Key_Code range 0 .. M4_KEY_MAX;
+   --  FIXME: The "-1" should be Curses_Err
+   subtype Real_Key_Code is Key_Code range -1 .. M4_KEY_MAX;
    --  This are the codes that potentially represent a real keystroke.
    --  Not all codes may be possible on a specific terminal. To check the
    --  availability of a special key, the Has_Key function is provided.
Index: Ada95/samples/ncurses2-acs_and_scroll.adb
--- ncurses-5.4-20040814+/Ada95/samples/ncurses2-acs_and_scroll.adb	2000-12-02 22:31:22.000000000 +0000
+++ ncurses-5.4-20040821/Ada95/samples/ncurses2-acs_and_scroll.adb	2004-08-21 21:37:00.000000000 +0000
@@ -7,7 +7,7 @@
 --                                 B O D Y                                  --
 --                                                                          --
 ------------------------------------------------------------------------------
--- Copyright (c) 2000 Free Software Foundation, Inc.                        --
+-- Copyright (c) 2000,2004 Free Software Foundation, Inc.                   --
 --                                                                          --
 -- Permission is hereby granted, free of charge, to any person obtaining a  --
 -- copy of this software and associated documentation files (the            --
@@ -35,7 +35,8 @@
 ------------------------------------------------------------------------------
 --  Author: Eugene V. Melaragno <aldomel@ix.netcom.com> 2000
 --  Version Control
---  @Revision: 1.1 @
+--  @Revision: 1.6 @
+--  @Date: 2004/08/21 21:37:00 @
 --  Binding Version 01.00
 ------------------------------------------------------------------------------
 --  Windows and scrolling tester.
@@ -224,8 +225,8 @@
          );
 
       buf : Bounded_String;
-      do_keypad : Boolean := HaveKeyPad (curpw);
-      do_scroll : Boolean := HaveScroll (curpw);
+      do_keypad : constant Boolean := HaveKeyPad (curpw);
+      do_scroll : constant Boolean := HaveScroll (curpw);
 
       pos : Natural;
 
@@ -331,8 +332,8 @@
       res : pair;
       i : Line_Position := 0;
       j : Column_Position := 0;
-      si : Line_Position := lri - uli + 1;
-      sj : Column_Position := lrj - ulj + 1;
+      si : constant Line_Position := lri - uli + 1;
+      sj : constant Column_Position := lrj - ulj + 1;
    begin
       res.y := uli;
       res.x := ulj;
@@ -714,7 +715,7 @@
 
    Allow_Scrolling (Mode => True);
 
-   End_Mouse;
+   End_Mouse (Mask2);
    Set_Raw_Mode (SwitchOn => True);
    Erase;
    End_Windows;
Index: Ada95/samples/ncurses2-acs_display.adb
--- ncurses-5.4-20040814+/Ada95/samples/ncurses2-acs_display.adb	2000-12-02 22:31:23.000000000 +0000
+++ ncurses-5.4-20040821/Ada95/samples/ncurses2-acs_display.adb	2004-08-21 21:37:00.000000000 +0000
@@ -7,7 +7,7 @@
 --                                 B O D Y                                  --
 --                                                                          --
 ------------------------------------------------------------------------------
--- Copyright (c) 2000 Free Software Foundation, Inc.                        --
+-- Copyright (c) 2000,2004 Free Software Foundation, Inc.                   --
 --                                                                          --
 -- Permission is hereby granted, free of charge, to any person obtaining a  --
 -- copy of this software and associated documentation files (the            --
@@ -35,7 +35,8 @@
 ------------------------------------------------------------------------------
 --  Author: Eugene V. Melaragno <aldomel@ix.netcom.com> 2000
 --  Version Control
---  @Revision: 1.1 @
+--  @Revision: 1.4 @
+--  @Date: 2004/08/21 21:37:00 @
 --  Binding Version 01.00
 ------------------------------------------------------------------------------
 with ncurses2.util; use ncurses2.util;
@@ -57,8 +58,8 @@
 
 
    procedure show_upper_chars (first : Integer)  is
-      C1 : Boolean := (first = 128);
-      last : Integer := first + 31;
+      C1 : constant Boolean := (first = 128);
+      last : constant Integer := first + 31;
       package p is new ncurses2.genericPuts (200);
       use p;
       use p.BS;
@@ -91,9 +92,11 @@
 
       for code in first .. last loop
          declare
-            row : Line_Position := Line_Position (4 + ((code - first) mod 16));
-            col : Column_Position := Column_Position (((code - first) / 16) *
-                                                      Integer (Columns) / 2);
+            row : constant Line_Position
+                := Line_Position (4 + ((code - first) mod 16));
+            col : constant Column_Position
+                := Column_Position (((code - first) / 16) *
+                                    Integer (Columns) / 2);
             tmp3 : String (1 .. 3);
             tmpx : String (1 .. Integer (Columns / 4));
             reply : Key_Code;
@@ -129,8 +132,8 @@
                         code :  Attributed_Character)
                        return Integer is
       height : constant Integer := 16;
-      row : Line_Position := Line_Position (4 + (N mod height));
-      col : Column_Position := Column_Position ((N / height) *
+      row : constant Line_Position := Line_Position (4 + (N mod height));
+      col : constant Column_Position := Column_Position ((N / height) *
                                                 Integer (Columns) / 2);
       tmpx : String (1 .. Integer (Columns) / 3);
    begin
