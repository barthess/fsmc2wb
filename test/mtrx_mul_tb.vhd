--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:22:48 02/01/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_mul_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_mul
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
 
ENTITY mtrx_mul_tb IS
END mtrx_mul_tb;
 
ARCHITECTURE behavior OF mtrx_mul_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mtrx_mul
    PORT(
         rst_i : IN  std_logic;
         clk_i : IN  std_logic;
         op_i : IN  std_logic_vector(15 downto 0);
         rdy_o : OUT  std_logic;
         bram_adr_a_o : OUT  std_logic_vector(9 downto 0);
         bram_adr_b_o : OUT  std_logic_vector(9 downto 0);
         bram_adr_c_o : OUT  std_logic_vector(9 downto 0);
         bram_dat_a_i : IN  std_logic_vector(63 downto 0);
         bram_dat_b_i : IN  std_logic_vector(63 downto 0);
         bram_dat_c_o : OUT  std_logic_vector(63 downto 0);
         bram_ce_a_o : OUT  std_logic;
         bram_ce_b_o : OUT  std_logic;
         bram_ce_c_o : OUT  std_logic;
         bram_we_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst_i : std_logic := '1';
   signal clk_i : std_logic := '0';
   signal op_i : std_logic_vector(15 downto 0) := (others => '0');
   signal bram_dat_a_i : std_logic_vector(63 downto 0) := (others => '0');
   signal bram_dat_b_i : std_logic_vector(63 downto 0) := (others => '0');

 	--Outputs
   signal rdy_o : std_logic;
   signal bram_adr_a_o : std_logic_vector(9 downto 0);
   signal bram_adr_b_o : std_logic_vector(9 downto 0);
   signal bram_adr_c_o : std_logic_vector(9 downto 0);
   signal bram_dat_c_o : std_logic_vector(63 downto 0);
   signal bram_ce_a_o : std_logic;
   signal bram_ce_b_o : std_logic;
   signal bram_ce_c_o : std_logic;
   signal bram_we_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mtrx_mul PORT MAP (
          rst_i => rst_i,
          clk_i => clk_i,
          op_i => op_i,
          rdy_o => rdy_o,
          bram_adr_a_o => bram_adr_a_o,
          bram_adr_b_o => bram_adr_b_o,
          bram_adr_c_o => bram_adr_c_o,
          bram_dat_a_i => bram_dat_a_i,
          bram_dat_b_i => bram_dat_b_i,
          bram_dat_c_o => bram_dat_c_o,
          bram_ce_a_o => bram_ce_a_o,
          bram_ce_b_o => bram_ce_b_o,
          bram_ce_c_o => bram_ce_c_o,
          bram_we_o => bram_we_o
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
    wait for 100 ns;	
    
    wait for clk_i_period*10;
    --op_i <= "0000001111111111";
    op_i <= x"0000";
    wait for clk_i_period*1;
    rst_i <= '0';
    
  wait;
  end process;

END;
