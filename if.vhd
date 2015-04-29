library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.components.all;

entity MIPS_IF is
    port (
        clk    : in  std_logic;
        if_in  : in  if_in;
        if_out : out if_out
    );
end entity;

architecture impl1 of MIPS_IF is
    signal pc, pc_incr : address;
begin
    imem1: MIPS_IMEM
        generic map ("imem_prog1.txt")
        port map(pc, if_out.instruction);

    choose_next_pc: process (clk) is
    begin
    if rising_edge(clk) then
        if if_in.use_branch_pc = '1' then
            pc <= if_in.branch_pc;
        else
            pc <= pc_incr;
        end if;
    end if;
    end process;

    pc_incr <= std_logic_vector(unsigned(pc) + 4);
    if_out.pc_curr <= pc;
    if_out.pc_incr <= pc_incr;
end architecture;
