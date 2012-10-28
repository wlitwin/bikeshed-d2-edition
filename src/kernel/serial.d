module kernel.serial;

import std.conv;

import core.vararg;
import kernel.support;

__gshared:

enum SERIAL_PORT_A = 0x3F8;

void init_serial_debug()
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
	while (serial_transmit_empty() == 0) { }
	__outb(SERIAL_PORT_A, c);
}

private string hexdigits = "0123456789ABCDEF";

private int to_string_u(uint val, ref char buffer[10], int index = 9)
{
	do
	{
		buffer[index] = val % 10 + '0';
		--index;
		val /= 10;
	} 
	while (index >= 0 && val != 0);

	return index+1;
}

private int to_string_i(int val, ref char buffer[11], int index = 10)
{
	bool negative = val < 0;
	if (negative)
	{
		val = -val;
	}

	do
	{
		buffer[index] = val % 10 + '0';
		--index;
		val /= 10;
	} 
	while (index >= 1 && val != 0);

	if (negative)
	{
		buffer[index] = '-';
		--index;
	}
	
	return index+1;
}

private void write_string(string s)
{
	foreach (c ; s)
	{
		serial_char(c);
	}
}

private void write_string(char[] s)
{
	foreach (c ; s)
	{
		serial_char(c);
	}
}

void serial_outln(...)
{
	for (int i = 0; i < _arguments.length; ++i)
	{
		if (_arguments[i] == typeid(string))
		{
			string str = va_arg!(string)(_argptr);
			write_string(str);
		}
		else if (_arguments[i] == typeid(uint))
		{
			uint val = va_arg!(uint)(_argptr);
			char buffer[10];
			for (int j = to_string_u(val, buffer); j < 10; ++j)
			{
				serial_char(buffer[j]);
			}
		}
		else if (_arguments[i] == typeid(int))
		{
			int val = va_arg!(int)(_argptr);				
			char buffer[11];
			
			for (int j = to_string_i(val, buffer); j < 11; ++j)
			{
				serial_char(buffer[j]);
			}
		}
	}

	serial_char('\n');
}

