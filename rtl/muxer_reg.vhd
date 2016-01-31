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

entity muxer_reg is
  generic (
    AW  : positive := 3; -- address width
    DW  : positive := 4 -- data width 
  );
  port(
    clk_i : in std_logic;
    A  : in  STD_LOGIC_VECTOR(AW-1       downto 0);
    di : in  STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
    do : out STD_LOGIC_VECTOR(DW-1       downto 0)
  );
end muxer_reg;


architecture Behavioral of muxer_reg is
  signal a_reg  : STD_LOGIC_VECTOR(AW-1       downto 0);
  signal di_reg : STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
  signal do_reg : STD_LOGIC_VECTOR(DW-1       downto 0);
begin

  muxer_e : entity work.muxer
  generic map(
    AW => AW,
    DW => DW
  )
  port map(
    A  => a_reg,
    di => di_reg,
    do => do_reg
  );
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      a_reg  <= A;
      di_reg <= di;
      do     <= do_reg;
    end if;
  end process;

end Behavioral;

