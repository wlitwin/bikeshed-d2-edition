#!/bin/sh

# Need to build ddemangle in utils/ddmangle.d
objdump -D output/kernel.o | ./utils/bin/ddemangle | less
