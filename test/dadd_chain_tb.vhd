--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:46:12 01/26/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/dadd_chain_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dadd_chain
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
 
ENTITY dadd_chain_tb IS
  Generic (
    LEN : positive := 5
  );
END dadd_chain_tb;
 
ARCHITECTURE behavior OF dadd_chain_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dadd_chain
    generic (
      LEN : positive
    );
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         nd_i  : IN  std_logic;
         cnt_i : IN  std_logic_vector(LEN-1 downto 0);
         dat_i : IN  std_logic_vector(63 downto 0);
         dat_o : OUT std_logic_vector(63 downto 0);
         rdy_o : OUT std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal nd_i  : std_logic := '0';
   signal cnt_i : std_logic_vector(LEN-1 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(63 downto 0) := (others => '0');

 	--Outputs
   signal dat_o : std_logic_vector(63 downto 0);
   signal rdy_o : std_logic;

   type state_t is (IDLE, LOAD_CNT, LOAD_DAT, ACTIVE, HALT);
   signal state : state_t := IDLE;
   
   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dadd_chain 
   generic map (
      LEN => LEN
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
    file fin  : text is in  "test/dadd/stim/in.txt";
    file fout : text is in  "test/dadd/stim/out.txt";
    file fmap : text is in  "test/dadd/stim/map.txt";
    variable lin  : line;
    variable lout : line;
    variable lmap : line;
    variable dat_read : std_logic_vector(63 downto 0);
    variable ref_read : std_logic_vector(63 downto 0);
    variable cnt_read1 : integer;
    variable cnt_read  : std_logic_vector(LEN-1 downto 0);
  begin
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        rst_i <= '1';
        state <= LOAD_CNT;

      when LOAD_CNT =>
        readline(fmap, lmap);
        read(lmap, cnt_read1);
        cnt_read := std_logic_vector(to_unsigned(cnt_read1 - 1, LEN));
        cnt_i <= cnt_read;
        state <= LOAD_DAT;

      when LOAD_DAT =>
        rst_i <= '0'; -- to latch counter inside add links
        if (not endfile(fin)) then   -- checking the "END OF FILE" is not reached.
          readline(fin, lin);
          hread(lin, dat_read);
          dat_i <= dat_read;
          nd_i  <= '1';
        else
          nd_i  <= '0';
          state <= ACTIVE;
        end if;

      when ACTIVE =>
        if rdy_o = '1' then
          readline(fout, lout);
          hread(lout, ref_read);
          assert (ref_read = dat_o) report "Result incorrect!" severity failure;
          state <= HALT;
        end if;

      when HALT =>
        state <= HALT; -- infinite loop
      
      end case;
      
    end if; -- clk
  end process;




END;
