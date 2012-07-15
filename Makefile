FILES:=main.c sources/*.c deps/minizip/unzip.c deps/minizip/ioapi.c deps/types/array_list.c deps/types/linked_iter.c deps/types/linked_list.c deps/types/hash_map.c

LUA:= -I/usr/include/lua5.1/ -L/usr/local/lib -llua5.1 -llualib50 

ALLEGRO:=-lallegro -lallegro_memfile -lallegro_primitives -lallegro_image -lallegro_audio -lallegro_acodec 
ALLEGRO_STATIC:=`pkg-config --libs --static allegro-static-5.0 allegro_memfile-static-5.0 allegro_primitives-static-5.0 allegro_image-static-5.0 allegro_audio-static-5.0 allegro_acodec-static-5.0` 

PROGRAM:=gcc -o main -Wall

build: $(FILES)
	$(PROGRAM) $(FILES) $(LUA) $(ALLEGRO)

bundle:
	$(PROGRAM) $(FILES) $(LUA) $(ALLEGRO) -DBUNDLE
	mkdir -p build
	cd game && zip ../build/game.zip *
	cd ..
	cat build/game.zip >> main

debug: $(FILES)
	$(PROGRAM) $(FILES) $(LUA) $(ALLEGRO) -ggdb

static: $(FILES)
	$(PROGRAM) $(FILES) -Wl,-Bstatic $(LUA) -Wl,-Bdynamic $(ALLEGRO_STATIC)
	strip -s main

