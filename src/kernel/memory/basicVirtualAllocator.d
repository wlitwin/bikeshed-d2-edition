module kernel.memory.basicVirtualAllocator;

import kernel.serial;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.iVirtualAllocator;

class BasicVirtualAllocator : IVirtualAllocator
{
	private IPhysicalAllocator m_physAllocator;

	void initialize(IPhysicalAllocator phys_allocator)
	{
		serial_outln("BVA: Initializing");
		m_physAllocator = phys_allocator;
		serial_outln("BVA: Finished");
	}
}
