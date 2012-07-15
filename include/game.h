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
#ifndef GAME_H
#define GAME_H

#include <stdio.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>
#include <allegro5/allegro_acodec.h>
#include <allegro5/allegro_primitives.h>
#include "../deps/types/hash_map.h"
#include "io.h"
#include "lua.h"
#include "api.h"
#include "debug.h"

void gameExit(const char *msg);
void gameLoad();
void gameLoop();
void gameAPI();
void gameCleanup();


// Externals ------------------------------------------------------------------
// ----------------------------------------------------------------------------

extern const char* defaultTitle;
extern const int defaultWidth;
extern const int defaultHeight;
extern const int defaultScale;
extern const int defaultFrameRate;

// State and Time
extern bool stateIsRunning;
extern bool stateIsPaused;
extern bool stateHasKeyboard;
extern bool stateHasMouse;

extern bool stateReload;

extern double gameTime;
extern double gameTimeDelta;
extern ALLEGRO_EVENT_QUEUE *stateEventQueue;
extern ALLEGRO_TIMER *stateTimer;

// Input
extern int mouseX;
extern int mouseY;
extern int mouseCount;
extern int mouseStates[];
extern int mouseStatesOld[];

extern int keyCount;
extern int keyStates[];
extern int keyStatesOld[];

// Graphics
extern const char* graphicsTitle;
extern int graphicsWidth;
extern int graphicsHeight;
extern int graphicsScale;
extern int graphicsFrameRate;
extern int graphicsLineWidth;
extern ALLEGRO_COLOR graphicsColor;
extern ALLEGRO_COLOR graphicsBackgroundColor;
extern ALLEGRO_DISPLAY *graphicsDisplay;
extern ALLEGRO_BITMAP *graphicsBackground;

extern int graphicsRenderOffsetX;
extern int graphicsRenderOffsetY;

// Images
extern HashMap *graphicsImages;
extern HashMap *graphicsImageTiles;

// Sounds
extern HashMap *soundSamples;

#endif

