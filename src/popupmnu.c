/* vi:set ts=8 sts=4 sw=4 noet:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */

/*
 * popupmnu.c: Popup menu (PUM)
 */
#include "vim.h"

#if defined(FEAT_INS_EXPAND) || defined(PROTO)

static pumitem_T *pum_array = NULL;	/* items of displayed pum */
static int pum_size;			/* nr of items in "pum_array" */
static int pum_selected;		/* index of selected item or -1 */
static int pum_first = 0;		/* index of top item */

static int pum_height;			/* nr of displayed pum items */
static int pum_width;			/* width of displayed pum items */
static int pum_base_width;		/* width of pum items base */
static int pum_kind_width;		/* width of pum items kind column */
static int pum_scrollbar;		/* TRUE when scrollbar present */

static int pum_row;			/* top row of pum */
static int pum_col;			/* left column of pum */

static int pum_do_redraw = FALSE;	/* do redraw anyway */

static int pum_set_selected(int n, int repeat);

#define PUM_DEF_HEIGHT 10
#define PUM_DEF_WIDTH  15

/*
 * Show the popup menu with items "array[size]".
 * "array" must remain valid until pum_undisplay() is called!
 * When possible the leftmost character is aligned with screen column "col".
 * The menu appears above the screen line "row" or at "row" + "height" - 1.
 */
    void
pum_display(
    pumitem_T	*array,
    int		size,
    int		selected)	/* index of initially selected item, none if
				   out of range */
{
    int		w;
    int		def_width;
    int		max_width;
    int		kind_width;
    int		extra_width;
    int		i;
    int		row;
    int		context_lines;
    int		col;
    int		above_row;
    int		below_row;
    int		redo_count = 0;
#if defined(FEAT_WINDOWS) && defined(FEAT_QUICKFIX)
    win_T	*pvwin;
#endif

redo:
    def_width = PUM_DEF_WIDTH;
    max_width = 0;
    kind_width = 0;
    extra_width = 0;
    above_row = 0;
    below_row = cmdline_row;

    /* Pretend the pum is already there to avoid that must_redraw is set when
     * 'cuc' is on. */
    pum_array = (pumitem_T *)1;
    validate_cursor_col();
    pum_array = NULL;

    row = curwin->w_wrow + W_WINROW(curwin);

#if defined(FEAT_WINDOWS) && defined(FEAT_QUICKFIX)
    FOR_ALL_WINDOWS(pvwin)
	if (pvwin->w_p_pvw)
	    break;
    if (pvwin != NULL)
    {
	if (W_WINROW(pvwin) < W_WINROW(curwin))
	    above_row = W_WINROW(pvwin) + pvwin->w_height;
	else if (W_WINROW(pvwin) > W_WINROW(curwin) + curwin->w_height)
	    below_row = W_WINROW(pvwin);
    }
#endif

    /*
     * Figure out the size and position of the pum.
     */
    if (size < PUM_DEF_HEIGHT)
	pum_height = size;
    else
	pum_height = PUM_DEF_HEIGHT;
    if (p_ph > 0 && pum_height > p_ph)
	pum_height = p_ph;

    /* Put the pum below "row" if possible.  If there are few lines decide on
     * where there is more room. */
    if (row + 2 >= below_row - pum_height
			    && row - above_row > (below_row - above_row) / 2)
    {
	/* pum above "row" */

	/* Leave two lines of context if possible */
	if (curwin->w_wrow - curwin->w_cline_row >= 2)
	    context_lines = 2;
	else
	    context_lines = curwin->w_wrow - curwin->w_cline_row;

	if (row >= size + context_lines)
	{
	    pum_row = row - size - context_lines;
	    pum_height = size;
	}
	else
	{
	    pum_row = 0;
	    pum_height = row - context_lines;
	}
	if (p_ph > 0 && pum_height > p_ph)
	{
	    pum_row += pum_height - p_ph;
	    pum_height = p_ph;
	}
    }
    else
    {
	/* pum below "row" */

	/* Leave two lines of context if possible */
	if (curwin->w_cline_row + curwin->w_cline_height - curwin->w_wrow >= 3)
	    context_lines = 3;
	else
	    context_lines = curwin->w_cline_row
				+ curwin->w_cline_height - curwin->w_wrow;

	pum_row = row + context_lines;
	if (size > below_row - pum_row)
	    pum_height = below_row - pum_row;
	else
	    pum_height = size;
	if (p_ph > 0 && pum_height > p_ph)
	    pum_height = p_ph;
    }

    /* don't display when we only have room for one line */
    if (pum_height < 1 || (pum_height == 1 && size > 1))
	return;

#if defined(FEAT_WINDOWS) && defined(FEAT_QUICKFIX)
    /* If there is a preview window at the above avoid drawing over it. */
    if (pvwin != NULL && pum_row < above_row && pum_height > above_row)
    {
	pum_row += above_row;
	pum_height -= above_row;
    }
#endif

    /* Compute the width of the widest match and the widest extra. */
    for (i = 0; i < size; ++i)
    {
	w = vim_strsize(array[i].pum_text);
	if (max_width < w)
	    max_width = w;
	if (array[i].pum_kind != NULL)
	{
	    w = vim_strsize(array[i].pum_kind) + 1;
	    if (kind_width < w)
		kind_width = w;
	}
	if (array[i].pum_extra != NULL)
	{
	    w = vim_strsize(array[i].pum_extra) + 1;
	    if (extra_width < w)
		extra_width = w;
	}
    }
    pum_base_width = max_width;
    pum_kind_width = kind_width;

    /* Calculate column */
#ifdef FEAT_RIGHTLEFT
    if (curwin->w_p_rl)
	col = W_WINCOL(curwin) + W_WIDTH(curwin) - curwin->w_wcol - 1;
    else
#endif
	col = W_WINCOL(curwin) + curwin->w_wcol;

    /* if there are more items than room we need a scrollbar */
    if (pum_height < size)
    {
	pum_scrollbar = 1;
	++max_width;
    }
    else
	pum_scrollbar = 0;

    if (def_width < max_width)
	def_width = max_width;

    if (((col < Columns - PUM_DEF_WIDTH || col < Columns - max_width)
#ifdef FEAT_RIGHTLEFT
		&& !curwin->w_p_rl)
	    || (curwin->w_p_rl && (col > PUM_DEF_WIDTH || col > max_width)
#endif
       ))
    {
	/* align pum column with "col" */
	pum_col = col;

#ifdef FEAT_RIGHTLEFT
	if (curwin->w_p_rl)
	    pum_width = pum_col - pum_scrollbar + 1;
	else
#endif
	    pum_width = Columns - pum_col - pum_scrollbar;

	if (pum_width > max_width + kind_width + extra_width + 1
						 && pum_width > PUM_DEF_WIDTH)
	{
	    pum_width = max_width + kind_width + extra_width + 1;
	    if (pum_width < PUM_DEF_WIDTH)
		pum_width = PUM_DEF_WIDTH;
	}
    }
    else if (Columns < def_width)
    {
	/* not enough room, will use what we have */
#ifdef FEAT_RIGHTLEFT
	if (curwin->w_p_rl)
	    pum_col = Columns - 1;
	else
#endif
	    pum_col = 0;
	pum_width = Columns - 1;
    }
    else
    {
	if (max_width > PUM_DEF_WIDTH)
	    max_width = PUM_DEF_WIDTH;	/* truncate */
#ifdef FEAT_RIGHTLEFT
	if (curwin->w_p_rl)
	    pum_col = max_width - 1;
	else
#endif
	    pum_col = Columns - max_width;
	pum_width = max_width - pum_scrollbar;
    }

    pum_array = array;
    pum_size = size;

    /* Set selected item and redraw.  If the window size changed need to redo
     * the positioning.  Limit this to two times, when there is not much
     * room the window size will keep changing. */
    if (pum_set_selected(selected, redo_count) && ++redo_count <= 2)
	goto redo;
}

/*
 * Redraw the popup menu, using "pum_first" and "pum_selected".
 */
    void
pum_redraw(void)
{
    int		row = pum_row;
    int		col;
    int		attr_norm = highlight_attr[HLF_PNI];
    int		attr_select = highlight_attr[HLF_PSI];
    int		attr_scroll = highlight_attr[HLF_PSB];
    int		attr_thumb = highlight_attr[HLF_PST];
    int		attr;
    int		i;
    int		idx;
    char_u	*s;
    char_u	*p = NULL;
    int		totwidth, width, w;
    int		thumb_pos = 0;
    int		thumb_heigth = 1;
    int		round;
    int		n;

    /* Never display more than we have */
    if (pum_first > pum_size - pum_height)
	pum_first = pum_size - pum_height;

    if (pum_scrollbar)
    {
	thumb_heigth = pum_height * pum_height / pum_size;
	if (thumb_heigth == 0)
	    thumb_heigth = 1;
	thumb_pos = (pum_first * (pum_height - thumb_heigth)
			    + (pum_size - pum_height) / 2)
						    / (pum_size - pum_height);
    }

    for (i = 0; i < pum_height; ++i)
    {
	idx = i + pum_first;
	attr = (idx == pum_selected) ? attr_select : attr_norm;

	/* prepend a space if there is room */
#ifdef FEAT_RIGHTLEFT
	if (curwin->w_p_rl)
	{
	    if (pum_col < W_WINCOL(curwin) + W_WIDTH(curwin) - 1)
		screen_putchar(' ', row, pum_col + 1, attr);
	}
	else
#endif
	    if (pum_col > 0)
		screen_putchar(' ', row, pum_col - 1, attr);

	/* Display each entry, use two spaces for a Tab.
	 * Do this 3 times: For the main text, kind and extra info */
	col = pum_col;
	totwidth = 0;
	for (round = 1; round <= 3; ++round)
	{
	    width = 0;
	    s = NULL;
	    switch (round)
	    {
		case 1: p = pum_array[idx].pum_text; break;
		case 2: p = pum_array[idx].pum_kind; break;
		case 3: p = pum_array[idx].pum_extra; break;
	    }
	    if (p != NULL)
		for ( ; ; MB_PTR_ADV(p))
		{
		    if (s == NULL)
			s = p;
		    w = ptr2cells(p);
		    if (*p == NUL || *p == TAB || totwidth + w > pum_width)
		    {
			/* Display the text that fits or comes before a Tab.
			 * First convert it to printable characters. */
			char_u	*st;
			int	saved = *p;

			*p = NUL;
			st = transstr(s);
			*p = saved;
#ifdef FEAT_RIGHTLEFT
			if (curwin->w_p_rl)
			{
			    if (st != NULL)
			    {
				char_u	*rt = reverse_text(st);

				if (rt != NULL)
				{
				    char_u	*rt_start = rt;
				    int		size;

				    size = vim_strsize(rt);
				    if (size > pum_width)
				    {
					do
					{
					    size -= has_mbyte
						    ? (*mb_ptr2cells)(rt) : 1;
					    MB_PTR_ADV(rt);
					} while (size > pum_width);

					if (size < pum_width)
					{
					    /* Most left character requires
					     * 2-cells but only 1 cell is
					     * available on screen.  Put a
					     * '<' on the left of the pum
					     * item */
					    *(--rt) = '<';
					    size++;
					}
				    }
				    screen_puts_len(rt, (int)STRLEN(rt),
						   row, col - size + 1, attr);
				    vim_free(rt_start);
				}
				vim_free(st);
			    }
			    col -= width;
			}
			else
#endif
			{
			    if (st != NULL)
			    {
				screen_puts_len(st, (int)STRLEN(st), row, col,
									attr);
				vim_free(st);
			    }
			    col += width;
			}

			if (*p != TAB)
			    break;

			/* Display two spaces for a Tab. */
#ifdef FEAT_RIGHTLEFT
			if (curwin->w_p_rl)
			{
			    screen_puts_len((char_u *)"  ", 2, row, col - 1,
									attr);
			    col -= 2;
			}
			else
#endif
			{
			    screen_puts_len((char_u *)"  ", 2, row, col, attr);
			    col += 2;
			}
			totwidth += 2;
			s = NULL;	    /* start text at next char */
			width = 0;
		    }
		    else
			width += w;
		}

	    if (round > 1)
		n = pum_kind_width + 1;
	    else
		n = 1;

	    /* Stop when there is nothing more to display. */
	    if (round == 3
		    || (round == 2 && pum_array[idx].pum_extra == NULL)
		    || (round == 1 && pum_array[idx].pum_kind == NULL
					  && pum_array[idx].pum_extra == NULL)
		    || pum_base_width + n >= pum_width)
		break;
#ifdef FEAT_RIGHTLEFT
	    if (curwin->w_p_rl)
	    {
		screen_fill(row, row + 1, pum_col - pum_base_width - n + 1,
						    col + 1, ' ', ' ', attr);
		col = pum_col - pum_base_width - n + 1;
	    }
	    else
#endif
	    {
		screen_fill(row, row + 1, col, pum_col + pum_base_width + n,
							      ' ', ' ', attr);
		col = pum_col + pum_base_width + n;
	    }
	    totwidth = pum_base_width + n;
	}

#ifdef FEAT_RIGHTLEFT
	if (curwin->w_p_rl)
	    screen_fill(row, row + 1, pum_col - pum_width + 1, col + 1, ' ',
								    ' ', attr);
	else
#endif
	    screen_fill(row, row + 1, col, pum_col + pum_width, ' ', ' ',
									attr);
	if (pum_scrollbar > 0)
	{
#ifdef FEAT_RIGHTLEFT
	    if (curwin->w_p_rl)
		screen_putchar(' ', row, pum_col - pum_width,
			i >= thumb_pos && i < thumb_pos + thumb_heigth
						  ? attr_thumb : attr_scroll);
	    else
#endif
		screen_putchar(' ', row, pum_col + pum_width,
			i >= thumb_pos && i < thumb_pos + thumb_heigth
						  ? attr_thumb : attr_scroll);
	}

	++row;
    }
}

/*
 * Set the index of the currently selected item.  The menu will scroll when
 * necessary.  When "n" is out of range don't scroll.
 * This may be repeated when the preview window is used:
 * "repeat" == 0: open preview window normally
 * "repeat" == 1: open preview window but don't set the size
 * "repeat" == 2: don't open preview window
 * Returns TRUE when the window was resized and the location of the popup menu
 * must be recomputed.
 */
    static int
pum_set_selected(int n, int repeat)
{
    int	    resized = FALSE;
    int	    context = pum_height / 2;

    pum_selected = n;

    if (pum_selected >= 0 && pum_selected < pum_size)
    {
	if (pum_first > pum_selected - 4)
	{
	    /* scroll down; when we did a jump it's probably a PageUp then
	     * scroll a whole page */
	    if (pum_first > pum_selected - 2)
	    {
		pum_first -= pum_height - 2;
		if (pum_first < 0)
		    pum_first = 0;
		else if (pum_first > pum_selected)
		    pum_first = pum_selected;
	    }
	    else
		pum_first = pum_selected;
	}
	else if (pum_first < pum_selected - pum_height + 5)
	{
	    /* scroll up; when we did a jump it's probably a PageDown then
	     * scroll a whole page */
	    if (pum_first < pum_selected - pum_height + 1 + 2)
	    {
		pum_first += pum_height - 2;
		if (pum_first < pum_selected - pum_height + 1)
		    pum_first = pum_selected - pum_height + 1;
	    }
	    else
		pum_first = pum_selected - pum_height + 1;
	}

	/* Give a few lines of context when possible. */
	if (context > 3)
	    context = 3;
	if (pum_height > 2)
	{
	    if (pum_first > pum_selected - context)
	    {
		/* scroll down */
		pum_first = pum_selected - context;
		if (pum_first < 0)
		    pum_first = 0;
	    }
	    else if (pum_first < pum_selected + context - pum_height + 1)
	    {
		/* scroll up */
		pum_first = pum_selected + context - pum_height + 1;
	    }
	}

#if defined(FEAT_WINDOWS) && defined(FEAT_QUICKFIX)
	/*
	 * Show extra info in the preview window if there is something and
	 * 'completeopt' contains "preview".
	 * Skip this when tried twice already.
	 * Skip this also when there is not much room.
	 * NOTE: Be very careful not to sync undo!
	 */
	if (pum_array[pum_selected].pum_info != NULL
		&& Rows > 10
		&& repeat <= 1
		&& vim_strchr(p_cot, 'p') != NULL)
	{
	    win_T	*curwin_save = curwin;
	    int		res = OK;

	    /* Open a preview window.  3 lines by default.  Prefer
	     * 'previewheight' if set and smaller. */
	    g_do_tagpreview = 3;
	    if (p_pvh > 0 && p_pvh < g_do_tagpreview)
		g_do_tagpreview = p_pvh;
	    ++RedrawingDisabled;
	    /* Prevent undo sync here, if an autocommand syncs undo weird
	     * things can happen to the undo tree. */
	    ++no_u_sync;
	    resized = prepare_tagpreview(FALSE);
	    --no_u_sync;
	    --RedrawingDisabled;
	    g_do_tagpreview = 0;

	    if (curwin->w_p_pvw)
	    {
		if (!resized
			&& curbuf->b_nwindows == 1
			&& curbuf->b_fname == NULL
			&& curbuf->b_p_bt[0] == 'n' && curbuf->b_p_bt[2] == 'f'
			&& curbuf->b_p_bh[0] == 'w')
		{
		    /* Already a "wipeout" buffer, make it empty. */
		    while (!BUFEMPTY())
			ml_delete((linenr_T)1, FALSE);
		}
		else
		{
		    /* Don't want to sync undo in the current buffer. */
		    ++no_u_sync;
		    res = do_ecmd(0, NULL, NULL, NULL, ECMD_ONE, 0, NULL);
		    --no_u_sync;
		    if (res == OK)
		    {
			/* Edit a new, empty buffer. Set options for a "wipeout"
			 * buffer. */
			set_option_value((char_u *)"swf", 0L, NULL, OPT_LOCAL);
			set_option_value((char_u *)"bt", 0L,
					       (char_u *)"nofile", OPT_LOCAL);
			set_option_value((char_u *)"bh", 0L,
						 (char_u *)"wipe", OPT_LOCAL);
			set_option_value((char_u *)"diff", 0L,
							     NULL, OPT_LOCAL);
		    }
		}
		if (res == OK)
		{
		    char_u	*p, *e;
		    linenr_T	lnum = 0;

		    for (p = pum_array[pum_selected].pum_info; *p != NUL; )
		    {
			e = vim_strchr(p, '\n');
			if (e == NULL)
			{
			    ml_append(lnum++, p, 0, FALSE);
			    break;
			}
			else
			{
			    *e = NUL;
			    ml_append(lnum++, p, (int)(e - p + 1), FALSE);
			    *e = '\n';
			    p = e + 1;
			}
		    }

		    /* Increase the height of the preview window to show the
		     * text, but no more than 'previewheight' lines. */
		    if (repeat == 0)
		    {
			if (lnum > p_pvh)
			    lnum = p_pvh;
			if (curwin->w_height < lnum)
			{
			    win_setheight((int)lnum);
			    resized = TRUE;
			}
		    }

		    curbuf->b_changed = 0;
		    curbuf->b_p_ma = FALSE;
		    curwin->w_cursor.lnum = 1;
		    curwin->w_cursor.col = 0;

		    if (curwin != curwin_save && win_valid(curwin_save))
		    {
			/* When the first completion is done and the preview
			 * window is not resized, skip the preview window's
			 * status line redrawing. */
			if (ins_compl_active() && !resized)
			    curwin->w_redr_status = FALSE;

			/* Return cursor to where we were */
			validate_cursor();
			redraw_later(SOME_VALID);

			/* When the preview window was resized we need to
			 * update the view on the buffer.  Only go back to
			 * the window when needed, otherwise it will always be
			 * redraw. */
			if (resized)
			{
			    ++no_u_sync;
			    win_enter(curwin_save, TRUE);
			    --no_u_sync;
			    update_topline();
			}

			/* Update the screen before drawing the popup menu.
			 * Enable updating the status lines. */
			pum_do_redraw = TRUE;
			update_screen(0);
			pum_do_redraw = FALSE;

			if (!resized && win_valid(curwin_save))
			{
			    ++no_u_sync;
			    win_enter(curwin_save, TRUE);
			    --no_u_sync;
			}

			/* May need to update the screen again when there are
			 * autocommands involved. */
			pum_do_redraw = TRUE;
			update_screen(0);
			pum_do_redraw = FALSE;
		    }
		}
	    }
	}
#endif
    }

    if (!resized)
	pum_redraw();

    return resized;
}

/*
 * Undisplay the popup menu (later).
 */
    void
pum_undisplay(void)
{
    pum_array = NULL;
    redraw_all_later(SOME_VALID);
#ifdef FEAT_WINDOWS
    redraw_tabline = TRUE;
#endif
    status_redraw_all();
}

/*
 * Clear the popup menu.  Currently only resets the offset to the first
 * displayed item.
 */
    void
pum_clear(void)
{
    pum_first = 0;
}

/*
 * Return TRUE if the popup menu is displayed.
 * Overruled when "pum_do_redraw" is set, used to redraw the status lines.
 */
    int
pum_visible(void)
{
    return !pum_do_redraw && pum_array != NULL;
}

/*
 * Return the height of the popup menu, the number of entries visible.
 * Only valid when pum_visible() returns TRUE!
 */
    int
pum_get_height(void)
{
    return pum_height;
}

#endif
