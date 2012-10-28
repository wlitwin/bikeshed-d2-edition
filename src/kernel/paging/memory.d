import kernel.serial;

__gshared:
enum MMAP_ADDRESS = 0x2D00;
enum MMAP_EXT_LO  = 0x00;
enum MMAP_EXT_HI  = 0x02;
enum MMAP_CFG_LO  = 0x04;
enum MMAP_CFG_HI  = 0x06;

enum ONE_MEGABYTE = 1024 * 1024;

uint PHYSICAL_MEMORY_SIZE;

void
init_memory()
{
	// Check how much memory is available	
	uint memory_low = *(cast(ushort*) (MMAP_ADDRESS + MMAP_EXT_LO)) * 1024;
	uint memory_hi  = *(cast(ushort*) (MMAP_ADDRESS + MMAP_EXT_HI)) * 64 * 1024;

	PHYSICAL_MEMORY_SIZE = ONE_MEGABYTE + memory_low + memory_hi;	

	serial_outln("Memory Size: ", PHYSICAL_MEMORY_SIZE);
	serial_outln("Memory Low : ", memory_low);
	serial_outln("Memory Hi  : ", memory_hi);
//	put_string(0, 2, "Memory size: ");
}

void
init_paging()
{

}
