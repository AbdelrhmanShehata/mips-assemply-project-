library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_mem is
    port (
        clk        : in  std_logic;
        mem_write  : in  std_logic;
        mem_read   : in  std_logic;
        addr       : in  std_logic_vector(31 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        read_data  : out std_logic_vector(31 downto 0)
    );
end entity data_mem;

architecture rtl of data_mem is
    type ram_type is array (0 to 63) of std_logic_vector(31 downto 0);
    signal ram : ram_type := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_write = '1' then
                ram(to_integer(unsigned(addr(7 downto 2)))) <= write_data;
            end if;
        end if;
    end process;
    
    read_data <= ram(to_integer(unsigned(addr(7 downto 2)))) when mem_read = '1' else (others => '0');
end architecture rtl;