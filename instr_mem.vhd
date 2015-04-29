library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

use std.textio.all;
use ieee.std_logic_textio.all;

-- An asynchronous ROM populated by the contents of instruction memory
entity MIPS_IMEM is
    generic ( imem_filename : string := "test/imem_test_5instr.txt" );
    port (
        data_addr : in  address;
        data_out  : out word
    );
end entity;

architecture impl1 of MIPS_IMEM is
    signal pc : address;
    signal instr_name : string (1 to 25);

    constant MEM_DLY : time := 0.5 ns;
begin
    INSTR_MEM_PROC: process ( pc ) is
        type INSTR_STR_ARY is array ( 0 to 1023 ) of STRING ( 1 to 25 );
        type MEMORY is array ( 0 to 1023 ) of BIT_VECTOR ( 31 downto 0 );
        file IN_FILE     : TEXT open READ_MODE is imem_filename;
        variable MEM     : MEMORY := ( others => X"0000_0000");
        variable IADDR   : INTEGER;               -- integer for address
        variable DTEMP   : BIT_VECTOR ( 31 downto 0 );
        variable INIT    : INTEGER := 0;          -- when to initialize...
        variable BUF     : LINE;
        variable ADR_STR : STD_LOGIC_VECTOR ( 31 downto 0 );
        variable TADR    : INTEGER;
        variable TDATA   : STD_LOGIC_VECTOR ( 31 downto 0 );
        variable BDATA   : BIT_VECTOR ( 31 downto 0 );
        variable STR_ING : STRING ( 1 to 25 );
        variable MEMSTRR : INSTR_STR_ARY :=
            (others => "                         ");
    begin
        if INIT = 0 then
            while not (ENDFILE ( IN_FILE )) loop
                READLINE ( IN_FILE, BUF );
                HREAD    ( BUF, ADR_STR ); -- get the address on the line
                TADR := CONV_INTEGER ( unsigned(ADR_STR (14 downto 2)));
                HREAD    ( BUF, TDATA   ); -- get the data on the line
                BDATA := To_bitvector (TDATA);
                MEM ( TADR ) := BDATA;     -- put into memory
                for J in 1 to 25 loop
                    STR_ING(J) := ' ';
                end loop;
                READ     ( BUF, STR_ING ); -- get instruction string
                MEMSTRR ( TADR ) := STR_ING;
                report "iteration of loop";
            end loop;
            INIT := 1;                   -- when all data in, set INIT to 1;
        end if;                        -- end of INIT check

        IADDR := CONV_INTEGER ( unsigned(pc ( 14 downto 2 )));
        data_out <= To_StdLogicVector ( MEM ( IADDR )) after MEM_DLY;
        instr_name <= MEMSTRR ( IADDR );
        -- report "should hit  INSTRUC";
    end process;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use work.components.all;

entity TB_MIPS_IMEM is
end entity;

architecture impl1 of TB_MIPS_IMEM is
    signal s_pc : address;
    signal s_instr : word;
begin
    uut : MIPS_IMEM
        generic map ("instr_mem.txt")
        port map (s_pc, s_instr);

    signalTests1: process
        variable buf: line;
    begin
        s_pc <= x"00000000";
        wait for 100 ns;
        assert (s_instr = x"00000000");

        s_pc <= x"00000004";
        wait for 100 ns;
        assert (s_instr = x"12345678");

        write(buf, string'("Assertions tb_alu complete"));
        writeline(output, buf);
        wait;
    end process;
end architecture;
