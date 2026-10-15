library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_pipeline_tb is
end entity mips_pipeline_tb;

architecture sim of mips_pipeline_tb is
    -- Signals to connect to the processor
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    
    -- Clock period definition (10ns = 100MHz)
    constant clk_period : time := 10 ns;
    constant sim_end    : time := 10 us;

begin
    -- 1. Instance of the MIPS Pipeline Processor
    UUT: entity work.mips_pipeline
        port map (
            clk   => clk,
            reset => reset
        );

    -- 2. Clock Generation: ????? ????? ??????
    clk_process : process
    begin
        while now < sim_end loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- 3. Stimulus Process: ?????? ?? ??? Reset
    stim_proc: process
    begin		
        -- ????? ??? Reset ?? ??????? ?????? ??? Registers
        reset <= '1';
        wait for 25 ns;
        
        -- ????? ??? Reset ???? ????? ???????? ?? ????????
        reset <= '0';
        
        -- ??? ???????? ????? ???? ????? ????? ?? ??? Instructions
        wait for sim_end - 25 ns;
        
        assert false report "Simulation Finished" severity note;
        wait;
    end process;

end architecture sim;