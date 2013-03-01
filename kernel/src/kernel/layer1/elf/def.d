module kernel.layer1.elf.def;

__gshared:
nothrow:

alias uint   Elf32_Addr;
alias ushort Elf32_Half;
alias uint   Elf32_Off;
alias int    Elf32_Sword;
alias uint   Elf32_Word;

enum EI_NIDENT = 12;

enum ELF_MAGIC_NUM = 0x464C457F; // 0x7F 'E' 'L' 'F' (little endian)
enum ET_EXEC = 2;
enum EM_386 = 3;
enum EV_CURRENT = 1;
enum PF_WRITE = 2;
enum PT_LOAD = 1;

struct ElfHeader
{
public:
nothrow:
	Elf32_Word e_magic;
	byte e_ident[EI_NIDENT];

	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;

	Elf32_Addr e_entry;
	Elf32_Off  e_phoff;
	Elf32_Off  e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
}

struct ElfSectHeader
{
public:
nothrow:
	Elf32_Word sh_name;
	Elf32_Word sh_type;
	Elf32_Word sh_flags;
	Elf32_Addr sh_addr;
	Elf32_Off sh_offset;
	Elf32_Word sh_size;
	Elf32_Word sh_link;
	Elf32_Word sh_info;
	Elf32_Word sh_addralign;
	Elf32_Word sh_entsize;
}

struct ElfSymTable
{
public:
nothrow:
	Elf32_Word st_name;
	Elf32_Addr st_value;
	Elf32_Word st_size;
	ubyte      st_info;
	ubyte      st_other;
	Elf32_Half st_shndx;
}

struct ElfReloc
{
public:
nothrow:
	Elf32_Addr r_offset;
	Elf32_Word r_info;
}

struct ElfRelation
{
public:
nothrow:
	Elf32_Addr  r_offset;
	Elf32_Word  r_info;
	Elf32_Sword r_addend;
}

struct ElfProgHeader
{
public:
nothrow:
	Elf32_Word p_type;
	Elf32_Off  p_offset;
	Elf32_Addr p_vaddr;
	Elf32_Addr p_addr;
	Elf32_Word p_filesz;
	Elf32_Word p_memsz;
	Elf32_Word p_flags;
	Elf32_Word p_align;
}
