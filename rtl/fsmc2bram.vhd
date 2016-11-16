----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:43:03 07/21/2015 
-- Design Name: 
-- Module Name:    fsmc_glue - A_fsmc_glue 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsmc2bram is
  Generic (
    AW : positive;
    DW : positive;
    AW_SLAVE : positive;
    -- Data latency cycles. It is STM32 dependant constant.
    -- Note: this core does not account this constant during read phase.
    -- the read latency depends only on data path latency. 
    -- Set this value to 3 if your BRAMs output are not registered, 
    -- add 1 latency cycle on every register level.
    DATLAT_LEN : positive
  );
	Port (
    clk : in std_logic; -- extenal clock generated by FSMC bus
    mmu_int : out std_logic;
    
    A : in STD_LOGIC_VECTOR (AW-1 downto 0);
    D : inout STD_LOGIC_VECTOR (DW-1 downto 0);
    NWE : in STD_LOGIC;
    NOE : in STD_LOGIC;
    NCE : in STD_LOGIC;
    
    bram_a   : out STD_LOGIC_VECTOR (AW_SLAVE-1 downto 0);
    bram_di  : in  STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_do  : out STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_we  : out STD_LOGIC_VECTOR (0 downto 0);
    bram_clk : out std_logic
  );
  
end fsmc2bram;



-----------------------------------------------------------------------------

architecture beh of fsmc2bram is

  type state_t is (IDLE, DATLAT, MOSI, MISO);
  signal state : state_t := IDLE;
  
  signal acnt : unsigned(AW_SLAVE-1 downto 0) := (others => 'U');
  signal areg : std_logic_vector(AW-1 downto 0);
  signal nwereg : std_logic := '1'; 
  signal ncereg : std_logic := '1';
  signal bram_we_reg : std_logic_vector(0 downto 0) := "0";
  signal dreg_bram2fsmc : std_logic_vector(DW-1 downto 0) := (others => 'X');
  
begin

  --
  -- permanent connections
  --
  bram_clk <= clk;
  bram_a <= std_logic_vector(acnt);
  D <= dreg_bram2fsmc when (NCE = '0' and NOE = '0') else (others => 'Z');
  bram_we <= "1" when (state = MOSI and nwereg = '0') else "0";
  
  --
  --
  --
  port_registering_proc : process(clk) is
  begin
    if rising_edge(clk) then
      dreg_bram2fsmc <= bram_di;
      bram_do <= D;
      areg <= A;
      nwereg <= NWE;
      ncereg <= NCE;
    end if;
  end process;

  --
  --
  --
  mmu_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if (ncereg = '0') then
        mmu_int <= or_reduce(areg(AW-1 downto AW_SLAVE));
      else
        mmu_int <= '0';
      end if;
    end if;
  end process;
  
  --
  --
  --
  fsmc_state_proc : process(clk) is
    variable latcnt : unsigned(2 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      if ncereg = '1' then
        state <= IDLE;
        latcnt := (others => '0');
      else
        case state is
        when IDLE =>
          acnt <= unsigned(areg(AW_SLAVE-1 downto 0));
          if (nwereg = '0') then
            latcnt := to_unsigned(DATLAT_LEN, latcnt'length);
            state <= DATLAT;
          else
            state <= MISO;
          end if;
          
        when DATLAT =>
          latcnt := latcnt - 1;
          if '0' = or_reduce(std_logic_vector(latcnt)) then
            state <= MOSI;
          end if;

        when MISO =>
          acnt <= acnt + 1;
          
        when MOSI =>
          acnt <= acnt + 1;

        end case;
      end if; -- NCE
    end if; -- clk
  end process;


 
end beh;




