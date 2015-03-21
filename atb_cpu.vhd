library ieee;
use ieee.std_logic_1164.all;
use work.components.all;

-- Single Cycle
entity TB_CPU_SC is end;

architecture impl1 of TB_CPU_SC is
begin
    -- uut: FPM32 port map (a1, b1, f1); -- , m_f1, e_f1);

    -- sigs: process is
    -- begin
    --     ---------------------- Basic functionality tests
    --     a1 <= x"40000000";       -- 2.0
    --     b1 <= x"40400000";       -- 3.0
    --     wait for 100 ns;
    --     assert f1 = x"40c00000"; -- 6.0 = 2.0 * 3.0
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     a1 <= x"44fa0000";       -- 2000.0
    --     b1 <= x"3d800000";       -- 0.0625
    --     wait for 100 ns;
    --     assert f1 = x"42fa0000"; -- 125.0 = 2000 * 0.0625
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     ---------------------- Signedness tests
    --     a1 <= x"c4fa0000";       -- -2000.0
    --     b1 <= x"3d800000";       -- 0.0625
    --     wait for 100 ns;
    --     assert f1 = x"c2fa0000"; -- -125.0 = -2000 * 0.0625
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     a1 <= x"c4fa0000";       -- -2000.0
    --     b1 <= x"bd800000";       -- -0.0625
    --     wait for 100 ns;
    --     assert f1 = x"42fa0000"; -- 125.0 = -2000 * -0.0625
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     ---------------------- Max/min tests
    --     a1 <= x"41800000";       -- 16.0
    --     b1 <= x"41800000";       -- 16.0
    --     wait for 100 ns;
    --     assert f1 = x"43800000"; -- 32.0
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     a1 <= x"3fffffff";       -- 1.9999999
    --     b1 <= x"3fffffff";       -- 1.9999999
    --     wait for 100 ns;
    --     assert f1 = x"407ffffe"; -- 3.999999
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     ---------------------- Overflow/inf values
    --     a1 <= x"7f000000";       -- 1.7e38
    --     b1 <= x"7f000000";       -- 1.7e38
    --     wait for 100 ns;
    --     assert f1 = x"7f800000"; -- +inF
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     a1 <= x"7f000000";       -- 1.7e38
    --     b1 <= x"ff000000";       -- 1.7e38
    --     wait for 100 ns;
    --     assert f1 = x"ff800000"; -- -inf
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     a1 <= x"00800000";       -- 1.17e-38
    --     b1 <= x"00800000";       -- 1.17e-38
    --     wait for 100 ns;
    --     assert f1 = x"00000000"; -- NaN
    --     printFPVals(a1, b1, m_f1, e_f1, f1);

    --     wait;
    -- end process;
end architecture;
