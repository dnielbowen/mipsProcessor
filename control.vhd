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

        -- RegDst is essentially a question of whether the instruction is 
        -- I-type or R-type (ie "where in the instruction is rd?")
        RegDst, Branch, MemRead, MemWrite, RegWrite : out std_logic;
        ALUSrc, RegWSrc: out std_logic_vector (1 downto 0);
        ALUControl: out std_logic_vector (3 downto 0)
    );
end entity;

architecture impl1 of CPU_IR_DECODER is
    type CONTROL_SIGS is record
        RegDst, RegWrite, MemRead, MemWrite, Branch: std_logic;
        ALUSrc, RegWSrc: std_logic_vector(1 downto 0);
        ALUOp: std_logic_vector(2 downto 0);
    end record;
    signal cSigs : CONTROL_SIGS;
    
    signal opcode : std_logic_vector(5 downto 0);
    signal fcn : std_logic_vector(5 downto 0);
begin
    opcode <= ir(31 downto 26);
    fcn <= ir(5 downto 0);

    cSigs <= ('1','1','0','0','0',"00","00","010")
            when opcode = "000000"  -- R-type instruction
        else ('0','1','1','0','0',"01","01","000")
            when opcode = "100011"  -- lw
        else ('0','0','0','1','0',"01","00","000")
            when opcode = "101011"  -- sw
        else ('0','1','0','0','0',"00","10","000")
            when opcode = "001111"  -- lui
        else ('0','1','0','0','0',"10","00","011")
            when opcode = "001101"  -- ori
        else ('0','1','0','0','0',"10","00","000")
            when opcode = "001001"  -- addiu
        else ('0','1','0','0','0',"01","00","100")
            when opcode = "001000"  -- addi
        else ('0','0','0','0','1',"00","00","001")
            when opcode = "000100"; -- beq

    ALUControl <=
             "0010" when cSigs.ALUOp = "000" -- addu (LW,SW,ADDIU)
        else "0110" when cSigs.ALUOp = "001" -- subu (BEQ)
        else "0001" when cSigs.ALUOp = "011" -- OR (ORI)
        else "1001" when cSigs.ALUOp = "100" -- signed add (addi)

        else "0010" when cSigs.ALUOp = "010" and fcn = "100000" -- addu (ADD)
        else "0110" when cSigs.ALUOp = "010" and fcn = "100010" -- subu (SUB)
        else "0000" when cSigs.ALUOp = "010" and fcn = "100100" -- AND
        else "0001" when cSigs.ALUOp = "010" and fcn = "100101" -- OR
        else "0111" when cSigs.ALUOp = "010" and fcn = "101010";-- SLT

    RegDst <= cSigs.RegDst;
    Branch <= cSigs.Branch;
    MemRead <= cSigs.MemRead;
    RegWSrc <= cSigs.RegWSrc;
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
    signal sRegWrite, sMemWrite, sMemRead, sBranch, sZero, sRegDst : std_logic;
    signal sALUControl : std_logic_vector(3 downto 0);
    signal sRegWSrc, sALUSrc : std_logic_vector(1 downto 0);

    signal sIR: std_logic_vector(31 downto 0);
begin
    uut1: CPU_IR_DECODER port map (
        sIR, sRegDst, sBranch, sMemRead, sMemWrite,
        sRegWrite, sALUSrc, sRegWSrc, sALUControl
    );

    signalTests1: process
        variable buf: line;
    begin
        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
        wait for T/4;

        sIR <= x"00430820"; -- add t1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = "00");
        assert(sRegWSrc = "00");
        assert(sRegWrite = '1');
        assert(sMemRead = '0');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"8f210200"; -- lw $t1,0x200($t9)
        wait for T/2;
        assert(sRegDst = '0');
        assert(sALUSrc = "01");
        assert(sRegWSrc = "01");
        assert(sRegWrite = '1');
        assert(sMemRead = '1');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"0043082a"; -- slt $1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = "00");
        assert(sRegWSrc = "00");
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
