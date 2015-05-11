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
    signal s_pc, s_pc_out : address := (others => '0');
    signal s_instruction, s_instruction_out : word := (others => '0');
begin
    imem1: MIPS_IMEM
        generic map (imem_filename)
        port map(s_pc, s_instruction);

    -- Use of these _out signals allows the initial state to be 0
    if_out.instruction <= s_instruction_out;
    if_out.pc <= s_pc_out;

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            if if_in.disable_pc_incr = '0' then
                if if_in.enable_delta_pc then
                    s_pc <= unsigned(s_pc) + 4 + signed(if_in.delta_pc);
                else
                    s_pc <= unsigned(s_pc) + 4;
                end if;
            end if;

            s_pc_out <= s_pc;
            s_instruction_out <= s_instruction;
        end if;
    end process;
end architecture;
