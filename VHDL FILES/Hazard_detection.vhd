library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection_unit is
    port (
        id_rs         : in  std_logic_vector(4 downto 0);
        id_rt         : in  std_logic_vector(4 downto 0);
        id_uses_rs    : in  std_logic;
        id_uses_rt    : in  std_logic;
        ex_mem_read   : in  std_logic;
        ex_rt         : in  std_logic_vector(4 downto 0);
        pc_stall      : out std_logic;
        if_id_stall   : out std_logic;
        ctrl_flush    : out std_logic
    );
end entity hazard_detection_unit;

architecture rtl of hazard_detection_unit is
begin
    process (id_rs, id_rt, id_uses_rs, id_uses_rt, ex_mem_read, ex_rt)
    begin
        pc_stall    <= '0';
        if_id_stall <= '0';
        ctrl_flush  <= '0';

        if ex_mem_read = '1' and ex_rt /= "00000" and
            ((id_uses_rs = '1' and ex_rt = id_rs) or (id_uses_rt = '1' and ex_rt = id_rt))
        then
            pc_stall    <= '1';
            if_id_stall <= '1';
            ctrl_flush  <= '1';
        end if;
    end process;
end architecture rtl;
