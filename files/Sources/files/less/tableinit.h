static unsigned char cmdtable_init[] =
{
	'\r',0,				A_F_LINE,
	'\n',0,				A_F_LINE,
	'e',0,				A_F_LINE,
	'j',0,				A_F_LINE,
	SK(SK_DOWN_ARROW),0,		A_F_LINE,
	CONTROL('E'),0,			A_F_LINE,
	CONTROL('N'),0,			A_F_LINE,
	'k',0,				A_B_LINE,
	'y',0,				A_B_LINE,
	CONTROL('Y'),0,			A_B_LINE,
	SK(SK_CONTROL_K),0,		A_B_LINE,
	CONTROL('P'),0,			A_B_LINE,
	SK(SK_UP_ARROW),0,		A_B_LINE,
	'J',0,				A_FF_LINE,
	'K',0,				A_BF_LINE,
	'Y',0,				A_BF_LINE,
	'd',0,				A_F_SCROLL,
	CONTROL('D'),0,			A_F_SCROLL,
	'u',0,				A_B_SCROLL,
	CONTROL('U'),0,			A_B_SCROLL,
	' ',0,				A_F_SCREEN,
	'f',0,				A_F_SCREEN,
	CONTROL('F'),0,			A_F_SCREEN,
	CONTROL('V'),0,			A_F_SCREEN,
	SK(SK_PAGE_DOWN),0,		A_F_SCREEN,
	'b',0,				A_B_SCREEN,
	CONTROL('B'),0,			A_B_SCREEN,
	ESC,'v',0,			A_B_SCREEN,
	SK(SK_PAGE_UP),0,		A_B_SCREEN,
	'z',0,				A_F_WINDOW,
	'w',0,				A_B_WINDOW,
	ESC,' ',0,			A_FF_SCREEN,
	'F',0,				A_F_FOREVER,
	ESC,'F',0,			A_F_UNTIL_HILITE,
	'R',0,				A_FREPAINT,
	'r',0,				A_REPAINT,
	CONTROL('R'),0,			A_REPAINT,
	CONTROL('L'),0,			A_REPAINT,
	ESC,'u',0,			A_UNDO_SEARCH,
	'g',0,				A_GOLINE,
	SK(SK_HOME),0,			A_GOLINE,
	'<',0,				A_GOLINE,
	ESC,'<',0,			A_GOLINE,
	'p',0,				A_PERCENT,
	'%',0,				A_PERCENT,
	ESC,'[',0,			A_LSHIFT,
	ESC,']',0,			A_RSHIFT,
	ESC,'(',0,			A_LSHIFT,
	ESC,')',0,			A_RSHIFT,
	ESC,'{',0,			A_LLSHIFT,
	ESC,'}',0,			A_RRSHIFT,
	SK(SK_RIGHT_ARROW),0,		A_RSHIFT,
	SK(SK_LEFT_ARROW),0,		A_LSHIFT,
	SK(SK_CTL_RIGHT_ARROW),0,	A_RRSHIFT,
	SK(SK_CTL_LEFT_ARROW),0,	A_LLSHIFT,
	'{',0,				A_F_BRACKET|A_EXTRA,	'{','}',0,
	'}',0,				A_B_BRACKET|A_EXTRA,	'{','}',0,
	'(',0,				A_F_BRACKET|A_EXTRA,	'(',')',0,
	')',0,				A_B_BRACKET|A_EXTRA,	'(',')',0,
	'[',0,				A_F_BRACKET|A_EXTRA,	'[',']',0,
	']',0,				A_B_BRACKET|A_EXTRA,	'[',']',0,
	ESC,CONTROL('F'),0,		A_F_BRACKET,
	ESC,CONTROL('B'),0,		A_B_BRACKET,
	'G',0,				A_GOEND,
	ESC,'G',0,			A_GOEND_BUF,
	ESC,'>',0,			A_GOEND,
	'>',0,				A_GOEND,
	SK(SK_END),0,			A_GOEND,
	'P',0,				A_GOPOS,

	'0',0,				A_DIGIT,
	'1',0,				A_DIGIT,
	'2',0,				A_DIGIT,
	'3',0,				A_DIGIT,
	'4',0,				A_DIGIT,
	'5',0,				A_DIGIT,
	'6',0,				A_DIGIT,
	'7',0,				A_DIGIT,
	'8',0,				A_DIGIT,
	'9',0,				A_DIGIT,
	'.',0,				A_DIGIT,

	'=',0,				A_STAT,
	CONTROL('G'),0,			A_STAT,
	':','f',0,			A_STAT,
	'/',0,				A_F_SEARCH,
	'?',0,				A_B_SEARCH,
	ESC,'/',0,			A_F_SEARCH|A_EXTRA,	'*',0,
	ESC,'?',0,			A_B_SEARCH|A_EXTRA,	'*',0,
	'n',0,				A_AGAIN_SEARCH,
	ESC,'n',0,			A_T_AGAIN_SEARCH,
	'N',0,				A_REVERSE_SEARCH,
	ESC,'N',0,			A_T_REVERSE_SEARCH,
	'&',0,				A_FILTER,
	'm',0,				A_SETMARK,
	'\'',0,				A_GOMARK,
	CONTROL('X'),CONTROL('X'),0,	A_GOMARK,
	'E',0,				A_EXAMINE,
	':','e',0,			A_EXAMINE,
	CONTROL('X'),CONTROL('V'),0,	A_EXAMINE,
	':','n',0,			A_NEXT_FILE,
	':','p',0,			A_PREV_FILE,
	't',0,				A_NEXT_TAG,
	'T',0,				A_PREV_TAG,
	':','x',0,			A_INDEX_FILE,
	':','d',0,			A_REMOVE_FILE,
	'-',0,				A_OPT_TOGGLE,
	':','t',0,			A_OPT_TOGGLE|A_EXTRA,	't',0,
	's',0,				A_OPT_TOGGLE|A_EXTRA,	'o',0,
	'_',0,				A_DISP_OPTION,
	'|',0,				A_PIPE,
	'v',0,				A_VISUAL,
	'!',0,				A_SHELL,
	'+',0,				A_FIRSTCMD,

	'H',0,				A_HELP,
	'h',0,				A_HELP,
	SK(SK_F1),0,			A_HELP,
	'V',0,				A_VERSION,
	'q',0,				A_QUIT,
	'Q',0,				A_QUIT,
	':','q',0,			A_QUIT,
	':','Q',0,			A_QUIT,
	'Z','Z',0,			A_QUIT
};

/* 
 * Command table for UNIX 2003 compatibility: added first before builtin
 * so that these commands override the normal LESS commands
 */

static unsigned char UNIX03cmdtable_init[] =
{
	's',0,				A_F_LINE
};

static unsigned char edittable_init[] =
{
	'\t',0,	    			EC_F_COMPLETE,	/* TAB */
	'\17',0,			EC_B_COMPLETE,	/* BACKTAB */
	SK(SK_BACKTAB),0,		EC_B_COMPLETE,	/* BACKTAB */
	ESC,'\t',0,			EC_B_COMPLETE,	/* ESC TAB */
	CONTROL('L'),0,			EC_EXPAND,	/* CTRL-L */
	CONTROL('V'),0,			EC_LITERAL,	/* BACKSLASH */
	CONTROL('A'),0,			EC_LITERAL,	/* BACKSLASH */
   	ESC,'l',0,			EC_RIGHT,	/* ESC l */
	SK(SK_RIGHT_ARROW),0,		EC_RIGHT,	/* RIGHTARROW */
	ESC,'h',0,			EC_LEFT,	/* ESC h */
	SK(SK_LEFT_ARROW),0,		EC_LEFT,	/* LEFTARROW */
	ESC,'b',0,			EC_W_LEFT,	/* ESC b */
	ESC,SK(SK_LEFT_ARROW),0,	EC_W_LEFT,	/* ESC LEFTARROW */
	SK(SK_CTL_LEFT_ARROW),0,	EC_W_LEFT,	/* CTRL-LEFTARROW */
	ESC,'w',0,			EC_W_RIGHT,	/* ESC w */
	ESC,SK(SK_RIGHT_ARROW),0,	EC_W_RIGHT,	/* ESC RIGHTARROW */
	SK(SK_CTL_RIGHT_ARROW),0,	EC_W_RIGHT,	/* CTRL-RIGHTARROW */
	ESC,'i',0,			EC_INSERT,	/* ESC i */
	SK(SK_INSERT),0,		EC_INSERT,	/* INSERT */
	ESC,'x',0,			EC_DELETE,	/* ESC x */
	SK(SK_DELETE),0,		EC_DELETE,	/* DELETE */
	ESC,'X',0,			EC_W_DELETE,	/* ESC X */
	ESC,SK(SK_DELETE),0,		EC_W_DELETE,	/* ESC DELETE */
	SK(SK_CTL_DELETE),0,		EC_W_DELETE,	/* CTRL-DELETE */
	SK(SK_CTL_BACKSPACE),0,		EC_W_BACKSPACE, /* CTRL-BACKSPACE */
	ESC,'\b',0,			EC_W_BACKSPACE,	/* ESC BACKSPACE */
	ESC,'0',0,			EC_HOME,	/* ESC 0 */
	SK(SK_HOME),0,			EC_HOME,	/* HOME */
	ESC,'$',0,			EC_END,		/* ESC $ */
	SK(SK_END),0,			EC_END,		/* END */
	ESC,'k',0,			EC_UP,		/* ESC k */
	SK(SK_UP_ARROW),0,		EC_UP,		/* UPARROW */
	ESC,'j',0,			EC_DOWN,	/* ESC j */
	SK(SK_DOWN_ARROW),0,		EC_DOWN,	/* DOWNARROW */
	CONTROL('G'),0,			EC_ABORT,	/* CTRL-G */
};

