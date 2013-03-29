module kernel.memory.defs;

__gshared:
nothrow:
public:

public import kernel.memory.physical.defs;
public import kernel.memory.virtual.defs;

enum KERNEL_VIRT_LOCATION = 0xC0000000;
enum KERNEL_LOAD_LOCATION = 0x00200000;
enum KERNEL_STACK_LOCATION = KERNEL_VIRT_LOCATION + (KERNEL_LOAD_LOCATION - 0x4);
