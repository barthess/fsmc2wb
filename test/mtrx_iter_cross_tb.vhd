--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:41:14 02/06/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_iter_cross_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_iter_cross
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
 
ENTITY mtrx_iter_cross_tb IS
END mtrx_iter_cross_tb;
 
ARCHITECTURE behavior OF mtrx_iter_cross_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mtrx_iter_cross
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         ce_i : IN  std_logic;
         end_o : OUT  std_logic;
         dv_o : OUT  std_logic;
         m_i : IN  std_logic_vector(4 downto 0);
         p_i : IN  std_logic_vector(4 downto 0);
         n_i : IN  std_logic_vector(4 downto 0);
         a_adr_o : OUT  std_logic_vector(9 downto 0);
         b_adr_o : OUT  std_logic_vector(9 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '1';
   signal ce_i : std_logic := '0';
   signal m_i : std_logic_vector(4 downto 0) := (others => '0');
   signal p_i : std_logic_vector(4 downto 0) := (others => '0');
   signal n_i : std_logic_vector(4 downto 0) := (others => '0');

 	--Outputs
   signal end_o : std_logic;
   signal dv_o : std_logic;
   signal a_adr_o : std_logic_vector(9 downto 0);
   signal b_adr_o : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
  type state_t is (IDLE, PRELOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mtrx_iter_cross PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          ce_i => ce_i,
          end_o => end_o,
          dv_o => dv_o,
          m_i => m_i,
          p_i => p_i,
          n_i => n_i,
          a_adr_o => a_adr_o,
          b_adr_o => b_adr_o
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
  begin
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        m_i <= "00010";
        p_i <= "00010";
        n_i <= "00010";
        state <= PRELOAD;
        
      when PRELOAD =>
        rst_i <= '0';
        state <= ACTIVE;
        
      when ACTIVE =>
        ce_i <= '1';
        if end_o = '1' then
          state <= HALT;
        end if;
        
      when HALT =>
        state <= HALT;
      end case;
    end if; -- clk
  end process;

END;
