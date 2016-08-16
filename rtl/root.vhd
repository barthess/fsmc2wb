
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- Non standard library from synopsis (for dev_null functions)
use ieee.std_logic_misc.all;


entity AA_root is
  generic (
    FSMC_AW   : positive := 20;
    FSMC_DW   : positive := 32;
    BRAM_A_AW : positive := 11;
    SLAVES    : positive := 17           -- 16 BRAMs + ctl regs
    );
  port (
    FSMC_CLK_54MHZ : in std_logic;

    FSMC_A   : in    std_logic_vector ((FSMC_AW - 1) downto 0);
    FSMC_D   : inout std_logic_vector ((FSMC_DW - 1) downto 0);
    FSMC_NBL : in    std_logic_vector (1 downto 0);
    FSMC_NOE : in    std_logic;
    FSMC_NWE : in    std_logic;
    FSMC_NCE : in    std_logic;

    STM_IO_MATH_RDY_OUT   : out std_logic;
    STM_IO_MATH_RST_IN    : in  std_logic;
    STM_IO_WB_ERR_OUT     : out std_logic;
    STM_IO_WB_ACK_OUT     : out std_logic;
    STM_IO_BRAM_AUTO_FILL : in  std_logic;
    STM_IO_BRAM_DBG_OUT   : out std_logic;
    STM_IO_FPGA_RDY       : out std_logic;
    STM_IO_MMU_ERR_OUT    : out std_logic;

    LED_LINE : out std_logic_vector (7 downto 0);

    -- GNSS UART ports between FPGA and STM32
    STM32_UART_TO_FPGA       : in  std_logic_vector (3 downto 0);
    STM32_UART_FROM_FPGA     : out std_logic_vector (3 downto 0);
    STM32_GNSS_NRST_TO_FPGA  : in  std_logic_vector (3 downto 0);
    STM32_GNSS_PPS_FROM_FPGA : out std_logic_vector (3 downto 0);

    -- ports for GNSS receivers (named relative to GNSS)
    GNSS_NRST_FROM_FPGA : out std_logic_vector (3 downto 0);
    GNSS_UART_TO_FPGA   : in  std_logic_vector (3 downto 0);
    GNSS_UART_FROM_FPGA : out std_logic_vector (3 downto 0);
    GNSS_PPS_TO_FPGA    : in  std_logic_vector (3 downto 0);  -- NOTE: 4 inputs
    GNSS_PPS_FROM_FPGA  : out std_logic_vector (2 downto 0);  -- NOTE: only 3 outputs needed

    -- ARINC GPIO
    ARINC_GPIO : out std_logic_vector (31 downto 0)
    );
end AA_root;


architecture Behavioral of AA_root is

-- clock wires
  signal clk_200mhz : std_logic;
  signal clk_150mhz : std_logic;
  signal clk_100mhz : std_logic;
  signal clk_50mhz  : std_logic;
  signal clk_locked : std_logic;
  signal clk_wb     : std_logic;
  signal clk_mul    : std_logic;

  -- wires between fsmc2bram and wb_mtrx
  signal bram_a          : std_logic_vector (BRAM_A_AW-1 downto 0);
  signal fsmc_do_bram_di : std_logic_vector (FSMC_DW-1 downto 0);
  signal bram_do_fsmc_di : std_logic_vector (SLAVES*FSMC_DW-1 downto 0);
  signal bram_en         : std_logic_vector (SLAVES-1 downto 0);
  signal bram_we         : std_logic_vector (0 downto 0);


begin

  BUFG_inst : BUFG
    port map (
      O => clk_wb,                      -- 1-bit output: Clock buffer output
      I => FSMC_CLK_54MHZ               -- 1-bit input: Clock buffer input
      );

  --
  -- clock sources
  --
  clk_src : entity work.clk_src
    port map (
      CLK_IN1  => clk_wb,
      CLK_OUT1 => clk_200mhz,
      LOCKED   => clk_locked
      );
  clk_mul <= clk_200mhz;


  -- bridge
  fsmc2bram : entity work.fmc2bram
    generic map (
      FMC_AW   => FSMC_AW,
      BRAM_AW  => BRAM_A_AW,
      DW       => FSMC_DW,
      BRAMS    => SLAVES,
      CTL_REGS => 6)
    port map (
      rst     => not clk_locked,
      mmu_int => STM_IO_MMU_ERR_OUT,
      fmc_clk => clk_wb,
      fmc_a   => FSMC_A,
      fmc_d   => FSMC_D,
      fmc_noe => FSMC_NOE,
      fmc_nwe => FSMC_NWE,
      fmc_ne  => FSMC_NCE,
      bram_a  => bram_a,
      bram_do => fsmc_do_bram_di,
      bram_di => bram_do_fsmc_di,
      bram_en => bram_en,
      bram_we => bram_we);


  --
  -- multiplicator with integrated BRAMs
  --
  wb_mtrx : entity work.wb_mtrx
    generic map (
      WB_DW  => FSMC_DW,
      SLAVES => SLAVES
      )
    port map (
      rdy_o => STM_IO_MATH_RDY_OUT,
      rst_i => STM_IO_MATH_RST_IN,

      clk_wb_i  => (others => clk_wb),
      clk_mul_i => clk_mul,

      bram_a  => bram_a,
      bram_di => fsmc_do_bram_di,
      bram_do => bram_do_fsmc_di,
      bram_en => bram_en,
      bram_we => bram_we
      );

  --
  -- raize ready flag for STM32
  --
  STM_IO_FPGA_RDY <= clk_locked;

  GNSS_UART_FROM_FPGA      <= STM32_UART_TO_FPGA;
  STM32_UART_FROM_FPGA     <= GNSS_UART_TO_FPGA;
  GNSS_NRST_FROM_FPGA      <= STM32_GNSS_NRST_TO_FPGA;
  STM32_GNSS_PPS_FROM_FPGA <= GNSS_PPS_TO_FPGA;
  GNSS_PPS_FROM_FPGA       <= (others => '0');

  -- ARINC GPIO
  ARINC_GPIO <= (others => '0');

  --
  -- warning suppressors and other trash
  --
--  DEV_NULL_BANK0 <= '1';--FSMC_NBL(0) or FSMC_NBL(1);
--  DEV_NULL_BANK1 <= '1';

end Behavioral;

