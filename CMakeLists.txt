cmake_minimum_required (VERSION 2.6)

project(kuusi C)
set(kuusi_VERSION_MAJOR 0)
set(kuusi_VERSION_MINOR 2)
 
include_directories(./include ./deps/types ./deps/lua)
add_library(api STATIC sources/api.c)


# Unzip / IO
add_library(io STATIC sources/io.c)
add_library(unzip STATIC deps/minizip/unzip.c deps/minizip/ioapi.c)
target_link_libraries(io unzip)


# Lua
add_library(liblua STATIC deps/lua/lapi.c deps/lua/lauxlib.c deps/lua/lbaselib.c deps/lua/lbitlib.c deps/lua/lcode.c deps/lua/lcorolib.c deps/lua/lctype.c deps/lua/ldblib.c deps/lua/ldebug.c deps/lua/ldo.c deps/lua/ldump.c deps/lua/lfunc.c deps/lua/lgc.c deps/lua/linit.c deps/lua/liolib.c deps/lua/llex.c deps/lua/lmathlib.c deps/lua/lmem.c deps/lua/loadlib.c deps/lua/lobject.c deps/lua/lopcodes.c deps/lua/loslib.c deps/lua/lparser.c deps/lua/lstate.c deps/lua/lstring.c deps/lua/lstrlib.c deps/lua/ltable.c deps/lua/ltablib.c deps/lua/ltm.c deps/lua/lundump.c deps/lua/lvm.c deps/lua/lzio.c)
add_library(lua STATIC sources/lua.c)
target_link_libraries(lua liblua)


# Game
add_library(game STATIC sources/game.c)
add_library(types STATIC deps/types/array_list.c deps/types/hash_map.c deps/types/linked_iter.c deps/types/linked_list.c)
target_link_libraries(game types lua api io allegro allegro_memfile allegro_primitives allegro_image allegro_audio allegro_acodec)


# Executable
add_executable(../main main.c)
target_link_libraries(../main unzip game lua)

