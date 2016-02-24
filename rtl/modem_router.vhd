----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:59:17 11/13/2015 
-- Design Name: 
-- Module Name:    modem_router - rtl 
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

entity modem_router is
    Port ( STM_DI  : in  STD_LOGIC;
           STM_DO  : out STD_LOGIC;
           STM_CSI : in  STD_LOGIC;
           STM_CSO : out STD_LOGIC;
           
           DI :  in  STD_LOGIC_VECTOR (1 downto 0);
           DO :  out STD_LOGIC_VECTOR (1 downto 0);
           CSI : in  STD_LOGIC_VECTOR (1 downto 0);
           CSO : out STD_LOGIC_VECTOR (1 downto 0);
           
           SEL : in  STD_LOGIC);
end modem_router;

architecture rtl of modem_router is

begin
  
  DO  <= (others => STM_DI);
  CSO <= (others => STM_CSI);
  
  d_mux : entity work.muxer
  generic map (
    AW => 1,
    DW => 1
  )
  port map (
    A(0)  => SEL,
    di    => DI,
    do(0) => STM_DO
  );
  
  cs_mux : entity work.muxer
  generic map (
    AW => 1,
    DW => 1
  )
  port map (
    A(0)  => SEL,
    di    => CSI,
    do(0) => STM_CSO
  );
  
end rtl;




