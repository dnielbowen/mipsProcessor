library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity MIPS_NO_HAZARDS is
    generic (
        imem_filename      : string;
        dmem_init_filename : string;
        dmem_filename      : string
    );
    port (
        clk : in std_logic;
        reg_debug : out pipeline_registers
    );
end entity;

architecture impl1 of MIPS_NO_HAZARDS is
    signal s_if_in  : if_in := (false, (others => '0'), false);
    signal s_if_out : if_out := ((others => '0'), (others => '0'));

    -- ID Instruction Decode stage
    signal s_id_in  : id_in  := (pc              => (others => '0'),
                                 instruction     => (others => '0'),
                                 enable_ext_br_data => '0',
                                 ext_br_data     => (others => '0'));

    signal s_id_out : id_out := (val_a           => (others => '0'),
                                 val_b           => (others => '0'),
                                 alu_op          => F_SLL,
                                 sh_amnt         => (others => '0'),

                                 enable_delta_pc => false,
                                 delta_pc        => (others => '0'),

                                 addr_a          => (others => '0'),
                                 addr_b          => (others => '0'),

                                 wb_reg_addr     => (others => '0'),
                                 reg_to_mem      => (others => '0'),
                                 mux_mem         => MEM_NA);

    signal s_ex_in  : ex_in;
    signal s_ex_out : ex_out;

    signal s_mem_in  : mem_in;
    signal s_mem_out : mem_out;

    signal s_wb_in   : wb_in;
begin
    ------------------------------------------ FETCH
    if_stage: MIPS_IF
        generic map (imem_filename)
        port map (clk, s_if_in, s_if_out);

    id_if_connections: process (s_id_out) is
    begin
        s_if_in.enable_delta_pc <= s_id_out.enable_delta_pc;
        s_if_in.delta_pc        <= s_id_out.delta_pc;
    end process;

    ------------------------------------------ DECODE
    id_stage: MIPS_ID_WB port map (clk, s_id_in, s_id_out, s_wb_in);

    if_id_connections: process (s_if_out) is
    begin
        s_id_in.pc              <= s_if_out.pc;
        s_id_in.instruction     <= s_if_out.instruction;
    end process;

    ------------------------------------------ EXECUTE
    ex_stage : MIPS_EX port map (clk, s_ex_in, s_ex_out);

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
        generic map (dmem_init_filename, dmem_filename)
        port map (clk, s_mem_in, s_mem_out);

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
        s_wb_in.wb_reg_addr <= s_mem_out.wb_reg_addr;
        s_wb_in.wb_data     <= s_mem_out.val_f;
    end process;

    ------------------------------------------

    reg_debug.if_in     <= s_if_in;
    reg_debug.if_out    <= s_if_out;
    reg_debug.id_in     <= s_id_in;
    reg_debug.id_out    <= s_id_out;
    reg_debug.ex_in     <= s_ex_in;
    reg_debug.ex_out    <= s_ex_out;
    reg_debug.mem_in    <= s_mem_in;
    reg_debug.mem_out   <= s_mem_out;
    reg_debug.wb_in     <= s_wb_in;
end architecture;
