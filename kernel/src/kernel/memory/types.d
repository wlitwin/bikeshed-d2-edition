module kernel.memory.types;

__gshared:
nothrow:
public:

/* This structure stores information about the memory available
 * in the system. Since the computer may not have a full 4GiB of
 * RAM, or there may be 'holes' in that memory this structure
 * represents a single contiguous block of memory.
 */
struct MemoryMap
{
	align(1)
	uint base;   // The starting address of the memory segment
	uint length; // The length of the memory segment in bytes
}
