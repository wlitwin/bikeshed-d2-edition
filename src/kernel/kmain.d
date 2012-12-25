import kernel.layer0.vga;
import kernel.layer0.serial;
import kernel.layer0.interrupts;
import kernel.layer0.memory.memory;

import kernel.layer1.clock;
import kernel.layer1.process.scheduler;
import kernel.layer1.syscall.syscalls;

__gshared:
string message = "Hello World! From the D2 Programming language!";

extern (C) void 
kmain()
{
	put_string(0, 0, message);

	init_serial_debug();

	// Must be first
	init_interrupts();
	init_clock();
	// Memory needs to happen before any other modules
	init_memory();

	// All other modules that depend on linkedlist or memory allocation
	scheduler_initialize();
	syscalls_initialize();

	serial_outln("Finished loading the kernel");

	enable_interrupts();
	
	int val1 = 0;
	while (true)
	{
		// Verify that everything is still working
		int val = 0x12345678;
		val1 += 1;
		asm
		{
			sti;
			mov EAX, val;
			mov EBX, val1;
			hlt;
		}
	}
}
