__gshared:
nothrow:

import bikeshedlib.stdlib;

enum video_address = 0xB8000;

void main()
{
	int counter = 0;
	uint _pid = cast(uint)get_pid();
	//while (true)
	{
		printNum(counter++, 70+_pid, 0);
		msleep(100);
	//	asm { hlt; }
	}
}

VideoCell* video = cast(VideoCell*) video_address;

struct VideoCell
{
	ubyte c;
	ubyte color;
}

void put_char(int x, int y, byte c)
{
	video[x + y*80].color = 0x9;
	video[x + y*80].c = c;
}

void put_string(string s, int x, int y)
{
	foreach (c ; s)
	{
		put_char(x++, y, c);
	}
}

int printNum(uint number, int x, int y)
{
	if (number == 0)
	{
		put_char(x, y, '0');
		return x;
	}

	int pos = printNum(number/10, x, y);

	put_char(pos, y, '0' + (number % 10));

	return pos+1;	
}	
