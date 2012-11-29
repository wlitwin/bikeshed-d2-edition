__gshared:
nothrow:

alias immutable(ubyte) iubyte;

extern (C) void
memclr(void* ptr, size_t size)
{
	ubyte* bytePtr = cast(ubyte *) ptr;
	while (size > 0)
	{
		*bytePtr = 0;
		++bytePtr;
		--size;
	}
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
memcpy(void* destination, const void* source, size_t num)
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

extern (C) int 
memcmp(const void* ptr1, const void* ptr2, size_t num)
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
