--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:17:29 11/08/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/fsmc_router/fsmc_bram_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fsmc2bram_sync
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
USE ieee.numeric_std.ALL;
 
ENTITY fsmc_emu IS
  Generic (
    AW : positive := 20;
    DW : positive := 32;
    AW_SLAVE : positive := 15;
    
    -- STM32 internal clock (known as AHB HCLK)  
    HCLK_PERIOD : time := 4.63 ns; 
    -- Clock divider for HCLK. In STM32 (val-1). Min=2.
    HCLK_DIV : positive := 2;
    -- Data latancy cicles. In STM32 (val-2). Min=2.
    DATLAT_LEN : positive := 3;
    -- Idle (NCE, NOW, NWE high) cycles after read or write.
    BUSTURN_W_LEN : positive := 2;
    BUSTURN_R_LEN : positive := 5;
    -- STM32 inserts useles active cycles after data read.
    READ_COOLDOWN : positive := 2
    );
  Port (
    clk : out std_logic := '0';
    A   : out std_logic_vector(AW-1 downto 0);
    D   : inout std_logic_vector(DW-1 downto 0);
    -- actually they are out but for read back purpose changed to inout
    NWE : inout std_logic := '1';
    NOE : inout std_logic := '1';
    NCE : inout std_logic := '1'
  );

  -- helper function to get constant for high state of clock
  function GET_HIGH return natural is
  begin
    return (HCLK_DIV - 2) / 2;
  end GET_HIGH;
  
  -- helper function to get constant for low state of clock
  function GET_LOW return natural is
  begin
    if (HCLK_DIV - 1) rem 2 = 0 then
      return GET_HIGH + 1;
    else
      return GET_HIGH;
    end if;
  end GET_LOW;
  
END fsmc_emu;

--
--
--
ARCHITECTURE behavior OF fsmc_emu IS 

  signal rst : std_logic := '1';
  signal hclk : std_logic := '0';
  signal fsmc_clk : std_logic := '0';
  type clkdiv_state_t is (HIGH, LOW);
  signal clkdiv_state : clkdiv_state_t := LOW;
  signal rnw : std_logic := '0'; -- read not write
  signal rnw_latch : std_logic := '0'; -- read not write
  signal dv  : std_logic := '0'; -- data valid
  
  signal fsmc_ce : std_logic := '0';
  signal state_rst : std_logic := '0';  
  type state_t is (IDLE, ADHOLD, DATLAT, WRITE, READ, BUSTURN);
  signal state : state_t := IDLE;
  
  signal addr_cnt : std_logic_vector(AW-1 downto 0) := (others => '0');
  signal dat_reg : std_logic_vector(DW-1 downto 0) := (others => 'U');
  
BEGIN
  
  clk <= fsmc_clk;
  D <= dat_reg when (NCE = '0' and NWE = '0') else (others => 'Z');
  
  --
  -- HCLK process
  --
  hclk_process : process
  begin
    hclk <= not hclk;
    wait for HCLK_PERIOD/2;
  end process;

  --
  -- Ugly clock divider for FSMC bus. I am too tired to rewrite it.
  --
  fsmc_clk_process : process(hclk)
    variable high_cnt : natural := GET_HIGH;
    variable low_cnt  : natural := GET_LOW;
  begin
    if rising_edge(hclk) then
      if rst = '1' then
        clkdiv_state <= LOW;
        fsmc_clk <= '0';
      else
        case clkdiv_state is
        when HIGH =>
          fsmc_clk <= '1';
          if high_cnt = 0 then
            high_cnt := GET_HIGH;
            clkdiv_state <= LOW;
          else
            high_cnt := high_cnt - 1;
          end if;
          
        when LOW =>
          fsmc_clk <= '0';
          if low_cnt = 0 then
            low_cnt := GET_LOW;
            clkdiv_state <= HIGH;
          else
            low_cnt := low_cnt - 1;
          end if;
        end case;
      end if; -- rst
    end if; -- clk
  end process;

  --
  --
  --
  stimuli_process : process
    constant BURST : positive := 4;
  begin
    wait for HCLK_PERIOD * 8;
    rst <= '0';
    
    -- write loop
    for wcycle in 0 to 1 loop
    
      for i in 0 to BUSTURN_W_LEN-1 loop
        wait until falling_edge(fsmc_clk);
      end loop;
      
      wait until falling_edge(fsmc_clk);
      NCE <= '0';
      NWE <= '0';
      A <= std_logic_vector(to_unsigned(16 + wcycle*BURST, AW));
      
      for i in 0 to DATLAT_LEN-1 loop
        wait until falling_edge(fsmc_clk);
        A <= (others => 'U');
      end loop;
      
      for i in 0 to BURST-1 loop
        wait until falling_edge(fsmc_clk);
        dat_reg <= std_logic_vector(to_unsigned(wcycle*10 + i, DW));
      end loop;
      
      wait until rising_edge(fsmc_clk);
      wait until rising_edge(hclk);
      NCE <= '1';
      NWE <= '1';
      dat_reg <= (others => 'U');

    end loop;
    
    -- read loop
    for rcycle in 0 to 1 loop
      for i in 0 to BUSTURN_R_LEN-1 loop
        wait until falling_edge(fsmc_clk);
      end loop;
      
      wait until falling_edge(fsmc_clk);
      NCE <= '0';
      A <= std_logic_vector(to_unsigned(16 + rcycle*BURST, AW));
      
      for i in 0 to 1 loop
        wait until falling_edge(fsmc_clk);
        A <= (others => 'U');
      end loop;
      NOE <= '0';

      for i in 0 to DATLAT_LEN-1 loop
        wait until falling_edge(fsmc_clk);
      end loop;
      
      for i in 0 to BURST-1 loop
        wait until falling_edge(fsmc_clk);
        dat_reg <= D;
      end loop;
      
      for i in 0 to READ_COOLDOWN-1 loop
        wait until rising_edge(fsmc_clk);
      end loop;
      
      wait until rising_edge(fsmc_clk);
      wait until rising_edge(hclk);
      NCE <= '1';
      NOE <= '1';
    end loop;
    
    wait for HCLK_PERIOD * 100;
    wait;
  end process;

  
END;
