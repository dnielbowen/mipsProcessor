BINDIR = ~/test/mips/bin
AS = $(BINDIR)/as-mips32
OBJDUMP = $(BINDIR)/objdump

VHD_OBJ = components.o \
          alu.o \
          adder32.o \
          signExtend.o \
          registerFile.o \
          mem1k_RO.o \
          mem1k.o \
          cpu.o \
          control.o \
          atb_cpu.o

ASM = program.s
PROGOBJ = program.o

# TB = tb_mem_ro_1k
TB = tb_cpu
IMPL = impl1
SIMDUR = 1ms

all: $(VHD_OBJ)
	ghdl -e --ieee=mentor $(TB) $(IMPL)

%.o: %.vhd
	ghdl -a --ieee=mentor $<

ex:
	./$(TB)-$(IMPL) --wave=$(TB)-$(IMPL).ghw --stop-time=$(SIMDUR)

# Current instructions:
# Run `make prog` and copy-paste the contents into mem1k_RO.vhd (the program 
# memory). You'll have to change the indices to 4-byte offsets (eg 0 4 8, etc)
prog:
	$(AS) -mips32 $(ASM) -o $(PROGOBJ)
	$(OBJDUMP) -d program.o | \
	    grep -P '[\da-f]+:' | \
	    nl -v0 | \
	    perl -pe \
	    's/\s*(\d+)\s+\w+:\s+([\da-f]+)\s+(.*)/mem(\1) <= x"\2"; -- \3/'

clean:
	rm -f *.cf tb_* *.ghw *.vcd *.o
