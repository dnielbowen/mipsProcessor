library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;

package COMPONENTS is
    constant g_delay: TIME := 1 ns;
    constant T: time := 200 ns; -- Testbench period

    component MEM_RO_1K is
        port (
            CLK:  in  std_logic;
            ADDR: in  std_logic_vector(9 downto 0);
            DATA: out std_logic_vector(31 downto 0)
        );
    end component;

    component MEM_1K is
        port (
            CLK:   in  std_logic;
            ADDR:  in  std_logic_vector(9 downto 0);
            WR:    in  std_logic;                     -- Enable write
            DATAW: in  std_logic_vector(31 downto 0); -- Data write
            DATAR: out std_logic_vector(31 downto 0)  -- Data read
        );
    end component;

    component ADDER_32 is
        port (
            A,B: in  std_logic_vector(31 downto 0);
            F:   out std_logic_vector(31 downto 0)
        );
    end component;

    component ALU is
        port (
            A,B:     in  std_logic_vector(31 downto 0);
            CLK:     in  std_logic;
            CONTROL: in  std_logic_vector(3 downto 0);
            F:       out std_logic_vector(31 downto 0)
        );
    end component;

    component REGISTER_ARRAY_32_32 is
        port (
            ADDR1,ADDR2,ADDRW: in  std_logic_vector(4 downto 0);
            REG1,REG2:         out std_logic_vector(31 downto 0);
            DATA:              in  std_logic_vector(31 downto 0);
            ENW:               in  std_logic; -- Register Write enable
            CLK:               in  std_logic
        );
    end component;

    component SIGNEXTEND_16_32 is
        port (
            X: in  std_logic_vector(15 downto 0);
            F: out std_logic_vector(31 downto 0)
        );
    end component;

    component CPU_IR_DECODER is
        port (
            IR:  in  std_logic_vector(31 downto 0);

            RegDst, Branch, MemRead, MemToReg: out std_logic;
            ALUSrc, MemWrite, RegWrite : out std_logic;
            ALUControl: out std_logic_vector (3 downto 0)
        );
    end component;

    component CPU_SINGLECYCLE is
        port (
            CLK:  in  std_logic;
            dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft,
                dPC, dIR, dBrPC, dIncrPC, dMemData, dRegData
                : out std_logic_vector(31 downto 0);
            dRegWrite, dALUSrc, dMemWrite, dMemRead, dMemToReg,
                dBranch, dZero, dRegDst : out std_logic;
            dALUControl : out std_logic_vector(3 downto 0)
        );
    end component;
end package;
