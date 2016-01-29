--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:26:07 01/28/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_mul/bram_file_ro_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: bram_file_ro
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
use ieee.std_logic_textio.all;
use std.textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY bram_file_in_tb IS
END bram_file_in_tb;
 
ARCHITECTURE behavior OF bram_file_in_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT bram_file_in
    Generic (
      LATENCY : positive;
      PREFIX  : string(1 to 1)
    );
    PORT(
         clk_i : IN  std_logic;
         ce_i : IN  std_logic;
         adr_i : IN  std_logic_vector(9 downto 0);
         dat_o : OUT  std_logic_vector(63 downto 0);
         m_i : IN  integer;
         p_i : IN  integer;
         n_i : IN  integer
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal ce_i : std_logic := '0';
   signal adr_i : std_logic_vector(9 downto 0) := (others => '0');
   signal m_i : integer := 0;
   signal p_i : integer := 0;
   signal n_i : integer := 0;

 	--Outputs
   signal dat_o : std_logic_vector(63 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
 
  type state_t is (IDLE, ACTIVE, HALT);
  signal state : state_t := IDLE;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bram_file_in 
     Generic map (
        LATENCY => 1,
        PREFIX  => "a"
     )
     PORT MAP (
          clk_i => clk_i,
          ce_i => ce_i,
          adr_i => adr_i,
          dat_o => dat_o,
          m_i => m_i,
          p_i => p_i,
          n_i => n_i
        );


  -- Stimulus process
  stim_proc: process(clk_i)
  begin		
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        m_i <= 2;
        p_i <= 2;
        n_i <= 2;
        ce_i <= '1';
        adr_i <= std_logic_vector(to_unsigned(1, 10));
        state <= ACTIVE;

      when ACTIVE =>
        adr_i <= std_logic_vector(to_unsigned(2, 10));
        state <= HALT;
        
      when HALT =>
        state <= HALT;
        
      end case;
    end if;
  end process;


   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;

END;
