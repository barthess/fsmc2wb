--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:19:18 02/04/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_iterator.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_iterator
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
USE ieee.numeric_std.ALL;
 
ENTITY mtrx_iterator_tb IS
END mtrx_iterator_tb;
 
ARCHITECTURE behavior OF mtrx_iterator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)

   --Inputs
   signal rst_i : std_logic := '1';
   signal clk_i : std_logic := '0';
   signal m_i : std_logic_vector(4 downto 0) := (others => '0');
   signal n_i : std_logic_vector(4 downto 0) := (others => '0');

 	--Outputs
   signal rdy_o : std_logic;
   signal eye_o : std_logic;
   signal adr_o : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
    signal ce : std_logic := '0';
    
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.mtrx_iter_eye
--   Generic map (
--    MTRX_AW => 5
--   )
   PORT MAP (
          rst_i => rst_i,
          clk_i => clk_i,
          m_i => m_i,
          n_i => n_i,
          rdy_o => rdy_o,
          eye_o => eye_o,
          adr_o => adr_o
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
   ce_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      m_i <= "11111";
      n_i <= "11111";
      ce <= '1';
      wait;
   end process;


  stim_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (ce = '1') then
        rst_i <= '0';
      end if;
    end if;
  end process;
  
END;




