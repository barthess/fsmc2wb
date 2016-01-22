--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:45:31 01/18/2016
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
 
ENTITY adr4mul_tb IS
END adr4mul_tb;
 
ARCHITECTURE behavior OF adr4mul_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adr4mul
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         row_rdy_o : OUT  std_logic;
         all_rdy_o : OUT  std_logic;
         m_i : IN  std_logic_vector(4 downto 0);
         p_i : IN  std_logic_vector(4 downto 0);
         n_i : IN  std_logic_vector(4 downto 0);
         a_adr_o : OUT  std_logic_vector(9 downto 0);
         b_adr_o : OUT  std_logic_vector(9 downto 0);
         a_tran_i : IN  std_logic;
         b_tran_i : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal m_i : std_logic_vector(4 downto 0) := (others => '0');
   signal p_i : std_logic_vector(4 downto 0) := (others => '0');
   signal n_i : std_logic_vector(4 downto 0) := (others => '0');
   signal a_tran_i : std_logic := '0';
   signal b_tran_i : std_logic := '0';

 	--Outputs
   signal row_rdy_o : std_logic;
   signal all_rdy_o : std_logic;
   signal a_adr_o : std_logic_vector(9 downto 0);
   signal b_adr_o : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adr4mul PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          row_rdy_o => row_rdy_o,
          all_rdy_o => all_rdy_o,
          m_i => m_i,
          p_i => p_i,
          n_i => n_i,
          a_adr_o => a_adr_o,
          b_adr_o => b_adr_o,
          a_tran_i => a_tran_i,
          b_tran_i => b_tran_i
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

      wait for clk_i_period*2;
      rst_i <= '0';
      m_i <= "00010";
      p_i <= "00010";
      n_i <= "00010";

      wait until all_rdy_o = '1';
      rst_i <= '1';
      
      wait;
   end process;
   
END;
