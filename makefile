CC=gcc
C_FLAG=-Wall -Werror -Wextra -pedantic -std=gnu99

DC=src/dlibrary/dmd/src/dmd
D_FLAGS=-m32 -Isrc -release -w -wi -vtls

AS=as
AS_FLAGS=--32 -n32

LD=ld
LD_FLAGS=-m elf_i386 --gc-sections --oformat=binary

OUTPUT_DIR=output
OBJ_DIR=obj
LIBRARIES=./src/bikeshed-lib/libdruntime-bikeshed32.a

all: kernel

clean:
	/bin/rm -rf $(OBJ_DIR)/*
	/bin/rm -rf $(OUTPUT_DIR)/*

bootloader:
	$(AS) $(AS_FLAGS) src/boot/bootloader.S -o $(OBJ_DIR)/bootloader.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/bootloader.o -Tsrc/boot/bootloader.ld -o $(OUTPUT_DIR)/bootloader.b
	/bin/rm -f $(OBJ_DIR)/bootloader.o

fancycat:
	$(CC) $(C_FLAGS) src/boot/FancyCat.c -o $(OUTPUT_DIR)/FancyCat

clib:
	$(DC) $(D_FLAGS) -c src/bikeshed-lib/stdlib.d -of$(OBJ_DIR)/stdlib.o 

#$(LD) -m elf_i386 -Tsrc/linker_scripts/kernel.ld $(OBJ_DIR)/pre-kernel.o $(OBJ_DIR)/kmain.o src/bikeshed-lib/libdruntime-bikeshed32.a $(OBJ_DIR)/stdlib.o $(OBJ_DIR)/vga.o $(OBJ_DIR)/memory.o $(OBJ_DIR)/interrupts.o $(OBJ_DIR)/support-asm.o $(OBJ_DIR)/support.o $(OBJ_DIR)/serial.o -o $(OUTPUT_DIR)/kernel.o 

kernel: clean bootloader fancycat clib
	$(AS) $(AS_FLAGS) src/kernel/pre-kernel.S -o $(OBJ_DIR)/pre-kernel.o		
	$(DC) $(D_FLAGS) -c src/kernel/kmain.d -Isrc -of$(OBJ_DIR)/kmain.o
	$(AS) $(AS_FLAGS) src/kernel/layer0/support.S -o $(OBJ_DIR)/support-asm.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/vga.d -of$(OBJ_DIR)/vga.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/interrupts.d -of$(OBJ_DIR)/interrupts.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/memory.d -of$(OBJ_DIR)/memory.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/iPhysicalAllocator.d -of$(OBJ_DIR)/iPhysicalAllocator.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/basicVirtualAllocator.d -of$(OBJ_DIR)/basicVirtualAllocator.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/templates.d -of$(OBJ_DIR)/templates.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/iVirtualAllocator.d -of$(OBJ_DIR)/iVirtualAllocator.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/bitmapAllocator.d -of$(OBJ_DIR)/bitmapAllocator.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/util.d -of$(OBJ_DIR)/util.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/support.d -of$(OBJ_DIR)/support.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/serial.d -of$(OBJ_DIR)/serial.o
	$(DC) $(D_FLAGS) -c src/kernel/layer0/memory/malloc.d -of$(OBJ_DIR)/kmalloc.o
	$(DC) $(D_FLAGS) -c src/kernel/layer1/clock.d -of$(OBJ_DIR)/clock.o
	$(DC) $(D_FLAGS) -c src/kernel/layer1/linkedlist.d -of$(OBJ_DIR)/linkedlist.o
	$(DC) $(D_FLAGS) -c src/kernel/layer1/process/pcb.d -of$(OBJ_DIR)/pcb.o
	$(DC) $(D_FLAGS) -c src/kernel/layer1/process/scheduler.d -of$(OBJ_DIR)/scheduler.o
	$(DC) $(D_FLAGS) -c src/kernel/layer1/syscall/syscalls.d -of$(OBJ_DIR)/syscalls.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/typeinfo/* -of$(OBJ_DIR)/typeinfo.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/object_.d -of$(OBJ_DIR)/object.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/minfo.d -of$(OBJ_DIR)/minfo.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/util/console.d -of$(OBJ_DIR)/rt-console.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/util/string.d -of$(OBJ_DIR)/rt-string.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/extra.d -of$(OBJ_DIR)/rt-extra.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/util/hash.d -of$(OBJ_DIR)/rt-hash.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/llmath.d -of$(OBJ_DIR)/rt-llmath.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/arraycast.d -of$(OBJ_DIR)/rt-arraycast.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/cast_.d -of$(OBJ_DIR)/rt-cast_.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/lifetime.d -of$(OBJ_DIR)/rt-lifetime.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/cmath2.d -of$(OBJ_DIR)/rt-cmath2.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/monitor_.d -of$(OBJ_DIR)/rt-monitor_.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/alloca.d -of$(OBJ_DIR)/rt-alloca.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/deh2.d -of$(OBJ_DIR)/rt-deh2.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/core/memory.d -of$(OBJ_DIR)/core-memory.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/adi.d -of$(OBJ_DIR)/rt-adi.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/util/utf.d -of$(OBJ_DIR)/rt-utf.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/aaA.d -of$(OBJ_DIR)/rt-aaA.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/memset.d -of$(OBJ_DIR)/rt-memset.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/rt/aApply.d -of$(OBJ_DIR)/rt-aApply.o
	$(DC) $(D_FLAGS) -Isrc/kernel/runtime -c src/kernel/runtime/core/stdc/stdarg.d -of$(OBJ_DIR)/core-stdarg.o
	@echo
	
	cd $(OBJ_DIR); $(LD) $(LD_FLAGS) -T../src/linker_scripts/kernel.ld pre-kernel.o kmain.o stdlib.o vga.o memory.o interrupts.o serial.o support-asm.o support.o iPhysicalAllocator.o bitmapAllocator.o iVirtualAllocator.o basicVirtualAllocator.o util.o clock.o templates.o kmalloc.o linkedlist.o pcb.o scheduler.o syscalls.o typeinfo.o object.o minfo.o rt-console.o rt-string.o rt-extra.o rt-hash.o rt-llmath.o rt-arraycast.o rt-cast_.o rt-lifetime.o rt-cmath2.o rt-monitor_.o rt-alloca.o rt-deh2.o core-memory.o rt-adi.o rt-utf.o rt-aaA.o rt-memset.o rt-aApply.o core-stdarg.o  -o ../$(OUTPUT_DIR)/kernel.b
	cd $(OBJ_DIR); $(LD) -m elf_i386 --gc-sections -T../src/linker_scripts/kernel.ld pre-kernel.o kmain.o stdlib.o vga.o memory.o interrupts.o serial.o support-asm.o support.o iPhysicalAllocator.o bitmapAllocator.o iVirtualAllocator.o basicVirtualAllocator.o util.o clock.o templates.o kmalloc.o linkedlist.o pcb.o scheduler.o syscalls.o typeinfo.o object.o minfo.o rt-console.o rt-string.o rt-extra.o rt-hash.o rt-llmath.o rt-arraycast.o rt-cast_.o rt-lifetime.o rt-cmath2.o rt-monitor_.o rt-alloca.o rt-deh2.o core-memory.o rt-adi.o rt-utf.o rt-aaA.o rt-memset.o rt-aApply.o core-stdarg.o  -o ../$(OUTPUT_DIR)/kernel.o
	$(OUTPUT_DIR)/FancyCat 0x100000 $(OUTPUT_DIR)/kernel.b
	mv image.dat $(OUTPUT_DIR)/.
	cat $(OUTPUT_DIR)/bootloader.b $(OUTPUT_DIR)/image.dat > $(OUTPUT_DIR)/kernel.bin
	@echo

qemu: kernel
	qemu-system-i386 -m 1024 -cpu core2duo -drive file=$(OUTPUT_DIR)/kernel.bin,format=raw,cyls=200,heads=16,secs=63 -monitor stdio -serial /dev/pts/1 -net user -net nic,model=i82559er -vga vmware
