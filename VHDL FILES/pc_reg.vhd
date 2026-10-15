library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc_reg is
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        stall   : in std_logic;
        pc_next : in std_logic_vector(31 downto 0);
        pc_out  : out std_logic_vector(31 downto 0)
    );
end entity pc_reg;

architecture rtl of pc_reg is
begin
    process (clk) is
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc_out <= (others => '0');
            elsif stall = '0' then
                pc_out <= pc_next;
            end if;
        end if;
    end process;
end architecture rtl;
