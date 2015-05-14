library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_EX is
    port (
        clk    : in  std_logic;
        p_ex_in  : in  ex_in;
        p_ex_out : out ex_out
    );
end entity;

architecture impl1 of MIPS_EX is
    signal s_alu_result : word := (others => '0');

    -- Use of this signal prevents undefined signals before rising clock
    signal s_out : ex_out :=
        ((others=>'0'), (others=>'0'), (others=>'0'), MEM_NA);
begin
    alu: MIPS_ALU
        port map(
            alu_op => p_ex_in.alu_op,
            sh_amnt => p_ex_in.sh_amnt,
            a => p_ex_in.val_a,
            b => p_ex_in.val_b,
            f => s_alu_result);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            if p_ex_in.nop then
                -- Contents are neither written to memory nor written back to a 
                -- register, thus are effetively discarded
                s_out.mux_mem <= MEM_NA;
                s_out.wb_reg_addr <= R_0;
            else
                s_out.mux_mem <= p_ex_in.mux_mem;
                s_out.wb_reg_addr <= p_ex_in.wb_reg_addr;
            end if;

            s_out.alu_result <= s_alu_result;
            s_out.reg_to_mem <= p_ex_in.reg_to_mem;
        end if;
    end process;

    p_ex_out <= s_out;
end architecture;
