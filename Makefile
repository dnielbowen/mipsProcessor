BINDIR = ~/test/mips/bin
AS = $(BINDIR)/as-mips32
OBJDUMP = $(BINDIR)/objdump

VHD_OBJ = components.o \
	  data_mem.o \
	  instr_mem.o \
	  alu.o \
	  reg.o \
	  if.o \
	  id.o \
	  ex.o \
	  mem.o \
	  atb_cpu.o

ASM = data/load_data.s

TB = tb_mips_cpu
# TB = tb_mips_dmem
# TB = tb_mips_id
# TB = tb_mips_mem
# TB = tb_mips_reg
IMPL = impl1
IEEE = synopsys
SIMDUR = 500ns

all: $(VHD_OBJ)
	ghdl -e --ieee=$(IEEE) $(TB) $(IMPL)
	ctags -R

%.o: %.vhd
	ghdl -a --ieee=$(IEEE) $<

ex:
	./$(TB)-$(IMPL) \
	    --wave=$(TB)-$(IMPL).ghw \
	    --stop-time=$(SIMDUR) \
	    --ieee-asserts=disable-at-0

clean:
	rm -f *.cf tb_* *.ghw *.vcd *.o tags

PROGOBJ = test_prog.o
prog:
	$(AS) -mips32 -O0 $(ASM) -o $(PROGOBJ)
	$(OBJDUMP) -d $(PROGOBJ) -z -M no-aliases | \
	    grep -P '[\da-f]+:' | \
	    python convert_opcodes.py > $(ASM).txt
