library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.components.all;

entity MIPS_ALU is
    port (
        clk     :   in  std_logic;
        alu_op  :   in  op_func;
        a       :   in  word;
        b       :   in  word;
        f       :   out word;
    );
end entity;

architecture impl1 of MIPS_ALU is
begin
    function_chooser: process (alu_op) is
    begin
        case alu_op
            when OP_ADD => f <= singed(a + b;
            when OP_SUB => f <= a - b;
        end case;
    end process;
end architecture;
