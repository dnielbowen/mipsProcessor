lw $gp,0x0($0)      # Load a "base address" (of 0) from memory address 0

lw $t1,0x04($gp)    # Load the hard-coded memory address 0 to $t9 (contains 1)
lw $t2,0x40($gp)    # Contains 64

add $t3,$t1,$t2     # $t3 should contain 66
sw $t3,0x44($gp)    # Store 66 at address 68 (0x44)
here:
b here
