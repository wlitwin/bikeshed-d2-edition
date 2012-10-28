alias immutable(ubyte) iubyte;

extern(C)
{
	__gshared
	{
		void* _deh_beg;
		void* _deh_end;
	}

	__gshared
	{
		int errno;
	}
}


// TODO - Should be for the current thread
extern(C)
int* __errno_location()
{
	return &errno;
}

// TODO - Actually return a valid value
extern(C)
double strtold(const char* str, char** endptr)
{
	return 0.0;
}

extern(C)
void* malloc()
{
	int val = 0x11111111;
	asm {
		mov EAX, val;
		hlt;
	}
	return null;
}

extern (C)
void* calloc()
{
	int val = 0x22222222;
	asm {
		mov EAX, val;
		hlt;
	}
	return null;
}

extern(C)
void* realloc(void* ptr, size_t size)
{
	return null;
}

extern (C)
void free(void* ptr)
{
	int val = 0x33333333;
	asm {
		mov EAX, val;
		hlt;
	}
}

extern (C)
int pthread_mutex_init(void* param)
{
	int val = 0x44444444;
	asm {
		mov EAX, val;
		hlt;
	}
	return 1;
}

extern (C)
int pthread_mutex_lock(void* param)
{
	int val = 0x55555555;
	asm {
		mov EAX, val;
		hlt;
	}
	return 1;
}

extern (C)
int pthread_mutex_unlock(void* param)
{
	int val = 0x66666666;
	asm {
		mov EAX, val;
		hlt;
	}
	return 1;
}

extern (C) int 
memcmp(immutable(void*) ptr1, immutable(void*) ptr2, size_t num)
{
	iubyte* ptrA = cast(iubyte *)ptr1;
	iubyte* ptrB = cast(iubyte *)ptr2;

	while (num > 0)
	{
		if (*ptrA != *ptrB) 
		{
			return *ptrA - *ptrB;		
		}

		++ptrA;
		++ptrB;
		--num;
	}

	return 0;
}

extern (C) void*
memmove(void* destination, const void* source, size_t num)
{
	ubyte* dest = cast(ubyte *)destination;
	ubyte* src  = cast(ubyte *)source;

	while(num > 0)
	{
		*dest = *src;
		++dest;
		++src;
		--num;
	}

	return dest;
}

extern (C) void*
memchr(const void* ptr, int value, size_t num)
{
	ubyte* srch = cast(ubyte *)ptr;
	ubyte val = cast(ubyte)value;
	while (num > 0)
	{
		if (*srch == val)
			return srch;

		++srch;
		--num;
	}

	return null;
}

extern (C) void* 
memset(void* ptr, int value, size_t num)
{
	ubyte val = cast(ubyte) value;
	ubyte* bytePtr = cast(ubyte *) ptr;
	while (num > 0)
	{
		*bytePtr = val;
		++bytePtr;
		--num;
	}

	return ptr;
}

extern (C) void* 
memcpy(void* destination, immutable(void*) source, size_t num)
{
	iubyte* bytePtrSrc  = cast(iubyte *)source;
	ubyte*  bytePtrDest = cast(ubyte *)destination;

	while (num > 0)
	{
		*bytePtrDest = *bytePtrSrc;
		++bytePtrDest;
		++bytePtrSrc;
		--num;
	}

	return destination;
}

extern (C) size_t 
strlen(immutable(char)* str)
{
	size_t length = 0;
	while (*str != 0)
	{
		++length;
		++str;
	}

	return length;
}
