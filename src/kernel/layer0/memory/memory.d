module kernel.layer0.memory.memory;

import kernel.layer0.serial;
import kernel.layer0.memory.malloc;
import kernel.layer0.memory.emplace;
import physAllocator = kernel.layer0.memory.iPhysicalAllocator;
import virtAllocator = kernel.layer0.memory.iVirtualAllocator;

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

// The global memory information struct.
// Constains information about how much
// memory the current machine has available.
MemoryInfo g_memoryInfo = void;

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

	//============================================================================
	// Initialize the physical allocator
	//============================================================================
	physAllocator.initialize(g_memoryInfo);

	// Reserve addresses in the physical allocator so they're not
	// given out as addresses
	physAllocator.reserve_range(0x0, 0x200000);

	//============================================================================
	// End of physical allocator initialization
	//============================================================================

	//============================================================================
	// Initialize the virtual allocator
	//============================================================================

	virtAllocator.initialize(g_memoryInfo);

	//============================================================================
	// End of virtual allocator initialization
	//============================================================================

	// Setup the kernel's heap
	malloc_initialize();

	// Print some debug information
	serial_outln("\tMemory Size: ", memory_total);
	serial_outln("\tMemory Low : ", memory_low);
	serial_outln("\tMemory Hi  : ", memory_hi);
	serial_outln("\tStart of kernel: ", g_memoryInfo.kernel_start);
	serial_outln("\tEnd of kernel: ", g_memoryInfo.kernel_end);
	serial_outln("Memory: Finished\n");
}

