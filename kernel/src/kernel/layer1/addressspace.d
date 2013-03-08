module kernel.layer1.addressspace;

import kernel.layer0.memory.memory;
import kernel.layer0.memory.iVirtualAllocator;
import physAllocator = kernel.layer0.memory.iPhysicalAllocator;

__gshared:
nothrow:

PageDirectory* new_address_space()
{
	// Create a new address space based off the kernel
	PageDirectory* old_pd = get_page_directory();	
	if (old_pd != g_kernelTable) {
		switch_page_directory(g_kernelTable);
	}

	PageDirectory* ret_pd = cast(PageDirectory*) physAllocator.allocate_page();

	uint lo_pd_1mb = 0;
	uint hi_pd_1mb = addr_to_pd_index(0x100000); 

	uint lo_pd_kern = addr_to_pd_index(g_memoryInfo.kernel_start);
	uint hi_pd_kern = 1023;//addr_to_pd_index(KERNEL_END);

	// Disable paging
	asm
	{
		mov EAX, CR0;
		and EAX, 0x7FFFFFFF;
		mov CR0, EAX;
	}

	// Copy between them
/*	for (int i = lo_pd_1mb; i <= hi_pd_1mb; ++i)
	{
		ret_pd.tables[i] = g_kernelTable.tables[i];
	}

	for (int i = lo_pd_kern; i <= 1022; ++i)
	{
		ret_pd.tables[i] = g_kernelTable.tables[i];
	}
	*/
	for (int i = 0; i < 1024; ++i)
	{
		ret_pd.tables[i] = g_kernelTable.tables[i];
	}

	// Map this page directory back to itself
	ret_pd.tables[1023] = cast(uint) ret_pd | PG_READ_WRITE | PG_PRESENT;

	// Enable paging
	asm
	{
		mov EAX, CR0;
		or EAX, 0x80000000;
		mov CR0, EAX;
	}

	if (old_pd != g_kernelTable) {
		switch_page_directory(old_pd);
	}

	return ret_pd;
}
