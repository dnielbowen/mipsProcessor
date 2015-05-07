.set noreorder
nop

# Prepare for testing
li $k0,68 # To be used later for memory indexing
li $t1,1 # Translates to sll or something?
li $t2,2
ori $t3,3

# Clear the pipe
nop
nop
nop
nop
nop

# Test r-type operations
add $t4,$t1,$t2 # -- Expect $t4 = 3

# Clear the pipe
nop
nop
nop
nop
nop
# Test hazard-less data operations
lw $s5,68($0) # Should be 1068
lw $s6,4($k0) # Should be 106C
