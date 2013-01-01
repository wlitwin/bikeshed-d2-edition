module kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.templates;

import kernel.layer0.print;

__gshared:
nothrow:
private:


enum SERIAL_PORT_A = 0x3F8;

public void 
init_serial_debug()
{
	__outb(SERIAL_PORT_A + 1, 0x00);
	__outb(SERIAL_PORT_A + 3, 0x80);
	__outb(SERIAL_PORT_A + 0, 0x03);
	__outb(SERIAL_PORT_A + 1, 0x00);
	__outb(SERIAL_PORT_A + 3, 0x03);
	__outb(SERIAL_PORT_A + 2, 0xC7);
	__outb(SERIAL_PORT_A + 4, 0x08);
}

int 
serial_transmit_empty()
{
	return __inb(SERIAL_PORT_A + 5) & 0x20;
}

void 
serial_char(char c)
{
	while (serial_transmit_empty() == 0) { }
	__outb(SERIAL_PORT_A, c);
}

immutable(string) hexdigits = "0123456789ABCDEF";

int 
to_string_u(ulong val, ref char buffer[20], int index = 19)
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

int
to_string_i(long val, ref char buffer[21], int index = 20)
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

void
write_string(string s)
{
	foreach (c ; s)
	{
		serial_char(c);
	}
}

void
write_string(char[] s)
{
	foreach (c ; s)
	{
		serial_char(c);
	}
}

public
{
mixin(CreatePrinter!("kserial_print", serial_char, write_string));
}

public void 
serial_outln(S...)(S args)
{
	serial_out(args, '\n');
}

public void
serial_out(S...)(S args)
{
	foreach (arg; args)
	{
		alias typeof(arg) A;
		static if (isAggregateType!A || is(A == enum))
		{
			// Do something
			write_string("aggregate...");
		}
		else static if (isSomeString!A 
						|| is(A == string)
						|| is(A == dstring) 
						|| is(A == wstring))
		{
			write_string(arg);
		}
		else static if (isIntegral!A)
		{
			char buffer[21];
			for (int j = to_string_i(arg, buffer); j < 21; ++j)
			{
				serial_char(buffer[j]);
			}
		}
		else static if (isBoolean!A)
		{
			write_string(arg ? "true" : "false");			
		}
		else static if (isSomeChar!A)
		{
			serial_char(arg);
		}
		else
		{
			// Do something
			write_string("something else");
		}
	}
}

