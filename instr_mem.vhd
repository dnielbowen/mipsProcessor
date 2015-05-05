library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

use std.textio.all;
use ieee.std_logic_textio.all;

-- An asynchronous 1K-word ROM populated by the contents of instruction memory
entity MIPS_IMEM is
    generic (imem_filename : string := "data/imem_test_5instr.txt");
    port (
        data_addr : in  address;
        data_out  : out word
    );
end entity;

architecture impl1 of MIPS_IMEM is
    subtype instr_str is string (1 to 25);
    type mem_str_t is array (1023 downto 0) of instr_str;
    -- XXX incorrectly is word-addressed instead of byte-address
    type mem_t is array (1023 downto 0) of word;

    signal mem : mem_t := (others => (others => '0'));
    signal memAsm : mem_str_t := (others => (others => '0'));
begin
    initMemory: process is
        file fp: text open READ_MODE is imem_filename;
        variable bufRead, bufWrite: line;
        variable memoryIsInit : boolean := false;

        variable addr   : address;
        variable opcode : word;
        variable asm    : instr_str;
    begin
        if not memoryIsInit then
            while not endfile(fp) loop
                -- Read the instruction on the current line
                readline(fp, bufRead);
                hread(bufRead, addr);
                hread(bufRead, opcode);
                read(bufRead, asm); -- Requires 25-char desc lines

                -- And add the instruction to the memory
                mem(conv_integer(unsigned(addr(9 downto 0)))) <= opcode;
                memAsm(conv_integer(unsigned(addr(9 downto 0)))) <= asm;

                -- imem Debug output
                -- write(bufWrite, string'("0x"));
                -- hwrite(bufWrite, addr);
                -- write(bufWrite, string'(": 0x"));
                -- hwrite(bufWrite, opcode);
                -- write(bufWrite, string'(", "));
                -- write(bufWrite, asm);
                -- writeline(OUTPUT, bufWrite);
            end loop;
            memoryIsInit := true;
        end if;
        wait;
    end process;

    data_out <= mem(conv_integer(unsigned(data_addr(10 downto 0))))
                after MEM_DLY;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use std.textio.all;
use ieee.std_logic_textio.all;
use work.components.all;

entity TB_MIPS_IMEM is
end entity;

architecture impl1 of TB_MIPS_IMEM is
    signal s_pc : address := (others => '0');
    signal s_instr : word;
begin
    uut : MIPS_IMEM
        generic map ("data/instr_5instr.txt")
        port map (s_pc, s_instr);

    signalTests1: process
    begin
        s_pc <= x"00000004";
        wait for 100 ns;
        assert (s_instr = x"12345678");
        print_word(s_pc, s_instr);

        s_pc <= x"00000000";
        wait for 100 ns;
        assert (s_instr = x"00000000");
        print_word(s_pc, s_instr);

        s_pc <= x"0000000C";
        wait for 100 ns;
        assert (s_instr = x"11110000");
        print_word(s_pc, s_instr);

        wait;
    end process;
end architecture;
