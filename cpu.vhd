library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

-- Control logic
-- Modeled after Fig 4.17 in Patterson and Hennessy Software/Hardware 4e
entity CPU_SINGLECYCLE is
    port (
        CLK:  in  std_logic;

        -- Debug ports
        dRegWrite, dALUSrc, dMemWrite, dMemRead, dMemToReg,
            dBranch, dZero, dRegDst : out std_logic;
        dALUControl : out std_logic_vector(3 downto 0);

        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft,
            dPC, dIR, dBrPC, dIncrPC, dMemData, dRegData
            : out std_logic_vector(31 downto 0)
    );
end entity;

architecture impl1 of CPU_SINGLECYCLE is
    -- Control signals (uppercase)
    signal RegWrite, ALUSrc, MemWrite, MemRead, MemToReg : std_logic;
    signal Branch, Zero, RegDst : std_logic;
    signal ALUControl : std_logic_vector(3 downto 0);

    constant CFour : std_logic_vector(31 downto 0) := x"00000004";

    -- Datapath signals (lowercase)
    signal regA, aluB, regB, aluF : std_logic_vector(31 downto 0);
    signal sExt, sExtShft : std_logic_vector(31 downto 0);
    signal regW : std_logic_vector(4 downto 0);
    signal pc, ir : std_logic_vector(31 downto 0); -- Special registers
    signal brPC, incrPC : std_logic_vector(31 downto 0);
    signal memData, regData : std_logic_vector(31 downto 0);
    -- Note: PC is 32-bits, but the memory/memaddr is only 10 bits (1024-word)
begin
    zeroDetect1: Zero <= '1' when (aluF = x"00000000") else '0';
    shiftMemAddrLeft: sExtShft <= sExt(29 downto 0) & "00";
    alu1: ALU port map (regA, aluB, CLK, ALUControl, aluF);
    memData1: MEM_1K port map (CLK, aluF(9 downto 0), MemWrite, regB, memData);
    memInstr1: MEM_RO_1K port map (CLK, pc(9 downto 0), ir);
    progCounter1: ADDER_32 port map (pc, CFour, incrPC);
    memAddrAdder1: ADDER_32 port map (incrPC, sExtShft, brPC);
    signExtend1: SIGNEXTEND_16_32 port map (ir(15 downto 0), sExt);
    registerFile1: REGISTER_ARRAY_32_32 port map (
        ADDR1 => ir(25 downto 21),
        ADDR2 => ir(20 downto 16),
        ADDRW => regW,
        REG1 => regA,
        REG2 => regB,
        DATA => regData,
        ENW => RegWrite,
        CLK => CLK
    );
    controlSignals1: CPU_IR_DECODER port map(
        ir, RegDst, Branch, MemRead,
        MemToReg, ALUSrc, MemWrite, RegWrite,
        ALUControl);

    p1: process (CLK) is
    begin
        if rising_edge(CLK) then
            muxALUInput1: case ALUSrc is
                when '1' => aluB <= sExt;
                when others => aluB <= regB;
            end case;

            muxPC: case (Branch AND Zero) is
                when '1' => pc <= brPC;
                when others => pc <= incrPC;
            end case;

            muxRegW1: case RegDst is
                when '1' => regW <= ir(15 downto 11);
                when others => regW <= ir(20 downto 16);
            end case;

            muxRegDataInput1: case MemToReg is
                when '1' => regData <= memData;
                when others => regData <= aluF;
            end case;
        end if;
    end process;

    -- Debug ports (control and datapath)
    dRegWrite <= RegWrite;
    dALUSrc <= ALUSrc;
    dMemWrite <= MemWrite;
    dMemRead <= MemRead;
    dMemToReg <= MemToReg;
    dBranch <= Branch;
    dZero <= Zero;
    dRegDst <= RegDst;
    dALUControl <= ALUControl;

    dRegA <= regA;
    dAluB <= aluB;
    dRegB <= regB;
    dAluF <= aluF;
    dSExt <= sExt;
    dSExtShft <= sExtShft;
    dPC <= pc;
    dIR <= ir;
    dBrPC <= brPC;
    dIncrPC <= incrPC;
    dMemData <= memData;
    dRegData <= regData;
end architecture;
