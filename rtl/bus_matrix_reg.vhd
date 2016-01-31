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


entity bus_matrix_reg is
  generic (
    AW   : positive := 3; -- address width in bits
    DW   : positive := 64; -- data bus width 
    ocnt : positive := 2 -- output ports count
  );
  port(
    clk_i : in std_logic;
    A  : in  STD_LOGIC_VECTOR(AW*ocnt-1  downto 0);
    di : in  STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
    do : out STD_LOGIC_VECTOR(ocnt*DW-1  downto 0)
  );
end bus_matrix_reg;


architecture Behavioral of bus_matrix_reg is
  signal a_reg  : STD_LOGIC_VECTOR(AW*ocnt-1  downto 0);
  signal di_reg : STD_LOGIC_VECTOR(2**AW*DW-1 downto 0);
  signal do_reg : STD_LOGIC_VECTOR(ocnt*DW-1  downto 0);
begin

  bus_matrix_e : entity work.bus_matrix
  generic map (
    AW => AW,
    DW => DW, 
    ocnt => ocnt
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






