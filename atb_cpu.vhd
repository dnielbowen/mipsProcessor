library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_CPU is
end entity;

architecture impl1 of TB_MIPS_CPU is
    signal s_clk : std_logic := '0';

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
        generic map ("data/instr_test_basic.s.txt")
        port map (s_clk, s_if_in, s_if_out);

    if_id_connections: process (s_if_out, s_id_out) is
    begin
        s_id_in.pc              <= s_if_out.pc;
        s_id_in.instruction     <= s_if_out.instruction;

        s_if_in.enable_delta_pc <= s_id_out.enable_delta_pc;
        s_if_in.delta_pc        <= s_id_out.delta_pc;
    end process;

    ------------------------------------------ DECODE
    id_stage: MIPS_ID port map (s_clk, s_id_in, s_id_out);
--
--    id_ex_connections: process (s_id_out) is
--    begin
--        s_ex_in.val_a       <= s_id_out.val_a;
--        s_ex_in.val_b       <= s_id_out.val_b;
--        s_ex_in.alu_op      <= s_id_out.alu_op;
--        s_ex_in.sh_amnt     <= s_id_out.sh_amnt;
--
--        s_ex_in.reg_to_mem  <= s_id_out.reg_to_mem;
--
--        s_ex_in.wb_reg_addr <= s_id_out.wb_reg_addr;
--        s_ex_in.mux_mem     <= s_id_out.mux_mem;
--    end process;
--
--    ------------------------------------------ EXECUTE
--    ex_stage : MIPS_EX port map (s_clk, s_ex_in, s_ex_out);
--
--    id_mem_connections: process (s_ex_out) is
--    begin
--        s_mem_in.alu_result     <= s_ex_out.alu_result;
--        s_mem_in.reg_to_mem     <= s_ex_out.reg_to_mem;
--
--        s_mem_in.wb_reg_addr    <= s_ex_out.wb_reg_addr;
--        s_mem_in.mux_mem        <= s_ex_out.mux_mem;
--    end process;
--
--    ------------------------------------------ MEMORY
--    mem_stage : MIPS_MEM
--        generic map ("data/data_mem_init.txt", "data/mem_trans_cpu.txt")
--        port map (s_clk, s_mem_in, s_mem_out);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for 5 ns;
    end process;

    signalTests1: process
    begin
        s_if_in.disable_pc_incr <= '0'; -- No pipeline stalls

        s_id_in.enable_ext_br_data <= '0'; -- No forwarding yet
        s_id_in.ext_br_data <= (others => '0');


        -- From MEM
        s_id_in.wb_reg_addr <= (others => '0'); -- R0
        s_id_in.wb_data <= (others => '0');

        wait for 10 ns;
        assert s_if_out.pc = x"00000004";

        wait;
    end process;
end architecture;
