#ifndef lua_compat_h
#define lua_compat_h

#include "lua.h"
#include "lauxlib.h"

#if LUA_VERSION_NUM < 502

#define lua_absindex(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)

#define lua_pushglobaltable(L) lua_pushvalue(L, LUA_GLOBALSINDEX)

#define luaL_requiref(L, modname, openf, glb)     (lua_pushcfunction(L, openf), lua_pushstring(L, modname), lua_call(L, 1, 1),      glb ? (lua_pushvalue(L, -1), lua_setglobal(L, modname)) : (void)0)

#define lua_rawlen(L, i) lua_objlen(L, i)

static inline void lua_geti(lua_State *L, int idx, lua_Integer n) {
    idx = lua_absindex(L, idx);
    lua_pushinteger(L, n);
    lua_gettable(L, idx);
}

static inline void lua_seti(lua_State *L, int idx, lua_Integer n) {
    idx = lua_absindex(L, idx);
    lua_pushinteger(L, n);
    lua_insert(L, -2);
    lua_settable(L, idx);
}

#define luaL_newlibtable(L,l)	  lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)

#define luaL_newlib(L,l)    (luaL_newlibtable(L,l), luaL_register(L,NULL,l))

#endif

#if LUA_VERSION_NUM < 503

static inline int lua_isinteger(lua_State *L, int idx) {
    if (!lua_isnumber(L, idx)) return 0;
    lua_Number n = lua_tonumber(L, idx);
    return (n == (lua_Integer)n);
}

#define lua_tointegerx(L, i, p) (*(p) = 1, lua_tointeger(L, i))
#define lua_tonumberx(L, i, p) (*(p) = 1, lua_tonumber(L, i))

#endif

#endif
