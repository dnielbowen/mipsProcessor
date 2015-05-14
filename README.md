4/25/15 3:45pm

The task at hand is to split the single cycle datapath into five independent 
units. All data flows only through this pipeline. That is, there are no detours 
around any stages, for that would violate the fact that each stage runs a 
different set of data on clock cycle. Any data needed by later stages must 
therefore be passed through preceding stages, even if those stages don't use 
it. Thus perhaps the best approach is to build the datapath from right to left, 
keeping track of data needed by later stages as earlier stages are implemented.

Ideally, each stage would be completely "decoupled" from the problem of 
"building a processor". All it knows is its single task ("perform ALU 
operations", "writing to memory", etc).

The stages:
  - IF (instruction fetch)
  - ID (instruction decode)
  - EX (execution)
  - MEM (memory access)
  - WB (register write-back)

# Misc

## How does a data hazard look?

Here's an implementation of

    lui $s0,0x1234
    lui $s1,0xABCD
    add $s2,$s1,$s0

  - IF
        - `instruction = add $s2,$s1,$s0`
  - ID
        - `wb_reg_addr = "10001"`
  - EX
        - `alu_result = x"ABCD0000"`
        - `wb_reg_addr = "10000"`
  - MEM
  - WB

- Non-branch data hazards
    ...are only important at the EX stage. Thus I'd have a mux before `val_a` 
    and `val_b` on the EX stage --- this ex hazard mux would check the ex, mem, 
    and wb's `wb_reg_addr` for the current writeback address (the ID would also 
    need to output the address of reg A and B for comparison) and forward 
    appropriately.

    -- XXX Does this incorrectly forward data destined for register $0?
    s_ex_in.val_a <= s_ex_out.alu_result when
                     (s_ex_out.wb_reg_addr = s_id_out.addr_a) else
                     s_mem_out.val_f when
                     (s_mem_out.wb_reg_addr = s_id_out.addr_a) else
    s_ex_in.val_b <= s_ex_out.alu_result when
                     (s_ex_out.wb_reg_addr = s_id_out.addr_b) else
                     s_mem_out.val_f when
                     (s_mem_out.wb_reg_addr = s_id_out.addr_b) else

- Non-branch stall data hazards (memory data hazard)
    The EX `val_a/val_b` hazard detection mux should check `mem_in.mux_mem` for 
    a load (`MEM_LW`, etc) with a `wb_reg_addr` of the current register. If 
    this were to happen, the PC would need to be frozen for that cycle and 
    `ex_in.mux_mem` and `ex_in.wb_reg_addr` would need to be zero'd (to cancel 
    the EX stage --- it will effectively be redone since the PC didn't move).

    If we detect usage of a register on a load

    stall_detection: process (s_ex_out) is
    begin
        case s_ex_out.mux_mem is
            -- We need to stall if a load of our registers hasn't yet executed
            when MEM_LW | MEM_LH | MEM_LB | MEM_LHW | MEM_LBU =>
                if s_ex_out.wb_reg_addr /= R_0 then
                    if (s_id_out.addr_a = s_ex_out.wb_reg_addr or
                        s_id_out.addr_b = s_ex_out.wb_reg_addr) then
                        s_if_in.disable_pc_incr = '1';
                        s_ex_in.nop = true;
                    end if;
                end if;
            when others =>
                s_if_in.disable_pc_incr = '0';
                s_ex_in.nop = false;
        end case;
    end process;

For branch hazard detection, I may have to add some branch ID capability to the 
IF stage so that branch hazards can be detected.

## How are branches handled?

In the single-cycle implementation, branch tests are performed in the ALU. For 
this pipelined implementation, that would we'd have to wait for two cycles 
after fetching (ID, EX) to know if we should branch (during which two more 
instructions will get started in the pipeline). However if we perform branch 
detection in the ID stage (either by putting another ALU in the ID stage, or, 
as MIPS does, adding logic for simple tests like equality and restricting the 
sophistication of branching criteria), then we only execute one more cycle 
before branches are detected. The instruction after a branch thus always 
executes. As this is preferable to always stalling after branches, it is 
specified as part of the architecture under the name "delay slot".

Moving branch resolution to the ID stage does complicate data hazards, because 
now data is sometimes needed even earlier in the pipeline. In two cases, 
pipeline stalls are unavoidable.

## When to stall

New data is only produced in the execute and mem stages.

- 1 stall: If an R-type instruction uses data from a preceding load

    `lw $t0,0x($t1)`        # IF  ID  EX  ME  WB
                            #               <-Data $t0 available
    `add $t2,$t0,$t1`       # IF  ID  EX  ME  WB
                            #         <-Data $t0 needed

- 1 stall: If a branch uses data from a preceding ALU operation

    `add $t0,$t1,$t2`       # IF  ID  EX  ME  WB
                            #           <-Data $t0 available
    `beq $t0,$t3,label1`    # IF  ID  EX  ME  WB
                            #       <-Data $t0 needed

- 2 stalls: If a branch uses data from a preceding load

    `lw $t0,0x($t1)`        # IF  ID  EX  ME  WB
                            #               <-Data $t0 available
    `beq $t0,$t2,label1`    # IF  ID  EX  ME  WB
                            #       <-Data $t0 needed

## How are stalls implemented?

We must simulate a fetched nop (by mirroring nop control signals) without 
changing the PC.

## What is the behavior at the interfaces?

### IF

The purpose of this stage is to:
- Present the appropriate instruction word at its output on each clock cycle.

The IF unit holds an internal PC (initialized to 0) and an internal instruction 
memory. On each clock cycle, this internal PC is incremented by 4. There is an 
optional delta to also add to this internal PC, representing the branch amount 
from the ID stage. The PC increment can also be disabled.

### ID

The purpose of this stage is to:
- Receive a PC and instruction
- Generate pipeline registers
- Detect branches and present branch PC

The ID stage owns the register file (thus actually executes both the ID and WB 
stages).

### Testing

It will be necessary to set the register file state for testing. It'd thus be 
nice to be able to write assembly statements. I should thus probably test the 
IF and ID stages together.

## EX

The purpose of this stage is to:
- Compute the ALU operation on val_a and val_b

It may be possible to just replace this stage with the ALU itself. I'm not sure 
what I'd be adding, when the registers could just be carried forward by the 
external CPU wiring. ...but are these registers necessary t mple: doping 
analysis ( calculate junction length if you know doping concentration and other 
parameters for P), dry oxide growth analysis ( for gate oxide 100nm of oxide 
was grown, justify the time provided in the process sheet using temperature) , 
exposure and develop analysis, wet  etch rate analysis.

save state from one stage to the next?

This module mostly just saves state from one stage to the next.

## MEM

The purpose of this stage is to:
- Access memory

For a read:
    - Use alu result for address
    - Set output to memory output

For a write:
    - Use alu result for address
    - Set output to 0 (doesn't matter)
    - Set wb_reg to r0

For no memory access:
    - Set output to data
    - Make sure wb_reg is passed through

Note: If mem_in.enable_memw and mem_in.enable_memr were ever both asserted, the 
WB stage would be a nop and the value in reg_to_mem would be written to memory 
at address alu_result. This should never occur

## CPU

This must include the "hazard detection unit" and the "forwarding unit". All 
hazard resolution goes through this CPU entity. The individual pipeline stages 
know nothing about stalls/etc --- this is handled by the CPU . From the 
perspective of the CPU, it's building a processor out of pipeline building 
blocks. Think of this as an alternative to the usual way of building a 
processor, where we'd typically have the ALU, instruction memory (etc) building 
blocks. All hazard resolution thus has to be done through this entity, just 
like it would for an ALU.

The pipeline components are built in such a way that they are ignorant to the 
rest of the system. They don't know they're building a processor.

# Report

## Discussion

Earlier in the semester, I wrote a single-cycle MIPS implementation modeled 
after Figure 4.16 in the text (relatively simple compared to our pipelined 
version in Figure 4.65). Data memory was monitored in a wave viewer and 
instruction memory was populated from the Microchip XC-32 assembler output run 
through the `objdump` disassembler included with Microchip's compiler. A python 
script was written to parse through the disassembly and write VHDL to populate 
each byte of instruction memory with opcodes in the appropriate format. A 
fragment of the output of this python script for a fibonacci program that was 
written is shown below.

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

However the later-supplied instruction memory for this project, which reads a 
file at runtime to obtain its initial contents, is a simpler approach, as it 
doesn't require modification to the data memory's VHDL source.
