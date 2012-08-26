import kernel.vga;
import kernel.interrupts;
import kernel.paging.memory;

__gshared:
string message = "Hello World! From the D2 Programming language!";

extern (C) void 
kmain()
{
	put_string(0, 0, message);

	init_interrupts();

	init_memory();
	put_string(0, 1, "Initialized Memory");

	int val = 0x12345678;
	asm
	{
		mov EAX, val;
		hlt;
	}
}
