--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:40:51 01/14/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/adr_incr_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: adr_incr
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
 
ENTITY adr_incr_tb IS
END adr_incr_tb;
 
ARCHITECTURE behavior OF adr_incr_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adr_incr
    PORT(
         row_rdy_o : OUT  std_logic;
         mul_rdy_i : IN  std_logic;
         sum_rdy_i : IN  std_logic;
         eoc_o : OUT  std_logic;
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         m_i : IN  std_logic_vector(4 downto 0);
         n_i : IN  std_logic_vector(4 downto 0);
         p_i : IN  std_logic_vector(4 downto 0);
         a_adr_o : OUT  std_logic_vector(9 downto 0);
         b_adr_o : OUT  std_logic_vector(9 downto 0);
         c_adr_o : OUT  std_logic_vector(9 downto 0);
         sum_adr_o : OUT  std_logic_vector(4 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal mul_rdy_i : std_logic := '0';
   signal sum_rdy_i : std_logic := '0';
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '1';
   signal m_i : std_logic_vector(4 downto 0) := (others => '0');
   signal n_i : std_logic_vector(4 downto 0) := (others => '0');
   signal p_i : std_logic_vector(4 downto 0) := (others => '0');

 	--Outputs
   signal row_rdy_o : std_logic;
   signal eoc_o : std_logic;
   signal a_adr_o : std_logic_vector(9 downto 0);
   signal b_adr_o : std_logic_vector(9 downto 0);
   signal c_adr_o : std_logic_vector(9 downto 0);
   signal sum_adr_o : std_logic_vector(4 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adr_incr PORT MAP (
          row_rdy_o => row_rdy_o,
          mul_rdy_i => mul_rdy_i,
          sum_rdy_i => sum_rdy_i,
          eoc_o => eoc_o,
          clk_i => clk_i,
          rst_i => rst_i,
          m_i => m_i,
          n_i => n_i,
          p_i => p_i,
          a_adr_o => a_adr_o,
          b_adr_o => b_adr_o,
          c_adr_o => c_adr_o,
          sum_adr_o => sum_adr_o
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
      wait for 10 ns;	

      wait for clk_i_period*2;

      -- insert stimulus here 
      rst_i <= '0';
      mul_rdy_i <= '1';
      m_i <= "00010";
      n_i <= "00010";
      p_i <= "00011";
      wait;
   end process;


   -- Stimulus process
--   mul_rdy_proc: process
--   begin		
--      -- hold reset state for 100 ns.
--      wait for 10 ns;	
--
--      wait for clk_i_period*10;
--
--      -- insert stimulus here 
--      mul_rdy_i <= '1';
--      wait;
--   end process;
   
   
END;
