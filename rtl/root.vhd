----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:35:50 09/09/2015 
-- Design Name: 
-- Module Name:    root - Behavioral 
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
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Non standard library from synopsis (for dev_null functions)
use ieee.std_logic_misc.all;


entity root is
  generic (
    FSMC_AW   : positive := 23;
    FSMC_DW   : positive := 16;
    WB_AW     : positive := 16;
    WBSTUBS   : positive := 5
  );
  port ( 
    CLK_IN_27MHZ : in std_logic;

    FSMC_A : in std_logic_vector ((FSMC_AW - 1) downto 0);
    FSMC_D : inout std_logic_vector ((FSMC_DW - 1) downto 0);
    FSMC_NBL : in std_logic_vector (1 downto 0);
    FSMC_NOE : in std_logic;
    FSMC_NWE : in std_logic;
    FSMC_NCE : in std_logic;

    STM_IO_MUL_RDY_OUT : out std_logic;
    STM_IO_WB_ERR_OUT : out std_logic;
    STM_IO_WB_ACK_OUT : out std_logic;
    STM_IO_BRAM_AUTO_FILL : in std_logic;
    STM_IO_BRAM_DBG_OUT : out std_logic;
    STM_IO_FPGA_RDY : out std_logic;

    LED_LINE : out std_logic_vector (5 downto 0);

    DEV_NULL_BANK1 : out std_logic; -- warning suppressor
    DEV_NULL_BANK0 : out std_logic -- warning suppressor
	);
end root;


architecture Behavioral of root is

-- wires for memtest
signal wire_bram_a   : std_logic_vector(14 downto 0); 
signal wire_bram_di  : std_logic_vector(FSMC_DW-1 downto 0); 
signal wire_bram_do  : std_logic_vector(FSMC_DW-1 downto 0); 
signal wire_bram_ce  : std_logic; 
signal wire_bram_we  : std_logic_vector(0 downto 0);  
signal wire_bram_clk : std_logic; 
signal wire_memtest_wb_sel    : std_logic;
signal wire_memtest_wb_stb    : std_logic;
signal wire_memtest_wb_we     : std_logic;
signal wire_memtest_wb_err    : std_logic;
signal wire_memtest_wb_ack    : std_logic;
signal wire_memtest_wb_adr    : std_logic_vector(WB_AW-1 downto 0);
signal wire_memtest_wb_dat_o  : std_logic_vector(FSMC_DW-1 downto 0);
signal wire_memtest_wb_dat_i  : std_logic_vector(FSMC_DW-1 downto 0);
signal wire_memtest_bram_a    : std_logic_vector(14 downto 0); 
signal wire_memtest_bram_di   : std_logic_vector(FSMC_DW-1 downto 0); 
signal wire_memtest_bram_do   : std_logic_vector(FSMC_DW-1 downto 0); 
signal wire_memtest_bram_ce   : std_logic;
signal wire_memtest_bram_we   : std_logic_vector(0 downto 0);  
signal wire_memtest_bram_clk  : std_logic;

-- wires for multiplier combined with BRAMs
constant MTRX_CNT : positive := 9; -- 8 brams + 1 control
signal wire_mul2wb_sel    : std_logic_vector(MTRX_CNT-1 downto 0);
signal wire_mul2wb_stb    : std_logic_vector(MTRX_CNT-1 downto 0);
signal wire_mul2wb_we     : std_logic_vector(MTRX_CNT-1 downto 0);
signal wire_mul2wb_err    : std_logic_vector(MTRX_CNT-1 downto 0);
signal wire_mul2wb_ack    : std_logic_vector(MTRX_CNT-1 downto 0);
signal wire_mul2wb_adr    : std_logic_vector(MTRX_CNT*WB_AW-1   downto 0);
signal wire_mul2wb_dat_o  : std_logic_vector(MTRX_CNT*FSMC_DW-1 downto 0);
signal wire_mul2wb_dat_i  : std_logic_vector(MTRX_CNT*FSMC_DW-1 downto 0);

-- wires for wishbone stubs
signal wb_stub_sel   : std_logic_vector(WBSTUBS - 1         downto 0);
signal wb_stub_stb   : std_logic_vector(WBSTUBS - 1         downto 0);
signal wb_stub_we    : std_logic_vector(WBSTUBS - 1         downto 0);
signal wb_stub_err   : std_logic_vector(WBSTUBS - 1         downto 0);
signal wb_stub_ack   : std_logic_vector(WBSTUBS - 1         downto 0);
signal wb_stub_adr   : std_logic_vector(WB_AW*WBSTUBS - 1   downto 0);
signal wb_stub_dat_i : std_logic_vector(FSMC_DW*WBSTUBS - 1 downto 0);
signal wb_stub_dat_o : std_logic_vector(FSMC_DW*WBSTUBS - 1 downto 0);

-- wires for wishbone led slave
signal wb_led_sel   : std_logic;
signal wb_led_stb   : std_logic;
signal wb_led_we    : std_logic;
signal wb_led_err   : std_logic;
signal wb_led_ack   : std_logic;
signal wb_led_adr   : std_logic_vector(WB_AW-1   downto 0);
signal wb_led_dat_i : std_logic_vector(FSMC_DW-1 downto 0);
signal wb_led_dat_o : std_logic_vector(FSMC_DW-1 downto 0);

-- clock wires
signal clk_250mhz : std_logic;
signal clk_200mhz : std_logic;
signal clk_100mhz : std_logic;
signal clk_locked : std_logic;
signal clk_wb     : std_logic;
signal clk_mul    : std_logic;

begin

  --
  -- clock sources
  --
	clk_src : entity work.clk_src port map (
		CLK_IN1  => CLK_IN_27MHZ,
  	CLK_OUT1 => clk_250mhz,
		CLK_OUT2 => clk_200mhz,
		CLK_OUT3 => clk_100mhz,
		LOCKED   => clk_locked
	);
  clk_wb  <= clk_100mhz;
  clk_mul <= clk_100mhz;

  --
  -- connect stubs to unused wishbone slots
  --
  wb_stub_gen : for n in 0 to WBSTUBS-1 generate 
  begin
    wb_stub : entity work.wb_stub
      generic map (
        AW => WB_AW,
        DW => FSMC_DW,
        ID => n
      )
      port map (
        clk_i => clk_wb,
        sel_i => wb_stub_sel(n),
        stb_i => wb_stub_stb(n),
        we_i  => wb_stub_we(n),
        err_o => wb_stub_err(n),
        ack_o => wb_stub_ack(n),
        adr_i => wb_stub_adr  ((n+1)*WB_AW-1   downto n*WB_AW),
        dat_o => wb_stub_dat_o((n+1)*FSMC_DW-1 downto n*FSMC_DW),
        dat_i => wb_stub_dat_i((n+1)*FSMC_DW-1 downto n*FSMC_DW)
      );
  end generate;

  --
  -- connect wishbone based LED strip
  --
  wb_led : entity work.wb_led
    generic map (
      AW => WB_AW,
      DW => FSMC_DW
    )
    port map (
      led   => LED_LINE,

      clk_i => clk_wb,
      sel_i => wb_led_sel,
      stb_i => wb_led_stb,
      we_i  => wb_led_we,
      err_o => wb_led_err,
      ack_o => wb_led_ack,
      adr_i => wb_led_adr,
      dat_o => wb_led_dat_o,
      dat_i => wb_led_dat_i
    );

  --  
  -- FSMC to Wishbone adaptor
  --
  fsmc2wb : entity work.fsmc2wb 
    generic map (
      AW      => FSMC_AW,
      DW      => FSMC_DW,
      AWSEL   => 4,
      AWSLAVE => WB_AW,
      USENBL  => '0'
    )
    port map (
      clk_i => clk_wb,
      err_o => STM_IO_WB_ERR_OUT,
      ack_o => STM_IO_WB_ACK_OUT,
      
      A   => FSMC_A,
      D   => FSMC_D,
      NCE => FSMC_NCE,
      NOE => FSMC_NOE,
      NWE => FSMC_NWE,
      NBL => FSMC_NBL,
      
--      sel_o => wb_stub_sel,
--      stb_o => wb_stub_stb,
--      we_o  => wb_stub_we,
--      adr_o => wb_stub_adr,
--      dat_o => wb_stub_dat_i,
--      err_i => wb_stub_err,
--      ack_i => wb_stub_ack,
--      dat_i => wb_stub_dat_o
      
      sel_o(15 downto 16-WBSTUBS)         => wb_stub_sel,
      sel_o(10 downto 2)                  => wire_mul2wb_sel,
      sel_o(1)                            => wb_led_sel,
      sel_o(0)                            => wire_memtest_wb_sel,
      
      stb_o(15 downto 16-WBSTUBS)         => wb_stub_stb,
      stb_o(10 downto 2)                  => wire_mul2wb_stb,
      stb_o(1)                            => wb_led_stb,
      stb_o(0)                            => wire_memtest_wb_stb,
      
      we_o(15 downto 16-WBSTUBS)          => wb_stub_we,
      we_o(10 downto 2)                   => wire_mul2wb_we,
      we_o(1)                             => wb_led_we,
      we_o(0)                             => wire_memtest_wb_we,
      
      adr_o(WB_AW*16-1 downto WB_AW*11)     => wb_stub_adr,
      adr_o(WB_AW*11-1 downto WB_AW*2)      => wire_mul2wb_adr,
      adr_o(WB_AW*2-1 downto WB_AW)         => wb_led_adr,
      adr_o(WB_AW-1   downto 0)             => wire_memtest_wb_adr,
      
      dat_o(FSMC_DW*16-1 downto FSMC_DW*11) => wb_stub_dat_i,
      dat_o(FSMC_DW*11-1 downto FSMC_DW*2)  => wire_mul2wb_dat_i,
      dat_o(FSMC_DW*2-1 downto FSMC_DW)     => wb_led_dat_i,
      dat_o(FSMC_DW-1   downto 0)           => wire_memtest_wb_dat_i,
      
      err_i(15 downto 16-WBSTUBS)           => wb_stub_err,
      err_i(10 downto 2)                    => wire_mul2wb_err,
      err_i(1)                              => wb_led_err,
      err_i(0)                              => wire_memtest_wb_err,
      
      ack_i(15 downto 16-WBSTUBS)           => wb_stub_ack,
      ack_i(10 downto 2)                    => wire_mul2wb_ack,
      ack_i(1)                              => wb_led_ack,
      ack_i(0)                              => wire_memtest_wb_ack,
      
      dat_i(FSMC_DW*16-1 downto FSMC_DW*11) => wb_stub_dat_o,
      dat_i(FSMC_DW*11-1 downto FSMC_DW*2)  => wire_mul2wb_dat_o,
      dat_i(FSMC_DW*2-1 downto FSMC_DW)     => wb_led_dat_o,
      dat_i(FSMC_DW-1   downto 0)           => wire_memtest_wb_dat_o
    );

  --
  -- Memtest assistant
  --
  memtest_assist : entity work.memtest_assist
  generic map (
    AW => 15,
    DW => FSMC_DW
  )
  port map (
    clk_i     => clk_100mhz,

    BRAM_FILL => STM_IO_BRAM_AUTO_FILL,
    BRAM_DBG  => STM_IO_BRAM_DBG_OUT,
    
    BRAM_CLK => wire_memtest_bram_clk, -- memory clock
    BRAM_A   => wire_memtest_bram_a,   -- memory address
    BRAM_DI  => wire_memtest_bram_di,  -- memory data in
    BRAM_DO  => wire_memtest_bram_do,  -- memory data out
    BRAM_EN  => wire_memtest_bram_ce,  -- memory enable
    BRAM_WE  => wire_memtest_bram_we   -- memory write enable
  );

  --
  -- BRAM chunk for memtest purpose
  --
  bram_memtest : entity work.bram_memtest
    PORT MAP (
      -- port A connected to Wishbone wrapper
      addra => wire_bram_a,
      dina  => wire_bram_di,
      douta => wire_bram_do,
      wea   => wire_bram_we,
      ena   => wire_bram_ce,
      clka  => wire_bram_clk,

      -- port B connected to memtest assistant
      addrb => wire_memtest_bram_a,
      dinb  => wire_memtest_bram_do,
      doutb => wire_memtest_bram_di,
      enb   => wire_memtest_bram_ce,
      web   => wire_memtest_bram_we,
      clkb  => wire_memtest_bram_clk
    );
  wire_bram_clk <= clk_wb;  

  --
  -- Connect memtest BRAM to wishbone adaptor
  --
  wb2bram : entity work.wb_bram
    generic map (
      WB_AW   => WB_AW,
      DW      => FSMC_DW,
      BRAM_AW => 15
    )
    port map (
      -- BRAM
      bram_clk_o => wire_bram_clk,
      bram_adr_o => wire_bram_a,
      bram_dat_i => wire_bram_do,
      bram_dat_o => wire_bram_di,
      bram_we_o  => wire_bram_we(0),
      bram_en_o  => wire_bram_ce,
      -- WB
      clk_i => clk_wb,
      sel_i => wire_memtest_wb_sel,
      stb_i => wire_memtest_wb_stb,
      we_i  => wire_memtest_wb_we,
      err_o => wire_memtest_wb_err,
      ack_o => wire_memtest_wb_ack,
      adr_i => wire_memtest_wb_adr,
      dat_o => wire_memtest_wb_dat_o,
      dat_i => wire_memtest_wb_dat_i
    );

  --
  -- multiplicator with integrated BRAMs
  --
  mtrx_math : entity work.mtrx_math
    generic map (
      WB_AW => WB_AW,
      WB_DW => FSMC_DW
    )
    port map (
      dat_rdy_o => STM_IO_MUL_RDY_OUT,
      
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

  --
  -- warning suppressors and other trash
  --
  DEV_NULL_BANK0 <= '1';
  DEV_NULL_BANK1 <= '1';

end Behavioral;

