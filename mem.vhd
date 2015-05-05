library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_MEM is
    port (
        clk    : in  std_logic;
        mem_in  : in  mem_in;
        mem_out : out mem_out
    );
end entity;

architecture impl1 of MIPS_MEM is
    signal mem_read_data : word;
begin
    dmem1: MIPS_DMEM
        generic map ("data/data_mem_init.txt", "data/mem_trans.txt")
        port map(
            clk => clk,
            addr => mem_in.alu_result,
            wr_enable => mem_in.enable_memw,
            wr_data => mem_in.reg_to_mem,
            data_out => mem_read_data);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            -- For a load, read memory output, for no mem access, set it to the 
            -- ALU operation, and for a store, it doesn't matter (thus ALU 
            -- op/address)
            if mem_in.enable_memr = '1' then
                mem_out.val_f <= mem_read_data;
            else
                mem_out.val_f <= mem_in.alu_result;
            end if;

            -- For a store, set to register zero (disables write-back), 
            -- otherwise pass the register through
            if mem_in.enable_memw = '1' then
                mem_out.wb_reg_addr <= (others => '0');
            else
                mem_out.wb_reg_addr <= mem_in.wb_reg_addr;
            end if;
        end if;
    end process;
end architecture;
