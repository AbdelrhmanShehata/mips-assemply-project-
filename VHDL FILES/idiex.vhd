library ieee;
use ieee.std_logic_1164.all;

entity id_ex_reg is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        flush         : in  std_logic;
        id_pc4        : in  std_logic_vector(31 downto 0);
        id_rd1        : in  std_logic_vector(31 downto 0);
        id_rd2        : in  std_logic_vector(31 downto 0);
        id_imm32      : in  std_logic_vector(31 downto 0);
        id_jump_index : in  std_logic_vector(25 downto 0);
        id_rs         : in  std_logic_vector(4 downto 0);
        id_rt         : in  std_logic_vector(4 downto 0);
        id_rd         : in  std_logic_vector(4 downto 0);
        id_funct      : in  std_logic_vector(5 downto 0);
        id_reg_dst    : in  std_logic;
        id_alu_src    : in  std_logic;
        id_mem_to_reg : in  std_logic;
        id_reg_write  : in  std_logic;
        id_mem_read   : in  std_logic;
        id_mem_write  : in  std_logic;
        id_branch     : in  std_logic;
        id_bne        : in  std_logic;
        id_jump_j     : in  std_logic;
        id_jal        : in  std_logic;
        id_jump_reg   : in  std_logic;
        id_lui        : in  std_logic;
        id_alu_op     : in  std_logic_vector(2 downto 0);
        ex_pc4        : out std_logic_vector(31 downto 0);
        ex_rd1        : out std_logic_vector(31 downto 0);
        ex_rd2        : out std_logic_vector(31 downto 0);
        ex_imm32      : out std_logic_vector(31 downto 0);
        ex_jump_index : out std_logic_vector(25 downto 0);
        ex_rs         : out std_logic_vector(4 downto 0);
        ex_rt         : out std_logic_vector(4 downto 0);
        ex_rd         : out std_logic_vector(4 downto 0);
        ex_funct      : out std_logic_vector(5 downto 0);
        ex_reg_dst    : out std_logic;
        ex_alu_src    : out std_logic;
        ex_mem_to_reg : out std_logic;
        ex_reg_write  : out std_logic;
        ex_mem_read   : out std_logic;
        ex_mem_write  : out std_logic;
        ex_branch     : out std_logic;
        ex_bne        : out std_logic;
        ex_jump_j     : out std_logic;
        ex_jal        : out std_logic;
        ex_jump_reg   : out std_logic;
        ex_lui        : out std_logic;
        ex_alu_op     : out std_logic_vector(2 downto 0)
    );
end entity id_ex_reg;

architecture rtl of id_ex_reg is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or flush = '1' then
                ex_reg_dst    <= '0';
                ex_alu_src    <= '0';
                ex_mem_to_reg <= '0';
                ex_reg_write  <= '0';
                ex_mem_read   <= '0';
                ex_mem_write  <= '0';
                ex_branch     <= '0';
                ex_bne        <= '0';
                ex_jump_j     <= '0';
                ex_jal        <= '0';
                ex_jump_reg   <= '0';
                ex_lui        <= '0';
                ex_alu_op     <= "000";
                ex_pc4        <= (others => '0');
                ex_rd1        <= (others => '0');
                ex_rd2        <= (others => '0');
                ex_imm32      <= (others => '0');
                ex_jump_index <= (others => '0');
                ex_rs         <= (others => '0');
                ex_rt         <= (others => '0');
                ex_rd         <= (others => '0');
                ex_funct      <= (others => '0');
            else
                ex_pc4        <= id_pc4;
                ex_rd1        <= id_rd1;
                ex_rd2        <= id_rd2;
                ex_imm32      <= id_imm32;
                ex_jump_index <= id_jump_index;
                ex_rs         <= id_rs;
                ex_rt         <= id_rt;
                ex_rd         <= id_rd;
                ex_funct      <= id_funct;
                ex_reg_dst    <= id_reg_dst;
                ex_alu_src    <= id_alu_src;
                ex_mem_to_reg <= id_mem_to_reg;
                ex_reg_write  <= id_reg_write;
                ex_mem_read   <= id_mem_read;
                ex_mem_write  <= id_mem_write;
                ex_branch     <= id_branch;
                ex_bne        <= id_bne;
                ex_jump_j     <= id_jump_j;
                ex_jal        <= id_jal;
                ex_jump_reg   <= id_jump_reg;
                ex_lui        <= id_lui;
                ex_alu_op     <= id_alu_op;
            end if;
        end if;
    end process;
end architecture rtl;
