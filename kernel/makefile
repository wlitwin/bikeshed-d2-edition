DC=dmd
D_FLAGS=-m32 -Isrc -w -vtls -nofloat

AS=as
AS_FLAGS=--32 -n32

LD=ld
LD_FLAGS=-m elf_i386 --oformat=binary
LD_FLAGS_DBG=-m elf_i386

OUTPUT_DIR=bin
OBJ_DIR=obj

# Filled in by debug rule
DBG=

KERNEL_OBJECTS=$(shell find src/ -name '*.[ds]' -o -name '*.di' | sed -e 's/^\(.*\.di\|.*\.[ds]\)$$/obj\/\1.o/g')
PRE_KERNEL = $(OBJ_DIR)/src/arch/x86/prekernel.s.o

all: kernel 

clean:
	/bin/rm -rf $(OBJ_DIR)/*
	/bin/rm -rf $(OUTPUT_DIR)/*

# TODO Separate the runtime compilation from the kernels compilation
$(OBJ_DIR)/%.d.o : %.d
	$(DBG) $(DC) $(D_FLAGS) -Isrc/runtime -c $^ -of$@

$(OBJ_DIR)/%.s.o : %.s
	mkdir -p $(shell dirname $@)
	$(AS) $(AS_FLAGS) $^ -o $@

.PHONY: kernel debug
debug: DBG+=gdb --args	

debug: kernel

kernel: $(KERNEL_OBJECTS)
	$(LD) $(LD_FLAGS) -T ./kernel.ld $(PRE_KERNEL) $(filter-out $(PRE_KERNEL),$(KERNEL_OBJECTS)) -o $(OUTPUT_DIR)/kernel.b
	$(LD) $(LD_FLAGS_DBG) -T ./kernel.ld $(PRE_KERNEL) $(filter-out $(PRE_KERNEL),$(KERNEL_OBJECTS)) -o $(OUTPUT_DIR)/kernel.o
