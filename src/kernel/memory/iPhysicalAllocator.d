module kernel.memory.iPhysicalAllocator;

import kernel.serial;
import kernel.support;
import kernel.memory.memory;

alias uint phys_addr;

interface IPhysicalAllocator
{
	// Do whatever is needed to initialize
	// the physical memory manager
	void initialize(ref MemoryInfo info);

	void reserve_page(phys_addr address);

	void reserve_range(phys_addr from, phys_addr to);

	// Allocate a new physical page
	phys_addr allocate_page();

	// Free a physical page
	void free_page(phys_addr address);
}
