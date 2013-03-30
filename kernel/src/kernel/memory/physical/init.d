module kernel.memory.physical.init;

import kernel.memory.physical.types;

__gshared:
nothrow:
public:

private Memory g_memory;

void init()
{
	version (X86)
	{
		import x86 = arch.x86.memory.physical.impl;
		x86.init(g_memory);
	}
	else
	{
		static assert(false, "Memory Init: Unsupported Architecture");
	}
}
