library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- Read-only (instruction) memory, 1K x 32-bit words
entity MEM_RO_1K is
    port (
        CLK:  in  std_logic;
        ADDR: in  std_logic_vector(9 downto 0);
        DATA: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of MEM_RO_1K is
    type WORD_ARR is array(1023 downto 0) of std_logic_vector(31 downto 0); 
    signal mem: WORD_ARR := (others => (others => '0'));
begin
    -- Enter the program (opcodes) here
    mem( 0) <= x"8c1c0000"; -- lw    gp,0(zero)
    mem( 4) <= x"8f890004"; -- lw    t1,4(gp)
    mem( 8) <= x"8f8a0040"; -- lw    t2,64(gp)
    mem(12) <= x"012a5820"; -- add   t3,t1,t2
    mem(16) <= x"af8b0044"; -- sw    t3,68(gp)
    mem(20) <= x"1000ffff"; -- b     14 <here>

    p1: process
    begin
        if rising_edge(CLK) then
            DATA <= mem(conv_integer(ADDR));
        end if;
    end process;
end;
