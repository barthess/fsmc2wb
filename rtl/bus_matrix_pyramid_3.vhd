----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:11:18 09/28/2015 
-- Design Name: 
-- Module Name:    fsmc_3to8_decoder - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity bus_matrix_pyramid_3 is
  generic (
    AW   : positive := 3; -- address width in bits
    ocnt : positive := 2; -- output ports count
    DW   : positive := 64 -- data bus width 
  );
  port(
    clk_i : in std_logic;
    A  : in  STD_LOGIC_VECTOR(AW*ocnt-1  downto 0);
    di : in  STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
    do : out STD_LOGIC_VECTOR(ocnt*DW-1  downto 0)
  );
end bus_matrix_pyramid_3;


architecture Behavioral of bus_matrix_pyramid_3 is

begin
  
  muxer_gen : for n in 0 to ocnt-1 generate 
  begin
    muxer_array : entity work.muxer_pyramid_3
    generic map (
      AW => 3,
      DW => DW
    )
    PORT MAP (
      clk_i => clk_i,
      di    => di,
      do    => do((n+1)*DW-1 downto n*DW),
      A     => A ((n+1)*AW-1 downto n*AW)
    );
  end generate;

end Behavioral;






