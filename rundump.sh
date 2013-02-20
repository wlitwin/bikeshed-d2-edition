#!/bin/sh
objdump -D output/kernel.o | ./ddemangle | less
