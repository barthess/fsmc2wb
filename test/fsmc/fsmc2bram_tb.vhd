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
  AW_SLAVE : positive := 12
  );
END fsmc2bram_tb;
 
ARCHITECTURE behavior OF fsmc2bram_tb IS 

  --Inputs
  signal clk_tb : std_logic := '0';
  signal A_tb : std_logic_vector(AW-1 downto 0) := (others => '0');
  signal NWE_tb : std_logic := '0';
  signal NOE_tb : std_logic := '0';
  signal NCE_tb : std_logic := '0';
  signal bram_di_tb : std_logic_vector(DW-1 downto 0) := (others => '0');

  --BiDirs
  signal D_tb : std_logic_vector(DW-1 downto 0);

  --Outputs
  signal bram_a_tb : std_logic_vector(AW_SLAVE-1 downto 0);
  signal bram_do_tb : std_logic_vector(DW-1 downto 0);
  signal bram_we_tb : std_logic_vector(0 downto 0);
  signal bram_clk_tb : std_logic;
 
BEGIN
 
  -- BRAM instance
  bram_memtest_inst : entity work.bram_memtest
  port map (
    addra => bram_a_tb,
    dina  => bram_di_tb,
    douta => bram_do_tb,
    wea   => bram_we_tb,
    clka  => bram_clk_tb);

  -- FSMC emulator
  fsmc_emu_inst : entity work.fsmc_emu
  generic map (
    AW => AW,
    DW => DW,
    AW_SLAVE => AW_SLAVE,
    HCLK_DIV => 2)
  port map (
    clk => clk_tb,
    A => A_tb,
    D => D_tb,
    NWE => NWE_tb,
    NOE => NOE_tb,
    NCE => NCE_tb);
 
	-- Instantiate the Unit Under Test (UUT)
  uut : entity work.fsmc2bram
  generic map (
    AW => AW,
    DW => DW,
    AW_SLAVE => AW_SLAVE,
    DATLAT_LEN => 3)
  PORT MAP (
    clk => clk_tb,

    A => A_tb,
    D => D_tb,
    NWE => NWE_tb,
    NOE => NOE_tb,
    NCE => NCE_tb,

    bram_a   => bram_a_tb,
    bram_di  => bram_do_tb,
    bram_do  => bram_di_tb,
    bram_we  => bram_we_tb,
    bram_clk => bram_clk_tb);

END;
