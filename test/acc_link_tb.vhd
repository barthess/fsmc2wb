--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:45:00 01/20/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/acc_link_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: acc_link
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
 
ENTITY dadd_link_tb IS
END dadd_link_tb;
 
ARCHITECTURE behavior OF dadd_link_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dadd_link
    PORT(
         clk_i : IN  std_logic;
         ce_i : IN  std_logic;
         dat_i : IN  std_logic_vector(15 downto 0);
         dat_o : OUT  std_logic_vector(15 downto 0);
         len_i : IN  std_logic_vector(4 downto 0);
         rdy_o : OUT  std_logic;
         rst_i : IN  std_logic;
         nd_i : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal ce_i : std_logic := '0';
   signal dat_i : std_logic_vector(15 downto 0) := (others => '0');
   signal len_i : std_logic_vector(4 downto 0) := (others => '0');
   signal rst_i : std_logic := '0';
   signal nd_i : std_logic := '0';

 	--Outputs
   signal dat_o : std_logic_vector(15 downto 0);
   signal rdy_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: acc_link PORT MAP (
          clk_i => clk_i,
          ce_i => ce_i,
          dat_i => dat_i,
          dat_o => dat_o,
          len_i => len_i,
          rdy_o => rdy_o,
          rst_i => rst_i,
          nd_i => nd_i
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin
      rst_i <= '1';
      -- hold reset state for 100 ns.
      wait for 10 ns;	

      wait for clk_i_period*3;
      wait for clk_i_period / 2;

      -- insert stimulus here 
      dat_i <= x"0009";
      len_i <= "00000";
      wait for clk_i_period*3;
      
      rst_i <= '0';
      ce_i <= '1';
      
      nd_i  <= '1';
      wait for clk_i_period;
      
      dat_i <= x"0008";
      nd_i  <= '0';
      wait for clk_i_period*3;
      
      nd_i  <= '1';
      wait for clk_i_period;
      
      dat_i <= x"0007";
      nd_i  <= '0';
      wait for clk_i_period*3;
      
      nd_i  <= '1';
      wait for clk_i_period;
      
      wait;
   end process;

END;
