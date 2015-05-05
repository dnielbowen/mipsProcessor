library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

use std.textio.all;
use ieee.std_logic_textio.all;

-- Async read, sync write
entity MIPS_DMEM is
    generic (
        dmem_init_filename : string := "data/data_mem_init.txt";
        dmem_filename      : string := "data/mem_trans.txt"
    );
    port (
        clk       : in  std_logic;
        addr      : in  address;
        wr_enable : in  std_logic;
        wr_data   : in  word;
        data_out  : out word
    );
end entity;

-- XXX For now, this memory always returns words (but it is stored as bytes)
architecture impl1 of MIPS_DMEM is
    type mem_t is array (1023 downto 0) of byte;
    signal mem : mem_t := (others => (others => '0'));
begin
    -- Reads words from a memory init file
    initalize_memory: process (clk, wr_enable, addr, wr_data) is
        file fpr: text open READ_MODE  is dmem_init_filename;
        variable buf_read, buf_write: line;
        variable memory_is_init : boolean := false;
        variable i : integer;

        variable v_addr : address;
        variable v_data : word;

        file fpw: text open WRITE_MODE is dmem_filename;   -- results
    begin
        if not memory_is_init then
            while not endfile(fpr) loop
                -- Read the instruction on the current line
                readline(fpr, buf_read);
                hread(buf_read, v_addr);
                hread(buf_read, v_data);

                i := conv_integer(unsigned(v_addr(9 downto 0)));

                -- And add the data word to the memory
                mem(i+0) <= v_data( 7 downto  0);
                mem(i+1) <= v_data(15 downto  8);
                mem(i+2) <= v_data(23 downto 16);
                mem(i+3) <= v_data(31 downto 24);

                -- dmem Debug output
                write(buf_write, string'("0x"));
                hwrite(buf_write, v_addr);
                write(buf_write, string'(": file: 0x"));
                hwrite(buf_write, v_data);
                write(buf_write, string'(" iAddr="));
                write(buf_write, i);
                writeline(OUTPUT, buf_write);

            end loop;
            memory_is_init := true;
        elsif rising_edge(clk) then
            i := conv_integer(unsigned(addr(9 downto 0)));
            if wr_enable = '1' then
                mem(i+0) <= wr_data( 7 downto  0);
                mem(i+1) <= wr_data(15 downto  8);
                mem(i+2) <= wr_data(23 downto 16);
                mem(i+3) <= wr_data(31 downto 24);

                write(buf_write, string'("W  "));
                hwrite(buf_write, addr);
                write(buf_write, string'("   "));
                hwrite(buf_write, wr_data);
                write(buf_write, string'("   i="));
                write(buf_write, i);
                write(buf_write, string'("   "));
                write(buf_write, now);
                writeline(fpw, buf_write);
            else
                write(buf_write, string'("R  "));
                hwrite(buf_write, addr);
                write(buf_write, string'("   "));
                hwrite(buf_write, mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0));
                write(buf_write, string'("   "));
                write(buf_write, now);
                writeline(fpw, buf_write);
            end if;
        end if;

        if wr_enable = '1' then
            data_out <= (others => 'Z');
        else
            i := conv_integer(unsigned(addr(9 downto 0)));
            data_out <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
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

entity TB_MIPS_DMEM is
end entity;

architecture impl1 of TB_MIPS_DMEM is
    signal s_addr : address := (others => '0');
    signal s_data_out, s_data_in : word;

    signal s_clk, s_wr_enable : std_logic := '0';
begin
    uut : MIPS_DMEM
        generic map ("data/data_mem_init.txt", "data/mem_trans_test.txt")
        port map (s_clk, s_addr, s_wr_enable, s_data_in, s_data_out);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for 5 ns;
    end process;

    signalTests1: process
    begin
        s_data_in <= x"DEADBEEF";
        s_addr <= x"00000064";
        s_wr_enable <= '0';
        wait for 35 ns;
        assert s_data_out = x"00001064";
        print_word(s_addr, s_data_out);

        s_wr_enable <= '1';
        wait for 10 ns;
        assert s_data_out /= x"00001064";
        s_wr_enable <= '0'; -- Read
        wait for 1 ns; -- Apparently reads are async, but not instantaneous
        assert s_data_out = x"DEADBEEF";
        print_word(s_addr, s_data_out);

        s_addr <= x"00000068";
        wait for 1 ns;
        assert s_data_out <= x"00001068";
        print_word(s_addr, s_data_out);
 
        wait;
    end process;
end architecture;
