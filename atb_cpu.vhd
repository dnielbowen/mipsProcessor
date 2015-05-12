library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_CPU is
end entity;

architecture impl1 of TB_MIPS_CPU is
    signal s_clk : std_logic := '1';

    signal s_if_in  : if_in := (false, (others => '0'), '0');
    signal s_if_out : if_out := ((others => '0'), (others => '0'));

    -- ID Instruction Decode stage
    signal s_id_in  : id_in  := (pc              => (others => '0'),
                                 instruction     => (others => '0'),
                                 enable_ext_br_data => '0',
                                 ext_br_data     => (others => '0'),
                                 wb_data         => (others => '0'),
                                 wb_reg_addr     => (others => '0'));

    signal s_id_out : id_out := (val_a           => (others => '0'),
                                 val_b           => (others => '0'),
                                 alu_op          => F_SLL,
                                 sh_amnt         => (others => '0'),

                                 enable_delta_pc => false,
                                 delta_pc        => (others => '0'),

                                 wb_reg_addr     => (others => '0'),
                                 reg_to_mem      => (others => '0'),
                                 mux_mem         => MEM_NA);

    signal s_ex_in  : ex_in;
    signal s_ex_out : ex_out;

    signal s_mem_in  : mem_in;
    signal s_mem_out : mem_out;
begin
    ------------------------------------------ FETCH
    if_stage: MIPS_IF
        generic map ("data/load_data.s.txt")
        port map (s_clk, s_if_in, s_if_out);

    id_if_connections: process (s_id_out) is
    begin
        s_if_in.enable_delta_pc <= s_id_out.enable_delta_pc;
        s_if_in.delta_pc        <= s_id_out.delta_pc;
    end process;

    ------------------------------------------ DECODE
    id_stage: MIPS_ID port map (s_clk, s_id_in, s_id_out);

    if_id_connections: process (s_if_out) is
    begin
        s_id_in.pc              <= s_if_out.pc;
        s_id_in.instruction     <= s_if_out.instruction;
    end process;

    ------------------------------------------ EXECUTE
    ex_stage : MIPS_EX port map (s_clk, s_ex_in, s_ex_out);

    id_ex_connections: process (s_id_out) is
    begin
        s_ex_in.val_a       <= s_id_out.val_a;
        s_ex_in.val_b       <= s_id_out.val_b;
        s_ex_in.alu_op      <= s_id_out.alu_op;
        s_ex_in.sh_amnt     <= s_id_out.sh_amnt;

        s_ex_in.reg_to_mem  <= s_id_out.reg_to_mem;

        s_ex_in.wb_reg_addr <= s_id_out.wb_reg_addr;
        s_ex_in.mux_mem     <= s_id_out.mux_mem;
    end process;

    ------------------------------------------ MEMORY
    mem_stage : MIPS_MEM
        generic map ("data/data_mem_init.txt", "data/mem_trans_cpu.txt")
        port map (s_clk, s_mem_in, s_mem_out);

    id_mem_connections: process (s_ex_out) is
    begin
        s_mem_in.alu_result     <= s_ex_out.alu_result;
        s_mem_in.reg_to_mem     <= s_ex_out.reg_to_mem;

        s_mem_in.wb_reg_addr    <= s_ex_out.wb_reg_addr;
        s_mem_in.mux_mem        <= s_ex_out.mux_mem;
    end process;

    ------------------------------------------ WRITEBACK

    id_wb_connections: process (s_mem_out) is
    begin
        s_id_in.wb_reg_addr <= s_mem_out.wb_reg_addr;
        s_id_in.wb_data     <= s_mem_out.val_f;
    end process;

    ------------------------------------------

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for CLK_T/2;
    end process;

    pipeline_assertions: process
    begin
        wait for CLK_T/5; -- Stagger assertions with the clock
        s_if_in.disable_pc_incr <= '0'; -- No pipeline stalls

        s_id_in.enable_ext_br_data <= '0'; -- No forwarding yet
        s_id_in.ext_br_data <= (others => '0');

        wait for CLK_T; -- if should output nop
        wait for CLK_T; -- if should output lui
        assert s_if_out.instruction = x"3c101234"; -- lui $s0,0x1234
        assert s_id_out.val_a = x"00000000";
        assert s_id_out.val_b = x"00000000";
        assert s_id_out.alu_op = F_SLL;
        assert s_id_out.wb_reg_addr = "00000"; -- R0

        wait for CLK_T; -- if=ori, id=lui, ex=(NA)
        assert s_id_out.val_a = x"12340000";
        assert s_id_out.val_b = x"00000000";
        assert s_id_out.alu_op = F_ADD;
        assert s_id_out.enable_delta_pc = false;
        assert s_id_out.mux_mem = MEM_NA;
        assert s_id_out.wb_reg_addr = "10000"; -- S0
        assert s_ex_out.alu_result = x"00000000";
        assert s_ex_out.wb_reg_addr = "00000";
        assert s_ex_out.mux_mem = MEM_NA;

        wait for CLK_T; -- if=nop, id=ori, ex=lui
        assert s_id_out.val_a = x"00000000"; -- Reg A
        assert s_id_out.val_b = x"0000ABCD";
        assert s_id_out.alu_op = F_OR;
        assert s_ex_out.alu_result = x"12340000";
        assert s_ex_out.wb_reg_addr = "10000";
        assert s_ex_out.mux_mem = MEM_NA;

        wait for CLK_T; -- if=nop, id=nop, ex=ori, mem=lui
        assert s_mem_out.wb_reg_addr = "10000";
        assert s_mem_out.val_f = x"12340000";
        wait for CLK_T; -- if=nop, id=nop, ex=nop, mem=ori wb=lui
        assert s_mem_out.wb_reg_addr = "10001";

        wait for CLK_T;
        assert s_if_out.instruction = x"02309020"; -- add $s2,$s1,$s0
        wait for 3*CLK_T; -- Propagate through id, ex, and mem
        assert s_mem_out.wb_reg_addr = "10010";
        assert s_mem_out.val_f = x"1234ABCD";

        wait;
    end process;
end architecture;
