.section .data

welcome_msg:
.asciz "Embedded HTTP Server started\n\n"

.section .text

.global __start

__start:
main:
	la $a0, welcome_msg
	jal puts

	li $a0, 13
	jal exit

exit:
	li $v0, 4001
	syscall

	jr $ra

strlen:
	# IN - $a0 - String address
	# OUT - $v0 - String length

	addi $t0, $zero, 0

	strlen_while:
		lb $t1, 0($a0)

		beq $t1, $zero, strlen_exit
		bge $t0, 200, strlen_exit

		addi $t0, $t0, 1
		addi $a0, $a0, 1

		j strlen_while

	strlen_exit:
		addi $v0, $zero, 0
		or $v0, $v0, $t0

		jr $ra

puts:
	# IN - $a0 - String address

	addi $sp, $sp, -4
	sw $ra, 0($sp)

	addi $sp, $sp, -4
	sw $a0, 0($sp)

	jal strlen

	lw $a0, 0($sp)
	addi $sp, $sp, 4

	# Load length into a2
	addi $a2, $zero, 0
	or $a2, $a2, $v0

	# Load address into a1
	addi $a1, $zero, 0
	or $a1, $a1, $a0

	li $v0, 4004
	li $a0, 1
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
