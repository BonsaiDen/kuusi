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
#include "../include/api.h"
#include <math.h>


// ----------------------------------------------------------------------------
// Game -----------------------------------------------------------------------
// ----------------------------------------------------------------------------
static int gameQuit(lua_State *L) {
    stateIsRunning = false;
    return 0;
}

static int gameGetTime(lua_State *L)  {
    lua_pushnumber(L, gameTime);
    return 1;
}

static int gameGetDelta(lua_State *L)  {
    lua_pushnumber(L, gameTimeDelta);
    return 1;
}

static int gamePause(lua_State *L)  {
    stateIsPaused = true;
    return 0;
}

static int gameResume(lua_State *L)  {
    stateIsPaused = false;
    return 0;
}

static int gameIsPaused(lua_State *L)  {
    lua_pushboolean(L, stateIsPaused);
    return 1;
}


// ----------------------------------------------------------------------------
// Keyboard -------------------------------------------------------------------
// ----------------------------------------------------------------------------
static const char *keyNames[ALLEGRO_KEY_MAX] = { 
   "(none)",     "A",          "B",          "C",
   "D",          "E",          "F",          "G",
   "H",          "I",          "J",          "K",
   "L",          "M",          "N",          "O",
   "P",          "Q",          "R",          "S",
   "T",          "U",          "V",          "W",
   "X",          "Y",          "Z",          "0",
   "1",          "2",          "3",          "4",
   "5",          "6",          "7",          "8",
   "9",          "PAD 0",      "PAD 1",      "PAD 2",
   "PAD 3",      "PAD 4",      "PAD 5",      "PAD 6",
   "PAD 7",      "PAD 8",      "PAD 9",      "F1",
   "F2",         "F3",         "F4",         "F5",
   "F6",         "F7",         "F8",         "F9",
   "F10",        "F11",        "F12",        "ESCAPE",
   "KEY60",      "KEY61",      "KEY62",      "BACKSPACE",
   "TAB",        "KEY65",      "KEY66",      "ENTER",
   "KEY68",      "KEY69",      "BACKSLASH",  "KEY71",
   "KEY72",      "KEY73",      "KEY74",      "SPACE",
   "INSERT",     "DELETE",     "HOME",       "END",
   "PGUP",       "PGDN",       "LEFT",       "RIGHT",
   "UP",         "DOWN",       "PAD /",      "PAD *",
   "PAD -",      "PAD +",      "PAD DELETE", "PAD ENTER",
   "PRINTSCREEN","PAUSE",      "KEY94",      "KEY95",
   "KEY96",      "KEY97",      "KEY98",      "KEY99",
   "KEY100",     "KEY101",     "KEY102",     "PAD =",
   "KEY104",     "KEY105",     "KEY106",     "KEY107",
   "KEY108",     "KEY109",     "KEY110",     "KEY111",
   "KEY112",     "KEY113",     "KEY114",     "KEY115",
   "KEY116",     "KEY117",     "KEY118",     "KEY119",
   "KEY120",     "KEY121",     "KEY122",     "KEY123",
   "KEY124",     "KEY125",     "KEY126",     "KEY127",
   "KEY128",     "KEY129",     "KEY130",     "KEY131",
   "KEY132",     "KEY133",     "KEY134",     "KEY135",
   "KEY136",     "KEY137",     "KEY138",     "KEY139",
   "KEY140",     "KEY141",     "KEY142",     "KEY143",
   "KEY144",     "KEY145",     "KEY146",     "KEY147",
   "KEY148",     "KEY149",     "KEY150",     "KEY151",
   "KEY152",     "KEY153",     "KEY154",     "KEY155",
   "KEY156",     "KEY157",     "KEY158",     "KEY159",
   "KEY160",     "KEY161",     "KEY162",     "KEY163",
   "KEY164",     "KEY165",     "KEY166",     "KEY167",
   "KEY168",     "KEY169",     "KEY170",     "KEY171",
   "KEY172",     "KEY173",     "KEY174",     "KEY175",
   "KEY176",     "KEY177",     "KEY178",     "KEY179",
   "KEY180",     "KEY181",     "KEY182",     "KEY183",
   "KEY184",     "KEY185",     "KEY186",     "KEY187",
   "KEY188",     "KEY189",     "KEY190",     "KEY191",
   "KEY192",     "KEY193",     "KEY194",     "KEY195",
   "KEY196",     "KEY197",     "KEY198",     "KEY199",
   "KEY200",     "KEY201",     "KEY202",     "KEY203",
   "KEY204",     "KEY205",     "KEY206",     "KEY207",
   "KEY208",     "KEY209",     "KEY210",     "KEY211",
   "KEY212",     "KEY213",     "KEY214",     "LSHIFT",
   "RSHIFT",     "LCTRL",      "RCTRL",      "ALT",
   "ALTGR",      "LWIN",       "RWIN",       "MENU",
   "SCROLLLOCK", "NUMLOCK",    "CAPSLOCK"
};

static int getKeyCodeFromName(const char *s) {
   int i;

   /* Some key names are not intuitive, but this is all we've got. */
   for (i = 1; i < ALLEGRO_KEY_MAX; i++) {
      if (0 == strcasecmp(s, keyNames[i])) {
         return i;
      }
   }

   return 0;

}

static int keyboardIsDown(lua_State *L) {
    const char *key = luaL_checkstring(L, 1);
    int id = getKeyCodeFromName(key);
    lua_pushboolean(L, id != 0 ? keyStates[id] > 0 : false);
    return 1;
}

static int keyboardWasPressed(lua_State *L) {
    const char *key = luaL_checkstring(L, 1);
    int id = getKeyCodeFromName(key);
    lua_pushboolean(L, id != 0 ? keyStates[id] == 1 : false);
    return 1;
}

static int keyboardWasReleased(lua_State *L) {
    const char *key = luaL_checkstring(L, 1);
    int id = getKeyCodeFromName(key);
    lua_pushboolean(L, id != 0 ? keyStates[id] == 0 && keyStatesOld[id] > 0 : false);
    return 1;
}

static int keyboardHasFocus(lua_State *L) {
    lua_pushboolean(L, stateHasKeyboard);
    return 1;
}

static int keyboardGetCount(lua_State *L) {
    lua_pushinteger(L, keyCount);
    return 1;
}


// ----------------------------------------------------------------------------
// Mouse ----------------------------------------------------------------------
// ----------------------------------------------------------------------------
static int mouseIsDown(lua_State *L) {
    const char *button = luaL_checkstring(L, 1);

    int id = 0;
    if (strcasecmp(button, "l") == 0) {
        id = 1;
        
    } else if (strcasecmp(button, "r") == 0) {
        id = 2;
    }

    lua_pushboolean(L, id != -1 ? mouseStates[id] > 0 : false);
    return 1;
}

static int mouseWasPressed(lua_State *L) {
    const char *button = luaL_checkstring(L, 1);

    int id = 0;
    if (strcasecmp(button, "l") == 0) {
        id = 1;
        
    } else if (strcasecmp(button, "r") == 0) {
        id = 2;
    }

    lua_pushboolean(L, id != -1 ? mouseStates[id] == 1 : false);
    return 1;
}

static int mouseWasReleased(lua_State *L) {
    const char *button = luaL_checkstring(L, 1);

    int id = 0;
    if (strcasecmp(button, "l") == 0) {
        id = 1;
        
    } else if (strcasecmp(button, "r") == 0) {
        id = 2;
    }

    lua_pushboolean(L, id != -1 ? mouseStates[id] == 0 && mouseStatesOld[id] > 0 : false);
    return 1;
}

static int mouseHasFocus(lua_State *L) {
    lua_pushboolean(L, stateHasMouse);
    return 1;
}

static int mouseGetCount(lua_State *L) {
    lua_pushinteger(L, mouseCount);
    return 1;
}

static int mouseGetPosition(lua_State *L) {
    lua_pushinteger(L, mouseX - graphicsRenderOffsetX);
    lua_pushinteger(L, mouseY - graphicsRenderOffsetY);
    return 2;
}


// ----------------------------------------------------------------------------
// Graphics -------------------------------------------------------------------
// ----------------------------------------------------------------------------
static int graphicsSetRenderOffset(lua_State *L) {
    graphicsRenderOffsetX = luaL_checkinteger(L, 1);
    graphicsRenderOffsetY = luaL_checkinteger(L, 2);
    return 0;
}

static int graphicsGetRenderOffset(lua_State *L) {
    lua_pushinteger(L, graphicsRenderOffsetX);
    lua_pushinteger(L, graphicsRenderOffsetY);
    return 2;
}

static int graphicsSetColor(lua_State *L) {

    int r = luaL_checkinteger(L, 1);
    int g = luaL_checkinteger(L, 2);
    int b = luaL_checkinteger(L, 3);
    double a = luaL_optnumber(L, 4, -1);

    if (a == -1) {
        graphicsColor = al_map_rgba(r, g, b, 255); 

    } else {
        graphicsColor = al_map_rgba(r, g, b, a * 255); 
    }

    return 0;
}

static int graphicsGetColor(lua_State *L) {
    unsigned char r, g, b, a;
    al_unmap_rgba(graphicsColor, &r, &g, &b, &a);
    lua_pushinteger(L, (int)r);
    lua_pushinteger(L, (int)g);
    lua_pushinteger(L, (int)r);
    lua_pushnumber(L, ((double)a) / 255);
    return 3;
}

static int graphicsSetBackgroundColor(lua_State *L) {

    int r = luaL_checkinteger(L, 1);
    int g = luaL_checkinteger(L, 2);
    int b = luaL_checkinteger(L, 3);
    double a = luaL_optnumber(L, 4, -1);

    if (a == -1) {
        graphicsBackgroundColor = al_map_rgba(r, g, b, 255);

    } else {
        graphicsBackgroundColor = al_map_rgba(r, g, b, a * 255);
    }

    return 0;
}

static int graphicsGetBackgroundColor(lua_State *L) {
    unsigned char r, g, b, a;
    al_unmap_rgba(graphicsBackgroundColor, &r, &g, &b, &a);
    lua_pushinteger(L, (int)r);
    lua_pushinteger(L, (int)g);
    lua_pushinteger(L, (int)r);
    lua_pushnumber(L, ((double)a) / 255);
    return 3;
}

static int graphicsSetLineWidth(lua_State *L) {
    int w = luaL_checkinteger(L, 1);
    graphicsLineWidth = w;
    return 0;
}

static int graphicsGetLineWidth(lua_State *L) {
    lua_pushinteger(L, luaL_checkinteger(L, 1));
    return 1;
}

static int graphicsDrawLine(lua_State *L) {

    double x1 = luaL_checkinteger(L, 1) + graphicsRenderOffsetX;
    double y1 = luaL_checkinteger(L, 2) + graphicsRenderOffsetY;
    double x2 = luaL_checkinteger(L, 3) + graphicsRenderOffsetX;
    double y2 = luaL_checkinteger(L, 4) + graphicsRenderOffsetY;

    if (graphicsLineWidth % 2 == 1) {
        x1 += 0.5;
        x2 += 0.5;
    } 

    al_draw_line(x1, y1, x2, y2, graphicsColor, graphicsLineWidth);

    return 0;
}

static int graphicsDrawTriangle(lua_State *L) {

    double x1 = luaL_checkinteger(L, 1) + graphicsRenderOffsetX;
    double y1 = luaL_checkinteger(L, 2) + graphicsRenderOffsetY;
    double x2 = luaL_checkinteger(L, 3) + graphicsRenderOffsetX;
    double y2 = luaL_checkinteger(L, 4) + graphicsRenderOffsetY;
    double x3 = luaL_checkinteger(L, 5) + graphicsRenderOffsetX;
    double y3 = luaL_checkinteger(L, 6) + graphicsRenderOffsetY;

    if (luax_optboolean(L, 7, false)) {
        al_draw_filled_triangle(x1, y1, x2, y2, x3, y3, graphicsColor);

    } else {

        if (graphicsLineWidth % 2 == 1) {
            x1 += 0.5;
            y1 += 0.5;
            x2 += 0.5;
            y2 += 0.5;
            x3 += 0.5;
            y3 += 0.5;
        } 

        al_draw_triangle(x1, y1, x2, y2, x3, y3, graphicsColor, graphicsLineWidth);
        
    }

    return 0;
}

static int graphicsDrawRect(lua_State *L) {

    double x = luaL_checkinteger(L, 1) + graphicsRenderOffsetX;
    double y = luaL_checkinteger(L, 2) + graphicsRenderOffsetY;
    double w = luaL_checkinteger(L, 3);
    double h = luaL_checkinteger(L, 4);

    if (luax_optboolean(L, 5, false)) {
        al_draw_filled_rectangle(x, y, x + w, y + h, graphicsColor);
        
    } else {
        if (graphicsLineWidth % 2 == 1) {
            x += 0.5;
            y += 0.5;
        }
        al_draw_rectangle(x, y, x + w - 1, y + h - 1, graphicsColor, graphicsLineWidth);
    }

    return 0;
}

static int graphicsDrawCircle(lua_State *L) {

    int x = luaL_checkinteger(L, 1) + graphicsRenderOffsetX; 
    int y = luaL_checkinteger(L, 2) + graphicsRenderOffsetY; 
    int r = luaL_checkinteger(L, 3);

    int filled = luax_optboolean(L, 5, false);
    if (filled) {
        al_draw_filled_circle(x, y, r, graphicsColor);
        
    } else {

        if (graphicsLineWidth % 2 == 1) {
            x += 0.5;
            y += 0.5;
        } 

        al_draw_circle(x, y, r, graphicsColor, graphicsLineWidth);

    }
    return 0;
}

static int graphicsSetScale(lua_State *L) {
    graphicsScale = luaL_checkinteger(L, 1);
    return 0;
}

static int graphicsGetScale(lua_State *L) {
    lua_pushinteger(L, graphicsScale);
    return 1;
}

static int graphicsSetSize(lua_State *L) {
    graphicsWidth = luaL_checkinteger(L, 1);
    graphicsHeight = luaL_checkinteger(L, 2);
    return 0;
}

static int graphicsGetSize(lua_State *L) {
    lua_pushinteger(L, graphicsWidth);
    lua_pushinteger(L, graphicsHeight);
    return 1;
}


// ----------------------------------------------------------------------------
// Image ----------------------------------------------------------------------
// ----------------------------------------------------------------------------
struct ImageTile;
typedef struct ImageTile {
    int cols;
    int rows;

} ImageTile;

static ALLEGRO_BITMAP *getImage(const char *filename) {
    
    ALLEGRO_BITMAP *img = NULL;
    ImageTile *tile = NULL;

    // Check if we need to load the image
    if (!graphicsImages->hasKey(graphicsImages, filename)) {
        
        img = ioLoadBitmap(filename);
        if (!img) {
            gameExit("Failed to load image");
        }

        graphicsImages->set(graphicsImages, filename, img);

        tile = calloc(1, sizeof(ImageTile));
        tile->cols = 1;
        tile->rows = 1;

        graphicsImageTiles->set(graphicsImageTiles, filename, tile);

        printf("image: %s loaded\n", filename);
        
    } else {
        img = (ALLEGRO_BITMAP*)graphicsImages->get(graphicsImages, filename);
    }

    return img;

}

static int imageLoad(lua_State *L) {
    const char* filename = luaL_checkstring(L, 1);
    getImage(filename);
    return 0;
}


static int imageSetTiles(lua_State *L) {

    const char* filename = luaL_checkstring(L, 1);
    int cols = luaL_checkinteger(L, 2);
    int rows = luaL_checkinteger(L, 3);
    ImageTile *tile = NULL;

    getImage(filename);

    tile = (ImageTile*)graphicsImageTiles->get(graphicsImageTiles, filename);
    tile->cols = cols;
    tile->rows = rows;

    return 0;

}

static int imageDraw(lua_State *L) {

    const char* filename = luaL_checkstring(L, 1);
    ALLEGRO_BITMAP *img = getImage(filename);

    int x = luaL_checkinteger(L, 2) + graphicsRenderOffsetX; 
    int y = luaL_checkinteger(L, 3) + graphicsRenderOffsetY; 
    double a = luaL_optnumber(L, 6, 1);

    int flags = 0;
    if (luax_optboolean(L, 4, false)) {
        flags |= ALLEGRO_FLIP_HORIZONTAL;
    }

    if (luax_optboolean(L, 5, false)) {
        flags |= ALLEGRO_FLIP_VERTICAL;
    }

    if (a == 1) {
        al_draw_bitmap(img, x, y, flags);

    } else {
        al_draw_tinted_bitmap(img, al_map_rgba_f(1, 1, 1, a), x, y, flags);
    }

    return 0;

}

static int imageDrawTile(lua_State *L) {

    const char* filename = luaL_checkstring(L, 1);
    ALLEGRO_BITMAP *img = getImage(filename);
    ImageTile *tile = (ImageTile*)graphicsImageTiles->get(graphicsImageTiles, filename);

    int x = luaL_checkinteger(L, 2) + graphicsRenderOffsetX; 
    int y = luaL_checkinteger(L, 3) + graphicsRenderOffsetY; 
    int index = luaL_checkinteger(L, 4) - 1;
    double a = luaL_optnumber(L, 7, 1);

    int w = al_get_bitmap_width(img) / tile->cols;
    int h = al_get_bitmap_height(img) / tile->rows;
    int ty = index / tile->rows;
    int tx = index - ty * tile->cols;

    int flags = 0;
    if (luax_optboolean(L, 5, false)) {
        flags |= ALLEGRO_FLIP_HORIZONTAL;
    }

    if (luax_optboolean(L, 6, false)) {
        flags |= ALLEGRO_FLIP_VERTICAL;
    }

    if (a == 1) {
        al_draw_bitmap_region(img, tx * w, ty * h, w, h, x, y, flags);

    } else {
        al_draw_tinted_bitmap_region(img, al_map_rgba_f(1, 1, 1, a), tx * w, ty * h, w, h, x, y, flags);
    }

    return 0;

}

#define expose(field, function) { lua_pushcfunction(L, function); lua_setfield(L, -2, field); }

static int mathRound(lua_State *L) {
    lua_pushinteger(L, round(luaL_checknumber(L, 1)));
    return 1;
}


// ----------------------------------------------------------------------------
// Sound ----------------------------------------------------------------------
// ----------------------------------------------------------------------------
static ALLEGRO_SAMPLE *getSound(const char *filename) {
    
    ALLEGRO_SAMPLE *snd = NULL;

    if (!soundSamples->hasKey(soundSamples, filename)) {
        
        snd = ioLoadSample(filename);
        if (!snd) {
            gameExit("Failed to load sound");
        }
    
        soundSamples->set(soundSamples, filename, snd);
        
    } else {
        snd = (ALLEGRO_SAMPLE*)soundSamples->get(soundSamples, filename);
    }

    return snd;

}

static int soundLoad(lua_State *L) {
    const char* filename = luaL_checkstring(L, 1);
    getSound(filename);
    return 0;
}

static int soundPlay(lua_State *L) {

    ALLEGRO_SAMPLE *snd;
    float pan = luaL_optnumber(L, 2, 0);
    float speed = luaL_optnumber(L, 3, 1);
    ALLEGRO_SAMPLE_ID id;

    // If we supply a string create a new sample and return the id
    if (lua_isstring(L, 1)) {
        const char* filename = luaL_checkstring(L, 1);
        snd = getSound(filename);
        
    // Otherwise modify the existing one
    } else {
        
    }

    if (al_play_sample(snd, 1, pan, speed, ALLEGRO_PLAYMODE_ONCE, &id)) {
        lua_pushinteger(L, id._id);
        
    } else {
        lua_pushboolean(L, false);
    }
    
    // Returns the ID, or false in case the sound could not be played
    return 1;

}

static int soundPause(lua_State *L) {
    return 1;
}

static int soundResume(lua_State *L) {
    return 1;
}

static int soundStop(lua_State *L) {
    //lua_pushboolean(L, al_stop_sample(luaL_checkinteger(L, 1)));
    return 1;
}


// ----------------------------------------------------------------------------
// Mapper ---------------------------------------------------------------------
// ----------------------------------------------------------------------------
void apiInit() {

    // Fixes
    lua_getglobal(L, "math");
    expose("round", mathRound);
    lua_pop(L, 1);

    lua_getglobal(L, "game");
    expose("getTime", gameGetTime);
    expose("getTimeDelta", gameGetDelta);
    expose("quit", gameQuit);
    expose("pause", gamePause);
    expose("resume", gameResume);
    expose("isPaused", gameIsPaused);
    lua_pop(L, 1);

    // Keyboard
    lua_getglobal(L, "keyboard");
    expose("isDown", keyboardIsDown);
    expose("wasPressed", keyboardWasPressed);
    expose("wasReleased", keyboardWasReleased);
    expose("hasFocus", keyboardHasFocus);
    expose("getCount", keyboardGetCount);
    lua_pop(L, 1);

    // Mouse
    lua_getglobal(L, "mouse");
    expose("isDown", mouseIsDown);
    expose("wasPressed", mouseWasPressed);
    expose("wasReleased", mouseWasReleased);
    expose("hasFocus", mouseHasFocus);
    expose("getCount", mouseGetCount);
    expose("getPosition", mouseGetPosition);
    lua_pop(L, 1);

    // Graphics
    lua_getglobal(L, "graphics");
    expose("setSize", graphicsSetSize);
    expose("getSize", graphicsGetSize);
    expose("getScale", graphicsGetScale);
    expose("setScale", graphicsSetScale);

    expose("setRenderOffset", graphicsSetRenderOffset);
    expose("getRenderOffset", graphicsGetRenderOffset);
    expose("getColor", graphicsGetColor);
    expose("setColor", graphicsSetColor);
    expose("getColor", graphicsGetColor);
    expose("setBackgroundColor", graphicsSetBackgroundColor);
    expose("getBackgroundColor", graphicsGetBackgroundColor);
    expose("setLineWidth", graphicsSetLineWidth);
    expose("getLineWidth", graphicsGetLineWidth);
    expose("line", graphicsDrawLine);
    expose("triangle", graphicsDrawTriangle);
    expose("rect", graphicsDrawRect);
    expose("circle", graphicsDrawCircle);
    lua_pop(L, 1);

    // Image
    lua_getglobal(L, "image");
    expose("load", imageLoad);
    expose("draw", imageDraw);
    expose("setTiles", imageSetTiles);
    expose("drawTile", imageDrawTile);
    lua_pop(L, 1);


    // Sound
    lua_getglobal(L, "sound");
    expose("load", soundLoad);
    expose("play", soundPlay);

    lua_pop(L, 1);

}

