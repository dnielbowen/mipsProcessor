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
