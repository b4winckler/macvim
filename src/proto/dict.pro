/* dict.c */
dict_T *dict_alloc(void);
int rettv_dict_alloc(typval_T *rettv);
void dict_unref(dict_T *d);
int dict_free_nonref(int copyID);
void dict_free_items(int copyID);
dictitem_T *dictitem_alloc(char_u *key);
void dictitem_remove(dict_T *dict, dictitem_T *item);
void dictitem_free(dictitem_T *item);
dict_T *dict_copy(dict_T *orig, int deep, int copyID);
int dict_add(dict_T *d, dictitem_T *item);
int dict_add_nr_str(dict_T *d, char *key, varnumber_T nr, char_u *str);
int dict_add_list(dict_T *d, char *key, list_T *list);
int dict_add_dict(dict_T *d, char *key, dict_T *dict);
long dict_len(dict_T *d);
dictitem_T *dict_find(dict_T *d, char_u *key, int len);
char_u *get_dict_string(dict_T *d, char_u *key, int save);
varnumber_T get_dict_number(dict_T *d, char_u *key);
char_u *dict2string(typval_T *tv, int copyID, int restore_copyID);
int get_dict_tv(char_u **arg, typval_T *rettv, int evaluate);
void dict_extend(dict_T *d1, dict_T *d2, char_u *action);
dictitem_T *dict_lookup(hashitem_T *hi);
int dict_equal(dict_T *d1, dict_T *d2, int ic, int recursive);
void dict_list(typval_T *argvars, typval_T *rettv, int what);
/* vim: set ft=c : */
