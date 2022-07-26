.data
	file: .asciiz "input_demo.txt"
	buffer: .space 2048
	
	victory_msg: .asciiz "You won!"
	
	blue: .word 0x0000ff
	black: .word 0x000000
	yellow: .word 0xffff00 
	green: .word 0x00ff00
	red: .word 0xff0000
	white: .word 0xffffff
	
.text
initialize:
### reads input file and draws maze###
    # read file to buffer
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 24	# allocate 24 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s2, -8($fp)	# save locally used registers
	sw	$s3, -12($fp)
	sw $s6, -16($fp)
	sw $s7, -20($fp)
	
	
	li $v0, 13 # get ready to open file
	la $a0, file
	li $a1, 0 # read only
	li $a2, 0 # ignore
	syscall
	
	move $s6, $v0 # the file descriptor
	
	li $v0, 14 # get ready to read from file
	move $a0, $s6 # load the file descriptor
	la $a1, buffer # address of buffer to which to load the contents
	li $a2, 2048 # 2048=max number of characters=size of the buffer
	syscall
	
	li $t1, 0 # t1 is the offset
	
	addi $t4, $zero, -1 # t4 = iterator
	addi $s2, $zero, 0 # s2 = column
	addi $s3, $zero, 0 # s3 = row
	
	move $s7, $gp # saving gp in a register as it is gonna be overwritten later on
	

	li $t8, 1 # we will be using $t8 to hold the height of the maze 
	li $t9, 0 # we will be using $t9 to hold the width of the maze 
	
	jal character_loop
	
	
	lw	$s7, -20($fp)	# reset saved registers
	lw    $s6, -16($fp)
	lw    $s3, -12($fp)
	lw	$s2, -8($fp)
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
	
	character_loop:
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 12	# allocate 24 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s2, -8($fp)	# save locally used registers
	
	###loops over each character in the buffer###
	la $t2, buffer # loading the address of the buffer
	add $t2, $t2, $t1 # incrementing the address by the offset
	lb $t3, ($t2) # t3 is the next character in the buffer
	addi $t1, $t1, 1 # increment the offset
	
	mul $t5, $t1, 4 # t5 is the offset in bytes (rather than words)
	add $t6, $gp, $t5 # t6 is the next pixel
	addi $t0, $t0, 4 # setting the iterator to the next pixel too
	
	addi $s2, $s2, 1 # going to the next column
	
	beq $t3, 119, color_blue # w
	beq $t3, 112,  color_black # p
	beq $t3, 115, color_yellow # s
	beq $t3, 117,  color_green # u
	beq $t3, 10, next_line # \n
	beq $t3, 101,  color_red # e
	beq $t3, 99, color_white # c
	
	beq $t3, $zero, reset_gp # nothing left in the buffer so we can close it
	
	j character_loop 
	
	lw	$s2, -8($fp)
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
	

	#  put the right color in memory (in $t3)
	color_blue:
		lw $t3, blue
		j color
	color_black:
		lw $t3, black
		j color
	color_yellow:
		move $s4, $s2 # storing the player's x-pos in $s4
		move $s5, $s3 # storing the player's y-pos in $s5
		lw $t3, yellow
		j color
	color_green:
		lw $t3, green
		j color
	color_red:
		lw $t3, red
		j color
	color_white:
		lw $t3, white
		j color
	next_line:
		addi $s3, $s3, 1 # incrementing the row   
		li $s2, 0 # resetting the column
		
		addi $t8, $t8, 1# incrementing the height of the maze
	
		subi $gp, $gp, 4 # go one pixel back
	
		j character_loop

	# draws the pixel with it's appropriate color
	color:
		addi $t9, $t9, 1 # incrementing the width of the maze 
		
		sw $t3, -4($t6)
		j character_loop
	
update_player_pos:
	### takes in the old coordinates ($a2, $a3) and new coordinates ($a0, $a1) and returns the new position if valid ###
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 36	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s4, -8($fp)	# save locally used registers
	sw	$s5, -12($fp)	
	sw $s6, -16($fp)
	sw $s0, -20($fp)
	sw $s1, -24($fp)
	sw $s2, -28($fp)
	sw $s3, -32($fp)
	
	move $s0, $a0 # new row
	move $s1, $a1 # new col
	move $s2, $a2 # cur row
	move $s3, $a3 # cur col
	
	
	jal conversion # $s6 now contains the address of the new pos
	
	lw $t4, -4 ($v0) # $t4 now contains the color of that pixel
	
	beq $t4, 0x0000ff, game_loop # if the new pos is a wall, we don't do anything
	
	move $s4, $a0 # updating the player's x-pos in $s4
	move $s5, $a1 # updating the player's y-pos in $s5
	
	lw $t3, yellow
	sw $t3, -4($v0)
	
	move $a0, $a2
	move $a1, $a3
	
	jal conversion # $s6 now contains the address of the old pos
	
	lw $t3, black 
	sw $t3, -4($v0) # making the old pos a passage again
	
	beq $t4, 0x00ff00, victory

	j game_loop
	
	lw	$s5, -12($fp)	
	lw $s6, -16($fp)
	lw $s0, -20($fp)
	lw $s1, -24($fp)
	lw $s2, -28($fp)
	lw $s3, -32($fp)
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
	
	
conversion: 
	### takes in a coordinate (x=$a0, y=$a1) and returns it's address in memory (in $s6) ###
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 20	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw $s6, -16($fp)
	
	move $t0, $a0 # x-coordinate
	move $t1, $a1 # y-coordinate
	
	move $t3, $t9 # moving the width 
	mul $t2, $t1, $t3 # r=y*width
	
	add $t2, $t2, $t0 # r=y*width + x
	
	sll $t2, $t2, 2 # r=y*width + x *4
	
	add $t2, $t2,  $gp
	
	move $v0, $t2
	
	lw $s6, -16($fp) # reset saved registers
	lw	$s1, -12($fp)	
	lw	$s0, -8($fp)	
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

	
reset_gp:
	div $t9, $t9, $t8 # row-width = total width/height
	move $gp, $s7  # loading back the original gp
	j game_loop
	
			
game_loop:
### manages the game ###

#  a ) check for input
	lw $t0, 0xffff0000 # $t0=0 when no input available, $t0=1 when there is an input available

    li $a0, 60    
    li $v0, 32  # sleep for 60 ms
    syscall
    
    beq $t0, 1, handle_input# $t0=1 when an input has been given
    
    j game_loop

	handle_input:
		lw $a0,0xffff0004 
	
		beq $a0, 119, up # 119=ascii code for w
		beq $a0, 97, left # 97=ascii code for a
		beq $a0, 115, down #115=ascii code for s
		beq $a0, 100, right # 110=ascii code for d
		
		beq $a0, 120, exit # 120=ascii code for x
		
		j game_loop
		
	up:
		# up means decrement the row but keep the same column
	    move $a0, $s4
	    subi $a1, $s5, 1
	
	    j take_action # the new positions have been determined (they're used as arguments $a0, $a1 for take_action)
		    
	left:
	    # left means decrement the column but keep the same row
	    subi $a0, $s4, 1
	    move $a1, $s5
	
	    j take_action # the new positions have been determined (they're used as arguments $a0, $a1 for take_action)
	    
	down:
	    # down means increment the row but keep the same column
	    move $a0, $s4
	    addi $a1, $s5, 1
	
	    j take_action # the new positions have been determined (they're used as arguments $a0, $a1 for take_action)	
	    
	right:
		# right means increment the column but keep the same row
	    addi $a0, $s4, 1
	    move $a1, $s5
	
	    j take_action # the new positions have been determined (they're used as arguments $a0, $a1 for take_action)
			
#  take action
	take_action:
		# $a0 and $a1 contain the new pos
		move $a2, $s4 # current x-pos
		move $a3,  $s5 # current y-pos
		
		jal update_player_pos
		
#  display victory
	victory:
		li $v0, 4
		la $a0, victory_msg
		syscall
		
		j exit
		
exit:
	li $v0, 10
	syscall
