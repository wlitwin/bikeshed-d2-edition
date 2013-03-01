__gshared:
nothrow:

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

void put_char(int x, int y, byte c) nothrow
{
	video[x + y*80].color = 0x9;
	video[x + y*80].c = c;
}

void main()
{
	video[0].color = 0x9;

	while (true)
	{
		for (int y = 0; y < 25; ++y)
		{
			for (int x = 0; x < 80; ++x)
			{
				put_char(x, y, rand() % 26 + 'A');
			}
		}
		asm { hlt; }
	}
}
