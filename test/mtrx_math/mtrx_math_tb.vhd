--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:05:09 02/07/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_math/mtrx_math_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_math
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
 
ENTITY mtrx_math_tb IS
END mtrx_math_tb;
 
ARCHITECTURE behavior OF mtrx_math_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mtrx_math
    PORT(
         rdy_o : OUT  std_logic;
         clk_mul_i : IN  std_logic;
         clk_wb_i : IN  std_logic_vector(8 downto 0);
         sel_i : IN  std_logic_vector(8 downto 0);
         stb_i : IN  std_logic_vector(8 downto 0);
         we_i : IN  std_logic_vector(8 downto 0);
         err_o : OUT  std_logic_vector(8 downto 0);
         ack_o : OUT  std_logic_vector(8 downto 0);
         adr_i : IN  std_logic_vector(143 downto 0);
         dat_o : OUT  std_logic_vector(143 downto 0);
         dat_i : IN  std_logic_vector(143 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_mul_i : std_logic := '0';
   signal clk_wb_i : std_logic_vector(8 downto 0) := (others => '0');
   signal sel_i : std_logic_vector(8 downto 0) := (others => '0');
   signal stb_i : std_logic_vector(8 downto 0) := (others => '0');
   signal we_i : std_logic_vector(8 downto 0) := (others => '0');
   signal adr_i : std_logic_vector(143 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(143 downto 0) := (others => '0');

 	--Outputs
   signal rdy_o : std_logic;
   signal err_o : std_logic_vector(8 downto 0);
   signal ack_o : std_logic_vector(8 downto 0);
   signal dat_o : std_logic_vector(143 downto 0);

   -- Clock period definitions
   constant clk_mul_i_period : time := 10 ns;
   constant clk_wb_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mtrx_math PORT MAP (
          rdy_o => rdy_o,
          clk_mul_i => clk_mul_i,
          clk_wb_i => clk_wb_i,
          sel_i => sel_i,
          stb_i => stb_i,
          we_i => we_i,
          err_o => err_o,
          ack_o => ack_o,
          adr_i => adr_i,
          dat_o => dat_o,
          dat_i => dat_i
        );

   -- Clock process definitions
   clk_mul_i_process :process
   begin
		clk_mul_i <= '0';
		wait for clk_mul_i_period/2;
		clk_mul_i <= '1';
		wait for clk_mul_i_period/2;
   end process;
 
   clk_wb_i_process :process
   begin
		clk_wb_i <= (others => '0');
		wait for clk_wb_i_period/2;
		clk_wb_i <= (others => '1');
		wait for clk_wb_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_mul_i_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
