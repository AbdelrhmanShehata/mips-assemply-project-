library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity alu is
    port (
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        alu_ctrl : in  std_logic_vector(2  downto 0);
        result   : out std_logic_vector(31 downto 0);
        zero     : out std_logic
    );
end entity alu;
 
architecture rtl of alu is
    signal alu_result : std_logic_vector(31 downto 0);
begin
    process(a, b, alu_ctrl)
        variable va, vb : signed(31 downto 0);
    begin
        va := signed(a);
        vb := signed(b);
        case alu_ctrl is
            when "000"  => alu_result <= a and b;                     -- AND
            when "001"  => alu_result <= a or  b;                     -- OR
            when "010"  => alu_result <= std_logic_vector(va + vb);   -- ADD
            when "011"  => alu_result <= a xor b;                     -- XOR
            when "100"  => alu_result <= not (a or b);                 -- NOR
            when "110"  => alu_result <= std_logic_vector(va - vb);   -- SUB
            when "111"  =>                                            -- SLT
                if va < vb then
                    alu_result <= x"00000001";
                else
                    alu_result <= x"00000000";
                end if;
            when others => alu_result <= (others => '0');
        end case;
    end process;
 
    result <= alu_result;
    zero   <= '1' when alu_result = x"00000000" else '0';
end architecture rtl;
