module kernel.memory.init;

import kernel.memory.physical.init;
import kernel.memory.virtual.init;

__gshared:
nothrow:
public:

void init()
{
	version (X86)
	{
		import x86 = arch.x86.memory.init;
		x86.init();
	}
	else
	{
		static assert(false, "Memory Init: Unsupported Architecture");
	}
}
