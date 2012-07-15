#define BINARY_TREE_MIN_SIZE 16

typedef struct BinaryNode {

    unsigned int parent;
    unsigned int index;
    void *data;

};

typedef struct BinaryTree {
    
    unsigned int size;
    unsigned int depth;
    BinaryNode **nodes;
    
};


/* Constructor -------------------------------------------------------------- */
BinaryTree *binaryTree(const unsigned int size) {

    BinaryTree *tree = malloc(sizeof(BinaryTree));
    if (tree == NULL) {
        return NULL;
    }

    tree->size = size > 0 ? size : BINARY_TREE_MIN_SIZE;
    tree->nodes = malloc(sizeof(BinaryNode*) * tree->size);
    
}

static void *add_node(void *parent, void *p) {
    
    BinaryNode node = malloc(sizeof(BinaryNode));
    node->parent = parent->index;

    // figure out whether we need to resize the array

    // figure out whether we need to move nodes around because of this insertion
    
    // get children of the parent and replace their parent with the new one

    // insert the new node
    
}


static int max_size(const unsigned int index) {
    return index * 2 + 2;
}

