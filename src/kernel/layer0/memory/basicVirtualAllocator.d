module kernel.layer0.memory.basicVirtualAllocator;

import kernel.layer0.serial;
import kernel.layer0.memory.util : memclr;
import kernel.layer0.memory.memory;
import kernel.layer0.interrupts;
import kernel.layer0.support;
import kernel.layer0.memory.iPhysicalAllocator;
import kernel.layer0.memory.iVirtualAllocator;

__gshared:
nothrow:

class BasicVirtualAllocator : IVirtualAllocator
{
	private IPhysicalAllocator m_physAllocator;
	private PageDirectory* m_kernelTable;

nothrow:

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

	private virt_addr align_address(virt_addr address)
	{
		return address & 0xFFFFF000;
	}

	private uint addr_to_pt_index(virt_addr address)
	{
		return (address >> 12) & 0x03FF;
	}

	private PageDirectory* get_current_page_directory()
	{
		return cast(PageDirectory *)0xFFFFF000;
	}

	private PageTable* get_page_table(uint index)
	{
		return cast(PageTable *)(cast(uint*)0xFFC00000 + (0x400 * index));
	}

	void map_range(PageDirectory* pd,
			const phys_addr p_low, const phys_addr p_hi,
			const virt_addr v_low, const virt_addr v_hi)
	{
		panic("map_range() not yet implemented");					
	}

	void map_page(virt_addr address, uint permissions)
	{
		PageDirectory* pd = get_current_page_directory();
		uint pg_dir_index = addr_to_pd_index(address);
		uint pg_tbl_index = addr_to_pt_index(address);
		PageTable* page_table = get_page_table(pg_dir_index);

		if ((pd.tables[pg_dir_index] & PG_PRESENT) == 0)
		{
			// Need to allocate a page table
			uint phys_page_table = cast(uint)m_physAllocator.allocate_page();
			pd.tables[pg_dir_index] = phys_page_table | 3;

			memclr(cast(void *)page_table, PAGE_SIZE);
		}

		if (page_table.addrs[pg_tbl_index] != 0)
		{
			panic("BVA: map_page - address is already mapped!");
		}

		// Get a new physical address to map
		uint phys_block = cast(uint)m_physAllocator.allocate_page();
		page_table.addrs[pg_tbl_index] = phys_block | (permissions & 0xFFF) | PG_PRESENT;

		// Flush the TLB
		uint pd_asm = cast(uint)pd & 0xFFFFF000;
		uint pt_asm = cast(uint)page_table & 0xFFFFF000;
		asm
		{
			invlpg address;
			invlpg pt_asm;
			invlpg pd_asm;
		}
	}

	void unmap_page(virt_addr address)
	{
		PageDirectory* pd = get_current_page_directory();
		uint pg_dir_index = addr_to_pd_index(address);
		uint pg_tbl_index = addr_to_pt_index(address);
		PageTable* page_table = get_page_table(pg_dir_index);

		// Check if the page directory entry is present. 
		// If it's not, then we can return
		if ((pd.tables[pg_dir_index] & PG_PRESENT) == 0)
		{
			return;
		}

		if ((page_table.addrs[pg_tbl_index] & PG_PRESENT) > 0)
		{
			m_physAllocator.free_page(cast(phys_addr)page_table.addrs[pg_tbl_index]);
		}

		page_table.addrs[pg_tbl_index] = 0;

		// TODO - check if all the page table entries are free
		// and free the page directory entry

		// Flush the TLB
		uint pd_asm = cast(uint)pd & 0xFFFFF000;
		uint pt_asm = cast(uint)page_table & 0xFFFFF000;
		asm
		{
			invlpg address;
			invlpg pt_asm;
			invlpg pd_asm;
		}
	}

	// Only works when paging is off
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

	private void enable_paging(ref MemoryInfo info)
	{
		m_kernelTable = cast(PageDirectory *) m_physAllocator.allocate_page();	
		// Make sure it's zero'd out, forgetting to do this can cause all
		// kinds of fun, hard to track down bugs
		memclr(cast(void *) m_kernelTable, PAGE_SIZE); 

		m_kernelTable.tables[1023] = cast(uint)m_kernelTable | PG_READ_WRITE | PG_PRESENT;

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

void unset_paging_bit()
{
	asm
	{
		mov EAX, CR0;
		and EAX, 0x7FFFFFFF;
		mov CR0, EAX;
	}
}

immutable(string[]) page_table_errors = 
[
	"Supervisory process tried to read a non-present page entry",
	"Supervisory process tried to read a page and caused a protection fault",
	"Supervisory process tried to write to a non-present page entry",
	"Supervisory process tried to write a page and cause a protection fault",
	"User process tried to read a non-present page entry",
	"User process tried to read a page and caused a protection fault",
	"User process tried to write a non-present page entry",
	"User process tried to write a page and caused a protection fault"
];

extern (C)
void isr_page_fault(int vector, int code)
{
	uint error_type = code & 0x7;
	uint cr2_val;
	asm
	{
		mov EAX, CR2;
		mov cr2_val, EAX;
	}

/*	serial_outln("Interrupt context:\n", 
			g_interruptContext.EFL, "\n", 
			g_interruptContext.CS, "\n", 
			g_interruptContext.EIP, "\n", 
			g_interruptContext.error_code, "\n", 
			g_interruptContext.vector, "\n", 
			g_interruptContext.EAX, "\n", 
			g_interruptContext.ECX, "\n", 
			g_interruptContext.EDX, "\n",
			g_interruptContext.EBX, "\n",
			g_interruptContext.ESP, "\n",
			g_interruptContext.EBP, "\n",
			g_interruptContext.ESI, "\n",
			g_interruptContext.EDI, "\n",
			g_interruptContext.DS, "\n",
			g_interruptContext.ES, "\n",
			g_interruptContext.FS, "\n",
			g_interruptContext.GS, "\n",
			g_interruptContext.SS);
			*/

	serial_outln("US RW P - Description");
	serial_outln(code & 0x4, "  ",
				 code & 0x2, "  ",
				 code & 0x1, "   ",
				cast(string)page_table_errors[error_type]);
	
	serial_outln("Faulting address: ", cr2_val);
	serial_outln("Page Fault: ", vector, " ", code);
	panic();
}
