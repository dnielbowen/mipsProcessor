library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

entity MIPS_IF is
    generic (imem_filename : string := "data/instr_mem.txt");
    port (
        clk    : in  std_logic;
        if_in  : in  if_in;
        if_out : out if_out
    );
end entity;

architecture impl1 of MIPS_IF is
    signal s_pc : address;
    signal s_instruction : word;
begin
    imem1: MIPS_IMEM
        generic map (imem_filename)
        port map(s_pc, s_instruction);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            if if_in.disable_pc_incr = '0' then
                if if_in.enable_delta_pc = '1' then
                    s_pc <= unsigned(s_pc) + 4 + signed(if_in.delta_pc);
                else
                    s_pc <= unsigned(s_pc) + 4;
                end if;
            end if;

            if_out.pc <= s_pc;
            if_out.instruction <= s_instruction;
        end if;
    end process;
end architecture;
