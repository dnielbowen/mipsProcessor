library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; -- vs numeric_std because this allows uint+int
use work.components.all;

entity MIPS_ID is
    port (
        clk    : in  std_logic;
        id_in  : in  id_in;
        id_out : out id_out
    );
end entity;

architecture impl1 of MIPS_ID is
    type mux_val_a_t is (
        M_REGA,  -- Register A value
        M_IMMUP, -- Upper immediate, useful for lui
        M_R_0,   -- Zeros out the value (effectively passing $0)
        M_PC     -- For passing PC to $31 on bal/jal
    );
    type mux_val_b_t is (
        M_REGB, -- Register B value
        M_IMMS, -- Sign-ext immediate, useful for r-ops and address calcs
        M_IMMU, -- Zero-ext imm, useful for logical immediates (andi, etc)
        M_R_0   -- Zeros out the value (effectively passing $0)
    );
    type branch_criteria_t is (
        B_J,    -- Unconditional branch (jump)
        B_EQ,   -- Check for reg_a = reg_b
        B_NE,   -- reg_a /= reg_b
        B_LEZ,  -- reg_a(31) = '1' or reg_a = 0
        B_LTZ,  -- reg_a(31) = '1' and reg_a /= 0
        B_GEZ,  -- reg_a(31) = '0' or reg_a = 0
        B_GTZ,  -- reg_a(31) = '0' and reg_a /= 0
        B_NA    -- Disable branching
    );

    -- Determines information ultimately seen in the other pipeline stages
    type control_word is record
        -- IF
        branch_criteria : branch_criteria_t;

        -- EX
        mux_val_a : mux_val_a_t; -- Determine outputs
        mux_val_b : mux_val_b_t;
        alu_op : op_func; -- The ALU operation that should be performed in EX

        -- MEM
        mux_mem : mux_mem_t; -- Determines what the memory stage should do

        -- WB
        wb_reg_addr : reg_address; -- The register address to pass to the WB
                                   -- stage (R_0 to disable WB)
    end record;

    signal reg_a, reg_b : word := (others => '0');

    signal jimm_sign_ext : word;
    signal imm_sign_ext : word;
        -- Sign-extended instruction immediates (jimm = jump immediate)

    signal enable_reg_wr : std_logic;
        -- Used for the WB stage (set to 1 if wb_reg_addr != $0)

    signal instr_imm       : std_logic_vector(15 downto  0);
    signal instr_jimm      : std_logic_vector(25 downto  0); -- Jump immediate
    signal instr_sh_amnt   : std_logic_vector( 4 downto  0);
    signal instr_rs, instr_rt, instr_rd : reg_address;
    signal instr_func      : op_func;
    signal instr_opcode    : opcode;

    signal cw : control_word;
begin
    reg_file: MIPS_REG port map(
        clk => clk,
        addr_a => instr_rs,
        addr_b => instr_rt,
        data_a => reg_a,
        data_b => reg_b,
        wr_enable => enable_reg_wr,
        wr_addr => id_in.wb_reg_addr,
        wr_data => id_in.wb_data);

    enable_reg_wr <= '0' when (id_in.wb_reg_addr = R_0) else '1';

    -- Extract portions of the instruction opcode
    instr_imm     <= id_in.instruction(15 downto  0);
    instr_jimm    <= id_in.instruction(25 downto  0);
    instr_sh_amnt <= id_in.instruction(10 downto  6);
    instr_func    <= id_in.instruction( 5 downto  0);
    instr_rs      <= id_in.instruction(25 downto 21);
    instr_rt      <= id_in.instruction(20 downto 16);
    instr_rd      <= id_in.instruction(15 downto 11);
    instr_opcode  <= id_in.instruction(31 downto 26);

    -- Sign-extend immediate and jump-immediate formats
    imm_sign_ext  <= x"FFFF" & instr_imm
                     when instr_imm(15) = '1' else
                     x"0000" & instr_imm;
    jimm_sign_ext <= "111111" & instr_jimm
                     when instr_jimm(25) = '1' else
                     "000000" & instr_jimm;
    
    instruction_decode: process (instr_func) is
    begin
        case instr_opcode is
            -- R-type ALU ops
            when OPCODE_SPECIAL =>
                case instr_func is
                    when F_MULT | F_MULTU | F_DIV | F_DIVU | F_ADD | F_ADDU |
                         F_SUB  | F_SUBU  | F_AND | F_OR   | F_XOR | F_NOR  |
                         F_SLT  | F_SLTU  | F_SLL | F_SRL  | F_SLLV| F_SRLV =>
                        cw <= (branch_criteria => B_NA,
                               mux_val_a       => M_REGA,
                               mux_val_b       => M_REGB,
                               alu_op          => instr_func,
                               mux_mem         => MEM_NA,
                               wb_reg_addr     => instr_rd);
                    when others =>
                        cw <= (B_NA, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                end case;

            -- Single-register branches
            when OPCODE_REGIMM  =>
                case instr_rt is
                    when RT_BLTZ =>
                        cw <= (B_LTZ, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                    when RT_BGEZ =>
                        cw <= (B_GEZ, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                    when RT_BLTZAL =>
                        cw <= (B_LTZ,  M_PC, M_R_0, F_ADDU, MEM_NA, R_31);
                    when RT_BGEZAL =>
                        cw <= (B_GEZ,  M_PC, M_R_0, F_ADDU, MEM_NA, R_31);
                    when others =>
                end case;

            -- Branches
            when OPCODE_J    =>
                cw <= (   B_J,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_JAL  =>
                cw <= (   B_J,    M_PC,  M_R_0,  F_ADDU, MEM_NA, R_31);
            when OPCODE_BEQ  =>
                cw <= (  B_EQ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BNE  =>
                cw <= (  B_NE,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BLEZ =>
                cw <= ( B_LEZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BGTZ =>
                cw <= ( B_GTZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);

            -- Immediates
            when OPCODE_ADDI  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_NA, instr_rt);
            when OPCODE_ADDIU =>
                cw <= (B_NA,  M_REGA, M_IMMS,  F_ADDU, MEM_NA, instr_rt);
            when OPCODE_SLTI  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when OPCODE_SLTIU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when OPCODE_ANDI  =>
                cw <= (B_NA,  M_REGA, M_IMMU,   F_AND, MEM_NA, instr_rt);
            when OPCODE_ORI   =>
                cw <= (B_NA,  M_REGA, M_IMMU,    F_OR, MEM_NA, instr_rt);
            when OPCODE_XORI  =>
                cw <= (B_NA,  M_REGA, M_IMMU,   F_XOR, MEM_NA, instr_rt);
            when OPCODE_LUI   =>
                cw <= (B_NA, M_IMMUP,  M_R_0,   F_ADD, MEM_NA, instr_rt);

            -- Loads
            when OPCODE_LB  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LB, instr_rt);
            when OPCODE_LH  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LH, instr_rt);
            when OPCODE_LW  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LW, instr_rt);
            when OPCODE_LBU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_LBU, instr_rt);
            when OPCODE_LHU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_LHU, instr_rt);

            -- Stores
            when OPCODE_SB =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SB, R_0);
            when OPCODE_SH =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SH, R_0);
            when OPCODE_SW =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SW, R_0);
            when others =>
        end case;
    end process;

    writeback_process: process (clk) is
    begin
    end process;

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            case cw.branch_criteria is
                when B_J =>
                    id_out.delta_pc <= jimm_sign_ext(29 downto 0) & "00";
                when others =>
                    id_out.delta_pc <=  imm_sign_ext(29 downto 0) & "00";
            end case;

            case cw.branch_criteria is
                when B_NA   => id_out.enable_delta_pc <= false;
                when B_J    => id_out.enable_delta_pc <= true;
                when B_EQ   => id_out.enable_delta_pc <= reg_a = reg_b;
                when B_NE   => id_out.enable_delta_pc <= reg_a /= reg_b;
                when B_LTZ  => id_out.enable_delta_pc <= reg_a(31) = '1';
                when B_GTZ  => id_out.enable_delta_pc <= reg_a(31) = '0';
                when B_LEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '1') or (reg_a = x"00000000");
                when B_GEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '0') or (reg_a = x"00000000");
                when others => id_out.enable_delta_pc <= false;
            end case;

            case cw.mux_val_a is
                when M_REGA  => id_out.val_a <= reg_a;
                when M_IMMUP => id_out.val_a <= instr_imm & x"0000";
                when M_R_0   => id_out.val_a <= (others => '0');
                when M_PC    => id_out.val_a <= id_in.pc;
            end case;

            case cw.mux_val_b is
                when M_IMMS => id_out.val_b <= imm_sign_ext;
                when M_IMMU => id_out.val_b <= x"0000" & instr_imm;
                when M_REGB => id_out.val_b <= reg_b;
                when M_R_0  => id_out.val_b <= (others => '0');
            end case;

            id_out.alu_op <= cw.alu_op;
            id_out.sh_amnt <= instr_sh_amnt; -- Only observed on shifts

            id_out.wb_reg_addr <= cw.wb_reg_addr;
            id_out.reg_to_mem <= reg_b;
            id_out.mux_mem <= cw.mux_mem;
        end if;
    end process;
end architecture;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_ID is
end entity;

architecture impl1 of TB_MIPS_ID is
    signal s_clk : std_logic := '0';

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
begin
    mips_id1 : MIPS_ID port map (s_clk, s_id_in, s_id_out);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for CLK_T/2;
    end process;

    pipeline_assertions: process
    begin
        wait for CLK_T/5;      -- Stagger clock with assertions
        s_id_in.pc <= x"deadbeef";
        s_id_in.instruction <= x"3c10ffff"; -- lui s0,0xffff

        wait for CLK_T;
        assert s_id_out.wb_reg_addr = "10000";
        assert s_id_out.enable_delta_pc = false;
        assert s_id_out.val_a = x"ffff0000";
        assert s_id_out.val_b = x"00000000";
        assert s_id_out.alu_op = F_ADD;
        assert s_id_out.mux_mem = MEM_NA;
        
        -- Now test writeback
        s_id_in.wb_reg_addr <= "10000"; -- $s0
        s_id_in.wb_data <= x"12341234";
        wait for CLK_T;
        -- Make sure we didn't slip it through yet
        assert s_id_out.reg_to_mem /= x"12341234";
        wait for CLK_T;
        -- Now we should see s0 at the output
        assert s_id_out.reg_to_mem = x"12341234";

        wait;
    end process;
end architecture;
