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
    signal reg_file : reg_file_t := (others => (others => '0'));
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

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use std.textio.all;
use ieee.std_logic_textio.all;
use work.components.all;

entity TB_MIPS_REG is
end entity;

architecture impl1 of TB_MIPS_REG is
    signal s_clk, s_wr_enable : std_logic := '0';

    signal s_addr_a, s_addr_b, s_wr_addr : reg_address;
    signal s_data_a, s_data_b, s_wr_data : word;
begin
    uut : MIPS_REG
        port map (s_clk, s_addr_a, s_addr_b, s_data_a, s_data_b,
                  s_wr_enable, s_wr_addr, s_wr_data);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for 5 ns;
    end process;

    signalTests1: process
    begin
        s_wr_enable <= '1';
        s_wr_data <= (others => '0');
        s_wr_addr <= (others => '0');
        s_addr_a <= (others => '0');
        s_addr_b <= (others => '0');
        wait for 100 ns;

        wait;
    end process;
end architecture;
