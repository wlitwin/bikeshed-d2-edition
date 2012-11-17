module kernel.memory.iVirtualAllocator;

import kernel.memory.memory;
import kernel.memory.iPhysicalAllocator;

alias uint virt_addr;

enum PG_PRESENT = 0x1;
enum PG_READ_WRITE = 0x2;
enum PG_USER = 0x4;
enum PG_WRITE_THRU = 0x8;
enum PG_CACHE_DISABLE = 0x10;


interface IVirtualAllocator
{
nothrow:

	void initialize(IPhysicalAllocator phys_allocator, ref MemoryInfo info);

	void map_page(virt_addr address, uint permissions);
}
