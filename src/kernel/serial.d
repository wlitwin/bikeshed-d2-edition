import kernel.support;

enum SERIAL_PORT_A = 0x3F8;



void serial_install()
{
	__outb(SERIAL_PORT_A + 1, 0x00);
	__outb(SERIAL_PORT_A + 3, 0x80);
	__outb(SERIAL_PORT_A + 0, 0x03);
	__outb(SERIAL_PORT_A + 1, 0x00);
	__outb(SERIAL_PORT_A + 3, 0x03);
	__outb(SERIAL_PORT_A + 2, 0xC7);
	__outb(SERIAL_PORT_A + 4, 0x08);
}

void serial_printf()
{

}

private int serial_transmit_empty()
{
	return __inb(SERIAL_PORT_A + 5) & 0x20;
}

private void serial_char(char c)
{
	while (serial_transmit_empty() == 0);
	__outb(SERIAL_PORT_A, c);
}

void serial_string(string s)
{
	foreach (c ; s)
	{
		serial_char(c);
	}
}

