CC=gcc
C_FLAGS=-Wall -Werror -Wextra -pedantic -std=gnu99

DC=src/dlibrary/dmd/src/dmd
D_FLAGS=-m32 -gc -Isrc -w -wi -vtls -nofloat

AS=as
AS_FLAGS=--32 -n32

LD=ld
LD_FLAGS=-m elf_i386 --gc-sections --oformat=binary
LD_FLAGS_DBG=-m elf_i386 --gc-sections

OUTPUT_DIR=output
OBJ_DIR=obj

# Filled in by debug rule
DBG=

KERNEL_OBJECTS=$(shell find src/kernel/ -name '*.[dS]' -o -name '*.di' | sed -e 's/^\(.*\.di\|.*\.[dS]\)$$/obj\/\1.o/g')
# Filtered out in the linker, this must go first in order to boot the kernel
PRE_KERNEL = obj/src/kernel/pre-kernel.S.o

all: utils kernel 

clean:
	/bin/rm -rf $(OBJ_DIR)/*
	/bin/rm -rf $(OUTPUT_DIR)/*
	$(MAKE) -C utils clean

bootloader: $(OUTPUT_DIR)/bootloader.b

.PHONY: utils
utils:
	$(MAKE) -C utils

fancycat: $(OUTPUT_DIR)/FancyCat

$(OUTPUT_DIR)/bootloader.b: 
	$(AS) $(AS_FLAGS) src/boot/bootloader.S -o $(OBJ_DIR)/bootloader.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/bootloader.o -Tsrc/boot/bootloader.ld -o $(OUTPUT_DIR)/bootloader.b

$(OUTPUT_DIR)/FancyCat:
	$(CC) $(C_FLAGS) src/boot/FancyCat.c -o $(OUTPUT_DIR)/FancyCat

# TODO Separate the runtime compilation from the kernels compilation
obj/%.d.o : %.d
	$(DBG) $(DC) $(D_FLAGS) -Isrc/kernel/runtime -c $^ -of$@

obj/%.di.o : %.di
	$(DBG) $(DC) $(D_FLAGS) -Isrc/kernel/runtime -c $^ -of$@

obj/%.S.o : %.S
	$(AS) $(AS_FLAGS) $^ -o $@

bikeshedlib: $(OUTPUT_DIR)/bikeshedlib.a

$(OUTPUT_DIR)/bikeshedlib.a:
	$(DC) $(D_FLAGS) -lib -Isrc/kernel/runtime src/bikeshed-lib/stdlib.d -of$(OUTPUT_DIR)/bikeshedlib.a

.PHONY: kernel debug
debug: DBG+=gdb --args	

debug: kernel

kernel: bootloader fancycat $(KERNEL_OBJECTS) bikeshedlib
	$(LD) $(LD_FLAGS) -T ./src/linker_scripts/kernel.ld $(PRE_KERNEL) $(filter-out $(PRE_KERNEL),$(KERNEL_OBJECTS)) -o $(OUTPUT_DIR)/kernel.b
	$(LD) $(LD_FLAGS_DBG) -T ./src/linker_scripts/kernel.ld $(PRE_KERNEL) $(filter-out $(PRE_KERNEL),$(KERNEL_OBJECTS)) -o $(OUTPUT_DIR)/kernel.o
	$(OUTPUT_DIR)/FancyCat 0x200000 $(OUTPUT_DIR)/kernel.b 
	mv image.dat $(OUTPUT_DIR)/.
	cat $(OUTPUT_DIR)/bootloader.b $(OUTPUT_DIR)/image.dat > $(OUTPUT_DIR)/kernel.bin

emu: kernel qemu

qemu: 
	qemu-system-i386 -s -m 1024 -cpu core2duo -drive file=$(OUTPUT_DIR)/kernel.bin,format=raw,cyls=200,heads=16,secs=63 -monitor stdio -serial /dev/pts/2 -net user -net nic,model=i82559er 
