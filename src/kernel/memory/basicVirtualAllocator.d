module kernel.memory.basicVirtualAllocator;

import kernel.serial;
import kernel.memory.util : memclr;
import kernel.memory.memory;
import kernel.interrupts;
import kernel.support;
import kernel.memory.iPhysicalAllocator;
import kernel.memory.iVirtualAllocator;

__gshared:
nothrow:

enum PG_PRESENT = 0x1;
enum PG_READ_WRITE = 0x2;
enum PG_USER = 0x4;
enum PG_WRITE_THRU = 0x8;
enum PG_CACHE_DISABLE = 0x10;

struct PageTable
{
	virt_addr addrs[1024];
}

struct PageDirectory
{
	union
	{
		phys_addr tables[1024];
		PageTable* ptables[1024];
	}

	PageTable* get_page_table(uint index) const nothrow
	{
		return cast(PageTable *) (tables[index] & 0xFFFFF000);
	}
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

	void identity_map(PageDirectory* pd, const virt_addr low, const virt_addr hi)
	{
		// First check if there is a page table at the page directory index	
		immutable(uint) pd_index_end = addr_to_pd_index(hi);

		virt_addr current = low & 0xFFFFF000;
		uint pd_index = addr_to_pd_index(low);
		serial_outln("PD Start: ", pd_index, " PD End: ", cast(uint)pd_index_end);
		serial_outln("Low: ", low, " Hi: ", hi);

		do // Run as least once
		{
			if ((pd.tables[pd_index] & PG_PRESENT) == 0)
			{
				// We need to allocate a new page table, and set everything
				// in it to zero
				phys_addr new_page_table = m_physAllocator.allocate_page();
				memclr(cast(void *) new_page_table, PAGE_SIZE);

				// Set the directory entry and the read/write permissions
				pd.tables[pd_index] = new_page_table;
				pd.tables[pd_index] |= PG_PRESENT | PG_READ_WRITE;
				serial_outln("PT: ", cast(uint) pd.tables[pd_index]);
			}

			PageTable* pt = pd.get_page_table(pd_index);
			serial_outln("pt: ", cast(uint)pt);

			// Map the addresses correctly
			uint pt_index = addr_to_pt_index(current);	
			while (addr_to_pd_index(current) == pd_index && 
					current < hi) // Don't map more than we have to
			{
				pt.addrs[pt_index] = current | PG_READ_WRITE | PG_PRESENT;
				
				current += PAGE_SIZE;
				++pt_index;
			}

			// Increment the page directory index
			++pd_index;
		} while(pd_index < pd_index_end);
	}

	private PageDirectory* allocate_page_directory()
	{
		PageDirectory* pd = cast(PageDirectory *) m_physAllocator.allocate_page();	
		// Make sure it's zero'd out, forgetting to do this can cause all
		// kinds of fun, hard to track down bugs
		memclr(cast(void *) pd, PAGE_SIZE); 

		return pd;
	}
	

	void enable_paging(ref MemoryInfo info)
	{
		m_kernelTable = allocate_page_directory();

		// Identity map the first megabyte
		identity_map(m_kernelTable, 0x0, 0x100000);

		// Identity map the kernel
		identity_map(m_kernelTable, info.kernel_start, info.kernel_end);

		// Don't forget to map the stack!
		identity_map(m_kernelTable, info.kernel_end, 0x200000);

		// In case we mess up
		install_isr(INT_VEC_PAGE_FAULT, &isr_page_fault);

		// Turn on paging!
		switch_page_directory(m_kernelTable);
		set_paging_bit();
	}
}

void set_paging_bit()
{
	asm
	{
		mov EAX, CR0;
		or EAX, 0x80000000;
		mov CR0, EAX;
	}
}

void switch_page_directory(PageDirectory* pd)
{
	asm
	{
		mov EAX, [pd];
		mov CR3, EAX;
	}
}

extern (C)
void isr_page_fault(int vector, int code)
{
	serial_outln("Page Fault: ", vector, " ", code);
	panic();
}
