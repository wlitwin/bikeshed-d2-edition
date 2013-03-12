import kernel.layer0.vga;
import kernel.layer0.serial;
import kernel.layer0.interrupts;
import kernel.layer0.memory.memory;

import kernel.layer1.clock;
import kernel.layer1.malloc;
import kernel.layer1.ramfs.fat;
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
	syscalls_initialize();

	initialize_ramfs(cast(ubyte*)0x600000);

	malloc_initialize();

	scheduler_initialize();

	serial_outln("Finished loading the kernel");

	// Save the current kernel stack
	asm
	{
		mov kernel_stack, ESP;
	}

	// Interrupts are turned on because EFLAGS gets restored with
	// the interrupt flag being turned on
	isr_restore();

	// Wait for the first interrupt, after that we should be
	// executing the idle process and never return here
	while (true) { asm { hlt; } }
}
