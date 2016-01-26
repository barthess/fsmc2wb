--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:23:19 01/26/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/dadd_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dadd
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
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY dadd_tb IS
END dadd_tb;
 
ARCHITECTURE behavior OF dadd_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dadd
    PORT(
         a : IN  std_logic_vector(63 downto 0);
         b : IN  std_logic_vector(63 downto 0);
         operation_nd : IN  std_logic;
         clk : IN  std_logic;
         ce : IN  std_logic;
         result : OUT  std_logic_vector(63 downto 0);
         rdy : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic_vector(63 downto 0) := (others => '0');
   signal b : std_logic_vector(63 downto 0) := (others => '0');
   signal nd : std_logic := '0';
   signal clk : std_logic := '0';
   signal ce : std_logic := '0';

 	--Outputs
   signal result : std_logic_vector(63 downto 0);
   signal rdy : std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dadd PORT MAP (
          a => a,
          b => b,
          operation_nd => nd,
          clk => clk,
          ce => ce,
          result => result,
          rdy => rdy
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
    file f : text is in  "test/adr_incr/sum_test/in.txt";
    variable l : line; --line number declaration
    variable a_read, b_read : std_logic_vector(63 downto 0);
  begin		
    -- hold reset state for 2 ns.
    wait for 2 ns;

    wait for clk_period*10;
    
    readline(f, l);
    hread(l, a_read);
    a <= a_read;
    readline(f, l);
    hread(l, b_read);
    b <= b_read;
    ce <= '1';
    
    wait for clk_period*1;
    nd <= '1';
    
    wait;
  end process;

END;
