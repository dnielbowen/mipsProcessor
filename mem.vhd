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
    signal mem_read_data, mem_write_data : word;
    signal wr_enable : std_logic;

    signal b_sign_ext, h_sign_ext : word;
    signal data_size : std_logic_vector(1 downto 0) := "11"; -- Read 4 Bytes
begin
    dmem1: MIPS_DMEM
        generic map ("data/data_mem_init.txt", "data/mem_trans.txt")
        port map(
            clk => clk,
            addr => mem_in.alu_result,
            wr_enable => wr_enable,
            wr_data => mem_write_data,
            data_size => data_size,
            data_out => mem_read_data);

    data_size <= "00" when (mem_in.mux_mem = MEM_SB) else
                 "01" when (mem_in.mux_mem = MEM_SH) else "11";

    mem_write_data <= mem_in.reg_to_mem;

    --wr_enable <= '1' when (mem_in.mux_mem = MEM_SW|MEM_SB) else '0'; -- XXX

    b_sign_ext <= x"FFFFFF" & mem_read_data(7 downto 0)
                  when mem_read_data(7) = '1' else
                  x"000000" & mem_read_data(7 downto 0);

    h_sign_ext <= x"FFFF" & mem_read_data(15 downto 0)
                  when mem_read_data(15) = '1' else
                  x"0000" & mem_read_data(15 downto 0);

    alignment_assertions: process (mem_in.reg_to_mem, mem_in.mux_mem) is
    begin
        case mem_in.mux_mem is
            when MEM_SH => assert mem_in.alu_result(0) = '0'
                report "Half-word store not 2 byte-aligned";
            when MEM_SW => assert mem_in.alu_result(1 downto 0) = "00"
                report "Word store not 4 byte-aligned";
            when others =>
        end case;
    end process;

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            case mem_in.mux_mem is
                when MEM_LB  =>
                    mem_out.val_f <= b_sign_ext;
                when MEM_LBU =>
                    mem_out.val_f <= x"000000" & mem_read_data(7 downto 0);
                when MEM_LH =>
                    mem_out.val_f <= h_sign_ext;
                when MEM_LHU =>
                    mem_out.val_f <= x"0000" & mem_read_data(15 downto 0);
                when MEM_LW  => mem_out.val_f <= mem_read_data;
                -- TODO: MEM_LWL, MEM_LWR
                when others =>
                    mem_out.val_f <= mem_in.alu_result;
            end case;

            -- Note that on stores, we don't want to save anything --- however 
            -- the ID stage should already have disabled WB (by setting 
            -- wb_reg_addr to R_0)
            mem_out.wb_reg_addr <= mem_in.wb_reg_addr;
        end if;
    end process;
end architecture;
