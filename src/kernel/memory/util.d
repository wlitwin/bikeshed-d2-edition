module kernel.memory.util;

__gshared:
nothrow:

alias immutable(ubyte) iubyte;

private uint m_z = 0x12345678;
private uint m_w = 0xC001C0DE;
uint krand()
{
	m_z = 36969 * (m_z & 65535) + (m_z >> 16);
	m_w = 18000 * (m_w & 65535) + (m_w >> 16);

	return (m_z << 16) + m_w;
}

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
