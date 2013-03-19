module arch.x86.prekernel;

__gshared:
nothrow:

// For x86 we're going to place the kernel at 0x200000 (2MiB)
// and place the kernel's stack under it from 0x100000-0x200000.
//
// To make things easier and to save TLB space the kernel will
// use 4MiB pages for it's code/data.
//
// Additionally we have a higher half kernel for x86. This means
// the kernel is at 0xC0000000 in virtual memory. For simplicity
// everything from 0x100000-0x400000 will be mapped to the range
// 0xC0000000-0xC0400000.
//
// This means the following mapping will be true:
//
// 0xC0000000-0xC0100000 -> 0x00000000-0x00100000 (Low Memory)
// 0xC0100000-0xC0200000 -> 0x00100000-0x00200000 (Kernel Stack)
// 0xC0200000-0xC0400000 -> 0x00200000-0x00400000 (Kernel Code/Data)
//
// Despite all this the code in the module will not be linked at
// the high address because it needs to be called by the bootloader.
//
//

enum KERNEL_STACK = 0x200000-0x4;
enum KERNEL_LOCATION = 0xC0000000;

extern (C) void kmain();

alias extern (C) void function() nothrow fn_void;

extern (C)
{
	// NOTE: These are not true variables, they are the 
	//       locations of these symbols. Use the & to 
	//       get the location.

	fn_void start_of_ctors = void; // The start address of the constructors
	fn_void end_of_ctors = void;   // The end address of the constructors

	uint start_of_dtors = void; // The start address of the destructors
	uint end_of_dtors = void;   // The end address of the destructors

	ubyte sbss = void; // Start of the bss section
	ubyte ebss = void; // End of the bss section
}

extern (C)
void pre_kernel()
{
	asm
	{
		naked;
		mov dword ptr ESP, KERNEL_STACK;
		mov dword ptr EBP, ESP;
	}

	// Setup the higher-half kernel page
	// tables and then enable paging
	// TODO

	// Clear out the BSS section
	ubyte* ptr_bss = &sbss;
	while (ptr_bss < &ebss)
	{
		*ptr_bss++ = 0;
	}

	// TODO - call constructors

	// Call the kernel
	kmain();

	// If we return from the kernel, something bad
	// has happend...
	asm 
	{
	loop:
		cli;
		hlt;
		jmp loop;
	}
}
