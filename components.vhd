library ieee;
use ieee.std_logic_1164.all;

package COMPONENTS is
    constant g_delay: TIME := 1 ns;

    subtype word is std_logic_vector(31 downto 0);
    subtype address is word;

    type ALU_OP is (
        -- Arithmetic
        OP_ADD,
        OP_ADDU,
        OP_SUB,
        OP_SUBU,
        OP_MULT,
        OP_MULTU,
        OP_DIV,
        OP_DIVU,
        -- Logical
        OP_AND,
        OP_OR,
        OP_NOT,
        OP_NOR
    );

    subtype op_func is std_logic_vector(5 downto 0);

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

end package;
