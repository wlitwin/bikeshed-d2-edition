module arch.x86.memory.physical.manager;

import arch.x86.memory.physical.impl : SMAPEntry;

import kernel.kprintf;

__gshared:
nothrow:
package: // Only allow other modules inside physical/ to have access

/* The physical memory manager is a two tier data structure. The
 * first tier is a linked list of free 4MiB pages. If a 4KiB page
 * needs to be allocated, a 4MiB page is broken down into another
 * tier which manages 4KiB tables in a similar manner.
 *
 * Operation:
 *   
 */
struct PhysicalManager
{
nothrow:
	align(1)
	uint free_list_4MiB[1024];

	this(ref SMAPEntry* memmap, uint count)
	{
		// The SMAP array contains the regions of memory
		// that are valid for use. We need to go through
		// it and find all the valid regions we have
		// available.

		enum LOW_MEMORY = 0x100000;
		enum KERNEL_PAGE_END = 0x400000;

		enum SMALL_PAGE_SIZE = 0x1000;
		enum LARGE_PAGE_SIZE = 0x400000;

		for (int i = 0; i < count; ++i)
		{
			kprintf("Entry: %d - Base: %X - Length: %d ", i, memmap[i].base, memmap[i].length);

			// Okay we're going to ignore anything that's below 1MiB
			// Also we need to fudge it a bit so that nothing in the
			// kernel's 4MiB page gets used.

			uint new_base = memmap[i].base;
			uint new_length = memmap[i].length;

			if (memmap[i].base < LOW_MEMORY) {
				// We don't want to touch anything lower than 1MiB
				// for now. It may be useful later when we need to
				// setup DMA or some other low memory buffers for
				// different uses.
				kprintf("Skipping -- Too Low\n");
				continue;
			}

			if (memmap[i].base < KERNEL_PAGE_END)
			{
				// We need to see if the length needs to be 
				// fudged. First check if fudging will help
				if (new_base + new_length < KERNEL_PAGE_END) {
					// No, fudging would leave it under the
					// boundary anyway
					kprintf("Skipping -- Can't Fudge");
					continue;
				} else {
					// Otherwise we can fudge it
					new_length = new_length - (KERNEL_PAGE_END - new_base);
					new_base = KERNEL_PAGE_END;
				}
			}

			// Here we do computation based on the new_base and new_length
			if (new_length < SMALL_PAGE_SIZE) {
				// It's not useful if it's less than a page in size
				kprintf("Skipping -- Too Small");
				continue;
			}

			kprintf("NewB: %x - NewL: %d\n", new_base, new_length);

			if (new_length >= LARGE_PAGE_SIZE) 
			{
				// See how many 4MiB pages we can get outta this thing	
			}
			else
			{

			}
		}
	}
}
