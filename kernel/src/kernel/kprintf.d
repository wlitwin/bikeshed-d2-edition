module kernel.kprintf;

import templates : va_arg;

__gshared:
nothrow:
public:

version (X86)
{
	// Need the write char/write string functions
	public  import arch.x86.kprintf : init;
	private import arch.x86.kprintf : write_char;
}
else
{
	static assert(false, "Kprintf: Unsupported Architecture");
}

void kprintf(string format, ...) 
{
	char ch;
	int index = 0;
	char buffer[12];

	char nextChar() nothrow {
		if (index >= format.length) {
			assert(false, "kprintf: Invalid format string");
		}
		return format[index++];
	}

	while (index < format.length)
	{
		ch = nextChar();

		if (ch == '%')
		{
			bool leftadjust = false;
			char padchar = ' ';
			int width = 0;

			ch = nextChar();
			if (ch == '-') {
				leftadjust = true;
				ch = nextChar();
			}
			if (ch == '0') {
				padchar = '0';
				ch = nextChar();
			}
			while (ch >= '0' && ch <= '9') {
				width *= 10;
				width += ch - '0';
				ch = nextChar();
			}

			switch(ch)
			{
				case 'c':
				case 'C':
					char c = va_arg!(char)(_argptr);
					buffer[0] = c;
					padstr(buffer, 1, width, leftadjust, padchar);
					break;
				case 'd':
				case 'D':
					int idx = convert_decimal(buffer, va_arg!(int)(_argptr));
					padstr(&buffer[idx], buffer.length-idx, width, leftadjust, padchar);
					break;
				case 'u':
				case 'U':
					int idx = convert_decimal_u(buffer, va_arg!(uint)(_argptr));
					padstr(&buffer[idx], buffer.length-idx, width, leftadjust, padchar);
					break;
				case 's':
				case 'S':
					string s = va_arg!(string)(_argptr);
					padstr(s.ptr, s.length, width, leftadjust, padchar);
					break;
				case 'x':
				case 'X':
					int idx = convert_hexidecimal(buffer, va_arg!(uint)(_argptr));
					padstr(&buffer[idx], buffer.length-idx, width, leftadjust, padchar);
					break;
				case 'o':
				case 'O':
					int idx = convert_octal(buffer, va_arg!(uint)(_argptr));
					padstr(&buffer[idx], buffer.length-idx, width, leftadjust, padchar);
					break;
				case '%':
					write_char('%');
					break;
				default:
					assert(false, "kprintf: Invalid format specifier");
					//break;
			}

		}
		else
		{
			write_char(ch);
		}
	}
}

private:

void padstr(const char* str, int len, int width, bool leftadjust, char padchar)
{
	void pad(int extra, char padchar) nothrow
	{
		for (; extra > 0; --extra)
		{
			write_char(padchar);
		}
	}

	int extra = width - len;
	if (extra > 0 && !leftadjust)
	{
		pad(extra, padchar);
	}

	for (int i = 0; i < len; ++i)
	{
		write_char(str[i]);
	}

	if (extra > 0 && leftadjust)
	{
		pad(extra, padchar);
	}
}

string hexdigits = "0123456789ABCDEF";

int convert_hexidecimal(ref char buf[12], uint value)
{
	int index = 11;
	do
	{
		buf[index--] = hexdigits[value % 16];
		value /= 16;
	} while (index >= 0 && value != 0);

	return index+1;
}

int convert_decimal_u(ref char buf[12], uint value)
{
	int index = 11;

	do	
	{
		buf[index--] = value % 10 + '0';
		value /= 10;
	} while (index >= 0 && value != 0);

	return index+1;
}

int convert_decimal(ref char buf[12], int value)
{
	int index = 11;
	bool negative = false;
	if (value < 0)
	{
		negative = true;
		value = -value;
	}

	do	
	{
		buf[index--] = value % 10 + '0';
		value /= 10;
	} while (index >= 0 && value != 0);

	if (negative)
	{
		assert(index >= 0, "convert_decimal: Bad index");
		buf[index--] = '-';
	}

	return index+1;
}

int convert_octal(ref char buf[12], int value)
{
	int index = 11;
	
	do
	{
		buf[index--] = value % 8 + '0';
		value /= 8;
	} while (index >= 0 && value != 0);

	return index+1;
}
