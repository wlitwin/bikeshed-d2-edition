import kernel.support;

__gshared:

alias extern(C) void function(int vector, int code) isr_handler;

isr_handler __isr_table[256];

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

struct IDT_Gate
{
	ushort offset_15_0;
	ushort segment_selector;
	ushort flags;
	ushort offset_31_16;
}

void
init_interrupts()
{
	init_idt();
	init_pic();	
}

void
init_idt()
{
	for (int i = 0; i < 256; ++i)
	{
		set_idt_entry(i, __isr_stub_table[i]);
		install_isr(i, &__default_unexpected_handler);
	}

	install_isr(INT_VEC_KEYBOARD, &__default_expected_handler);
	install_isr(INT_VEC_TIMER,    &__default_expected_handler);
	install_isr(INT_VEC_MYSTERY,  &__default_mystery_handler);
}

extern (C)
void regular_isr_stub()
{

}

extern (C)
void error_code_isr_stub()
{

}

void
init_pic()
{
	__outb(PIC_MASTER_CMD_PORT, PIC_ICW1BASE | PIC_NEEDICW4);
	__outb(PIC_SLAVE_CMD_PORT,  PIC_ICW1BASE | PIC_NEEDICW4);

	__outb(PIC_MASTER_IMR_PORT, 0x20);
	__outb(PIC_SLAVE_IMR_PORT,  0x28);

	__outb(PIC_MASTER_IMR_PORT, PIC_MASTER_SLAVE_LINE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_SLAVE_ID);

	__outb(PIC_MASTER_IMR_PORT, PIC_86MODE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_86MODE);
	
	__outb(PIC_MASTER_IMR_PORT, 0x0);
	__outb(PIC_SLAVE_IMR_PORT,  0x0);
}

void
set_idt_entry(int entry, isr_handler handler)
{
	IDT_Gate* g = cast(IDT_Gate*)IDT_ADDRESS + entry;

	g.offset_15_0 = cast(int)handler & 0xFFFF;
	g.segment_selector = 0x0010;
	g.flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
	g.offset_31_16 = cast(int)handler >> 16 & 0xFFFF;
}

void
install_isr(int vector, isr_handler handler)
{
	__isr_table[vector] = handler;
}

extern (C) void
__default_expected_handler(int vector, int code)
{
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
		panic();
	}
}

void
panic()
{
	while (true)
	{
		asm
		{
			cli;
			hlt;
		}
	}
}

extern (C) void
__default_mystery_handler(int vector, int code)
{
	__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
}

extern (C) void 
__default_unexpected_handler(int vector, int code)
{
	panic();
}
