module kernel.layer1.blockallocator;

import virtAllocator = kernel.layer0.memory.iVirtualAllocator;
import kernel.layer0.memory.iVirtualAllocator : virt_addr, PG_READ_WRITE, PG_PRESENT;
import kernel.layer0.memory.memory : PAGE_SIZE;
import kernel.layer0.serial;
import kernel.layer0.support : panic;

__gshared:
nothrow:

// Provides a fast allocator
// for fixed-size blocks of
// memory. Used by things like
// PCB allocation where there's
// a fixed number of them.
struct BlockAllocator(T)
{
nothrow:
private:
	T* start_address;
	int free_index;
	int alloc_index;
	uint length;

public:

	static BlockAllocator!(T)* create_allocator(const T* start, const T* end)
	{
		if (start > end || (cast(uint)end-cast(uint)start) < (BlockAllocator!(T).sizeof + T.sizeof))
		{
			assert(false, "Bad allocator parameters");
		}

		virt_addr va_addr = cast(virt_addr)start;
		virt_addr va_end  = cast(virt_addr)end;
		while (va_addr < va_end)
		{
			virtAllocator.map_page(va_addr, PG_READ_WRITE | PG_PRESENT);
			va_addr += PAGE_SIZE;
		}


		BlockAllocator!(T)* ba = cast(BlockAllocator!(T)*) start;
		ba.start_address = cast(T*)(cast(uint)start + BlockAllocator!(T).sizeof);
		ba.length = (end - ba.start_address);
		ba.alloc_index = 0;
		ba.free_index = ba.length-1;

		serial_outln("Creating block allocator of type: " ~ T.stringof);
		serial_outln("Start: ", cast(uint)start, " End: ", cast(uint)end);
		serial_outln("Block Allocator size: ", BlockAllocator!(T).sizeof);
		serial_outln("Size of type: ", T.sizeof);
		serial_outln("New start address: ", cast(uint)ba.start_address);
		serial_outln("Length: ", ba.length);
		serial_outln("Alloc index: ", ba.alloc_index);
		serial_outln("Free index: ", ba.free_index);

		ba.setupFreeList();

		return ba;
	}

	private int toIndex(const T* address) const
	{
		int index = address - start_address;

		if (index < 0 || index >= length) return -1;

		return index;
	}
	
	private T* toAddress(const int index)
	{
		return &(start_address[index]);
	}

	private void setupFreeList()
	{
		// Make every block point to the next block, and the last
		// block contain -1 as the 'End of List' marker
		for (int i = 0; i < length-1; ++i)
		{
			*(cast(int*)(&start_address[i])) = i+1;
		}

		*(cast(int*)(&start_address[length-1])) = -1; // End of list marker
	}

	T* alloc()
	{
		// The last allocation was the last block
		if (alloc_index == -1) panic("Block Allocator (" ~ T.stringof ~ "): No more free blocks");

		// Grab the current block and set the next free block
		T* block = toAddress(alloc_index);
		alloc_index = *(cast(int*)(&start_address[alloc_index]));

		return block;
	}

	void free(const T* ptr)
	{
		const int index = toIndex(ptr);
		if (index < 0) panic("Block Allocator (" ~ T.stringof ~ "): Freeing invalid address");

		// Make sure the current free pointer is correct
		int* old_free = cast(int*)(&start_address[free_index]);
		if (*old_free != -1) panic("Block Allocator (" ~ T.stringof ~ "): Free list corrupted");

		// Move the free pointer
		*old_free = index;
		free_index = index;

		// Fix the current free index
		*(cast(int*)(&start_address[index])) = -1;
	}
}
