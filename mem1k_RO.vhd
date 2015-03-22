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
    -- 0x00000000 nop
    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
    -- 0x8c1c0000 lw gp,0(zero)
    mem(4)<=x"00"; mem(5)<=x"00"; mem(6)<=x"1c"; mem(7)<=x"8c";
    -- 0x8f890004 lw t1,4(gp)
    mem(8)<=x"04"; mem(9)<=x"00"; mem(10)<=x"89"; mem(11)<=x"8f";
    -- 0x8f8a0040 lw t2,64(gp)
    mem(12)<=x"40"; mem(13)<=x"00"; mem(14)<=x"8a"; mem(15)<=x"8f";
    -- 0x012a5820 add t3,t1,t2
    mem(16)<=x"20"; mem(17)<=x"58"; mem(18)<=x"2a"; mem(19)<=x"01";
    -- 0xaf8b0044 sw t3,68(gp)
    mem(20)<=x"44"; mem(21)<=x"00"; mem(22)<=x"8b"; mem(23)<=x"af";
    -- 0x1000ffff b 18 <here>
    mem(24)<=x"ff"; mem(25)<=x"ff"; mem(26)<=x"00"; mem(27)<=x"10";

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
