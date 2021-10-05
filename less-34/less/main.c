/*
 * Copyright (C) 1984-2016  Mark Nudelman
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Less License, as specified in the README file.
 *
 * For more information, see the README file.
 */


/*
 * Entry point, initialization, miscellaneous routines.
 */

#include "less.h"
#if MSDOS_COMPILER==WIN32C
#include <windows.h>
#endif

#ifdef __APPLE__
// #include "get_compat.h"
// #else
#define COMPAT_MODE(func, mode) 1
#endif


public char *	every_first_cmd = NULL;
public int	new_file;
public int	is_tty;
public IFILE	curr_ifile = NULL_IFILE;
public IFILE	old_ifile = NULL_IFILE;
public struct scrpos initial_scrpos;
public int	any_display = FALSE;
public POSITION	start_attnpos = NULL_POSITION;
public POSITION	end_attnpos = NULL_POSITION;
public int	wscroll;
public char *	progname;
public int	quitting;
public int	secure;
public int	dohelp;

public int	file_errors = 0;
public int	unix2003_compat = 0;
public int	add_newline = 0;
public char *	active_dashp_command = NULL;
public char *	dashp_commands = NULL;
#if LOGFILE
public int	logfile = -1;
public int	force_logfile = FALSE;
public char *	namelogfile = NULL;
#endif

#if EDITOR
public char *	editor;
public char *	editproto;
#endif

#if TAGS
extern char *	tags;
extern char *	tagoption;
extern int	jump_sline;
#endif

#ifdef WIN32
static char consoleTitle[256];
#endif

extern int	less_is_more;
extern int	missing_cap;
extern int	know_dumb;
extern int	pr_type;

// iOS:
#if SPACES_IN_FILENAMES
extern char openquote;
extern char closequote;
#endif
extern int utf_mode;
extern int binattr;
extern int fd0;
extern int no_back_scroll;
extern int same_pos_bell;
extern int display_next_file_or_exit;
extern int size_linebuf;
extern int tabstops[];
extern int ntabstops;
extern int tabdefault;
extern int plusoption;
// from opttbl.c
extern int quiet;        /* Should we suppress the audible bell? */
extern int how_search;        /* Where should forward searches start? */
extern int top_scroll;        /* Repaint screen from top? (alternative is scroll from bottom) */
extern int pr_type;        /* Type of prompt (short, medium, long) */
extern int bs_mode;        /* How to process backspaces */
extern int know_dumb;        /* Don't complain about dumb terminals */
extern int quit_at_eof;        /* Quit after hitting end of file twice */
extern int quit_if_one_screen;    /* Quit if EOF on first screen */
extern int squeeze;        /* Squeeze multiple blank lines into one */
extern int tabstop;        /* Tab settings */
extern int back_scroll;        /* Repaint screen on backwards movement */
extern int forw_scroll;        /* Repaint screen on forward movement */
extern int caseless;        /* Do "caseless" searches */
extern int linenums;        /* Use line numbers */
extern int autobuf;        /* Automatically allocate buffers as needed */
extern int bufspace;        /* Max buffer space per file (K) */
extern int ctldisp;        /* Send control chars to screen untranslated */
extern int force_open;        /* Open the file even if not regular file */
extern int swindow;        /* Size of scrolling window */
extern int jump_sline;        /* Screen line of "jump target" */
extern long jump_sline_fraction;
extern long shift_count_fraction;
extern int chopline;        /* Truncate displayed lines at screen width */
extern int no_init;        /* Disable sending ti/te termcap strings */
extern int no_keypad;        /* Disable sending ks/ke termcap strings */
extern int twiddle;             /* Show tildes after EOF */
extern int show_attn;        /* Hilite first unread line */
extern int shift_count;        /* Number of positions to shift horizontally */
extern int dashn_numline_count;    /* Number of lines override (Unix 2003) */
extern int status_col;        /* Display a status column */
extern int use_lessopen;    /* Use the LESSOPEN filter */
extern int quit_on_intr;    /* Quit on interrupt */
extern int follow_mode;        /* F cmd Follows file desc or file name? */
extern int oldbot;        /* Old bottom of screen behavior {{REMOVE}} */
extern int opt_use_backslash;    /* Use backslash escaping in option parsing */
#if HILITE_SEARCH
extern int hilite_search;    /* Highlight matched search patterns? */
#endif
// from optfunc.c:
extern int sc_width;
extern int sc_height;
extern char *prproto[];
extern char *eqproto;
extern char *hproto;
extern char *wproto;
#if TAGS
extern char* ztags;
#endif
// from output.c:
extern int errmsgs;    /* Count of messages displayed by error() */
extern int need_clr;
extern int final_attr;
extern int at_prompt;
// end iOS

/*
 * Entry point.
 */
int
less_main(argc, argv)
	int argc;
	char *argv[];
{
	IFILE ifile;
	char *s;

    // iOS: reinitialize flags:
    file_errors = 0;
    unix2003_compat = 0;
    add_newline = 0;
    less_is_more = 0;    /* Make compatible with POSIX more */
    utf_mode = 1; // iOS
    binattr = AT_STANDOUT;
    fd0 = fileno(thread_stdin);
    no_back_scroll = 0;
    same_pos_bell = 1;
    display_next_file_or_exit = 0;
    size_linebuf = 0;    /* Size of line buffer (and attr buffer) */
    tabstops[0] = 0; /* Custom tabstops */
    ntabstops = 1;    /* Number of tabstops */
    tabdefault = 8;    /* Default repeated tabstops */
    every_first_cmd = NULL;
    curr_ifile = NULL_IFILE;
    old_ifile = NULL_IFILE;
    any_display = FALSE;
    start_attnpos = NULL_POSITION;
    end_attnpos = NULL_POSITION;
    file_errors = 0;
    unix2003_compat = 0;
    add_newline = 0;
    active_dashp_command = NULL;
    dashp_commands = NULL;
    plusoption = FALSE;
    ztags = "tags";
    tags = ztags;
    missing_cap = 0;    /* Some capability is missing */
    // From opttbl.c:
    quiet = 0;        /* Should we suppress the audible bell? */
    how_search = 0;        /* Where should forward searches start? */
    top_scroll = 0;        /* Repaint screen from top? (alternative is scroll from bottom) */
    pr_type = 0;        /* Type of prompt (short, medium, long) */
    bs_mode = 0;        /* How to process backspaces */
    know_dumb = 0;        /* Don't complain about dumb terminals */
    quit_at_eof = 0;        /* Quit after hitting end of file twice */
    quit_if_one_screen = 0;    /* Quit if EOF on first screen */
    squeeze = 0;        /* Squeeze multiple blank lines into one */
    tabstop = 0;        /* Tab settings */
    back_scroll = 0;        /* Repaint screen on backwards movement */
    forw_scroll = 0;        /* Repaint screen on forward movement */
    caseless = 0;        /* Do "caseless" searches */
    linenums = 0;        /* Use line numbers */
    autobuf = 0;        /* Automatically allocate buffers as needed */
    bufspace = 0;        /* Max buffer space per file (K) */
    ctldisp = 0;        /* Send control chars to screen untranslated */
    force_open = 0;        /* Open the file even if not regular file */
    swindow = 0;        /* Size of scrolling window */
    jump_sline = 0;        /* Screen line of "jump target" */
    jump_sline_fraction = -1;
    shift_count_fraction = -1;
    chopline = 0;        /* Truncate displayed lines at screen width */
    no_init = 0;        /* Disable sending ti/te termcap strings */
    no_keypad = 0;        /* Disable sending ks/ke termcap strings */
    twiddle = 0;             /* Show tildes after EOF */
    show_attn = 0;        /* Hilite first unread line */
    shift_count = 0;        /* Number of positions to shift horizontally */
    dashn_numline_count = 0;    /* Number of lines override (Unix 2003) */
    status_col = 0;        /* Display a status column */
    use_lessopen = 0;    /* Use the LESSOPEN filter */
    quit_on_intr = 0;    /* Quit on interrupt */
    follow_mode = 0;        /* F cmd Follows file desc or file name? */
    oldbot = 0;        /* Old bottom of screen behavior {{REMOVE}} */
    opt_use_backslash = 0;    /* Use backslash escaping in option parsing */
#if HILITE_SEARCH
    hilite_search = 0;    /* Highlight matched search patterns? */
#endif
#if LOGFILE
    logfile = -1;
    force_logfile = FALSE;
    namelogfile = NULL;
#endif
#if SPACES_IN_FILENAMES
    openquote = '"';
    closequote = '"';
#endif
    // from optfunc.c
#if TAGS
    public char *tagoption = NULL;
#endif
    sc_width = 0;
    sc_height = 0;
    quitting = 0;
    secure = 0;
    dohelp = 0;
    // from output.c:
    errmsgs = 0;    /* Count of messages displayed by error() */
    need_clr = 0;
    final_attr = 0;
    at_prompt = 0;



	if (COMPAT_MODE("bin/more", "unix2003")) {
		unix2003_compat = 1;
	}
#ifdef __EMX__
	_response(&argc, &argv);
	_wildcard(&argc, &argv);
#endif

	progname = *argv++;
	argc--;

	secure = 0;
	s = lgetenv("LESSSECURE");
	if (s != NULL && *s != '\0')
		secure = 1;

#ifdef WIN32
	if (getenv("HOME") == NULL)
	{
		/*
		 * If there is no HOME environment variable,
		 * try the concatenation of HOMEDRIVE + HOMEPATH.
		 */
		char *drive = getenv("HOMEDRIVE");
		char *path  = getenv("HOMEPATH");
		if (drive != NULL && path != NULL)
		{
			char *env = (char *) ecalloc(strlen(drive) + 
					strlen(path) + 6, sizeof(char));
			strcpy(env, "HOME=");
			strcat(env, drive);
			strcat(env, path);
			putenv(env);
		}
	}
	GetConsoleTitle(consoleTitle, sizeof(consoleTitle)/sizeof(char));
#endif /* WIN32 */

	is_tty = ios_isatty(1);
	get_term();
	init_cmds();
	init_charset();
	init_line();
	init_cmdhist();
	init_option();
	init_search();

	/*
	 * If the name of the executable program is "more",
	 * act like LESS_IS_MORE is set.
	 */
	for (s = progname + strlen(progname);  s > progname;  s--)
	{
		if (s[-1] == PATHNAME_SEP[0])
			break;
	}
	if (strcmp(s, "more") == 0)
		less_is_more = 1;
	else
		unix2003_compat = 0;
	init_prompt();
	if (less_is_more) {
		if (!unix2003_compat) {
			scan_option("-E");
		}
		scan_option("-m");
		scan_option("-G");
		scan_option("-X"); /* avoid alternate screen */
		scan_option("-A"); /* search avoids current screen */
	}
	s = lgetenv(less_is_more ? "MORE" : "LESS");
	if (s != NULL)
		scan_option(save(s));

#define	isoptstring(s)	(((s)[0] == '-' || (s)[0] == '+') && (s)[1] != '\0')
	while (argc > 0 && (isoptstring(*argv) || isoptpending()))
	{
		s = *argv++;
		argc--;
		if (strcmp(s, "--") == 0)
			break;
		scan_option(s);
	}
#undef isoptstring

	if (isoptpending())
	{
		/*
		 * Last command line option was a flag requiring a
		 * following string, but there was no following string.
		 */
		nopendopt();
		quit(QUIT_OK);
	}

#if EDITOR
	editor = lgetenv("VISUAL");
	if (editor == NULL || *editor == '\0')
	{
		editor = lgetenv("EDITOR");
		if (editor == NULL || *editor == '\0')
			editor = EDIT_PGM;
	}
	editproto = lgetenv("LESSEDIT");
	if (editproto == NULL || *editproto == '\0')
	{
		if (unix2003_compat) {
			editproto = "%E ?l+%l. %f";
		} else {
			editproto = "%E ?lm+%lm. %f";
		}
	}
#endif
	if (less_is_more) {
		if (unix2003_compat) {
			/* If -n option appears, force screen size override */
			get_term();
		}
	}

	/*
	 * Call get_ifile with all the command line filenames
	 * to "register" them with the ifile system.
	 */
	ifile = NULL_IFILE;
	if (dohelp)
		ifile = get_ifile(FAKE_HELPFILE, ifile);
	while (argc-- > 0)
	{
		char *filename;
#if (MSDOS_COMPILER && MSDOS_COMPILER != DJGPPC)
		/*
		 * Because the "shell" doesn't expand filename patterns,
		 * treat each argument as a filename pattern rather than
		 * a single filename.  
		 * Expand the pattern and iterate over the expanded list.
		 */
		struct textlist tlist;
		char *gfilename;
		
		gfilename = lglob(*argv++);
		init_textlist(&tlist, gfilename);
		filename = NULL;
		while ((filename = forw_textlist(&tlist, filename)) != NULL)
		{
			(void) get_ifile(filename, ifile);
			ifile = prev_ifile(NULL_IFILE);
		}
		free(gfilename);
#else
		filename = shell_quote(*argv);
		if (filename == NULL)
			filename = *argv;
		argv++;
		(void) get_ifile(filename, ifile);
		ifile = prev_ifile(NULL_IFILE);
		free(filename);
#endif
	}
	/*
	 * Set up terminal, etc.
	 */
	if (!is_tty)
	{
		/*
		 * Output is not a tty.
		 * Just copy the input file(s) to output.
		 */
		SET_BINARY(1);
		if (nifile() == 0)
		{
			if (edit_stdin() == 0)
				cat_file();
			else
				file_errors++;
		} else if (edit_first() == 0)
		{
			do {
				cat_file();
			} while (edit_next(1) == 0);
		} else
			file_errors++;
		if (file_errors) {
			if (unix2003_compat) 
				quit(QUIT_ERROR);
		}
		quit(QUIT_OK);
	}

	if (missing_cap && !know_dumb && !less_is_more)
		error("WARNING: terminal is not fully functional", NULL_PARG);
	init_mark();
	open_getchr();
	raw_mode(1);
	init_signals(1);

	/*
	 * Select the first file to examine.
	 */
#if TAGS
	if (tagoption != NULL || strcmp(tags, "-") == 0)
	{
		int tags_skip_other_files = 1;
		/*
		 * A -t option was given.
		 * Verify that no filenames were also given.
		 * Edit the file selected by the "tags" search,
		 * and search for the proper line in the file.
		 */
		if (unix2003_compat) {
			tags_skip_other_files = 0;
		} else {
			if (nifile() > 0)
			{
				error("No filenames allowed with -t option", NULL_PARG);
				quit(QUIT_ERROR);
			}
		}
		findtag(tagoption);
		if (edit_tagfile())  /* Edit file which contains the tag */
			quit(QUIT_ERROR);
		/*
		 * Search for the line which contains the tag.
		 * Set up initial_scrpos so we display that line.
		 */
		initial_scrpos.pos = tagsearch();
		if (initial_scrpos.pos == NULL_POSITION)
			quit(QUIT_ERROR);
		initial_scrpos.ln = jump_sline;
		if (!tags_skip_other_files) {
			/* TBD: -t under unix2003 requires other files on
			   command line to be processed after tagfile, but
			   conformance tests do not test this feature
			 */
		}
	}
	else
#endif
	if (nifile() == 0)
	{
		if (edit_stdin())  /* Edit standard input */
			quit(QUIT_ERROR);
	} else 
	{
		if (edit_first())  /* Edit first valid file in cmd line */
			quit(QUIT_ERROR);
	}

	init();
	commands();
	if (file_errors) {
		if (unix2003_compat) 
			quit(QUIT_ERROR);
	}
	quit(QUIT_OK);
	/*NOTREACHED*/
	return (0);
}

/*
 * Copy a string to a "safe" place
 * (that is, to a buffer allocated by calloc).
 */
	public char *
save(s)
	char *s;
{
	register char *p;

	p = (char *) ecalloc(strlen(s)+1, sizeof(char));
	strcpy(p, s);
	return (p);
}

/*
 * Allocate memory.
 * Like calloc(), but never returns an error (NULL).
 */
	public VOID_POINTER
ecalloc(count, size)
	int count;
	unsigned int size;
{
	register VOID_POINTER p;

	p = (VOID_POINTER) calloc(count, size);
	if (p != NULL)
		return (p);
	error("Cannot allocate memory", NULL_PARG);
	quit(QUIT_ERROR);
	/*NOTREACHED*/
	return (NULL);
}

/*
 * Skip leading spaces in a string.
 */
	public char *
skipsp(s)
	register char *s;
{
	while (*s == ' ' || *s == '\t')	
		s++;
	return (s);
}

/*
 * See how many characters of two strings are identical.
 * If uppercase is true, the first string must begin with an uppercase
 * character; the remainder of the first string may be either case.
 */
	public int
sprefix(ps, s, uppercase)
	char *ps;
	char *s;
	int uppercase;
{
	register int c;
	register int sc;
	register int len = 0;

	for ( ;  *s != '\0';  s++, ps++)
	{
		c = *ps;
		if (uppercase)
		{
			if (len == 0 && ASCII_IS_LOWER(c))
				return (-1);
			if (ASCII_IS_UPPER(c))
				c = ASCII_TO_LOWER(c);
		}
		sc = *s;
		if (len > 0 && ASCII_IS_UPPER(sc))
			sc = ASCII_TO_LOWER(sc);
		if (c != sc)
			break;
		len++;
	}
	return (len);
}

/*
 * Exit the program.
 */
	public void
quit(status)
	int status;
{
	static int save_status;

	/*
	 * Put cursor at bottom left corner, clear the line,
	 * reset the terminal modes, and exit.
	 */
	if (status < 0)
		status = save_status;
	else
		save_status = status;
	quitting = 1;
    // iOS:
    while (curr_ifile != NULL_IFILE)
        del_ifile(curr_ifile);
    clean_cmds();
    //
	edit((char*)NULL);
	save_cmdhist();
    if (any_display && is_tty)
		clear_bot();
    deinit();
	flush();
	raw_mode(0);
#if MSDOS_COMPILER && MSDOS_COMPILER != DJGPPC
	/* 
	 * If we don't close 2, we get some garbage from
	 * 2's buffer when it flushes automatically.
	 * I cannot track this one down  RB
	 * The same bug shows up if we use ^C^C to abort.
	 */
	close(2);
#endif
#ifdef WIN32
	SetConsoleTitle(consoleTitle);
#endif
	close_getchr();
    lower_left(); // iOS, required in some cases.
    flush();
	exit(status);
}
