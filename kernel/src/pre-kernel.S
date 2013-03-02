.code32
.globl pre_kernel
pre_kernel:

	# TODO - Maybe move the kernel higher and
	#        place the stack under the kernel?
	# Setup the kernels stack
	movl $(0x200000-0x4), %esp
	movl %esp, %ebp

	# Clear out the BSS, probably a good idea
	movl $sbss, %eax
	movl $ebss, %ecx
	subl %eax, %ecx

zero_loop:
	cmpl $0, %ecx
	jle done_zeroing
	movl $0, (%eax)
	addl $4, %eax
	subl $4, %ecx
	jmp zero_loop
done_zeroing:

	# Call all of the constructors
	movl $start_of_ctors, %ebx
	jmp check_end_ctors

loop_ctors:
	call *(%ebx)
	add $4, %ebx

check_end_ctors:
	cmpl $end_of_ctors, %ebx
	jne loop_ctors

	# Jump to the kernel
	jmp kmain

	# Call all of the destructors
	movl $start_of_dtors, %ebx
	jmp check_end_dtors

loop_dtors:
	call *(%ebx)
	add $4, %ebx

check_end_dtors:
	cmpl $end_of_dtors, %ebx
	jne loop_dtors

	# Halt, because we can't return to the bootloader
	cli
stop_executing:
	hlt
	jmp stop_executing
/*
.globl _tlsstart
.section .tdata,"awT",@progbits
.align 4
.type _tlsstart, @object
.size _tlsstart, 4
_tlsstart:
	.long 3

.globl _tlsend
.section .tcommon,"awT",@nobits
.align 4
.type _tlsend, object
.size _tlsend, 4
_tlsend:
	.zero 4
	*/
