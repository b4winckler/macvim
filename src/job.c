/* vim:set ts=8 sts=4 sw=4 tw=0 noet:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */
/*
 * job.c - Asynchronous job support.
 *
 * Original Author: MURAOKA Taro
 *
 * Released under Vim License.
 */

#include "vim.h"

#define JOB_WAIT_MIN		100

static void setup_timer_arch(int msec);
static void remove_timer_arch(void);

#ifdef FEAT_GUI_W32

/*
 * Timer related functions for Windows.
 */

static UINT_PTR timer_id_w32 = 0;

    static void CALLBACK
timer_proc_w32(HWND hWnd, UINT uMsg UNUSED, UINT_PTR idEvent UNUSED,
	DWORD dwTime UNUSED)
{
    job_check_ends();
}

    void
setup_timer_arch(int msec)
{
    remove_timer_arch();
    if (msec >= 0)
    {
	if (msec < JOB_WAIT_MIN)
	    msec = JOB_WAIT_MIN;
	timer_id_w32 = SetTimer(NULL, 0, msec, timer_proc_w32);
    }
}

    void
remove_timer_arch(void)
{
    if (timer_id_w32 != 0)
    {
	KillTimer(NULL, timer_id_w32);
	timer_id_w32 = 0;
    }
}

#else

    void
setup_timer_arch(int msec)
{
    /* nothing to do. */
}

    void
remove_timer_arch(void)
{
    /* nothing to do. */
}

#endif

    static void
setup_timer(int msec)
{
    if (msec >= 0)
    {
	setup_timer_arch(msec);
    }
    job_next_wait = msec;
}

    static void
remove_timer(void)
{
    remove_timer_arch();
    job_next_wait = -1;
}

    job_T *
job_add(void *data, JOB_CHECK_END check_end, JOB_CLOSE close, int wait)
{
    job_T	*job;

    if (check_end == NULL)
	return NULL;

    job = (job_T*)alloc(sizeof(job_T));
    if (job != NULL)
    {
	job->data	= data;
	job->check_end	= check_end;
	job->close	= close;
	job->wait	= wait > JOB_WAIT_MIN ? wait : JOB_WAIT_MIN;
	job->next	= job_top_p;

	job_top_p = job;
	if (job_next_wait < 0 || job->wait < job_next_wait)
	{
	    setup_timer(job->wait);
	}
    }
    return job;
}

/**
 * Detect jobs which ended, and dispose job_T.
 */
    void
job_check_ends(void)
{
    job_T	**pp;
    job_T	*job;
    int		next_wait = -1;

    remove_timer();

    for (pp = &job_top_p; (job = *pp) != NULL; )
    {
	int remain = (*job->check_end)(job->data);
	if (remain > 0)
	{
	    /* A job is alive, update wait timer. */
	    job->wait = remain > JOB_WAIT_MIN ? remain : JOB_WAIT_MIN;
	    if (next_wait < 0 || job->wait < next_wait)
		next_wait = job->wait;
	    pp = &job->next;
	}
	else
	{
	    /* A job is ended, notify the end. */
	    if (job->close)
		(*job->close)(job->data);
	    /* dispose the job object. */
	    *pp = job->next;
	    vim_free(job);
	}
    }

    if (next_wait >= 0)
	setup_timer(next_wait);
}

    int
job_get_wait(void)
{
    int wait = job_top_p == NULL ? -1 : job_next_wait;
    return wait;
}
