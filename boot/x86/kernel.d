extern (C) void kmain()
{
	put_string(0, 0, message);	
	char[] s = new char[12];
	asm { hlt; }
}

void put_char(int x, int y, byte c)
{
	ushort* video = cast(ushort *) 0xB8000 + (y*80 + x);

	*video = (0x70 << 8) | c;
}

void put_string(int x, int y, string message)
{
	foreach(character; message)
	{
		put_char(x, y, cast(byte)character);

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
}

string message = "Hello World! From the D2 Programming language!";
