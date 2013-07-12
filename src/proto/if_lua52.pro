/* if_lua52.c */
int lua52_enabled __ARGS((int verbose));
void lua52_end __ARGS((void));
void ex_lua52 __ARGS((exarg_T *eap));
void ex_lua52do __ARGS((exarg_T *eap));
void ex_lua52file __ARGS((exarg_T *eap));
void lua52_buffer_free __ARGS((buf_T *buf));
void lua52_window_free __ARGS((win_T *win));
void do_lua52eval __ARGS((char_u *str, typval_T *arg, typval_T *rettv));
void set_ref_in_lua52 __ARGS((int copyID));
/* vim: set ft=c : */
