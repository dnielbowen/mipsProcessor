# Extra MUXs

MUX sources to the register write:
    00 ALU (R-type operation)
    01 Memory (lw)
    10 Instruction upper (lui)

Add a 3-input MUX on ALUB for immediate values:
    00 Register input
    01 Instruction sign-extended
    10 Instruction not sign-extended

# Implemented instructions

- I-type instructions take 2 register and a 16-bit immediate
- R-type instructions take 3 registers and use the other 11 bits for additional 
  details (ALU function and shift amount)
- J-type instructions are engineered to allow the biggest jump possible, so 
  everything but the opcode (6 bits) is dedicated to the immediate

Opcode  function    mnemonic    type
100011              lw          I
101011              sw          I
000100              beq         I
000000  100000      add         R
000000  100010      sub         R
000000  100100      and         R
000000  100101      or          R
000000  101010      slt         R

Additions
Opcode  function    mnemonic
001101              ori         I
001111              lui         I

            ORI LUI
Branch      0   0
RegWrite    1   1
RegDst      0   0
MemToReg    00  10          (Rename to RegWSrc)
MemRead     0   0
MemWrite    0   0
ALUSrc      10  XX
ALUOp       11  XX          (Requires a new ALUOp control def)

- ORI: Send regA = rs ir(25 downto 21) and an immediate ir(15 downto 0) to the 
  ALU and write back to regW = rt ir(20 downto 16)
- LUI: Write the immediate ir(15 downto 0) to regW = rt ir(20 downto 16)
