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
   signal ce_i : std_logic := '0';
   signal m_i : std_logic_vector(4 downto 0) := (others => '0');
   signal n_i : std_logic_vector(4 downto 0) := (others => '0');

 	--Outputs
   signal end_o : std_logic;
   signal eye_o : std_logic;
   signal dv_o  : std_logic;
   signal adr_o : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
    signal stim_ce : std_logic := '0';
  
  type state_t is (IDLE, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.mtrx_iter_eye
   Generic map (
    MTRX_AW => 5
   )
   PORT MAP (
          rst_i => rst_i,
          clk_i => clk_i,
          ce_i => ce_i,
          m_i => m_i,
          n_i => n_i,
          end_o => end_o,
          dv_o  => dv_o,
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
      m_i <= "00010";
      n_i <= "00010";
      stim_ce <= '1';
      wait;
   end process;


  stim_proc : process(clk_i)
    constant DROP : integer := 2;
    variable ce_drop : integer := DROP;
  begin
    if rising_edge(clk_i) then
      if (stim_ce = '1') then
        case state is
        when IDLE =>
          rst_i <= '0';
          state <= ACTIVE;
          ce_i <= '1';
          
        when ACTIVE =>
--          if ce_drop = 0 then
--            ce_i <= '0';
--            ce_drop := DROP;
--          else
--            ce_i <= '1';
--            ce_drop := ce_drop - 1;
--          end if;
          
          if (end_o = '1') then
            state <= HALT;
          end if;
          
        when HALT =>
          state <= HALT;
        end case;
      end if;
    end if;
  end process;
  
END;




