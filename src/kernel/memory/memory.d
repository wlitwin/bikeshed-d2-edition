module kernel.memory;

import kernel.serial;
import kernel.memory.iPhysicalAllocator;

__gshared:
// This is a linker symbol, it's address is the end of the kernel
extern(C) int end;

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
// memory this machine has available.
MemoryInfo g_memoryInfo = void;

IPhysicalAllocator g_physicalAllocator = void;

void
init_memory()
{
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
	g_memoryInfo.kernel_start = KERNEL_START;
	g_memoryInfo.kernel_end = cast(uint)&end;

	// Initialize the physical allocator

	// Print some debug information
	serial_outln("Memory Size: ", PHYSICAL_MEMORY_SIZE);
	serial_outln("Memory Low : ", memory_low);
	serial_outln("Memory Hi  : ", memory_hi);

	serial_outln("End of kernel: ", cast(int)&end);
}

