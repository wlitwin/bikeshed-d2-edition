ARG1 = 8  /* offset to the first argument */
ARG2 = 12 /* offset to the second argument */

.globl __inb
__inb:
	enter $0, $0
	xorl %eax, %eax       /* Clear the high order bytes of eax */
	movl ARG1(%ebp), %edx /* Move the port number into edx */
	inb (%dx)             /* Get a byte from the port into %al */
	leave
	ret

.globl __inw
__inw:
	enter $0, $0
	xorl %eax, %eax       /* Clear the high order bytes of eax */
	movl ARG1(%ebp), %edx /* Move the port number into edx */
	inw (%dx)             /* Get a word from the port into %al */
	leave
	ret

.globl __inl
__inl:
	enter $0, $0
	xorl %eax, %eax       /* Clear the high order bytes of eax */
	movl ARG1(%ebp), %edx /* Move the port number into edx */
	inl (%dx)             /* Get a dword from the port into %al */
	leave
	ret

.globl __outb
__outb:
	enter $0, $0
	movl ARG1(%ebp), %edx /* Get the port number into edx */
	movl ARG2(%ebp), %eax /* Get the value into eax */
	outb (%dx)            /* Output the byte to the port */
	leave
	ret

.globl __outw
__outw:
	enter $0, $0
	movl ARG1(%ebp), %edx /* Get the port number into edx */
	movl ARG2(%ebp), %eax /* Get the value into eax */
	outw (%dx)            /* Output the word to the port */
	leave
	ret

.globl __outl
__outl:
	enter $0, $0
	movl ARG1(%ebp), %edx /* Get the port number into edx */
	movl ARG2(%ebp), %eax /* Get the value into eax */
	outl (%dx)
	leave
	ret
