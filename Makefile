FILES:=main.c sources/*.c deps/minizip/unzip.c deps/minizip/ioapi.c deps/types/array_list.c deps/types/linked_iter.c deps/types/linked_list.c deps/types/hash_map.c
LUA:=build/lua/lapi.o build/lua/lauxlib.o build/lua/lbaselib.o build/lua/lbitlib.o build/lua/lcode.o build/lua/lcorolib.o build/lua/lctype.o build/lua/ldblib.o build/lua/ldebug.o build/lua/ldo.o build/lua/ldump.o build/lua/lfunc.o build/lua/lgc.o build/lua/linit.o build/lua/liolib.o build/lua/llex.o build/lua/lmathlib.o build/lua/lmem.o build/lua/loadlib.o build/lua/lobject.o build/lua/lopcodes.o build/lua/loslib.o build/lua/lparser.o build/lua/lstate.o build/lua/lstring.o build/lua/lstrlib.o build/lua/ltable.o build/lua/ltablib.o build/lua/ltm.o build/lua/lundump.o build/lua/lvm.o build/lua/lzio.o


ALLEGRO:=-lallegro -lallegro_memfile -lallegro_primitives -lallegro_image -lallegro_audio -lallegro_acodec 
ALLEGRO_STATIC:=`pkg-config --libs --static allegro-static-5.0 allegro_memfile-static-5.0 allegro_primitives-static-5.0 allegro_image-static-5.0 allegro_audio-static-5.0 allegro_acodec-static-5.0` 

CFLAGS=-o main -Wall -Wextra -Wno-unused

build: $(FILES) $(LUA)
	gcc $(CFLAGS) $(FILES) $(LUA) $(ALLEGRO)
	strip main

build/lua/%.o: deps/lua/%.c
	@mkdir -p build/lua
	$(CC) -O2 -c -o $@ $<

bundle:
	gcc $(CFLAGS) $(FILES) $(LUA) $(ALLEGRO) -DBUNDLE
	strip main
	mkdir -p build
	cd game && zip ../build/game.zip *
	cd ..
	cat build/game.zip >> main

debug: $(FILES)
	gcc $(CFLAGS) $(FILES) $(LUA) $(ALLEGRO) -ggdb

static: $(FILES)
	gcc $(CFLAGS) $(FILES) $(LUA) $(ALLEGRO_STATIC)
	strip main

