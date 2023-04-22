.section .data

system_array:
	.space 48

system_command_part1:
.asciz "/bin/sh"

system_command_part2:
.asciz "-c"

msg1:
.asciz "Before\n"

msg2:
.asciz "After\n"

command:
.asciz "/bin/echo Hello; echo Bye"

.section .text

.global __start

__start:
main:
	la $a0, msg1
	jal puts

	la $a0, command
	jal system

	la $a0, msg2
	jal puts

	li $a0, 13
	jal exit

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

system:
	# IN - $a0 - Command to run

	addi $sp, $sp, -4
	sw $ra, 0($sp)	

	addi $t0, $zero, 0
	la $t1, system_command_part1
	sw $t1, system_array($t0)

	addi $t0, $t0, 4
	la $t1, system_command_part2
	sw $t1, system_array($t0)

	# Load command from argument
	addi $t0, $t0, 4
	addi $t1, $zero, 0
	or $t1, $t1, $a0
	sw $t1, system_array($t0)

	addi $t0, $t0, 4
	addi $t1, $zero, 0
	sw $t1, system_array($t0)

	# fork()
	li $v0, 4002
	syscall

	# On parent, just return
	bne $v0, $zero, system_exit

	# On child, do execve()
	la $a0, system_command_part1 # Command
	la $a1, system_array         # Arguments
	addi $a2, $zero, 0           # Environment
	li $v0, 4011
	syscall

	system_exit:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

exit:
	li $v0, 4001
	syscall

	jr $ra
