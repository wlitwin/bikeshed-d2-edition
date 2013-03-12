__gshared:
nothrow:

import bikeshedlib.stdlib;

enum video_address = 0xB8000;

VideoCell* video = cast(VideoCell*) video_address;

struct VideoCell
{
	ubyte c;
	ubyte color;
}

uint m_z = 0x12345678;
uint m_w = 0xC001C0DE;
uint
rand()
{
	m_z = 36969 * (m_z & 65535) + (m_z >> 16);
	m_w = 18000 * (m_w & 65535) + (m_w >> 16);

	return (m_z << 16) + m_w;
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

void main()
{
	uint priority = get_priority();
	uint proc_id = get_pid();

	video[0].color = 0x9;

	set_time(500000);

	printNum(proc_id, 79, 0);

	Pid pid;
	if (fork(&pid) != Status.SUCCESS)
	{
		put_string("Fork Failed", 0, 0);
		while (true) asm {hlt;}
	}

	if (pid == 0)
	{
		set_priority(Priority.HIGH);
		exec("/test1");
	}

	while (true)
	{
		for (int y = 1; y < 25; ++y)
		{
			for (int x = 0; x < 80; ++x)
			{
				put_char(x, y, rand() % 26 + 'A');
			}
		}
		// Print the number in the top right
		printNum(priority, 0, 0);
		// Get the time
		uint time = get_time();
		printNum(time, 10, 0);
		asm { hlt; }
	}
}
