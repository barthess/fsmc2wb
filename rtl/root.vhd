
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

use work.mtrx_math_constants.all;


entity AA_root is
  generic (
    FSMC_AW   : positive := 20;
    FSMC_DW   : positive := 32;
    BRAM_A_AW : positive := 11;
    BRAMS     : positive := 16
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

  -- wires for BRAMs, ctl_regs, memtest, LEDs
  signal slave_a          : std_logic_vector (BRAM_A_AW-1 downto 0);
  signal fsmc_do_slave_di : std_logic_vector (FSMC_DW-1 downto 0);
  signal slave_do_fsmc_di : std_logic_vector ((SL_LED+1)*FSMC_DW-1 downto 0);
  signal slave_en         : std_logic_vector (SL_LED downto 0);
  signal slave_we         : std_logic_vector (0 downto 0);

  signal memtest_bram_a  : std_logic_vector (BRAM_A_AW-1 downto 0);
  signal memtest_bram_di : std_logic_vector (FSMC_DW-1 downto 0);  -- memory in
  signal memtest_bram_do : std_logic_vector (FSMC_DW-1 downto 0);  -- memory out
  signal memtest_bram_en : std_logic;
  signal memtest_bram_we : std_logic_vector (0 downto 0);

  signal led_reg : std_logic_vector (7 downto 0);

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
  fsmc2slaves : entity work.fmc2slaves
    generic map (
      FMC_AW   => FSMC_AW,
      BRAM_AW  => BRAM_A_AW,
      DW       => FSMC_DW,
      BRAMS    => BRAMS,
      CTL_REGS => 6)
    port map (
      rst      => not clk_locked,
      mmu_int  => F_MMU_ERR_S,
      fmc_clk  => clk_wb,
      fmc_a    => FSMC_A,
      fmc_d    => FSMC_D,
      fmc_noe  => FSMC_NOE,
      fmc_nwe  => FSMC_NWE,
      fmc_ne   => FSMC_NCE,
      slave_a  => slave_a,
      slave_do => fsmc_do_slave_di,
      slave_di => slave_do_fsmc_di,
      slave_en => slave_en,
      slave_we => slave_we);


  --
  -- multiplicator with integrated BRAMs
  --
  wb_mtrx : entity work.wb_mtrx
    generic map (
      WB_DW  => FSMC_DW,
      SLAVES => BRAMS+1                 -- brams + ctl_regs
      )
    port map (
      rdy_o => F_MATH_RDY_S,
      rst_i => S_MATH_RST_F,

      clk_wb_i  => (others => clk_wb),
      clk_mul_i => clk_mul,

      bram_a  => slave_a,
      bram_di => fsmc_do_slave_di,
      bram_do => slave_do_fsmc_di ((SL_MATH_CTL+1)*FSMC_DW-1 downto 0),
      bram_en => slave_en (SL_MATH_CTL downto 0),
      bram_we => slave_we
      );



  bram_memtest : entity work.bram_memtest
    port map (
      -- port A to fsmc2slaves
      addra => slave_a,
      dina  => fsmc_do_slave_di,
      douta => slave_do_fsmc_di ((SL_MEMTEST+1)*FSMC_DW-1 downto SL_MEMTEST*FSMC_DW),
      wea   => slave_we,
      ena   => slave_en(SL_MEMTEST),
      clka  => clk_wb,

      -- port B to memtest assistant
      addrb => memtest_bram_a,
      dinb  => memtest_bram_di,
      doutb => memtest_bram_do,
      enb   => memtest_bram_en,
      web   => memtest_bram_we,
      clkb  => clk_wb
      );

  memtest_assist : entity work.memtest_assist
    generic map (
      AW => BRAM_A_AW,
      DW => FSMC_DW
      )
    port map (
      clk_i => clk_wb,

      BRAM_FILL => S_BRAM_FILL_F,
      BRAM_DBG  => F_DBG_S,

      BRAM_CLK => open,
      BRAM_A   => memtest_bram_a,
      BRAM_DI  => memtest_bram_do,      -- memory out
      BRAM_DO  => memtest_bram_di,      -- memory in
      BRAM_EN  => memtest_bram_en,
      BRAM_WE  => memtest_bram_we
      );



  LED <= led_reg;

  led_proc : process (clk_wb) is
  begin
    if rising_edge(clk_wb) then
      if (slave_en(SL_LED) = '1' and slave_a = "00000000000") then
        if (slave_we = "1") then
          led_reg <= fsmc_do_slave_di (7 downto 0);
        else
          slave_do_fsmc_di ((SL_LED+1)*FSMC_DW-1 downto SL_LED*FSMC_DW) <= X"000000" & led_reg;
        end if;
      end if;
    end if;
  end process;

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

