module kernel.memory.bitmapAllocator;

import kernel.memory.memory;
import kernel.memory.iPhysicalAllocator;

class BitmapAllocator : IPhysicalAllocator
{
	void initialize(ref MemoryInfo info)
	{

	}

	phys_addr allocate_page()
	{
		return 42;
	}

	void free_page(phys_addr address)
	{

	}
}
