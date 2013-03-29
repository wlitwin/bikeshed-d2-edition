module kernel.memory.physical.types;

__gshared:
nothrow:
public:

// One of the structures contains information about a usable segment
// of memory that the computer has. An array of these forms all of
// the usable memory the system has to offer. The reason this is needed
// is the system may have memory 'holes' or regions that aren't usable.
struct MemoryMap
{
	align(1)
	uint base_address; // The start address of the memory segment
	uint length;       // The length of the memory segment in bytes
}

// This structure is filled in by the physical memory manager implementation.
// It converts any hardware specific memory information into this generalized
// structure.
struct Memory
{
	uint total_memory; // The total memory of the system in bytes
	uint kernel_start; // The address of the start of the kernel
	uint kernel_end;   // The address of the end of the kernel
	uint mmap_count;   // The number of entries in the memory map array
	const(MemoryMap)* mmap; // A pointer to the memory map array
}
