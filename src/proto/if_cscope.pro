/* if_cscope.c */
char_u *get_cscope_name(expand_T *xp, int idx);
void set_context_in_cscope_cmd(expand_T *xp, char_u *arg, cmdidx_T cmdidx);
void ex_cscope(exarg_T *eap);
void ex_scscope(exarg_T *eap);
void ex_cstag(exarg_T *eap);
int cs_fgets(char_u *buf, int size);
void cs_free_tags(void);
void cs_print_tags(void);
int cs_connection(int num, char_u *dbpath, char_u *ppath);
void cs_end(void);
/* vim: set ft=c : */
