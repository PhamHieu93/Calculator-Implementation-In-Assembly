.data
 
    # STACK = LIFO
    #new_line: .asciiz "\n"

    infix_stack: .space 100   # Due to 100 characters max
    postfix_stack: .space 200 
    operator_stack: .space 100
    calculation: .space 800    # Expression may be up to 50 integer + 50 operator
    to_write_1: .space 200
    to_write_2: .space 200
    status_factori: .space 80
    insert_string: .asciiz "Please insert your expression: "
    initial_expression: .asciiz "Your initial expression: "
    postfix_string: .asciiz "Postfix expression: "
    error_math: .asciiz "Your expression got some errors, please try again\n"
    invalid_insert: .asciiz "You inserted an invalid character in your expression\n"
    new_line: .asciiz "\n"
    result_final: .asciiz "Result is: "
    
    number_0: .double 0
    number_10: .double 10
    number_1: .double 1
    number_100: .double 100
    number_millions_posiv: .double 2147483647
    number_millions_negav: .double -2147483647
    M: .double 0
    E_value: .word 0
    #Space array for save status of factorial
    fout: .asciiz "calc_log.txt"
    
.text
main:


    # Open file to write
    li $v0, 13
    la $a0, fout
    li $a1, 1        	# Open for writing (flags are 0: read, 1: write) 
    li $a2, 0        	# mode is ignored
    syscall            	# open a file (file descriptor returned in $v0)
    move $s1, $v0      	# save the file descriptor
    
    # Allocate memory
    li $v0, 9           #System call code for dynamic allocation
    li $a0, 100          #$a0 contains number of bytes to allocate
    syscall
    move $s0, $v0
    #************************** Insert a string expression***************************
    #*******************************************************************************#
    scan_new:
    # This functon is using for clear the array, prevent floating arithmetic
    clear_register:
        la $t2, postfix_stack
        la $t8, status_factori 
        la $t3, infix_stack
        addi $t2, $t2, -1
        addi $t8, $t8, -1
        addi $t3, $t3, -1
        clear_reg:
        addi $t2, $t2, 1
        addi $t8, $t8, 1
        addi $t3, $t3, 1
        lb $t4, ($t2)
        beq $t4, 0, after_clear
        li $t4, 0
        sb $t4, ($t2)
        sb $t4, ($t8)
        sb $t4, ($t3)
        j clear_reg
    # After clearing
    after_clear:
    li $v0, 4 # system call code for printing string = 4
    la $a0, insert_string # load address of string to be printed into $a0
    syscall
    
    li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, initial_expression   # Content to write
	li $a2, 25
	syscall
	
    # Reading input expression
    la $a0, infix_stack      #Get address to store string
    addi $a1, $s0, 100        #Maximum number of character valid of string
    li $v0, 8                 #Get string mode
    syscall
    
    la $t1, infix_stack
    addi $t1, $t1, -1
    li $t2, 0
    # Count length of infix expression
    loop_length:
        add $t1, $t1, 1
        lb $t4, ($t1)
        beq $t4, '\n', print_infix
        addi $t2, $t2, 1
        j loop_length
    # Save infix into calc_log.txt
    print_infix:
    move $a2, $t2
    li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, infix_stack   # Content to write
	#li $a2, 100
	syscall
	
    li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, new_line   # Content to write
	li $a2, 1
	syscall
	
    #**************************SETTING STATUS***************************
    #*******************************************************************************#
    # Set up Status
    li $t3, 0
    li $t4, 0
    li $t2, 0
    li $t1, 0
    li $t8, 0
    
    
    li $s7, 32
    li $s3, 48
    li $s4, 48
    # Initial parameter for storing
    li $t5, -1                # Postfix top offset
    li $t6, -1                # Operator top offset
    la $t8, status_factori    # Set status for factorial
    la $t1, infix_stack       # Address of infix stack
    la $t2, postfix_stack     # Address of postfix stack
    la $t3, operator_stack    # Address of operator stack
    addi $t1, $t1, -1         # Set initial value to -1
    addi $t8, $t8, -1         # Set initial value to -1
    j Scan_infix
    #****************************PART 1: CONVERT INFIX TO POSTFIX***************************
    #**************************************************************************************#
    Scan_infix_without_prev:  # This function for scan without loading previous to $s6
        addi $t1, $t1, 1
        lb $t4, ($t1)
        j continue_scan_infix
    Scan_infix:              # This function for scan with loading previous to $s6
        addi $t1, $t1, 1                #Increase infix position
        lb $t4, ($t1)                 #Load the current character into $s0
        lb $s6, -1($t1)               #Load the previous character
    continue_scan_infix:
        beq $t4,'\n', EOF    #End loop is the current is 0 (end of string)
        
        lb $t9, 1($t1)                #Load the next character
        
        beq $t4, 113, check_quit_1    #Check if user input quit
        j done_check_quit
        check_quit_1:
            lb $t4, 1($t1)
            bne $t4, 117, invalid_input 
            
            lb $t4, 2($t1)
            bne $t4, 105, invalid_input

            lb $t4, 3($t1)
            bne $t4, 116, invalid_input

            lb $t4, 4($t1)
            bne $t4, '\n', invalid_input
            j end_all
        # Done check quit function   
        done_check_quit:
        bne $s6, 0, scan_real   # This check if we are scaning first elements or not
        beq $t4, '-', PlusMinus
        beq $t4, '+', PlusMinus
        beq $t4, '*', error_mathtype
        beq $t4, '/', error_mathtype
        beq $t4, ')', error_mathtype
        beq $t4, '!', error_mathtype
        beq $t4, '.', Dot
        beq $t4, 'M', M_checking
        j scan_real
        
        scan_real:            # Scan from the second elements
        #Checking character
        blt $t4, 48, Check_Ope
        bgt $t4, 57, Check_Ope
        #If charac is number and next character is factori ! -> save into the postfix expression
        #If charac is number -> save into the postfix expression
        j inputto_postfix
        #If not an operator -> save in postfix
        Check_Ope:
        #beq $t9, 33, invalid_input
        #beq $s3,1, save_negav
        beq $t4, 33, factorization      #33 = "!" in ASCII
        beq $t4, 40, OpenBracket        #40 = "(" in ASCII
        beq $t4, 41, CloseBracket       #41 = ")" in ASCII
        beq $t4, 42, MulDiv             #42 = "*" in ASCII
        beq $t4, 43, PlusMinus          #43 = "+" in ASCII
        beq $t4, 45, PlusMinus          #45 = "-" in ASCII        
        beq $t4, 46, Dot                #46 = "." in ASCII        
        beq $t4, 47, MulDiv             #47 = "/" in ASCII
        beq $t4, 94, Pow                #94 = "^" in ASCII
        beq $t4, 77, M_checking         #77= "M" in ASCII
        j invalid_input
    Finish_Scan:
    ################ IF YOU WANT TO PRINT POSTFIX, JUST UNLOCK CMT BELOW ##########
    #Print Postfix expression
    #Print prompt
   # li $v0, 4
   # la $a0, postfix_string
   # syscall
   # li $t6, -1     #Load current of Postfix offset to -1

    j print_post
    
    print_post:
       # addi $t6, $t6, 1   #Increase current of postfix offset
       # add $s5, $t6, $t2
       # lb $t7, ($s5)
       # beq $t7 , 0, end_loop_checking
       # move $a0, $t7
    #If not, then current post is number
       # li $v0, 11
      #  syscall
     #   j print_post
         j end_loop_checking    #Comment this row end unlock all about if you want to print postfix
    
    #SUB PROGRAM
    PlusMinus:
            beq $s6, '*', add_0_postfix    # Add 0 to postfix for some special case like
            beq $s6, '/', add_0_postfix    # 5*+---6
            beq $s6, '^', add_0_postfix
            beq $s6, '(', add_0_postfix
            beq $s6, 0, add_0_postfix
            j after_check_ope_plusminus
        add_0_postfix:
            move $t7, $t4       # Save the initial value first
            li $t4, 48
            addi $t5, $t5, 1
            add $s5, $t5, $t2
            sb $t4, ($s5)
            #add space
            addi $t5, $t5, 1
            add $s5, $t5, $t2
            sb $s7, ($s5)
            move $t4, $t7      # Load agian the initial value
            beq $s6, '*', set_s4     #Set_s4 to 1 for marking some special case
            beq $s6, '/', set_s4     
            beq $s6, '^', set_s4          
        after_check_ope_plusminus:   # This code block use for conclude many "+" and "-" like +---
            beq $t4, '-', check_prev_minus
            beq $t4, '+', check_prev_plus
        check_prev_minus:
            beq $s6, '+', check_next_plusminus
            beq $s6, '-', trade_check_next_minus
            j check_next_plusminus
            
        check_prev_plus:
            beq $s6, '+', check_next_plusminus
            beq $s6, '-', trade_check_next_plus
            j check_next_plusminus
            
        check_next_plusminus:
            beq $t9, '+', Scan_infix
            beq $t9, '-', Scan_infix
            j main_pre_plusminus
             
        trade_check_next_plus:
            li $s6, 45
            li $t4, 45
            beq $t9, '+', Scan_infix_without_prev
            beq $t9, '-', Scan_infix_without_prev
            j main_pre_plusminus
        
        trade_check_next_minus:
            li $s6, 43
            li $t4, 43
            beq $t9, '+', Scan_infix_without_prev
            beq $t9, '-', Scan_infix_without_prev
            j main_pre_plusminus
        # End of code block for concluding
        main_pre_plusminus:
        beq $t9, '!', error_mathtype     # Check the order of operator, jump error if it error
        beq $t9, '*', error_mathtype
        beq $t9, '/', error_mathtype
        beq $t9, '^', error_mathtype
        beq $t9, '(', main_plusminus
        beq $t4, '-', main_plusminus
        beq $t4, '+', main_plusminus
            
        main_plusminus:    # Main function for saving operator 
        beq $t6, -1, InputTo_Operator
        beq $s4, 49, InputTo_Operator
        add $s5, $t6, $t3
        lb $t7, ($s5)
        beq $t7, 40, InputTo_Operator
        beq $t7, 43, EqualPreCe
        beq $t7, 45, EqualPreCe
        beq $t7, 42, LowPreCe_plusminus
        beq $t7, 47, LowPreCe_plusminus
        beq $t7, 94, LowPreCe_plusminus
        
    MulDiv:                  # The function for muldiv operator
        beq $t9, '*', error_mathtype
        beq $t9, '/', error_mathtype
        beq $t9, '^', error_mathtype
        beq $t9, '!', error_mathtype
        #beq $t9, 45, negative_num_muldiv
        main_muldiv:         # Main funtion for Muldiv saving
        beq $t6, -1, InputTo_Operator
        add $s5, $t6, $t3
        lb $t7, ($s5)
        beq $t7, 40, InputTo_Operator
        beq $t7, 43, InputTo_Operator
        beq $t7, 45, InputTo_Operator
        beq $t7, 42, EqualPreCe
        beq $t7, 47, EqualPreCe
        beq $t7, 94, LowPreCe_muldiv
        
    Pow:          #The function for pow operator
        beq $t9, '*', error_mathtype
        beq $t9, '/', error_mathtype
        beq $t9, '!', error_mathtype
        main_pow:    # Main function for saving pow operator
        beq $t6, -1, InputTo_Operator
        add $s5, $t6, $t3
        lb $t7, ($s5)
        beq $t7, 40, InputTo_Operator
        beq $t7, 43, InputTo_Operator
        beq $t7, 45, InputTo_Operator
        beq $t7, 42, InputTo_Operator
        beq $t7, 47, InputTo_Operator
        beq $t7, 94, EqualPreCe
        
    OpenBracket:    #The function for open bracket operator
        beq $t9, '!', error_mathtype
        beq $s6, '!', input_mul     #Input_mul function is use for some case like 23(23),
        beq $s6, '0', input_mul     #It will put the "*" before process openbracket
        beq $s6, '1', input_mul
        beq $s6, '2', input_mul
        beq $s6, '3', input_mul
        beq $s6, '4', input_mul
        beq $s6, '5', input_mul
        beq $s6, '6', input_mul
        beq $s6, '7', input_mul
        beq $s6, '8', input_mul
        beq $s6, '9', input_mul
        beq $s6, ')', input_mul
        j main_openbracket
        
        input_mul:     #Main function for input multiply
            li $t4, 42
            beq $t6, -1, InputTo_Operator_special
            add $s5, $t6, $t3
            lb $t7, ($s5)
            beq $t7, 40, InputTo_Operator_special
            beq $t7, 43, InputTo_Operator_special
            beq $t7, 45, InputTo_Operator_special
            beq $t7, 42, EqualPreCe_special
            beq $t7, 47, EqualPreCe_special
            beq $t7, 94, LowPreCe_muldiv_special
        
        InputTo_Operator_special:  # Special function for this case
        add $t6, $t6, 1
        add $s5, $t6, $t3
        sb $t4, ($s5)
        j after_set_mul
        
        EqualPreCe_special:    # Special function for this case
        jal OpeToPostfix
        j input_mul
        LowPreCe_muldiv_special:  # Special function for this case
        jal OpeToPostfix
        j input_mul
        
        after_set_mul:   # After set mul, we back to openbracket
            li $t4, 40
            j main_openbracket
        
        main_openbracket: # Main function for saving openbracket
        j InputTo_Operator
        
    CloseBracket:   # Main function for saving openbracket
        beq $s6, '+', error_mathtype
        beq $s6, '-', error_mathtype
        beq $s6, '*', error_mathtype
        beq $s6, '/', error_mathtype
        beq $s6, '^', error_mathtype
        
        blt $t9, 48, continue_closebracket # This for checking some special case like (2+3)2 is invalid
        bgt $t9, 57, continue_closebracket
        j invalid_input

        continue_closebracket:
            beq $t6, -1, error_mathtype    #Case of there is no operator in operator stack
            add $s5, $t6, $t3
            lb $t7, ($s5)
            beq $t7, 40, SkipBracket    # Function for skipping bracket if we meet
            
            jal OpeToPostfix           #Pop all the element in () into postfixs
            j continue_closebracket
                   
    factorization:         # Function for processing "!"
        beq $s6, 33, error_mathtype       # 33 = "!" in ASCII
        beq $s6, 40, error_mathtype       #40 =  "(" in ASCII
        beq $s6, 42, error_mathtype       #42 = "*" in ASCII
        beq $s6, 43, error_mathtype       #43 = "+" in ASCII
        beq $s6, 45, error_mathtype       #45 = "-" in ASCII        
        beq $s6, 46, error_mathtype       #46 = "." in ASCII        
        beq $s6, 47, error_mathtype       #47 = "/" in ASCII
        beq $s6, 94, error_mathtype       #94 = "^" in ASCII
        
        #If closebracket ")" -> contiue
        blt $t9, 48, continue_factori
        bgt $t9, 57, continue_factori
        continue_factori:
        beq $s6, ')', save_1_to_status_factori  # Save mark for cheking negav or not in function block 2
        j save_0_to_status_factori
        
        
    save_1_to_status_factori: #Function for save 1 into res $t8
        addi $t8, $t8, 1
        li $s5, 49
        sb $s5, ($t8)
        j inputto_postfix
    save_0_to_status_factori: #Function for save 0 into res $t8
        addi $t8, $t8, 1
        li $s5, 48
        sb $s5, ($t8)
        j inputto_postfix
        
    Dot:        # Function for processing "."
        beq $s3, 49, error_mathtype
        li $s3, 49    # Mark 1 dot, if 2 dot more, it will be error
        beq $s6, 0, error_mathtype    # . at first infix
        beq $s6, 40, error_mathtype   # (. is invalid
        beq $s6, 42, error_mathtype   # *. is invalid
        beq $s6, 43, error_mathtype   # +. is invalid
        beq $s6, 45, error_mathtype   # -. is invalid
        beq $s6, 47, error_mathtype   # /. is invalid
        beq $s6, 33, error_mathtype   # !. is invalid
        beq $s6, 41, error_mathtype   # ). is invalid
        beq $t9, 0, error_mathtype   # Same as above
        beq $t9, 40, error_mathtype
        beq $t9, 42, error_mathtype
        beq $t9, 43, error_mathtype
        beq $t9, 45, error_mathtype
        beq $t9, 47, error_mathtype
        beq $t9, 33, error_mathtype
        beq $t9, 41, error_mathtype
        beq $t9, '\n', error_mathtype
        j inputto_postfix_dot  #Input dot to postfix
        
     M_checking:      #Main function for checking value M
         beq $s6, 46, error_mathtype  # .M is invalid 
         beq $t9, 46, error_mathtype  # M. is invalid
         beq $t9, 48, error_mathtype  # M0 is invalid
         beq $t9, 49, error_mathtype  # M1 is invalid
         beq $t9, 50, error_mathtype  # M2 is invalid
         beq $t9, 51, error_mathtype  # M3 is invalid
         beq $t9, 52, error_mathtype  # M4 is invalid
         beq $t9, 53, error_mathtype  # M5 is invalid
         beq $t9, 54, error_mathtype  # M6 is invalid
         beq $t9, 55, error_mathtype  # M7 is invalid
         beq $t9, 56, error_mathtype  # M8 is invalid
         beq $t9, 57, error_mathtype  # M9 is invalid
         j inputto_postfix       # Input character "M" into postfix
    #*****************SOME SPECIAL CASE WITH NEGATIVE NUMBER*****************#
    set_s4:
        li $s4, 49
        j after_check_ope_plusminus  
              
    OpeToPostfix:        #Pop top of operator and push into Postfix
        
        addi $t5, $t5, 1
        add $s5, $t5, $t2
        sb $t7, ($s5)
        addi $t6, $t6, -1
        
        bne $t6, -2, inputspace_postfix_ope
        jr $ra
        continue_OpetoPostfix:
        jr $ra
        
    inputspace_postfix_ope: # Input a space between each element for easier in calculation for ope

        addi $t5, $t5, 1
        add $s5, $t5, $t2
        sb $s7, ($s5)
        j continue_OpetoPostfix
        
    inputspace_postfix_post: # Input a space between each element for easier in calculation for postfix

        addi $t5, $t5, 1
        add $s5, $t5, $t2
        sb $s7, ($s5)
        li $s3, 48
        j Scan_infix
           
    InputTo_Operator: # Input operator into operator stack
        li $s4, 48
        add $t6, $t6, 1
        add $s5, $t6, $t3
        sb $t4, ($s5)
        j Scan_infix
        
    inputto_postfix: # Input to postfixstack
        addi $t5, $t5, 1
        add $s5, $t5, $t2
        sb $t4, ($s5)
        #beq $t9, '\n', Scan_infix
        blt $t9, 48, check_dot_factori #Check dot in the next element
        bgt $t9, 57, check_dot_factori
        j Scan_infix
        
    inputto_postfix_dot: # Special function for dot
        addi $t5, $t5, 1
        add $s5, $t5, $t2
        sb $t4, ($s5)
        j Scan_infix
        
    check_dot_factori: # Check do function
        bne $t9, 46, inputspace_postfix_post
        j Scan_infix
        
    EqualPreCe:  # Equal precedence overall
        jal OpeToPostfix
        j InputTo_Operator
    LowPreCe_plusminus: # Lower precedence for plusminus
        jal OpeToPostfix
        j PlusMinus
    LowPreCe_muldiv:  # Equal precedence for muldiv
        jal OpeToPostfix
        j MulDiv
    SkipBracket: # Skip bracket
        add $t6, $t6, -1
        j Scan_infix
    popAll:  # Popall elements out
        beq $t6, -1, Finish_Scan
        add $s5, $t6, $t3
        lb $t7, ($s5)
        jal OpeToPostfix
        j popAll
    
    #END PRPGRAM
    invalid_input: #Invalid character
        li $v0, 4 # system call code for printing string = 4
        la $a0, invalid_insert # load address of string to be printed into $a0
        syscall
        
        li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, invalid_insert            # Content to write
	li $a2, 54
	syscall
        j convert_double_to_string
        
    error_mathtype: #Error in math
        li $v0, 4 # system call code for printing string = 4
        la $a0, error_math # load address of string to be printed into $a0
        syscall
        
        li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, error_math            # Content to write
	li $a2, 50
	syscall
        j convert_double_to_string
    
    EOF: #Check the final character like 6-, 6* is invalid
        beq $s6, 45, invalid_input
        beq $s6, 43, invalid_input
        beq $s6, 42, invalid_input
        beq $s6, 47, invalid_input
        beq $s6, 40, invalid_input
       
        j popAll
    end_loop_checking:
    li $v0, 4 # system call code for printing string = 4
    la $a0, new_line # load address of string to be printed into $a0
    syscall
    j Calculation_Main
    
    
    #**************CALCULATION POSTFIX*****************#
    #**************************************************#
    
    #Seetup Status for function block 2
    Calculation_Main:
    li $t3, 0
    li $t2, 0
    li $t6, 0
    li $t1, 0
    
    
    la $t3, calculation     # Address of calculation
    la $t2, postfix_stack   # Address of postfix stack
    la $t5, status_factori  # Address of status factori
    li $t6, -8              #Offset of calculation arr
    li $s3, 0 
    
    addi $t3, $t3, -8       # Load initial value                  
    addi $t2, $t2, -1
    addi $t5, $t5, -1
    
    scan_postfix:   #Scan postfix expression
    
    addi $t2, $t2, 1
    lb $t4, ($t2)
    
    beq $t4, '(', scan_postfix
    beq $t4, '-', check_negav
    beq $t4, 0, print_result   #If it end
    continue_postfix:
    beq $t4,32, scan_postfix
    beq $t4, 0, print_result
    l.d $f2, number_0
    l.d $f4, number_10
    
    beq $t4, 'M', save_M_value
    beq $t4, '!', factorization_double
    beq $t4, '+', is_operator
    beq $t4, '-', is_operator
    beq $t4, '*', is_operator
    beq $t4, '/', is_operator
    beq $t4, '^', is_operator
                    
    double_to_cal:  #Main function for convert the string into double and save to calculation stack
        subi $t4, $t4, 48
        mtc1.d $t4, $f8
        cvt.d.w $f8, $f8
        
        
        mul.d $f2, $f2, $f4     #Multiply by 10
        add.d $f2, $f2, $f8     #Adding for new value

        addi $t2, $t2, 1
        lb $t4, ($t2)

        # If it is a decimal point
        beq $t4, 46, main1_decimal_point
        beq $t4, 32, input_to_cal
        j double_to_cal
        
        decimal_point:
        l.d $f6, number_10
        mul.d $f4, $f4, $f6
        j main2_decimal_point
        
        main1_decimal_point:
        addi $t2, $t2, 1

        j main2_decimal_point
        
        main2_decimal_point:
        lb $t4, ($t2)
        subi $t4, $t4, 48
        
        mtc1.d $t4, $f8
        cvt.d.w $f8, $f8
        div.d $f8, $f8, $f4
        
        add.d $f2, $f2, $f8
        addi $t2, $t2,1
        lb $t4, ($t2)

        bne $t4, 32, decimal_point
        j input_to_cal
         
    check_negav:  # Function for checking negative
        lb $s4, 1($t2)
        bne $s4, 32, set_negav
        j continue_postfix
    set_negav:    # Function for save negav 
        li $s3, 1
        j scan_postfix   
        
    save_M_value:  # If M value, just store
        ldc1 $f24, M
        j store_result  
        
    factorization_double: #Special function for only !
        l.d $f16, number_1
        add $t8, $t6, $t3
        ldc1 $f20, ($t8)
        ldc1 $f22, ($t8)
        addi $t6, $t6, -8
        
        #Check negav or posiv in the bracket ()
        addi $t5, $t5, 1
        lb $t7, ($t5)
        beq $t7, 49, check_negav_factori_inbracket
        beq $t7, 48, check_negav_factori
        check_negav_factori_inbracket:
            l.d $f18, number_0
            c.lt.d $f20, $f18
            bc1t error_mathtype
            j setup_factori_initial
            
        check_negav_factori:
            l.d $f18, number_0
            c.lt.d $f20, $f18
            bc1t invert_negav
            j setup_factori_initial
        
        #Invert negav is use for negative number before !
        invert_negav:
            neg.d $f20, $f20
            neg.d $f22, $f22
            l.d $f16, number_0    
            j setup_factori_initial
            
        setup_factori_initial:  # Main function for processin !
        l.d $f30, number_0
        c.eq.d $f20, $f30
        bc1t factorization_for_01
        l.d $f30, number_1
        c.eq.d $f20, $f30
        bc1t factorization_for_01
        j main_factori_loop
        
        factorization_for_01:
            l.d $f18, number_1
            l.d $f24, number_1
            j check_subtract
                   
        main_factori_loop:
        l.d $f18, number_0
        cvt.w.d $f20, $f20
        cvt.d.w $f20, $f20
        sub.d $f24, $f22, $f20
        c.eq.d $f24, $f18
        bc1t satisfy_factori
        bc1f error_mathtype
        
        satisfy_factori:
            l.d $f18, number_1    
            sub.d $f22, $f22, $f18
            mul.d $f24, $f20, $f22
            c.eq.d $f22, $f18
            bc1t check_subtract 
            j loop_factori_calculate
            loop_factori_calculate:
                sub.d $f22, $f22, $f18
                mul.d $f24, $f24, $f22
                c.eq.d $f22, $f18
                bc1t check_subtract 
                j loop_factori_calculate
        check_subtract:
            c.lt.d $f16, $f18
            bc1t subtract_factori
            j store_result
        subtract_factori:
            sub.d $f24, $f16, $f24
            j store_result
        
    is_operator:  # If te character is operator
        blt $t6, 8, scan_postfix  # Take first value
        add $t8, $t6, $t3
        ldc1 $f20, ($t8)
        
        addi $t6, $t6, -8  # Take second value
        add $t8, $t6, $t3
        ldc1 $f22, ($t8)
        
        addi $t6, $t6, -8
        
        beq $t4, 42, multiply_double
        beq $t4, 43, add_double
        beq $t4, 45, sub_double
        beq $t4, 47, divide_double
        beq $t4, 94, pow_double
        
    multiply_double: # Function for multiply
        mul.d $f24, $f22, $f20
        j store_result
        
    add_double:  # Function for add
        add.d $f24, $f22, $f20
        j store_result
        
    sub_double: # Function for sub
        sub.d $f24, $f22, $f20
        j store_result
        
    divide_double: # Function for divide
        l.d $f28, number_0
        c.eq.d $f20, $f28
        bc1t error_mathtype
        div.d $f24, $f22, $f20
        j store_result
    
    store_result:   # Store double value after convert into calculation
        addi $t6, $t6, 8
        add $t9, $t6, $t3
        sdc1 $f24, ($t9)
        j scan_postfix 
           
    pow_double:   # Main function for processing Pow double
        l.d $f16, number_0
        l.d $f18, number_1
        cvt.w.d $f14, $f20
        cvt.d.w $f14, $f14
        sub.d $f14, $f20, $f14
        c.eq.d $f14, $f16
        bc1f error_mathtype  # Check whether a decimal or not, 2^2.3 is invalid
        
        c.lt.d $f20, $f16    # Check for negav pow like 2^-3
        bc1t negav_pow
        
        calculate_pow:
        check_pow_0and1:    # Value for pow 0 and 1, result is 1
            c.eq.d $f20, $f16
            bc1t pow_zero
            c.eq.d $f20, $f18
            bc1t pow_one
        # The first calculation in pow
        sub.d $f20, $f20, $f18
        mul.d $f24, $f22, $f22
        
        add.d $f16, $f16, $f18
        c.eq.d $f16, $f20
        bc1t store_pow
        bc1f pow_double_main
        # From the second to n pow
        pow_double_main:
        mul.d $f24, $f24, $f22
        
        add.d $f16, $f16, $f18
        c.eq.d $f16, $f20
        
        bc1t store_pow
        bc1f pow_double_main
        # Invert negative to positive if it < 0
        negav_pow:
            neg.d $f20, $f20
            li $s3, 1
            j calculate_pow
        pow_zero:    #Pow for zero
            l.d $f24, number_1
            j store_pow
        pow_one:     #Pow for one
            mov.d $f24, $f22
            j store_pow
        store_pow:   #Store pow
            beq $s3, 1, revert_pow   #Check if negative or not
            j store_main_pow 
        revert_pow:   # If negative, we divide 1/ result
            div.d $f24, $f18, $f24
            li $s3, 0
            j store_main_pow  # Main function for storing
        store_main_pow:
        addi $t6, $t6, 8
        add $t9, $t6, $t3
        sdc1 $f24, ($t9)

        j scan_postfix  
     # Some other functions
    input_to_cal:
        addi $t6, $t6, 8
        add $t8, $t6, $t3
        beq $s3, 1, negav_num
        j posi_num
        
    negav_num:
        l.d $f14, number_0
        sub.d $f2, $f14, $f2
        sdc1 $f2, ($t8)
        li $s3, 0
        j scan_postfix
    posi_num:
        sdc1 $f2, ($t8)
        j scan_postfix
        
    print_result:

        li $v0, 4 # system call code for printing string = 4
        la $a0, result_final # load address of string to be printed into $a0
        syscall
        
        
        add  $t9, $t6, $t3
        ldc1 $f26, ($t9)
        sdc1 $f26, M
        
        mov.d $f12, $f26
        li $v0, 3 # Print double number
        syscall
        
        li $v0, 4 # system call code for printing string = 4
        la $a0, new_line # load address of string to be printed into $a0
        syscall
        # Function block 3: convert from double to string
        convert_double_to_string:
        li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, result_final            # Content to write
	li $a2, 11
	syscall
	# First, check if M is too big or too small
        li $t3, 0
        li $s3, 48
        lw $t2, E_value
        
        l.d $f2, M
        l.d $f28, number_millions_posiv
        l.d $f26, number_millions_negav
        
        c.le.d $f2, $f28
        bc1t check_infi_negav
        j decrease_number_posiv
        
        check_infi_negav:
        c.le.d $f2, $f26
        bc1t decrease_number_negav
        j satis_number
        # We will decrease the number and mark Exxx in the end of string
        decrease_number_posiv:         # For too big
         li $s3, 49
         
         l.d $f6, number_100
         div.d $f2, $f2, $f6
         addi $t2, $t2, 2
         c.le.d $f2, $f28
         bc1t satis_number
         j decrease_number_posiv
         
        decrease_number_negav:    # For too small
         
         li $s3, 49
         l.d $f6, number_100
         div.d $f2, $f2, $f6
         addi $t2, $t2, 2
         c.le.d $f26, $f2
         bc1t satis_number
         j decrease_number_negav
         
        satis_number:    # Function main for convert
        l.d $f8, number_0
        l.d $f10, number_1
        mov.d $f4, $f2
        mov.d $f6, $f2
        li $t9, -1
        li $t8, -1
        
        c.lt.d $f2, $f8 
        bc1t save_minus_first   # If it < 0, save minus first
        j not_minus_first
        save_minus_first:  #Function for saving minus
            addi $t8, $t8, 1
            li $t7, 45
            sb $t7, to_write_2($t8)
            addi $t3, $t3, 1
            neg.d $f2, $f2
            neg.d $f6, $f6
            neg.d $f4, $f4
            j not_minus_first
            
        not_minus_first:  # Function if it > 0

        cvt.w.d $f6, $f6
        cvt.d.w $f6, $f6
        
        cvt.w.d $f20, $f6
        sub.d $f4, $f4, $f6
        
        # Check M is decimal or integer
        mfc1.d $t5, $f20
        c.eq.d $f4, $f8
        bc1t not_decimal_point_result
        bc1f decimal_point_result
        
        not_decimal_point_result:  # If it is integer
            addi $t9, $t9, 1       # Save integer part
            li $t1, 10
            div $t5, $t1
            mflo $t5          #result
            mfhi $s7          #remainder
            addi $t4, $s7, 48
            sb $t4, to_write_1($t9)   #save remainder
            beq $t5, 0, finish_not_decimal_point
            j not_decimal_point_result
        # Save integer part, convert from to_write 1 to 2 in preverse order for correct
        finish_not_decimal_point:
            addi $t8, $t8, 1
            lb $t7, to_write_1($t9)
            sb $t7, to_write_2($t8)
            addi $t3, $t3, 1
            beq $t9, 0, print_M
            addi $t9, $t9, -1
            j finish_not_decimal_point
        # Print function for integer M
        print_M:
            beq $s3, 49, print_E_value   # Check if it has E or not ( too big or too small )
            li $t9, -1
            j print_M_main
            # Function for print E value
            print_E_value:
                addi $t8, $t8, 1
                li $t7, 69
                sb $t7, to_write_2($t8)
                print_after_E:
                addi $t9, $t9, 1
                li $t1, 10
                div $t2, $t1
                mflo $t2          #result
                mfhi $s7          #remainder
                addi $t4, $s7, 48
                sb $t4, to_write_1($t9)   #save remainder
                beq $t2, 0, finish_after_E_value
                j print_after_E
                # Print after E like E100, E12, E14
                finish_after_E_value:
                addi $t8, $t8, 1
                lb $t7, to_write_1($t9)
                sb $t7, to_write_2($t8)
                addi $t3, $t3, 1
                beq $t9, 0, print_M_main
                addi $t9, $t9, -1
                j finish_after_E_value
            
            # Main function of print M and write to file
            print_M_main:
            move $a2, $t3
            li $v0, 15       	# System call for write to file
	    move $a0, $s1      	# File descriptor 
	    la $a1, to_write_2            # Content to write
	    #li $a2, 100
	    syscall
	    j print_newline_result
        # If M is decimal point
        decimal_point_result:  # The same as integer, save integer part
            beq $s3, 49, not_decimal_point_result
            
            addi $t9, $t9, 1
            li $t1, 10
            div $t5, $t1
            mflo $t5          #result
            mfhi $t6         #remainder
            addi $t4, $t6, 48
            sb $t4, to_write_1($t9)
            beq $t5, 0, finish_decimal_point
            j decimal_point_result
            
        finish_decimal_point:
            addi $t8, $t8, 1
            lb $t7, to_write_1($t9)
            sb $t7, to_write_2($t8)
            addi $t3, $t3, 1
            beq $t9, 0, save_dot_point
            addi $t9, $t9, -1
            j finish_decimal_point
        # Save dot point
        save_dot_point:
           addi $t8, $t8, 1
           li $t7, 46
           sb $t7, to_write_2($t8)
           addi $t3, $t3, 1
           j after_dot_point
        # Save decimal part
        after_dot_point:
            initial_setup_after_dot_point:
            l.d $f16, number_10
            li $t6, 0
            save_after_dot_point:
                addi $t8, $t8, 1
                mul.d $f4, $f4, $f16

                cvt.w.d $f18, $f4

                cvt.d.w $f22, $f18
                sub.d $f4, $f4, $f22
                mfc1.d $t7, $f18
                add $t7, $t7, 48
                sb $t7, to_write_2($t8)
                addi $t3, $t3, 1
                addi $t6, $t6, 1
                
                beq $t6, 16, print_M_decimal
                j save_after_dot_point
            
        print_M_decimal:
            move $a2, $t3
            li $v0, 15       	# System call for write to file
	    move $a0, $s1      	# File descriptor 
	    la $a1, to_write_2            # Content to write
	    #li $a2, 100
	    syscall
	   j print_newline_result
        # Print newline at all
	print_newline_result:
	li $v0, 15       	# System call for write to file
	move $a0, $s1      	# File descriptor 
	la $a1, new_line            # Content to write
	li $a2, 1
	syscall
	
        j scan_new
        
        
    end_all:
    li $v0, 16         # system call for close file
    move $a0, $s1      # file descriptor to close
    syscall # close file
    #**************************************END OF PROGRAM***************************#
    #*******************************************************************************#
    li $v0, 10              # System call code for exit
    syscall
        
        
        
