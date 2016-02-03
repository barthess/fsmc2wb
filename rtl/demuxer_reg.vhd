----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:11:18 09/28/2015 
-- Design Name: 
-- Module Name:    fsmc_3to8_decoder - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity demuxer_reg is
  generic (
    AW : positive := 3;  -- address width (select bits count)
    DW : positive := 1;  -- data width 
    default : std_logic := '0'-- value for unselected outputs
  );
  port(
    clk_i : in std_logic;
    A  : in  STD_LOGIC_VECTOR(AW-1 downto 0);
    di : in  STD_LOGIC_VECTOR(DW-1 downto 0);
    do : out STD_LOGIC_VECTOR(2**AW*DW-1 downto 0)
  );
end demuxer_reg;

--
--
--
architecture reg_io of demuxer_reg is
  signal a_reg  : STD_LOGIC_VECTOR(AW-1 downto 0) := (others => '0');
  signal di_reg : STD_LOGIC_VECTOR(DW-1 downto 0);
  signal do_reg : STD_LOGIC_VECTOR(2**AW*DW-1 downto 0) := (others => default);
begin
  
  demuxer_e : entity work.demuxer
  generic map(
    AW => AW,
    DW => DW,
    default => default
  )
  port map(
    A => a_reg,
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
  
end reg_io;

--
--
--
architecture reg_i of demuxer_reg is
  signal a_reg  : STD_LOGIC_VECTOR(AW-1 downto 0) := (others => '0');
  signal di_reg : STD_LOGIC_VECTOR(DW-1 downto 0);
begin
  
  demuxer_e : entity work.demuxer
  generic map(
    AW => AW,
    DW => DW,
    default => default
  )
  port map(
    A => a_reg,
    di => di_reg,
    do => do
  );
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      a_reg  <= A;
      di_reg <= di;
    end if;
  end process;
  
end reg_i;

--
--
--
architecture reg_o of demuxer_reg is
  signal do_reg : STD_LOGIC_VECTOR(2**AW*DW-1 downto 0) := (others => default);
begin
  
  demuxer_e : entity work.demuxer
  generic map(
    AW => AW,
    DW => DW,
    default => default
  )
  port map(
    A  => A,
    di => di,
    do => do_reg
  );
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      do     <= do_reg;
    end if;
  end process;
  
end reg_o;


