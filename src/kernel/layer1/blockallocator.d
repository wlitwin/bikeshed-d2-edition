module kernel.layer1.blockallocator;

import virtAllocator = kernel.layer0.memory.iVirtualAllocator;
import kernel.layer0.memory.iVirtualAllocator : virt_addr, PG_READ_WRITE, PG_PRESENT;
import kernel.layer0.memory.memory : PAGE_SIZE;

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
	T* end_address;
	T* free_ptr_head;
	T* free_ptr_tail;
	uint free_amt;
	uint max_free;

public:

	static BlockAllocator!(T)* create_allocator(T* start, T* end)
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
		ba.end_address = end;
		ba.free_ptr_head = ba.start_address;
		ba.free_amt = (cast(uint)ba.end_address - cast(uint)ba.start_address) / T.sizeof;
		ba.max_free = ba.free_amt;

		ba.setup_free_list();

		return ba;
	}

	private void setup_free_list()
	{
		T* node = free_ptr_head;
		for (int i = 0; i < free_amt; ++i)
		{
			*(cast(T**)node) = node + 1; 
			++node;
		}
		free_ptr_tail = node-1;
		*(cast(T**)free_ptr_tail) = cast(T*)0x0;
	}

	// TODO - What to do when we reach 0 free blocks
	T* alloc()
	{
		if (free_amt == 0)
		{
			return null;
		}

		T* node = free_ptr_head;
		free_ptr_head = *(cast(T**)free_ptr_head);

		if (free_ptr_head == cast(T*)0x0)
		{
			assert(false, "Block allocator: " ~ T.stringof ~ " allocate problem");
		}

		--free_amt;

		return node;
	}

	// TODO - What to do when we reach 0 free blocks
	void free(T* ptr)
	{
		if (ptr < start_address ||
			ptr > end_address ||
			free_amt == max_free)
		{
			return;
		}

		*(cast(T**)free_ptr_tail) = ptr;
		free_ptr_tail = ptr;
		*(cast(T**)free_ptr_tail) = cast(T*)0x0;

		++free_amt;
	}
}
