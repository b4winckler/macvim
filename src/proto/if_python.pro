/* if_python.c */
int python_enabled __ARGS((int verbose));
void python_end __ARGS((void));
int python_loaded __ARGS((void));
void ex_python __ARGS((exarg_T *eap));
void ex_pyfile __ARGS((exarg_T *eap));
void ex_pydo __ARGS((exarg_T *eap));
void python_buffer_free __ARGS((buf_T *buf));
void python_window_free __ARGS((win_T *win));
void python_tabpage_free __ARGS((tabpage_T *tab));
void do_pyeval __ARGS((char_u *str, typval_T *rettv));
int set_ref_in_python __ARGS((int copyID));
/* vim: set ft=c : */
