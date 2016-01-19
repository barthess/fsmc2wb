----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:52:50 01/18/2016 
-- Design Name: 
-- Module Name:    pyramid_sum - beh 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sum_line is
  Generic (
    WIDTH : natural -- := 4 -- number of summators == 2**WIDTH
  );
  Port ( 
    clk_i : in  STD_LOGIC;
    dat_i : in  STD_LOGIC_VECTOR (2 * 2**WIDTH * 64 - 1 downto 0);
    dat_o : out STD_LOGIC_VECTOR (2**WIDTH * 64 - 1 downto 0);
    ce_i  : in  STD_LOGIC;
    rdy_o : out STD_LOGIC;
    nd_i  : in  STD_LOGIC
    );
end sum_line;


architecture beh of sum_line is
  signal rdy_array : std_logic_vector(2**WIDTH-1 downto 0) := (others => '0');
  constant rdy_check : std_logic_vector(2**WIDTH-1 downto 0) := (others => '1');
begin
  
  sum_loop : for n in 0 to 2**WIDTH-1 generate
  begin
    sum : entity work.sum
    port map (
      clk     => clk_i,
      ce      => ce_i,
      a       => dat_i((n+1)*128-1    downto (n+1)*128 - 64),
      b       => dat_i((n+1)*128-64-1 downto n*128),
      result  => dat_o((n+1)*64-1     downto n*64),
      rdy     => rdy_array(n),
      operation_nd => nd_i
    );
  end generate;
  
  rdy_o <= '1' when (rdy_array = rdy_check) else '0';
  
end beh;

