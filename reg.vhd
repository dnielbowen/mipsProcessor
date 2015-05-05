library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

entity MIPS_REG is
    port (
        clk       : in  std_logic;
        addr_a    : in  reg_address;
        addr_b    : in  reg_address;
        data_a    : out word;
        data_b    : out word;
        wr_enable : in  std_logic;
        wr_addr   : in  reg_address;
        wr_data   : in  word
    );
end entity;

architecture impl1 of MIPS_REG is
    type reg_file_t is array (0 to 31) of word;
    signal reg_file : reg_file_t;
begin
    async_data_read_a: data_a <= reg_file(conv_integer(unsigned(addr_a)));
    async_data_read_b: data_b <= reg_file(conv_integer(unsigned(addr_b)));

    data_write: process (clk) is
    begin
        if rising_edge(clk) and wr_enable = '1' then
            reg_file(conv_integer(unsigned(wr_addr))) <= wr_data;
        end if;
    end process;
end architecture;
