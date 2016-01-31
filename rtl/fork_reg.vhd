library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity fork_reg is
  generic (
    ocnt : positive := 8; -- number of output forks
    DW   : positive := 64 -- data width 
  );
  port(
    clk_i : in std_logic;
    di : in  STD_LOGIC_VECTOR(DW-1      downto 0);
    do : out STD_LOGIC_VECTOR(ocnt*DW-1 downto 0)
  );
end fork_reg;

--
--
--
architecture Behavioral of fork_reg is
  signal di_reg : STD_LOGIC_VECTOR(DW-1 downto 0);
  signal do_reg : STD_LOGIC_VECTOR(ocnt*DW-1 downto 0);
begin
  
  frk : entity work.fork
  generic map (
    ocnt => ocnt,
    DW => DW
  )
  port map (
    do => do_reg,
    di => di_reg
  );
  
  main : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      di_reg <= di;
      do <= do_reg;
    end if;
  end process;
  
end Behavioral;
