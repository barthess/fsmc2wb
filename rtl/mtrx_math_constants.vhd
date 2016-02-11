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
  constant MATH_OP_EYE   : natural := 5; -- uses mtrx_mov
  constant MATH_OP_ADD   : natural := 6; -- uses mtrx_add
  constant MATH_OP_SUB   : natural := 7; -- uses mtrx_add
  constant MATH_OP_DOT   : natural := 8; -- uses mtrx_dot

end mtrx_math_constants;


package body mtrx_math_constants is
end mtrx_math_constants;
