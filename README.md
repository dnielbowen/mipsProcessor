# MIPS processor in VHDL

### 2020 overview for GitHub upload

This is a project from a computer design class I took in 2015. It implements a 
computer processor with a subset of the MIPS instruction set using VHDL, to the 
point that machine code generated by a C compiler can be executed (it takes 
some work to arrange the compiler's output into a simulated ROM, enabled by the 
included shell scripts). Some simulator screenshots are included in the 
subdirectories, though with no particularly interesting demos --- just some 
small sample Fibonacci test functions, etc. While it is a subset, it seems to 
implement all the instructions a compiler in normal operation generates. You 
couldn't, for example, run an operating system on this, as it would no doubt 
use more-exotic instructions.

The design follows a RISC computer development from the textbook [Computer 
Architecture: A Quantitative 
Approach](https://www.amazon.com/Computer-Architecture-Quantitative-John-Hennessy/dp/012383872X) 
by Hennessy and Patterson. Hennessy, before becoming president of Stanford, is 
the inventor of the MIPS architecture in the 1980s, which was later used in 
Silicon Graphics workstations, the Nintendo 64, PlayStation/PS2, Wifi routers, 
and many other applications. Patterson is the inventor of the Berkeley RISC 
architecture, the basis for the Sun SPARC, which continues to be used in 
servers, radiation-hardened processors in satellites, etc. So, it's an 
understatement to say the authors are well-qualified to write a good book about 
processor design.

Subdirectories are included for a single-cycle processor, where one clock cycle 
implements an entire instruction, and a five-stage pipelined version, where 
each instruction is broken into five smaller stages for faster execution --- as 
outlined in the textbook. If I recall, the authors cite modern Intel chips as 
using on the order of 20 to 30-stage pipelines. This implementation "cheats" a 
bit in the arithmetic-logic unit (among a number of other places, like not 
having to deal with sophisticated memory bus protocols, etc) by using built-in 
arithmetic operators from default VHDL libraries like `+`, `/`, etc --- though 
elsewhere in the semester(s) we did have to build such arithmetic units from 
scratch, including IEEE floating point multipliers and dividers. All testing 
and simulation was done using GHDL, an open source VHDL simulator.
