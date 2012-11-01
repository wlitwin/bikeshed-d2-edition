module kernel.memory.basicVirtualAllocator;

import kernel.serial;
import kernel.memory.util : memclr;
import kernel.memory.memory;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.iVirtualAllocator;

struct PageDirectory
{
	phys_addr tables[1024];
}

class BasicVirtualAllocator : IVirtualAllocator
{
	private IPhysicalAllocator m_physAllocator;
	private PageDirectory* m_kernelTable;

	void initialize(IPhysicalAllocator phys_allocator, ref MemoryInfo info)
	{
		serial_outln("BVA: Initializing");
		m_physAllocator = phys_allocator;

		enable_paging(info);
		serial_outln("BVA: Finished");
	}

	void identity_map(virt_addr low, virt_addr hi)
	{

	}

	void enable_paging(ref MemoryInfo info)
	{
		m_kernelTable = cast(PageDirectory *) m_physAllocator.allocate_page();	

		memclr(m_kernelTable, PageDirectory.sizeof);
		// Identity map the first megabyte
		identity_map(0x0, 0x100000);

		// Identity map the kernel
		identity_map(info.kernel_start, info.kernel_end);
	}
}
