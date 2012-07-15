
#ifndef ARRAY_LIST_H
#define ARRAY_LIST_H

struct ArrayList;
typedef struct ArrayList {
    
    unsigned int length;
    unsigned int size;

    void **items;

    void (*clear)(struct ArrayList *list);
    void (*trim)(struct ArrayList *list);
    void (*reverse)(struct ArrayList *list);
    void (*destroy)(struct ArrayList **list);

    int (*has)(struct ArrayList *list, void *p);
    int (*find)(struct ArrayList *list, void *p);
    int (*findLast)(struct ArrayList *list, void *p);

    void *(*get)(struct ArrayList *list, const int index);
    struct ArrayList *(*getRange)(struct ArrayList *list, const int startIndex, 
                                                          const int endIndex);

    void *(*set)(struct ArrayList *list, const int index, void *p);

    void *(*append)(struct ArrayList *list, void *p);
    struct ArrayList *(*appendRange)(struct ArrayList *list, 
                                     struct ArrayList *other);

    void *(*insert)(struct ArrayList *list, const int index, void *p);
    struct ArrayList *(*insertRange)(struct ArrayList *list, const int index, 
                                     struct ArrayList *other);

    void *(*pop)(struct ArrayList *list, const int index);
    struct ArrayList *(*popRange)(struct ArrayList *list, const int startIndex, 
                                                          const int endIndex);

    void *(*add)(struct ArrayList *list, void *p);
    void *(*remove)(struct ArrayList *list, void *p);

    void (*each)(struct ArrayList *list, void (*cb)(void *value));

} ArrayList;


/* Constructor -------------------------------------------------------------- */
ArrayList *arrayList(const unsigned int size);


/* Constants ---------------------------------------------------------------- */
#define ARRAY_LIST_MIN_SIZE 16

#endif

