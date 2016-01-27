--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:39:13 01/26/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/dadd/dadd_link_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dadd_link
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
--USE ieee.numeric_std.ALL;
 
ENTITY dadd_link_tb IS
  generic (
    WIDTH : positive := 1
  );
END dadd_link_tb;
 
 
ARCHITECTURE behavior OF dadd_link_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dadd_link
    generic (
      WIDTH : positive
    );
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         nd_i  : IN  std_logic;
         cnt_i : IN  std_logic_vector(WIDTH-1 downto 0);
         dat_i : IN  std_logic_vector(63 downto 0);
         dat_o : OUT std_logic_vector(63 downto 0);
         rdy_o : OUT std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '1';
   signal nd_i  : std_logic := '0';
   signal cnt_i : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(63 downto 0) := (others => '0');

 	--Outputs
   signal dat_o : std_logic_vector(63 downto 0);
   signal rdy_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
 
   type state_t is (IDLE, LOAD_CNT, LOAD_A, LOAD_B, SLEEP1, SLEEP2, ACTIVE, HALT);
   signal state : state_t := IDLE;
   
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dadd_link 
   generic map (
      WIDTH => WIDTH
   )
   PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          nd_i  => nd_i,
          cnt_i => cnt_i,
          dat_i => dat_i,
          dat_o => dat_o,
          rdy_o => rdy_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
   
   
   
   -- Stimulus process for single argument
  stim_proc: process(clk_i)
    file f : text is in  "test/dadd/stim/in.txt";
    variable l : line; --line number declaration
    variable a_read, b_read : std_logic_vector(63 downto 0);
  begin
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        
  --      readline(f, l);
  --      hread(l, b_read);
  --      b <= b_read;
        
        cnt_i <= "1";
        rst_i <= '1';
        state <= LOAD_CNT;
        
      when LOAD_CNT =>
        rst_i <= '0';
        state <= LOAD_A;
        
      when LOAD_A =>
        readline(f, l);
        hread(l, a_read);
        dat_i <= a_read;
        nd_i  <= '1';
        state <= SLEEP1;
        
      when SLEEP1 =>
        nd_i  <= '0';
        state <= SLEEP2;

      when SLEEP2 =>
        nd_i  <= '0';
        state <= LOAD_B;
        
      when LOAD_B =>
        readline(f, l);
        hread(l, b_read);
        dat_i <= b_read;
        nd_i  <= '1';
        state <= ACTIVE;
        
      when ACTIVE =>
        nd_i  <= '0';
        if rdy_o = '1' then
          state <= HALT;
        end if;

      when HALT =>
        state <= HALT; -- infinite loop
      
      end case;
      
    end if; -- clk
  end process;



--  -- Stimulus process for single argument
--  stim_proc: process(clk_i)
--    file f : text is in  "test/dadd/stim/in.txt";
--    variable l : line; --line number declaration
--    variable a_read, b_read : std_logic_vector(63 downto 0);
--  begin
--    if rising_edge(clk_i) then
--      case state is
--      when IDLE =>
--        readline(f, l);
--        hread(l, a_read);
--        dat_i <= a_read;
--  --      readline(f, l);
--  --      hread(l, b_read);
--  --      b <= b_read;
--        
--        cnt_i <= "0";
--        ce_i  <= '1';
--        rst_i <= '0';
--        nd_i  <= '1';
--        state <= ACTIVE;
--      
--      when ACTIVE =>
--        nd_i  <= '0';
--        if rdy_o = '1' then
--          state <= HALT;
--        end if;
--
--      when HALT =>
--        state <= HALT; -- infinite loop
--      
--      end case;
--      
--    end if; -- clk
--  end process;

END;
