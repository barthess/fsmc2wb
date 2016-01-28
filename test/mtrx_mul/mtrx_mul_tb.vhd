--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:10:46 01/28/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_mul/mtrx_mul_tb.vhd
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
         dat_rdy_o : OUT  std_logic;
         clk_i : IN  std_logic;
         sel_i : IN  std_logic;
         stb_i : IN  std_logic;
         we_i : IN  std_logic;
         err_o : OUT  std_logic;
         ack_o : OUT  std_logic;
         adr_i : IN  std_logic_vector(15 downto 0);
         dat_o : OUT  std_logic_vector(15 downto 0);
         dat_i : IN  std_logic_vector(15 downto 0);
         bram_clk_o : OUT  std_logic_vector(2 downto 0);
         bram_adr_o : OUT  std_logic_vector(29 downto 0);
         bram_dat_i : IN  std_logic_vector(191 downto 0);
         bram_dat_o : OUT  std_logic_vector(191 downto 0);
         bram_we_o : OUT  std_logic_vector(2 downto 0);
         bram_en_o : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal sel_i : std_logic := '0';
   signal stb_i : std_logic := '0';
   signal we_i : std_logic := '0';
   signal adr_i : std_logic_vector(15 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(15 downto 0) := (others => '0');
   signal bram_dat_i : std_logic_vector(191 downto 0) := (others => '0');

 	--Outputs
   signal dat_rdy_o : std_logic;
   signal err_o : std_logic;
   signal ack_o : std_logic;
   signal dat_o : std_logic_vector(15 downto 0);
   signal bram_clk_o : std_logic_vector(2 downto 0);
   signal bram_adr_o : std_logic_vector(29 downto 0);
   signal bram_dat_o : std_logic_vector(191 downto 0);
   signal bram_we_o : std_logic_vector(2 downto 0);
   signal bram_en_o : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mtrx_mul PORT MAP (
          dat_rdy_o => dat_rdy_o,
          clk_i => clk_i,
          sel_i => sel_i,
          stb_i => stb_i,
          we_i => we_i,
          err_o => err_o,
          ack_o => ack_o,
          adr_i => adr_i,
          dat_o => dat_o,
          dat_i => dat_i,
          bram_clk_o => bram_clk_o,
          bram_adr_o => bram_adr_o,
          bram_dat_i => bram_dat_i,
          bram_dat_o => bram_dat_o,
          bram_we_o => bram_we_o,
          bram_en_o => bram_en_o
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
      wait for 3 ns;	

      wait for clk_i_period*2;

      -- insert stimulus here 

      wait;
   end process;

END;
