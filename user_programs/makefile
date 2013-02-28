DC=dmd
D_FLAGS=-m32 -w -wi -vtls -nofloat -I./src/ -I./src/runtime/

LD=ld
LD_FLAGS=-m elf_i386 --gc-sections 

OUTPUT_DIR=./bin
OBJ_DIR=./obj

USER_PROGS=idle/

USER_OBJECTS=$(shell find src/kernel/ -name '*.[dS]' -o -name '*.di' | sed -e 's/^\(.*\.di\|.*\.[dS]\)$$/obj\/\1.o/g')

all: idle

clean:
	/bin/rm -rf $(OBJ_DIR)/*
	/bin/rm -rf $(OUTPUT_DIR)/*

.PHONY: bikeshedlib
bikeshedlib:
	$(DC) $(D_FLAGS) -c ./src/bikeshedlib/stdlib.d -of$(OBJ_DIR)/stdlib.o

startup: bikeshedlib
	$(DC) $(D_FLAGS) -c ./src/startup.d -of$(OBJ_DIR)/startup.o

idle: startup
	$(DC) $(D_FLAGS) -c ./src/idle/idle.d -of./$(OBJ_DIR)/idle/idle.o
	$(LD) $(LD_FLAGS) -T./linker.ld $(OBJ_DIR)/startup.o $(OBJ_DIR)/stdlib.o ./$(OBJ_DIR)/idle/idle.o -o ./$(OUTPUT_DIR)/idle

