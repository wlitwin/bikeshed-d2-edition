module kernel.memory.iVirtualAllocator;

import kernel.memory.iPhysicalAllocator;

alias uint virt_addr;

interface IVirtualAllocator
{
	void initialize(IPhysicalAllocator phys_allocator);
}
