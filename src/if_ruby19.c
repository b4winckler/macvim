#define FEAT_RUBY19_COMPILING

#define DYNAMIC_RUBY_DLL DYNAMIC_RUBY19_DLL
#define DYNAMIC_RUBY_VER DYNAMIC_RUBY19_VER
#define RUBY_VERSION RUBY19_VERSION

#define dll_rb_cFalseClass dll_rb19_cFalseClass
#define dll_rb_cFixnum dll_rb19_cFixnum
#define dll_rb_cNilClass dll_rb19_cNilClass
#define dll_rb_cSymbol dll_rb19_cSymbol
#define dll_rb_cTrueClass dll_rb19_cTrueClass
#define rb_num2long_stub rb19_num2long_stub
#define rb_int2big_stub rb19_int2big_stub
#define rb_fix2int_stub rb19_fix2int_stub
#define rb_num2int_stub rb19_num2int_stub
#define rb_float_new_in_heap rb19_float_new_in_heap
#define rb_num2ulong rb19_num2ulong
#define ex_ruby ex_ruby19
#define ex_rubydo ex_ruby19do
#define ex_rubyfile ex_ruby19file
#define ruby_buffer_free ruby19_buffer_free
#define ruby_enabled ruby19_enabled
#define ruby_end ruby19_end
#define ruby_window_free ruby19_window_free
#define vim_ruby_init vim_ruby19_init

#include "if_ruby.c"
