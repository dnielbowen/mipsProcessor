library ieee;
use ieee.std_logic_1164.all;

entity SIGNEXTEND_16_32 is
    port (
        X: in  std_logic_vector(15 downto 0);
        F: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of SIGNEXTEND_16_32 is
    signal extension : std_logic_vector(15 downto 0);
begin
    extension <= x"0000" when X(15) = '0' else x"FFFF";
    F <= extension & X;
end architecture;
