module kernel.layer0.vga;

import core.vararg; // From druntime

__gshared:
nothrow:

void put_char(int x, int y, byte c) nothrow
{
	ushort* video = cast(ushort *) 0xB8000 + (y*80 + x);

	*video = (0x70 << 8) | c;
}

void increment_col(ref int x, ref int y) nothrow //pure 
{
	++x;
	if (x > 80) {
		x = 0;
		++y;
		if (y == 25)
		{
			y = 0;
		}
	}
}

void put_string(int x, int y, string msg) 
{
	write_string(x, y, msg);
	/*for (int i = 0; i < _arguments.length; ++i)
	{
		if (_arguments[i] == typeid(string))
		{
			write_string(x, y, va_arg!(string)(_argptr));
		}
		else if (_arguments[i] == typeid(int))
		{
			write_string(x, y, "Integer");
		}
		else if (_arguments[i] == typeid(bool))
		{
			bool b = va_arg!(bool)(_argptr);
			if (b)
			{
				write_string(x, y, "True");
			}
			else
			{
				write_string(x, y, "False");
			}
		}
		else if (_arguments[i] == typeid(char))
		{
			put_char(x, y, va_arg!(char)(_argptr));
		}
	}
//	*/
}

private
void write_string(ref int x, ref int y, string message)
{
	foreach(character; message)
	{
		put_char(x, y, cast(byte)character);
		increment_col(x, y);
	}
}
