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
    signal regs: REG_ARRAY(31 downto 0);
begin
    p1: process
    begin
        if rising_edge(CLK) then
            if ENW = '1' then
                regs(conv_integer(ADDRW)) <= DATA;
            end if;

            REG1 <= regs(conv_integer(ADDR1));
            REG2 <= regs(conv_integer(ADDR2));
        end if;
    end process;
end;
