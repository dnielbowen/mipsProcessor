library ieee;
use ieee.std_logic_1164.all;

-- Decodes instruction register to provide CPU control signals
-- Below are some sample opcodes
--   8f210200        lw      at,512(t9)
--   1001ffff        beq     zero,at,8 <main+0x8>
--   af210204        sw      at,516(t9)
--   00000000        nop
--   00430820        add     at,v0,v1
--   00430822        sub     at,v0,v1
--   00430824        and     at,v0,v1
--   00430825        or      at,v0,v1
--   0043082a        slt     at,v0,v1
entity CPU_IR_DECODER is
    port (
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

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_CPU_IR_DECODER is end;

architecture impl1 of TB_CPU_IR_DECODER  is
    signal sRegWrite, sALUSrc, sMemWrite, sMemRead, sMemToReg : std_logic;
    signal sBranch, sZero, sRegDst : std_logic;
    signal sALUControl : std_logic_vector(3 downto 0);

    signal sIR: std_logic_vector(31 downto 0);
begin
    uut1: CPU_IR_DECODER port map (
        sIR, sRegDst, sBranch, sMemRead, sMemToReg,
        sALUSrc, sMemWrite, sRegWrite, sALUControl
    );

    signalTests1: process
        variable buf: line;
    begin
        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
        wait for T/4;

        sIR <= x"00430820"; -- add t1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = '0');
        assert(sMemToReg = '0');
        assert(sRegWrite = '1');
        assert(sMemRead = '0');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"8f210200"; -- lw $t1,0x200($t9)
        wait for T/2;
        assert(sRegDst = '0');
        assert(sALUSrc = '1');
        assert(sMemToReg = '1');
        assert(sRegWrite = '1');
        assert(sMemRead = '1');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"0043082a"; -- slt $1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = '0');
        assert(sMemToReg = '0');
        assert(sRegWrite = '1');
        assert(sMemRead = '0');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0111");

        write(buf, string'("Assertions tb_control complete"));
        writeline(output, buf);

        wait;
    end process;
end architecture;
