module kernel.support;

nothrow:

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
panic()
{
	asm
	{
		cli;
		hlt;
	}
}
