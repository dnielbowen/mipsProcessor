library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity ALU is
    port (
        A,B:     in  std_logic_vector(31 downto 0);
        CLK:     in  std_logic;
        CONTROL: in  std_logic_vector(3 downto 0);
        F:       out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of ALU is
    signal aLessThanB : std_logic;
begin
    -- This signal exists because you apparently can't write this inline...?
    -- The Boolean-std_logic conversion function is in Mentor Graphics' IEEE
    aLessThanB <= to_stdlogic(signed(A) < signed(B));

    p1: process (CLK) is
    begin
        if rising_edge(CLK) then
            case CONTROL is
                when x"0" => F <= A AND B;
                when x"1" => F <= A OR B;
                when x"C" => F <= A NOR B;
                when x"2" => F <= std_logic_vector(unsigned(A) + unsigned(B));
                when x"6" => F <= std_logic_vector(unsigned(A) - unsigned(B));
                when x"7" => F <= (1 => aLessThanB, others => '0');
                when others => F <= (others => '0');
            end case;
        end if;
    end process;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity TB_ALU is end;

architecture impl1 of TB_ALU is
begin
end;
