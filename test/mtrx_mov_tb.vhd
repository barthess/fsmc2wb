--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:07:58 02/05/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_mov_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_mov
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
 
ENTITY mtrx_mov_tb IS
END mtrx_mov_tb;
 
ARCHITECTURE behavior OF mtrx_mov_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mtrx_mov
    PORT(
         rst_i : IN  std_logic;
         clk_i : IN  std_logic;
         size_i : IN  std_logic_vector(15 downto 0);
         err_o : OUT  std_logic;
         rdy_o : OUT  std_logic;
         op_i : IN  std_logic_vector(1 downto 0);
         bram_adr_a_o : OUT  std_logic_vector(9 downto 0);
         bram_adr_c_o : OUT  std_logic_vector(9 downto 0);
         constant_i : IN  std_logic_vector(63 downto 0);
         bram_dat_a_i : IN  std_logic_vector(63 downto 0);
         bram_dat_c_o : OUT  std_logic_vector(63 downto 0);
         bram_ce_a_o : OUT  std_logic;
         bram_ce_c_o : OUT  std_logic;
         bram_we_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst_i : std_logic := '1';
   signal clk_i : std_logic := '0';
   signal size_i : std_logic_vector(15 downto 0) := (others => '0');
   signal op_i : std_logic_vector(1 downto 0) := (others => '0');
   signal constant_i : std_logic_vector(63 downto 0) := x"aaaabbbbccccdddd";
   signal bram_dat_a_i : std_logic_vector(63 downto 0) := x"1111222233334444";

 	--Outputs
   signal err_o : std_logic;
   signal rdy_o : std_logic;
   signal bram_adr_a_o : std_logic_vector(9 downto 0);
   signal bram_adr_c_o : std_logic_vector(9 downto 0);
   signal bram_dat_c_o : std_logic_vector(63 downto 0);
   signal bram_ce_a_o : std_logic;
   signal bram_ce_c_o : std_logic;
   signal bram_we_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
   type state_t is (IDLE, ACTIVE, HALT);
   signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.mtrx_mov 
   Generic map (
      MTRX_AW => 5,
      BRAM_DW => 64,
      DAT_LAT => 4
   )
   PORT MAP (
          rst_i => rst_i,
          clk_i => clk_i,
          size_i => size_i,
          err_o => err_o,
          rdy_o => rdy_o,
          op_i => op_i,
          bram_adr_a_o => bram_adr_a_o,
          bram_adr_c_o => bram_adr_c_o,
          constant_i => constant_i,
          bram_dat_a_i => bram_dat_a_i,
          bram_dat_c_o => bram_dat_c_o,
          bram_ce_a_o => bram_ce_a_o,
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
  stim_proc: process(clk_i)
    variable m, n : std_logic_vector(4 downto 0);
  begin		
    if rising_edge(clk_i) then
      case state is

      when IDLE =>
        m := "00000";
        n := "00000";
        size_i(9 downto 5) <= n;
        size_i(4 downto 0) <= m;
        op_i <= "01";
        rst_i <= '0';
        state <= ACTIVE;
        
      when ACTIVE =>
        if rdy_o = '1' then
          state <= HALT;
        end if;
        
      when HALT =>
        state <= HALT;
      end case;
      
    end if;
  end process;

END;
