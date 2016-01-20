----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:04:50 01/19/2016 
-- Design Name: 
-- Module Name:    u16add - beh 
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
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity u16add is
  Generic (
    latency : natural := 5
  );
  Port (
    clk : in  std_logic;
    a   : in  STD_LOGIC_VECTOR (15 downto 0);
    b   : in  STD_LOGIC_VECTOR (15 downto 0);
    res : out STD_LOGIC_VECTOR (15 downto 0);
    rdy : out std_logic;
    ce  : in  STD_LOGIC;
    nd  : in  STD_LOGIC
  );
end u16add;

architecture beh of u16add is
  signal sum : std_logic_vector(15 downto 0) := x"0000";
  signal nd_buf : std_logic := '0';
begin

  dat_lat : entity work.latency 
    generic map (
      LAT => latency,
      WIDTH => 16
    )
    port map (
      clk => clk,
      ce  => ce,
      i   => sum,
      o   => res
    );
    
  nd_lat : entity work.latency 
    generic map (
      LAT => latency,
      WIDTH => 1
    )
    port map (
      clk => clk,
      ce  => ce,
      i(0)=> nd_buf,
      o(0)=> rdy
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if ce = '1' then
        nd_buf <= nd;
        sum <= std_logic_vector(unsigned(a) + unsigned(b));
      end if;
    end if;
  end process;
  
end beh;




