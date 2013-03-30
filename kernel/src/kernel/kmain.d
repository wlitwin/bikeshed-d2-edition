module kernel.kmain;

import kernel.kprintf;
import kernel.memory.init;

__gshared:
nothrow:

extern (C)
void kmain()
{
	// Needs to be first for now, as pretty much everything will
	// depend on it for debugging purposes
	kernel.kprintf.init();

	// Next we really need to have our physical and virtual allocators
	// up and running before the rest of the kernel can do anything.
	kernel.memory.init.init();

	// A little test for kprintf
	kprintf("Test String %x!\n", 1234);

	asm { cli; mov EAX, 0xCAFEBABE; hlt; }
}
