library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_EX is
    port (
        clk    : in  std_logic;
        ex_in  : in  ex_in;
        ex_out : out ex_out
    );
end entity;

architecture impl1 of MIPS_EX is
    signal s_alu_result : word := (others => '0');
begin
    alu: MIPS_ALU
        port map(
            alu_op => ex_in.alu_op,
            a => ex_in.val_a,
            b => ex_in.val_b,
            f => s_alu_result);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            ex_out.wb_reg_addr <= ex_in.wb_reg_addr;
            ex_out.mux_mem <= ex_in.mux_mem;
            ex_out.reg_to_mem <= ex_in.reg_to_mem;
            ex_out.alu_result <= s_alu_result;
        end if;
    end process;
end architecture;
