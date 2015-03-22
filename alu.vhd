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
                when x"7" => F <= (0 => aLessThanB, others => '0');
                when others => F <= (others => '0');
            end case;
        end if;
    end process;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_ALU  is end;

architecture impl1 of TB_ALU is
    signal sA, sB, sF: std_logic_vector(31 downto 0);
    signal sControl: std_logic_vector(3 downto 0);
    signal sClk: std_logic := '0';
begin
    uut1: ALU port map (sA, sB, sCLK, sControl, sF);

    clk1: process is
    begin
        sClk <= not sClk;
        wait for T/2;
    end process;

    signalTests1: process
        variable buf: line;
    begin
        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
        wait for T/4;

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0010"; -- Addition
        wait for T/2;
        assert (sF /= x"00000005");
        wait for T/2;
        assert (sF = x"00000005");

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0110"; -- Subtraction
        wait for T/2;
        assert (sF /= x"FFFFFFFF");
        wait for T/2;
        assert (sF = x"FFFFFFFF");

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0111"; -- SLT
        wait for T/2;
        assert (sF /= x"00000001");
        wait for T/2;
        assert (sF = x"00000001");

        sA <= x"00000003";
        sB <= x"00000003";
        sControl <= "0111"; -- SLT
        wait for T/2;
        assert (sF /= x"00000000");
        wait for T/2;
        assert (sF = x"00000000");

        write(buf, string'("Assertions tb_alu complete"));
        writeline(output, buf);
        wait;
    end process;
end architecture;
