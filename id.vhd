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
    signal addr_a, addr_b : reg_address;
    signal reg_a, reg_b, wr_data : word;

    signal jimm_sign_ext : word;
    signal imm_sign_ext : word;
        -- Instruction immediate, signed-extended (jimm = jump immediate)
    signal imm_upper    : word;
        -- Holds data for load upper immediate

    signal reg_a_b_equal : std_logic;
        -- Used for beq/bne, tests equality of registers
    signal enable_reg_wr : std_logic;
        -- Used for the WB stage (set to 1 if wb_reg_addr != $0)

    type mux_val_a_t is (
        M_REGA,  -- Register A value
        M_IMMUP, -- Upper immediate, useful for lui
        M_IMMS,  -- Sign-ext immediate, useful for r-ops and address calcs
        M_PC     -- For passing PC to $31 on bal/jal
    );
    type mux_val_b_t is (
        M_REGB, -- Register B value
        M_R_0   -- Zeros out the value (effectively passing $0)
    );

    type control_word is record
        wb_reg_addr : reg_address;
            -- The register address to pass to the WB stage (0 to disable WB)

        alu_op : op_func;
            -- The ALU operation that should be performed in EX

        enable_jimm : std_logic;
            -- Determines whether to use regular immediate or jump immediates
        enable_delta_pc  : std_logic;
            -- Set to 1 for branch instructions
        mux_val_a : mux_val_a_t;
        mux_val_b : mux_val_b_t;
            -- Determine outputs
        enable_memw : std_logic;
            -- Assert on stores
        enable_memr : std_logic;
            -- Assert on loads
    end record;

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

    reg_a_b_equal <= '1' when (reg_a = reg_b) else '0';

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
    begin
        case instr_opcode is
            when O_J   =>
                cw <= (R_0,F_PASSA,'1','1','1','1','0','0');
            when O_JAL =>
                cw <= (R_31,F_PASSA,'1','1','1','1','0','0');
            when O_BEQ =>
                cw <= (R_0,F_PASSA,'0',reg_a_b_equal,'1','1','1','1');
            when others =>
        end case;
    end process;

--    constant O_J     : opcode := "000010";
--    constant O_JAL   : opcode := "000011";
--    constant O_BEQ   : opcode := "000100";
--    constant O_BNE   : opcode := "000101";
--    constant O_BLEZ  : opcode := "000110";
--    constant O_BGTZ  : opcode := "000111";
--    constant O_ADDI  : opcode := "001000";
--    constant O_ADDIU : opcode := "001001";
--    constant O_SLTI  : opcode := "001010";
--    constant O_SLTIU : opcode := "001011";
--    constant O_ANDI  : opcode := "001100";
--    constant O_ORI   : opcode := "001101";
--    constant O_XORI  : opcode := "001110";
--    constant O_LUI   : opcode := "001111";
--
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
            if cw.enable_jimm = '1' then
                id_out.delta_pc <= jimm_sign_ext(29 downto 0) & "00";
            else
                id_out.delta_pc <=  imm_sign_ext(29 downto 0) & "00";
            end if;

            id_out.enable_delta_pc <= cw.enable_delta_pc;

            case cw.mux_val_a is
                when M_REGA  => id_out.val_a <= reg_a;
                when M_IMMUP => id_out.val_a <= instr_imm & x"0000";
                when M_IMMS  => id_out.val_a <= imm_sign_ext;
                when M_PC    => id_out.val_a <= id_in.pc;
            end case;

            case cw.mux_val_b is
                when M_REGB => id_out.val_b <= reg_b;
                when M_R_0  => id_out.val_b <= (others => '0');
            end case;
        end if;
    end process;
end architecture;
