module kernel.memory.memory;

import kernel.memory.emplace;

import kernel.serial;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.iVirtualAllocator;
import kernel.memory.bitmapAllocator;
import kernel.memory.basicVirtualAllocator;

__gshared:
// These are linker symbols,
// To get the address of the end of the kernel, take
// the address of KERNEL_END.
// Similarly to get the address of the start of the
// kernel take the address of KERNEL_START.
// TODO - virtual or physical addresses?
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
IVirtualAllocator  g_virtualAllocator  = void;

private
{
	// The global memory information struct.
	// Constains information about how much
	// memory the current machine has available.
	MemoryInfo g_memoryInfo = void;

	BitmapAllocator ba;
	BasicVirtualAllocator va;	

	// Allocate some space for the physical allocator
	void _phys_allocator_space[__traits(classInstanceSize, typeof(ba))] = void;
	// Allocator space for the virtual allocator
	void _virt_allocator_space[__traits(classInstanceSize, typeof(va))] = void;
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

	// Reserve addresses in the physical allocator so they're not
	// given out as addresses
//	g_physicalAllocator.reserve_range(0x0, 0x100000);

	// Place the virtual allocator in the correct spot
	va = emplace!BasicVirtualAllocator(_virt_allocator_space[]);
	g_virtualAllocator = va;

	// Initialize the physical allocator
	g_physicalAllocator.initialize(g_memoryInfo);

	// Initialize the virtual allocator
	g_virtualAllocator.initialize(g_physicalAllocator, g_memoryInfo);

	// Print some debug information
	serial_outln("\tMemory Size: ", memory_total);
	serial_outln("\tMemory Low : ", memory_low);
	serial_outln("\tMemory Hi  : ", memory_hi);
	serial_outln("\tStart of kernel: ", g_memoryInfo.kernel_start);
	serial_outln("\tEnd of kernel: ", g_memoryInfo.kernel_end);
	serial_outln("Memory: Finished\n");
}

