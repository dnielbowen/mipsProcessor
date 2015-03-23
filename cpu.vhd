library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

-- Control logic
-- Modeled after Fig 4.17 in Patterson and Hennessy Software/Hardware 4e
entity CPU_SINGLECYCLE is
    port (
        CLK:  in  std_logic;

        -- Debug ports
        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft,
            dPC, dIR, dBrPC, dIncrPC, dMemData, dRegData
            : out std_logic_vector(31 downto 0);

        dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst: out std_logic;
        dALUControl: out std_logic_vector(3 downto 0);
        dRegWSrc, dALUSrc: out std_logic_vector(1 downto 0)
    );
end entity;

architecture impl1 of CPU_SINGLECYCLE is
    -- Control signals (uppercase)
    signal RegWrite, MemWrite, MemRead, Branch, Zero, RegDst : std_logic;
    signal ALUControl : std_logic_vector(3 downto 0);
    signal ALUSrc, RegWSrc : std_logic_vector (1 downto 0);

    constant CFour : std_logic_vector(31 downto 0) := x"00000004";

    -- Datapath signals (lowercase)
    signal regA, aluB, regB, aluF : std_logic_vector(31 downto 0);
    signal sExt, sExtShft : std_logic_vector(31 downto 0);
    signal regW : std_logic_vector(4 downto 0);
    signal pc, ir : std_logic_vector(31 downto 0) := (others=>'0');
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
        MemWrite, RegWrite, ALUSrc, RegWSrc, ALUControl);

    muxALUInputB: aluB <= sExt when ALUSrc = "01"
        else regB when ALUSrc = "00" else x"0000" & ir(15 downto 0);
    muxInputDataToRegister: regData <= memData when RegWSrc = "01"
        else aluF when RegWSrc = "00" else ir(15 downto 0) & x"0000";
    muxSelectIOrJInstructionType: regW <=
        ir(15 downto 11) when RegDst = '1' else ir(20 downto 16);

    p1: process (CLK) is -- Apparently only the PC needs to be clocked?
    begin
        if rising_edge(CLK) then
            muxPC: case (Branch AND Zero) is
                when '1' => pc <= brPC;
                when others => pc <= incrPC;
            end case;
        end if;
    end process;

    -- Debug ports (control and datapath)
    dRegWrite <= RegWrite;
    dALUSrc <= ALUSrc;
    dMemWrite <= MemWrite;
    dMemRead <= MemRead;
    dRegWSrc <= RegWSrc;
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

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.components.all;

entity TB_CPU is end;

architecture impl1 of TB_CPU is
    -- Datapath debug signals
    signal dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft, dPC, dIR, dBrPC,
        dIncrPC, dMemData, dRegData : std_logic_vector(31 downto 0);
    -- Control debug signals
    signal dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst : std_logic;
    signal dALUControl : std_logic_vector(3 downto 0);
    signal dRegWSrc, dALUSrc : std_logic_vector(1 downto 0);

    signal sClk: std_logic := '0';
begin
    uut1: CPU_SINGLECYCLE port map (
        sClk,

        dRegA, dAluB, dRegB, dAluF, dSExt, dSExtShft, dPC, dIR, dBrPC,
        dIncrPC, dMemData, dRegData,

        dRegWrite, dMemWrite, dMemRead, dBranch, dZero, dRegDst, dALUControl, 
        dRegWSrc, dALUSrc
    );

    clk1: process is
    begin
        sClk <= not sClk;
        wait for T/2;
    end process;

--    signalTests1: process
--        variable buf: line;
--    begin
--        -- Stagger assertions wrt the clock to ensure edge-clocked behavior
--        wait for T/4;
--
--        --sA <= x"00000002";
--        --sB <= x"00000003";
--        --sControl <= "0010"; -- Addition
--        --wait for T/2;
--        --assert (sF /= x"00000005");
--        --wait for T/2;
--        --assert (sF = x"00000005");
--
--        wait;
--    end process;
end architecture;
