library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- Read-only (instruction) memory, 1KB
entity MEM_RO_1K is
    port (
        CLK:  in  std_logic; -- WARNING: clock not used!
        ADDR: in  std_logic_vector(9 downto 0);
        DATA: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of MEM_RO_1K is
    type BYTE_ARR is array(1023 downto 0) of std_logic_vector(7 downto 0); 
    signal mem: BYTE_ARR := (others => (others => '0'));
begin
    -- Enter the program (opcodes) here

    -- loadStoreAdd.s
--    -- 0x00000000 nop
--    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
--    -- 0x8c1c0000 lw gp,0(zero)
--    mem(4)<=x"00"; mem(5)<=x"00"; mem(6)<=x"1c"; mem(7)<=x"8c";
--    -- 0x8f890004 lw t1,4(gp)
--    mem(8)<=x"04"; mem(9)<=x"00"; mem(10)<=x"89"; mem(11)<=x"8f";
--    -- 0x8f8a0040 lw t2,64(gp)
--    mem(12)<=x"40"; mem(13)<=x"00"; mem(14)<=x"8a"; mem(15)<=x"8f";
--    -- 0x012a5820 add t3,t1,t2
--    mem(16)<=x"20"; mem(17)<=x"58"; mem(18)<=x"2a"; mem(19)<=x"01";
--    -- 0xaf8b0044 sw t3,68(gp)
--    mem(20)<=x"44"; mem(21)<=x"00"; mem(22)<=x"8b"; mem(23)<=x"af";
--    -- 0x1000ffff b 18 <here>
--    mem(24)<=x"ff"; mem(25)<=x"ff"; mem(26)<=x"00"; mem(27)<=x"10";

    -- addImmediates.s
--    -- 0x00000000 nop
--    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
--    -- 0x3c083434 lui t0,0x3434
--    mem(4)<=x"34"; mem(5)<=x"34"; mem(6)<=x"08"; mem(7)<=x"3c";
--    -- 0x3c09bf88 lui t1,0xbf88
--    mem(8)<=x"88"; mem(9)<=x"bf"; mem(10)<=x"09"; mem(11)<=x"3c";
--    -- 0x35296210 ori t1,t1,0x6210
--    mem(12)<=x"10"; mem(13)<=x"62"; mem(14)<=x"29"; mem(15)<=x"35";
--    -- 0x354affff ori t2,t2,0xffff
--    mem(16)<=x"ff"; mem(17)<=x"ff"; mem(18)<=x"4a"; mem(19)<=x"35";
--    -- 0x356bfefe ori t3,t3,0xfefe
--    mem(20)<=x"fe"; mem(21)<=x"fe"; mem(22)<=x"6b"; mem(23)<=x"35";
--    -- 0x014be022 sub gp,t2,t3
--    mem(24)<=x"22"; mem(25)<=x"e0"; mem(26)<=x"4b"; mem(27)<=x"01";

    -- fibonacci.s
    -- 0x00000000 nop
    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
    -- 0x241c0100 li gp,256
    mem(4)<=x"00"; mem(5)<=x"01"; mem(6)<=x"1c"; mem(7)<=x"24";
    -- 0x24090032 li t1,50
    mem(8)<=x"32"; mem(9)<=x"00"; mem(10)<=x"09"; mem(11)<=x"24";
    -- 0x240a0000 li t2,0
    mem(12)<=x"00"; mem(13)<=x"00"; mem(14)<=x"0a"; mem(15)<=x"24";
    -- 0xaf8a0000 sw t2,0(gp)
    mem(16)<=x"00"; mem(17)<=x"00"; mem(18)<=x"8a"; mem(19)<=x"af";
    -- 0x240b0001 li t3,1
    mem(20)<=x"01"; mem(21)<=x"00"; mem(22)<=x"0b"; mem(23)<=x"24";
    -- 0xaf8b0004 sw t3,4(gp)
    mem(24)<=x"04"; mem(25)<=x"00"; mem(26)<=x"8b"; mem(27)<=x"af";
    -- 0x279c0008 addiu gp,gp,8
    mem(28)<=x"08"; mem(29)<=x"00"; mem(30)<=x"9c"; mem(31)<=x"27";
    -- 0x2129fffe addi t1,t1,-2
    mem(32)<=x"fe"; mem(33)<=x"ff"; mem(34)<=x"29"; mem(35)<=x"21";
    -- 0x8f8afff8 lw t2,-8(gp)
    mem(36)<=x"f8"; mem(37)<=x"ff"; mem(38)<=x"8a"; mem(39)<=x"8f";
    -- 0x8f8bfffc lw t3,-4(gp)
    mem(40)<=x"fc"; mem(41)<=x"ff"; mem(42)<=x"8b"; mem(43)<=x"8f";
    -- 0x014b6020 add t4,t2,t3
    mem(44)<=x"20"; mem(45)<=x"60"; mem(46)<=x"4b"; mem(47)<=x"01";
    -- 0xaf8c0000 sw t4,0(gp)
    mem(48)<=x"00"; mem(49)<=x"00"; mem(50)<=x"8c"; mem(51)<=x"af";
    -- 0x279c0004 addiu gp,gp,4
    mem(52)<=x"04"; mem(53)<=x"00"; mem(54)<=x"9c"; mem(55)<=x"27";
    -- 0x2129ffff addi t1,t1,-1
    mem(56)<=x"ff"; mem(57)<=x"ff"; mem(58)<=x"29"; mem(59)<=x"21";
    -- 0x0120402a slt t0,t1,zero
    mem(60)<=x"2a"; mem(61)<=x"40"; mem(62)<=x"20"; mem(63)<=x"01";
    -- 0x1100fff8 beqz t0,24 <fibonacciLoop>
    mem(64)<=x"f8"; mem(65)<=x"ff"; mem(66)<=x"00"; mem(67)<=x"11";
    -- 0x1000ffff b 44 <finishedLoop>
    mem(68)<=x"ff"; mem(69)<=x"ff"; mem(70)<=x"00"; mem(71)<=x"10";

    p1: process (ADDR) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        DATA <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
    end process;
end;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_MEM_RO_1K is end;

architecture impl1 of TB_MEM_RO_1K  is
    signal sClk: std_logic := '0';
    signal sAddr: std_logic_vector(9 downto 0);
    signal sData: std_logic_vector(31 downto 0);
begin
    uut1: MEM_RO_1K port map (sClk, sAddr, sData);

    clk1: process is
    begin
        sClk <= not sClk;
        wait for T/2;
    end process;

    signalTests1: process
        variable buf: line;
    begin
        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
        wait for T/4;

        sAddr <= "0000010100";
        wait for T/2;
        assert (sData /= x"1000ffff");
        wait for T/2;
        assert (sData = x"1000ffff");
 
        wait;
    end process;
end architecture;
