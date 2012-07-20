/**
 * Copyright (c) 2012 Ivo Wetzel.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
#include "../include/lua.h"

// Game externals
extern const char* defaultTitle;
extern const int defaultWidth;
extern const int defaultHeight;
extern const int defaultScale;
extern const int defaultFrameRate;

extern double gameTime;
extern double gameTimeDelta;

extern const char* graphicsTitle;
extern int graphicsWidth;
extern int graphicsHeight;
extern int graphicsScale;
extern int graphicsFrameRate;


// Lua 
void luaCheckGameFunction(const char *name);
const char *luaGetGameConfigString(const char *name);
int luaGetGameConfigInteger(const char *name);

int luaEmptyFunction(lua_State *L) {
    return 0;
}

bool luax_optboolean(lua_State * L, int idx, bool b) {
    if (lua_isboolean(L, idx) == 1) {
        return (lua_toboolean(L, idx) == 1 ? true : false);
    }
    return b;
}


// Works somehow like require, but is able to load files from a zip bundle if possible
// leaves the function on the stack
void luaRequire(const char *filename) {

    char *buf;
    unsigned int len;

    debugLog("lua: require \"%s\"\n", filename);

    buf = ioLoadResource(filename, &len);
    if (buf != NULL) {
        luaL_loadbuffer(L, buf, len, filename);
        lua_pcall(L, 0, 1, 0); // this will leave return value of the module on the stack
        free(buf);
    }

}

int luax_require(lua_State *L) {
    const char *filename = luaL_checkstring(L, 1);
    char *str = (char*)calloc(strlen(filename) + 5, sizeof(char));
    strcat(str, filename);
    strcat(str, ".lua");
    luaRequire(str);
    return 1;
}

void luaError() {
    
    const char *err = lua_tostring(L, -1);
    lua_getglobal(L, "debug");
    lua_getfield(L, -1, "traceback");
    lua_remove(L, -2);
    lua_call(L, 0, 1);

    debugLog("%s\n - %s\n", lua_tostring(L, -1), err);

}

int luaReload(lua_State *L) {
    stateReload = true;
    return 0;
}

void luaAPI() {
    
    debugLog("lua: api...\n");

    // Game
    lua_newtable(L);
    lua_setglobal(L, "game");
    lua_getglobal(L, "game");

    lua_pushcfunction(L, luaEmptyFunction);
    lua_setfield(L, -2, "init");

    lua_pushcfunction(L, luaEmptyFunction);
    lua_setfield(L, -2, "load");

    lua_pushcfunction(L, luaEmptyFunction);
    lua_setfield(L, -2, "update");

    lua_pushcfunction(L, luaEmptyFunction);
    lua_setfield(L, -2, "render");

    lua_pushcfunction(L, luaEmptyFunction);
    lua_setfield(L, -2, "exit");

    lua_pushcfunction(L, luaReload);
    lua_setfield(L, -2, "reload");

    // Configuration
    lua_newtable(L);
    lua_setfield(L, -2, "conf");
    lua_getfield(L, -1, "conf");

    lua_pushinteger(L, defaultWidth);
    lua_setfield(L, -2, "width");

    lua_pushinteger(L, defaultHeight);
    lua_setfield(L, -2, "height");

    lua_pushinteger(L, defaultScale);
    lua_setfield(L, -2, "scale");

    lua_pushinteger(L, defaultFrameRate);
    lua_setfield(L, -2, "fps");

    lua_pushstring(L, defaultTitle);
    lua_setfield(L, -2, "title");

    lua_newtable(L);
    lua_setglobal(L, "keyboard");

    lua_newtable(L);
    lua_setglobal(L, "mouse");

    lua_newtable(L);
    lua_setglobal(L, "graphics");

    lua_newtable(L);
    lua_setglobal(L, "image");

    lua_newtable(L);
    lua_setglobal(L, "sound");

    lua_newtable(L);
    lua_setglobal(L, "music");

}

void luaInit() {

    debugLog("lua: init...\n");

    // Create lua state and load game file
    L = luaL_newstate();
    luaL_openlibs(L);

    luaAPI();

    debugLog("lua: main...\n");

    // Patch require
    lua_getglobal(L, "_G");
    lua_pushcfunction(L, luax_require);
    lua_setfield(L, -2, "require");
    lua_pop(L, 1);

    // Require and pop the returned table
    luaRequire("main.lua");
    lua_pop(L, 1);

    debugLog("lua: conf...\n");

    // Do some basic checks to see whether the main functions exist
    luaCheckGameFunction("init");
    luaCheckGameFunction("load");
    luaCheckGameFunction("update");
    luaCheckGameFunction("render");

    // call "game.init" and pass it the configuration table
    lua_getglobal(L, "game");
    lua_getfield(L, -1, "conf");
    lua_getglobal(L, "game");
    lua_getfield(L, -1, "init");
    lua_pushvalue(L, -3);

    if (lua_pcall(L, 1, 0, 0)) {
        luaError();
    }
    lua_pop(L, 1);
    lua_pop(L, 1);

    // Parse the configuration
    graphicsTitle = luaGetGameConfigString("title");
    graphicsWidth = luaGetGameConfigInteger("width");
    graphicsHeight = luaGetGameConfigInteger("height");
    graphicsScale = luaGetGameConfigInteger("scale");
    graphicsFrameRate = luaGetGameConfigInteger("fps");

    if (graphicsWidth * graphicsScale <= 0 || graphicsWidth >= 1024 * graphicsScale) {
        gameExit("Invalid width.");
    }

    if (graphicsHeight * graphicsScale <= 0 || graphicsHeight >= 768 * graphicsScale) {
        gameExit("Invalid graphicsHeight.");
    }

    if (graphicsFrameRate <= 0 || graphicsFrameRate > 60) {
        gameExit("Invalid frame rate.");
    }

}

void luaLoad() {
    lua_getglobal(L, "game");
    lua_getfield(L, -1, "load");
    if (lua_pcall(L, 0, 0, 0)) {
        luaError();
    }
    lua_pop(L, 1);
}

void luaUpdate() {

    lua_getglobal(L, "game");
    lua_getfield(L, -1, "update");
    lua_pushnumber(L, gameTimeDelta);
    lua_pushnumber(L, gameTime);
    if (lua_pcall(L, 2, 0, 0)) {
        luaError();
    }
    lua_pop(L, 1);

}

void luaRender() {

    lua_getglobal(L, "game");
    lua_getfield(L, -1, "render");
    if (lua_pcall(L, 0, 0, 0)) {
        luaError();
    }

    lua_pop(L, 1);

}

void luaCleanup() {
    
    debugLog("lua: cleanup...\n");

    lua_getglobal(L, "game");
    lua_getfield(L, -1, "exit");
    lua_call(L, 0, 0);
    lua_pop(L, 1);

    lua_close(L);

}


// Lua Helper -----------------------------------------------------------------
void luaCheckGameFunction(const char *name) {

    lua_getglobal(L, "game");
    lua_getfield(L, -1, name);

    if (!lua_isfunction(L, -1)) {
        debugLog("FATAL: Missing function '%s' in lua code.\n", name);
        exit(1);
    }

    lua_pop(L, 1);

}

const char *luaGetGameConfigString(const char *name) {

    unsigned int length = 0;
    const char *string;

    lua_getglobal(L, "game");
    lua_getfield(L, -1, "conf");
    lua_getfield(L, -1, name);
    string = lua_tolstring(L, -1, &length);
    lua_pop(L, 1);
    lua_pop(L, 1);

    return string;

}

int luaGetGameConfigInteger(const char *name) {

    int number;
    lua_getglobal(L, "game");
    lua_getfield(L, -1, "conf");
    lua_getfield(L, -1, name);

    number = lua_tointeger(L, -1);
    lua_pop(L, 1);
    lua_pop(L, 1);

    return number;

}

