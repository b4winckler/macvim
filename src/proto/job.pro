/* job.c */
job_T * job_add __ARGS((void *data, JOB_CHECK_END check_end, JOB_CLOSE close, int wait));
void job_check_ends __ARGS((void));
int job_get_wait __ARGS((void));
/* vim: set ft=c noet: */
