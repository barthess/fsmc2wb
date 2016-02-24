----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:03:46 09/09/2015 
-- Design Name: 
-- Module Name:    gnss_router - Behavioral 
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

entity gnss_router is
  Port (
    to_gnss   : out STD_LOGIC_VECTOR (3 downto 0);
    from_gnss : in  STD_LOGIC_VECTOR (3 downto 0);
    sel       : in  STD_LOGIC_VECTOR (1 downto 0);
    ubx_nrst  : out STD_LOGIC;
    to_stm    : out STD_LOGIC;
    from_stm  : in  STD_LOGIC
  );
end gnss_router;


architecture Behavioral of gnss_router is

begin
  uart_mux : entity work.muxer
  generic map (
    AW => 2,
    DW => 1
  )
  port map (
    A     => sel,
    di    => from_gnss,
    do(0) => to_stm
	);
	
	uart_demux : entity work.demuxer
  generic map (
    AW => 2,
    DW => 1,
    default => '1'
  )
  port map (
    A     => sel,
    do    => to_gnss,
    di(0) => from_stm
	);

  -- release reset on ublox when selected
  with sel select ubx_nrst <=
		'1' when "10",
		'0' when others;
        
end Behavioral;

