module kernel.layer1.elf.loader;

import kernel.layer1.elf.def;

import kernel.layer0.types;
import kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.memory.memory;
import kernel.layer0.memory.iVirtualAllocator;
import kernel.layer0.memory.util;

import kernel.layer1.process.pcb;
import ramfs = kernel.layer1.ramfs.fat;

import glue;

__gshared:
nothrow:

Status load_from_file(ProcessControlBlock* pcb, string filename)
{
	serial_outln("ELF: Loading ", filename);

	if (pcb is null || filename is null)
	{
		return Status.BAD_PARAM;
	}

	ElfHeader elf_header;

	uint bytes_read = ramfs.context.read(filename, cast(ubyte*) &elf_header, 
									0, ElfHeader.sizeof);

	if (bytes_read < ElfHeader.sizeof
		|| elf_header.e_magic != ELF_MAGIC_NUM
		|| elf_header.e_type != ET_EXEC
		|| elf_header.e_machine != EM_386
		|| elf_header.e_entry == 0x0
		|| elf_header.e_version != EV_CURRENT
		|| elf_header.e_phoff == 0
		|| elf_header.e_phnum == 0
		)
	{
		serial_outln(bytes_read);
		return Status.BAD_PARAM;
	}

	uint pheader_table_size = ElfProgHeader.sizeof * elf_header.e_phnum;
	ElfProgHeader[] pheaders = cast(ElfProgHeader[]) alloca(pheader_table_size)[0..pheader_table_size];

	if (pheaders is null)
	{
		panic("ELF: Couldn't allocate pheaders");
	}

	bytes_read = ramfs.context.read(filename, cast(ubyte*) &pheaders[0], 
								elf_header.e_phoff, pheader_table_size);

	if (bytes_read < pheader_table_size)
	{
		return Status.BAD_PARAM;
	}

	for (int i = 0; i < elf_header.e_phnum; ++i)
	{
		ElfProgHeader* cur_pheader = &(pheaders[i]);

		if (cur_pheader.p_type == PT_LOAD)
		{
			// TODO - Update later for when the kernel is put in the higher half
			if ((cur_pheader.p_vaddr >= g_memoryInfo.kernel_start
						&& cur_pheader.p_vaddr < g_memoryInfo.kernel_end)
					|| cur_pheader.p_vaddr < 0x100000)
			{
				panic("ELF: Program header with a bad address");
			}

			// Skip empty sections
			if (cur_pheader.p_memsz == 0)
			{
				continue;
			}

			uint flags = PG_USER;
			if ((cur_pheader.p_flags & PF_WRITE) > 0)
			{
				flags |= PG_READ_WRITE;
			}

			uint start_address = cast(uint) cur_pheader.p_vaddr;
			uint end_address   = start_address + cur_pheader.p_memsz;
			for (; start_address <= end_address; start_address += PAGE_SIZE)
			{
				serial_outln("Mapping: ", start_address);
				map_page(start_address, flags);	
			}

			// Zero out the bss part
			uint bss_size = cur_pheader.p_memsz - cur_pheader.p_filesz;
			memclr(cast(void *) (start_address + bss_size), bss_size);

			if (cur_pheader.p_filesz > cur_pheader.p_memsz)
			{
				panic("ELF: File size is larger than memory size");
			}

			// Read in the actual file
			if (cur_pheader.p_filesz > 0)
			{
				serial_outln("File: ", filename, " Spot: ", cur_pheader.p_vaddr, 
						" Offset: ", cur_pheader.p_offset, " Size: ", cur_pheader.p_filesz);

				bytes_read = ramfs.context.read(filename, cast(ubyte*) cur_pheader.p_vaddr, 
						cur_pheader.p_offset, cur_pheader.p_filesz);

				if (bytes_read != cur_pheader.p_filesz)
				{
					panic("ELF: Failed to read in enough data");
				}
			}
		}
	}

	enum USER_STACK_LOCATION = 0x2000000;
	enum USER_STACK_SIZE = 0x4000;

	uint stack_start = USER_STACK_LOCATION;
	uint stack_end   = USER_STACK_LOCATION + USER_STACK_SIZE;
	for (; stack_start < stack_end; stack_start += PAGE_SIZE)
	{
		map_page(stack_start, PG_READ_WRITE | PG_USER);
	}
	memclr(cast(void*) USER_STACK_LOCATION, USER_STACK_SIZE);


	Context* context = (cast(Context*) (USER_STACK_LOCATION + USER_STACK_SIZE - 4)) - 1;	
	pcb.context = context;

	context.ESP = cast(uint) (cast(uint*)context - 1);
	context.EBP = USER_STACK_LOCATION + USER_STACK_SIZE - 4;
	context.CS = GDT_CODE;
	context.SS = GDT_STACK;
	context.DS = GDT_DATA;
	context.ES = GDT_DATA;
	context.FS = GDT_DATA;
	context.GS = GDT_DATA;

	// Entry point
	context.EIP = elf_header.e_entry;

	// Setup the rest of the PCB
	context.EFL = DEFAULT_EFLAGS;

	return Status.SUCCESS;
}
