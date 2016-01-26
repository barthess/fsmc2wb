--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:46:12 01/26/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/dadd_chain_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dadd_chain
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
 
ENTITY dadd_chain_tb IS
  Generic (
    LEN : positive := 5
  );
END dadd_chain_tb;
 
ARCHITECTURE behavior OF dadd_chain_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dadd_chain
    generic (
      LEN : positive
    );
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         ce_i : IN  std_logic;
         nd_i : IN  std_logic;
         len_i : IN  std_logic_vector(LEN-1 downto 0);
         dat_i : IN  std_logic_vector(63 downto 0);
         dat_o : OUT  std_logic_vector(63 downto 0);
         rdy_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal ce_i : std_logic := '0';
   signal nd_i : std_logic := '0';
   signal len_i : std_logic_vector(LEN-1 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(63 downto 0) := (others => '0');

 	--Outputs
   signal dat_o : std_logic_vector(63 downto 0);
   signal rdy_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dadd_chain 
   generic map (
      LEN => LEN
   )
   PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          ce_i  => ce_i,
          nd_i  => nd_i,
          len_i => len_i,
          dat_i => dat_i,
          dat_o => dat_o,
          rdy_o => rdy_o
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
      -- hold reset state for 100 ns.
      wait for 2 ns;	

      wait for clk_i_period*2;

      -- insert stimulus here 

      wait;
   end process;

END;
