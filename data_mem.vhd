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

-- XXX For now, this memory always returns words (though it's stored as bytes)
architecture impl1 of MIPS_DMEM is
    type mem_t is array (1023 downto 0) of byte;
    signal mem : mem_t := (others => (others => '0'));
begin
    -- Reads words from a memory init file
    initalize_memory: process (clk) is
        file fpr: text open READ_MODE  is dmem_init_filename;
        variable buf_read, buf_write: line;
        variable memory_is_init : boolean := false;
        variable i : integer;

        variable addr : address;
        variable data : word;

        file fpw: text open WRITE_MODE is dmem_filename;   -- results
    begin
        if not memory_is_init then
            while not endfile(fpr) loop
                -- Read the instruction on the current line
                readline(fpr, buf_read);
                hread(buf_read, addr);
                hread(buf_read, data);

                i := conv_integer(unsigned(addr(9 downto 0)));

                -- And add the data word to the memory
                mem(i+0) <= data( 7 downto  0);
                mem(i+1) <= data(15 downto  8);
                mem(i+2) <= data(23 downto 16);
                mem(i+3) <= data(31 downto 24);

                -- dmem Debug output
                write(buf_write, string'("0x"));
                hwrite(buf_write, addr);
                write(buf_write, string'(": file: 0x"));
                hwrite(buf_write, data);
                write(buf_write, string'(" iAddr="));
                write(buf_write, i);
                writeline(OUTPUT, buf_write);

            end loop;
            memory_is_init := true;
        end if;

        if rising_edge(clk) then
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
    end process;

    async_data_output: process (addr, wr_enable) is
        variable i : integer;
    begin
        if wr_enable = '1' then
            data_out <= (others => 'Z');
        else
            i := conv_integer(unsigned(addr(9 downto 0)));
            data_out <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
        end if;
    end process;
end architecture;

-- {{{1 implPollard
--architecture implPollard of MIPS_DMEM is
--    signal M_DATA_IN : STD_LOGIC_VECTOR ( 31 downto 0 ) := ( others => 'Z');
--    signal M_DATA_OUT : STD_LOGIC_VECTOR ( 31 downto 0 ):= ( others => 'Z');
--    signal M_ADDR    : STD_LOGIC_VECTOR ( 11 downto 0 ) := ( others => '0');
--
--    signal MEMREAD   : STD_LOGIC := '0';
--    signal M_DATA_WHEN   : STD_LOGIC := '0';
--    signal MEMWRITE  : STD_LOGIC := '0';
--begin
--    -- Map my signals to example Pollard memory signals
--    MEMREAD <= not wr_enable;
--    MEMWRITE <= wr_enable;
--    data_out <= M_DATA_OUT;
--    M_DATA_IN <= wr_data;
--
---- The following is the magic process
---- User must supply:
----  M_ADDR - memory address (data memory) as a 12 bit STD_LOGIC_VECTOR
----           Remember the M_ADDR is a WORD address
----  M_DATA_IN - value going to memory from hardware (data path)
----           Remember that this is 32 bit STD_LOGIC_VECTOR, user supplied
----  READ_DATA2 - this is to be replaced by user's sourceof info for memory
--DATA_MEMORY_PROCESS:                          -- name of process ...
--  process ( M_ADDR, CLK, MEMREAD ) is         -- Sens: M_ADDR, CLK, MEMREAD
--  file IN_FILE: TEXT open READ_MODE is dmem_init_filename; -- Inital data
--  file OUT_FILE: TEXT open WRITE_MODE is dmem_filename;   -- results
--  variable BUF : LINE;                        -- declare BUF as LINE
--  variable TVAL : STD_LOGIC_VECTOR ( 31 downto 0 ); -- var for temp value
--  variable TADRHEX : STD_LOGIC_VECTOR ( 31 downto 0 ); -- var for address
--  variable TADR : INTEGER;                    -- address as integer
--  type MEM_TYPE is array ( 0 to 1023 ) of STD_LOGIC_VECTOR ( 31 downto 0 );
--  variable THE_MEMORY : MEM_TYPE := ( others => X"00000000" ); -- the memory
--  variable FIRST : BOOLEAN := TRUE;           -- flag for first time thru
--  constant STR : STRING ( 1 to 3 ) := "   ";  -- 3 spaces - for printing
--  constant WR_STR : STRING ( 1 to 3 ) := "W  "; -- for write
--  constant RD_STR : STRING ( 1 to 3 ) := "R  "; -- for read
--  variable TSTR2 : STRING ( 1 to 29 );          -- to create a string
--  type MEMSTR_TYPE is array ( 0 to 1023 ) of STRING ( 1 to 29 ); -- 
--  variable INSTRS : MEMSTR_TYPE;
--  begin                                       -- start here
--    if FIRST then                             -- first time thru,
--      while FIRST loop                        -- loop on data available - until
--        if not ( ENDFILE ( IN_FILE )) then    -- end of file shows up
--          READLINE(IN_FILE, BUF);             -- read a line from file,
--          HREAD(BUF, TADRHEX);                -- get address from BUF
--          TADR := CONV_INTEGER ( unsigned(TADRHEX(14 downto 0)) );
--          HREAD(BUF, TVAL);                   -- next, get value from BUF
--          THE_MEMORY(TADR/4) := TVAL;         -- put TVAL into the memory
--        else                                  -- the 'else' is for end of file
--          FIRST := FALSE;                     -- EOF shows up - set FIRST false
--        end if;
--      end loop;                               -- where loop ends...
--    end if;                                   -- where if FIRST ends ...
--    if MEMREAD = '1' then                     -- now, memory function 'read'
--      M_DATA_OUT <= THE_MEMORY ( CONV_INTEGER ( unsigned(M_ADDR(11 downto 0)) ) / 4 );
--      M_DATA_WHEN <= not M_DATA_WHEN;         -- and invert M_DATA_WHEN
--    else                                      -- if not MEMREAD,
--      M_DATA_OUT <= ( others => 'Z' );        -- set memory out to 'Z's
--    end if;
--    if RISING_EDGE ( CLK ) then               -- on clock edge...
--      if MEMREAD = '1' then                   -- if MEMREAD asserted,
--        TADR := CONV_INTEGER ( unsigned(M_ADDR(11 downto 0)) ) / 4;
--        -- set TADR to address as int
--        TVAL := THE_MEMORY ( TADR );          -- and get contents to TVAL
--        WRITE (BUF, RD_STR);                  -- then build BUF; put read indi
--        HWRITE (BUF, M_ADDR);                 -- and the address
--        WRITE (BUF, STR);                     -- some spaces
--        HWRITE (BUF, TVAL);                   -- and the value
--        WRITE (BUF, STR);                     -- more spaces
--        WRITE (BUF, NOW);                     -- current simulation time
--        WRITELINE (OUT_FILE, BUF);            -- and send line to file.
--      elsif MEMWRITE = '1' then               -- if not read, but it is write
--        TADR := CONV_INTEGER ( unsigned(M_ADDR(11 downto 0)) ) / 4;
--        -- set TADR to address as int
--        TVAL := M_DATA_IN;                    -- set TVAL as data in value
--        WRITE (BUF, WR_STR);                  -- start buffer with write indi
--        HWRITE (BUF, M_ADDR);                 -- then the address
--        WRITE (BUF, STR);                     -- then some spaces
--        HWRITE (BUF, TVAL);                   -- and the value written
--        WRITE (BUF, STR);                     -- still more spaces
--        WRITE (BUF, NOW);                     -- simulation time
--        WRITELINE (OUT_FILE, BUF);            -- and send line to file
--        THE_MEMORY ( CONV_INTEGER ( unsigned(M_ADDR(11 downto 0)) ) / 4) := M_DATA_IN;
--                                              -- and finally, value to the mem
--      end if;
--    end if;
--  end process;
--end architecture;
-- }}}1

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
        wait for 20 ns;
    end process;

    signalTests1: process
        procedure printInstruction(p_addr : in address; p_data : in word) is
            variable buf: line;
        begin
            write(buf, string'("0x"));
            hwrite(buf, p_addr);
            write(buf, string'(": 0x"));
            hwrite(buf, p_data);
            writeline(OUTPUT, buf);
        end procedure;
    begin
        s_data_in <= (others => '0');
        s_addr <= x"00000064";
        s_wr_enable <= '0';
        wait for 100 ns;
        assert (s_data_out = x"00001064");
        printInstruction(s_addr, s_data_out);
 
        wait;
    end process;
end architecture;
