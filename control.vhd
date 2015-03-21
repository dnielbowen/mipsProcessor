library ieee;
use ieee.std_logic_1164.all;

-- Decodes instruction register to provide CPU control signals
entity CPU_IR_DECODER is
    port (
        CLK: in  std_logic;
        IR:  in  std_logic_vector(31 downto 0);

        RegDst, Branch, MemRead, MemToReg: out std_logic;
        ALUSrc, MemWrite, RegWrite : out std_logic;
        ALUControl: out std_logic_vector (3 downto 0)
    );
end entity;

architecture impl1 of CPU_IR_DECODER is
    type CONTROL_SIGS is record
        RegDst, ALUSrc, MemToReg, RegWrite: std_logic;
        MemRead, MemWrite, Branch: std_logic;
        ALUOp: std_logic_vector(1 downto 0);
    end record;
    signal cSigs : CONTROL_SIGS;
    
    signal opcode : std_logic_vector(5 downto 0);
    signal fcn : std_logic_vector(5 downto 0);
begin
    opcode <= ir(31 downto 26);
    fcn <= ir(5 downto 0);

    cSigs <= ('1','0','0','1','0','0','0',"10") when opcode = "000000"  -- Rfmt
        else ('0','1','1','1','1','0','0',"00") when opcode = "100011"  -- LW
        else ('0','1','0','0','0','1','0',"00") when opcode = "101011"  -- SW
        else ('0','0','0','0','0','0','1',"01") when opcode = "000100"; -- BEQ

    ALUControl <=
             "0010" when cSigs.ALUOp = "00" --add (LW,SW)
        else "0110" when cSigs.ALUOp = "01" --sub (BEQ)

        else "0010" when cSigs.ALUOp = "10" and fcn = "100000" -- add (ADD)
        else "0110" when cSigs.ALUOp = "10" and fcn = "100010" -- sub (SUB)
        else "0000" when cSigs.ALUOp = "10" and fcn = "100100" -- AND
        else "0001" when cSigs.ALUOp = "10" and fcn = "100101" -- OR
        else "0111" when cSigs.ALUOp = "10" and fcn = "101010";-- SLT

    RegDst <= cSigs.RegDst;
    Branch <= cSigs.Branch;
    MemRead <= cSigs.MemRead;
    MemToReg <= cSigs.MemToReg;
    ALUSrc <= cSigs.ALUSrc;
    MemWrite <= cSigs.MemWrite;
    RegWrite <= cSigs.RegWrite;
end architecture;
