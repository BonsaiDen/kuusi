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
#include <allegro5/allegro.h>
#include "include/io.h"
#include "include/game.h"
#include "include/lua.h"
#include "include/debug.h"

int main(int argc, char *argv[]) {

    // Open the bundle this will trigger all game data to be loaded from the
    // zip file that's attached to the binary
    #ifdef BUNDLE
        ioOpenBundle(argv[0]);
    #else
        chdir("game");
    #endif

    debugLog("main: enter...\n");

    luaInit();
    gameLoad();
    gameLoop();
    gameCleanup();
    luaCleanup();

    debugLog("main: leave...\n");

    return 0;

}

