import kernel.vga;

extern (C) void kmain()
{
	put_string(0, 0, message);	
	char[] s = new char[12];
	asm { hlt; }
}

