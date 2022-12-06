.data
	rules: .asciiz "Enter the number from 1 to 7 to place your character.\nPlayer 1 will go first.\nPlayer 1 type 1 for O, 2 for X (Default Player 1: X,Player 2: O): "
	index: .asciiz "1|2|3|4|5|6|7\n"
	matrix: .space 42 
	ful_col: .asciiz "Column is full! Please try another column\n"
	player1_pen: .asciiz "Player 1's trials remain: "
	player2_pen: .asciiz "Player 2's trials remain: "
	player1_move: .asciiz "Enter player 1's move: " 
	player2_move:  .asciiz "Enter player 2's move: " 
	player1_win:	.asciiz "CONGRATULATIONS! PLAYER 1 WINS!"
	player2_win: .asciiz "CONGRATULATIONS! PLAYER 2 WINS!"
	tie: .asciiz "NO MOVE LEFT. IT'S A TIE!"
	undo_remain_1:.asciiz "Player 1's undo: "
	undo_remain_2:.asciiz "Player 2's undo: "
	undo_input: .asciiz "Do you want to undo? Type 'y' for yes, type any key for no: "
	tab: .asciiz "	"
	dash: .asciiz "------------------------------\n"
	invalid_input: .asciiz "Invalid input! Please try again: "
	invalid_placement: .asciiz " => Invalid player's move! Please try again!"
	
.text
				###ASCII TABLE
# 				' ' = 32
# 				'\n' = 10
# 				'*' = 42
#				'Y' = 89
#				'y' = 121
# 			        '0' -> '7' = 48 to 55
##############################################
main:
	# Declare variables
	addi $s0,$0,42	# Empty slots remain
	addi $s1,$0,3		# Player 1's trials
	addi $s2,$0, 3	# Player 2's trials
	addi $s3,$0,0 	# Last inserted address
	addi $s4,$0,3		# Player 1's undos
	addi $s5,$0,3		# Player 2's undos
	la $a3,matrix		# Base matrix
	# Display rules
	li $v0,4
	la $a0,rules
	syscall
	# Get set-token input
	get_token:
	li $v0,12
	syscall
	# Print newline		
	addi $a0,$v0,-48
	# If valid input then jump to pass
	beq $a0,1,pass
	beq $a0,2,pass
	# If invalid input found, repeat until input satisfies
	li $v0,11
	li $a0,10
	syscall	
	li $v0,4
	la $a0,invalid_input
	syscall
	j get_token
	
	pass:
	# Set player token	
	jal set
	
	# Newline
	li $v0,11
	li $a0,10
	syscall
	
	# Initialize empty 6x7 matrix and print it
	jal init_matrix	
	jal print_matrix
	    	
    	# Main loop - GAME START
	jal while_game
	
##############################################					
end:
	li $v0,10
	syscall	
	
##############################################				
while_game:   
        #@@@@@@@@@@@@@@@@@@@@@@@@@@@ PLAYER 1
	PLAYER_1:
      	# Display input message for player 1
	li $v0,4
	la $a0,player1_move
	syscall
	# Get index from player 1
	li $v0,12
	syscall
	move $a0,$a1
	# Player 1's turn
	jal player_go
	# Newline
	li $v0,11
	li $a0,10
	syscall
	# FINISHING WORKS
	jal print_matrix	# Print matrix
	move $a0,$a1
	jal check_win_player	# Check if player 1 win	
	beq $s0,0,player_tie	# Check if game is tie
	move $a0,$a1
	beq $s4,0, PLAYER_2	# If player 1 can undo then ask
      	jal player_undo
      
      #@@@@@@@@@@@@@@@@@@@@@@@@@@@ PLAYER 2
      	PLAYER_2:
      	# Display input message for player 2
	li $v0,4
	la $a0,player2_move
	syscall
	# Get index from player 2
	li $v0,12
	syscall
	move $a0,$a2
	# Player 2's turn
	jal player_go
	# Newline
	li $v0,11
	li $a0,10
	syscall
	# FINISHING WORKS
	jal print_matrix	# print matrix
	move $a0,$a2
	jal check_win_player	# Check if player 2 win
	beq $s0,0,player_tie	# Check if game is tie
	move $a0,$a2	
	beq $s5,0, while_game	# If player 2 can undo then ask	
	jal player_undo
	j while_game		
					
##############################################
set:
	bne $a0,1,set_default
	la $a1,'O'
	la $a2,'X'
	jr $ra
set_default:
	la $a1,'X'
	la $a2,'O'
	jr $ra
	
###############################################
player_go:	# v0 = j ,  a0 = player 's token
	# Check if input is valid index
	move $t0,$a0
	addi $t2,$0,49
	slt $t1, $v0, $t2
	beq $t1,1, invalid_move
	addi $t2,$0,56
	slt $t1, $v0, $t2   
	beq $t1,0, invalid_move    
	# Get matrix[nRow][j]
	addi $t0,$v0,-14	
	if:
	    add $t1,$t0,$a3 	# Load matrix[i][j]
	    lb $t2, ($t1)	# Get token at matrix[i][j]
	    bne  $t2,	42, else	# If matrix[i][j] not empty, do else condition
	    sb $a0,($t1)	# Save player's token to matrix[i][j]
	    move $s3, $t1	# Save last address
	    addi $s0,$s0,-1
	    jr $ra		# Exit function
	else:    		
	    addi $t0,$t0,-7	# Get matrix[i-1][j]
	    # If index still in bound, jump if
	    slt $t2,$t0,$0	
	    beq $t2,0,if
	    # If index out of bound, throw error	
	    move $t0,$a0	# Move data of current player
	    		error_full_col:
				li $v0,11
				li $a0,10
				syscall
				# Display error message
				li $v0,4
				la $a0,ful_col
				syscall
	    identify_player:
	    beq $t0,$a1,punish_player1
	    beq $t0,$a2,punish_player2
	    		  punish_player1:
	    		  	# If player 1 has no trial left, player 2 wins
	    		  	beq $s1,0,congrat_player2
	    		  	# Else decrease player 1's trials by 1
	    		  	addi $s1,$s1,-1
	    		  	# Display player's 1 remaining trials
	    		  	li $v0,4
	    		  	la $a0,player1_pen
	    		  	syscall
    	    			la $v0,1
    	    			move $a0,$s1
    	    			syscall
    	    			# Print newline
				li $v0,11
				li $a0,10
				syscall
    	    			# Display input message for player 1
				li $v0,4
				la $a0,player1_move
				syscall
				# Get retry index from player 1
				li $v0,12
				syscall
    	    			move $a0,$t0
    	    			j player_go
    	    		punish_player2:
    	    			# If player 2 has no trial left, player 1 wins
	    		  	beq $s2,0,congrat_player1
	    		  	# Else decrease player 2's trials by 1
	    		  	addi $s2,$s2,-1
	    		  	# Display player's 2 remaining trials
	    		  	li $v0,4
	    		  	la $a0,player2_pen
	    		  	syscall
    	    			la $v0,1
    	    			move $a0,$s2
    	    			syscall
    	    			# Print newline
				li $v0,11
				li $a0,10
				syscall
    	    			# Display input message for player 2
				li $v0,4
				la $a0,player2_move
				syscall
				# Get retry index from player 2
				li $v0,12
				syscall
    	    			move $a0,$t0
    	    			j player_go    
    	    		invalid_move:
    	    			li $v0,4
    	    			la $a0,invalid_placement
    	    			syscall
    	    			# Newline
				li $v0,11
				li $a0,10
				syscall
				j identify_player 

##############################################			      									      									      						
player_undo:	# a0 = player's token
	move $t0,$a0
	li $v0,4
	la $a0,undo_input
	syscall
	li $v0,12
	syscall
	beq $v0,89,continue	# If Y is typed
	beq $v0,121,continue	# If y is typed
	li $v0,11
	li $a0,10
	syscall
	jr $ra		# Else player do not want to undo, exit
	continue:
	addi $s0,$s0,1
	beq $t0,$a1,player1_undo
	beq $t0,$a2,player2_undo
			player1_undo:
			      addi $s4,$s4,-1	# Decrease undo chances
			      la $a0,'*'
			      sb $a0,($s3)	# Store last accessed cell to *
			      li $v0,11
			      la $a0,10
			      syscall
			      jal print_matrix
			      j PLAYER_1	# Exit
			player2_undo:
		 	      addi $s5,$s5,-1	# Decrease undo chances
			      la $a0,'*'	
			      sb $a0,($s3)	# Store last accessed cell to *
			      li $v0,11
			      la $a0,10
			      syscall
			      jal print_matrix
			      j PLAYER_2	# Exit	
			      		      									      									      									      						
##############################################																																																							
init_matrix:
	la $a3,matrix
	addi $t0,$0,0	# Let i = 0
	init:
	add $t1,$t0,$a3	# i = base + i
	# Store byte
	la $t2,'*'
	sb $t2,($t1)	
	# Increase loop index and compare condition
	addi $t0,$t0,1
	bne $t0,42, init
	# exit init function
	jr $ra
	
##############################################
print_matrix:
	move $t0,$a0	
	li $v0,4
	la $a0,dash
	syscall
	li $v0,4 
	la $a0,undo_remain_1
	syscall
	li $v0,1
	move $a0,$s4
	syscall
	li $v0,4 
	la $a0,tab
	syscall
	li $v0,4 
	la $a0,undo_remain_2
	syscall
	li $v0,1
	move $a0,$s5
	syscall
	li $v0,11
	la $a0,10
	syscall
	## matrix[i][n] = i * 7 + j	
	move $a0,$t0
	addi $t0,$0,0		# Let i = 0
	for_i:
	addi $t1,$0,0		# Let j = 0
		for_j:		
		mul $t3,$t0,7		# i*7
		add $t3,$t3,$t1	# + j
		add $t3, $t3,$a3	# matrix[i][j]
		# Print matrix[i][j]
		li $v0,11
		lb $a0,($t3)
		syscall
		# Whitespace
		li $v0,11
		li $a0,32
		syscall
		# Increase loop index and compare condition
		addi $t1,$t1,1
		bne $t1,7,for_j
	# Newline
	li $v0,11
	li $a0,10
	syscall
	# Increase loop index and compare condition	
	addi $t0,$t0,1
	bne $t0,6,for_i
	# Print index
	li $v0,4
	la $a0,index
	syscall		
	# Exit print function
	jr $ra

##############################################
check_win_player:	# a0 = player's token

	# Vertical check
	addi $t0,$0,0		# let i = 0
	vertical1:
	addi $t1,$0,0		# let j = 0
		vertical2:
		mul $t3,$t0,7 	# i*7
		add $t3,$t3,$t1	# + j
		add $t3, $t3,$a3	# matrix[i][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_vertical2	# If matrix[i][j] !=a0 then continue
		addi $t3, $t3, 7	# matrix[i+1][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_vertical2 # If matrix[i+1][j] !=a0 then continue
		addi $t3, $t3, 7	# matrix[i+2][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_vertical2 # If matrix[i+2][j] !=a0 then continue
		addi $t3, $t3, 7	# matrix[i+3][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_vertical2 # If matrix[i+3][j] !=a0 then continue
		j exit_true
		end_vertical2:
		addi $t1,$t1,1
		bne $t1,7,vertical2	# j go from 0 to 6
	addi $t0,$t0,1	
	bne $t0,3, vertical1		# i go from 0 to 2
	
	# Main diagonal check
	addi $t0,$0,0		# let i = 0
	diagonal1:
	addi $t1,$0,0		# let j = 0
		diagonal2:
		mul $t3,$t0,7 	# i*7
		add $t3,$t3,$t1	# + j
		add $t3, $t3,$a3	# matrix[i][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal2	# If matrix[i][j] !=a0 then continue
		addi $t3, $t3, 8	# matrix[i+1][j+1]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal2  # If matrix[i+1][j+1] !=a0 then continue
		addi $t3, $t3, 8	# matrix[i+2][j+2]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal2  # If matrix[i+2][j+2] !=a0 then continue
		addi $t3, $t3, 8	# matrix[i+3][j+3]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal2  # If matrix[i+3][j+3] !=a0 then continue
		j exit_true
		end_diagonal2:
		addi $t1,$t1,1
		bne $t1,4,diagonal2	# j go from 0 to 3
	addi $t0,$t0,1	
	bne $t0,3, diagonal1		# i go from 0 to 2
	
	# Anti diagonal check
	addi $t0,$0,0		# let i = 0
	diagonal3:
	addi $t1,$0,3		# let j = 3
		diagonal4:
		mul $t3,$t0,7 	# i*7
		add $t3,$t3,$t1	# + j
		add $t3, $t3,$a3	# matrix[i][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal4	# If matrix[i][j] !=a0 then continue
		addi $t3, $t3, 6	# matrix[i+1][j-1]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal4  # If matrix[i+1][j-1] !=a0 then continue
		addi $t3, $t3, 6	# matrix[i+2][j-2]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal4  # If matrix[i+2][j-2] !=a0 then continue
		addi $t3, $t3, 6	# matrix[i+3][j-3]
		lb $t4, ($t3)
		bne $t4,$a0, end_diagonal4  # If matrix[i+3][j-3] !=a0 then continue
		j exit_true
		end_diagonal4:
		addi $t1,$t1,1
		bne $t1,7,diagonal4	# j go from 3 to 6
	addi $t0,$t0,1	
	bne $t0,3, diagonal3		# i go from 0 to 2
	
	# Horizontal check
	addi $t0,$0,0		# let i = 0
	horizontal1:
	addi $t1,$0,0		# let j = 0
		horizontal2:
		mul $t3,$t0,7 	# i*7
		add $t3,$t3,$t1	# + j
		add $t3, $t3,$a3	# matrix[i][j]
		lb $t4, ($t3)
		bne $t4,$a0, end_horizontal2 # If matrix[i][j] !=a0 then continue
		addi $t3, $t3, 1	 # matrix[i][j+1]
		lb $t4, ($t3)
		bne $t4,$a0, end_horizontal2 # If matrix[i][j+1] !=a0 then continue
		addi $t3, $t3, 1	 # matrix[i][j+2]
		lb $t4, ($t3)
		bne $t4,$a0, end_horizontal2 # If matrix[i][j+2] !=a0 then continue
		addi $t3, $t3, 1	 # matrix[i][j+3]
		lb $t4, ($t3)
		bne $t4,$a0, end_horizontal2 # If matrix[i][j+3] !=a0 then continue
		j exit_true
		end_horizontal2:
		addi $t1,$t1,1
		bne $t1,4,horizontal2	# j go from 0 to 3
	addi $t0,$t0,1	
	bne $t0,6, horizontal1		# i go from 0 to 6		
	# Return values	
	exit_false:
	     jr $ra
	exit_true:
                   move $t0,$a0	# Move data of current player
	     li $v0,11
	     li $a0,10
	     syscall
	     beq  $t0,$a1,congrat_player1	# If winner is player 1, then display message for player 1
	     beq  $t0,$a2,congrat_player2	# If winner is player 2, then display message for player 2	     
##############################################
congrat_player1:
	li $v0,4
	la $a0,player1_win
	syscall
	j end	# End program
##############################################
congrat_player2:
	li $v0,4
	la $a0,player2_win
	syscall
	j end	 # End program     	     	     
##############################################
player_tie:	
	# Newline
	li $v0,11
	li $a0,10
	syscall
	li $v0,4
	la $a0,tie
	syscall
	j end	 # End program   