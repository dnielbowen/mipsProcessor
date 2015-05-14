library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_NO_HAZARDS is
end entity;

architecture impl1 of TB_MIPS_NO_HAZARDS is
    signal s_clk : std_logic := '1';
    signal s_pr : pipeline_registers;
begin
    uut: MIPS_NO_HAZARDS
        generic map (
            imem_filename      => "data/load_data.s.txt",
            dmem_init_filename => "data/data_mem_init.txt",
            dmem_filename      => "data/mem_trans_cpu.txt")
        port map (s_clk, s_pr);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for CLK_T/2;
    end process;

    pipeline_assertions: process
    begin
        wait for CLK_T/5; -- Stagger assertions with the clock
        s_pr.if_in.disable_pc_incr <= false; -- No pipeline stalls

        s_pr.id_in.enable_ext_br_data <= '0'; -- No forwarding yet
        s_pr.id_in.ext_br_data <= (others => '0');

        wait for CLK_T; -- if should output nop
        wait for CLK_T; -- if should output lui
        assert s_pr.if_out.instruction = x"3c101234"; -- lui $s0,0x1234
        assert s_pr.id_out.val_a = x"00000000";
        assert s_pr.id_out.val_b = x"00000000";
        assert s_pr.id_out.alu_op = F_SLL;
        assert s_pr.id_out.wb_reg_addr = "00000"; -- R0

        wait for CLK_T; -- if=ori, id=lui, ex=(NA)
        assert s_pr.id_out.val_a = x"12340000";
        assert s_pr.id_out.val_b = x"00000000";
        assert s_pr.id_out.alu_op = F_ADD;
        assert s_pr.id_out.enable_delta_pc = false;
        assert s_pr.id_out.mux_mem = MEM_NA;
        assert s_pr.id_out.wb_reg_addr = "10000"; -- S0
        assert s_pr.ex_out.alu_result = x"00000000";
        assert s_pr.ex_out.wb_reg_addr = "00000";
        assert s_pr.ex_out.mux_mem = MEM_NA;

        wait for CLK_T; -- if=nop, id=ori, ex=lui
        assert s_pr.id_out.val_a = x"00000000"; -- Reg A
        assert s_pr.id_out.val_b = x"0000ABCD";
        assert s_pr.id_out.alu_op = F_OR;
        assert s_pr.ex_out.alu_result = x"12340000";
        assert s_pr.ex_out.wb_reg_addr = "10000";
        assert s_pr.ex_out.mux_mem = MEM_NA;

        wait for CLK_T; -- if=nop, id=nop, ex=ori, mem=lui
        assert s_pr.mem_out.wb_reg_addr = "10000";
        assert s_pr.mem_out.val_f = x"12340000";
        wait for CLK_T; -- if=nop, id=nop, ex=nop, mem=ori wb=lui
        assert s_pr.mem_out.wb_reg_addr = "10001";

        wait for CLK_T;
        assert s_pr.if_out.instruction = x"02309020"; -- add $s2,$s1,$s0
        wait for 3*CLK_T; -- Propagate through id, ex, and mem
        assert s_pr.mem_out.wb_reg_addr = "10010";
        assert s_pr.mem_out.val_f = x"1234ABCD";

        wait;
    end process;
end architecture;

-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_DATA_HAZARDS is
end entity;

architecture impl1 of TB_MIPS_DATA_HAZARDS is
    signal s_clk : std_logic := '1';
    signal s_pr : pipeline_registers;
begin
    uut: MIPS_DATA_HAZARDS
        generic map (
            imem_filename      => "data/data_hazards.s.txt",
            dmem_init_filename => "data/data_mem_init.txt",
            dmem_filename      => "data/mem_trans_cpu.txt")
        port map (s_clk, s_pr);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for CLK_T/2;
    end process;

    pipeline_assertions: process
    begin
        wait for CLK_T/5; -- Stagger assertions with the clock

        s_pr.id_in.enable_ext_br_data <= '0'; -- No forwarding yet
        s_pr.id_in.ext_br_data <= (others => '0');

        wait for CLK_T; -- if should output nop
        wait for CLK_T; -- if should output lui
        assert s_pr.if_out.instruction = x"3c101234"; -- lui $s0,0x1234
        assert s_pr.id_out.val_a = x"00000000";

        wait for CLK_T; -- if=ori id=lui
        assert s_pr.if_out.instruction = x"36105678"; -- lui $s0,0x1234
        wait for CLK_T; -- id=ori ex=lui
        wait for CLK_T; -- ex=ori mem=lui
        assert s_pr.ex_out.alu_result = x"12345678";

        wait;
    end process;
end architecture;
