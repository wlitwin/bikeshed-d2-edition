module arch.x86.support;

__gshared:
nothrow:
public:

extern (C)
{
	ubyte  inb(ushort port);
	ushort inw(ushort port);
	uint   inl(ushort port);

	void outb(ushort port, ubyte  val);
	void outw(ushort port, ushort val);
	void outl(ushort port, uint   val);
}
