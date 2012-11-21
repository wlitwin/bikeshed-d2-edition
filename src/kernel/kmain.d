import kernel.vga;
import kernel.serial;
import kernel.interrupts;
import kernel.clock;
import kernel.memory.memory;
import kernel.process.scheduler;

// From the D runtime
//import core.runtime;

__gshared:
string message = "Hello World! From the D2 Programming language!";

extern (C) void 
kmain()
{
//	void exception_handler(Throwable t)
//	{
//		throw t;
//	}

//	try
//	{
//		Runtime.initialize(&exception_handler);

		put_string(0, 0, message);

		init_serial_debug();

		serial_outln("TESTING TESTING\n", 10, "\n", -10, "\n");

		init_interrupts();
		init_clock();

		init_memory();
		put_string(0, 1, "Initialized Memory");

		scheduler_initialize();

		serial_outln("Finished loading the kernel");
		// Don't bother terminating the runtime
		//Runtime.terminate();

//	}
//	catch (Throwable t) { /* Do nothing */ }
//	finally { /* Do nothing */ }
	enable_interrupts();
	
	int val1 = 0;
	while (true)
	{
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
