# Instructions implemented:
# lw, sw, beq, add, sub, and, or, lui, ori

nop

lui $t0,0x3434
lui $t1,0xBF88
ori $t1,0x6210
ori $t2,0xFFFF
ori $t3,0xFEFE

sub $gp,$t2,$t3
