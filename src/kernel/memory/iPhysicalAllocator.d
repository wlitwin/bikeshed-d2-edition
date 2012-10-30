module kernel.memory.iPhysicalAllocator;

import kernel.memory.memory;

alias uint phys_addr;

interface IPhysicalAllocator
{
	// Do whatever is needed to initialize
	// the physical memory manager
	void initialize(ref MemoryInfo info);

	// Allocate a new physical page
	phys_addr allocate_page();

	// Free a physical page
	void free_page(phys_addr address);
}
