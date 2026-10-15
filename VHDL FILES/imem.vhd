library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instr_mem is
    port (
        addr  : in std_logic_vector(31 downto 0);
        instr : out std_logic_vector(31 downto 0)
    );
end entity instr_mem;

architecture rtl of instr_mem is
    type mem_array is array (0 to 63) of std_logic_vector(31 downto 0);

    -- Factorial n! for n in $t0 ($8), result in $t1 ($9). Uses repeated addition (no mult).
    -- n=5 -> 5! = 120 (0x78). Final result also stored at data_mem word 0 (sw $t1, 0($0)).
    --
    -- $t0=$8 n   $t1=$9 result   $t2=$10 i   $t3=$11 slt temp
    -- $t4=$12 acc (inner)   $t5=$13 j (inner counter)
    constant mem : mem_array := (
        0  => x"20080005",   -- addi $t0, $0, 5        # n = 5
        1  => x"20090001",   -- addi $t1, $0, 1        # result = 1
        2  => x"200A0002",   -- addi $t2, $0, 2        # i = 2
        -- outer: 3
        3  => x"010A582A",   -- slt $t3, $t0, $t2      # $t3 = (n < i) i.e. (i > n)
        4  => x"15600009",   -- bne $t3, $0, done      # if i > n, exit (to word 14)
        5  => x"200C0000",   -- addi $t4, $0, 0        # acc = 0
        6  => x"200D0000",   -- addi $t5, $0, 0        # j = 0
        -- inner: 7  -- acc += result each time, j runs 0..i-1  ->  acc = result * i
        7  => x"11AA0003",   -- beq $t5, $t2, end_inner  # if j == i, exit inner (word 11)
        8  => x"01896020",   -- add $t4, $t4, $t1       # acc += result
        9  => x"21AD0001",   -- addi $t5, $t5, 1        # j++
        10 => x"08000007",   -- j inner                 # jump to word 7
        -- end_inner: 11
        11 => x"01804820",   -- add $t1, $t4, $0        # result = acc
        12 => x"214A0001",   -- addi $t2, $t2, 1       # i++
        13 => x"08000003",   -- j outer                 # jump to word 3
        -- done: 14
        14 => x"AC090000",   -- sw $t1, 0($0)          # store 120 to dmem[0]
        15 => x"0800000F",   -- j 15                    # halt loop

        others => x"00000000"
    );

begin
    process (addr)
    begin
        if (unsigned(addr) < 256) then
            instr <= mem(to_integer(unsigned(addr(7 downto 2))));
        else
            instr <= x"00000000";
        end if;
    end process;

end architecture rtl;
