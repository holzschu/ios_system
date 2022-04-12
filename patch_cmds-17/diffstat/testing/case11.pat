*** test/ncurses.orig.c Sat Dec 21 08:04:03 1996
--- test/ncurses.c      Sun Dec 29 00:11:07 1996
***************
*** 2746,2751 ****
--- 2746,2752 ----
  static void
  set_terminal_modes(void)
  {
+     noraw();
      cbreak();
      noecho();
      scrollok(stdscr, TRUE);
