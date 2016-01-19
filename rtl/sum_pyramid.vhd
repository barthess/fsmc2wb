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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sum_pyramid is
  Generic (
    WIDTH : positive := 5
  );
  Port (
    clk_i : in  std_logic;
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    adr_i : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
    rst_i : in  STD_LOGIC;
    ce_i  : in  STD_LOGIC;
    rdy_o : out STD_LOGIC;
    nd_i  : in  STD_LOGIC   -- new data loaded in all needed registers
    );
end sum_pyramid;


architecture beh of sum_pyramid is
  signal dat_32to16 : std_logic_vector(2**WIDTH*64-1 downto 0) := (others=>'0');
  signal dat_16to8  : std_logic_vector(16*64-1 downto 0);
  signal dat_8to4   : std_logic_vector(8*64-1  downto 0);
  signal dat_4to2   : std_logic_vector(4*64-1  downto 0);
  signal dat_2to1   : std_logic_vector(2*64-1  downto 0);
  
  signal nd_16to8 : std_logic;
  signal nd_8to4  : std_logic;
  signal nd_4to2  : std_logic;
  signal nd_2to1  : std_logic;
begin



  sum_32to16 : entity work.sum_line
    generic map (
      WIDTH => 4
    )
    port map (
      clk_i   => clk_i,
      ce_i    => ce_i,
      dat_i   => dat_32to16,
      nd_i    => nd_i,
      dat_o   => dat_16to8,
      rdy_o   => nd_16to8
    );

  sum_16to8 : entity work.sum_line
    generic map (
      WIDTH => 3
    )
    port map (
      clk_i   => clk_i,
      ce_i    => ce_i,
      dat_i   => dat_16to8,
      nd_i    => nd_16to8,
      dat_o   => dat_8to4,
      rdy_o   => nd_8to4
    );

  sum_8to4 : entity work.sum_line
    generic map (
      WIDTH => 2
    )
    port map (
      clk_i   => clk_i,
      ce_i    => ce_i,
      dat_i   => dat_8to4,
      nd_i    => nd_8to4,
      dat_o   => dat_4to2,
      rdy_o   => nd_4to2
    );
    
  sum_4to2 : entity work.sum_line
    generic map (
      WIDTH => 1
    )
    port map (
      clk_i   => clk_i,
      ce_i    => ce_i,
      dat_i   => dat_4to2,
      nd_i    => nd_4to2,
      dat_o   => dat_2to1,
      rdy_o   => nd_2to1
    );
    
  sum_2to1 : entity work.sum_line
    generic map (
      WIDTH => 0
    )
    port map (
      clk_i   => clk_i,
      ce_i    => ce_i,
      dat_i   => dat_2to1,
      nd_i    => nd_2to1,
      dat_o   => dat_o,
      rdy_o   => rdy_o
    );
    
  process
    --variable n : integer range 0 to 2**WIDTH-1 := 0;
    variable n : integer;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        dat_32to16 <= (others => '0');
      else
        n := to_integer(signed(adr_i));
        dat_32to16((n+1)*64-1 downto 64*n) <= dat_i;
      end if;
    end if;
  end process;

end beh;




