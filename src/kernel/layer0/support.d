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

void
panic(S...)(S args)
{
	serial_outln(args);
	asm
	{
		cli;
		hlt;
	}
}