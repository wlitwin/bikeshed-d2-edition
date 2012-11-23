import kernel.layer0.vga;
import kernel.layer0.serial;
import kernel.layer0.interrupts;
import kernel.layer1.clock;
import kernel.layer0.memory.memory;
import kernel.layer1.process.scheduler;
import kernel.layer1.syscall.syscalls;

// From the D runtime
//import core.runtime;

__gshared:
string message = "Hello World! From the D2 Programming language!";

extern (C) void 
kmain()
{
	put_string(0, 0, message);

	init_serial_debug();
	serial_outln("TESTING TESTING\n", 10, "\n", -10, "\n");
	// Must be first
	init_interrupts();
	init_clock();
	// Memory needs to happen before any other modules
	init_memory();
	put_string(0, 1, "Initialized Memory");

	// All other modules that depend on linkedlist or memory allocation
	scheduler_initialize();

	syscalls_initialize();

	serial_outln("Finished loading the kernel");

/+	void exception_handler(Throwable t)
	{
		throw t;
	}

	/*asm { mov EAX, 0x99999999; }

	void delegate(int a) nothrow my_del = void;

	int super_variable = 20;
	void my_function(int a) nothrow
	{
		serial_outln(super_variable, a);
	}

	my_del = &my_function;

	asm { mov EAX, 0xAAAAAAAA; }
	*/

	try
	{
		Runtime.initialize(&exception_handler);

		// Don't bother terminating the runtime
		//Runtime.terminate();

	}
	catch (Throwable t) { /* Do nothing */ }
	finally { /* Do nothing */ }
	// +/
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
