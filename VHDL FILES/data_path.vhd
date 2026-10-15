-- ============================================================
-- Module: Sign Extender
-- Purpose: Sign-extends a 16-bit immediate value to 32 bits.
--          Used for lw, sw, and beq offset fields.
-- Inputs:
--   imm16   : 16-bit signed immediate from instruction[15:0]
-- Outputs:
--   imm32   : 32-bit sign-extended value
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity sign_ext is
    port (
        imm16 : in  std_logic_vector(15 downto 0);
        imm32 : out std_logic_vector(31 downto 0)
    );
end entity sign_ext;

architecture rtl of sign_ext is
begin
    -- Replicate MSB (sign bit) into upper 16 bits
    imm32 <= (31 downto 16 => imm16(15)) & imm16;
end architecture rtl;


-- ============================================================
-- Module: Shift Left 2
-- Purpose: Multiplies a 32-bit value by 4 (left-shift by 2).
--          Used to scale the sign-extended branch offset from
--          word offsets to byte offsets before adding to PC+4.
-- Inputs:
--   din     : 32-bit input
-- Outputs:
--   dout    : 32-bit output = din << 2
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity shift_left2 is
    port (
        din  : in  std_logic_vector(31 downto 0);
        dout : out std_logic_vector(31 downto 0)
    );
end entity shift_left2;

architecture rtl of shift_left2 is
begin
    dout <= din(29 downto 0) & "00";    -- shift left 2, fill with zeros
end architecture rtl;


-- ============================================================
-- Module: 32-bit Adder
-- Purpose: General-purpose unsigned 32-bit adder.
--          Instantiated twice: once for PC+4, once for branch target.
-- Inputs:
--   a, b    : 32-bit addends
-- Outputs:
--   result  : 32-bit sum (overflow ignored)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder32 is
    port (
        a      : in  std_logic_vector(31 downto 0);
        b      : in  std_logic_vector(31 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity adder32;

architecture rtl of adder32 is
begin
    result <= std_logic_vector(unsigned(a) + unsigned(b));
end architecture rtl;


-- ============================================================
-- Module: 2-to-1 Multiplexer (32-bit)
-- Purpose: Selects between two 32-bit buses based on 1-bit sel.
--          Used in multiple places in the datapath.
-- Inputs:
--   d0, d1  : 32-bit data inputs
--   sel     : select (0 => d0, 1 => d1)
-- Outputs:
--   y       : 32-bit selected output
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity mux2_32 is
    port (
        d0  : in  std_logic_vector(31 downto 0);
        d1  : in  std_logic_vector(31 downto 0);
        sel : in  std_logic;
        y   : out std_logic_vector(31 downto 0)
    );
end entity mux2_32;

architecture rtl of mux2_32 is
begin
    y <= d1 when sel = '1' else d0;
end architecture rtl;


-- ============================================================
-- Module: 2-to-1 Multiplexer (5-bit)
-- Purpose: Selects between two 5-bit register addresses.
--          Used to choose write register: rt (I-type) or rd (R-type).
-- Inputs:
--   d0, d1  : 5-bit inputs
--   sel     : select (0 => d0/rt, 1 => d1/rd)
-- Outputs:
--   y       : 5-bit selected output
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity mux2_5 is
    port (
        d0  : in  std_logic_vector(4 downto 0);
        d1  : in  std_logic_vector(4 downto 0);
        sel : in  std_logic;
        y   : out std_logic_vector(4 downto 0)
    );
end entity mux2_5;

architecture rtl of mux2_5 is
begin
    y <= d1 when sel = '1' else d0;
end architecture rtl;


-- ============================================================
-- Module: Branch Logic
-- Purpose: Determines whether a branch is taken.
--          Branch is taken when branch='1' AND zero='1' (beq).
-- Inputs:
--   branch  : branch control signal from Main Control Unit
--   zero    : zero flag from ALU (rs == rt after subtraction)
-- Outputs:
--   pc_src  : '1' selects branch target PC, '0' selects PC+4
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity branch_logic is
    port (
        branch : in  std_logic;
        zero   : in  std_logic;
        pc_src : out std_logic
    );
end entity branch_logic;

architecture rtl of branch_logic is
begin
    pc_src <= branch and zero;
end architecture rtl;
