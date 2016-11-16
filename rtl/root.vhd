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
--use ieee.std_logic_misc.all;

use work.mtrx_math_constants.all;


entity AA_root is
  generic (
    FSMC_AW       : positive := 20;
    FSMC_DW       : positive := 32;
    BRAM_A_AW     : positive := 11;
    BRAMS         : positive := 16
    );
  port (

    FSMC_CLK       : in    std_logic;
    FSMC_A         : in    std_logic_vector ((FSMC_AW - 1) downto 0);
    FSMC_D         : inout std_logic_vector ((FSMC_DW - 1) downto 0);
    FSMC_NOE       : in    std_logic;
    FSMC_NWE       : in    std_logic;
    FSMC_NCE       : in    std_logic;

    -- Control
    F_MATH_RDY_S  : out std_logic;
    F_FPGA_RDY_S  : out std_logic;
    F_MMU_ERR_S   : out std_logic;
    F_MATH_ERR_S  : out std_logic;
    F_ACK_S       : out std_logic;
    F_DBG_S       : out std_logic;
    S_MATH_RST_F  : in  std_logic;
    S_BRAM_FILL_F : in  std_logic;

    LED_G : out std_logic_vector (3 downto 0);
    LED_R : out std_logic_vector (3 downto 0);
    
    -- STM <-> FPGA
    S_TX_F  : in  std_logic_vector (5 downto 2);
    F_S_RX  : out std_logic_vector (5 downto 2);
    S_RST_F : in  std_logic_vector (3 downto 0);
    F_PPS_S : out std_logic_vector (3 downto 0);
    STM_DEV_NULL1 : out std_logic;
    STM_DEV_NULL2 : out std_logic_vector (0 downto 0);
    
    -- GNSS <-> FPGA
    G1_TX_F    : in  std_logic_vector (2 downto 0);
    F_G1_RX    : out std_logic_vector (2 downto 0);
    G1_PPS_F   : in  std_logic;
    F_RST_G1   : out std_logic;
    G1_INT_B_F : in  std_logic;
    G1_PV_F    : in  std_logic;
    F_G1_EV    : out std_logic;
    G1_VARF_F  : in  std_logic;
    G1_DEV_NULL: out std_logic;
    
    G2_TX_F    : in  std_logic_vector (2 downto 0);
    F_G2_RX    : out std_logic_vector (2 downto 0);
    G2_PPS_F   : in  std_logic;
    F_RST_G2   : out std_logic;
    G2_INT_B_F : in  std_logic;
    G2_PV_F    : in  std_logic;
    F_G2_EV    : out std_logic;
    G2_VARF_F  : in  std_logic;
    G2_DEV_NULL: out std_logic;
    
    G3_TX_F    : in  std_logic_vector (2 downto 0);
    F_G3_RX    : out std_logic_vector (2 downto 0);
    G3_PPS_F   : in  std_logic;
    F_RST_G3   : out std_logic;
    G3_INT_B_F : in  std_logic;
    G3_PV_F    : in  std_logic;
    F_G3_EV    : out std_logic;
    G3_VARF_F  : in  std_logic;
    G3_DEV_NULL: out std_logic;
    
    -- ARINC
    AR_IO : out std_logic_vector (31 downto 0);
    AR_THREE_STATE : out std_logic_vector(9 downto 1);

    -- PPS out
    F_PPSp_O : out std_logic
    );
end AA_root;


architecture Behavioral of AA_root is

  -- clock wires
  signal clk_200mhz : std_logic;
  signal clk_valid  : std_logic;
  signal clk_mtrx   : std_logic;
  signal clk_fsmc   : std_logic;

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

  -- wires for memspace to fsmc
  signal wire_bram_a   : std_logic_vector (12 downto 0); 
  signal wire_bram_di  : std_logic_vector (FSMC_DW-1 downto 0); 
  signal wire_bram_do  : std_logic_vector (FSMC_DW-1 downto 0); 
  signal wire_bram_ce  : std_logic; 
  signal wire_bram_we  : std_logic_vector (0 downto 0);  
  signal wire_bram_clk : std_logic; 

  signal led_red_reg : natural range 0 to 2**4 - 1 := 0;
  signal led_green_reg : natural range 0 to 2**4 - 1 := 0;
  constant led_red_divider : natural := 216000000;
  constant led_green_divider : natural := 54000000;
  signal led_red_counter : natural range 0 to 2**28 - 1 := 0;
  signal led_green_counter : natural range 0 to 2**28 - 1 := 0;
  
begin

  --
  -- clock sources
  --
  BUFG_inst : BUFG
    port map (
      O => clk_fsmc,
      I => FSMC_CLK);
  
  clk_src : entity work.clk_src
    port map (
      CLK_IN1   => FSMC_CLK,
      CLK_OUT1  => clk_200mhz,
      CLK_VALID => clk_valid,
      RESET     => S_MATH_RST_F);

  clk_mtrx <= clk_200mhz;

  --
  -- debug FSMC connections for logic analizer
  --
  LED_G(0) <= FSMC_CLK;
  LED_G(1) <= FSMC_NWE;
  LED_G(2) <= FSMC_NOE;
  LED_G(3) <= FSMC_NCE;
  
  LED_R(3) <= FSMC_A(0);
  LED_R(2) <= FSMC_A(1);
  LED_R(1) <= FSMC_D(0);
  LED_R(0) <= FSMC_D(1);
  
--LED_G <= std_logic_vector(to_unsigned(led_green_reg, 4));
--  led_green_proc : process (clk_fsmc) is
--  begin
--    if rising_edge(clk_fsmc) then
--      led_green_counter <= led_green_counter + 1;
--      if led_green_counter = led_green_divider then
--        led_green_counter <= 0;
--        led_green_reg <= led_green_reg + 1;
--      end if;
--    end if;
--  end process;
--


  STM_DEV_NULL2 <= std_logic_vector(to_unsigned(led_red_reg, 1));
  led_red_proc : process (clk_mtrx) is
  begin
    if rising_edge(clk_mtrx) then
      led_red_counter <= led_red_counter + 1;
      if led_red_counter = led_red_divider then
        led_red_counter <= 0;
        led_red_reg <= led_red_reg + 1;
      end if;
    end if;
  end process;



  F_MATH_RDY_S <= '1';
  --F_MMU_ERR_S <= '1';
  F_DBG_S <= '1';
    




  bram_memtest_inst : entity work.bram_memtest
    port map (
      addra => wire_bram_a,
      dina  => wire_bram_di,
      douta => wire_bram_do,
      wea   => wire_bram_we,
      clka  => wire_bram_clk);


  fsmc2bram_inst : entity work.fsmc2bram 
    generic map (
      AW => FSMC_AW,
      DW => FSMC_DW,
      AW_SLAVE => 13)
    port map (
      clk => clk_fsmc,
      mmu_int => F_MMU_ERR_S,
      
      A   => FSMC_A,
      D   => FSMC_D,
      NCE => FSMC_NCE,
      NOE => FSMC_NOE,
      NWE => FSMC_NWE,

      bram_a   => wire_bram_a,
      bram_di  => wire_bram_do,
      bram_do  => wire_bram_di,
      bram_we  => wire_bram_we,
      bram_clk => wire_bram_clk);





  -- bridge
--  fsmc2slaves : entity work.fmc2slaves
--  fsmc2slaves : entity work.fmc2slaves
--    generic map (
--      FMC_AW   => FSMC_AW,
--      BRAM_AW  => BRAM_A_AW,
--      DW       => FSMC_DW,
--      BRAMS    => BRAMS,
--      CTL_REGS => 6)
--    port map (
--      rst      => not clk_locked,
--      mmu_int  => F_MMU_ERR_S,
--      fmc_clk  => clk_wb,
--      fmc_a    => FSMC_A,
--      fmc_d    => FSMC_D,
--      fmc_noe  => FSMC_NOE,
--      fmc_nwe  => FSMC_NWE,
--      fmc_ne   => FSMC_NCE,
--      slave_a  => slave_a,
--      slave_do => fsmc_do_slave_di,
--      slave_di => slave_do_fsmc_di,
--      slave_en => slave_en,
--      slave_we => slave_we);


  --
  -- multiplicator with integrated BRAMs
--  --
--  wb_mtrx : entity work.wb_mtrx
--    generic map (
--      WB_DW  => FSMC_DW,
--      SLAVES => BRAMS+1                 -- brams + ctl_regs
--      )
--    port map (
--      rdy_o => F_MATH_RDY_S,
--      rst_i => S_MATH_RST_F,
--
--      clk_wb_i  => (others => clk_wb),
--      clk_mul_i => clk_mul,
--
--      bram_a  => slave_a,
--      bram_di => fsmc_do_slave_di,
--      bram_do => slave_do_fsmc_di ((SL_MATH_CTL+1)*FSMC_DW-1 downto 0),
--      bram_en => slave_en (SL_MATH_CTL downto 0),
--      bram_we => slave_we
--      );

--  bram_memtest : entity work.bram_memtest
--    port map (
--      -- port A to fsmc2slaves
--      addra => slave_a,
--      dina  => fsmc_do_slave_di,
--      douta => slave_do_fsmc_di ((SL_MEMTEST+1)*FSMC_DW-1 downto SL_MEMTEST*FSMC_DW),
--      wea   => slave_we,
--      ena   => slave_en(SL_MEMTEST),
--      clka  => clk_wb,
--
--      -- port B to memtest assistant
--      addrb => memtest_bram_a,
--      dinb  => memtest_bram_di,
--      doutb => memtest_bram_do,
--      enb   => memtest_bram_en,
--      web   => memtest_bram_we,
--      clkb  => clk_wb
--      );


--
--  memtest_assist : entity work.memtest_assist
--    generic map (
--      AW => BRAM_A_AW,
--      DW => FSMC_DW
--      )
--    port map (
--      clk_i => clk_wb,
--
--      BRAM_FILL => S_BRAM_FILL_F,
--      BRAM_DBG  => F_DBG_S,
--
--      BRAM_CLK => open,
--      BRAM_A   => memtest_bram_a,
--      BRAM_DI  => memtest_bram_do,      -- memory out
--      BRAM_DO  => memtest_bram_di,      -- memory in
--      BRAM_EN  => memtest_bram_en,
--      BRAM_WE  => memtest_bram_we
--      );




  
--  led_proc : process (clk_wb) is
--  begin
--    if rising_edge(clk_wb) then
--      if (slave_en(SL_LED) = '1' and slave_a = "00000000000") then
--        if (slave_we = "1") then
--          led_reg <= fsmc_do_slave_di (7 downto 0);
--        else
--          slave_do_fsmc_di ((SL_LED+1)*FSMC_DW-1 downto SL_LED*FSMC_DW) <= X"000000" & led_reg;
--        end if;
--      end if;
--    end if;
--  end process;

  --
  -- raise ready flag for STM32
  --
  F_FPGA_RDY_S <= not clk_valid;

  -- ARINC GPIO
  AR_IO <= (others => '0');
  AR_THREE_STATE <= (others => '0');
  
  --
  -- PPS map from GNSS to STM32
  --
  F_PPS_S(0) <= G1_PPS_F;
  F_PPS_S(1) <= G2_PPS_F;
  F_PPS_S(2) <= G3_PPS_F;
  F_PPS_S(3) <= '0';

  --
  -- from GNSS to ARINC
  --
  F_PPSp_O <= G3_PPS_F;
  
  --
  -- Resets from STM32 to GNSS
  --
  F_RST_G1 <= S_RST_F(0);
  F_RST_G2 <= S_RST_F(1);
  F_RST_G3 <= S_RST_F(2);
  STM_DEV_NULL1 <= S_RST_F(3) or S_BRAM_FILL_F;
  
  --
  -- UARTS from GNSS to STM32
  --
  F_G1_RX(0) <= S_TX_F(2);
  F_G2_RX(0) <= S_TX_F(3);
  F_G3_RX(0) <= S_TX_F(4);
  F_G3_RX(2) <= S_TX_F(5); -- reserved UART
  F_S_RX(2) <= G1_TX_F(0);
  F_S_RX(3) <= G2_TX_F(0);
  F_S_RX(4) <= G3_TX_F(0);
  F_S_RX(5) <= G3_TX_F(2); -- reserved UART

  --
  -- recycle bin
  --
  G1_DEV_NULL <= G1_VARF_F or G1_PV_F or G1_INT_B_F or G1_TX_F(1) or G1_TX_F(2);
  G2_DEV_NULL <= G2_VARF_F or G2_PV_F or G2_INT_B_F or G2_TX_F(1) or G2_TX_F(2);
  G3_DEV_NULL <= G3_VARF_F or G3_PV_F or G3_INT_B_F or G3_TX_F(1);-- or G3_TX_F(2);
  
  F_G1_EV <= '1';
  F_G2_EV <= '1';
  F_G3_EV <= '1';

  F_G1_RX(1) <= '1';
  F_G1_RX(2) <= '1';
  F_G2_RX(1) <= '1';
  F_G2_RX(2) <= '1';
  F_G3_RX(1) <= '1';
  --F_G3_RX(2) <= '1';
  
  F_MATH_ERR_S <= '1';
  F_ACK_S <= '1';
  
end Behavioral;

