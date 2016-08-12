
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

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
    WB_AW     : positive := 16;
    WBSTUBS   : positive := 5
  );
  port ( 
    FSMC_CLK_54MHZ : in std_logic;

    FSMC_A : in std_logic_vector ((FSMC_AW - 1) downto 0);
    FSMC_D : inout std_logic_vector ((FSMC_DW - 1) downto 0);
    FSMC_NBL : in std_logic_vector (1 downto 0);
    FSMC_NOE : in std_logic;
    FSMC_NWE : in std_logic;
    FSMC_NCE : in std_logic;

    STM_IO_MATH_RDY_OUT : out std_logic;
    STM_IO_MATH_RST_IN : in std_logic;
    STM_IO_WB_ERR_OUT : out std_logic;
    STM_IO_WB_ACK_OUT : out std_logic;
    STM_IO_BRAM_AUTO_FILL : in std_logic;
    STM_IO_BRAM_DBG_OUT : out std_logic;
    STM_IO_FPGA_RDY : out std_logic;
    STM_IO_MMU_ERR_OUT : out std_logic;

    LED_LINE : out std_logic_vector (7 downto 0);

    -- GNSS UART ports between FPGA and STM32
    STM32_UART_TO_FPGA        : in  std_logic_vector (3 downto 0);
    STM32_UART_FROM_FPGA      : out std_logic_vector (3 downto 0);
    STM32_GNSS_NRST_TO_FPGA   : in  std_logic_vector (3 downto 0);
    STM32_GNSS_PPS_FROM_FPGA  : out std_logic_vector (3 downto 0);

    -- ports for GNSS receivers (named relative to GNSS)
    GNSS_NRST_FROM_FPGA : out std_logic_vector (3 downto 0);
    GNSS_UART_TO_FPGA   : in  std_logic_vector (3 downto 0);
    GNSS_UART_FROM_FPGA : out std_logic_vector (3 downto 0);
    GNSS_PPS_TO_FPGA    : in  std_logic_vector (3 downto 0); -- NOTE: 4 inputs
    GNSS_PPS_FROM_FPGA  : out std_logic_vector (2 downto 0); -- NOTE: only 3 outputs needed
    
    -- ARINC GPIO
    ARINC_GPIO  : out std_logic_vector (31 downto 0)
	);
end AA_root;


architecture Behavioral of AA_root is

-- clock wires
signal clk_200mhz : std_logic;
signal clk_150mhz : std_logic;
signal clk_100mhz : std_logic;
signal clk_50mhz : std_logic;
signal clk_locked : std_logic;
signal clk_wb     : std_logic;
signal clk_mul    : std_logic;

begin
   
   BUFG_inst : BUFG
   port map (
      O => clk_wb, -- 1-bit output: Clock buffer output
      I => FSMC_CLK_54MHZ  -- 1-bit input: Clock buffer input
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


  --
  -- multiplicator with integrated BRAMs
  --
  wb_mtrx : entity work.wb_mtrx
  generic map (
    WB_AW => WB_AW,
    WB_DW => FSMC_DW
  )
  port map (
    rdy_o => STM_IO_MATH_RDY_OUT,
    rst_i => STM_IO_MATH_RST_IN,

    clk_wb_i  => (others => clk_wb),
    clk_mul_i => clk_mul,
    
    sel_i => wire_mul2wb_sel,
    stb_i => wire_mul2wb_stb,
    we_i  => wire_mul2wb_we,
    err_o => wire_mul2wb_err,
    ack_o => wire_mul2wb_ack,
    adr_i => wire_mul2wb_adr,
    dat_o => wire_mul2wb_dat_o,
    dat_i => wire_mul2wb_dat_i
  );
    
  --
	-- raize ready flag for STM32
  --
	STM_IO_FPGA_RDY <= clk_locked;
  
  GNSS_UART_FROM_FPGA       <= STM32_UART_TO_FPGA;
  STM32_UART_FROM_FPGA      <= GNSS_UART_TO_FPGA;
  GNSS_NRST_FROM_FPGA       <= STM32_GNSS_NRST_TO_FPGA;
  STM32_GNSS_PPS_FROM_FPGA  <= GNSS_PPS_TO_FPGA;
  GNSS_PPS_FROM_FPGA        <= (others => '0');
  
  -- ARINC GPIO
  ARINC_GPIO <= (others => '0');
  
  --
  -- warning suppressors and other trash
  --
--  DEV_NULL_BANK0 <= '1';--FSMC_NBL(0) or FSMC_NBL(1);
--  DEV_NULL_BANK1 <= '1';

end Behavioral;

