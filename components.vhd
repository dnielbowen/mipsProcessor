library ieee;
use ieee.std_logic_1164.all;

package COMPONENTS is
    constant g_delay: TIME := 1 ns;

    subtype word is std_logic_vector(31 downto 0);
    subtype address is word;

    -- constant RS_H   : integer := 25; -- High register source bit
    -- constant RS_L   : integer := 21; -- High register source bit

    subtype reg_address is std_logic_vector(4 downto 0);
    subtype op_func is std_logic_vector(5 downto 0);

    -- TODO Add the rest of the ALU functions
    constant F_ADD   : op_func := "100000";
    constant F_ADDU  : op_func := "100001";
    constant F_AND   : op_func := "100100";
    constant F_DIV   : op_func := "011010";
    constant F_DIVU  : op_func := "011011";
    constant F_NOR   : op_func := "100111";
    constant F_OR    : op_func := "100101";
    constant F_XOR   : op_func := "100110";
    constant F_MULT  : op_func := "011000";
    constant F_MULTU : op_func := "011001";
    constant F_SUB   : op_func := "100010";
    constant F_SUBU  : op_func := "100011";

    -- IF Instruction Fetch stage
    type if_out is record
        pc_curr     : address; -- The PC associated with `instruction`
        pc_incr     : address;
        instruction : word;
    end record;

    type if_in is record
        branch_pc     : address;
        use_branch_pc : std_logic;
    end record;

    component MIPS_IMEM is
        generic (imem_filename : string);
        port (
            data_addr : in  address;
            data_out  : out word
        );
    end component;

end package;
