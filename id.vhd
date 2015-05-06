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
        B_NONE  -- Disable branching
    );

    -- Determines information ultimately seen in the other pipeline stages
    type control_word is record
        -- IF
        branch_criteria : branch_criteria_t;

        -- EX
        mux_val_a : mux_val_a_t;
        mux_val_b : mux_val_b_t;
            -- Determine outputs
        alu_op : op_func;
            -- The ALU operation that should be performed in EX

        -- MEM
        mux_mem : mux_mem_t;
            -- Determines what the memory stage should do

        -- WB
        wb_reg_addr : reg_address;
            -- The register address to pass to the WB stage (0 to disable WB)
    end record;

    signal reg_a, reg_b : word;

    signal jimm_sign_ext : word;
    signal imm_sign_ext : word;
        -- Sign-extended instruction immediates (jimm = jump immediate)

    signal enable_reg_wr : std_logic;
        -- Used for the WB stage (set to 1 if wb_reg_addr != $0)

    signal instr_rs, instr_rt, instr_rd : reg_address;
    signal instr_imm       : std_logic_vector(15 downto  0);
    signal instr_jimm      : std_logic_vector(25 downto  0); -- Jump immediate
    signal instr_sh_amnt   : std_logic_vector( 4 downto  0);
    signal instr_func      : std_logic_vector( 5 downto  0);
    signal instr_opcode    : std_logic_vector(31 downto 26);

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

    -- Extract portions of the instruction
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
    
    instruction_decode: process (id_in.instruction) is
        variable bcrit : std_logic; -- Branching criteria
    begin
        case instr_opcode is
            when O_SPECIAL => -- ALU ops specified by func
                case instr_func is
                    when others =>
                end case;
            when O_REGIMM  => -- Single-register branch criteria
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
            when O_J    =>
                cw <= (   B_J,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when O_JAL  =>
                cw <= (   B_J,    M_PC,  M_R_0,  F_ADDU, MEM_NA, R_31);
            when O_BEQ  =>
                cw <= (  B_EQ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when O_BNE   =>
                cw <= (  B_NE,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when O_BLEZ  =>
                cw <= ( B_LEZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when O_BGTZ  =>
                cw <= ( B_GTZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);

            when O_ADDI  =>
                cw <= (B_NONE,  M_REGA, M_IMMS,   F_ADD, MEM_NA, instr_rt);
            when O_ADDIU =>
                cw <= (B_NONE,  M_REGA, M_IMMS,  F_ADDU, MEM_NA, instr_rt);
            when O_SLTI  =>
                cw <= (B_NONE,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when O_SLTIU =>
                cw <= (B_NONE,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when O_ANDI  =>
                cw <= (B_NONE,  M_REGA, M_IMMU,   F_AND, MEM_NA, instr_rt);
            when O_ORI   =>
                cw <= (B_NONE,  M_REGA, M_IMMU,    F_OR, MEM_NA, instr_rt);
            when O_XORI  =>
                cw <= (B_NONE,  M_REGA, M_IMMU,   F_XOR, MEM_NA, instr_rt);
            when O_LUI   =>
                cw <= (B_NONE, M_IMMUP,  M_R_0,   F_ADD, MEM_NA, instr_rt);

            when O_LB    =>
                cw <= (B_NONE, M_IMMUP,  M_R_0,   F_ADD, MEM_NA, instr_rt);
            when others =>
        end case;
    end process;

--    constant O_LB    : opcode := "100000";
--    constant O_LH    : opcode := "100001";
--    constant O_LWL   : opcode := "100010";
--    constant O_LW    : opcode := "100011";
--    constant O_LBU   : opcode := "100100";
--    constant O_LHU   : opcode := "100101";
--    constant O_LWR   : opcode := "100110";

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
                when B_NONE => id_out.enable_delta_pc <= false;
                when B_J    => id_out.enable_delta_pc <= true;
                when B_EQ   => id_out.enable_delta_pc <= reg_a = reg_b;
                when B_NE   => id_out.enable_delta_pc <= reg_a /= reg_b;
                when B_LTZ  => id_out.enable_delta_pc <= reg_a(31) = '1';
                when B_GTZ  => id_out.enable_delta_pc <= reg_a(31) = '0';
                when B_LEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '1') or (reg_a = x"00000000");
                when B_GEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '0') or (reg_a = x"00000000");
                when others =>
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

            id_out.mux_mem <= cw.mux_mem;
            id_out.reg_to_mem <= reg_b; -- XXX make sure this is valid
        end if;
    end process;
end architecture;
