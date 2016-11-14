--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:57:02 11/11/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/fsmc/fsmc2bram.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fsmc2bram_sync
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY fsmc2bram_tb IS
Generic (
  AW : positive := 20;
  DW : positive := 32;
  AW_SLAVE : positive := 16
  );
END fsmc2bram_tb;
 
ARCHITECTURE behavior OF fsmc2bram_tb IS 

   --Inputs
   signal clk : std_logic := '0';
   signal A : std_logic_vector(AW-1 downto 0) := (others => '0');
   signal NWE : std_logic := '0';
   signal NOE : std_logic := '0';
   signal NCE : std_logic := '0';
   signal bram_di : std_logic_vector(DW-1 downto 0) := (others => '0');

	--BiDirs
   signal D : std_logic_vector(DW-1 downto 0);

 	--Outputs
   signal bram_a : std_logic_vector(AW_SLAVE-1 downto 0);
   signal bram_do : std_logic_vector(DW-1 downto 0);
   signal bram_we : std_logic_vector(0 downto 0);
   signal bram_clk : std_logic;
 
BEGIN
 
  bram_memtest_inst : entity work.bram_memtest
  port map (
    addra => bram_a,
    dina  => bram_di,
    douta => bram_do,
    wea   => bram_we,
    clka  => bram_clk);

  fsmc_emulator : entity work.fsmc_emulator 
  port map (
    clk => clk,
    A => A,
    D => D,
    NWE => NWE,
    NOE => NOE,
    NCE => NCE);
 
 
	-- Instantiate the Unit Under Test (UUT)
  uut : entity work.fsmc2bram
  generic map (
    AW => AW,
    DW => DW,
    AW_SLAVE => AW_SLAVE)
  PORT MAP (
    clk => clk,

    A => A,
    D => D,
    NWE => NWE,
    NOE => NOE,
    NCE => NCE,

    bram_a   => bram_a,
    bram_di  => bram_do,
    bram_do  => bram_di,
    bram_we  => bram_we,
    bram_clk => bram_clk);

END;
