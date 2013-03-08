module kernel.layer0.memory.memory;

import kernel.layer0.serial;
import kernel.layer0.memory.emplace;
import kernel.layer0.memory.mmap_list;
public import kernel.layer0.memory.mmap_list : MemoryMap;

import physAllocator = kernel.layer0.memory.iPhysicalAllocator;
import virtAllocator = kernel.layer0.memory.iVirtualAllocator;

__gshared:
nothrow:
// These are linker symbols,
// To get the address of the end of the kernel, take
// the address of KERNEL_END.
// Similarly to get the address of the start of the
// kernel take the address of KERNEL_START.
// TODO - virtual or physical addresses?
private extern(C) int KERNEL_END;   // Assumed to be aligned to 4-byte boundary
private extern(C) int KERNEL_START;

enum PAGE_SIZE = 4096;

// Bottom of the stack
enum STACK_MAX_LOC = 0x200000;
// Top of the stack
enum STACK_MIN_LOC = 0x100000;

// Gathers a bunch of information
// about the machines memory layout
// and size in one location
struct MemoryInfo
{
	uint total_usable_memory;
	uint max_mem_address;
	uint kernel_start;
	uint kernel_end;
	uint mmap_count;
	const(MemoryMap)* mmap;
}

// The global memory information struct.
// Contains information about how much
// memory the current machine has available.
MemoryInfo g_memoryInfo = void;

align(1) /* Means pack the values */
struct SMAPEntry
{
	uint baseL;
	uint baseH;
	uint lengthL;
	uint lengthH;
	ushort type;
	uint ACPI;
}

void
detect_memory()
{
	assert(SMAPEntry.sizeof == 24);

	// The BIOS uses the 0xE820 call to get a pretty good
	// memory map of the system. It stores an array of and
	// count of the SMAP structs at the below addresses.
	enum SMAP_COUNT   = 0x2D00;
	enum SMAP_ADDRESS = 0x2D04;

	int count = *(cast(int *)SMAP_COUNT);
	if (count < 0)
	{
		panic("Failed to get memory map");
	}

	// Need to go through and cleanup what's been given by
	// the BIOS. Sometimes the regions overlap or need to
	// be merged together.
	initialize_mmap_list();

	SMAPEntry* entry = cast(SMAPEntry*) SMAP_ADDRESS;
	for (int i = 0; i < count; ++i, ++entry)
	{
		if (entry.type == 0x1) // Available memory
		{
			const uint bh = entry.baseH;
			const uint bl = entry.baseL;
			const uint lh = entry.lengthH;
			const uint ll = entry.lengthL;

			uint start  = cast(uint) ((cast(ulong)bh << 32) | bl);
			uint length = cast(uint) ((cast(ulong)lh << 32) | ll);

			add_usable_region(start, length);
		}
	}

	// Reserve regions the kernel uses
	// We'll need to do something special later for
	// reserving the lower memory addresses, in order
	// to use things like DMA and other cool features
	print_mmap_list();
	print_mmap_list();
	/*reserve_region(0x000, 0x2500 + 256*4 - 0x000); // GDT + IDT
	reserve_region(0x7C00, 1536); // Bootloader
	reserve_region(0x2D00, SMAPEntry.sizeof*count); // SMAP entries
	*/

	// Loop through all the entries
	g_memoryInfo.kernel_start = cast(uint) &KERNEL_START;
	// The memory map starts at the current end of the kernel
	g_memoryInfo.kernel_end = cast(uint) (get_mmap_start() + get_mmap_count());

	reserve_region(0x0, 0x100000);
	reserve_region(STACK_MIN_LOC, STACK_MAX_LOC - STACK_MIN_LOC);
	reserve_region(g_memoryInfo.kernel_start, g_memoryInfo.kernel_end - g_memoryInfo.kernel_start);

	// These might have changed because we're reserving addresses
	g_memoryInfo.mmap_count = get_mmap_count();
	g_memoryInfo.mmap = get_mmap_start();

	// Loop through and find the total amount of memory
	const(MemoryMap)* mm = g_memoryInfo.mmap;
	g_memoryInfo.total_usable_memory = 0;
	g_memoryInfo.max_mem_address = 0;
	for (int i = 0; i < g_memoryInfo.mmap_count; ++i, ++mm)
	{
		g_memoryInfo.total_usable_memory += mm.length;	

		if (mm.start + mm.length > g_memoryInfo.max_mem_address)
		{
			g_memoryInfo.max_mem_address = mm.start + mm.length;
		}
	}

	// Print some debug info
	serial_outln("Memory information");
	serial_outln("Kernel start: ", g_memoryInfo.kernel_start);
	serial_outln("Kernel end:   ", g_memoryInfo.kernel_end, " (Orig: ", (cast(uint)&KERNEL_END), ")");
	serial_outln("Total memory: ", g_memoryInfo.total_usable_memory);
	serial_outln("Max mem addr: ", g_memoryInfo.max_mem_address);
	serial_outln("Mmap count:   ", g_memoryInfo.mmap_count);

	print_mmap_list();

	serial_outln("\nSMAP:");
	entry = cast(SMAPEntry*) SMAP_ADDRESS;
	for (int i = 0; i < count; ++i)
	{
		uint start = cast(uint)((cast(ulong)entry.baseH << 32) | entry.baseL);
		uint length = cast(uint)((cast(ulong)entry.lengthH << 32) | entry.lengthL);

		serial_outln("S: ", start, " L: ", length, " T: ", entry.type, " A: ", entry.ACPI);
		++entry;
	}
}

// Called by the virtual allocator, because it
// doesn't know about what needs to be mapped
void
setup_initial_pages()
{
	// Identity map the lower 1MiB
	virtAllocator.identity_map(0x0, 0x100000);
	// Identity map the kernel for now
	virtAllocator.identity_map(g_memoryInfo.kernel_start, g_memoryInfo.kernel_end);
	// Identity map the kernel's stack
	virtAllocator.identity_map(STACK_MIN_LOC, STACK_MAX_LOC);
	// Ask the physical manager to map some pages
	physAllocator.map_initial_allocator_pages();
}

void
init_memory()
{
	serial_outln("\nMemory: Initializing");

	detect_memory();

	//============================================================================
	// Initialize the physical allocator
	//============================================================================
	physAllocator.initialize(g_memoryInfo);

	// Reserve addresses in the physical allocator so they're not
	// given out as addresses
	//physAllocator.reserve_range(0x0, 0x200000);

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
}

