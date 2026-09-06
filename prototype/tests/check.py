"""Syntax and mocked UI-state checks using a locally available Lua 5.4 library.
This checks the shared Lua/Luau subset; it is not the Roblox engine or Luau analyzer.
"""
import ctypes
from pathlib import Path

root=Path(__file__).resolve().parents[1]
lua=ctypes.CDLL('liblua5.4.so.0')
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_settop.argtypes=[ctypes.c_void_p,ctypes.c_int]
lua.lua_close.argtypes=[ctypes.c_void_p]
L=lua.luaL_newstate(); lua.luaL_openlibs(L)
def load(source,name,execute=False):
    data=source.encode()
    result=lua.luaL_loadbufferx(L,data,len(data),name.encode(),None)
    if not result and execute: result=lua.lua_pcallk(L,0,0,0,0,None)
    if result: raise RuntimeError(lua.lua_tolstring(L,-1,None).decode())
    lua.lua_settop(L,0)
for path in root.rglob('*.lua'):
    load(path.read_text(),str(path))
print('All Lua files compile in the Lua 5.4-compatible subset.',flush=True)
source=(root/'tests/mock.lua').read_text().replace('__BUNDLE_PATH__',str(root/'dist/SerenityConcept.lua'))
load(source,'@mock-tests',True)
lua.lua_close(L)
