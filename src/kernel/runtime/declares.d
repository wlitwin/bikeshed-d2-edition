
extern(C)
void* memcpy(void* s1, in void* s2, size_t n) @system nothrow;

extern(C)
void free(void* ptr) @system nothrow;

extern(C)
int memcmp(in void* s1, in void* s2, size_t n) pure @system nothrow;

extern(C)
size_t strlen(in char* s) pure nothrow @system;

extern(C)
void* malloc(size_t size) @system nothrow;

extern(C)
void* alloca(size_t size) @system nothrow;
