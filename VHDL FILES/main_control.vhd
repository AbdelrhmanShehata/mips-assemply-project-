library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
    port (
        opcode     : in  std_logic_vector(5 downto 0);
        funct      : in  std_logic_vector(5 downto 0);
        reg_dst    : out std_logic;
        alu_src    : out std_logic;
        mem_to_reg : out std_logic;
        reg_write  : out std_logic;
        mem_read   : out std_logic;
        mem_write  : out std_logic;
        branch     : out std_logic;
        bne        : out std_logic;
        jump_j     : out std_logic;
        jal        : out std_logic;
        jump_reg   : out std_logic;
        lui        : out std_logic;
        imm_zext   : out std_logic;
        uses_rs    : out std_logic;
        uses_rt    : out std_logic;
        alu_op     : out std_logic_vector(2 downto 0)
    );
end entity control_unit;

architecture rtl of control_unit is
begin
    process (opcode, funct)
    begin
        reg_dst    <= '0';
        alu_src    <= '0';
        mem_to_reg <= '0';
        reg_write  <= '0';
        mem_read   <= '0';
        mem_write  <= '0';
        branch     <= '0';
        bne        <= '0';
        jump_j     <= '0';
        jal        <= '0';
        jump_reg   <= '0';
        lui        <= '0';
        imm_zext   <= '0';
        uses_rs    <= '0';
        uses_rt    <= '0';
        alu_op     <= "000";

        case opcode is
            when "000000" =>
                if funct = "001000" then
                    reg_dst    <= '0';
                    mem_to_reg <= '0';
                    reg_write  <= '0';
                    mem_read   <= '0';
                    mem_write  <= '0';
                    jump_reg   <= '1';
                    uses_rs    <= '1';
                    alu_op     <= "000";
                else
                    reg_dst    <= '1';
                    alu_src    <= '0';
                    mem_to_reg <= '0';
                    reg_write  <= '1';
                    uses_rs    <= '1';
                    uses_rt    <= '1';
                    alu_op     <= "010";
                end if;

            when "001111" =>          -- lui rt, imm16  (rt <- imm << 16)
                reg_dst    <= '0';
                alu_src    <= '1';
                reg_write  <= '1';
                lui        <= '1';
                alu_op     <= "000";

            when "100011" =>          -- lw
                reg_dst    <= '0';
                alu_src    <= '1';
                mem_to_reg <= '1';
                reg_write  <= '1';
                mem_read   <= '1';
                uses_rs    <= '1';
                alu_op     <= "000";

            when "001000" =>          -- addi
                reg_dst    <= '0';
                alu_src    <= '1';
                reg_write  <= '1';
                uses_rs    <= '1';
                alu_op     <= "000";

            when "001010" =>          -- slti
                reg_dst    <= '0';
                alu_src    <= '1';
                reg_write  <= '1';
                uses_rs    <= '1';
                alu_op     <= "101";

            when "001100" =>          -- andi
                reg_dst    <= '0';
                alu_src    <= '1';
                reg_write  <= '1';
                uses_rs    <= '1';
                imm_zext   <= '1';
                alu_op     <= "011";

            when "001101" =>          -- ori
                reg_dst    <= '0';
                alu_src    <= '1';
                reg_write  <= '1';
                uses_rs    <= '1';
                imm_zext   <= '1';
                alu_op     <= "100";

            when "101011" =>          -- sw
                reg_dst    <= '0';
                alu_src    <= '1';
                mem_write  <= '1';
                uses_rs    <= '1';
                uses_rt    <= '1';
                alu_op     <= "000";

            when "000100" =>          -- beq
                alu_src    <= '0';
                branch     <= '1';
                bne        <= '0';
                uses_rs    <= '1';
                uses_rt    <= '1';
                alu_op     <= "001";

            when "000101" =>          -- bne
                alu_src    <= '0';
                branch     <= '1';
                bne        <= '1';
                uses_rs    <= '1';
                uses_rt    <= '1';
                alu_op     <= "001";

            when "000010" =>
                jump_j <= '1';

            when "000011" =>
                jump_j    <= '1';
                jal       <= '1';
                reg_write <= '1';

            when others =>
                null;
        end case;
    end process;
end architecture rtl;
