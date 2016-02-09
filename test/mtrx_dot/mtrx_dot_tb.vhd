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
use ieee.std_logic_textio.all;
use std.textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY mtrx_mul_tb IS
END mtrx_mul_tb;
 
ARCHITECTURE behavior OF mtrx_mul_tb IS 

  --Inputs
  signal clk_i : std_logic := '0';
  signal rst_i : std_logic := '1';
  
  --Outputs
  signal rdy_o : std_logic;
  signal err_o : std_logic;
  signal size_i : std_logic_vector(15 downto 0);
  
  signal bram_ce_a_o  : std_logic;
  signal bram_ce_b_o  : std_logic;
  signal bram_ce_c_o  : std_logic;

  signal bram_adr_a_o : std_logic_vector(9 downto 0);
  signal bram_adr_b_o : std_logic_vector(9 downto 0);
  signal bram_adr_c_o : std_logic_vector(9 downto 0);

  signal bram_dat_c_o : std_logic_vector(63 downto 0);
  signal bram_dat_a_i : std_logic_vector(63 downto 0) := (others => '0');
  signal bram_dat_b_i : std_logic_vector(63 downto 0) := (others => '0');

  signal bram_we_o : std_logic;

  -- Clock period definitions
  constant clk_i_period : time := 1 ns;

  -- state machine
  type state_t is (IDLE, LOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;

  signal m_i, p_i, n_i : integer := 0;

BEGIN
 
  -- Instantiate the Unit Under Test (UUT)
  uut: entity work.mtrx_dot
  generic map (
    BRAM_DW => 64,
    MTRX_AW => 5,
    DAT_LAT => 1
  )
  PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          rdy_o => rdy_o,
          size_i => size_i,
          err_o => err_o,
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


  -- Instantiate the input A bram 
  bram_file_a: entity work.bram_file_in 
  Generic map (
    LATENCY => 1,
    PREFIX  => "a"
  )
  PORT MAP (
    clk_i => clk_i,
    ce_i  => bram_ce_a_o,
    adr_i => bram_adr_a_o,
    dat_o => bram_dat_a_i,
    m_i => m_i,
    p_i => p_i,
    n_i => n_i
  );

  -- Instantiate the input B bram 
  bram_file_b: entity work.bram_file_in 
  Generic map (
    LATENCY => 1,
    PREFIX  => "b"
  )
  PORT MAP (
    clk_i => clk_i,
    ce_i  => bram_ce_b_o,
    adr_i => bram_adr_b_o,
    dat_o => bram_dat_b_i,
    m_i => m_i,
    p_i => p_i,
    n_i => n_i
  );
  
  -- Instantiate the pseudo output C bram 
  bram_file_c: entity work.bram_file_ref
  Generic map (
    PREFIX  => "c"
  )
  PORT MAP (
    clk_i => clk_i,
    ce_i  => bram_ce_c_o,
    we_i  => bram_we_o,
    adr_i => bram_adr_c_o,
    dat_i => bram_dat_c_o,
    m_i => m_i,
    p_i => p_i,
    n_i => n_i
  );
  
  
   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

 
  -- Control logic process
  control_proc: process(clk_i)
    constant idle_cnt_val : integer := 10;
    variable idle_cnt : integer := idle_cnt_val;
    file f : text is in  "test/mtrx_mul/stim/map.txt";
    variable l : line;
    variable m_read, p_read, n_read : integer;
  begin
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        idle_cnt := idle_cnt - 1;
        if idle_cnt = 0 then
          state <= LOAD;
          idle_cnt := idle_cnt_val;
        end if;

      when LOAD =>
        if (not endfile(f)) then  
          readline(f, l);
          read(l, m_read);
          readline(f, l);
          read(l, p_read);
          readline(f, l);
          read(l, n_read);
          assert (m_read < 32 and p_read < 32 and n_read < 32) report "Overflow" severity failure;
          m_i <= m_read;
          p_i <= p_read;
          n_i <= n_read;
          size_i(4  downto 0)  <= std_logic_vector(to_unsigned(m_read, 5));
          size_i(9  downto 5)  <= std_logic_vector(to_unsigned(p_read, 5));
          size_i(14 downto 10) <= std_logic_vector(to_unsigned(n_read, 5));
          state <= ACTIVE;
          rst_i <= '0';
        else
          state <= HALT;
        end if;

      when ACTIVE => 
        if (rdy_o = '1') then
          state <= IDLE;
        end if;
        
      when HALT =>
        state <= HALT;
      end case;

    end if; -- clk
    
  end process;
  

END;
