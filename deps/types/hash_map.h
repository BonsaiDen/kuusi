
#ifndef HASH_MAP_H
#define HASH_MAP_H

#include "linked_list.h"
#include "array_list.h"

struct HashEntry;
typedef struct HashEntry {

    struct HashEntry *next;
    char *key;
    void *value;
    LinkedNode *lnode;

} HashEntry;

typedef struct HashMap {
    
    unsigned int size;
    unsigned int filled;
    unsigned int length;

    HashEntry **buckets;
    LinkedList *entries;

    void (*clear)(struct HashMap *map);
    void (*destroy)(struct HashMap **map);

    int (*hasKey)(struct HashMap *map, const char *key);
    int (*hasValue)(struct HashMap *map, void *p);

    void *(*set)(struct HashMap *map, const char *key, void *value);
    void *(*get)(struct HashMap *map, const char *key);
    void *(*del)(struct HashMap *map, const char *key);

    void (*each)(struct HashMap *map, void (*cb)(const char *key, void *value));

    ArrayList *(*values)(struct HashMap *map);
    ArrayList *(*keys)(struct HashMap *map);

} HashMap;


/* Constructor -------------------------------------------------------------- */
HashMap *hashMap(const unsigned int size);


/* Constants ---------------------------------------------------------------- */
#define HASH_MAP_DEFAULT_SIZE 256

#endif

