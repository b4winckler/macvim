/* vi:set ts=8 sts=4 sw=4 noet:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 */

/*
 * This file contains the defines for the machine dependent escape sequences
 * that the editor needs to perform various operations. All of the sequences
 * here are optional, except "cm" (cursor motion).
 */

#if defined(SASC) && SASC < 658
/*
 * The SAS C compiler has a bug that makes typedefs being forgot in include
 * files.  Has been fixed in version 6.58.
 */
typedef unsigned char char_u;
#endif

/*
 * Index of the termcap codes in the term_strings array.
 */
enum SpecialKey
{
    KS_NAME = 0,/* name of this terminal entry */
    KS_CE,	/* clear to end of line */
    KS_AL,	/* add new blank line */
    KS_CAL,	/* add number of blank lines */
    KS_DL,	/* delete line */
    KS_CDL,	/* delete number of lines */
    KS_CS,	/* scroll region */
    KS_CL,	/* clear screen */
    KS_CD,	/* clear to end of display */
    KS_UT,	/* clearing uses current background color */
    KS_DA,	/* text may be scrolled down from up */
    KS_DB,	/* text may be scrolled up from down */
    KS_VI,	/* cursor invisible */
    KS_VE,	/* cursor visible */
    KS_VS,	/* cursor very visible */
    KS_ME,	/* normal mode */
    KS_MR,	/* reverse mode */
    KS_MD,	/* bold mode */
    KS_SE,	/* normal mode */
    KS_SO,	/* standout mode */
    KS_CZH,	/* italic mode start */
    KS_CZR,	/* italic mode end */
    KS_UE,	/* exit underscore (underline) mode */
    KS_US,	/* underscore (underline) mode */
    KS_UCE,	/* exit undercurl mode */
    KS_UCS,	/* undercurl mode */
    KS_MS,	/* save to move cur in reverse mode */
    KS_CM,	/* cursor motion */
    KS_SR,	/* scroll reverse (backward) */
    KS_CRI,	/* cursor number of chars right */
    KS_VB,	/* visual bell */
    KS_KS,	/* put term in "keypad transmit" mode */
    KS_KE,	/* out of "keypad transmit" mode */
    KS_TI,	/* put terminal in termcap mode */
    KS_TE,	/* out of termcap mode */
    KS_BC,	/* backspace character (cursor left) */
    KS_CCS,	/* cur is relative to scroll region */
    KS_CCO,	/* number of colors */
    KS_CSF,	/* set foreground color */
    KS_CSB,	/* set background color */
    KS_XS,	/* standout not erased by overwriting (hpterm) */
    KS_XN,	/* newline glitch */
    KS_MB,	/* blink mode */
    KS_CAF,	/* set foreground color (ANSI) */
    KS_CAB,	/* set background color (ANSI) */
    KS_LE,	/* cursor left (mostly backspace) */
    KS_ND,	/* cursor right */
    KS_CIS,	/* set icon text start */
    KS_CIE,	/* set icon text end */
    KS_TS,	/* set window title start (to status line)*/
    KS_FS,	/* set window title end (from status line) */
    KS_CWP,	/* set window position in pixels */
    KS_CGP,	/* get window position */
    KS_CWS,	/* set window size in characters */
    KS_CRV,	/* request version string */
    KS_RBG,	/* request background color */
    KS_CSI,	/* start insert mode (bar cursor) */
    KS_CEI,	/* end insert mode (block cursor) */
    KS_CSR,	/* start replace mode (underline cursor) */
#ifdef FEAT_WINDOWS
    KS_CSV,	/* scroll region vertical */
#endif
    KS_OP,	/* original color pair */
    KS_U7,	/* request cursor position */
    KS_8F,	/* set foreground color (RGB) */
    KS_8B,	/* set background color (RGB) */
    KS_CBE,	/* enable bracketed paste mode */
    KS_CBD,	/* disable bracketed paste mode */
    KS_CPS,	/* start of bracketed paste */
    KS_CPE	/* end of bracketed paste */
};

#define KS_LAST	    KS_CPE

/*
 * the terminal capabilities are stored in this array
 * IMPORTANT: When making changes, note the following:
 * - there should be an entry for each code in the builtin termcaps
 * - there should be an option for each code in option.c
 * - there should be code in term.c to obtain the value from the termcap
 */

extern char_u *(term_strings[]);    /* current terminal strings */

/*
 * strings used for terminal
 */
#define T_NAME	(TERM_STR(KS_NAME))	/* terminal name */
#define T_CE	(TERM_STR(KS_CE))	/* clear to end of line */
#define T_AL	(TERM_STR(KS_AL))	/* add new blank line */
#define T_CAL	(TERM_STR(KS_CAL))	/* add number of blank lines */
#define T_DL	(TERM_STR(KS_DL))	/* delete line */
#define T_CDL	(TERM_STR(KS_CDL))	/* delete number of lines */
#define T_CS	(TERM_STR(KS_CS))	/* scroll region */
#define T_CSV	(TERM_STR(KS_CSV))	/* scroll region vertical */
#define T_CL	(TERM_STR(KS_CL))	/* clear screen */
#define T_CD	(TERM_STR(KS_CD))	/* clear to end of display */
#define T_UT	(TERM_STR(KS_UT))	/* clearing uses background color */
#define T_DA	(TERM_STR(KS_DA))	/* text may be scrolled down from up */
#define T_DB	(TERM_STR(KS_DB))	/* text may be scrolled up from down */
#define T_VI	(TERM_STR(KS_VI))	/* cursor invisible */
#define T_VE	(TERM_STR(KS_VE))	/* cursor visible */
#define T_VS	(TERM_STR(KS_VS))	/* cursor very visible */
#define T_ME	(TERM_STR(KS_ME))	/* normal mode */
#define T_MR	(TERM_STR(KS_MR))	/* reverse mode */
#define T_MD	(TERM_STR(KS_MD))	/* bold mode */
#define T_SE	(TERM_STR(KS_SE))	/* normal mode */
#define T_SO	(TERM_STR(KS_SO))	/* standout mode */
#define T_CZH	(TERM_STR(KS_CZH))	/* italic mode start */
#define T_CZR	(TERM_STR(KS_CZR))	/* italic mode end */
#define T_UE	(TERM_STR(KS_UE))	/* exit underscore (underline) mode */
#define T_US	(TERM_STR(KS_US))	/* underscore (underline) mode */
#define T_UCE	(TERM_STR(KS_UCE))	/* exit undercurl mode */
#define T_UCS	(TERM_STR(KS_UCS))	/* undercurl mode */
#define T_MS	(TERM_STR(KS_MS))	/* save to move cur in reverse mode */
#define T_CM	(TERM_STR(KS_CM))	/* cursor motion */
#define T_SR	(TERM_STR(KS_SR))	/* scroll reverse (backward) */
#define T_CRI	(TERM_STR(KS_CRI))	/* cursor number of chars right */
#define T_VB	(TERM_STR(KS_VB))	/* visual bell */
#define T_KS	(TERM_STR(KS_KS))	/* put term in "keypad transmit" mode */
#define T_KE	(TERM_STR(KS_KE))	/* out of "keypad transmit" mode */
#define T_TI	(TERM_STR(KS_TI))	/* put terminal in termcap mode */
#define T_TE	(TERM_STR(KS_TE))	/* out of termcap mode */
#define T_BC	(TERM_STR(KS_BC))	/* backspace character */
#define T_CCS	(TERM_STR(KS_CCS))	/* cur is relative to scroll region */
#define T_CCO	(TERM_STR(KS_CCO))	/* number of colors */
#define T_CSF	(TERM_STR(KS_CSF))	/* set foreground color */
#define T_CSB	(TERM_STR(KS_CSB))	/* set background color */
#define T_XS	(TERM_STR(KS_XS))	/* standout not erased by overwriting */
#define T_XN	(TERM_STR(KS_XN))	/* newline glitch */
#define T_MB	(TERM_STR(KS_MB))	/* blink mode */
#define T_CAF	(TERM_STR(KS_CAF))	/* set foreground color (ANSI) */
#define T_CAB	(TERM_STR(KS_CAB))	/* set background color (ANSI) */
#define T_LE	(TERM_STR(KS_LE))	/* cursor left */
#define T_ND	(TERM_STR(KS_ND))	/* cursor right */
#define T_CIS	(TERM_STR(KS_CIS))	/* set icon text start */
#define T_CIE	(TERM_STR(KS_CIE))	/* set icon text end */
#define T_TS	(TERM_STR(KS_TS))	/* set window title start */
#define T_FS	(TERM_STR(KS_FS))	/* set window title end */
#define T_CWP	(TERM_STR(KS_CWP))	/* set window position */
#define T_CGP	(TERM_STR(KS_CGP))	/* get window position */
#define T_CWS	(TERM_STR(KS_CWS))	/* window size */
#define T_CSI	(TERM_STR(KS_CSI))	/* start insert mode */
#define T_CEI	(TERM_STR(KS_CEI))	/* end insert mode */
#define T_CSR	(TERM_STR(KS_CSR))	/* start replace mode */
#define T_CRV	(TERM_STR(KS_CRV))	/* request version string */
#define T_RBG	(TERM_STR(KS_RBG))	/* request background RGB */
#define T_OP	(TERM_STR(KS_OP))	/* original color pair */
#define T_U7	(TERM_STR(KS_U7))	/* request cursor position */
#define T_8F	(TERM_STR(KS_8F))	/* set foreground color (RGB) */
#define T_8B	(TERM_STR(KS_8B))	/* set background color (RGB) */
#define T_BE	(TERM_STR(KS_CBE))	/* enable bracketed paste mode */
#define T_BD	(TERM_STR(KS_CBD))	/* disable bracketed paste mode */
#define T_PS	(TERM_STR(KS_CPS))	/* start of bracketed paste */
#define T_PE	(TERM_STR(KS_CPE))	/* end of bracketed paste */

#define TMODE_COOK  0	/* terminal mode for external cmds and Ex mode */
#define TMODE_SLEEP 1	/* terminal mode for sleeping (cooked but no echo) */
#define TMODE_RAW   2	/* terminal mode for Normal and Insert mode */
