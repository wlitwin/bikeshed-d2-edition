module kernel.memory.memory;

import kernel.memory.emplace;

import kernel.serial;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.bitmapAllocator;

__gshared:
// This is a linker symbol, it's address is the end of the kernel
extern(C) int KERNEL_END;
extern(C) int KERNEL_START;

enum PAGE_SIZE = 4096;

// Gathers a bunch of information
// about the machines memory layout
// and size in one location
struct MemoryInfo
{
	uint memory_low;
	uint memory_high;
	uint memory_total;
	uint kernel_start;
	uint kernel_end;
}

IPhysicalAllocator g_physicalAllocator = void;

private
{
	// The global memory information struct.
	// Constains information about how much
	// memory this machine has available.
	MemoryInfo g_memoryInfo = void;

	BitmapAllocator ba;

	// Allocate some space for the bitmap allocator
	void _phys_allocator_space[__traits(classInstanceSize, typeof(ba))] = void;
}

void
init_memory()
{
	serial_outln("\nMemory: Initializing");
	// Some useful constants
	// The memory addresses are defined in bootloader.S
	enum MMAP_ADDRESS = 0x2D00;
	enum MMAP_EXT_LO  = 0x00;
	enum MMAP_EXT_HI  = 0x02;
	enum MMAP_CFG_LO  = 0x04;
	enum MMAP_CFG_HI  = 0x06;
	enum ONE_MEGABYTE = 1024 * 1024;

	// Check how much memory is available	
	uint memory_low = *(cast(ushort*) (MMAP_ADDRESS + MMAP_EXT_LO)) * 1024;
	uint memory_hi  = *(cast(ushort*) (MMAP_ADDRESS + MMAP_EXT_HI)) * 64 * 1024;
	uint memory_total = ONE_MEGABYTE + memory_low + memory_hi;	

	// Fill the memory information struct
	g_memoryInfo.memory_low = memory_low;
	g_memoryInfo.memory_high = memory_hi;
	g_memoryInfo.memory_total = memory_total;
	g_memoryInfo.kernel_start = cast(uint)&KERNEL_START;
	g_memoryInfo.kernel_end = cast(uint)&KERNEL_END;

	// Place the physical allocator in the correct spot
	ba = emplace!BitmapAllocator(_phys_allocator_space[]);
	g_physicalAllocator = ba;

	// Initialize the physical allocator
	g_physicalAllocator.initialize(g_memoryInfo);

	// Try to allocate something from the physical allocator
	phys_addr address = g_physicalAllocator.allocate_page();
	serial_outln("Allocated: ", address);
	g_physicalAllocator.free_page(address);
	address = g_physicalAllocator.allocate_page();
	serial_outln("Allocated: ", address);

	// Print some debug information
	serial_outln("\tMemory Size: ", memory_total);
	serial_outln("\tMemory Low : ", memory_low);
	serial_outln("\tMemory Hi  : ", memory_hi);
	serial_outln("\tEnd of kernel: ", g_memoryInfo.kernel_end);
	serial_outln("Memory: Finished\n");
}

