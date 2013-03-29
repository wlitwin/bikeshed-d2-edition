module arch.x86.kprintf;

private import arch.x86.support;

__gshared:
nothrow:
public:

void init()
{
	init_serial_debug();
}

void write_char(char c)
{
	serial_char(c);
}

private:

enum SERIAL_PORT_A = 0x3F8;

public void 
init_serial_debug()
{
	outb(SERIAL_PORT_A + 1, 0x00);
	outb(SERIAL_PORT_A + 3, 0x80);
	outb(SERIAL_PORT_A + 0, 0x03);
	outb(SERIAL_PORT_A + 1, 0x00);
	outb(SERIAL_PORT_A + 3, 0x03);
	outb(SERIAL_PORT_A + 2, 0xC7);
	outb(SERIAL_PORT_A + 4, 0x08);
}

int serial_transmit_empty()
{
	return inb(SERIAL_PORT_A + 5) & 0x20;
}

void serial_char(char c)
{
	while (serial_transmit_empty() == 0) { }
	outb(SERIAL_PORT_A, c);
}
