all: realclean
	as --32 -n32 -o bootloader.o bootloader.S
	ld -m elf_i386 -o bootloader.b --oformat binary -Tbootloader.ld bootloader.o
	gcc -Wall -Werror -Wextra -pedantic -std=gnu99 -o FancyCat FancyCat.c
	gdc -m32 -nodefaultlibs -nostartfiles -nostdlib -fno-bounds-check -c kernel.d -o kernel.o #-ldruntime-bikeshed32
	ld -m elf_i386 -o kernel.b --oformat binary -Tkernel.ld kernel.o libdruntime-bikeshed32.a ../../bikeshed-lib/stdlib.o
	./FancyCat 0x100000 kernel.b 0x200000 textfile
	cat bootloader.b image.dat > kernel.bin

realclean:
	/bin/rm -f *.o
	/bin/rm -f *.b
	/bin/rm -f image.dat
	/bin/rm -f kernel.bin

qemu:
	qemu-system-i386 -m 1024 -cpu core2duo -drive file=kernel.bin,format=raw,cyls=200,heads=16,secs=63 -monitor stdio -net user -net nic,model=i82559er -vga vmware

debug:
	qemu-system-i386 -m 1024 -cpu core2duo -drive file=kernel.bin,format=raw,cyls=200,heads=16,secs=63 -monitor stdio -net user -net nic,model=i82559er -vga vmware -no-kvm
