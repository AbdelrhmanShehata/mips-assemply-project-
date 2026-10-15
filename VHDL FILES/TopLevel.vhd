library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_pipeline is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity mips_pipeline;

architecture structural of mips_pipeline is
    signal if_pc, if_pc4, if_instr : std_logic_vector(31 downto 0);
    signal id_pc4, id_instr, id_rd1, id_rd2, id_imm32 : std_logic_vector(31 downto 0);
    signal id_reg_dst, id_alu_src, id_mem_to_reg, id_reg_write, id_mem_read, id_mem_write, id_branch : std_logic;
    signal id_bne, id_jump_j, id_jal, id_jump_reg : std_logic;
    signal id_lui, id_imm_zext : std_logic;
    signal id_uses_rs, id_uses_rt : std_logic;
    signal id_alu_op : std_logic_vector(2 downto 0);
    signal ex_pc4, ex_rd1, ex_rd2, ex_imm32, ex_alu_res : std_logic_vector(31 downto 0);
    signal ex_jump_index : std_logic_vector(25 downto 0);
    signal ex_rs, ex_rt, ex_rd, ex_write_reg : std_logic_vector(4 downto 0);
    signal ex_funct : std_logic_vector(5 downto 0);
    signal ex_alu_src, ex_reg_dst, ex_reg_write, ex_mem_to_reg, ex_mem_read, ex_mem_write, ex_branch : std_logic;
    signal ex_bne, ex_jump_j, ex_jal, ex_jump_reg, ex_lui : std_logic;
    signal ex_alu_op : std_logic_vector(2 downto 0);
    signal alu_in_a, alu_in_b, forward_b_out : std_logic_vector(31 downto 0);
    signal mem_alu_res, mem_rd2, mem_data : std_logic_vector(31 downto 0);
    signal mem_write_reg : std_logic_vector(4 downto 0);
    signal mem_reg_write, mem_mem_to_reg, mem_mem_read, mem_mem_write : std_logic;
    signal wb_alu_res, wb_data, wb_final_res : std_logic_vector(31 downto 0);
    signal wb_write_reg : std_logic_vector(4 downto 0);
    signal wb_reg_write, wb_mem_to_reg : std_logic;
    signal forward_a, forward_b : std_logic_vector(1 downto 0);
    signal pc_stall, if_id_stall, ctrl_flush : std_logic;
    signal alu_ctrl_sig : std_logic_vector(2 downto 0);
    signal ex_alu_zero : std_logic;
    signal branch_cond_taken : std_logic;
    signal ctrl_flow_taken : std_logic;
    signal branch_target : std_logic_vector(31 downto 0);
    signal jump_target : std_logic_vector(31 downto 0);
    signal pc_next : std_logic_vector(31 downto 0);
    signal mem_fwd_val : std_logic_vector(31 downto 0);
    signal if_id_flush : std_logic;
    signal id_ex_flush : std_logic;
    signal ex_exmem_result : std_logic_vector(31 downto 0);
    signal jr_pc           : std_logic_vector(31 downto 0);

begin
    if_pc4        <= std_logic_vector(unsigned(if_pc) + 4);
    branch_target <= std_logic_vector(unsigned(ex_pc4) + unsigned(shift_left(signed(ex_imm32), 2)));
    jump_target   <= ex_pc4(31 downto 28) & ex_jump_index & "00";

    branch_cond_taken <= (ex_branch and (not ex_bne) and ex_alu_zero)
        or (ex_branch and ex_bne and (not ex_alu_zero));

    ctrl_flow_taken <= branch_cond_taken or ex_jump_j or ex_jump_reg;

    jr_pc <= alu_in_a(31 downto 2) & "00";

    pc_next <= jr_pc when ex_jump_reg = '1' else
        jump_target when ex_jump_j = '1' else
        branch_target when branch_cond_taken = '1' else
        if_pc4;

    if_id_flush <= ctrl_flow_taken;
    id_ex_flush <= ctrl_flush or ctrl_flow_taken;

    mem_fwd_val <= mem_data when mem_mem_read = '1' else mem_alu_res;

    PC_UNIT: entity work.pc_reg
        port map (clk => clk, reset => reset, stall => pc_stall, pc_next => pc_next, pc_out => if_pc);
    IMEM: entity work.instr_mem
        port map (addr => if_pc, instr => if_instr);

    REG_IF_ID: entity work.if_id_reg
        port map (
            clk => clk, reset => reset, stall => if_id_stall, flush => if_id_flush,
            if_pc4 => if_pc4, if_instr => if_instr, id_pc4 => id_pc4, id_instr => id_instr
        );

    CTRL: entity work.control_unit
        port map (
            opcode => id_instr(31 downto 26), funct => id_instr(5 downto 0),
            reg_dst => id_reg_dst, alu_src => id_alu_src, mem_to_reg => id_mem_to_reg,
            reg_write => id_reg_write, mem_read => id_mem_read, mem_write => id_mem_write,
            branch => id_branch, bne => id_bne, jump_j => id_jump_j, jal => id_jal,
            jump_reg => id_jump_reg, lui => id_lui, imm_zext => id_imm_zext,
            uses_rs => id_uses_rs, uses_rt => id_uses_rt,
            alu_op => id_alu_op
        );
    RF: entity work.register_file
        port map (
            clk => clk, reset => reset, reg_write => wb_reg_write,
            read_reg1 => id_instr(25 downto 21), read_reg2 => id_instr(20 downto 16),
            write_reg => wb_write_reg, write_data => wb_final_res,
            read_data1 => id_rd1, read_data2 => id_rd2
        );
    id_imm32 <= std_logic_vector(resize(unsigned(id_instr(15 downto 0)), 32))
        when id_imm_zext = '1' else std_logic_vector(resize(signed(id_instr(15 downto 0)), 32));

    REG_ID_EX: entity work.id_ex_reg
        port map (
            clk => clk, reset => reset, flush => id_ex_flush,
            id_pc4 => id_pc4, id_rd1 => id_rd1, id_rd2 => id_rd2, id_imm32 => id_imm32,
            id_jump_index => id_instr(25 downto 0),
            id_rs => id_instr(25 downto 21), id_rt => id_instr(20 downto 16), id_rd => id_instr(15 downto 11),
            id_funct => id_instr(5 downto 0),
            id_reg_dst => id_reg_dst, id_alu_src => id_alu_src, id_mem_to_reg => id_mem_to_reg,
            id_reg_write => id_reg_write, id_mem_read => id_mem_read, id_mem_write => id_mem_write,
            id_branch => id_branch, id_bne => id_bne, id_jump_j => id_jump_j, id_jal => id_jal,
            id_jump_reg => id_jump_reg, id_lui => id_lui, id_alu_op => id_alu_op,
            ex_pc4 => ex_pc4, ex_rd1 => ex_rd1, ex_rd2 => ex_rd2, ex_imm32 => ex_imm32,
            ex_jump_index => ex_jump_index,
            ex_rs => ex_rs, ex_rt => ex_rt, ex_rd => ex_rd, ex_funct => ex_funct,
            ex_reg_dst => ex_reg_dst, ex_alu_src => ex_alu_src, ex_mem_to_reg => ex_mem_to_reg,
            ex_reg_write => ex_reg_write, ex_mem_read => ex_mem_read, ex_mem_write => ex_mem_write,
            ex_branch => ex_branch, ex_bne => ex_bne, ex_jump_j => ex_jump_j, ex_jal => ex_jal,
            ex_jump_reg => ex_jump_reg, ex_lui => ex_lui, ex_alu_op => ex_alu_op
        );

    alu_in_a <= ex_rd1 when forward_a = "00" else mem_fwd_val when forward_a = "10" else wb_final_res;
    forward_b_out <= ex_rd2 when forward_b = "00" else mem_fwd_val when forward_b = "10" else wb_final_res;
    alu_in_b <= forward_b_out when ex_alu_src = '0' else ex_imm32;

    ALU_CTRL_U: entity work.alu_ctrl
        port map (alu_op => ex_alu_op, funct => ex_funct, alu_ctrl => alu_ctrl_sig);

    ALU_UNIT: entity work.alu
        port map (a => alu_in_a, b => alu_in_b, alu_ctrl => alu_ctrl_sig, result => ex_alu_res, zero => ex_alu_zero);

    ex_write_reg <= "11111" when ex_jal = '1' else ex_rt when ex_reg_dst = '0' else ex_rd;
    ex_exmem_result <= ex_pc4 when ex_jal = '1' else
        (ex_imm32(15 downto 0) & x"0000") when ex_lui = '1' else
        ex_alu_res;

    REG_EX_MEM: entity work.ex_mem_reg
        port map (
            clk => clk, reset => reset,
            ex_alu_result => ex_exmem_result, ex_rd2 => forward_b_out, ex_write_reg => ex_write_reg,
            ex_mem_to_reg => ex_mem_to_reg, ex_reg_write => ex_reg_write,
            ex_mem_read => ex_mem_read, ex_mem_write => ex_mem_write,
            mem_alu_result => mem_alu_res, mem_rd2 => mem_rd2, mem_write_reg => mem_write_reg,
            mem_mem_to_reg => mem_mem_to_reg, mem_reg_write => mem_reg_write,
            mem_mem_read => mem_mem_read, mem_mem_write => mem_mem_write
        );

    DM: entity work.data_mem
        port map (
            clk => clk, mem_write => mem_mem_write, mem_read => mem_mem_read,
            addr => mem_alu_res, write_data => mem_rd2, read_data => mem_data
        );

    REG_MEM_WB: entity work.mem_wb_reg
        port map (
            clk => clk, reset => reset,
            mem_alu_result => mem_alu_res, mem_mem_data => mem_data, mem_write_reg => mem_write_reg,
            mem_mem_to_reg => mem_mem_to_reg, mem_reg_write => mem_reg_write,
            wb_alu_result => wb_alu_res, wb_mem_data => wb_data, wb_write_reg => wb_write_reg,
            wb_mem_to_reg => wb_mem_to_reg, wb_reg_write => wb_reg_write
        );

    wb_final_res <= wb_alu_res when wb_mem_to_reg = '0' else wb_data;

    FWD: entity work.forwarding_unit
        port map (
            ex_rs => ex_rs, ex_rt => ex_rt, mem_reg_write => mem_reg_write, mem_write_reg => mem_write_reg,
            wb_reg_write => wb_reg_write, wb_write_reg => wb_write_reg,
            forward_a => forward_a, forward_b => forward_b
        );
    HAZ: entity work.hazard_detection_unit
        port map (
            id_rs => id_instr(25 downto 21), id_rt => id_instr(20 downto 16),
            id_uses_rs => id_uses_rs, id_uses_rt => id_uses_rt,
            ex_mem_read => ex_mem_read, ex_rt => ex_rt,
            pc_stall => pc_stall, if_id_stall => if_id_stall, ctrl_flush => ctrl_flush
        );

end architecture structural;
