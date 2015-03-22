library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- 1KB, byte-addressable, but always reads whole words
-- Doesn't allow simultaneous read/write
entity MEM_1K is
    port (
        CLK:   in  std_logic;
        ADDR:  in  std_logic_vector(9 downto 0);
        WR:    in  std_logic;                     -- Enable write
        DATAW: in  std_logic_vector(31 downto 0); -- Data write
        DATAR: out std_logic_vector(31 downto 0)  -- Data read
    );
end entity;

architecture impl1 of MEM_1K is
    type BYTE_ARR is array(natural range <>) of std_logic_vector(7 downto 0);
    signal mem: BYTE_ARR(1023 downto 0) := (others => (others => '0'));
begin

    p1: process (CLK) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        if rising_edge(CLK) then
            if WR = '1' then
                mem(i+3) <= DATAW(31 downto 24);
                mem(i+2) <= DATAW(23 downto 16);
                mem(i+1) <= DATAW(15 downto 08);
                mem(i+0) <= DATAW(07 downto 00);
                DATAR <= (others => '0');
            else
                DATAR <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);

                -- Add some initial data to the memory
                -- LIMITATIONS: this data is essentially read-only --- any 
                -- attempts to write to it will be undone when write is 
                -- de-asserted! Write to areas of memory other than this!
                mem( 0) <= x"04";
                mem( 4) <= x"02";
                mem( 5) <= x"FF";
                mem( 8) <= x"03";
                mem(12) <= x"04";
                mem(16) <= x"05";
                mem(64) <= x"40";
            end if;
        end if;
    end process;
end;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_MEM1K is end;

architecture impl1 of TB_MEM1K is
    signal sWrite,sClk: std_logic := '0';
    signal sAddr: std_logic_vector(9 downto 0);
    signal sDataR,sDataW: std_logic_vector(31 downto 0);
begin
    uut1: MEM_1K port map (sClk, sAddr, sWrite, sDataW, sDataR);

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

        sAddr <= "00" & x"00";
        sWrite <= '0';
        wait for T/2;
        assert (sDataR /= x"0000ff01");
        wait for T/2;
        assert (sDataR = x"0000ff01");

        wait for T;
        sAddr <= "00" & x"20";
        sDataW <= x"deadbeef";
        sWrite <= '1';
        wait for T;
        sWrite <= '0';
        wait for T;
        assert(sDataR = x"deadbeef");
 
        write(buf, string'("Assertions tb_mem1k complete"));
        writeline(output, buf);
        wait;
    end process;
end architecture;
