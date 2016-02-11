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
 
  --Inputs
  signal rst_i : std_logic := '1';
  signal clk_i : std_logic := '0';
  signal m_size_i : std_logic_vector(4 downto 0) := (others => '0');
  signal p_size_i : std_logic_vector(4 downto 0) := (others => '0');
  signal n_size_i : std_logic_vector(4 downto 0) := (others => '0');
  signal op_i : std_logic_vector(1 downto 0) := (others => '0');
  signal constant_i : std_logic_vector(63 downto 0) := x"aaaabbbbccccdddd";
  signal bram_dat_a_i : std_logic_vector(63 downto 0) := x"1111222233334444";

  --Outputs
  signal err_o : std_logic;
  signal rdy_o : std_logic;
  signal bram_adr_a_o : std_logic_vector(9 downto 0);
  signal bram_adr_b_o : std_logic_vector(9 downto 0);
  signal bram_adr_c_o : std_logic_vector(9 downto 0);
  signal bram_dat_b_i : std_logic_vector(63 downto 0);
  signal bram_dat_c_o : std_logic_vector(63 downto 0);
  signal bram_ce_a_o : std_logic;
  signal bram_ce_c_o : std_logic;
  signal bram_we_o : std_logic;

  -- Clock period definitions
  constant clk_i_period : time := 10 ns;

  type state_t is (IDLE, PRELOAD_EYE, ACTIVE_EYE, PRELOAD_CPY, ACTIVE_CPY, HALT);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.mtrx_mov 
   Generic map (
      MTRX_AW => 5,
      BRAM_DW => 64,
      DAT_LAT => 1
   )
   PORT MAP (
          rst_i => rst_i,
          clk_i => clk_i,
          
          m_size_i => m_size_i,
          p_size_i => p_size_i,
          n_size_i => n_size_i,

          err_o => err_o,
          rdy_o => rdy_o,
          op_i => op_i,
          bram_adr_a_o => bram_adr_a_o,
          bram_adr_b_o => bram_adr_b_o,
          bram_adr_c_o => bram_adr_c_o,
          constant_i => constant_i,
          bram_dat_a_i => bram_dat_a_i,
          bram_dat_b_i => bram_dat_b_i,
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
  begin		
    if rising_edge(clk_i) then
      case state is

      when IDLE =>
        m_size_i <= "00010";
        p_size_i <= "00000";
        n_size_i <= "00010";
        op_i  <= "01"; -- EYE
        rst_i <= '1';
        state <= PRELOAD_EYE;

      when PRELOAD_EYE =>
        rst_i <= '0';
        state <= ACTIVE_EYE;
        
      when ACTIVE_EYE =>
        if rdy_o = '1' then
          state <= PRELOAD_CPY;
          rst_i <= '1';
        end if;

      when PRELOAD_CPY =>
        m_size_i <= "00010";
        p_size_i <= "00000";
        n_size_i <= "00001";
        op_i  <= "00"; -- CPY
        rst_i <= '0';
        state <= ACTIVE_CPY;

      when ACTIVE_CPY =>
        if rdy_o = '1' then
          state <= HALT;
          rst_i <= '1';
        end if;
        
      when HALT =>
        state <= HALT;
      end case;
      
    end if;
  end process;

END;
