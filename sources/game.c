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
#include "../include/game.h"

// Game State and Constants ---------------------------------------------------
// ----------------------------------------------------------------------------
const char* defaultTitle = "Game";
const int defaultWidth = 640;
const int defaultHeight = 480;
const int defaultScale = 1;
const int defaultFrameRate = 60;

// State and Time
bool stateIsRunning = false;
bool stateIsPaused = false;
bool stateHasKeyboard = false;
bool stateHasMouse = false;
bool stateReload = false;

double gameTime = 0;
double gameTimeDelta = 0;
ALLEGRO_EVENT_QUEUE *stateEventQueue = NULL;
ALLEGRO_TIMER *stateTimer = NULL;

// Input
#define MAX_MOUSE 8
int mouseX = -1;
int mouseY = -1;
int mouseCount = 0;
int mouseStates[MAX_MOUSE];
int mouseStatesOld[MAX_MOUSE];

int keyCount = 0;
int keyStates[ALLEGRO_KEY_MAX];
int keyStatesOld[ALLEGRO_KEY_MAX];

// Graphics
const char* graphicsTitle = "";
int graphicsWidth = 0;
int graphicsHeight = 0;
int graphicsScale = 0;
bool graphicsResized = false;
int graphicsFrameRate = 60;
int graphicsLineWidth = 1;
ALLEGRO_COLOR graphicsColor;
ALLEGRO_COLOR graphicsBackgroundColor;
ALLEGRO_DISPLAY *graphicsDisplay = NULL;
ALLEGRO_BITMAP *graphicsBackground = NULL;

int graphicsRenderOffsetX = 0;
int graphicsRenderOffsetY = 0;

// Images
HashMap *graphicsImages;
HashMap *graphicsImageTiles;

// Sounds
HashMap *soundSamples;



// Game Functions -------------------------------------------------------------
// ----------------------------------------------------------------------------
void gameExit(const char *msg) {
    debugLog("FATAL: %s\n", msg);
    ioCloseBundle();
    exit(1);
}

void gameLoad() {
    
    unsigned int i;

    debugLog("game: load...\n");

    // Init API exposure
    apiInit();

    // Setup input state
    for(i = 0; i < ALLEGRO_KEY_MAX; i++) keyStates[i] = 0;
    for(i = 0; i < MAX_MOUSE; i++) mouseStates[i] = 0;

    // Init Allegro
	if (!al_init()) {
        gameExit("Failed to initialize allegro.");
    }

	if (!al_init_image_addon() || !al_init_primitives_addon()) {
        gameExit("Failed to initialize allegro graphics.");
    }

    // Init Screen
    graphicsDisplay = al_create_display(graphicsWidth * graphicsScale, graphicsHeight * graphicsScale);

    if (graphicsDisplay == NULL) {
        gameExit("Failed to set display resolution.");
    }

    al_set_new_display_option(ALLEGRO_VSYNC, true, ALLEGRO_SUGGEST);
    al_set_window_title(graphicsDisplay, graphicsTitle);

    // Setup Timer
	stateTimer = al_create_timer(1.0 / graphicsFrameRate);

    // Setup events
	stateEventQueue = al_create_event_queue();
	al_install_keyboard();
	al_install_mouse();

	al_register_event_source(stateEventQueue, al_get_keyboard_event_source());
	al_register_event_source(stateEventQueue, al_get_mouse_event_source());
	al_register_event_source(stateEventQueue, al_get_display_event_source(graphicsDisplay));
	al_register_event_source(stateEventQueue, al_get_timer_event_source(stateTimer));

    if (graphicsScale != 1) {
        graphicsBackground = al_create_bitmap(graphicsWidth, graphicsHeight);
        al_set_target_bitmap(graphicsBackground);

    } else {
        al_set_target_bitmap(al_get_backbuffer(graphicsDisplay));
    }

    graphicsColor = al_map_rgba(255, 255, 255, 255); 
    graphicsBackgroundColor = al_map_rgba(0, 0, 0, 255); 
    graphicsImages = hashMap(0);
    graphicsImageTiles = hashMap(0);


    // Setup the audio
    if (!al_install_audio()) {
        gameExit("Failed to initialize sound.");
    }

    /*ALLEGRO_VOICE *voice = al_create_voice(44100, ALLEGRO_AUDIO_DEPTH_INT16, ALLEGRO_CHANNEL_CONF_2);*/
    /*ALLEGRO_MIXER *mixer = al_create_mixer(44100, ALLEGRO_AUDIO_DEPTH_INT16, ALLEGRO_CHANNEL_CONF_2);*/
    /*al_attach_mixer_to_voice(mixer, voice);*/
    /*if (!al_set_default_mixer(mixer)) {*/
        /*gameExit("Failed to initialize sound.");*/
    /*}*/

    al_reserve_samples(16);
	al_init_acodec_addon();
    soundSamples = hashMap(0);

    // API and everything is ready, we can now load stuff
    luaLoad();

}


// Loop -----------------------------------------------------------------------
void gameLoop() {

    double lastFrameTime = 0, now = 0;
    bool redraw = true;
    unsigned int i = 0;
    
    debugLog("game: loop...\n");
	al_start_timer(stateTimer);

    stateIsRunning = true;
    while (stateIsRunning) {

		ALLEGRO_EVENT event;
		al_wait_for_event(stateEventQueue, &event);

        // Handle Events
        switch (event.type) {
            case ALLEGRO_EVENT_DISPLAY_CLOSE:
                stateIsRunning = false;
                break;

            case ALLEGRO_EVENT_KEY_DOWN:
                keyStates[event.keyboard.keycode] = 1;
                keyCount++;
                break;
            
            case ALLEGRO_EVENT_KEY_UP:
                keyStates[event.keyboard.keycode] = 0;

                keyCount--;
                if (keyCount < 0) {
                    keyCount = 0;
                }
                break;
            
            case ALLEGRO_EVENT_MOUSE_AXES:
                mouseX = event.mouse.x / graphicsScale;
                mouseY = event.mouse.y / graphicsScale;
                break;
            
            case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                for(i = 0; i < 4; i++) {
                    if (event.mouse.button & (1 << i)) {
                        mouseStates[i + 1] = 1;
                        mouseCount++;
                    }
                }
                break;
            
            case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                for(i = 0; i < 4; i++) {
                    if (event.mouse.button & (1 << i)) {
                        mouseStates[i + 1] = 0;
                        mouseCount--;
                    }
                }
                if (mouseCount < 0) {
                    mouseCount = 0;
                }

                break;
            
            case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
                stateHasMouse = true;
                break;

            case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
                stateHasMouse = false;
                break;

            case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
                stateHasKeyboard = true;
                break;

            case ALLEGRO_EVENT_DISPLAY_SWITCH_OUT:
                stateHasKeyboard = false;
                break;

            case ALLEGRO_EVENT_TIMER:

                // Timer
                now = al_get_time();
                gameTimeDelta = now - lastFrameTime;
                if (stateIsPaused) {
                    gameTimeDelta = 0;
                }

                gameTime += gameTimeDelta;
                lastFrameTime = now;

                // Lua call
                luaUpdate();

                // Update / Reset Input States
                for(i = 0; i < ALLEGRO_KEY_MAX; i++) {
                    if (keyStates[i] == 1) {
                        keyStates[i] = 2;
                    }
                }

                for(i = 0; i < MAX_MOUSE; i++) {
                    if (mouseStates[i] == 1) {
                        mouseStates[i] = 2;
                    }
                }

                for(i = 0; i < ALLEGRO_KEY_MAX; i++) {
                    keyStatesOld[i] = keyStates[i];
                }

                redraw = true;
                
                // Handle hot code reloading
                if (stateReload) {

                    redraw = false;
                    stateReload = false;
                    while(lua_gettop(L)) {
                        lua_pop(L, 1);
                    }
                    luaRequire("main.lua");
                    lua_pop(L, 1);

                }

                break;
        

            default:
                break;
        }


        // Render it out
		if (redraw && al_is_event_queue_empty(stateEventQueue)) {

            // Handle resizing
            if (graphicsResized) {

                al_resize_display(graphicsDisplay, graphicsWidth * graphicsScale, graphicsHeight * graphicsScale);

                if (graphicsBackground != NULL) {
                    al_destroy_bitmap(graphicsBackground);
                }

                if (graphicsScale != 1) {
                    graphicsBackground = al_create_bitmap(graphicsWidth, graphicsHeight);
                    al_set_target_bitmap(graphicsBackground);

                } else {
                    al_set_target_bitmap(al_get_backbuffer(graphicsDisplay));
                }

                graphicsResized = false;

            }

            if (graphicsScale != 1) {
                al_set_target_bitmap(graphicsBackground);
            }

            al_clear_to_color(graphicsBackgroundColor);

            // Lua call
            //al_hold_bitmap_drawing(true);
            luaRender();
            //al_hold_bitmap_drawing(false);

            // Scale up if necessary
            if (graphicsScale != 1) {
                al_set_target_bitmap(al_get_backbuffer(graphicsDisplay));
                al_draw_scaled_bitmap(graphicsBackground, 0, 0, graphicsWidth, graphicsHeight, 0, 0, 
                                      graphicsWidth * graphicsScale, graphicsHeight * graphicsScale, 0);
            }

			al_flip_display();
            redraw = false;

        }

    }

}

void clearImage(const char *key, void *value) {
    al_destroy_bitmap(value);
}

void clearImageTile(const char *key, void *value) {
    free(value);
}

void gameCleanup() {
    
    debugLog("game: cleanup...\n");

	al_destroy_event_queue(stateEventQueue);
	al_destroy_timer(stateTimer);
	al_destroy_display(graphicsDisplay);

    if (graphicsBackground != NULL) {
        al_destroy_bitmap(graphicsBackground);
    }

    // Free images
    graphicsImages->each(graphicsImages, *clearImage);
    graphicsImages->destroy(&graphicsImages);

    // Free image tiles
    graphicsImageTiles->each(graphicsImageTiles, *clearImageTile);
    graphicsImageTiles->destroy(&graphicsImageTiles);

    ioCloseBundle();

}

