%Daniel Bowen
%ECE438L Design of Computers\
Pipelined MIPS Processor
%Due: 05/06/15

\pagebreak
\tableofcontents
\pagebreak

# Introduction

This project's specification is an implementation of Figure 4.65 in Hennessy 
and Patterson for a 5-stage pipelined MIPS processor. (Also included is a basic 
implementation of the simpler single-cycle MIPS processor from Figure 4.17, 
described later)

# Methodology

A disclaimer to start: I unfortunately ran out of time to complete this project 
as thoroughly as I would have liked. This was quite disappointing, as I think I 
have a reasonably solid foundation to work with and had a rough plan of attack 
for the problems that still need to be solved (forwarding, stalls, more 
testing/verification).

The pipelined processor in its current form does mostly function (more on that 
later) for a reasonably-sized subset of MIPS instructions, as long as all 
hazards are avoided (thus basically most instructions that did not sound 
particularly exotic, like coprocessor, trap, floating point, etc). All three 
instruction formats are thus supported (jump, r-type, and immediate). The 
pipeline stages (fetch, decode, execute, memory, and write-back) were split up 
into individual modules to make the problems easier to think about and test. It 
is intended that the pipeline modules do not have to comprehend anything beyond 
the current clock cycle.  They simply perform their single, small task on each 
clock cycle with the work they are given (at the inputs). It is the task of an 
overarching "CPU" module that instantiates these pipeline stages to view the 
bigger picture and coordinate connections between the pipeline stages and 
detect/handle hazards, forwarding, and stalls. One perceived benefit of this 
approach was simplifying this complex hazard resolution task by removing the 
rest of the processor's functionality from it. Each stage writes to its output 
on the rising clock edge only.  Values thus ripple through the pipeline on each 
clock cycle.

Each pipeline stage's interface is implemented as a record type so that the 
higher CPU module simply "plugs" one module into another (it plays an "adapter" 
role in object-oriented parlance) in a clean fashion, making any translations 
and splices along the way.

## Stages

The pipeline stages "own their own hardware", so the fetch stage owns 
instruction memory and the PC, the decode stage owns the register file, the 
execute stage owns the ALU, and the memory stage owns the data memory. The 
exception to this is the writeback stage, since it shares the register file 
with the decode stage. The decode unit thus unwittingly performs double-duty 
(its write-back activity is independent of its decode activity --- forwarding 
is to be handled by the CPU module, not the decode module).

# Testing

Though the pipeline stages were divided up to facilitate testing, most testing 
was done in `atb_cpu.vhd`. Though this file originated as an instruction fetch 
test, for time reasons, it grew into what became the integration of all five 
pipeline units. There are also testbenches for the register file, data memory, 
and instruction memory.

To test programs in the CPU module (with all pipelines), a script was written 
(in Python, `convert_opcodes.py`) that parsed disassembled MIPS output from 
`objdump` (from the Microchip tool suite) and wrote a data memory input file in 
the expected format (address-opcode-mnemonic). Thus small test programs could 
be written in MIPS assembly, converted to the right format (using a `Make` 
script that invoked the assembler, disassembler, and format converter), and run 
in the testbench (the instruction and data memory filenames were specified as 
generics, thus could easily be switched by different testbenches).  Multiple 
testbench implementations for the CPU module then could have a series of 
assertions catered to specific test programs. For the wave viewer I was using 
(GTKWave), a format lookup table was created that translated hex opcodes to 
assembly mnemonics on the signal. The same was done for internal pipeline 
register types (to, for example, write out the ALU function from its 
std_logic_vector spec).

## Functionality

Again, for time reasons I did not get to test as much as I think the processor 
could demonstrate, incomplete though it is. The biggest issue was a circular 
signal of some sort in the write-back stage to the instruction decode register 
accesses. I did not get to look too far into it, but I suspect something in the 
register file is to blame with the way values are written and read. The 
inability to write to the register files proves quite crippling to a computer's 
functionality, as in its absence, ALU operations and data memory reads/writes 
cannot be demonstrated. Their architecture, however, is only slightly different 
from loading immediate values (immediates still pass through the ALU). Thus 
shown in Figure 1 is the processor without register write-back loading 
immediate values. 

![A screenshot of the pipelined processor in operation.  The current program is 
set to load various immediates into registers. By following the highlighted 
signals across clock cycles, a trickle of immediate data from the instruction 
can be seen on each clock tick](pipelined1.png)

Without anything being written to registers, the data memory output file 
obviously is not particularly interesting, so it has been omitted.

Once write-back functionality is debugged, I expect to have something pretty 
close to a functioning, hazard-ignorant pipelined processor. At this point the 
plan was to implement data hazard detection and forwarding to the CPU module.

## Hazards

The following are some notes I made in anticipation of forwarding/hazard 
detection.

In the single-cycle implementation, branch tests are performed in the ALU. For 
this pipelined implementation, that would mean we would have to wait for two 
cycles after fetching (ID, EX) to know if we should branch (during which two 
more instructions will get started in the pipeline). However if we perform 
branch detection in the ID stage (either by putting another ALU in the ID 
stage, or, as MIPS does, adding logic for simple tests like equality and 
restricting the sophistication of branching criteria), then we only execute one 
more cycle before branches are detected. The instruction after a branch thus 
always executes. As this is preferable to always stalling after branches, it is 
specified as part of the architecture under the name "delay slot".

### When to stall

New data is only produced in the execute and mem stages.

- 1 stall: If an R-type instruction uses data from a preceding load

```
    `lw $t0,0x($t1)`        # IF  ID  EX  ME  WB
                            #               <-Data $t0 available
    `add $t2,$t0,$t1`       # IF  ID  EX  ME  WB
                            #           <-Data $t0 needed
```

- 1 stall: If a branch uses data from a preceding ALU operation

```
    `add $t0,$t1,$t2`       # IF  ID  EX  ME  WB
                            #           <-Data $t0 available
    `beq $t0,$t3,label1`    # IF  ID  EX  ME  WB
                            #       <-Data $t0 needed
```

- 2 stalls: If a branch uses data from a preceding load


```
    `lw $t0,0x($t1)`        # IF  ID  EX  ME  WB
                            #               <-Data $t0 available
    `beq $t0,$t2,label1`    # IF  ID  EX  ME  WB
                            #       <-Data $t0 needed
```


The CPU module would insert stalls in the fetch stage by disabling PC 
increments and sending a `nop` instruction.  The instruction decode module 
would have to be modified to provide the CPU module with information about 
register accesses.  Infrastructure is already in place to facilitate data 
hazards to branch tests, through branch data test inputs.

# Single-Cycle MIPS

I figure this is relevant: earlier in the semester, I wrote a single-cycle MIPS 
implementation modeled after Figure 4.17 in the text (relatively simple 
compared to the pipelined version in Figure 4.65). Data memory was monitored in 
a wave viewer and instruction memory was populated from the MIPS assembler 
output run through the `objdump` disassembler (in the same way as described 
above for the pipelined version). However instead of loading the instruction 
memory at runtime, a python script was written to parse through the disassembly 
and write VHDL to populate each byte of read-only instruction memory with 
opcodes in the appropriate format. Below is a Fibonacci program (that the 
processor was able to run), next to a fragment of its corresponding VHDL 
instruction memory output. A screenshot of its execution is shown in Figure 2.

The later-supplied instruction memory for this project, which reads a file at 
runtime to obtain its initial contents, is a more elegant approach, as it does 
not require modification to the data memory's VHDL source. It also facilitates 
loading multiple data memory files (filenames) in different test benches.

Shown in Figure 2 are some signals showing operation of the single cycle 
computer as it executes the Fibonacci program. Code for the single-cycle MIPS 
is included in Appendix B.

![The single cycle MIPS implementation executing the Fibonacci program. Signals 
of interest are highlighted (instruction register and the three registers 
holding the Fibonacci value). The Fibonacci sum is also being written to memory 
(not shown, as they each require a separate line)](singleCycle.png)

# Comments

I did run into some problems while running the provided instruction and data 
memory. For example, the string parse on instructions was looking for 25 
characters and would return an (unhelpful/vague) error if fewer than 25 
characters were left on the instruction memory data text line. Over the course 
of trying to debug these kinds of issues, I ended up rewriting the instruction 
and data memory. It is essentially a copy of the provided implementation --- 
the changes are primarily in code style, with a few variables removed in the 
process (in hindsight, this was probably a poor use of limited time).

As I suspect is the case for most curious people, computers have always been 
something quite mysterious and interesting, so to finally now wrap my head 
fairly completely around what a processor does and how it works (even after 
having programmed for some time before) has been very satisfying. Being able to 
say I've implemented a pipelined "modern" processor sounds quite impressive, 
even if just to myself. It thus feels a bit anticlimactic to have not finished 
this --- I intend to keep working on it.

# Appendix A Pipelined MIPS

## A.1 `alu.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.components.all;

-- An asynchronous ALU
entity MIPS_ALU is
    port (
        alu_op  :   in  op_func;
        sh_amnt :   in  std_logic_vector (4 downto 0);
        a       :   in  word;
        b       :   in  word;
        f       :   out word
    );
end entity;

architecture impl1 of MIPS_ALU is
begin
    alu_function_chooser: process (a, b, alu_op) is
    begin
        -- TODO Finish implementing these
        case alu_op is
            -- Arithmetic
            when F_ADD   =>
                f <= std_logic_vector(signed(a)   + signed(b));
            when F_ADDU  =>
                f <= std_logic_vector(unsigned(a) + unsigned(b));
            when F_SUB   =>
                f <= std_logic_vector(signed(a)   - signed(b));
            when F_SUBU  =>
                f <= std_logic_vector(unsigned(a) - unsigned(b));
            when F_DIV   =>
                f <= std_logic_vector(signed(a)   / signed(b));
            when F_DIVU  =>
                f <= std_logic_vector(unsigned(a) / unsigned(b));

            -- Logical
            when F_AND   =>
                f <= a and b;
            when F_OR    =>
                f <= a or b;
            when F_XOR   =>
                f <= a nor b;
            when F_NOR   =>
                f <= a xor b;

            -- Complicated branch checks
            when F_SLT   =>
                if (signed(a) < signed(b)) then
                    f <= x"00000001";
                else
                    f <= (others => '0');
                end if;
            when F_SLTU  =>
                if (unsigned(a) < unsigned(b)) then
                    f <= x"00000001";
                else
                    f <= (others => '0');
                end if;

            -- Shifts
            when F_SLL =>
                f <= std_logic_vector(
                     unsigned(a) sll to_integer(unsigned(sh_amnt)));
            when F_SRL =>
                f <= std_logic_vector(
                     unsigned(a) srl to_integer(unsigned(sh_amnt)));
            when F_SLLV =>
                f <= std_logic_vector(
                     unsigned(a) sll to_integer(unsigned(b)));
            when F_SRLV =>
                f <= std_logic_vector(
                     unsigned(a) srl to_integer(unsigned(b)));

            when others => f <= (others => 'Z');
        end case;
    end process;
end architecture;

```

## A.2 `atb_cpu.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_CPU is
end entity;

architecture impl1 of TB_MIPS_CPU is
    signal s_clk : std_logic := '1';

    signal s_if_in  : if_in := (false, (others => '0'), '0');
    signal s_if_out : if_out := ((others => '0'), (others => '0'));

    -- ID Instruction Decode stage
    signal s_id_in  : id_in  := (pc              => (others => '0'),
                                 instruction     => (others => '0'),
                                 enable_ext_br_data => '0',
                                 ext_br_data     => (others => '0'),
                                 wb_data         => (others => '0'),
                                 wb_reg_addr     => (others => '0'));

    signal s_id_out : id_out := (val_a           => (others => '0'),
                                 val_b           => (others => '0'),
                                 alu_op          => F_SLL,
                                 sh_amnt         => (others => '0'),

                                 enable_delta_pc => false,
                                 delta_pc        => (others => '0'),

                                 wb_reg_addr     => (others => '0'),
                                 reg_to_mem      => (others => '0'),
                                 mux_mem         => MEM_NA);

    signal s_ex_in  : ex_in;
    signal s_ex_out : ex_out;

    signal s_mem_in  : mem_in;
    signal s_mem_out : mem_out;
begin
    ------------------------------------------ FETCH
    if_stage: MIPS_IF
        generic map ("data/instr_test_basic.s.txt")
        port map (s_clk, s_if_in, s_if_out);

    id_if_connections: process (s_id_out) is
    begin
        s_if_in.enable_delta_pc <= s_id_out.enable_delta_pc;
        s_if_in.delta_pc        <= s_id_out.delta_pc;
    end process;

    ------------------------------------------ DECODE
    id_stage: MIPS_ID port map (s_clk, s_id_in, s_id_out);

    if_id_connections: process (s_if_out) is
    begin
        s_id_in.pc              <= s_if_out.pc;
        s_id_in.instruction     <= s_if_out.instruction;
    end process;

    ------------------------------------------ EXECUTE
    ex_stage : MIPS_EX port map (s_clk, s_ex_in, s_ex_out);

    id_ex_connections: process (s_id_out) is
    begin
        s_ex_in.val_a       <= s_id_out.val_a;
        s_ex_in.val_b       <= s_id_out.val_b;
        s_ex_in.alu_op      <= s_id_out.alu_op;
        s_ex_in.sh_amnt     <= s_id_out.sh_amnt;

        s_ex_in.reg_to_mem  <= s_id_out.reg_to_mem;

        s_ex_in.wb_reg_addr <= s_id_out.wb_reg_addr;
        s_ex_in.mux_mem     <= s_id_out.mux_mem;
    end process;

    ------------------------------------------ MEMORY
    mem_stage : MIPS_MEM
        generic map ("data/data_mem_init.txt", "data/mem_trans_cpu.txt")
        port map (s_clk, s_mem_in, s_mem_out);

    id_mem_connections: process (s_ex_out) is
    begin
        s_mem_in.alu_result     <= s_ex_out.alu_result;
        s_mem_in.reg_to_mem     <= s_ex_out.reg_to_mem;

        s_mem_in.wb_reg_addr    <= s_ex_out.wb_reg_addr;
        s_mem_in.mux_mem        <= s_ex_out.mux_mem;
    end process;

    ------------------------------------------ WRITEBACK

--    id_wb_connections: process (s_mem_out) is
--    begin
--        s_id_in.wb_reg_addr <= s_mem_out.wb_reg_addr;
--        s_id_in.wb_data     <= s_mem_out.val_f;
--    end process;

    ------------------------------------------

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for 5 ns;
    end process;

    pipeline_assertions: process
    begin
        s_if_in.disable_pc_incr <= '0'; -- No pipeline stalls

        s_id_in.enable_ext_br_data <= '0'; -- No forwarding yet
        s_id_in.ext_br_data <= (others => '0');

        -- From MEM
        s_id_in.wb_reg_addr <= (others => '0'); -- R0
        s_id_in.wb_data <= (others => '0');

        wait for 10 ns; -- Wait for rising edge to pass
        wait for 10 ns; -- Let the nop pass
        assert s_if_out.pc = x"00000004";
        wait for 10 ns; -- Let the nop pass
        assert s_id_out.val_a = x"FFFF0000"; -- From lui

        wait;
    end process;
end architecture;

```

## A.3 `components.vhd`

```vhdl

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
    subtype opcode is std_logic_vector(5 downto 0);

    type mux_mem_t is (
        MEM_NA, -- Bypass memory (for non-load/store instructions)

        MEM_SB,
        MEM_SH,
        MEM_SW,

        MEM_LB,
        MEM_LBU,
        MEM_LH,
        MEM_LHU,
        MEM_LW

        -- MEM_SWL, -- TODO implement load/store left/right words
        -- MEM_SWR,
        -- MEM_LWR,
        -- MEM_LWL
    );

    ---PIPELINE REGISTER TYPES-------------------------------------- {{{1


    -- IF Instruction Fetch stage
    type if_in is record
        enable_delta_pc : boolean;
        delta_pc        : word;
            -- Adds delta_pc to incremented PC (for branches)

        disable_pc_incr : std_logic;
            -- Prevents PC from being incremented (for stalls)
    end record;

    type if_out is record
        pc          : address; -- The PC associated with `instruction`
        instruction : word;
    end record;

    -- ID Instruction Decode stage
    type id_in is record
        pc : address;
            -- Used to forward pc to $31 during bal/jal
        instruction : word;

        enable_ext_br_data : std_logic;
        ext_br_data : word;
            -- Forwarded data for branching. It's the responsibility of the CPU 
            -- entity to determine data/branch hazards and present the 
            -- appropriate data here.

        wb_data     : word;
        wb_reg_addr : reg_address;
            -- Represents the address to write wb_data to. If zero (register 
            -- r0), wb_data is ignored.
    end record;

    type id_out is record
        val_a       : word;
        val_b       : word;
        alu_op      : op_func;
        sh_amnt     : std_logic_vector(4 downto 0);

        enable_delta_pc : boolean;
        delta_pc    : word;

        wb_reg_addr : reg_address;
            -- Dictates which register the result is written to during WB. If 
            -- this is register zero, nothing is written.
        reg_to_mem : word;
            -- The data for stores and load left/right
        mux_mem : mux_mem_t;
            -- When MEM_W, the result from the ALU represents a memory address 
            -- and should be written to memory. This represents a store.
            -- When MEM_R, the result from the ALU represents a memory address, 
            -- whose contents should then be written to register wb_reg_addr.  
            -- This represents a load.
    end record;

    -- EX Execute stage
    type ex_in is record
        val_a : word;
        val_b : word;
        alu_op : op_func;
        sh_amnt : std_logic_vector(4 downto 0);

        reg_to_mem   : word;

        wb_reg_addr : reg_address;
        mux_mem : mux_mem_t;
    end record;

    type ex_out is record
        alu_result   : word;
            -- The result of the ALU operation. This will be fed into the 
            -- memory stage either as an address (for load/store) or the result 
            -- to store in register wb_reg_addr
        reg_to_mem   : word;
            -- On a store, this will be the data (register contents) to write 
            -- to memory PLAN: just add zero to the value in the ALU to pass it 
            -- through (the CPU module should be able to figure this one out 
            -- for stores?)

        wb_reg_addr : reg_address;
        mux_mem : mux_mem_t;
    end record;

    -- MEM Memory stage
    type mem_in is record
        alu_result   : word;
        reg_to_mem   : word;

        wb_reg_addr : reg_address;
        mux_mem : mux_mem_t;
    end record;

    type mem_out is record
        val_f       : word;
        wb_reg_addr : reg_address;
    end record;


    ---CONSTANTS---------------------------------------------------- {{{1


    constant MEM_DLY : time := 0.5 ns;

    constant R_0  : reg_address := "00000"; -- $0, read-only zero
    constant R_31 : reg_address := "11111"; -- $ra, return address

    -- These opcodes are mostly from Hennessy/Patterson Figure A.10.2 (MIPS 
    -- opcode map)
    constant F_SLL   : op_func := "000000";

    constant F_SRL   : op_func := "000010";
    constant F_SRA   : op_func := "000011";
    constant F_SLLV  : op_func := "000100";

    constant F_SRLV  : op_func := "000110";
    constant F_SRAV  : op_func := "000101";

    constant F_JR    : op_func := "001000";
    constant F_JALR  : op_func := "001001";

    constant F_MULT  : op_func := "011000";
    constant F_MULTU : op_func := "011001";
    constant F_DIV   : op_func := "011010";
    constant F_DIVU  : op_func := "011011";

    constant F_ADD   : op_func := "100000";
    constant F_ADDU  : op_func := "100001";
    constant F_SUB   : op_func := "100010";
    constant F_SUBU  : op_func := "100011";
    constant F_AND   : op_func := "100100";
    constant F_OR    : op_func := "100101";
    constant F_XOR   : op_func := "100110";
    constant F_NOR   : op_func := "100111";

    constant F_SLT   : op_func := "101010";
    constant F_SLTU  : op_func := "101011";

    constant OPCODE_SPECIAL : opcode := "000000"; -- Rest of opcode in func
    constant OPCODE_REGIMM  : opcode := "000001"; -- Single-reg branch tests
    constant OPCODE_J       : opcode := "000010";
    constant OPCODE_JAL     : opcode := "000011";
    constant OPCODE_BEQ     : opcode := "000100";
    constant OPCODE_BNE     : opcode := "000101";
    constant OPCODE_BLEZ    : opcode := "000110";
    constant OPCODE_BGTZ    : opcode := "000111";
    constant OPCODE_ADDI    : opcode := "001000";
    constant OPCODE_ADDIU   : opcode := "001001";
    constant OPCODE_SLTI    : opcode := "001010";
    constant OPCODE_SLTIU   : opcode := "001011";
    constant OPCODE_ANDI    : opcode := "001100";
    constant OPCODE_ORI     : opcode := "001101";
    constant OPCODE_XORI    : opcode := "001110";
    constant OPCODE_LUI     : opcode := "001111";

    constant OPCODE_LB      : opcode := "100000";
    constant OPCODE_LH      : opcode := "100001";
    constant OPCODE_LWL     : opcode := "100010";
    constant OPCODE_LW      : opcode := "100011";
    constant OPCODE_LBU     : opcode := "100100";
    constant OPCODE_LHU     : opcode := "100101";
    constant OPCODE_LWR     : opcode := "100110";

    constant OPCODE_SB      : opcode := "101000";
    constant OPCODE_SH      : opcode := "101001";
    constant OPCODE_SWL     : opcode := "101010";
    constant OPCODE_SW      : opcode := "101011";

    constant RT_BLTZ   : reg_address := "00001";
    constant RT_BGEZ   : reg_address := "00010";
    constant RT_BLTZAL : reg_address := "10000";
    constant RT_BGEZAL : reg_address := "10001";

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
            sh_amnt :   in  std_logic_vector (4 downto 0);
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
            data_size : in  std_logic_vector(1 downto 0);
                -- Number of bytes (1-4) to read/write. Warning: likely gotcha: 
                -- this is implemented as number of bytes-1, not number of 
                -- bytes!
            data_out  : out word
        );
    end component;

    ---PIPELINE STAGES---------------------------------------------- {{{1

    component MIPS_IF is
        generic (imem_filename : string);
        port (
            clk    : in  std_logic;
            if_in  : in  if_in;
            if_out : out if_out
        );
    end component;

    component MIPS_ID is
        port (
            clk    : in  std_logic;
            id_in  : in  id_in;
            id_out : out id_out
        );
    end component;

    component MIPS_EX is
        port (
            clk    : in  std_logic;
            ex_in  : in  ex_in;
            ex_out : out ex_out
        );
    end component;

    component MIPS_MEM is
        generic (
            dmem_init_filename : string;
            dmem_filename      : string
        );
        port (
            clk    : in  std_logic;
            mem_in  : in  mem_in;
            mem_out : out mem_out
        );
    end component;

    ---FUNCTIONS---------------------------------------------------- {{{1

    procedure print_word (p_addr : in address; p_word : in word);
end package;

package body COMPONENTS is
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

```

## A.4 `convert_opcodes.py`

```python

import sys
import re

# 3/22/15 7:56pm
# Converts opcodes from the text format objdump disassembles them into (passed 
# to this script via stdin) to a format able to be copy-pasted into VHDL to 
# initialize the instruction memory.
addr = 0
for l in sys.stdin.readlines():
    m = re.findall("\s+\w+:\s+(\w{8})\s+(.*)\s",
        re.sub('\s+', ' ', l));
    print('%08X %8s%25s' % (addr, m[0][0], m[0][1]))
    addr = addr + 4

```

## A.5 `data_mem.vhd`

```vhdl

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
        data_size : in  std_logic_vector(1 downto 0);
            -- Number of bytes (1-4) to read/write. Warning: likely gotcha: 
            -- this is implemented as number of bytes-1, not number of bytes!
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
                -- write(buf_write, string'("0x"));
                -- hwrite(buf_write, v_addr);
                -- write(buf_write, string'(": file: 0x"));
                -- hwrite(buf_write, v_data);
                -- write(buf_write, string'(" iAddr="));
                -- write(buf_write, i);
                -- writeline(OUTPUT, buf_write);
            end loop;
            write(buf_write, string'("Data memory loaded"));
            writeline(OUTPUT, buf_write);
            memory_is_init := true;
        elsif rising_edge(clk) then
            i := conv_integer(unsigned(addr(9 downto 0)));
            if wr_enable = '1' then
                for j in 0 to conv_integer(unsigned(data_size)) loop
                    mem(i+j) <= wr_data((8*j)+7 downto 8*j);
                end loop;

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
            -- XXX Ignores data_size for now on reads
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
    signal s_data_size : std_logic_vector(1 downto 0) := "11";
begin
    uut : MIPS_DMEM
        generic map
            ("data/data_mem_init.txt", "data/mem_trans_test.txt")
        port map
            (s_clk, s_addr, s_wr_enable, s_data_in, s_data_size, s_data_out);

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
        assert s_data_out = x"00001068";
        print_word(s_addr, s_data_out);

        s_addr <= x"00000065";
        s_data_in <= x"FFFFFFFF";
        s_data_size <= "00"; -- 1 byte
        s_wr_enable <= '1';
        wait for 15 ns;
        s_wr_enable <= '0';
        s_addr <= x"00000064";
        wait for 10 ns;
        assert s_data_out = x"DEADFFEF";
        print_word(s_addr, s_data_out);
 
        wait;
    end process;
end architecture;

```

## A.6 `ex.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_EX is
    port (
        clk    : in  std_logic;
        ex_in  : in  ex_in;
        ex_out : out ex_out
    );
end entity;

architecture impl1 of MIPS_EX is
    signal s_alu_result : word := (others => '0');
begin
    alu: MIPS_ALU
        port map(
            alu_op => ex_in.alu_op,
            sh_amnt => ex_in.sh_amnt,
            a => ex_in.val_a,
            b => ex_in.val_b,
            f => s_alu_result);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            ex_out.wb_reg_addr <= ex_in.wb_reg_addr;
            ex_out.mux_mem <= ex_in.mux_mem;
            ex_out.reg_to_mem <= ex_in.reg_to_mem;
            ex_out.alu_result <= s_alu_result;
        end if;
    end process;
end architecture;

```

## A.7 `id.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; -- vs numeric_std because this allows uint+int
use work.components.all;

entity MIPS_ID is
    port (
        clk    : in  std_logic;
        id_in  : in  id_in;
        id_out : out id_out
    );
end entity;

architecture impl1 of MIPS_ID is
    type mux_val_a_t is (
        M_REGA,  -- Register A value
        M_IMMUP, -- Upper immediate, useful for lui
        M_R_0,   -- Zeros out the value (effectively passing $0)
        M_PC     -- For passing PC to $31 on bal/jal
    );
    type mux_val_b_t is (
        M_REGB, -- Register B value
        M_IMMS, -- Sign-ext immediate, useful for r-ops and address calcs
        M_IMMU, -- Zero-ext imm, useful for logical immediates (andi, etc)
        M_R_0   -- Zeros out the value (effectively passing $0)
    );
    type branch_criteria_t is (
        B_J,    -- Unconditional branch (jump)
        B_EQ,   -- Check for reg_a = reg_b
        B_NE,   -- reg_a /= reg_b
        B_LEZ,  -- reg_a(31) = '1' or reg_a = 0
        B_LTZ,  -- reg_a(31) = '1' and reg_a /= 0
        B_GEZ,  -- reg_a(31) = '0' or reg_a = 0
        B_GTZ,  -- reg_a(31) = '0' and reg_a /= 0
        B_NA    -- Disable branching
    );

    -- Determines information ultimately seen in the other pipeline stages
    type control_word is record
        -- IF
        branch_criteria : branch_criteria_t;

        -- EX
        mux_val_a : mux_val_a_t; -- Determine outputs
        mux_val_b : mux_val_b_t;
        alu_op : op_func; -- The ALU operation that should be performed in EX

        -- MEM
        mux_mem : mux_mem_t; -- Determines what the memory stage should do

        -- WB
        wb_reg_addr : reg_address; -- The register address to pass to the WB
                                   -- stage (R_0 to disable WB)
    end record;

    signal reg_a, reg_b : word := (others => '0');

    signal jimm_sign_ext : word;
    signal imm_sign_ext : word;
        -- Sign-extended instruction immediates (jimm = jump immediate)

    signal enable_reg_wr : std_logic;
        -- Used for the WB stage (set to 1 if wb_reg_addr != $0)

    signal instr_imm       : std_logic_vector(15 downto  0);
    signal instr_jimm      : std_logic_vector(25 downto  0); -- Jump immediate
    signal instr_sh_amnt   : std_logic_vector( 4 downto  0);
    signal instr_rs, instr_rt, instr_rd : reg_address;
    signal instr_func      : op_func;
    signal instr_opcode    : opcode;

    signal cw : control_word;
begin
    reg_file: MIPS_REG port map(
        clk => clk,
        addr_a => instr_rs,
        addr_b => instr_rt,
        data_a => reg_a,
        data_b => reg_b,
        wr_enable => enable_reg_wr,
        wr_addr => id_in.wb_reg_addr,
        wr_data => id_in.wb_data);

    enable_reg_wr <= '0' when (id_in.wb_reg_addr = R_0) else '1';

    -- Extract portions of the instruction opcode
    instr_imm     <= id_in.instruction(15 downto  0);
    instr_jimm    <= id_in.instruction(25 downto  0);
    instr_sh_amnt <= id_in.instruction(10 downto  6);
    instr_func    <= id_in.instruction( 5 downto  0);
    instr_rs      <= id_in.instruction(25 downto 21);
    instr_rt      <= id_in.instruction(20 downto 16);
    instr_rd      <= id_in.instruction(15 downto 11);
    instr_opcode  <= id_in.instruction(31 downto 26);

    -- Sign-extend immediate and jump-immediate formats
    imm_sign_ext  <= x"FFFF" & instr_imm
                     when instr_imm(15) = '1' else
                     x"0000" & instr_imm;
    jimm_sign_ext <= "111111" & instr_jimm
                     when instr_jimm(25) = '1' else
                     "000000" & instr_jimm;
    
    instruction_decode: process (instr_func) is
    begin
        case instr_opcode is
            -- R-type ALU ops
            when OPCODE_SPECIAL =>
                case instr_func is
                    when F_MULT | F_MULTU | F_DIV | F_DIVU | F_ADD | F_ADDU |
                         F_SUB  | F_SUBU  | F_AND | F_OR   | F_XOR | F_NOR  |
                         F_SLT  | F_SLTU  | F_SLL | F_SRL  | F_SLLV| F_SRLV =>
                        cw <= (branch_criteria => B_NA,
                               mux_val_a       => M_REGA,
                               mux_val_b       => M_REGB,
                               alu_op          => instr_func,
                               mux_mem         => MEM_NA,
                               wb_reg_addr     => instr_rd);
                    when others =>
                        cw <= (B_NA, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                end case;

            -- Single-register branches
            when OPCODE_REGIMM  =>
                case instr_rt is
                    when RT_BLTZ =>
                        cw <= (B_LTZ, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                    when RT_BGEZ =>
                        cw <= (B_GEZ, M_R_0, M_R_0, F_ADDU, MEM_NA, R_0);
                    when RT_BLTZAL =>
                        cw <= (B_LTZ,  M_PC, M_R_0, F_ADDU, MEM_NA, R_31);
                    when RT_BGEZAL =>
                        cw <= (B_GEZ,  M_PC, M_R_0, F_ADDU, MEM_NA, R_31);
                    when others =>
                end case;

            -- Branches
            when OPCODE_J    =>
                cw <= (   B_J,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_JAL  =>
                cw <= (   B_J,    M_PC,  M_R_0,  F_ADDU, MEM_NA, R_31);
            when OPCODE_BEQ  =>
                cw <= (  B_EQ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BNE  =>
                cw <= (  B_NE,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BLEZ =>
                cw <= ( B_LEZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);
            when OPCODE_BGTZ =>
                cw <= ( B_GTZ,   M_R_0,  M_R_0,  F_ADDU, MEM_NA, R_0);

            -- Immediates
            when OPCODE_ADDI  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_NA, instr_rt);
            when OPCODE_ADDIU =>
                cw <= (B_NA,  M_REGA, M_IMMS,  F_ADDU, MEM_NA, instr_rt);
            when OPCODE_SLTI  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when OPCODE_SLTIU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_SLT, MEM_NA, instr_rt);
            when OPCODE_ANDI  =>
                cw <= (B_NA,  M_REGA, M_IMMU,   F_AND, MEM_NA, instr_rt);
            when OPCODE_ORI   =>
                cw <= (B_NA,  M_REGA, M_IMMU,    F_OR, MEM_NA, instr_rt);
            when OPCODE_XORI  =>
                cw <= (B_NA,  M_REGA, M_IMMU,   F_XOR, MEM_NA, instr_rt);
            when OPCODE_LUI   =>
                cw <= (B_NA, M_IMMUP,  M_R_0,   F_ADD, MEM_NA, instr_rt);

            -- Loads
            when OPCODE_LB  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LB, instr_rt);
            when OPCODE_LH  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LH, instr_rt);
            when OPCODE_LW  =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_LW, instr_rt);
            when OPCODE_LBU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_LBU, instr_rt);
            when OPCODE_LHU =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD, MEM_LHU, instr_rt);

            -- Stores
            when OPCODE_SB =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SB, R_0);
            when OPCODE_SH =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SH, R_0);
            when OPCODE_SW =>
                cw <= (B_NA,  M_REGA, M_IMMS,   F_ADD,  MEM_SW, R_0);
            when others =>
        end case;
    end process;

    writeback_process: process (clk) is
    begin
    end process;

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            case cw.branch_criteria is
                when B_J =>
                    id_out.delta_pc <= jimm_sign_ext(29 downto 0) & "00";
                when others =>
                    id_out.delta_pc <=  imm_sign_ext(29 downto 0) & "00";
            end case;

            case cw.branch_criteria is
                when B_NA   => id_out.enable_delta_pc <= false;
                when B_J    => id_out.enable_delta_pc <= true;
                when B_EQ   => id_out.enable_delta_pc <= reg_a = reg_b;
                when B_NE   => id_out.enable_delta_pc <= reg_a /= reg_b;
                when B_LTZ  => id_out.enable_delta_pc <= reg_a(31) = '1';
                when B_GTZ  => id_out.enable_delta_pc <= reg_a(31) = '0';
                when B_LEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '1') or (reg_a = x"00000000");
                when B_GEZ  => id_out.enable_delta_pc <=
                    (reg_a(31) = '0') or (reg_a = x"00000000");
                when others => id_out.enable_delta_pc <= false;
            end case;

            case cw.mux_val_a is
                when M_REGA  => id_out.val_a <= reg_a;
                when M_IMMUP => id_out.val_a <= instr_imm & x"0000";
                when M_R_0   => id_out.val_a <= (others => '0');
                when M_PC    => id_out.val_a <= id_in.pc;
            end case;

            case cw.mux_val_b is
                when M_IMMS => id_out.val_b <= imm_sign_ext;
                when M_IMMU => id_out.val_b <= x"0000" & instr_imm;
                when M_REGB => id_out.val_b <= reg_b;
                when M_R_0  => id_out.val_b <= (others => '0');
            end case;

            id_out.alu_op <= cw.alu_op;
            id_out.sh_amnt <= instr_sh_amnt; -- Only observed on shifts

            id_out.wb_reg_addr <= cw.wb_reg_addr;
            id_out.reg_to_mem <= reg_b;
            id_out.mux_mem <= cw.mux_mem;
        end if;
    end process;
end architecture;

```

## A.8 `if.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

entity MIPS_IF is
    generic (imem_filename : string := "data/instr_mem.txt");
    port (
        clk    : in  std_logic;
        if_in  : in  if_in;
        if_out : out if_out
    );
end entity;

architecture impl1 of MIPS_IF is
    signal s_pc : address := (others => '0');
    signal s_instruction : word := (others => '0');
begin
    imem1: MIPS_IMEM
        generic map (imem_filename)
        port map(s_pc, s_instruction);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            if if_in.disable_pc_incr = '0' then
                if if_in.enable_delta_pc then
                    s_pc <= unsigned(s_pc) + 4 + signed(if_in.delta_pc);
                else
                    s_pc <= unsigned(s_pc) + 4;
                end if;
            end if;

            if_out.pc <= s_pc;
            if_out.instruction <= s_instruction;
        end if;
    end process;
end architecture;

```

## A.9 `instr_mem.vhd`

```vhdl

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
    -- XXX incorrectly is word-addressed instead of byte-addressed
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
            write(bufWrite, string'("Instruction memory loaded"));
            writeline(OUTPUT, bufWrite);
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

```

## A.10 `mem.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

entity MIPS_MEM is
    generic (
        dmem_init_filename : string := "data/data_mem_init.txt";
        dmem_filename      : string := "data/mem_trans.txt"
    );
    port (
        clk    : in  std_logic;
        mem_in  : in  mem_in;
        mem_out : out mem_out
    );
end entity;

architecture impl1 of MIPS_MEM is
    signal mem_read_data, mem_write_data : word;
    signal wr_enable : std_logic;

    signal b_sign_ext, h_sign_ext : word;
    signal data_size : std_logic_vector(1 downto 0) := "11"; -- Read 4 Bytes
begin
    dmem1: MIPS_DMEM
        generic map (dmem_init_filename, dmem_filename)
        port map(
            clk => clk,
            addr => mem_in.alu_result,
            wr_enable => wr_enable,
            wr_data => mem_write_data,
            data_size => data_size,
            data_out => mem_read_data);

    data_size <= "00" when (mem_in.mux_mem = MEM_SB) else
                 "01" when (mem_in.mux_mem = MEM_SH) else "11";

    mem_write_data <= mem_in.reg_to_mem;

    wr_enable <= '1' when(mem_in.mux_mem = MEM_SW or
                          mem_in.mux_mem = MEM_SH or
                          mem_in.mux_mem = MEM_SB) else '0';

    b_sign_ext <= x"FFFFFF" & mem_read_data(7 downto 0)
                  when mem_read_data(7) = '1' else
                  x"000000" & mem_read_data(7 downto 0);

    h_sign_ext <= x"FFFF" & mem_read_data(15 downto 0)
                  when mem_read_data(15) = '1' else
                  x"0000" & mem_read_data(15 downto 0);

    alignment_assertions: process (mem_in.reg_to_mem, mem_in.mux_mem) is
    begin
        case mem_in.mux_mem is
            when MEM_SH => assert mem_in.alu_result(0) = '0'
                report "Half-word store not 2 byte-aligned";
            when MEM_SW => assert mem_in.alu_result(1 downto 0) = "00"
                report "Word store not 4 byte-aligned";
            when others =>
        end case;
    end process;

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            case mem_in.mux_mem is
                when MEM_LB  =>
                    mem_out.val_f <= b_sign_ext;
                when MEM_LBU =>
                    mem_out.val_f <= x"000000" & mem_read_data(7 downto 0);
                when MEM_LH =>
                    mem_out.val_f <= h_sign_ext;
                when MEM_LHU =>
                    mem_out.val_f <= x"0000" & mem_read_data(15 downto 0);
                when MEM_LW  => mem_out.val_f <= mem_read_data;
                when others =>
                    mem_out.val_f <= mem_in.alu_result;
            end case;

            -- Note that on stores, we don't want to save anything --- however 
            -- the ID stage should already have disabled WB (by setting 
            -- wb_reg_addr to R_0)
            mem_out.wb_reg_addr <= mem_in.wb_reg_addr;
        end if;
    end process;
end architecture;

```

## A.11 `reg.vhd`

```vhdl

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

```

# Appendix B Single Cycle MIPS

## B.1 `adder32.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity ADDER_32 is
    port (
        A,B: in  std_logic_vector(31 downto 0);
        F:   out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of ADDER_32 is
begin
    F <= std_logic_vector(unsigned(A) + unsigned(B));
end;

```

## B.2 `alu.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity ALU is
    port (
        A,B:     in  std_logic_vector(31 downto 0);
        CLK:     in  std_logic;
        CONTROL: in  std_logic_vector(3 downto 0);
        F:       out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of ALU is
    signal aLessThanB : std_logic;
begin
    -- This signal exists because you apparently can't write this inline...?
    -- The Boolean-std_logic conversion function is in Mentor Graphics' IEEE
    aLessThanB <= to_stdlogic(signed(A) < signed(B));

    F <= A AND B when CONTROL = x"0" else
         A OR B  when CONTROL = x"1" else
         A NOR B when CONTROL = x"C" else
         std_logic_vector(unsigned(A) + unsigned(B)) when CONTROL = x"2" else
         std_logic_vector(unsigned(A) - unsigned(B)) when CONTROL = x"6" else
         std_logic_vector(signed(A) + signed(B)) when CONTROL = x"9" else
         (0 => aLessThanB, others => '0') when CONTROL = x"7" else
         (others => '0');

--    p1: process (CLK) is
--    begin
--        if rising_edge(CLK) then
--            case CONTROL is
--                when x"0" => F <= A AND B;
--                when x"1" => F <= A OR B;
--                when x"C" => F <= A NOR B;
--                when x"2" => F <= std_logic_vector(unsigned(A) + unsigned(B));
--                when x"6" => F <= std_logic_vector(unsigned(A) - unsigned(B));
--                when x"7" => F <= (0 => aLessThanB, others => '0');
--                when others => F <= (others => '0');
--            end case;
--        end if;
--    end process;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_ALU  is end;

architecture impl1 of TB_ALU is
    signal sA, sB, sF: std_logic_vector(31 downto 0);
    signal sControl: std_logic_vector(3 downto 0);
    signal sClk: std_logic := '0';
begin
    uut1: ALU port map (sA, sB, sCLK, sControl, sF);

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

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0010"; -- Addition
        wait for T/2;
        assert (sF /= x"00000005");
        wait for T/2;
        assert (sF = x"00000005");

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0110"; -- Subtraction
        wait for T/2;
        assert (sF /= x"FFFFFFFF");
        wait for T/2;
        assert (sF = x"FFFFFFFF");

        sA <= x"00000002";
        sB <= x"00000003";
        sControl <= "0111"; -- SLT
        wait for T/2;
        assert (sF /= x"00000001");
        wait for T/2;
        assert (sF = x"00000001");

        sA <= x"00000003";
        sB <= x"00000003";
        sControl <= "0111"; -- SLT
        wait for T/2;
        assert (sF /= x"00000000");
        wait for T/2;
        assert (sF = x"00000000");

        write(buf, string'("Assertions tb_alu complete"));
        writeline(output, buf);
        wait;
    end process;
end architecture;

```

## B.3 `components.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;

package COMPONENTS is
    constant g_delay: TIME := 1 ns;
    constant T: time := 200 ns; -- Testbench period

    component MEM_RO_1K is
        port (
            CLK:  in  std_logic;
            ADDR: in  std_logic_vector(9 downto 0);
            DATA: out std_logic_vector(31 downto 0)
        );
    end component;

    component MEM_1K is
        port (
            CLK:   in  std_logic;
            ADDR:  in  std_logic_vector(9 downto 0);
            WR:    in  std_logic;                     -- Enable write
            DATAW: in  std_logic_vector(31 downto 0); -- Data write
            DATAR: out std_logic_vector(31 downto 0)  -- Data read
        );
    end component;

    component ADDER_32 is
        port (
            A,B: in  std_logic_vector(31 downto 0);
            F:   out std_logic_vector(31 downto 0)
        );
    end component;

    component ALU is
        port (
            A,B:     in  std_logic_vector(31 downto 0);
            CLK:     in  std_logic;
            CONTROL: in  std_logic_vector(3 downto 0);
            F:       out std_logic_vector(31 downto 0)
        );
    end component;

    component REGISTER_ARRAY_32_32 is
        port (
            ADDR1,ADDR2,ADDRW: in  std_logic_vector(4 downto 0);
            REG1,REG2:         out std_logic_vector(31 downto 0);
            DATA:              in  std_logic_vector(31 downto 0);
            ENW:               in  std_logic; -- Register Write enable
            CLK:               in  std_logic
        );
    end component;

    component SIGNEXTEND_16_32 is
        port (
            X: in  std_logic_vector(15 downto 0);
            F: out std_logic_vector(31 downto 0)
        );
    end component;

    component CPU_IR_DECODER is
    port (
        IR:  in  std_logic_vector(31 downto 0);

        -- RegDst is essentially a question of whether the instruction is 
        -- I-type or R-type (ie "where in the instruction is rd?")
        RegDst, Branch, MemRead, MemWrite, RegWrite : out std_logic;
        ALUSrc, RegWSrc: out std_logic_vector (1 downto 0);
        ALUControl: out std_logic_vector (3 downto 0)
    );
    end component;

    component CPU_SINGLECYCLE is
    port (
        CLK:  in  std_logic;
        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft,
            dPC, dIR, dBrPC, dIncrPC, dMemData, dRegData
            : out std_logic_vector(31 downto 0);
        dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst: out std_logic;
        dALUControl: out std_logic_vector(3 downto 0);
        dRegWSrc, dALUSrc: out std_logic_vector(1 downto 0)
    );
    end component;
end package;

```

## B.4 `control.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;

-- Decodes instruction register to provide CPU control signals
-- Below are some sample opcodes
--   8f210200        lw      at,512(t9)
--   1001ffff        beq     zero,at,8 <main+0x8>
--   af210204        sw      at,516(t9)
--   00000000        nop
--   00430820        add     at,v0,v1
--   00430822        sub     at,v0,v1
--   00430824        and     at,v0,v1
--   00430825        or      at,v0,v1
--   0043082a        slt     at,v0,v1
entity CPU_IR_DECODER is
    port (
        IR:  in  std_logic_vector(31 downto 0);

        -- RegDst is essentially a question of whether the instruction is 
        -- I-type or R-type (ie "where in the instruction is rd?")
        RegDst, Branch, MemRead, MemWrite, RegWrite : out std_logic;
        ALUSrc, RegWSrc: out std_logic_vector (1 downto 0);
        ALUControl: out std_logic_vector (3 downto 0)
    );
end entity;

architecture impl1 of CPU_IR_DECODER is
    type CONTROL_SIGS is record
        RegDst, RegWrite, MemRead, MemWrite, Branch: std_logic;
        ALUSrc, RegWSrc: std_logic_vector(1 downto 0);
        ALUOp: std_logic_vector(2 downto 0);
    end record;
    signal cSigs : CONTROL_SIGS;
    
    signal opcode : std_logic_vector(5 downto 0);
    signal fcn : std_logic_vector(5 downto 0);
begin
    opcode <= ir(31 downto 26);
    fcn <= ir(5 downto 0);

    cSigs <= ('1','1','0','0','0',"00","00","010")
            when opcode = "000000"  -- R-type instruction
        else ('0','1','1','0','0',"01","01","000")
            when opcode = "100011"  -- lw
        else ('0','0','0','1','0',"01","00","000")
            when opcode = "101011"  -- sw
        else ('0','1','0','0','0',"00","10","000")
            when opcode = "001111"  -- lui
        else ('0','1','0','0','0',"10","00","011")
            when opcode = "001101"  -- ori
        else ('0','1','0','0','0',"10","00","000")
            when opcode = "001001"  -- addiu
        else ('0','1','0','0','0',"01","00","100")
            when opcode = "001000"  -- addi
        else ('0','0','0','0','1',"00","00","001")
            when opcode = "000100"; -- beq

    ALUControl <=
             "0010" when cSigs.ALUOp = "000" -- addu (LW,SW,ADDIU)
        else "0110" when cSigs.ALUOp = "001" -- subu (BEQ)
        else "0001" when cSigs.ALUOp = "011" -- OR (ORI)
        else "1001" when cSigs.ALUOp = "100" -- signed add (addi)

        else "0010" when cSigs.ALUOp = "010" and fcn = "100000" -- addu (ADD)
        else "0110" when cSigs.ALUOp = "010" and fcn = "100010" -- subu (SUB)
        else "0000" when cSigs.ALUOp = "010" and fcn = "100100" -- AND
        else "0001" when cSigs.ALUOp = "010" and fcn = "100101" -- OR
        else "0111" when cSigs.ALUOp = "010" and fcn = "101010";-- SLT

    RegDst <= cSigs.RegDst;
    Branch <= cSigs.Branch;
    MemRead <= cSigs.MemRead;
    RegWSrc <= cSigs.RegWSrc;
    ALUSrc <= cSigs.ALUSrc;
    MemWrite <= cSigs.MemWrite;
    RegWrite <= cSigs.RegWrite;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_CPU_IR_DECODER is end;

architecture impl1 of TB_CPU_IR_DECODER  is
    signal sRegWrite, sMemWrite, sMemRead, sBranch, sZero, sRegDst : std_logic;
    signal sALUControl : std_logic_vector(3 downto 0);
    signal sRegWSrc, sALUSrc : std_logic_vector(1 downto 0);

    signal sIR: std_logic_vector(31 downto 0);
begin
    uut1: CPU_IR_DECODER port map (
        sIR, sRegDst, sBranch, sMemRead, sMemWrite,
        sRegWrite, sALUSrc, sRegWSrc, sALUControl
    );

    signalTests1: process
        variable buf: line;
    begin
        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
        wait for T/4;

        sIR <= x"00430820"; -- add t1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = "00");
        assert(sRegWSrc = "00");
        assert(sRegWrite = '1');
        assert(sMemRead = '0');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"8f210200"; -- lw $t1,0x200($t9)
        wait for T/2;
        assert(sRegDst = '0');
        assert(sALUSrc = "01");
        assert(sRegWSrc = "01");
        assert(sRegWrite = '1');
        assert(sMemRead = '1');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0010");

        sIR <= x"0043082a"; -- slt $1,$2,$3
        wait for T/2;
        assert(sRegDst = '1');
        assert(sALUSrc = "00");
        assert(sRegWSrc = "00");
        assert(sRegWrite = '1');
        assert(sMemRead = '0');
        assert(sMemWrite = '0');
        assert(sBranch = '0');
        assert(sALUControl = "0111");

        write(buf, string'("Assertions tb_control complete"));
        writeline(output, buf);

        wait;
    end process;
end architecture;

```

## B.5 `convertOpcodes.py`

```python

import sys
import re

# 3/22/15 7:56pm
# Converts opcodes from the text format objdump disassembles them into (passed 
# to this script via stdin) to a format able to be copy-pasted into VHDL to 
# initialize the instruction memory.
n = 0
for l in sys.stdin.readlines():
    m = re.findall("\s+\w+:\s+((\w\w)(\w\w)(\w\w)(\w\w))\s+(.*)",
        re.sub('\s+', ' ', l));
    print('-- 0x%s %s' % (m[0][0], m[0][5]))
    print('mem(%d)<=x"%s"; mem(%d)<=x"%s"; mem(%d)<=x"%s"; mem(%d)<=x"%s";' %
        (n*4+0, m[0][4], n*4+1, m[0][3], n*4+2, m[0][2], n*4+3, m[0][1]))
    n = n+1

```

## B.6 `cpu.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

-- Control logic
-- Modeled after Fig 4.17 in Patterson and Hennessy Software/Hardware 4e
entity CPU_SINGLECYCLE is
    port (
        CLK:  in  std_logic;

        -- Debug ports
        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft,
            dPC, dIR, dBrPC, dIncrPC, dMemData, dRegData
            : out std_logic_vector(31 downto 0);

        dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst: out std_logic;
        dALUControl: out std_logic_vector(3 downto 0);
        dRegWSrc, dALUSrc: out std_logic_vector(1 downto 0)
    );
end entity;

architecture impl1 of CPU_SINGLECYCLE is
    -- Control signals (uppercase)
    signal RegWrite, MemWrite, MemRead, Branch, Zero, RegDst : std_logic;
    signal ALUControl : std_logic_vector(3 downto 0);
    signal ALUSrc, RegWSrc : std_logic_vector (1 downto 0);

    constant CFour : std_logic_vector(31 downto 0) := x"00000004";

    -- Datapath signals (lowercase)
    signal regA, aluB, regB, aluF : std_logic_vector(31 downto 0);
    signal sExtImm, sExtShft : std_logic_vector(31 downto 0);
    signal regW : std_logic_vector(4 downto 0);
    signal pc, ir : std_logic_vector(31 downto 0) := (others=>'0');
    signal brPC, incrPC : std_logic_vector(31 downto 0);
    signal memData, regData : std_logic_vector(31 downto 0);
    -- Note: PC is 32-bits, but the memory/memaddr is only 10 bits (1024-word)
begin
    zeroDetect1: Zero <= '1' when (aluF = x"00000000") else '0';
    shiftMemAddrLeft: sExtShft <= sExtImm(29 downto 0) & "00";
    alu1: ALU port map (regA, aluB, CLK, ALUControl, aluF);
    memData1: MEM_1K port map (CLK, aluF(9 downto 0), MemWrite, regB, memData);
    memInstr1: MEM_RO_1K port map (CLK, pc(9 downto 0), ir);
    progCounter1: ADDER_32 port map (pc, CFour, incrPC);
    memAddrAdder1: ADDER_32 port map (incrPC, sExtShft, brPC);
    signExtend1: SIGNEXTEND_16_32 port map (ir(15 downto 0), sExtImm);
    registerFile1: REGISTER_ARRAY_32_32 port map (
        ADDR1 => ir(25 downto 21),
        ADDR2 => ir(20 downto 16),
        ADDRW => regW,
        REG1 => regA,
        REG2 => regB,
        DATA => regData,
        ENW => RegWrite,
        CLK => CLK
    );
    controlSignals1: CPU_IR_DECODER port map(
        ir, RegDst, Branch, MemRead,
        MemWrite, RegWrite, ALUSrc, RegWSrc, ALUControl);

    muxALUInputB: aluB <= sExtImm when ALUSrc = "01"
        else regB when ALUSrc = "00" else x"0000" & ir(15 downto 0);
    muxInputDataToRegister: regData <= memData when RegWSrc = "01"
        else aluF when RegWSrc = "00" else ir(15 downto 0) & x"0000";
    muxSelectIOrJInstructionType: regW <=
        ir(15 downto 11) when RegDst = '1' else ir(20 downto 16);

    p1: process (CLK) is -- Apparently only the PC MUX needs to be clocked?
    begin
        if rising_edge(CLK) then
            muxPC: case (Branch AND Zero) is
                when '1' => pc <= brPC;
                when others => pc <= incrPC;
            end case;
        end if;
    end process;

    -- Debug ports (control and datapath)
    dRegWrite <= RegWrite;
    dALUSrc <= ALUSrc;
    dMemWrite <= MemWrite;
    dMemRead <= MemRead;
    dRegWSrc <= RegWSrc;
    dBranch <= Branch;
    dZero <= Zero;
    dRegDst <= RegDst;
    dALUControl <= ALUControl;

    dRegA <= regA;
    dAluB <= aluB;
    dRegB <= regB;
    dAluF <= aluF;
    dSExt <= sExtImm;
    dSExtShft <= sExtShft;
    dPC <= pc;
    dIR <= ir;
    dBrPC <= brPC;
    dIncrPC <= incrPC;
    dMemData <= memData;
    dRegData <= regData;
end architecture;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_CPU is end;

architecture impl1 of TB_CPU is
    -- Datapath debug signals
    signal dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft, dPC, dIR, dBrPC,
        dIncrPC, dMemData, dRegData : std_logic_vector(31 downto 0);
    -- Control debug signals
    signal dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst : std_logic;
    signal dALUControl : std_logic_vector(3 downto 0);
    signal dRegWSrc, dALUSrc : std_logic_vector(1 downto 0);

    signal sClk: std_logic := '0';
begin
    uut1: CPU_SINGLECYCLE port map (
        sClk,

        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft, dPC, dIR, dBrPC,
        dIncrPC, dMemData, dRegData,

        dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst, dALUControl, 
        dRegWSrc, dALUSrc
    );

    clk1: process is
    begin
        sClk <= not sClk;
        wait for T/2;
    end process;

--    signalTests1: process
--        variable buf: line;
--    begin
--        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
--        wait for T/4;
--
--        --sA <= x"00000002";
--        --sB <= x"00000003";
--        --sControl <= "0010"; -- Addition
--        --wait for T/2;
--        --assert (sF /= x"00000005");
--        --wait for T/2;
--        --assert (sF = x"00000005");
--
--        wait;
--    end process;
end architecture;

```

## B.7 `mem1k_RO.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- Read-only (instruction) memory, 1KB
entity MEM_RO_1K is
    port (
        CLK:  in  std_logic; -- WARNING: clock not used!
        ADDR: in  std_logic_vector(9 downto 0);
        DATA: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of MEM_RO_1K is
    type BYTE_ARR is array(1023 downto 0) of std_logic_vector(7 downto 0); 
    signal mem: BYTE_ARR := (others => (others => '0'));
begin
    -- Enter the program (opcodes) here

    -- loadStoreAdd.s
--    -- 0x00000000 nop
--    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
--    -- 0x8c1c0000 lw gp,0(zero)
--    mem(4)<=x"00"; mem(5)<=x"00"; mem(6)<=x"1c"; mem(7)<=x"8c";
--    -- 0x8f890004 lw t1,4(gp)
--    mem(8)<=x"04"; mem(9)<=x"00"; mem(10)<=x"89"; mem(11)<=x"8f";
--    -- 0x8f8a0040 lw t2,64(gp)
--    mem(12)<=x"40"; mem(13)<=x"00"; mem(14)<=x"8a"; mem(15)<=x"8f";
--    -- 0x012a5820 add t3,t1,t2
--    mem(16)<=x"20"; mem(17)<=x"58"; mem(18)<=x"2a"; mem(19)<=x"01";
--    -- 0xaf8b0044 sw t3,68(gp)
--    mem(20)<=x"44"; mem(21)<=x"00"; mem(22)<=x"8b"; mem(23)<=x"af";
--    -- 0x1000ffff b 18 <here>
--    mem(24)<=x"ff"; mem(25)<=x"ff"; mem(26)<=x"00"; mem(27)<=x"10";

    -- addImmediates.s
--    -- 0x00000000 nop
--    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
--    -- 0x3c083434 lui t0,0x3434
--    mem(4)<=x"34"; mem(5)<=x"34"; mem(6)<=x"08"; mem(7)<=x"3c";
--    -- 0x3c09bf88 lui t1,0xbf88
--    mem(8)<=x"88"; mem(9)<=x"bf"; mem(10)<=x"09"; mem(11)<=x"3c";
--    -- 0x35296210 ori t1,t1,0x6210
--    mem(12)<=x"10"; mem(13)<=x"62"; mem(14)<=x"29"; mem(15)<=x"35";
--    -- 0x354affff ori t2,t2,0xffff
--    mem(16)<=x"ff"; mem(17)<=x"ff"; mem(18)<=x"4a"; mem(19)<=x"35";
--    -- 0x356bfefe ori t3,t3,0xfefe
--    mem(20)<=x"fe"; mem(21)<=x"fe"; mem(22)<=x"6b"; mem(23)<=x"35";
--    -- 0x014be022 sub gp,t2,t3
--    mem(24)<=x"22"; mem(25)<=x"e0"; mem(26)<=x"4b"; mem(27)<=x"01";

    -- fibonacci.s
    -- 0x00000000 nop
    mem(0)<=x"00"; mem(1)<=x"00"; mem(2)<=x"00"; mem(3)<=x"00";
    -- 0x241c0100 li gp,256
    mem(4)<=x"00"; mem(5)<=x"01"; mem(6)<=x"1c"; mem(7)<=x"24";
    -- 0x24090032 li t1,50
    mem(8)<=x"32"; mem(9)<=x"00"; mem(10)<=x"09"; mem(11)<=x"24";
    -- 0x240a0000 li t2,0
    mem(12)<=x"00"; mem(13)<=x"00"; mem(14)<=x"0a"; mem(15)<=x"24";
    -- 0xaf8a0000 sw t2,0(gp)
    mem(16)<=x"00"; mem(17)<=x"00"; mem(18)<=x"8a"; mem(19)<=x"af";
    -- 0x240b0001 li t3,1
    mem(20)<=x"01"; mem(21)<=x"00"; mem(22)<=x"0b"; mem(23)<=x"24";
    -- 0xaf8b0004 sw t3,4(gp)
    mem(24)<=x"04"; mem(25)<=x"00"; mem(26)<=x"8b"; mem(27)<=x"af";
    -- 0x279c0008 addiu gp,gp,8
    mem(28)<=x"08"; mem(29)<=x"00"; mem(30)<=x"9c"; mem(31)<=x"27";
    -- 0x2129fffe addi t1,t1,-2
    mem(32)<=x"fe"; mem(33)<=x"ff"; mem(34)<=x"29"; mem(35)<=x"21";
    -- 0x8f8afff8 lw t2,-8(gp)
    mem(36)<=x"f8"; mem(37)<=x"ff"; mem(38)<=x"8a"; mem(39)<=x"8f";
    -- 0x8f8bfffc lw t3,-4(gp)
    mem(40)<=x"fc"; mem(41)<=x"ff"; mem(42)<=x"8b"; mem(43)<=x"8f";
    -- 0x014b6020 add t4,t2,t3
    mem(44)<=x"20"; mem(45)<=x"60"; mem(46)<=x"4b"; mem(47)<=x"01";
    -- 0xaf8c0000 sw t4,0(gp)
    mem(48)<=x"00"; mem(49)<=x"00"; mem(50)<=x"8c"; mem(51)<=x"af";
    -- 0x279c0004 addiu gp,gp,4
    mem(52)<=x"04"; mem(53)<=x"00"; mem(54)<=x"9c"; mem(55)<=x"27";
    -- 0x2129ffff addi t1,t1,-1
    mem(56)<=x"ff"; mem(57)<=x"ff"; mem(58)<=x"29"; mem(59)<=x"21";
    -- 0x0120402a slt t0,t1,zero
    mem(60)<=x"2a"; mem(61)<=x"40"; mem(62)<=x"20"; mem(63)<=x"01";
    -- 0x1100fff8 beqz t0,24 <fibonacciLoop>
    mem(64)<=x"f8"; mem(65)<=x"ff"; mem(66)<=x"00"; mem(67)<=x"11";
    -- 0x1000ffff b 44 <finishedLoop>
    mem(68)<=x"ff"; mem(69)<=x"ff"; mem(70)<=x"00"; mem(71)<=x"10";

    p1: process (ADDR) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        DATA <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
    end process;
end;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_MEM_RO_1K is end;

architecture impl1 of TB_MEM_RO_1K  is
    signal sClk: std_logic := '0';
    signal sAddr: std_logic_vector(9 downto 0);
    signal sData: std_logic_vector(31 downto 0);
begin
    uut1: MEM_RO_1K port map (sClk, sAddr, sData);

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

        sAddr <= "0000010100";
        wait for T/2;
        assert (sData /= x"1000ffff");
        wait for T/2;
        assert (sData = x"1000ffff");
 
        wait;
    end process;
end architecture;

```

## B.8 `mem1k.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-- 1KB, byte-addressable, but always reads whole words
-- Doesn't allow simultaneous read/write
entity MEM_1K is
    port (
        CLK:   in  std_logic;
        ADDR:  in  std_logic_vector(9 downto 0);
        WR:    in  std_logic;                     -- Enable write
        DATAW: in  std_logic_vector(31 downto 0); -- Data write
        DATAR: out std_logic_vector(31 downto 0)  -- Data read
    );
end entity;

architecture impl1 of MEM_1K is
    type BYTE_ARR is array(natural range <>) of std_logic_vector(7 downto 0);
    -- Goes over 1K a bit to allow a 1-word memory access at index 1K (1023)
    signal mem: BYTE_ARR(1026 downto 0) := (others => (others => '0'));
begin
    p1: process (CLK) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        if rising_edge(CLK) then
            if WR = '1' then
                mem(i+3) <= DATAW(31 downto 24);
                mem(i+2) <= DATAW(23 downto 16);
                mem(i+1) <= DATAW(15 downto 08);
                mem(i+0) <= DATAW(07 downto 00);
                --DATAR <= (others => '0');
            else
                --DATAR <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);

                -- Add some initial data to the memory
                -- LIMITATIONS: this data is essentially read-only --- any 
                -- attempts to write to it will be undone when write is 
                -- de-asserted! Write to areas of memory other than this!
                mem( 0) <= x"04";
                mem( 4) <= x"02";
                mem( 5) <= x"FF";
                mem( 8) <= x"88";
                mem(12) <= x"07";
                mem(16) <= x"05";
                mem(64) <= x"40";
            end if;
        end if;
    end process;

    p2: process (ADDR) is
        variable i: natural;
    begin
        i := conv_integer(unsigned(ADDR));
        DATAR <= mem(i+3) & mem(i+2) & mem(i+1) & mem(i+0);
    end process;
end;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_MEM1K is end;

architecture impl1 of TB_MEM1K is
    signal sWrite,sClk: std_logic := '0';
    signal sAddr: std_logic_vector(9 downto 0);
    signal sDataR,sDataW: std_logic_vector(31 downto 0);
begin
    uut1: MEM_1K port map (sClk, sAddr, sWrite, sDataW, sDataR);

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

        sAddr <= "00" & x"00";
        sWrite <= '0';
        wait for T/2;
        assert (sDataR /= x"0000ff01");
        wait for T/2;
        assert (sDataR = x"0000ff01");

        wait for T;
        sAddr <= "00" & x"20";
        sDataW <= x"deadbeef";
        sWrite <= '1';
        wait for T;
        sWrite <= '0';
        wait for T;
        assert(sDataR = x"deadbeef");
 
        write(buf, string'("Assertions tb_mem1k complete"));
        writeline(output, buf);
        wait;
    end process;
end architecture;

```

## B.9 `registerFile.vhd`

```vhdl

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
    p1: process (CLK, ADDR1, ADDR2) is
        variable i1,i2,iW: natural;
    begin
        i1 := conv_integer(unsigned(ADDR1));
        i2 := conv_integer(unsigned(ADDR2));
        iW := conv_integer(unsigned(ADDRW));

        REG1 <= regs(i1);
        REG2 <= regs(i2);
        if rising_edge(CLK) then
            if ENW = '1' then
                regs(iW) <= DATA;

             --   if i1 = iW then
             --       REG1 <= DATA;
             --   else
             --       REG1 <= regs(i1);
             --   end if;

             --   if i2 = iW then
             --       REG2 <= DATA;
             --   else
             --       REG2 <= regs(i2);
             --   end if;
            else
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

```

## B.10 `signExtend.vhd`

```vhdl

library ieee;
use ieee.std_logic_1164.all;

entity SIGNEXTEND_16_32 is
    port (
        X: in  std_logic_vector(15 downto 0);
        F: out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of SIGNEXTEND_16_32 is
    signal extension : std_logic_vector(15 downto 0);
begin
    extension <= x"0000" when X(15) = '0' else x"FFFF";
    F <= extension & X;
end architecture;

```

