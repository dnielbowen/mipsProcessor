library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

entity MIPS_IF is
    generic (imem_filename : string := "data/instr_mem.txt");
    port (
        clk    : in  std_logic;
        p_if_in  : in  if_in;
        p_if_out : out if_out
    );
end entity;

architecture impl1 of MIPS_IF is
    signal s_pc, s_pc_out : address := (others => '0');
    signal s_instruction, s_instruction_out : word := (others => '0');

    signal s_out : if_out := ((others => '0'), (others => '0'));
begin
    imem1: MIPS_IMEM
        generic map (imem_filename)
        port map(s_pc, s_instruction);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            if p_if_in.disable_pc_incr = '0' then
                if p_if_in.enable_delta_pc then
                    s_pc <= unsigned(s_pc) + 4 + signed(p_if_in.delta_pc);
                else
                    s_pc <= unsigned(s_pc) + 4;
                end if;
            end if;

            s_out.pc <= s_pc;
            s_out.instruction <= s_instruction;
        end if;
    end process;

    p_if_out <= s_out;
end architecture;
