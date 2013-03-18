module prekernel

extern (C)
void pre_kernel()
{
	asm
	{
		naked;
	}
}
