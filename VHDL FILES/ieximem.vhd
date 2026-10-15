library ieee;
use ieee.std_logic_1164.all;

entity ex_mem_reg is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        -- Data inputs from EX stage
        ex_alu_result : in  std_logic_vector(31 downto 0);
        ex_rd2        : in  std_logic_vector(31 downto 0);
        ex_write_reg  : in  std_logic_vector(4 downto 0);
        -- Control inputs
        ex_mem_to_reg : in  std_logic;
        ex_reg_write  : in  std_logic;
        ex_mem_read   : in  std_logic;
        ex_mem_write  : in  std_logic;
        -- Data outputs to MEM stage
        mem_alu_result : out std_logic_vector(31 downto 0);
        mem_rd2        : out std_logic_vector(31 downto 0);
        mem_write_reg  : out std_logic_vector(4 downto 0);
        -- Control outputs
        mem_mem_to_reg : out std_logic;
        mem_reg_write  : out std_logic;
        mem_mem_read   : out std_logic;
        mem_mem_write  : out std_logic
    );
end entity ex_mem_reg;

architecture rtl of ex_mem_reg is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mem_alu_result <= (others => '0');
                mem_rd2        <= (others => '0');
                mem_write_reg  <= (others => '0');
                mem_mem_to_reg <= '0';
                mem_reg_write  <= '0';
                mem_mem_read   <= '0';
                mem_mem_write  <= '0';
            else
                mem_alu_result <= ex_alu_result;
                mem_rd2        <= ex_rd2;
                mem_write_reg  <= ex_write_reg;
                mem_mem_to_reg <= ex_mem_to_reg;
                mem_reg_write  <= ex_reg_write;
                mem_mem_read   <= ex_mem_read;
                mem_mem_write  <= ex_mem_write;
            end if;
        end if;
    end process;
end architecture rtl;
