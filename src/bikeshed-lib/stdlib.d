extern (C) int memcmp(void* ptr1, void* ptr2, size_t num)
{
	byte* ptrA = cast(byte *)ptr1;
	byte* ptrB = cast(byte *)ptr2;

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
}

extern (C) void* memset(void* ptr, int value, size_t num)
{
	byte val = cast(byte) value;
	byte* bytePtr = cast(byte *) ptr;
	while (num > 0)
	{
		*bytePtr = val;
		++bytePtr;
		--num;
	}

	return ptr;
}

extern (C) void* memcpy(void* destination, void* source, size_t num)
{
	byte* bytePtrSrc  = cast(byte *)source;
	byte* bytePtrDest = cast(byte *)destination;

	while (num > 0)
	{
		*bytePtrDest = *bytePtrSrc;
		++bytePtrDest;
		++bytePtrSrc;
		--num;
	}

	return destination;
}

extern (C) size_t strlen(char* str)
{
	size_t length = 0;
	while (*str != 0)
	{
		++length;
		++str;
	}

	return length;
}
