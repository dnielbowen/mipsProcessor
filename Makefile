OBJ = alu.o \
      adder32.o \
      signExtend.o \
      registerFile.o \
      mem1k_RO.o \
      mem1k.o \
      cpu.o

TB = atb_alu

IMPL = impl1

all: $(OBJ)
	ghdl -e --ieee=mentor $(TB) $(IMPL)

%.o: %.vhd
	ghdl -a --ieee=mentor $<

ex:
	./$(TB)-$(IMPL) --vcd=$(TB)-$(IMPL).vcd

clean:
	rm -f *.cf tb_* *.vcd *.o
