library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.components.all;

entity MIPS_IF is
    generic (imem_filename : string := "data/instr_mem.txt");
    port (
        clk    : in  std_logic;
        p_if_in  : in  if_in;
        p_if_out : out if_out
    );
end entity;

architecture impl1 of MIPS_IF is
    signal s_pc : address := (others => '0');
    signal s_instruction : word := (others => '0');

    signal s_out : if_out := ((others => '0'), (others => '0'));
begin
    imem1: MIPS_IMEM
        generic map (imem_filename)
        port map(s_pc, s_instruction);

    pipeline_registers: process (clk) is
    begin
        if rising_edge(clk) then
            s_out.pc <= s_pc;
            s_out.instruction <= s_instruction;

            if p_if_in.disable_pc_incr then
                puts("Holding");
                --s_pc <= unsigned(s_pc);
            elsif p_if_in.enable_delta_pc then
                s_pc <= unsigned(s_pc) + 4 + signed(p_if_in.delta_pc);
            else
                s_pc <= unsigned(s_pc) + 4;
                print_word(x"FFFFFFFF", s_pc);
            end if;
        end if;
    end process;

    p_if_out <= s_out;
end architecture;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.components.all;

entity TB_MIPS_IF is
end entity;

architecture impl1 of TB_MIPS_IF is
    signal s_clk : std_logic := '0';

    signal s_if_in  : if_in := (false, (others => '0'), false);
    signal s_if_out : if_out := ((others => '0'), (others => '0'));
begin
    mips_if1 : MIPS_IF
        generic map ("data/data_hazards.s.txt")
        port map (s_clk, s_if_in, s_if_out);

    clock_process: process is
    begin
        s_clk <= not s_clk;
        wait for CLK_T/2;
    end process;

    -- Desired behavior:
    -- At the end of every clock cycle, a PC value of +4 is presented at the 
    -- output, unless I just say to provide PC
    pipeline_assertions: process
    begin
        wait for CLK_T/5;      -- Stagger clock with assertions
        
        assert s_if_out.pc = x"00000000";
        wait for CLK_T;
        assert s_if_out.pc = x"00000004";

        s_if_in.disable_pc_incr <= true;
        puts("Disabling pc incr");
        wait for CLK_T;
        assert s_if_out.pc = x"00000004";
        wait for CLK_T;
        print_word(s_if_out.pc, s_if_out.instruction);

        wait;
    end process;
end architecture;
