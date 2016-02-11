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

entity muxer_pyramid_3 is
  generic (
    AW  : positive := 3;
    DW  : positive := 64 -- data width 
  );
  port(
    clk_i : in std_logic;
    A     : in  STD_LOGIC_VECTOR(AW-1       downto 0);
    di    : in  STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
    do    : out STD_LOGIC_VECTOR(DW-1       downto 0)
  );
end muxer_pyramid_3;

--
--
--
architecture beh of muxer_pyramid_3 is
  signal dat_4to2 : std_logic_vector(4*DW-1 downto 0);
  signal dat_2to1 : std_logic_vector(2*DW-1 downto 0);
  
  signal a_4to2 : std_logic := '0';
  signal a_2to1 : std_logic := '0';

begin
  
  a_4to2_delay : entity work.delay
  generic map (
    LAT => 1,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => A(1),
    do(0) => a_4to2
  );

  a_2to1_delay : entity work.delay
  generic map (
    LAT => 2,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => A(2),
    do(0) => a_2to1
  );


  muxer_line_8to4 : entity work.muxer_line
  generic map (
    AW => 3,
    DW => DW
  )
  port map (
    clk_i => clk_i,
    A     => A(0),
    di    => di,
    do    => dat_4to2
  );


  muxer_line_4to2 : entity work.muxer_line
  generic map (
    AW => 2,
    DW => DW
  )
  port map (
    clk_i => clk_i,
    A     => a_4to2,
    di    => dat_4to2,
    do    => dat_2to1
  );


  muxer_line_2to1 : entity work.muxer_line
  generic map (
    AW => 1,
    DW => DW
  )
  port map (
    clk_i => clk_i,
    A     => a_2to1,
    di    => dat_2to1,
    do    => do
  );

end beh;



