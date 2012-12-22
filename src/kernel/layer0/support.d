module kernel.layer0.support;

import kernel.layer0.serial : serial_outln;

__gshared:
nothrow:
public:

extern (C)
{
	ubyte  __inb(ushort port);
	ushort __inw(ushort port);
	uint   __inl(ushort port);

	void __outb(ushort port, ubyte  val);
	void __outw(ushort port, ushort val);
	void __outl(ushort port, uint   val);
}

private uint m_z = 0x12345678;
private uint m_w = 0xC001C0DE;
uint
krand()
{
	m_z = 36969 * (m_z & 65535) + (m_z >> 16);
	m_w = 18000 * (m_w & 65535) + (m_w >> 16);

	return (m_z << 16) + m_w;
}

void
panic(S...)(S args)
{
	serial_outln(args);
	asm
	{
		mov EAX, 0xBADC0DE;	
		cli;
		hlt;
	}
}
