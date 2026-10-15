library ieee;
use ieee.std_logic_1164.all;

entity forwarding_unit is
    port (
        ex_rs          : in  std_logic_vector(4 downto 0);
        ex_rt          : in  std_logic_vector(4 downto 0);
        mem_reg_write  : in  std_logic;
        mem_write_reg  : in  std_logic_vector(4 downto 0);
        wb_reg_write   : in  std_logic;
        wb_write_reg   : in  std_logic_vector(4 downto 0);
        -- Mux selectors for ALU inputs
        forward_a      : out std_logic_vector(1 downto 0);
        forward_b      : out std_logic_vector(1 downto 0)
    );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
begin
    process(ex_rs, ex_rt, mem_reg_write, mem_write_reg, wb_reg_write, wb_write_reg)
    begin
        -- Default: No forwarding (use values from Register File)
        forward_a <= "00";
        forward_b <= "00";

        -- Forwarding from MEM stage to Operand A
        if (mem_reg_write = '1' and mem_write_reg /= "00000" and mem_write_reg = ex_rs) then
            forward_a <= "10";
        -- Forwarding from WB stage to Operand A
        elsif (wb_reg_write = '1' and wb_write_reg /= "00000" and wb_write_reg = ex_rs) then
            forward_a <= "01";
        end if;

        -- Forwarding from MEM stage to Operand B
        if (mem_reg_write = '1' and mem_write_reg /= "00000" and mem_write_reg = ex_rt) then
            forward_b <= "10";
        -- Forwarding from WB stage to Operand B
        elsif (wb_reg_write = '1' and wb_write_reg /= "00000" and wb_write_reg = ex_rt) then
            forward_b <= "01";
        end if;
    end process;
end architecture rtl;