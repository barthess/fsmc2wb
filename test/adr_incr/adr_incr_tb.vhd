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
use std.textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY adr4mul_tb IS
END adr4mul_tb;
 
ARCHITECTURE behavior OF adr4mul_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adr4mul
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         ce_i : IN  std_logic;
         row_rdy_o : OUT  std_logic;
         eoi_o : OUT  std_logic;
         dv_o : OUT  std_logic;
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
   signal eoi_o : std_logic := '0';
   signal dv_o : std_logic := '0';
   signal adr_ce : std_logic := '0';
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
   constant clk_i_period : time := 1 ns;
   
   -- map file read stuff
   signal endoffile : std_logic := '0';
  signal file_rst : std_logic := '1';
  
  type state_t is (IDLE, ACTIVE, COOLDOWN);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adr4mul PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          ce_i  => adr_ce,
          row_rdy_o => row_rdy_o,
          eoi_o => eoi_o,
          dv_o => dv_o,
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
 
   
   --read process
  reading : process(clk_i)
    --file      infile    : text is in  "test/adr_incr/test_vectors/3_3_3_a.txt";
    file      infile    : text is in  "test/adr_incr/test_vectors/map.txt";
    variable  inline    : line; --line number declaration
    variable  dataread1 : real;
    variable  m_read1, p_read1, n_read1 : integer;
  begin
    
    if rising_edge(clk_i) then
      if (file_rst = '1') then
        state <= IDLE;
      else
        case state is
        when IDLE =>
          if (not endfile(infile)) then   --checking the "END OF FILE" is not reached.
            readline(infile, inline);
            read(inline, m_read1);
            m_i <= std_logic_vector(to_unsigned(m_read1, 5));
            readline(infile, inline);
            read(inline, p_read1);
            p_i <= std_logic_vector(to_unsigned(p_read1, 5));
            readline(infile, inline);
            read(inline, n_read1);
            n_i <= std_logic_vector(to_unsigned(n_read1, 5));
          else
            endoffile <='1';         --set signal to tell end of file read file is reached.
          end if;
          state <= ACTIVE;
          adr_ce <= '1';
          rst_i <= '0';

        when ACTIVE =>
          if eoi_o = '1' then
            adr_ce <= '0';
            rst_i <= '1';
            state <= COOLDOWN;
          end if;
          
        when COOLDOWN =>
          state <= IDLE;
          
        end case;
      end if;
    end if;
  end process reading;
   
   
   
   -- Stimulus process
   stim_proc: process
   begin		
   
      file_rst <= '1';
      wait for 3 ns;	
      file_rst <= '0';
      
      wait until eoi_o = '1';
      --rst_i <= '1';
      
      wait;
   end process;   
   

END;
