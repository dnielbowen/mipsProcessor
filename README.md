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

- 1 stall: If an R-type instruction uses data from a preceeding load

    `lw $t0,0x($t1)`        # IF  ID  EX  ME  WB
                            #               <-Data $t0 available
    `add $t2,$t0,$t1`       # IF  ID  EX  ME  WB
                            #           <-Data $t0 needed

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

type if_in is record
    enable_delta_pc : std_logic;
    delta_pc        : word;
        -- Adds delta_pc to incremented PC (for branches)

    disable_pc_incr : std_logic;
        -- Prevents PC from being incremented (for stalls)
end record;

type if_out is record
    pc          : address; -- The PC associated with `instruction` (for debug)
    instruction : word;
end record;

The IF unit holds an internal PC (initialized to 0) and an internal instruction 
memory. On each clock cycle, this internal PC is incremented by 4. There is an 
optional delta to also add to this internal PC, representing the branch amount 
from the ID stage. The PC increment can also be disabled.

### ID

The purpose of this stage is to:
- Present ALU inputs (from registers) on its output
- Detect branches and present branch PC
- Generate various control signals

type id_in is record
    instruction : word;

    enable_ext_br_data : std_logic;
    ext_br_data : word;
        -- Forwarded data for branching. It's the responsibility of the CPU 
        -- entity to determine data/branch hazards and present the appropriate 
        -- data here.

    wb_data     : word;
    wb_reg_addr : reg_address;
        -- Represents the address to write wb_data to. If zero (register r0), 
        -- wb_data is ignored.
end record;

type id_out is record
    val_a       : word;
    val_b       : word;
    alu_op      : op_func;

    enable_delta_pc : std_logic;
    delta_pc    : word;

    wb_reg_addr : reg_address;
        -- Dictates which register the result is written to during WB. If this 
        -- is register zero, nothing is written.
    enable_memw : std_logic;
        -- When asserted, the result from the ALU represents a memory address 
        -- and should be written to memory. This represents a store.
    enable_memr : std_logic;
        -- When asserted, the result from the ALU represents a memory address, 
        -- whose contents should then be written to register wb_reg_addr. This 
        -- represents a load.
end record;

The ID stage owns the register file (thus actually executes both the ID and WB 
stages).

## EX

The purpose of this stage is to:
- Compute the ALU operation on val_a and val_b

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

type mem_in is record
    val_f : word;

    wb_reg_addr : reg_address;
    enable_memw : std_logic;
    enable_memr : std_logic;
end record;

type mem_out is record
    val_f       : word;
    wb_reg_addr : reg_address;
end record;


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
