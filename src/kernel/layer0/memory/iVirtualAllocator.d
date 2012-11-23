module kernel.layer0.memory.iVirtualAllocator;

import kernel.layer0.memory.memory;
import kernel.layer0.memory.iPhysicalAllocator;

__gshared:
nothrow:

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

interface IVirtualAllocator
{
nothrow:

	void initialize(IPhysicalAllocator phys_allocator, ref MemoryInfo info);

	void map_page(virt_addr address, uint permissions);
	void unmap_page(virt_addr address);

}

public PageDirectory* clone_page_directory()
{
	return null;
}

public void switch_page_directory(PageDirectory* pd)
{
	asm
	{
		mov EAX, [pd];
		mov CR3, EAX;
	}
}

