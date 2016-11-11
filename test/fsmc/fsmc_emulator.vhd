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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY fsmc_emulator IS
  Generic (
    AW_FSMC : positive := 20;
    DW : positive := 32;
    AW_SLAVE : positive := 15;
    
    HCLK_DIV : positive := 1;        -- clock divider as defined in ST's datasheet
    ADHOLD_LEN : positive := 1;
    DATLAT_LEN : positive := 2;
    IDLE_LEN : positive := 1;
    BUSTURN_LEN : positive := 1;
    TRN_LEN : positive := 8;
    hclk_period : time := 4.63 ns    -- STM32 internal clock (known as HCLK)
    );
  Port (
    clk : out std_logic := '0';
    A   : out std_logic_vector(AW_FSMC-1 downto 0);
    NWE : out std_logic;
    NOE : out std_logic;
    NCE : out std_logic;
    D   : inout std_logic_vector(DW-1 downto 0)
  );

  -- helper function to get constant for high state of clock
  function GET_HIGH return natural is
  begin
    return (HCLK_DIV - 1) / 2;
  end GET_HIGH;
  
  -- helper function to get constant for low state of clock
  function GET_LOW return natural is
  begin
    if HCLK_DIV rem 2 = 0 then
      return GET_HIGH + 1;
    else
      return GET_HIGH;
    end if;
  end GET_LOW;
  
END fsmc_emulator;

--
--
--
ARCHITECTURE behavior OF fsmc_emulator IS 

  -- FSMC simulation definitions
  signal write_burst : integer := 0;
  signal read_burst : integer := 0;
  signal burst_cnt : integer := 0;
  
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
  
  signal addr_cnt : std_logic_vector(AW_FSMC-1 downto 0) := (others => '0');
  signal data_reg : std_logic_vector(DW-1 downto 0) := (others => '0');
  signal data_lat_reg : std_logic_vector(DW-1 downto 0) := (others => '0');
  
BEGIN
  
  D <= data_reg when (state = WRITE) else (others => 'Z');
  clk <= fsmc_clk;
  
  --
  -- HCLK process
  --
  hclk_process : process
  begin
    hclk <= not hclk;
    wait for hclk_period/2;
  end process;

  --
  -- reset release process
  --
  reset_process : process
  begin
    wait for hclk_period * 8;
    rst <= '0';
    rnw <= '0';
    
    wait for hclk_period * (HCLK_DIV + 1);
    dv <= '1';
    
    wait for hclk_period;
    dv <= '0';
    rnw <= '1';
    
    wait until state = IDLE;
    wait for hclk_period*10;
    dv <= '1';
    wait until state = ADHOLD;
    dv <= '0';

    wait for hclk_period * 10;
    wait;
  end process;
  
  --
  -- clock divider for FSMC bus
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
  state_process : process(hclk, fsmc_clk)
    variable waitcnt : integer := 0;
  begin
    if rising_edge(hclk) then
      if rst = '1' then
        state <= IDLE;
        waitcnt := 1;
      else 
        case state is
        
        when IDLE =>
          if dv = '1' then
            rnw_latch <= rnw;
            waitcnt := ADHOLD_LEN * (HCLK_DIV + 1);
            if rnw = '1' then
              waitcnt := waitcnt + HCLK_DIV * 2;
            end if;
            state <= ADHOLD;
          end if;

        when ADHOLD =>
          waitcnt := waitcnt - 1;
          if waitcnt = 0 then
            state <= DATLAT;
            waitcnt := DATLAT_LEN * (HCLK_DIV + 1);
          end if;

        when DATLAT =>
          waitcnt := waitcnt - 1;
          if waitcnt = 0 then
            if rnw_latch = '0' then
              state <= WRITE;
              waitcnt := TRN_LEN * (HCLK_DIV + 1);
            else
              state <= READ;
              -- there is 1 additional clock comparing to WRITE
              waitcnt := (TRN_LEN + 1)  * (HCLK_DIV + 1);
            end if;
          end if;
          
        when WRITE =>
          waitcnt := waitcnt - 1;
          if waitcnt = 0 then
            state <= BUSTURN;
            waitcnt := BUSTURN_LEN * (HCLK_DIV + 1);
          end if;
          
        when READ =>
          waitcnt := waitcnt - 1;
          if waitcnt = 0 then
            state <= BUSTURN;
            waitcnt := BUSTURN_LEN * (HCLK_DIV + 1);
          end if;

        when BUSTURN =>
          waitcnt := waitcnt - 1;
          if waitcnt = 0 then
            waitcnt := IDLE_LEN * (HCLK_DIV + 1);
            state <= IDLE;
          end if;
          
        end case;
      end if; -- rst
    end if; -- clk
  end process;
  
  
  
  
  --
  -- Stimulus process
  --
  stim_proc: process(state)
    file f : text;
    variable ln : line;
    variable fpath : string(1 to 22) := "test/fsmc/bus_data.txt";
    variable adr_read : integer;
    variable data_read : std_logic_vector(63 downto 0);
  begin
    file_close(f);
    file_open(f, fpath, READ_MODE);    
    
    case state is
    when IDLE =>
      NCE <= '1';
      NWE <= '1';
      NOE <= '1';

    when ADHOLD =>
      readline(f, ln);
      read(ln, adr_read);

      A <= conv_std_logic_vector(adr_read, AW_FSMC);
      addr_cnt <= addr_cnt + 2;
      NCE <= '0';
      if rnw_latch = '0' then
        NWE <= '0';
      end if;

    when DATLAT =>
      if rnw_latch = '1' then
        NOE <= '0';
      end if;

    when WRITE =>
      -- empty
      
    when READ =>
      -- empty
      
    when BUSTURN =>
      NCE <= '1';
      NWE <= '1';
      NOE <= '1';
      
    end case;
  end process;
  
  
  --
  -- Data process
  --
  data_proc: process(fsmc_clk)
  begin
    if falling_edge(fsmc_clk) then
      if state = WRITE then
        data_lat_reg <= data_lat_reg + 1;
        data_reg <= data_lat_reg;
      end if;
    end if;
  end process;
 
  
  
END;
