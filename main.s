.section .data

msg:
.asciz "Hello World!\n"

.section .text

.global __start

__start:
main:
	jal print
	jal exit

exit:
	li $v0, 4001
	li $a0, 13
	syscall

	jr $ra

print:
	li $v0, 4004
	li $a0, 1
	la $a1, msg
	li $a2, 13
	syscall

	jr $ra
