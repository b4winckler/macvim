/* if_ruby19.c */
int ruby19_enabled __ARGS((int verbose));
void ruby19_end __ARGS((void));
void ex_ruby19 __ARGS((exarg_T *eap));
void ex_ruby19do __ARGS((exarg_T *eap));
void ex_ruby19file __ARGS((exarg_T *eap));
void ruby19_buffer_free __ARGS((buf_T *buf));
void ruby19_window_free __ARGS((win_T *win));
void vim_ruby19_init __ARGS((void *stack_start));
/* vim: set ft=c : */
