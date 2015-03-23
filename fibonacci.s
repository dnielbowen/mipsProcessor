.set noreorder
nop             # The PC seems to want to start at 0x4, not 0x0

# Print the first 100 fibonacci numbers in 100 consecutive slots in memory
# t0: temp values
# t1: counter
# t2: first fibonacci number
# t3: second fibonacci number
# t4: current fibonacci number

li $gp,0x100    # Start at address 0x100
li $t1,50       # Initialize the counter

############### # Compute the first two numbers by-hand
li $t2,0
sw $t2,0x0($gp) # The first Fibonacci number is 0
li $t3,1
sw $t3,0x4($gp) # The second Fibonacci number is 1

# The following could be implemented with immediate instruction versions
addiu $gp,$gp,8     # Increment the counter by 8 (by-hand)
addi $t1,$t1,-2     # Add -2 (decrement counter by 2)

############### # Do the rest in a loop
fibonacciLoop:
    lw $t2,-0x8($gp)            # Load first number
    lw $t3,-0x4($gp)            # Load second number
    add $t4,$t2,$t3             # Compute current number
    sw $t4,0x0($gp)             # Store current number

    addiu $gp,$gp,4             # Increment memory address
    addi $t1,$t1,-1             # Decrement counter

    slt $t0,$t1,$zero           # Set if i<0
    beq $t0,$0,fibonacciLoop    # Branch if i>=0

finishedLoop:
    b finishedLoop
