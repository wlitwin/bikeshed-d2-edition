module kernel.layer0.memory.iVirtualAllocator;

import kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.interrupts;
import kernel.layer0.memory.util;
import kernel.layer0.memory.memory;
import kernel.layer0.memory.iPhysicalAllocator;

__gshared:
nothrow:
public:

alias uint virt_addr;

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

public void switch_page_directory(PageDirectory* pd)
{
	asm
	{
		mov EAX, [pd];
		mov CR3, EAX;
	}
}

public PageDirectory* get_page_directory()
{
	PageDirectory* pd;
	asm
	{
		mov EAX, CR3;
		mov pd, EAX;
	}

	return pd;
}

public PageDirectory* g_kernelTable;

void initialize(ref MemoryInfo info)
{
	serial_outln("VA: Initializing");

	enable_paging(info);
	serial_outln("VA: Finished");
}

public uint addr_to_pd_index(virt_addr address)
{
	return address >> 22;	
}

public virt_addr align_address(virt_addr address)
{
	return address & 0xFFFFF000;
}

public uint addr_to_pt_index(virt_addr address)
{
	return (address >> 12) & 0x03FF;
}

public PageDirectory* get_current_page_directory()
{
	return cast(PageDirectory *)0xFFFFF000;
}

public PageTable* get_page_table(uint index)
{
	return cast(PageTable *)(cast(uint*)0xFFC00000 + (0x400 * index));
}

void map_range(virt_addr v_low, const virt_addr v_hi, 
			   const uint permissions)
{
	assert(v_low < v_hi);

	while (v_low < v_hi)
	{
		map_page(v_low, permissions);
		v_low += PAGE_SIZE;
	}
}

void map_absolute(const phys_addr p_addr, const virt_addr v_addr, uint permissions)
{
	PageDirectory* pd = get_current_page_directory();
	uint pg_dir_index = addr_to_pd_index(v_addr);
	uint pg_tbl_index = addr_to_pt_index(v_addr);

	PageTable* page_table = get_page_table(pg_dir_index);

	if ((pd.tables[pg_dir_index] & PG_PRESENT) == 0)
	{
		// Need to allocate a page table
		uint phys_page_table = cast(uint)physAllocator.allocate_page();
		pd.tables[pg_dir_index] = phys_page_table | 3;

		memclr(cast(void *)page_table, PAGE_SIZE);
	}

	page_table.addrs[pg_tbl_index] = p_addr | (permissions & 0xFFF) | PG_PRESENT;

	// Flush the TLB
	uint pd_asm = cast(uint)pd & 0xFFFFF000;
	uint pt_asm = cast(uint)page_table & 0xFFFFF000;
	asm
	{
		invlpg v_addr;
		invlpg pt_asm;
		invlpg pd_asm;
	}
}

void map_range(phys_addr p_lo, const phys_addr p_hi,
			   virt_addr v_lo, const virt_addr v_hi,
			   const uint permissions)
{
	assert(p_lo < p_hi);
	assert(v_lo < v_hi);
	assert((p_hi-p_lo) == (v_hi-v_lo));

	PageDirectory* pd = get_current_page_directory();

	p_lo = p_lo & 0xFFFFF000; // Align to 4KiB boundary
	v_lo = v_lo & 0xFFFFF000; // Align to 4KiB boundary

	while (v_lo < v_hi)
	{
		uint pg_dir_index = addr_to_pd_index(v_lo);
		uint pg_tbl_index = addr_to_pt_index(v_lo);

		PageTable* page_table = get_page_table(pg_dir_index);

		if ((pd.tables[pg_dir_index] & PG_PRESENT) == 0)
		{
			// Need to allocate a page table
			uint phys_page_table = cast(uint)physAllocator.allocate_page();
			pd.tables[pg_dir_index] = phys_page_table | 3;

			memclr(cast(void *)page_table, PAGE_SIZE);
		}

		if (page_table.addrs[pg_tbl_index] != 0)
		{
			assert(false, "VA: map_range - address is already mapped!");
		}

		page_table.addrs[pg_tbl_index] = p_lo | (permissions & 0xFFF) | PG_PRESENT;

		// Flush the TLB
		uint pd_asm = cast(uint)pd & 0xFFFFF000;
		uint pt_asm = cast(uint)page_table & 0xFFFFF000;
		asm
		{
			invlpg v_lo;
			invlpg pt_asm;
			invlpg pd_asm;
		}

		v_lo += PAGE_SIZE;
		p_lo += PAGE_SIZE;
	}
}

public PageDirectory* clone_page_directory()
{
	PageDirectory* pd = get_current_page_directory();

	const uint scratch_pd_address  = 0x100000 - PAGE_SIZE;
	const uint scratch_pt_address  = 0x100000 - PAGE_SIZE*2;
	const uint scratch_pte_address = 0x100000 - PAGE_SIZE*3;

	// We're going to do most of the copying with paging on for
	// easiness. This means we need have some scratch space to
	// copy data from this address space into the new one. We'll
	// temporarily unmap some of the pages below 1MiB and then
	// remap them.
	PageDirectory* scratch_pd = cast(PageDirectory*) scratch_pd_address;
	PageTable* scratch_pt = cast(PageTable*) scratch_pt_address;
	uint* scratch_pte = cast(uint*) scratch_pte_address;

	// A little helper function to map some memory to the scratch areas
	uint map_and_clear(uint address) nothrow
	{
		uint phys_address = physAllocator.allocate_page();
		map_absolute(phys_address, cast(virt_addr)address, PG_READ_WRITE);
		memclr(cast(void *)address, PAGE_SIZE);
		return phys_address;
	}

	// Allocate space for the new page directory and clear it
	const uint phys_pd_address = map_and_clear(cast(uint)scratch_pd);

	// Allocate space for a page table
	const uint phys_pt_address = map_and_clear(cast(uint)scratch_pt);

	// Setup an identity mapping of the lowest 1MiB in the new address space	
	const uint one_MiB = addr_to_pt_index(0x100000);	
	for (uint i = 0; i < one_MiB; ++i)
	{
		scratch_pt.addrs[i] = i*PAGE_SIZE | PG_PRESENT | PG_READ_WRITE;
	}

	scratch_pd.tables[0] = phys_pt_address | PG_READ_WRITE | PG_PRESENT;

	// Map in the kernel
	const uint kernel_idx_lo = addr_to_pd_index(g_memoryInfo.kernel_start);
	const uint kernel_idx_hi = addr_to_pd_index(g_memoryInfo.kernel_end);

	// Copy the whole default kernel address space
	for (uint idx = kernel_idx_lo; idx <= kernel_idx_hi; ++idx)
	{
		serial_outln("I: ", idx, " PD: ", cast(uint)pd.tables[idx]);
		scratch_pd.tables[idx] = pd.tables[idx];
	}

	void flush_tlb() nothrow
	{
		asm {
			mov EAX, CR3;
			mov CR3, EAX;
		}
	}

	// A little helper function to do a physical copy
	void physical_copy(const uint pd_index) nothrow
	{
		uint copy_from_address = pd_index * (PAGE_SIZE * 1024);
		if ((pd.tables[pd_index] & PG_PRESENT) > 0)
		{
			serial_outln("Copying Start: ", copy_from_address);
			// Go through all the page table entries and see if they need
			// to be copied
			PageTable* pt = get_page_table(pd_index);

			const uint phys_pt_address = map_and_clear(cast(uint)scratch_pt);
			scratch_pd.tables[pd_index] = phys_pt_address | PG_READ_WRITE | PG_PRESENT;

			for (uint i = 0; i < 1024; ++i, copy_from_address += PAGE_SIZE)
			{
				if ((pt.addrs[i] & PG_PRESENT) > 0)
				{
					serial_outln("Copying: ", copy_from_address);
					// Physically copy this page
					const uint phys_address = map_and_clear(cast(uint)scratch_pte);
					const uint orig_flags_and_addr = phys_address | (pt.addrs[i] & 0xFFF);

					scratch_pt.addrs[i] = phys_address | PG_READ_WRITE | PG_PRESENT;

					// Do the actual copy operation
					memcpy(cast(void*)scratch_pte, cast(void*)copy_from_address, PAGE_SIZE);

					// Use the original flags
					scratch_pt.addrs[i] = orig_flags_and_addr;
					
					flush_tlb();
				}
			}
		}
	}

	serial_outln("Kernel low: ", kernel_idx_lo);
	serial_outln("Kernel hi:  ", kernel_idx_hi);

	// Now make a copy of everything else, that's from 0x100000 - Kernel Start
	// and Kernel End - 0xFFFFF000
	for (uint idx = one_MiB; idx < kernel_idx_lo; ++idx)
	{
		physical_copy(idx);
	}

	// Don't copy the last section, that maps back to the scratch_pd
	// TODO - Fix when we get a higher half kernel
	//        Work around so we don't copy the kernel heap
	for (uint idx = kernel_idx_hi+1; idx < 1023; ++idx)
	{
		physical_copy(idx);
	}

	// Map the new page directory back to itself
	scratch_pd.tables[1023] = phys_pd_address | PG_READ_WRITE | PG_PRESENT;

	// Reset the scratch entries
	map_absolute(scratch_pd_address,  scratch_pd_address, PG_READ_WRITE);
	map_absolute(scratch_pt_address,  scratch_pt_address, PG_READ_WRITE);
	map_absolute(scratch_pte_address, scratch_pte_address, PG_READ_WRITE);

	return cast(PageDirectory*) phys_pd_address;
}

void map_page(const virt_addr address, const uint permissions)
{
	PageDirectory* pd = get_current_page_directory();
	uint pg_dir_index = addr_to_pd_index(address);
	uint pg_tbl_index = addr_to_pt_index(address);
	PageTable* page_table = get_page_table(pg_dir_index);

	if ((pd.tables[pg_dir_index] & PG_PRESENT) == 0)
	{
		// Need to allocate a page table
		uint phys_page_table = cast(uint)physAllocator.allocate_page();
		pd.tables[pg_dir_index] = phys_page_table | 3;

		memclr(cast(void *)page_table, PAGE_SIZE);
	}

	if (page_table.addrs[pg_tbl_index] != 0)
	{
		assert(false, "VA: map_page - address is already mapped!");
	}

	// Get a new physical address to map
	uint phys_block = cast(uint)physAllocator.allocate_page();
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
		physAllocator.free_page(cast(phys_addr)page_table.addrs[pg_tbl_index]);
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

void reset_page_directory()
{
	for (uint addr = 0x100000; addr < g_memoryInfo.kernel_start; addr += PAGE_SIZE)
	{
		unmap_page(addr);	
	}

	const uint max_address = 1023 * PAGE_SIZE * 1024;
	for (uint addr = g_memoryInfo.kernel_end; addr < max_address; addr += PAGE_SIZE)
	{
		if (addr < 0x600000 || addr > 0x619000)
			unmap_page(addr);	
	}
}

void identity_map(const virt_addr low, const virt_addr hi)
{
	identity_map(g_kernelTable, low, hi);
}

void free_page_directory(PageDirectory* pd)
{
	reset_page_directory();
	switch_page_directory(g_kernelTable);

	// Free it
	physAllocator.free_page(cast(uint)pd);
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
			phys_addr new_page_table = physAllocator.allocate_page();
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
	g_kernelTable = cast(PageDirectory *) physAllocator.allocate_page();	
	// Make sure it's zero'd out, forgetting to do this can cause all
	// kinds of fun, hard to track down bugs
	memclr(cast(void *) g_kernelTable, PAGE_SIZE); 

	g_kernelTable.tables[1023] = cast(uint)g_kernelTable | PG_READ_WRITE | PG_PRESENT;

	setup_initial_pages();

	// In case we mess up
	install_isr(INT_VEC_PAGE_FAULT, &isr_page_fault);

	// Turn on paging!
	switch_page_directory(g_kernelTable);
	set_paging_bit();
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

	serial_outln("Interrupt context:\n", 
			"EFL: ", g_interruptContext.EFL, "\n", 
			"CS:  ", g_interruptContext.CS, "\n", 
			"EIP: ", g_interruptContext.EIP, "\n", 
			"Err: ", g_interruptContext.error_code, "\n", 
			"Vec: ", g_interruptContext.vector, "\n", 
			"EAX: ", g_interruptContext.EAX, "\n", 
			"ECX: ", g_interruptContext.ECX, "\n", 
			"EDX: ", g_interruptContext.EDX, "\n",
			"EBX: ", g_interruptContext.EBX, "\n",
			"ESP: ", g_interruptContext.ESP, "\n",
			"EBP: ", g_interruptContext.EBP, "\n",
			"ESI: ", g_interruptContext.ESI, "\n",
			"EDI: ", g_interruptContext.EDI, "\n",
			"DS:  ", g_interruptContext.DS, "\n",
			"ES:  ", g_interruptContext.ES, "\n",
			"FS:  ", g_interruptContext.FS, "\n",
			"GS:  ", g_interruptContext.GS, "\n",
			"SS:  ", g_interruptContext.SS);

	serial_outln("US RW P - Description");
	serial_outln(code & 0x4, "  ",
			code & 0x2, "  ",
			code & 0x1, "   ",
			cast(string)page_table_errors[error_type]);

	serial_outln("Faulting address: ", cr2_val);
	serial_outln("Page Fault: ", vector, " ", code);
	panic();
}
