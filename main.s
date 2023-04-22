.section .text

.global __start

__start:
	li $v0, 4
	la $a0, out_string
	syscall

	li $v0, 4001
	li $a0, 13
	syscall

.section .data
out_string: .asciiz "\nHello, World!\n"
