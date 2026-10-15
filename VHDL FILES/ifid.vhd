-- ============================================================
-- Module: IF/ID Pipeline Register
-- Purpose: Latches the outputs of the Instruction Fetch stage
--          (PC+4 and instruction word) between clock cycles.
--          On stall, retains current values (freeze).
--          On flush (branch taken), clears to NOP (all zeros).
-- Inputs:
--   clk, reset : clock and synchronous reset
--   stall      : hold register contents (hazard stall)
--   flush      : insert NOP bubble (branch flush)
--   if_pc4     : PC+4 from fetch stage
--   if_instr   : instruction word from fetch stage
-- Outputs:
--   id_pc4     : PC+4 passed to decode stage
--   id_instr   : instruction passed to decode stage
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity if_id_reg is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        stall    : in  std_logic;
        flush    : in  std_logic;
        if_pc4   : in  std_logic_vector(31 downto 0);
        if_instr : in  std_logic_vector(31 downto 0);
        id_pc4   : out std_logic_vector(31 downto 0);
        id_instr : out std_logic_vector(31 downto 0)
    );
end entity if_id_reg;

architecture rtl of if_id_reg is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or flush = '1' then
                id_pc4   <= (others => '0');
                id_instr <= (others => '0');   -- NOP = all zeros
            elsif stall = '0' then
                id_pc4   <= if_pc4;
                id_instr <= if_instr;
            -- else stall='1': hold values (implicit, no assignment)
            end if;
        end if;
    end process;
end architecture rtl;
