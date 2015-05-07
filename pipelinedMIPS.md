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

```mips

.set noreorder
nop             # The PC seems to want to start at 0x4, not 0x0

# Print the first 100 fibonacci numbers in 100 consecutive slots in memory
# t0: temp values
# t1: counter
# t2: first fibonacci number
# t3: second fibonacci number
# t4: current fibonacci number

li $sp,0x100    # Start at address 0x100
li $t1,50       # Initialize the counter

############### # Compute the first two numbers by-hand
li $t2,0
sw $t2,0x0($sp) # The first Fibonacci number is 0
li $t3,1
sw $t3,0x4($sp) # The second Fibonacci number is 1

addiu $sp,$sp,8     # Increment the counter by 8 (by-hand)
addi $t1,$t1,-2     # Add -2 (decrement counter by 2)

############### # Do the rest in a loop
fibonacciLoop:
    lw $t2,-0x8($sp)            # Load first number
    lw $t3,-0x4($sp)            # Load second number
    add $t4,$t2,$t3             # Compute current number
    sw $t4,0x0($sp)             # Store current number

    addiu $sp,$sp,4             # Increment memory address
    addi $t1,$t1,-1             # Decrement counter

    slt $t0,$t1,$zero           # Set if i<0
    beq $t0,$0,fibonacciLoop    # Branch if i>=0

finishedLoop:
    b finishedLoop

```

A fragment of the VHDL output produced by the script, to be inserted into the 
data memory module:

```vhdl
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
.
.
.
```

The later-supplied instruction memory for this project, which reads a file at 
runtime to obtain its initial contents, is a more elegant approach, as it does 
not require modification to the data memory's VHDL source. It also facilitates 
loading multiple data memory files (filenames) in different test benches.

Shown in Figure 2 are some signals showing operation of the single cycle 
computer as it executes the Fibonacci program. Code for the single-cycle MIPS 
is included in Appendix B.

![The single cycle MIPS implementation executing the Fibonacci program.  
Signals of interest are highlighted (instruction register and the three 
registers holding the Fibonacci value). The Fibonacci sum is also being written 
to memory (not shown, as they each require a separate line)](singleCycle.png)

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
