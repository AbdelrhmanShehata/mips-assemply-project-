library ieee;
use ieee.std_logic_1164.all;

entity alu_ctrl is
    port (
        alu_op   : in  std_logic_vector(2 downto 0);
        funct    : in  std_logic_vector(5 downto 0);
        alu_ctrl : out std_logic_vector(2 downto 0)
    );
end entity alu_ctrl;

architecture rtl of alu_ctrl is
begin
    process (alu_op, funct)
    begin
        case alu_op is
            when "000" =>
                alu_ctrl <= "010";           -- ADD (incl. lui slot / address)

            when "001" =>
                alu_ctrl <= "110";           -- SUB (branches)

            when "010" =>                    -- R-type from funct
                case funct is
                    when "100000" => alu_ctrl <= "010";   -- add
                    when "100010" => alu_ctrl <= "110";   -- sub
                    when "100100" => alu_ctrl <= "000";   -- and
                    when "100101" => alu_ctrl <= "001";   -- or
                    when "100110" => alu_ctrl <= "011";   -- xor
                    when "100111" => alu_ctrl <= "100";   -- nor
                    when "101010" => alu_ctrl <= "111";   -- slt
                    when others   => alu_ctrl <= "010";
                end case;

            when "011" =>
                alu_ctrl <= "000";           -- ANDI

            when "100" =>
                alu_ctrl <= "001";           -- ORI

            when "101" =>
                alu_ctrl <= "111";           -- SLTI (signed)

            when others =>
                alu_ctrl <= "010";
        end case;
    end process;
end architecture rtl;
