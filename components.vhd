library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use ieee.std_logic_textio.all;

package COMPONENTS is
    ---TYPES-------------------------------------------------------- {{{1

    subtype byte is std_logic_vector(7 downto 0);
    subtype word is std_logic_vector(31 downto 0);
    subtype address is word;

    subtype reg_address is std_logic_vector(4 downto 0);
    subtype op_func is std_logic_vector(5 downto 0);

    ---PIPELINE REGISTER TYPES-------------------------------------- {{{1

    -- IF Instruction Fetch stage
    type if_in is record
        branch_pc     : address;
        use_branch_pc : std_logic;
        stall_pc      : std_logic;
    end record;

    type if_out is record
        pc_curr     : address; -- The PC associated with `instruction`
        pc_incr     : address;
        instruction : word;
    end record;

    -- ID Instruction Decode stage
    type id_in is record
        pc_incr     : address;
        instruction : word;

        wb_data_a   : word; -- Data hazard write-back
        wb_data_b   : word;
    end record;

    type id_out is record
        val_a       : word;
        val_b       : word;
        alu_op      : op_func;

        branch_pc     : address;
        use_branch_pc : std_logic;
    end record;

    -- EX Execute stage
    type ex_in is record
        val_a : word;
        val_b : word;
        alu_op : op_func;

        wb_reg_addr : reg_address;
        enable_memw : std_logic;
        enable_memr : std_logic;
    end record;

    type ex_out is record
        val_f       : word;

        wb_reg_addr : reg_address;
        enable_memw : std_logic;
        enable_memr : std_logic;
    end record;

    ---CONSTANTS---------------------------------------------------- {{{1

    constant MEM_DLY : time := 0.5 ns;

    -- TODO Add the rest of the ALU functions
    constant F_ADD   : op_func := "100000";
    constant F_ADDU  : op_func := "100001";
    constant F_AND   : op_func := "100100";
    constant F_DIV   : op_func := "011010";
    constant F_DIVU  : op_func := "011011";
    constant F_NOR   : op_func := "100111";
    constant F_OR    : op_func := "100101";
    constant F_XOR   : op_func := "100110";
    constant F_MULT  : op_func := "011000";
    constant F_MULTU : op_func := "011001";
    constant F_SUB   : op_func := "100010";
    constant F_SUBU  : op_func := "100011";

    ---COMPONENTS--------------------------------------------------- {{{1

    component MIPS_IMEM is
        generic (imem_filename : string);
        port (
            data_addr : in  address;
            data_out  : out word
        );
    end component;

    component MIPS_REG is
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
    end component;

    component MIPS_ALU is
        port (
            alu_op  :   in  op_func;
            a       :   in  word;
            b       :   in  word;
            f       :   out word
        );
    end component;

    component MIPS_DMEM is
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
    end component;

    ---FUNCTIONS---------------------------------------------------- {{{1

    -- Provides a stdout debug function for memory parsers
    procedure print_word (p_addr : in address; p_word : in word);
end package;

package body COMPONENTS is
    -- Prints debug info (including debug ports) for the fp_mult testbench
    procedure print_word (p_addr : in address; p_word : in word) is
        variable buf: line;
    begin
        write(buf, string'("0x"));
        hwrite(buf, p_addr);
        write(buf, string'(": 0x"));
        hwrite(buf, p_word);
        writeline(OUTPUT, buf);
    end procedure;
end package body;
