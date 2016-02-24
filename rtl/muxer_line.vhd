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

entity muxer_line is
  generic (
    AW  : positive := 3; -- 2**AW is number of inputs
    DW  : positive := 64 -- data width 
  );
  port(
    clk_i : in std_logic;
    A     : in  STD_LOGIC;
    di    : in  STD_LOGIC_VECTOR(2**AW*DW-1      downto 0);
    do    : out STD_LOGIC_VECTOR(2**(AW-1)*DW-1  downto 0)
  );
end muxer_line;

--
--
--
architecture beh of muxer_line is
  signal a_reg  : STD_LOGIC_VECTOR(AW-1       downto 0);
  signal di_reg : STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
  signal do_reg : STD_LOGIC_VECTOR(DW-1       downto 0);
begin

  muxer_gen : for n in 0 to 2**(AW-1)-1 generate
  begin
    muxer : entity work.muxer_reg(i)
    generic map (
      AW => 1,
      DW => DW
    )
    port map (
      clk_i => clk_i,
      a(0)  => a,
      di    => di((n+1)*2*DW-1  downto n*2*DW),
      do    => do((n+1)*DW-1    downto n*DW)
    );
  end generate;

end beh;

