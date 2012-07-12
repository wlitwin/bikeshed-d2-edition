ENTRY (kmain)
OUTPUT_ARCH (i386)

SECTIONS {
	. = 0x100000;

	.text : {
		code = .; _code = .; __code = .;
		*(.text)
	}

	.data ALIGN(0x1000) : {
		data = .; _data = .; __data = .;
		*(.data)
	}

	.rodata ALIGN(0x1000) : {
		*(.rodata)
	}

	.bss : {
		sbss = .;
		bss = .; _bss = .; __bss = .;
		*(COMMON)
		*(.bss)
		ebss = .;
	}
	end = .; _end = .; __end = .;

	/DISCARD/ :
	{
		*(.comment)
		*(.eh_frame)
	}
}
