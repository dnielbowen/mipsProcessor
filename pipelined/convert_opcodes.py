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
