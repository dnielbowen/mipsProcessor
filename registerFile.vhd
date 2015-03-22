library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity REGISTER_ARRAY_32_32 is
    port (
        -- Register addresses
        ADDR1,ADDR2,ADDRW: in  std_logic_vector(4 downto 0);
        -- Registers referenced by ADDR1,ADDR2
        REG1,REG2:         out std_logic_vector(31 downto 0);
        -- Register write input
        DATA:              in  std_logic_vector(31 downto 0);
        -- Register write enable
        ENW:               in  std_logic; -- Register Write enable
        CLK:               in  std_logic
    );
end entity;

architecture impl1 of REGISTER_ARRAY_32_32 is
    type REG_ARRAY is array(natural range <>) of std_logic_vector(31 downto 0);
    signal regs: REG_ARRAY(31 downto 0) := (others => (others => '0'));
begin
    p1: process (CLK) is
        variable i1,i2,iW: natural;
    begin
        i1 := conv_integer(unsigned(ADDR1));
        i2 := conv_integer(unsigned(ADDR2));
        iW := conv_integer(unsigned(ADDRW));

        if rising_edge(CLK) then
            if ENW = '1' then
                regs(iW) <= DATA;

                if i1 = iW then
                    REG1 <= DATA;
                else
                    REG1 <= regs(i1);
                end if;

                if i2 = iW then
                    REG2 <= DATA;
                else
                    REG2 <= regs(i2);
                end if;
            else
                REG1 <= regs(i1);
                REG2 <= regs(i2);
            end if;
        end if;
    end process;
end;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_REGISTERS is end;

architecture impl1 of TB_REGISTERS is
    signal sWrEnable,sClk: std_logic := '0';
    signal sAddr1,sAddr2,sAddrW: std_logic_vector(4 downto 0);
    signal sReg1,sReg2,sRegData: std_logic_vector(31 downto 0);
begin
    uut1: REGISTER_ARRAY_32_32 port map (
        sAddr1, sAddr2, sAddrW, sReg1, sReg2, sRegData, sWrEnable, sClk
    );

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
        sWrEnable <= '1';
        sAddr1 <= '1' & x"C"; -- $gp, AKA $28
        sAddr2 <= '1' & x"8"; -- $t0

        -- Write 0xBABEBABE to $t0
        sAddrW <= '1' & x"8"; -- $t0
        sRegData <= x"babebabe";
        wait for T;

        -- Write 0xDEADBEEF to $gp, then read it.
        sAddrW <= '1' & x"C"; -- $gp
        sRegData <= x"deadbeef";

        wait for T/2;
        assert (sReg1 /= x"deadbeef"); -- Haven't written it yet
        wait for T/2;                  -- Wrote in the middle of this wait
        sWrEnable <= '0';
        -- Make sure we can read it, even though we're still "writing"
        assert (sReg1 = x"deadbeef");
        assert (sReg2 = x"babebabe"); -- Now that we've changed, can we read?

        wait for T;  -- Let another clock cycle pass
        assert (sReg1 = x"deadbeef");

        wait;
    end process;
end architecture;
