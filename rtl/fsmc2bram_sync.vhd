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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsmc2bram_sync is
  Generic (
    AW_FSMC : positive;     -- total FSMC address width
    DW : positive;          -- data witdth
    AW_SLAVE : positive     -- actually used address lines starts from
  );
	Port (
    clk : in std_logic; -- extenal clock generated by FSMC bus
    mmu_err : out std_logic;
    
    A : in STD_LOGIC_VECTOR (AW_FSMC-1 downto 0);
    D : inout STD_LOGIC_VECTOR (DW-1 downto 0);
    NWE : in STD_LOGIC;
    NOE : in STD_LOGIC;
    NCE : in STD_LOGIC;
    
    bram_a   : out STD_LOGIC_VECTOR (AW_SLAVE-1 downto 0);
    bram_di  : in  STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_do  : out STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_ce  : out STD_LOGIC;
    bram_we  : out STD_LOGIC_VECTOR (0 downto 0);
    bram_clk : out std_logic
  );
  
  --
  -- because you can not define constants here
  --
  function SLAVE_MSB return positive is
  begin
    return AW_SLAVE + LSB_UNUSED - 1;
  end SLAVE_MSB;
  
  --
  -- just cut out unused lines from address bus
  --
  function address2cnt(A : in std_logic_vector(AW_FSMC-1 downto 0)) return natural is
  begin
    return to_integer(unsigned(A(SLAVE_MSB downto LSB_UNUSED)));
  end address2cnt;

  --
  -- MMU check routine. Must be called when addres sampled
  --
  function mmu_check(A : in std_logic_vector(AW_FSMC - 1 downto 0)) return std_logic is
    constant high_mask : std_logic_vector(AW_FSMC - AW_SLAVE - LSB_UNUSED downto 0) := (others => '0');
    constant low_mask  : std_logic_vector(LSB_UNUSED - 1 downto 0) := (others => '0');
  begin
    if (A(AW_FSMC-1 downto SLAVE_MSB + 1) > high_mask) or (A(LSB_UNUSED-1 downto 0) > low_mask) then
      return '1';
    else
      return '0';
    end if;
  end mmu_check;

end fsmc2bram_sync;



-----------------------------------------------------------------------------

architecture beh of fsmc2bram_sync is

  type state_t is (IDLE, ADSET, WRITE, READ);
  signal state : state_t := IDLE;
  signal a_cnt : natural range 0 to 2**(AW_SLAVE) - 1 := 0;

begin

  -- connect permanent signals
  bram_clk <= clk;
  --bram_a   <= a_cnt;
  bram_a <= std_logic_vector(to_unsigned(a_cnt, AW_SLAVE));
  
  -- coonect 3-state data bus
  D <= bram_di when (NCE = '0' and NOE = '0') else (others => 'Z');
  bram_do <= D;

  --
  --
  --
  fsmc_mmu_process : process(clk) is
  begin
    if rising_edge(clk) then
      if (NCE = '0') then
        mmu_err <= mmu_check(A);
      end if; -- NCE
    end if; -- clk
  end process;
  
  --
  --
  --
  fsmc_main_process : process(clk) is
  begin
    if rising_edge(clk) then
      if (NCE = '0') then
        case state is
        when IDLE =>
          a_cnt <= address2cnt(A);
          if (NWE = '0') then
            state <= ADSET;
          else
            state <= READ;
            bram_ce <= '1';
          end if;
          
        when ADSET =>
          state <= WRITE;
          
        when READ =>
          a_cnt <= a_cnt + 1;
          
        when WRITE =>
          bram_ce <= '1';
          bram_we <= "1";
          a_cnt <= a_cnt + 1;
        end case;
        
      else 
        state <= IDLE;
      end if; -- NCE
    end if; -- clk
  end process;


  -- main process
--  process(clk, NCE) begin
--    if (NCE = '1') then
--      bram_ce <= '0';
--      bram_we <= "0";
--      mmu_int <= '0';
--      state <= IDLE;
--
--    elsif rising_edge(clk) then
--      case state is
--      
--      when IDLE =>
--        if (NCE = '0') then
--          mmu_int <= mmu_check(A, NBL);
--          if (NWE = '0') then
--            a_cnt <= address2cnt(A) - 1;
--            state <= WRITE0;
--          else
--            state <= READ0;
--            bram_ce <= '1';
--            a_cnt <= address2cnt(A);
--          end if;
--        end if;
--
--      when READ0 =>
--        a_cnt <= a_cnt + 1;
--
--      when WRITE0 =>
--        state <= WRITE1;
--  
--      when WRITE1 =>
--        bram_ce <= '1';
--        if USENBL = '1' then
--          bram_we <= not NBL;
--        else
--          bram_we <= "1";
--        end if;
--        a_cnt <= a_cnt + 1;
--
--      end case;
--    end if;
--  end process;
end beh;




