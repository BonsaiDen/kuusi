
#ifndef LINKED_LIST_H
#define LINKED_LIST_H

#include "array_list.h"

struct LinkedNode;
typedef struct LinkedNode {
    
    struct LinkedNode *prev;
    struct LinkedNode *next;
    void *value;
    
} LinkedNode;


struct LinkedList;
typedef struct LinkedIter {

    struct LinkedList *list;
    LinkedNode *node;

    void (*destroy)(struct LinkedIter **iter);

    void (*begin)(struct LinkedIter *iter);
    void *(*next)(struct LinkedIter *iter);
    void *(*prev)(struct LinkedIter *iter);
    void (*end)(struct LinkedIter *iter);

} LinkedIter;


typedef struct LinkedList {
    
    unsigned int length;

    LinkedNode *front;
    LinkedNode *back;

    void (*clear)(struct LinkedList *list);
    void (*reverse)(struct LinkedList *list);
    void (*destroy)(struct LinkedList **list);

    ArrayList *(*array)(struct LinkedList *list);

    int (*has)(struct LinkedList *list, void *p);
    int (*find)(struct LinkedList *list, void *p);
    int (*findLast)(struct LinkedList *list, void *p);

    LinkedNode *(*insertFront)(struct LinkedList *list, void *value);
    LinkedNode *(*insertBack)(struct LinkedList *list, void *value);
    LinkedNode *(*insertBefore)(struct LinkedList *list, 
                                struct LinkedNode *p, void *value);

    LinkedNode *(*insertAfter)(struct LinkedList *list, 
                               struct LinkedNode *p, void *value);

    void *(*removeFront)(struct LinkedList *list);
    void *(*removeNode)(struct LinkedList *list, LinkedNode **p);
    void *(*removeBack)(struct LinkedList *list);

    void (*each)(struct LinkedList *list, void (*cb)(void *value));

} LinkedList;


/* Constructor -------------------------------------------------------------- */
LinkedList *linkedList();
LinkedIter *linkedIter();

#endif

