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
        f       :   out word
    );
end entity;

architecture impl1 of MIPS_ALU is
begin
    alu_function_chooser: process (a, b, alu_op) is
    begin
        -- TODO Finish implementing these
        case alu_op is
            when F_ADD   => f <= std_logic_vector(signed(a)   + signed(b));
            when F_ADDU  => f <= std_logic_vector(unsigned(a) + unsigned(b));
            when F_SUB   => f <= std_logic_vector(signed(a)   - signed(b));
            when F_SUBU  => f <= std_logic_vector(unsigned(a) - unsigned(b));
            when F_DIV   => f <= std_logic_vector(signed(a)   / signed(b));
            when F_DIVU  => f <= std_logic_vector(unsigned(a) / unsigned(b));
            when F_AND   => f <= a and b;
            when others => f <= (others => 'Z');
        end case;
    end process;
end architecture;
