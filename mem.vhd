library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_MEM is
    port (
        clk         :   in  std_logic;
        wr_enable   :   in  std_logic;
        data_in     :   in  word;
        data_addr   :   in  address;
        data_out    :   out word
    );
end;
