module kernel.layer0.memory.iPhysicalAllocator;

import kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.memory.memory;
import kernel.layer0.memory.iVirtualAllocator : identity_map;

private import bitmap = kernel.layer0.memory.bitmapAllocator;

// Interface for the phyiscal memory manager

__gshared:
nothrow:
public:

alias uint phys_addr;

void
initialize(ref MemoryInfo info)
{
	// Scan the memory map for some free memory
	// above the 1MiB line that's large enough
	// for the bitmap
	uint bitmap_size = info.max_mem_address / PAGE_SIZE / 32;

	bool initialized = false;
	const(MemoryMap)* mmap = info.mmap;
	for (int i = 0; i < info.mmap_count; ++i, ++mmap)
	{
		if (mmap.start > 0x100000 && mmap.length > bitmap_size)
		{
			// Found it!
			initialized = true;
			bitmap.initialize(cast(uint*) mmap.start, info.max_mem_address);
		}
	}

	if (!initialized)
	{
		panic("PHYS MM: Couldn't initialize");
	}

	// Loop through and free all the usable regions
	mmap = info.mmap;
	for (int i = 0; i < info.mmap_count; ++i, ++mmap)
	{
		// Bitmap won't free it's own storage
		bitmap.free_range(mmap.start, mmap.start+mmap.length);
	}
}

void
map_initial_allocator_pages()
{
	uint bitmap_start = cast(uint) bitmap.get_bitmap_location();	
	uint bitmap_end   = bitmap_start + bitmap.get_bitmap_size();

	identity_map(bitmap_start, bitmap_end);
}

phys_addr
allocate_page()
{
	return bitmap.allocate_page();
}

phys_addr
allocate_pages(int num_blocks)
{
	return bitmap.allocate_pages(num_blocks);
}

void
reserve_region(uint start, uint length)
{
	bitmap.reserve_range(start, start+length);
}

/*
void
unreserve_region(uint start, uint length)
{
}
*/

void
free_page(phys_addr ptr)
{
	bitmap.free_page(ptr);
}

