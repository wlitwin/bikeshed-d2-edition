module arch.x86.memory.physical.impl;

// This module needs to convert SMAPEntry's to MemoryMap structures
import kernel.memory.physical.types : MemoryMap;

// This is the structure that needs to be filled in by the init()
// method
import kernel.memory.physical.types : Memory;

import arch.x86.memory.physical.manager;

__gshared:
nothrow:
public:

void init(ref Memory memInfo)
{
	// This is here to verify that the SMAPEntry structure size
	// matches that of what the BIOS puts in memory for us.
	static assert(SMAPEntry.sizeof == 24);	

	// Okay find some space for the new MemoryMap structures. For
	// now assume that the end of the kernel is fine and align it
	// to a 4-byte boundary.
	// TODO/Improvement - Make sure it's a valid place to put it.
	//MemoryMap* mmap = cast(MemoryMap*) ((&KERNEL_END) & 0xFFFFFF8) + 0x4;
	//uint mmap_count = 0;
	
	// We need a spot to place the physical memory manager. It needs
	// 4KiB of space for managing 4MiB blocks of memory.
	SMAPEntry* mmapStart = cast(SMAPEntry*)SMAP_START_ADDRESS;
	uint* count = cast(uint*) SMAP_COUNT_ADDRESS;
	PhysicalManager pm = PhysicalManager(mmapStart, *count);
}

package:

// This is the symbol that marks the start of the kernel's code.
// To use it you take its address, as in &KERNEL_START, this
// will give the address of the start of the kernel's code.
extern (C) int KERNEL_START;

// This is the symbol that marks the end of the kernel's code.
// To use it you take its address, as in &KERNEL_END, this
// will give the address of the end of the kernel's code.
extern (C) int KERNEL_END;

// This is the location that stores the size of the SMAPEntry
// array that the BIOS gives us. It's 4-bytes.
enum SMAP_COUNT_ADDRESS = 0x2D00;

// This is the location of the first SMAPEntry. The value in
// the location above is the number of contiguous SMAPEntry
// structures starting at this location.
enum SMAP_START_ADDRESS = 0x2D04;

/* This structure comes from the BIOS 0xE820 memory map call.
 * The following is what the BIOS puts in memory for us. We're
 * going to turn it into a more friendly format to work with,
 * to make it easier to see how much memory the system has to
 * offer.
 */
struct SMAPEntry
{
nothrow:
	align(1)
	uint baseL;
	uint baseH;
	uint lengthL;
	uint lengthH;
	ushort type;
	uint ACPI;

	uint base() @property
	{
		return cast(uint)((cast(ulong)baseH << 32) | baseL);
	}
	
	uint length() @property
	{
		return cast(uint)((cast(ulong)lengthH << 32) | lengthL);
	}
}

