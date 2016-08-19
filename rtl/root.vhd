
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
    SLAVES    : positive := 17          -- 16 BRAMs + ctl regs
    );
  port (

    FSMC_CLK_54MHZ : in    std_logic;
    FSMC_A         : in    std_logic_vector ((FSMC_AW - 1) downto 0);
    FSMC_D         : inout std_logic_vector ((FSMC_DW - 1) downto 0);
    FSMC_NOE       : in    std_logic;
    FSMC_NWE       : in    std_logic;
    FSMC_NCE       : in    std_logic;
    --FSMC_NBL : in    std_logic_vector (1 downto 0);

    -- Control
    F_MATH_RDY_S  : out std_logic;
    F_FPGA_RDY_S  : out std_logic;
    F_MMU_ERR_S   : out std_logic;
    F_MATH_ERR_S  : out std_logic;
    F_ACK_S       : out std_logic;
    F_DBG_S       : out std_logic;
    S_MATH_RST_F  : in  std_logic;
    S_BRAM_FILL_F : in  std_logic;

    LED : out std_logic_vector (7 downto 0);

    -- STM <-> FPGA
    S_TX_F  : in  std_logic_vector (5 downto 2);
    F_S_RX  : out std_logic_vector (5 downto 2);
    S_RST_F : in  std_logic_vector (3 downto 0);
    F_PPS_S : out std_logic_vector (3 downto 0);

    -- GNSS <-> FPGA
    G1_TX_F    : in  std_logic_vector (2 downto 0);
    F_G1_RX    : out std_logic_vector (2 downto 0);
    G1_PPS_F   : in  std_logic;
    F_RST_G1   : out std_logic;
    G1_INT_B_F : in  std_logic;
    G1_PV_F    : in  std_logic;
    F_G1_EV    : out std_logic;
    G1_VARF_F  : in  std_logic;

    G2_TX_F    : in  std_logic_vector (2 downto 0);
    F_G2_RX    : out std_logic_vector (2 downto 0);
    G2_PPS_F   : in  std_logic;
    F_RST_G2   : out std_logic;
    G2_INT_B_F : in  std_logic;
    G2_PV_F    : in  std_logic;
    F_G2_EV    : out std_logic;
    G2_VARF_F  : in  std_logic;

    G3_TX_F    : in  std_logic_vector (2 downto 0);
    F_G3_RX    : out std_logic_vector (2 downto 0);
    G3_PPS_F   : in  std_logic;
    F_RST_G3   : out std_logic;
    G3_INT_B_F : in  std_logic;
    G3_PV_F    : in  std_logic;
    F_G3_EV    : out std_logic;
    G3_VARF_F  : in  std_logic;

    -- ARINC
    AR_IO : out std_logic_vector (31 downto 0);

    -- PPS out
    F_PPSp_O : out std_logic;
    F_PPSn_O : out std_logic
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
      mmu_int => F_MMU_ERR_S,
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
      rdy_o => F_MATH_RDY_S,
      rst_i => S_MATH_RST_F,

      clk_wb_i  => (others => clk_wb),
      clk_mul_i => clk_mul,

      bram_a  => bram_a,
      bram_di => fsmc_do_bram_di,
      bram_do => bram_do_fsmc_di,
      bram_en => bram_en,
      bram_we => bram_we
      );

  --
  -- raise ready flag for STM32
  --
  F_FPGA_RDY_S <= clk_locked;

  -- ARINC GPIO
  AR_IO <= (others => '0');

  OBUFDS_PPS : OBUFDS
    generic map (
      IOSTANDARD => "LVDS_33")
    port map (
      O  => F_PPSp_O,
      OB => F_PPSn_O,
      I  => '1'
      );

end Behavioral;

