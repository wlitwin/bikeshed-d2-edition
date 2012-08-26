alias immutable(ubyte) iubyte;

extern(C)
{
	__gshared
	{
		void* _deh_beg;
		void* _deh_end;
	}
}


extern(C)
void* malloc()
{
	asm {hlt;}
	return null;
}

extern (C)
void* calloc()
{
	asm {hlt;}
	return null;
}

extern (C)
void free(void* ptr)
{
	asm {hlt;}
}

extern (C)
int pthread_mutex_init(void* param)
{
	asm {hlt;}
	return 1;
}

extern (C)
int pthread_mutex_lock(void* param)
{
	asm {hlt;}
	return 1;
}

extern (C)
int pthread_mutex_unlock(void* param)
{
	asm {hlt;}
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
