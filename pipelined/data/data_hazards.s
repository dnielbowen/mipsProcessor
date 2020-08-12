ori $t0,100
lui $s0,0x1234
ori $s0,0x5678
lui $s1,0x1000
add $s2,$s1,$s0
nop
nop
nop
nop
nop
sw $s2,0xC($t0)
lw $s3,0xC($t0)
addi $s4,$s3,0x100
