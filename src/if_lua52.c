#define FEAT_LUA52_COMPILING

#define DYNAMIC_LUA_DLL DYNAMIC_LUA52_DLL
#define DYNAMIC_LUA_VER DYNAMIC_LUA52_VER

#define lua_enabled lua52_enabled
#define lua_end lua52_end
#define ex_lua ex_lua52
#define ex_luado ex_lua52do
#define ex_luafile ex_lua52file
#define lua_buffer_free lua52_buffer_free
#define lua_window_free lua52_window_free
#define do_luaeval do_lua52eval
#define set_ref_in_lua set_ref_in_lua52

#include "if_lua.c"
