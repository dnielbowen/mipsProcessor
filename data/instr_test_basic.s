.set noreorder
nop

# Prepare for testing
li $16,0xFFFF1010
ori $10,1
ori $11,2
ori $12,3

# Test r-type operations
add $14,$10,$11 # -- Expect $t4 = 3
nop
