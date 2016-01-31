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

entity fork is
  generic (
    ocnt : positive; -- number of forked outputs
    DW   : positive  -- data width 
  );
  port(
    di : in  STD_LOGIC_VECTOR(DW-1      downto 0);
    do : out STD_LOGIC_VECTOR(ocnt*DW-1 downto 0)
  );
end fork;


architecture Behavioral of fork is
begin
  
  forking : for n in 0 to ocnt generate 
  begin
    do ((n+1)*DW-1 downto n*DW) <= di;
  end generate;

end Behavioral;

