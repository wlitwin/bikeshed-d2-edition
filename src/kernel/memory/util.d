module kernel.memory.util;

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
