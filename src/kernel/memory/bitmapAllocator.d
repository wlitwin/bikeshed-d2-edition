module kernel.memory.bitmapAllocator;

import kernel.serial;
import kernel.support;

import kernel.memory.memory;
import kernel.memory.iPhysicalAllocator;

__gshared:

class BitmapAllocator : IPhysicalAllocator
{
	private uint m_bitmapSize;
	private uint* m_bitmap;
	private uint last_index;

	private uint phys_to_index(phys_addr address)
	{
		return address / PAGE_SIZE / 32;
	}

	private uint phys_to_offset(phys_addr address)
	{
		return (address / PAGE_SIZE) % 32;
	}

	void initialize(ref MemoryInfo info)
	{
		serial_outln("\nBitmap Allocator: Initializing");

		last_index = 0;

		// Figure out how large the bitmap needs to
		// be based on the total amount of memory available
		m_bitmapSize = (info.memory_total / PAGE_SIZE) / 32;	

		// Align it to the nearest 4-byte boundary
		m_bitmap = cast(uint*) ((info.kernel_end + 0x4) & 0xFFFFFFF8);

		// For now mark up to the bitmaps end as used
		phys_addr end_of_bitmap = (cast(uint)m_bitmap) + 
									m_bitmapSize * uint.sizeof;
		// TODO - Set the individual bits instead of adding +1
		uint end_index = phys_to_index(end_of_bitmap) + 1;
		serial_outln("\tEnd Index: ", end_index);
		serial_outln("\tEnd Address: ", end_of_bitmap);
		for (int i = 0; i < end_index; ++i)
		{
			m_bitmap[i] = 0xFFFFFFFF;
		}

		serial_outln("\tBitmap size: ", m_bitmapSize);
		serial_outln("\tBitmap location: ", cast(uint) m_bitmap);
		serial_outln("Bitmap Allocator: Finished\n");
	}

	phys_addr allocate_page()
	{
		uint i = last_index;
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
			serial_outln("Bitmap Allocator: No more memory!");
			panic();
		}

		// Okay find the free bit
		uint the_bit = 0x1, offset = 0;
		while ((m_bitmap[i] & the_bit) != 0 && the_bit != 0)
		{
			the_bit <<= 1;
			++offset;
		}

		if (offset >= 32)
		{
			serial_outln("Bitmap Allocator: Error finding free page!");
			panic();
		}

		m_bitmap[i] |= the_bit;


		phys_addr address = i * PAGE_SIZE * 32;
		serial_outln("Bitmap Allocator: Giving out page ", address);
		last_index = i;
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

}
