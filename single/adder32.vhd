library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity ADDER_32 is
    port (
        A,B: in  std_logic_vector(31 downto 0);
        F:   out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of ADDER_32 is
begin
    F <= std_logic_vector(unsigned(A) + unsigned(B));
end;
