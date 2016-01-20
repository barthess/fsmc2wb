--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:52:26 01/19/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/u16add_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: u16add
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY u16add_tb IS
END u16add_tb;
 
ARCHITECTURE behavior OF u16add_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT u16add
    PORT(
         clk : IN  std_logic;
         a : IN  std_logic_vector(15 downto 0);
         b : IN  std_logic_vector(15 downto 0);
         res : OUT  std_logic_vector(15 downto 0);
         rdy : OUT  std_logic;
         ce : IN  std_logic;
         nd : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal a : std_logic_vector(15 downto 0) := (others => '0');
   signal b : std_logic_vector(15 downto 0) := (others => '0');
   signal ce : std_logic := '0';
   signal nd : std_logic := '0';

 	--Outputs
   signal res : std_logic_vector(15 downto 0);
   signal rdy : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: u16add PORT MAP (
          clk => clk,
          a => a,
          b => b,
          res => res,
          rdy => rdy,
          ce => ce,
          nd => nd
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 10 ns;	

      wait for clk_period*2;
      ce <= '1';
      wait for clk_period*1;
      
      -- insert stimulus here 
      a <= x"0001";
      b <= x"0002";
      nd <= '1';
      wait for clk_period*1;
      
      a <= x"0003";
      b <= x"0004";
      nd <= '1';
      wait for clk_period*1;
      
      a <= x"FFFF";
      b <= x"FFFF";
      nd <= '0';
      
      wait;
   end process;

END;
