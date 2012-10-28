CC=gcc
C_FLAG=-Wall -Werror -Wextra -pedantic -std=gnu99

DC=src/dlibrary/dmd/src/dmd
D_FLAGS=-m32 -Isrc -release -w -wi -vtls

SOURCES=src/kernel/kmain.d src/kernel/vga.d

AS=as
AS_FLAGS=--32 -n32

LD=ld
LD_FLAGS=-m elf_i386 --oformat binary

OUTPUT_DIR=output
OBJ_DIR=obj

all: kernel

clean:
	/bin/rm -f $(OBJ_DIR)/*
	/bin/rm -f $(OUTPUT_DIR)/*

bootloader:
	$(AS) $(AS_FLAGS) src/boot/bootloader.S -o $(OBJ_DIR)/bootloader.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/bootloader.o -Tsrc/boot/bootloader.ld -o $(OUTPUT_DIR)/bootloader.b

fancycat:
	$(CC) $(C_FLAGS) src/boot/FancyCat.c -o $(OUTPUT_DIR)/FancyCat

clib:
	$(DC) $(D_FLAGS) -c src/bikeshed-lib/stdlib.d -of$(OBJ_DIR)/stdlib.o 

	#$(LD) -m elf_i386 -Tsrc/linker_scripts/kernel.ld $(OBJ_DIR)/constructors.o $(OBJ_DIR)/kmain.o src/bikeshed-lib/libdruntime-bikeshed32.a $(OBJ_DIR)/stdlib.o $(OBJ_DIR)/vga.o $(OBJ_DIR)/memory.o $(OBJ_DIR)/interrupts.o $(OBJ_DIR)/support-asm.o $(OBJ_DIR)/support.o $(OBJ_DIR)/serial.o -o $(OUTPUT_DIR)/kernel.o 

kernel: clean bootloader fancycat clib
	$(AS) $(AS_FLAGS) src/kernel/constructors.S -o $(OBJ_DIR)/constructors.o		
	$(AS) $(AS_FLAGS) src/kernel/support.S -o $(OBJ_DIR)/support-asm.o
	$(DC) $(D_FLAGS) -c src/kernel/kmain.d -Isrc -of$(OBJ_DIR)/kmain.o
	$(DC) $(D_FLAGS) -c src/kernel/vga.d -of$(OBJ_DIR)/vga.o
	$(DC) $(D_FLAGS) -c src/kernel/interrupts.d -of$(OBJ_DIR)/interrupts.o
	$(DC) $(D_FLAGS) -c src/kernel/paging/memory.d -of$(OBJ_DIR)/memory.o
	$(DC) $(D_FLAGS) -c src/kernel/support.d -of$(OBJ_DIR)/support.o
	$(DC) $(D_FLAGS) -c src/kernel/serial.d -of$(OBJ_DIR)/serial.o
	@echo
	$(LD) $(LD_FLAGS) -Tsrc/linker_scripts/kernel.ld  $(OBJ_DIR)/constructors.o $(OBJ_DIR)/kmain.o   $(OBJ_DIR)/stdlib.o $(OBJ_DIR)/vga.o $(OBJ_DIR)/memory.o $(OBJ_DIR)/interrupts.o $(OBJ_DIR)/support-asm.o $(OBJ_DIR)/serial.o $(OBJ_DIR)/support.o src/bikeshed-lib/libdruntime-bikeshed32.a -o $(OUTPUT_DIR)/kernel.b
	$(OUTPUT_DIR)/FancyCat 0x100000 $(OUTPUT_DIR)/kernel.b
	mv image.dat $(OUTPUT_DIR)/.
	cat $(OUTPUT_DIR)/bootloader.b $(OUTPUT_DIR)/image.dat > $(OUTPUT_DIR)/kernel.bin
	@echo

qemu: kernel
	qemu-system-i386 -m 1024 -cpu core2duo -drive file=$(OUTPUT_DIR)/kernel.bin,format=raw,cyls=200,heads=16,secs=63 -monitor stdio -serial /dev/pts/3 -net user -net nic,model=i82559er -vga vmware
