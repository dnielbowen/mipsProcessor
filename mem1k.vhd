library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- 1K x 32-bit words, does not allow simultaneous read/write
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
    type WORD_ARR is array(natural range <>) of std_logic_vector(31 downto 0);
    signal mem: WORD_ARR(1023 downto 0);
begin
    p1: process
    begin
        if rising_edge(CLK) then
            if WR = '1' then
                mem(conv_integer(ADDR)) <= DATAW;
                DATAR <= (others => '0');
            else
                DATAR <= mem(conv_integer(ADDR));
            end if;
        end if;
    end process;
end;
