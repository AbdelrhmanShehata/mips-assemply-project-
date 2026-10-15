library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_reg is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        -- Inputs from MEM stage
        mem_alu_result : in  std_logic_vector(31 downto 0);
        mem_mem_data   : in  std_logic_vector(31 downto 0);
        mem_write_reg  : in  std_logic_vector(4 downto 0);
        -- Control inputs
        mem_mem_to_reg : in  std_logic;
        mem_reg_write  : in  std_logic;
        -- Outputs to WB stage
        wb_alu_result  : out std_logic_vector(31 downto 0);
        wb_mem_data    : out std_logic_vector(31 downto 0);
        wb_write_reg   : out std_logic_vector(4 downto 0);
        -- Control outputs
        wb_mem_to_reg  : out std_logic;
        wb_reg_write   : out std_logic
    );
end entity mem_wb_reg;

architecture rtl of mem_wb_reg is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                wb_alu_result  <= (others => '0');
                wb_mem_data    <= (others => '0');
                wb_write_reg   <= (others => '0');
                wb_mem_to_reg  <= '0';
                wb_reg_write   <= '0';
            else
                wb_alu_result  <= mem_alu_result;
                wb_mem_data    <= mem_mem_data;
                wb_write_reg   <= mem_write_reg;
                wb_mem_to_reg  <= mem_mem_to_reg;
                wb_reg_write   <= mem_reg_write;
            end if;
        end if;
    end process;
end architecture rtl;