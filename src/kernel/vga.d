module kernel.vga;

void put_char(int x, int y, byte c) nothrow
{
	ushort* video = cast(ushort *) 0xB8000 + (y*80 + x);

	*video = (0x70 << 8) | c;
}

void put_string(int x, int y, string message) nothrow
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
