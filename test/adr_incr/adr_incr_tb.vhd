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
  Generic (
    WIDTH : positive := 3
  );
END adr4mul_tb;
 
ARCHITECTURE behavior OF adr4mul_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adr4mul
    Generic (
      WIDTH : positive
    );
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         row_rdy_o : OUT  std_logic;
         rdy_o : OUT  std_logic;
         dv_o : OUT  std_logic;
         m_i : IN  std_logic_vector(WIDTH-1 downto 0);
         p_i : IN  std_logic_vector(WIDTH-1 downto 0);
         n_i : IN  std_logic_vector(WIDTH-1 downto 0);
         a_adr_o : OUT  std_logic_vector(2*WIDTH-1 downto 0);
         b_adr_o : OUT  std_logic_vector(2*WIDTH-1 downto 0);
         a_tran_i : IN  std_logic;
         b_tran_i : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal rdy_o : std_logic := '0';
   signal dv_o : std_logic := '0';
   signal m_i : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
   signal p_i : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
   signal n_i : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
   signal a_tran_i : std_logic := '0';
   signal b_tran_i : std_logic := '0';

 	--Outputs
   signal row_rdy_o : std_logic;
   signal all_rdy_o : std_logic;
   signal a_adr_o : std_logic_vector(2*WIDTH-1 downto 0);
   signal b_adr_o : std_logic_vector(2*WIDTH-1 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 1 ns;
   
   -- map file read stuff
   signal endoffile : std_logic := '0';
   signal file_rst  : std_logic := '1';
   signal a_adr_ref : std_logic_vector(2*WIDTH-1 downto 0);
   signal b_adr_ref : std_logic_vector(2*WIDTH-1 downto 0);
   
  type state_t is (IDLE, PRELOAD, ACTIVE, COOLDOWN);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adr4mul 
   Generic map (
    WIDTH => WIDTH
   )
   PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          row_rdy_o => row_rdy_o,
          rdy_o => rdy_o,
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
    file len_file : text is in  "test/adr_incr/stim/len.txt";
    variable len_line : line; --line number declaration
    variable m_read1, p_read1, n_read1 : integer;
    
    file a_adr_file : text is in  "test/adr_incr/stim/a_adr.txt";
    file b_adr_file : text is in  "test/adr_incr/stim/b_adr.txt";
    variable a_adr_line, b_adr_line : line; --line number declaration
    variable a_adr_read1, b_adr_read1 : integer;
  begin
    
    if rising_edge(clk_i) then
      if (file_rst = '1') then
        state <= IDLE;
        rst_i <= '1';
      else
        if (endoffile = '0') then -- 1-bit latch
          case state is
          when IDLE =>
            if (not endfile(len_file)) then   --checking the "END OF FILE" is not reached.
              readline(len_file, len_line);
              read(len_line, m_read1);
              m_i <= std_logic_vector(to_unsigned(m_read1, WIDTH));
              readline(len_file, len_line);
              read(len_line, p_read1);
              p_i <= std_logic_vector(to_unsigned(p_read1, WIDTH));
              readline(len_file, len_line);
              read(len_line, n_read1);
              n_i <= std_logic_vector(to_unsigned(n_read1, WIDTH));
            else
              endoffile <='1';         --set signal to tell end of file read file is reached.
            end if;
            state  <= PRELOAD;
            rst_i  <= '0';

          when PRELOAD =>
            readline(a_adr_file, a_adr_line);
            read(a_adr_line, a_adr_read1);
            a_adr_ref <= std_logic_vector(to_unsigned(a_adr_read1, 2*WIDTH));
            readline(b_adr_file, b_adr_line);
            read(b_adr_line, b_adr_read1);
            b_adr_ref <= std_logic_vector(to_unsigned(b_adr_read1, 2*WIDTH));
            state <= ACTIVE;
            
          when ACTIVE =>
            if rdy_o = '0' then
              if (dv_o = '1') then
                readline(a_adr_file, a_adr_line);
                read(a_adr_line, a_adr_read1);
                a_adr_ref <= std_logic_vector(to_unsigned(a_adr_read1, 2*WIDTH));
                readline(b_adr_file, b_adr_line);
                read(b_adr_line, b_adr_read1);
                b_adr_ref <= std_logic_vector(to_unsigned(b_adr_read1, 2*WIDTH));
              end if;
            else
              rst_i <= '1';
              state <= COOLDOWN;
            end if;

          when COOLDOWN =>
            state <= IDLE;
            
          end case;
        end if;
      end if;
    end if;
  end process reading;


  -- assertion process
  checking : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (dv_o = '1' and endoffile = '0') then
        assert (a_adr_o = a_adr_ref) report "A address incorrect!" severity failure;
        assert (b_adr_o = b_adr_ref) report "B address incorrect!" severity failure;
      end if;
    end if;
  end process checking;
  
   
   -- Stimulus process
   stim_proc: process
   begin		
   
      file_rst <= '1';
      wait for 3 ns;	
      file_rst <= '0';
      
      wait until rdy_o = '1';
      --rst_i <= '1';
      
      wait;
   end process;   
   

END;
