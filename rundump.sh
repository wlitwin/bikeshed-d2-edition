#!/bin/sh

# Need to build ddemangle in utils/ddmangle.d
objdump -D ./kernel/bin/kernel.o | ./utils/bin/ddemangle | less
