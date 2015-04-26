BINDIR = ~/test/mips/bin
AS = $(BINDIR)/as-mips32
OBJDUMP = $(BINDIR)/objdump

VHD_OBJ = components.o \
	  mem.o

TB = tb_cpu
IMPL = impl1
IEEE = synopsys
SIMDUR = 200us

all: $(VHD_OBJ)
	ghdl -e --ieee=$(IEEE) $(TB) $(IMPL)

%.o: %.vhd
	ghdl -a --ieee=$(IEEE) $<

ex:
	./$(TB)-$(IMPL) --wave=$(TB)-$(IMPL).ghw --stop-time=$(SIMDUR)

clean:
	rm -f *.cf tb_* *.ghw *.vcd *.o
