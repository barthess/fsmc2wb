----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:10 01/28/2016 
-- Design Name: 
-- Module Name:    pseudo_bram_r - Behavioral 
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
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram_file_ro is
  Generic (
    LATENCY : positive := 1
  );
  Port (
    clk_i : in  STD_LOGIC;
    ce_i  : in  STD_LOGIC;
    adr_i : in  STD_LOGIC_VECTOR (9 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    nf_i  : in  STD_LOGIC;
    m_i   : in  integer;
    p_i   : in  integer;
    n_i   : in  integer
  );
end bram_file_r;



architecture Behavioral of bram_file_ro is
begin
  
  main : process(clk_i)
    
  begin
    if rising_edge(clk_i) then
      
    end if; -- clk
  end process;

end Behavioral;







