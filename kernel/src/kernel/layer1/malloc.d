module kernel.layer1.malloc;

import kernel.layer0.memory.memory : PAGE_SIZE;
import physAllocator = kernel.layer0.memory.iPhysicalAllocator;
import kernel.layer0.memory.util;
import virtAllocator = kernel.layer0.memory.iVirtualAllocator;
import kernel.layer0.memory.iVirtualAllocator : virt_addr, PG_READ_WRITE, PG_PRESENT;
import kernel.layer0.support;

__gshared:
private:
nothrow:

struct LinkedNode
{
	uint size; // Size must be first! Also it's the size without the HEADER
	LinkedNode* next;
	LinkedNode* prev;
}

enum HEADER_SIZE = 4;

struct Heap
{
	void* start_address;
	void* end_address;
	void* max_address;
	LinkedNode* start_node;
}

Heap kernel_heap = void;

enum HEAP_INITIAL_PAGES = 2;

enum HEAP_START_LOCATION = 0xD1000000;
enum HEAP_MAX_LOCATION   = 0xE0000000;

extern (C)
public void* malloc(uint size)
{
	return kmalloc(size);
}

extern (C)
public void* calloc(uint size)
{
	return kcalloc(size);
}

extern (C)
public void* realloc(void* ptr, size_t size)
{
	return krealloc(ptr, size);
}

extern (C)
public void free(void* ptr)
{
	kfree(ptr);
}

public void malloc_initialize()
{
	kernel_heap.start_address = cast(void *) HEAP_START_LOCATION;
	kernel_heap.max_address   = cast(void *) HEAP_MAX_LOCATION;

	void* start_address = kernel_heap.start_address;
	for (uint i = 0; i < HEAP_INITIAL_PAGES; ++i)
	{
		virtAllocator.map_page(cast(virt_addr) start_address, PG_READ_WRITE | PG_PRESENT);
		start_address += PAGE_SIZE;
	}

	kernel_heap.end_address = start_address;
	kernel_heap.start_node = cast(LinkedNode *) kernel_heap.start_address;

	kernel_heap.start_node.size = HEAP_INITIAL_PAGES * PAGE_SIZE;
	kernel_heap.start_node.next = null;
	kernel_heap.start_node.prev = null;
}

void malloc_info()
{
	uint node_number = 1;
	LinkedNode* node = kernel_heap.start_node;

	while (node != null)
	{
		serial_outln("Node number: ", node_number);
		serial_outln("Node addr: ", node);
		serial_outln("Node size: ", node.size);
		serial_outln("Node next: ", node.next);
		serial_outln("Node prev: ", node.prev);
		node = node.next;
		++node_number;
	}
}

public void* kmalloc(uint size)
{
	if (size < LinkedNode.sizeof)
	{
		size = LinkedNode.sizeof;
	}

	// Make sure the size is aligned to a 4-byte boundary
	if (size % 4 != 0)
	{
		size += 4 - (size % 4);
	}

	// Add the head size to the allocation size, because we subtract that when returning the node
	size += HEADER_SIZE;

	// Find a node that will fit
	LinkedNode* current_node = kernel_heap.start_node;
	while (current_node.next != null && current_node.size <= (size + LinkedNode.sizeof))
	{
		current_node = current_node.next;	
	}

	if (current_node.next == null && current_node.size < (size + LinkedNode.sizeof))
	{
		// We couldn't find a node large enough, ask for more space!
		// We need to allocate at least 1 page, but also include some fudge for the next
		// header which will need to come after this as we're expanding the last node
		uint num_pages = (size - current_node.size + LinkedNode.sizeof) / PAGE_SIZE + 1;	

		// TODO - fix for multiple processes
		//current_node.size += num_pages * PAGE_SIZE;
		panic("Kmalloc, ran out of space!");
	}

	// Okay we've found a good node
	LinkedNode* next_node = cast(LinkedNode *)(cast(uint)current_node + size);
	// Setup next_node's size
	next_node.size = cast(uint)current_node.size - size;

	// Check if we're replacing the root node
	if (current_node == kernel_heap.start_node)
	{
		kernel_heap.start_node = next_node;
		next_node.prev = null;
		next_node.next = current_node.next;
	}
	else
	{
		next_node.next = current_node.next;
		next_node.prev = current_node.prev;

		current_node.prev.next = next_node;
	}

	// Add the previous node for both cases
	if (current_node.next != null)
	{
		current_node.next.prev = next_node;
	}

	// Fix up current_node's size so we know how much to free!
	current_node.size = size;
	current_node.next = cast(LinkedNode *)0xDEADBEEF; // Sentinal pointers to see if something is wrong later
	current_node.prev = cast(LinkedNode *)0xCAFEBABE;

	void* addr = cast(void *)(cast(uint)current_node + HEADER_SIZE);

	return addr;
}

public void* krealloc(void* old_ptr, uint size)
{
	// Do the simplest implementation for now
	void* ptr = kmalloc(size);
	if (ptr == null)
	{
		return null;
	}

	// Get the old pointers size, which lives
	// just above the old pointer
	uint old_size = *(cast(uint*)old_ptr - 1);

	memcpy(ptr, old_ptr, old_size);

	return ptr;
}

public void* kcalloc(uint size)
{
	void* address = kmalloc(size);
	memclr(address, size);

	return address;
}

public void kfree(void* address)
{
	// Do nothing if we've been given a bad value
	if (address < kernel_heap.start_address || address > kernel_heap.end_address)
	{
		serial_outln("KMALLOC OUT OF RANGE ADDRESS: ", address);
		return;
	}

	LinkedNode* free_node = cast(LinkedNode *)(cast(uint)address - HEADER_SIZE);

	if (free_node.size > (cast(uint)kernel_heap.end_address - cast(uint)kernel_heap.start_address))
	{
		serial_outln("Bad size!");
		panic("Kmalloc, bad size!");
	}

	LinkedNode* current_node = kernel_heap.start_node;
	// Check to see if this free_node is before the current head of the free list
	if (free_node < current_node)
	{
		// Check if we can combine the free_node with the start_node
		if ((cast(uint)free_node + free_node.size) == cast(uint)current_node)
		{
			free_node.size += kernel_heap.start_node.size;
			free_node.next = kernel_heap.start_node.next;
			free_node.prev = null;

			if (kernel_heap.start_node.next != null)
			{
				kernel_heap.start_node.next.prev = free_node;
			}
		}
		else
		{
			// We can't combine the free_node with start_node, so we have to replace it
			free_node.next = kernel_heap.start_node;
			free_node.prev = null;
			kernel_heap.start_node.prev = free_node;
		}

		kernel_heap.start_node = free_node;
		return; // We've found a place for the free_node
	}

	// Okay we still haven't found a place for the free_node.
	// At this point current_node == kernel_heap.start_node.
	// Loop until we find a node that is after free_node and
	// then insert free_node before that node
	while (current_node != null && current_node < free_node)
	{
		current_node = current_node.next;
	}

	// Okay either fell of the list (which should be impossible)
	// or we found a node that comes after free_node
	if (current_node == null)
	{
		// We fell off the list! This should be impossible!
		panic("Kfree, fell off of the free list! Impossible condition!");
	}

	// Current node is now a node that should come after free_node
	// so setup the relations
	free_node.next = current_node;
	free_node.prev = current_node.prev;
	current_node.prev.next = free_node;
	current_node.prev = free_node;

	// These should all point to the correct places now
	LinkedNode* prev_node   = free_node.prev;
	LinkedNode* middle_node = free_node;
	LinkedNode* last_node   = free_node.next;

	// Check if the previous node can be combined with free_node
	if ((cast(uint)prev_node + prev_node.size) == cast(uint)middle_node)
	{
		// We can combine them
		prev_node.next = middle_node.next;
		middle_node.next.prev = prev_node;

		// Update prev_node's size
		prev_node.size += free_node.size;

		// Make us the new middle
		middle_node = prev_node;
	}

	// Check if the middle node can be combined with the last_node
	if ((cast(uint)middle_node + middle_node.size) == cast(uint)last_node)
	{
		// We can combine them
		middle_node.next = last_node.next;
		if (last_node.next != null)
		{
			last_node.next.prev = middle_node;
		}

		// Update middle_node's size
		middle_node.size += last_node.size;
	}
}

void kmalloc_test_1()
{
	uint amt = 1000;
	uint ptrs[1000];

	uint total_allocated = 0;
	for (uint i = 0; i < amt; ++i)
	{
		uint size = krand() % 8192;
		ptrs[i] = cast(uint)kmalloc(size);
		total_allocated += size;
	}

	uint num_freed = 0;
	while (num_freed != amt / 2)
	{
		uint index = krand() % amt;
		if (ptrs[index] != 0)
		{
			kfree(cast(void*)ptrs[index]);
			ptrs[index] = 0;
			++num_freed;
		}
	}

	for (uint i = 0; i < amt; ++i)
	{
		if (ptrs[i] == 0)
		{
			uint size = krand() % 8192;
			ptrs[i] = cast(uint)kmalloc(size);
			total_allocated += size;
		}
	}

	num_freed = 0;
	while (num_freed != amt)
	{
		uint index = krand() % amt;
		if (ptrs[index] != 0)
		{
			kfree(cast(void*)ptrs[index]);
			ptrs[index] = 0;
			++num_freed;
		}
	}

	serial_outln("Total amount allocated: ", total_allocated);

	malloc_info();

	asm { cli; hlt; }
}
