module kernel.memory.basicVirtualAllocator;

import kernel.serial;
import kernel.memory.util : memclr;
import kernel.memory.memory;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.iVirtualAllocator;

enum PG_PRESENT = 0x1;
enum PG_READ_WRITE = 0x2;
enum PG_USER = 0x4;
enum PG_WRITE_THRU = 0x8;
enum PG_CACHE_DISABLE = 0x10;

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

	private uint addr_to_pd_index(virt_addr address)
	{
		return address >> 22;	
	}

	private uint addr_to_pt_index(virt_addr address)
	{
		return (address >> 12) & 0x03FF;
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
