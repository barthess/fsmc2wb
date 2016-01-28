
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity sp6_gtp_top is
  port
    (
      REFCLK0_IN : in std_logic;

      GTPRESET_IN   : in  std_logic_vector (1 downto 0);
      PLLLKDET_OUT  : out std_logic_vector (1 downto 0);
      RESETDONE_OUT : out std_logic_vector (1 downto 0);

      -- Parallel clock (8 bit)
      RXUSRCLK8_0_OUT : out std_logic;  -- RXRECCLK GTP 0
      RXUSRCLK8_1_OUT : out std_logic;  -- RXRECCLK GTP 1
      TXUSRCLK8_OUT   : out std_logic;

      -- RX ports
      RXDATA0_OUT : out std_logic_vector (7 downto 0);  -- GTP 0
      RXDATA1_OUT : out std_logic_vector (7 downto 0);  -- GTP 1   
      RXN_IN      : in  std_logic_vector(1 downto 0);
      RXP_IN      : in  std_logic_vector(1 downto 0);

      RXCHARISCOMMA_OUT   : out std_logic_vector (1 downto 0);
      RXCHARISK_OUT       : out std_logic_vector (1 downto 0);
      RXBYTEISALIGNED_OUT : out std_logic_vector (1 downto 0);
      RXBYTEREALIGN_OUT   : out std_logic_vector (1 downto 0);
      RXBUFSTATUS_OUT     : out std_logic_vector (5 downto 0);

      -- TX ports
      TXDATA0_IN : in  std_logic_vector (7 downto 0);  -- GTP 0
      TXDATA1_IN : in  std_logic_vector (7 downto 0);  -- GTP 1    
      TXN_OUT    : out std_logic_vector(1 downto 0);
      TXP_OUT    : out std_logic_vector(1 downto 0);

      TXCHARISK_IN    : in  std_logic_vector (1 downto 0);
      TXBUFSTATUS_OUT : out std_logic_vector (3 downto 0)
      );
end sp6_gtp_top;

architecture RTL of sp6_gtp_top is
  component sp6_gtp
    generic
      (
        -- Simulation attributes  
        WRAPPER_SIM_GTPRESET_SPEEDUP : integer := 0;  -- Set to 1 to speed up sim reset
        WRAPPER_CLK25_DIVIDER_0      : integer := 4;
        WRAPPER_CLK25_DIVIDER_1      : integer := 4;
        WRAPPER_PLL_DIVSEL_FB_0      : integer := 5;
        WRAPPER_PLL_DIVSEL_FB_1      : integer := 5;
        WRAPPER_PLL_DIVSEL_REF_0     : integer := 2;
        WRAPPER_PLL_DIVSEL_REF_1     : integer := 2;
        WRAPPER_SIMULATION           : integer := 0  -- Set to 1 for simulation  
        );
    port
      (
        --------------------------------- PLL Ports --------------------------------
        TILE0_CLK00_IN             : in  std_logic;
        TILE0_CLK01_IN             : in  std_logic;
        TILE0_GTPRESET0_IN         : in  std_logic;
        TILE0_GTPRESET1_IN         : in  std_logic;
        TILE0_PLLLKDET0_OUT        : out std_logic;
        TILE0_PLLLKDET1_OUT        : out std_logic;
        TILE0_RESETDONE0_OUT       : out std_logic;
        TILE0_RESETDONE1_OUT       : out std_logic;
        ----------------------- Receive Ports - 8b10b Decoder ----------------------
        TILE0_RXCHARISCOMMA0_OUT   : out std_logic;
        TILE0_RXCHARISCOMMA1_OUT   : out std_logic;
        TILE0_RXCHARISK0_OUT       : out std_logic;
        TILE0_RXCHARISK1_OUT       : out std_logic;
        TILE0_RXDISPERR0_OUT       : out std_logic;
        TILE0_RXDISPERR1_OUT       : out std_logic;
        TILE0_RXNOTINTABLE0_OUT    : out std_logic;
        TILE0_RXNOTINTABLE1_OUT    : out std_logic;
        --------------- Receive Ports - Comma Detection and Alignment --------------
        TILE0_RXBYTEISALIGNED0_OUT : out std_logic;
        TILE0_RXBYTEISALIGNED1_OUT : out std_logic;
        TILE0_RXBYTEREALIGN0_OUT   : out std_logic;
        TILE0_RXBYTEREALIGN1_OUT   : out std_logic;
        TILE0_RXENMCOMMAALIGN0_IN  : in  std_logic;
        TILE0_RXENMCOMMAALIGN1_IN  : in  std_logic;
        TILE0_RXENPCOMMAALIGN0_IN  : in  std_logic;
        TILE0_RXENPCOMMAALIGN1_IN  : in  std_logic;
        ------------------- Receive Ports - RX Data Path interface -----------------
        TILE0_RXDATA0_OUT          : out std_logic_vector(7 downto 0);
        TILE0_RXDATA1_OUT          : out std_logic_vector(7 downto 0);
        TILE0_RXRECCLK0_OUT        : out std_logic;
        TILE0_RXRECCLK1_OUT        : out std_logic;
        TILE0_RXUSRCLK0_IN         : in  std_logic;
        TILE0_RXUSRCLK1_IN         : in  std_logic;
        TILE0_RXUSRCLK20_IN        : in  std_logic;
        TILE0_RXUSRCLK21_IN        : in  std_logic;
        ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        TILE0_RXN0_IN              : in  std_logic;
        TILE0_RXN1_IN              : in  std_logic;
        TILE0_RXP0_IN              : in  std_logic;
        TILE0_RXP1_IN              : in  std_logic;
        ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
        TILE0_RXBUFSTATUS0_OUT     : out std_logic_vector(2 downto 0);
        TILE0_RXBUFSTATUS1_OUT     : out std_logic_vector(2 downto 0);
        ---------------------------- TX/RX Datapath Ports --------------------------
        TILE0_GTPCLKOUT0_OUT       : out std_logic_vector(1 downto 0);
        TILE0_GTPCLKOUT1_OUT       : out std_logic_vector(1 downto 0);
        ------------------- Transmit Ports - 8b10b Encoder Control -----------------
        TILE0_TXCHARISK0_IN        : in  std_logic;
        TILE0_TXCHARISK1_IN        : in  std_logic;
        --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
        TILE0_TXBUFSTATUS0_OUT     : out std_logic_vector(1 downto 0);
        TILE0_TXBUFSTATUS1_OUT     : out std_logic_vector(1 downto 0);
        ------------------ Transmit Ports - TX Data Path interface -----------------
        TILE0_TXDATA0_IN           : in  std_logic_vector(7 downto 0);
        TILE0_TXDATA1_IN           : in  std_logic_vector(7 downto 0);
        TILE0_TXUSRCLK0_IN         : in  std_logic;
        TILE0_TXUSRCLK1_IN         : in  std_logic;
        TILE0_TXUSRCLK20_IN        : in  std_logic;
        TILE0_TXUSRCLK21_IN        : in  std_logic;
        --------------- Transmit Ports - TX Driver and OOB signalling --------------
        TILE0_TXN0_OUT             : out std_logic;
        TILE0_TXN1_OUT             : out std_logic;
        TILE0_TXP0_OUT             : out std_logic;
        TILE0_TXP1_OUT             : out std_logic
        );
  end component;

  -- PLL
  signal tile0_plllkdet0_i     : std_logic;
  signal tile0_plllkdet1_i     : std_logic;
  ----------------------- Receive Ports - 8b10b Decoder ----------------------
  signal tile0_rxdisperr0_i    : std_logic;
  signal tile0_rxdisperr1_i    : std_logic;
  signal tile0_rxnotintable0_i : std_logic;
  signal tile0_rxnotintable1_i : std_logic;
  ------------------- Receive Ports - RX Data Path interface -----------------
  signal tile0_rxrecclk0_i     : std_logic;
  signal tile0_rxrecclk1_i     : std_logic;
  ---------------------------- TX/RX Datapath Ports --------------------------
  signal tile0_gtpclkout0_i    : std_logic_vector(1 downto 0);
  signal tile0_gtpclkout1_i    : std_logic_vector(1 downto 0);

  ----------------------------- User Clocks ---------------------------------
  signal tile0_gtp0_refclk_i          : std_logic;
  signal tile0_txusrclk0_i            : std_logic;
  signal tile0_rxusrclk0_i            : std_logic;
  signal tile0_rxusrclk1_i            : std_logic;
  signal gtpclkout0_0_pll0_locked_i   : std_logic;
  signal gtpclkout0_0_pll0_reset_i    : std_logic;
  signal tile0_gtpclkout0_0_to_cmt_i  : std_logic;
  signal pll0_fb_out_i                : std_logic;
  signal tile0_gtpclkout0_1_to_bufg_i : std_logic;
  signal tile0_gtpclkout1_1_to_bufg_i : std_logic;

begin

  PLLLKDET_OUT <= tile0_plllkdet1_i & tile0_plllkdet0_i;

  RXUSRCLK8_0_OUT <= tile0_rxusrclk0_i;
  RXUSRCLK8_1_OUT <= tile0_rxusrclk1_i;
  TXUSRCLK8_OUT   <= tile0_txusrclk0_i;

  gtpclkout0_0_pll0_bufio2_i : BUFIO2
    generic map
    (
      DIVIDE        => 1,
      DIVIDE_BYPASS => true
      )
    port map
    (
      I            => tile0_gtpclkout0_i(0),
      DIVCLK       => tile0_gtpclkout0_0_to_cmt_i,
      IOCLK        => open,
      SERDESSTROBE => open
      );

  gtpclkout0_0_bufg0_i : BUFG           -- no clock division
    port map
    (
      I => tile0_gtpclkout0_0_to_cmt_i,
      O => tile0_txusrclk0_i
      );

  gtpclkout0_0_pll0_reset_i <= not tile0_plllkdet0_i;

  gtpclkout0_1_bufg1_bufio2_i : BUFIO2
    generic map
    (
      DIVIDE        => 1,
      DIVIDE_BYPASS => true
      )
    port map
    (
      I            => tile0_gtpclkout0_i(1),
      DIVCLK       => tile0_gtpclkout0_1_to_bufg_i,
      IOCLK        => open,
      SERDESSTROBE => open
      );

  gtpclkout0_1_bufg1_i : BUFG
    port map
    (
      I => tile0_gtpclkout0_1_to_bufg_i,
      O => tile0_rxusrclk0_i
      );

  gtpclkout1_1_bufg2_bufio2_i : BUFIO2
    generic map
    (
      DIVIDE        => 1,
      DIVIDE_BYPASS => true
      )
    port map
    (
      I            => tile0_gtpclkout1_i(1),
      DIVCLK       => tile0_gtpclkout1_1_to_bufg_i,
      IOCLK        => open,
      SERDESSTROBE => open
      );

  gtpclkout1_1_bufg2_i : BUFG
    port map
    (
      I => tile0_gtpclkout1_1_to_bufg_i,
      O => tile0_rxusrclk1_i
      );

  sp6_gtp_i : sp6_gtp
    generic map
    (
      WRAPPER_SIM_GTPRESET_SPEEDUP => 0,
      WRAPPER_CLK25_DIVIDER_0      => 10,
      WRAPPER_CLK25_DIVIDER_1      => 10,
      WRAPPER_PLL_DIVSEL_FB_0      => 2,
      WRAPPER_PLL_DIVSEL_FB_1      => 2,
      WRAPPER_PLL_DIVSEL_REF_0     => 1,
      WRAPPER_PLL_DIVSEL_REF_1     => 1,
      WRAPPER_SIMULATION           => 0
      )
    port map
    (
      --------------------------------- PLL Ports --------------------------------
      TILE0_CLK00_IN             => REFCLK0_IN,
      TILE0_CLK01_IN             => REFCLK0_IN,
      TILE0_GTPRESET0_IN         => GTPRESET_IN(0),
      TILE0_GTPRESET1_IN         => GTPRESET_IN(1),
      TILE0_PLLLKDET0_OUT        => tile0_plllkdet0_i,
      TILE0_PLLLKDET1_OUT        => tile0_plllkdet1_i,
      TILE0_RESETDONE0_OUT       => RESETDONE_OUT(0),
      TILE0_RESETDONE1_OUT       => RESETDONE_OUT(1),
      ----------------------- Receive Ports - 8b10b Decoder ----------------------
      TILE0_RXCHARISCOMMA0_OUT   => RXCHARISCOMMA_OUT(0),
      TILE0_RXCHARISCOMMA1_OUT   => RXCHARISCOMMA_OUT(1),
      TILE0_RXCHARISK0_OUT       => RXCHARISK_OUT(0),
      TILE0_RXCHARISK1_OUT       => RXCHARISK_OUT(1),
      TILE0_RXDISPERR0_OUT       => tile0_rxdisperr0_i,
      TILE0_RXDISPERR1_OUT       => tile0_rxdisperr1_i,
      TILE0_RXNOTINTABLE0_OUT    => tile0_rxnotintable0_i,
      TILE0_RXNOTINTABLE1_OUT    => tile0_rxnotintable1_i,
      --------------- Receive Ports - Comma Detection and Alignment --------------
      TILE0_RXBYTEISALIGNED0_OUT => RXBYTEISALIGNED_OUT(0),
      TILE0_RXBYTEISALIGNED1_OUT => RXBYTEISALIGNED_OUT(1),
      TILE0_RXBYTEREALIGN0_OUT   => RXBYTEREALIGN_OUT(0),
      TILE0_RXBYTEREALIGN1_OUT   => RXBYTEREALIGN_OUT(1),
      TILE0_RXENMCOMMAALIGN0_IN  => '1',
      TILE0_RXENMCOMMAALIGN1_IN  => '1',
      TILE0_RXENPCOMMAALIGN0_IN  => '1',
      TILE0_RXENPCOMMAALIGN1_IN  => '1',
      ------------------- Receive Ports - RX Data Path interface -----------------
      TILE0_RXDATA0_OUT          => RXDATA0_OUT,
      TILE0_RXDATA1_OUT          => RXDATA1_OUT,
      TILE0_RXRECCLK0_OUT        => tile0_rxrecclk0_i,
      TILE0_RXRECCLK1_OUT        => tile0_rxrecclk1_i,
      TILE0_RXUSRCLK0_IN         => tile0_rxusrclk0_i,
      TILE0_RXUSRCLK1_IN         => tile0_rxusrclk1_i,
      TILE0_RXUSRCLK20_IN        => tile0_rxusrclk0_i,
      TILE0_RXUSRCLK21_IN        => tile0_rxusrclk1_i,
      ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      TILE0_RXN0_IN              => RXN_IN(0),
      TILE0_RXN1_IN              => RXN_IN(1),
      TILE0_RXP0_IN              => RXP_IN(0),
      TILE0_RXP1_IN              => RXP_IN(1),
      ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
      TILE0_RXBUFSTATUS0_OUT     => RXBUFSTATUS_OUT(2 downto 0),
      TILE0_RXBUFSTATUS1_OUT     => RXBUFSTATUS_OUT(5 downto 3),
      ---------------------------- TX/RX Datapath Ports --------------------------
      TILE0_GTPCLKOUT0_OUT       => tile0_gtpclkout0_i,
      TILE0_GTPCLKOUT1_OUT       => tile0_gtpclkout1_i,
      ------------------- Transmit Ports - 8b10b Encoder Control -----------------
      TILE0_TXCHARISK0_IN        => TXCHARISK_IN(0),
      TILE0_TXCHARISK1_IN        => TXCHARISK_IN(1),
      --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
      TILE0_TXBUFSTATUS0_OUT     => TXBUFSTATUS_OUT(1 downto 0),
      TILE0_TXBUFSTATUS1_OUT     => TXBUFSTATUS_OUT(3 downto 2),
      ------------------ Transmit Ports - TX Data Path interface -----------------
      TILE0_TXDATA0_IN           => TXDATA0_IN,
      TILE0_TXDATA1_IN           => TXDATA1_IN,
      TILE0_TXUSRCLK0_IN         => tile0_txusrclk0_i,
      TILE0_TXUSRCLK1_IN         => tile0_txusrclk0_i,
      TILE0_TXUSRCLK20_IN        => tile0_txusrclk0_i,
      TILE0_TXUSRCLK21_IN        => tile0_txusrclk0_i,
      --------------- Transmit Ports - TX Driver and OOB signalling --------------
      TILE0_TXN0_OUT             => TXN_OUT(0),
      TILE0_TXN1_OUT             => TXN_OUT(1),
      TILE0_TXP0_OUT             => TXP_OUT(0),
      TILE0_TXP1_OUT             => TXP_OUT(1)
      );
end RTL;
