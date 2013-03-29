/* This file provides the implementation for the
 * x86 port functions. support.d defines the interfaces
 * for this functions so they can be imported by
 * other modules.
 *
 * These functions allows data to be exchanged through
 * the port address space, which is separate from the
 * virtual address space.
 */

ARG1 = 8  /* Offset to first argument */
ARG2 = 12 /* Offset to second argument */

/* Read a byte (8-bits) of data from a port */
.globl inb
inb:
	enter $0, $0
	xorl %eax, %eax
	movl ARG1(%ebp), %edx
	inb (%dx)
	leave
	ret

/* Read a word (16-bits) of data from a port */
.globl inw
inw:
	enter $0, $0
	xorl %eax, %eax
	movl ARG1(%ebp), %edx
	inw (%dx)
	leave
	ret

/* Read a dword (32-bits) of data from a port */
.globl inl
inl:
	enter $0, $0
	xorl %eax, %eax
	movl ARG1(%ebp), %edx
	inb (%dx)
	leave
	ret

/* Write a byte (8-bits) of data to a port */
.globl outb
outb:
	enter $0, $0
	movl ARG1(%ebp), %edx
	movl ARG2(%ebp), %eax
	outb (%dx)
	leave
	ret

/* Write a word (16-bits) of data to a port */
.globl outw
outw:
	enter $0, $0
	movl ARG1(%ebp), %edx
	movl ARG2(%ebp), %eax
	outw (%dx)
	leave
	ret

/* Write a dword (32-bits) of data to a port */
.globl outl
outl:
	enter $0, $0
	movl ARG1(%ebp), %edx
	movl ARG2(%ebp), %edx
	outl (%dx)
	leave
	ret
