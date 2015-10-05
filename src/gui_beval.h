/* vi:set ts=8 sts=4 sw=4:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *			Visual Workshop integration by Gordon Prieur
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 */

#if !defined(GUI_BEVAL_H) && (defined(FEAT_BEVAL) || defined(PROTO))
#define GUI_BEVAL_H

#ifdef FEAT_GUI_GTK
# include <gtk/gtkwidget.h>
#else
# if defined(FEAT_GUI_X11)
#  include <X11/Intrinsic.h>
# endif
#endif

typedef enum
{
    ShS_NEUTRAL,			/* nothing showing or pending */
    ShS_PENDING,			/* data requested from debugger */
    ShS_UPDATE_PENDING,			/* switching information displayed */
    ShS_SHOWING				/* the balloon is being displayed */
} BeState;

typedef struct BalloonEvalStruct
{
#ifdef FEAT_GUI_GTK
    GtkWidget		*target;	/* widget we are monitoring */
    GtkWidget		*balloonShell;
    GtkWidget		*balloonLabel;
    unsigned int	timerID;	/* timer for run */
    BeState		showState;	/* tells us whats currently going on */
    int			x;
    int			y;
    unsigned int	state;		/* Button/Modifier key state */
#elif defined(FEAT_GUI_MACVIM)
    int			x;
    int			y;
#else
# if !defined(FEAT_GUI_W32)
    Widget		target;		/* widget we are monitoring */
    Widget		balloonShell;
    Widget		balloonLabel;
    XtIntervalId	timerID;	/* timer for run */
    BeState		showState;	/* tells us whats currently going on */
    XtAppContext	appContext;	/* used in event handler */
    Position		x;
    Position		y;
    Position		x_root;
    Position		y_root;
    int			state;		/* Button/Modifier key state */
# else
    HWND		target;
    HWND		balloon;
    int			x;
    int			y;
    BeState		showState;	/* tells us whats currently going on */
# endif
#endif
    int			ts;		/* tabstop setting for this buffer */
    char_u		*msg;
    void		(*msgCB)__ARGS((struct BalloonEvalStruct *, int));
    void		*clientData;	/* For callback */
#if !defined(FEAT_GUI_GTK) && !defined(FEAT_GUI_W32) \
	&& !defined(FEAT_GUI_MACVIM)
    Dimension		screen_width;	/* screen width in pixels */
    Dimension		screen_height;	/* screen height in pixels */
#endif
} BalloonEval;

#define EVAL_OFFSET_X 15 /* displacement of beval topleft corner from pointer */
#define EVAL_OFFSET_Y 10

#include "gui_beval.pro"

#endif /* GUI_BEVAL_H and FEAT_BEVAL */
