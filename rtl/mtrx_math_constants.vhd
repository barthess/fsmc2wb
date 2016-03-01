library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mtrx_math_constants is
  
  -- supported math operations. Note: some of them share single hardware block
  constant MATH_HW_TOTAL : integer := 4; -- total number of different hardware modules

  -- hardware blocks
  constant MATH_HW_MUL   : integer := 0;
  constant MATH_HW_ADD   : integer := 1;
  constant MATH_HW_MOV   : integer := 2;
  constant MATH_HW_DOT   : integer := 3; -- classical matrix multiplication

  -- (pseudo)operations codes
  constant MATH_OP_MUL   : natural := 0; -- uses mtrx_mul
  constant MATH_OP_SCALE : natural := 1; -- uses mtrx_mul
  constant MATH_OP_TRN   : natural := 2; -- uses mtrx_mov
  constant MATH_OP_CPY   : natural := 3; -- uses mtrx_mov
  constant MATH_OP_SET   : natural := 4; -- uses mtrx_mov
  constant MATH_OP_DIA   : natural := 5; -- uses mtrx_mov
  constant MATH_OP_ADD   : natural := 6; -- uses mtrx_add
  constant MATH_OP_SUB   : natural := 7; -- uses mtrx_add
  constant MATH_OP_DOT   : natural := 8; -- uses mtrx_dot
  
  constant MATH_OP_LAST  : natural := MATH_OP_DOT; -- for checks from C code
  
  constant MOV_OP_CPY : std_logic_vector (1 downto 0) := "00";
  constant MOV_OP_DIA : std_logic_vector (1 downto 0) := "01";
  constant MOV_OP_TRN : std_logic_vector (1 downto 0) := "10";
  constant MOV_OP_SET : std_logic_vector (1 downto 0) := "11";

  -- bit positions in control word
  constant CMD_BIT_B_TR   : natural := 13;
  constant CMD_BIT_RESVD  : natural := 14;
  constant CMD_BIT_DV     : natural := 15;

end mtrx_math_constants;


package body mtrx_math_constants is
end mtrx_math_constants;
