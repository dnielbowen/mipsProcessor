library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.components.all;

-- An asynchronous ALU
entity MIPS_ALU is
    port (
        alu_op  :   in  op_func;
        sh_amnt :   in  std_logic_vector (4 downto 0);
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
            -- Arithmetic
            when F_ADD   =>
                f <= std_logic_vector(signed(a)   + signed(b));
            when F_ADDU  =>
                f <= std_logic_vector(unsigned(a) + unsigned(b));
            when F_SUB   =>
                f <= std_logic_vector(signed(a)   - signed(b));
            when F_SUBU  =>
                f <= std_logic_vector(unsigned(a) - unsigned(b));
            when F_DIV   =>
                f <= std_logic_vector(signed(a)   / signed(b));
            when F_DIVU  =>
                f <= std_logic_vector(unsigned(a) / unsigned(b));

            -- Logical
            when F_AND   =>
                f <= a and b;
            when F_OR    =>
                f <= a or b;
            when F_XOR   =>
                f <= a nor b;
            when F_NOR   =>
                f <= a xor b;

            -- Complicated branch checks
            when F_SLT   =>
                if (signed(a) < signed(b)) then
                    f <= x"00000001";
                else
                    f <= (others => '0');
                end if;
            when F_SLTU  =>
                if (unsigned(a) < unsigned(b)) then
                    f <= x"00000001";
                else
                    f <= (others => '0');
                end if;

            -- Shifts
            when F_SLL =>
                f <= std_logic_vector(
                     unsigned(a) sll to_integer(unsigned(sh_amnt)));
            when F_SRL =>
                f <= std_logic_vector(
                     unsigned(a) srl to_integer(unsigned(sh_amnt)));
            when F_SLLV =>
                f <= std_logic_vector(
                     unsigned(a) sll to_integer(unsigned(b)));
            when F_SRLV =>
                f <= std_logic_vector(
                     unsigned(a) srl to_integer(unsigned(b)));

            when others => f <= (others => 'Z');
        end case;
    end process;
end architecture;
