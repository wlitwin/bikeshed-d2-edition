module kernel.interrupts;

import kernel.interrupt_defs;
import kernel.templates;
import kernel.support;
import kernel.serial;

__gshared:
nothrow:

alias extern(C) void function(int vector, int code) isr_handler;
alias extern(C) void function() idt_handler;

isr_handler __isr_table[256];
idt_handler __idt_table[256];

enum IDT_ADDRESS = 0x2500;

enum INT_VEC_DIVIDE_ERROR    = 0x0;
enum INT_VEC_DEBUG_EXCEPTION = 0x1;
enum INT_VEC_NMI_INTERRUPT   = 0x2;
enum INT_VEC_BREAKPOINT      = 0x3;
enum INT_VEC_INTO_DETECTED_OVERFLOW = 0x4;
enum INT_VEC_BOUND_RANGE_EXCEEDED = 0x5;
enum INT_VEC_INVALID_OPCODE = 0x6;
enum INT_VEC_DEVICE_NOT_AVAILABLE = 0x7;
enum INT_VEC_COPROCESSOR_OVERRUN = 0x8;
enum INT_VEC_INVALID_TSS = 0xa;
enum INT_VEC_SEGMENT_NOT_PRESENT = 0xb;
enum INT_VEC_STACK_FAULT = 0xc;
enum INT_VEC_GENERAL_PROTECTION = 0xd;
enum INT_VEC_PAGE_FAULT = 0xe;
enum INT_VEC_COPROCESSOR_ERROR = 0x10;
enum INT_VEC_ALIGNMENT_CHECK = 0x11;
enum INT_VEC_MACHINE_CHECK = 0x12;
enum INT_VEC_SIMD_FP_EXCEPTION = 0x13;
enum INT_VEC_TIMER = 0x20;
enum INT_VEC_KEYBOARD = 0x21;
enum INT_VEC_SERIAL_PORT_2 = 0x23;
enum INT_VEC_SERIAL_PORT_1 = 0x24;
enum INT_VEC_PARALLEL_PORT = 0x25;
enum INT_VEC_FLOPPY_DISK = 0x26;
enum INT_VEC_MYSTERY = 0x27;
enum INT_VEC_MOUSE = 0x2c;

enum PIC_MASTER_IMR_PORT = 0x21;
enum PIC_MASTER_SLAVE_LINE = 0x04;
enum PIC_SLAVE_ID = 0x02;
enum PIC_SLAVE_IMR_PORT  = 0xA1;
enum PIC_NEEDICW4 = 0x01;
enum PIC_ICW1BASE = 0x10;
enum PIC_86MODE = 0x01;
enum PIC_MASTER_CMD_PORT = 0x20;
enum PIC_SLAVE_CMD_PORT = 0xA0;
enum PIC_EOI = 0x20;

enum IDT_PRESENT = 0x8000;
enum IDT_DPL_0 = 0x0000;
enum IDT_INT32_GATE = 0x0e00;

private struct 
IDT_Gate
{
	short offset_15_0;
	short segment_selector;
	short flags;
	short offset_31_16;
}

public void
enable_interrupts()
{
	asm
	{
		sti;
	}
}

public void
disable_interrupts()
{
	asm
	{
		cli;
	}
}

public void
init_interrupts()
{
	serial_outln("\nInterrupts: Initializing");
	serial_outln("Interrupts: table size: ", __idt_table.sizeof, " ", __isr_table.sizeof);
	init_idt();
	init_pic();	
	serial_outln("Interrupts: Finished");
}

void
install_isr(int vector, isr_handler handler)
{
	__isr_table[vector] = handler;
}

private:

template createIDTStubs(long howMany = 255)
{
	static if (howMany < 0)
	{
		const string createIDTStubs = "";
	}
	// Error ISRs, these ISRs push an error code onto the
	// stack, so we need to handle that
	else static if (howMany == 0x08 || howMany == 0x0a ||
					howMany == 0x0b || howMany == 0x0c ||
					howMany == 0x0d || howMany == 0x0e ||
					howMany == 0x11)
	{
		const string createIDTStubs = createIDTStubs!(howMany-1) ~ 
			"extern (C) void idt_handler_" ~ itoa!(howMany) ~ "() {
				asm { 
					naked; 
					push " ~ itoa!(howMany) ~ ";
					jmp [__isr_table + 4*" ~ itoa!(howMany) ~ "];
					add ESP, 8;
					iret;
				}
			}\n";
	}
	else
	{
		const string createIDTStubs = createIDTStubs!(howMany-1) ~ 
			"extern (C) void idt_handler_" ~ itoa!(howMany) ~ "() {
				asm {
					naked; 
					push 0;
					push " ~ itoa!(howMany) ~ ";
					jmp [__isr_table + 4*" ~ itoa!(howMany) ~ "];
					add ESP, 8;
					iret;
				}
			}\n";
	}
}



template initializeIDTHandlers(long howMany = 255)
{
	static if (howMany < 0)
	{
		const string initializeIDTHandlers = "";
	}
	else
	{
		const string initializeIDTHandlers = initializeIDTHandlers!(howMany-1) 
			~ "__idt_table[" ~ itoa!(howMany) ~ "] = &idt_handler_" 
			~ itoa!(howMany) ~ ";\n";
	}
}

void
init_idt()
{
	// Make sure interrupts are off
	asm { cli; }

	setup_idt_table();

	serial_outln("Setup IDT table");
	// Setup the idt table
	// Parentheses are important for mixins!
//	mixin(initializeIDTHandlers!(255));

	for (int i = 0; i < 256; ++i)
	{
		// TODO - probably don't need the ISR stub table
		set_idt_entry(i, __idt_table[i]);
		install_isr(i, &__default_unexpected_handler);
	}

	install_isr(INT_VEC_KEYBOARD, &__default_expected_handler);
	install_isr(INT_VEC_SERIAL_PORT_1, &__default_expected_handler);
	install_isr(INT_VEC_MYSTERY,  &__default_mystery_handler);
	install_isr(INT_VEC_GENERAL_PROTECTION, &gpf_handler);

	// We could check to see if they were on and turn them
	// but leave them off for now and the caller will have
	// to turn interrupts back on
	//enable_interrupts();
	serial_outln("Done with IDT");
}

void
init_pic()
{
	asm { cli; }
	serial_outln("Initializing the pic");
	__outb(PIC_MASTER_CMD_PORT, PIC_ICW1BASE | PIC_NEEDICW4);
	__outb(PIC_SLAVE_CMD_PORT,  PIC_ICW1BASE | PIC_NEEDICW4);

	serial_outln("pic 2");
	__outb(PIC_MASTER_IMR_PORT, 0x20);
	__outb(PIC_SLAVE_IMR_PORT,  0x28);

	serial_outln("pic 3");
	__outb(PIC_MASTER_IMR_PORT, PIC_MASTER_SLAVE_LINE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_SLAVE_ID);

	serial_outln("pic 3");
	__outb(PIC_MASTER_IMR_PORT, PIC_86MODE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_86MODE);
	
	serial_outln("pic 4");
	__outb(PIC_MASTER_IMR_PORT, 0x0);
	__outb(PIC_SLAVE_IMR_PORT,  0x0);
	serial_outln("Finished with the pic");
}

void
set_idt_entry(int entry, idt_handler handler)
{
	IDT_Gate* g = cast(IDT_Gate*)IDT_ADDRESS + entry;

	g.offset_15_0 = cast(int)handler & 0xFFFF;
	g.segment_selector = 0x0010;
	g.flags = cast(short) (IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE);
	g.offset_31_16 = (cast(int)handler >> 16) & 0xFFFF;
}


extern (C) void
__default_expected_handler(int vector, int code)
{
	serial_outln("Expected interrupt ", vector);
	serial_outln("Error code: ", code);

	if (vector >= 0x20 && vector < 0x30)
	{
		__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
		if (vector > 0x28)
		{
			__outb(PIC_SLAVE_CMD_PORT, PIC_EOI);
		}
	}
	else
	{
		serial_outln("Something's wrong!");
		panic();
	}
}

extern (C) void
gpf_handler(int vector, int code)
{
	serial_outln("GPF: ", vector, " ", code);
	panic();
}

extern (C) void
__default_mystery_handler(int vector, int code)
{
	serial_outln("Got mystery interrupt");
	__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
}

extern (C) void 
__default_unexpected_handler(int vector, int code)
{
	serial_outln("Unexpected interrupt: ", vector);
	serial_outln("Error code: ", code);
	panic();
}
