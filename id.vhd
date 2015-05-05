library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; -- vs numeric_std because this has uint+int
use work.components.all;

entity MIPS_ID is
    port (
        clk    : in  std_logic;
        id_in  : in  id_in;
        id_out : out id_out
    );
end entity;

architecture impl1 of MIPS_ID is
    signal addr_a, addr_b, wr_addr : reg_address;
    signal reg_a, reg_b, wr_data : word;
    signal wr_enable : std_logic;

    signal imm_sign_ext : word;

    signal instr_rs, instr_rt, instr_rd : reg_address;
    signal instr_imm       : std_logic_vector(15 downto  0);
    signal instr_jimm      : std_logic_vector(25 downto  0); -- Jump immediate
    signal instr_sh_amnt   : std_logic_vector( 4 downto  0);
    signal instr_func      : std_logic_vector( 5 downto  0);
    signal instr_opcode    : std_logic_vector(31 downto 26);
begin
    reg_file: MIPS_REG port map(
        clk => clk,
        addr_a => instr_rs,
        addr_b => instr_rt,
        data_a => reg_a,
        data_b => reg_b,
        wr_enable => wr_enable,
        wr_addr => wr_addr,
        wr_data => wr_data);

    -- Extract portions of the instruction
    instr_imm     <= id_in.instruction(15 downto  0);
    instr_jimm    <= id_in.instruction(25 downto  0);
    instr_sh_amnt <= id_in.instruction(10 downto  6);
    instr_func    <= id_in.instruction( 5 downto  0);
    instr_rs      <= id_in.instruction(25 downto 21);
    instr_rt      <= id_in.instruction(20 downto 16);
    instr_rd      <= id_in.instruction(15 downto 11);

    imm_sign_ext <= x"FFFF" & instr_imm
                    when instr_imm(15) = '1' else
                    x"0000" & instr_imm;

    id_out.branch_pc <= unsigned(id_in.pc_incr) +
                        signed(imm_sign_ext(29 downto 0) & "00");
end architecture;
