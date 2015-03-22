library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- Read-only (instruction) memory, 1KB
entity MEM_RO_1K is
    port (
        CLK:  in  std_logic;
        ADDR: in  std_logic_vector(9 downto 0);
        DATA: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of MEM_RO_1K is
    type BYTE_ARR is array(1023 downto 0) of std_logic_vector(7 downto 0); 
    signal mem: BYTE_ARR := (others => (others => '0'));
begin
    -- Enter the program (opcodes) here
    --mem( 0) <= x"8c1c0000"; -- lw    gp,0(zero)
    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"1c"; mem(3)<=x"8c";
    mem( 4) <= x"8f890004"; -- lw    t1,4(gp)
    mem( 8) <= x"8f8a0040"; -- lw    t2,64(gp)
    mem(12) <= x"012a5820"; -- add   t3,t1,t2
    mem(16) <= x"af8b0044"; -- sw    t3,68(gp)
    mem(20) <= x"1000ffff"; -- b     14 <here>

    p1: process (CLK) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        if rising_edge(CLK) then
            DATA <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
        end if;
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
