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
#include "../include/io.h"

unzFile *zipFile = NULL;

void ioOpenBundle(const char *filename) {
    
    debugLog("bundle: open \"%s\"...\n", filename);
    zipFile = unzOpen(filename);
    if (zipFile == NULL) {
        debugLog("bundle: Failed to open\n");
    }

}

void ioCloseBundle() {
    if (zipFile) {
        unzClose(zipFile);
    }
}

char *ioLoadResource(const char *filename, int *bufSize) {
    
    // We assume the chdir to "game" has been done already
    if (zipFile == NULL) {

        FILE *f = fopen(filename, "r");
        if (f == NULL) {
            debugLog("io: File \"%s\" not found\n", filename);
            return NULL;
        }

        fseek(f, 0, SEEK_END);
        *bufSize = ftell(f);
        fseek(f, 0, SEEK_SET);
        
        char *buf = (char*)calloc(*bufSize + 1, sizeof(char));
        if (fread(buf, sizeof(char), *bufSize, f) != *bufSize) {
            debugLog("io: File \"%s\" could not be read\n", filename);
            return NULL;
        }
        fclose(f);

        debugLog("io: File \"%s\" loaded\n", filename);
        return buf;

    } else {
        
        if (unzLocateFile(zipFile, filename, 0) != UNZ_OK) {
            debugLog("io: File \"%s\" not found in bundle\n", filename);
            return NULL;

        } else {

            if (unzOpenCurrentFile(zipFile) != UNZ_OK) {
                debugLog("io: Failed to open \"%s\" in bundle\n", filename);
                return NULL;
                
            } else {

                unz_file_info file_info;
                char filename_inzip[256];
                int err = unzGetCurrentFileInfo(zipFile, &file_info, filename_inzip,sizeof(filename_inzip),NULL,0,NULL,0);

                if (err != UNZ_OK) {
                    debugLog("io: Failed to get info on \"%s\" in bundle\n", filename);
                    return NULL;
                }

                *bufSize = file_info.uncompressed_size;
                char *buf = (char*)calloc(*bufSize + 1, sizeof(char));
                unzReadCurrentFile(zipFile, buf, *bufSize);

                unzCloseCurrentFile(zipFile);

                debugLog("io: File \"%s\" loaded from bundle\n", filename);

                return buf;

            }

        }
        
    }

}

static ALLEGRO_FILE *ioOpenFile(const char *filename) {
    int len;
    char *buf = ioLoadResource(filename, &len);
    return al_open_memfile(buf, len, "r");
}

ALLEGRO_BITMAP *ioLoadBitmap(const char *filename) {

    debugLog("io: load bitmap \"%s\"\n", filename);

    int len = strlen(filename);
    char *ext = (char*)calloc(5, sizeof(char));
    strcpy(ext, filename + (len - 4));

    ALLEGRO_FILE *fp = ioOpenFile(filename);
    ALLEGRO_BITMAP *img = al_load_bitmap_f(fp, ext);

    free(ext);

    debugLog("io: bitmap \"%s\" loaded\n", filename);

    return img;
}

ALLEGRO_SAMPLE *ioLoadSample(const char *filename) {

    debugLog("io: load sample \"%s\"\n", filename);

    int len = strlen(filename);
    char *ext = (char*)calloc(5, sizeof(char));
    strcpy(ext, filename + (len - 4));

    ALLEGRO_FILE *fp = ioOpenFile(filename);
    ALLEGRO_SAMPLE *img = al_load_sample_f(fp, ext);

    free(ext);

    debugLog("io: sample \"%s\" loaded\n", filename);

    return img;
}

void ioDumpResource(const char* filename) {
    
    char *buf;
    int len;
    buf = ioLoadResource(filename, &len);
    if (buf != NULL) {

        int i;
        for(i = 0; i < len; i++) {
            debugLog("%c", ((char *)buf)[i]);
        }

        free(buf);
    }

}

