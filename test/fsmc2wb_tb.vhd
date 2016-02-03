--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:01:49 02/02/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/fsmc2wb_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fsmc2wb
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY fsmc2wb_tb IS
END fsmc2wb_tb;
 
ARCHITECTURE behavior OF fsmc2wb_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fsmc2wb
    PORT(
         clk_i : IN  std_logic;
         err_o : OUT  std_logic;
         ack_o : OUT  std_logic;
         A : IN  std_logic_vector(22 downto 0);
         D : INOUT  std_logic_vector(15 downto 0);
         NWE : IN  std_logic;
         NOE : IN  std_logic;
         NCE : IN  std_logic;
         NBL : IN  std_logic_vector(1 downto 0);
         sel_o : OUT  std_logic_vector(1 downto 0);
         stb_o : OUT  std_logic_vector(1 downto 0);
         we_o : OUT  std_logic_vector(1 downto 0);
         err_i : IN  std_logic_vector(1 downto 0);
         ack_i : IN  std_logic_vector(1 downto 0);
         adr_o : OUT  std_logic_vector(31 downto 0);
         dat_o : OUT  std_logic_vector(31 downto 0);
         dat_i : IN  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal A : std_logic_vector(22 downto 0) := (others => '0');
   signal NWE : std_logic := '1';
   signal NOE : std_logic := '1';
   signal NCE : std_logic := '1';
   signal NBL : std_logic_vector(1 downto 0) := (others => '1');
   signal err_i : std_logic_vector(1 downto 0) := (others => '0');
   signal ack_i : std_logic_vector(1 downto 0) := (others => '0');
   signal dat_i : std_logic_vector(31 downto 0) := (others => '0');

	--BiDirs
   signal D : std_logic_vector(15 downto 0);

 	--Outputs
   signal err_o : std_logic;
   signal ack_o : std_logic;
   signal sel_o : std_logic_vector(1 downto 0);
   signal stb_o : std_logic_vector(1 downto 0);
   signal we_o : std_logic_vector(1 downto 0);
   signal adr_o : std_logic_vector(31 downto 0);
   signal dat_o : std_logic_vector(31 downto 0);

   -- fsmc control signals
   signal clk_fsmc : std_logic := '0';
   signal w_rst : std_logic := '1';
    signal r_rst : std_logic := '1';
  
   -- Clock period definitions
   constant clk_i_period : time := 1 ns / 0.108;
   constant clk_fsmc_period : time := 1 ns / 0.168;
   
   -- FSMC timings
   constant T_BUSTURN_W : positive := 1; -- this field must not be zero in STM32
   constant T_DATAST_W  : positive := 2;
   
   constant T_BUSTURN_R : positive := 1; -- this field must not be zero in STM32
   constant T_DATAST_R  : positive := 8;
   
  type state_t is (DATAST, BUSTURN, IDLE);
  signal state : state_t := IDLE;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fsmc2wb PORT MAP (
          clk_i => clk_i,
          err_o => err_o,
          ack_o => ack_o,
          A => A,
          D => D,
          NWE => NWE,
          NOE => NOE,
          NCE => NCE,
          NBL => NBL,
          sel_o => sel_o,
          stb_o => stb_o,
          we_o => we_o,
          err_i => err_i,
          ack_i => ack_i,
          adr_o => adr_o,
          dat_o => dat_o,
          dat_i => dat_i
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 
   -- Clock process definitions
   clk_fsmc_process :process
   begin
		clk_fsmc <= '0';
		wait for clk_fsmc_period/2;
		clk_fsmc <= '1';
		wait for clk_fsmc_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 31 ns;	
      
      r_rst <= '0';
      w_rst <= '0';
      wait for clk_i_period*20;
      r_rst <= '1';
      w_rst <= '1';
      
      -- insert stimulus here 

      wait;
   end process;

--  fsmc_read : process(clk_fsmc)
--    variable datast_r  : integer := T_DATAST_R;
--    variable busturn_r : integer := T_BUSTURN_R;
--    variable a_cnt : std_logic_vector (22 downto 0) := std_logic_vector(to_unsigned(3, 23));
--    variable d_cnt : std_logic_vector (15 downto 0) := x"AD00";
--  begin
--    if rising_edge(clk_fsmc) then
--      if (r_rst = '1') then
--        NOE <= '1';
--        NCE <= '1';
--        state <= IDLE;
--        datast_r  := T_DATAST_R;
--        busturn_r := T_BUSTURN_R;
--      else
--        case state is
--        when IDLE =>
--          datast_r  := T_DATAST_R;
--          busturn_r := T_BUSTURN_R;
--          NOE <= '0';
--          NCE <= '0';
--          a_cnt(16) := '1';
--          a_cnt := a_cnt + 1;
--          A <= a_cnt;
--          state <= DATAST;
--          
--        when DATAST =>
--          datast_r := datast_r - 1;
--          if datast_r = 0 then
--            state <= BUSTURN;
--            NOE <= '1';
--          end if;
--          
--        when BUSTURN =>
--          busturn_r := busturn_r - 1;
--          if busturn_r = 0 then
--            state <= IDLE;
--            NCE <= '1';
--          end if;
--        end case;
--
--
--      end if;
--    end if;
--  end process;
  
  
  
  
  

  fsmc_write : process(clk_fsmc)
    variable busturn_w : integer := T_BUSTURN_W;
    variable datast_w  : integer := T_DATAST_W;
    variable a_cnt : std_logic_vector (22 downto 0) := std_logic_vector(to_unsigned(3, 23));
    variable d_cnt : std_logic_vector (15 downto 0) := x"AD00";
  begin
    if rising_edge(clk_fsmc) then
      if (w_rst = '1') then
        NWE <= '1';
        NCE <= '1';
        state <= IDLE;
        busturn_w := T_BUSTURN_W;
        datast_w  := T_DATAST_W;
      else
        case state is
        when IDLE =>
          busturn_w := T_BUSTURN_W;
          datast_w  := T_DATAST_W;
          NWE <= '0';
          NCE <= '0';
          a_cnt(16) := '1';
          a_cnt := a_cnt + 1;
          d_cnt := d_cnt + 1;
          A <= a_cnt;
          D <= d_cnt;
          state <= DATAST;
          
        when DATAST =>
          datast_w := datast_w - 1;
          if datast_w = 0 then
            state <= BUSTURN;
            NWE <= '1';
          end if;
          
        when BUSTURN =>
          busturn_w := busturn_w - 1;
          if busturn_w = 0 then
            state <= IDLE;
            NCE <= '1';
          end if;
        end case;
        
      end if;
    end if;
  end process;
  

  
  
END;