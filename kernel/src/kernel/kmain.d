module kernel.kmain;

__gshared:
nothrow:

extern (C)
void kmain()
{
	asm { cli; mov EAX, 0xCAFEBABE; hlt; }
}
