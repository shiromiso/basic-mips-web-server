.section .data

system_array:
    .space 48

system_command_part1:
.asciz "/bin/sh"

system_command_part2:
.asciz "-c"

msg_cmd_on:
.asciz "Sending command: LED on\n"

msg_cmd_off:
.asciz "Sending command: LED off\n"

msg_cmd_err:
.asciz "Error: bad command\n"

response_cmd_on:
.asciz "HTTP/1.1 200 OK\nContent-Length: 20\nContent-Type: text/plain; charset=utf-8\n\nSent command: LED on"

response_cmd_off:
.asciz "HTTP/1.1 200 OK\nContent-Length: 21\nContent-Type: text/plain; charset=utf-8\n\nSent command: LED off"

response_cmd_err:
.asciz "HTTP/1.1 500 Internal Server Error\nContent-Length: 18\nContent-Type: text/plain; charset=utf-8\n\nError: bad command"

socket_struct:
.byte 0x02 # sin_family = AF_INET
.byte 0x00
.byte 0x1f # sin_port = 8080
.byte 0x90

.byte 0x00 # sin_addr = 0.0.0.0
.byte 0x00
.byte 0x00
.byte 0x00

.byte 0x30 # sin_zero
.byte 0x30
.byte 0x30
.byte 0x30

.byte 0x30 # sin_zero
.byte 0x30
.byte 0x30
.byte 0x30

read_buf:
.byte 0:300 # 300 bytes, each equal to 0

msg1:
.asciz "Program start\n"

msg2:
.asciz "Program end\n"

command_led_on:
.asciz "echo 1 > /sys/class/leds/green:wps/brightness"

command_led_off:
.asciz "echo 0 > /sys/class/leds/green:wps/brightness"


.section .text

.global __start

__start:
main:
    la $a0, msg1
    jal puts

    # socket(AF_INET, SOCK_STREAM, 0)
    li $a0, 2 # int family   = AF_INET
    li $a1, 2 # int type     = SOCK_STREAM
    li $a2, 0 # int protocol = 0
    li $v0, 4183
    syscall

    # Save socket fd
    move $s0, $v0

    # bind()
    move $a0, $s0      # int fd
    la $a1, socket_struct # struct sockaddr *umyaddr
    li $a2, 16            # int addrlen
    li $v0, 4169
    syscall

    # listen()
    move $a0, $s0      # int fd
    li $a1, 10            # int backlog
    li $v0, 4174
    syscall


	main_loop:
	    # accept()
	    move $a0, $s0  # int fd
	    li $a1, 0      # struct sockaddr *upeer_sockaddr
	    li $a2, 0      # int *upeer_addrlen
	    li $v0, 4168
	    syscall

	    # Save connection fd
	    move $s1, $v0

	    # fgets()
	    move $a0, $s1
	    la $a1, read_buf
	    jal fgets

	    la $t0, read_buf

	    addi $t0, 5
		lb $t1, 0($t0)

		li $t2, 49 # ASCII '1'
		beq $t1, $t2, cmd_on

		li $t2, 48 # ASCII '0'
		beq $t1, $t2, cmd_off

		j cmd_err

		cmd_on:
			la $a0, msg_cmd_on
			jal puts

			move $a0, $s1
			la $a1, response_cmd_on
			jal fputs

    		la $a0, command_led_on
    		jal system

			j cmd_finish

		cmd_off:
			la $a0, msg_cmd_off
			jal puts

			move $a0, $s1
			la $a1, response_cmd_off
			jal fputs

    		la $a0, command_led_off
    		jal system

			j cmd_finish

		cmd_err:
			la $a0, msg_cmd_err
			jal puts

			move $a0, $s1
			la $a1, response_cmd_err
			jal fputs

			j cmd_finish

		cmd_finish:

    	# fputs()
		move $a0, $s1
		la $a1, read_buf
		jal fputs

	    # close() connection fd
	    move $a0, $s1      # int fd
	    li $v0, 4006
	    syscall

		j main_loop


    # close() socket fd
    move $a0, $s0      # int fd
    li $v0, 4006
    syscall

    la $a0, msg2
    jal puts

    li $a0, 13

    move $a0, $v0
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
        move $v0, $t0

        jr $ra


fgets:
	# IN - $a0 - fd
    # IN - $a1 - Buffer address

    addi $sp, $sp, -4
    sw $ra, 0($sp)

	li $a2, 200
    li $v0, 4003
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


fputs:
	# IN - $a0 - fd
    # IN - $a1 - String address

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    addi $sp, $sp, -4
    sw $a0, 0($sp)

	move $a0, $a1
    jal strlen

    lw $a0, 0($sp)
    addi $sp, $sp, 4

    move $a2, $v0

    li $v0, 4004
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


puts:
    # IN - $a0 - String address

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    move $a1, $a0
    li $a0, 1 # stdout
    jal fputs

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
    move $t1, $a0
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
