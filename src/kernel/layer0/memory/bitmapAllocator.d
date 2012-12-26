module kernel.layer0.memory.bitmapAllocator;

private import kernel.layer0.serial;
private import kernel.layer0.support : panic;
private import kernel.layer0.memory.iPhysicalAllocator;
private import kernel.layer0.memory.memory : PAGE_SIZE;
private import kernel.layer0.memory.util;

__gshared:
nothrow:
public:

private uint m_bitmapSize;
private uint* m_bitmap;
private uint m_last_index;

private uint phys_to_index(phys_addr address)
{
	return cast(uint)address / PAGE_SIZE / 32;
}

private uint phys_to_offset(phys_addr address)
{
	return (cast(uint)address / PAGE_SIZE) % 32;
}

void initialize(uint* bitmap_loc, uint mem_size)
{
	serial_outln("\nBitmap Allocator: Initializing");

	m_bitmap = bitmap_loc;
	// Bitmap size in uint's
	m_bitmapSize = mem_size / PAGE_SIZE / 32;
	// Used to speed up allocations
	m_last_index = 0;

	// Mark the entire bitmap as used
	memset(m_bitmap, 0xFF, m_bitmapSize*uint.sizeof);

	serial_outln("\tBitmap size: ", m_bitmapSize);
	serial_outln("\tBitmap location: ", cast(uint) m_bitmap);
	serial_outln("Bitmap Allocator: Finished\n");
}

void reserve_page(phys_addr address)
{
	uint index = phys_to_index(address);
	if (index >= m_bitmapSize)
		return;

	uint offset = phys_to_offset(address);
	m_bitmap[index] |= (1 << offset);
}

void reserve_range(phys_addr from, phys_addr to)
{
	serial_outln("Bitmap Allocator: Reserving range ", cast(uint)from, " - ", cast(uint)to);
	if (from > to)
	{
		panic("Bitmap Allocator: From address is greater than To address");
	}

	while (from <= to)
	{
		reserve_page(from);
		from += PAGE_SIZE;
	}
}

void free_range(phys_addr from, phys_addr to)
{
	serial_outln("Bitmap Allocator: Freeing range ", cast(uint)from, " - ", cast(uint)to);

	// Don't let our bitmap get overwritten
	uint bitmap_addr = cast(uint) m_bitmap;
	uint bitmap_end  = bitmap_addr + m_bitmapSize;

	if (to > bitmap_addr && to <= bitmap_end)
	{
		to = bitmap_addr-4;
	}

	if (from >= bitmap_addr && from < bitmap_end)
	{
		from = bitmap_end+4;
	}

	if (from >= to ||
			(from <= bitmap_addr && to >= bitmap_end))
	{ 
		return; 
	}

	serial_outln("Bitmap Allocator: Adjusted range ", cast(uint)from, " - ", cast(uint)to);

	while (from <= to)
	{
		//free_page(from);
		uint index = phys_to_index(from);
		if (index >= m_bitmapSize)
			return;
		uint offset = phys_to_offset(from);
		m_bitmap[index] &= ~(1 << offset);
		from += PAGE_SIZE;
	}
}

// Allocate continuous pages
phys_addr allocate_pages(int num_pages)
{
	panic("Bitmap: Allocate pages not implemented!");
	return 0;
}

phys_addr allocate_page()
{
	uint i = m_last_index;
	uint start = i;
	while (m_bitmap[i] == 0xFFFFFFFF)
	{
		i = (i + 1) % m_bitmapSize;
		if (i == start)
			break;
	}

	if (m_bitmap[i] == 0xFFFFFFFF)
	{
		// Uh-oh no more memory!
		panic("Bitmap Allocator: No more memory!");
	}

	// Okay find the free bit
	uint the_bit = 0x1, offset = 0;
	while ((m_bitmap[i] & the_bit) != 0 && the_bit != 0)
	{
		the_bit <<= 1;
		++offset;
	}

	// Check if something weird happend
	if (offset >= 32 || the_bit == 0)
	{
		panic("Bitmap Allocator: Error finding free page!");
	}

	m_bitmap[i] |= the_bit;

	phys_addr address = (i * PAGE_SIZE * 32) + (offset * PAGE_SIZE);
	serial_outln("Bitmap Allocator: Giving out page ", address);
	m_last_index = i;
	return address;
}

void free_page(phys_addr address)
{
	uint index = phys_to_index(address);
	if (index >= m_bitmapSize)
		return;

	serial_outln("Bitmap Allocator: Freeing page ", address);
	uint offset = phys_to_offset(address);
	m_bitmap[index] &= ~(1 << offset);
}

