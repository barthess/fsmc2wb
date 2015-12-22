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
    FSMC_A_WIDTH : positive := 23;
    FSMC_D_WIDTH : positive := 16;
    AWSLAVE      : positive := 16;
    WBSTUBS      : positive := 7
  );
  port ( 
    CLK_IN_27MHZ : in std_logic;

    FSMC_A : in std_logic_vector ((FSMC_A_WIDTH - 1) downto 0);
    FSMC_D : inout std_logic_vector ((FSMC_D_WIDTH - 1) downto 0);
    FSMC_NBL : in std_logic_vector (1 downto 0);
    FSMC_NOE : in std_logic;
    FSMC_NWE : in std_logic;
    FSMC_NCE : in std_logic;
    --FSMC_CLK : in std_logic;
    
    STM_IO_MUL_RDY : out std_logic;
    STM_IO_MUL_DV  : in std_logic;
    STM_IO_MMU_INT : out std_logic;
    STM_IO_ACK_INT : out std_logic;
    STM_IO_FPGA_READY : out std_logic;
    STM_IO_OLD_FSMC_CLK : in std_logic;
    
    DEV_NULL_BANK1 : out std_logic; -- warning suppressor
    DEV_NULL_BANK0 : out std_logic -- warning suppressor
	);
end root;


architecture Behavioral of root is

signal clk_170mhz : std_logic;
signal clk_150mhz : std_logic;
signal clk_100mhz : std_logic;
signal clk_locked : std_logic;
signal clk_wb : std_logic;

-- wires for memspace to fsmc
signal wire_bram_a   : std_logic_vector (AWSLAVE-1      downto 0); 
signal wire_bram_di  : std_logic_vector (FSMC_D_WIDTH-1 downto 0); 
signal wire_bram_do  : std_logic_vector (FSMC_D_WIDTH-1 downto 0); 
signal wire_bram_ce  : std_logic; 
signal wire_bram_we  : std_logic_vector (0 downto 0);  
signal wire_bram_clk : std_logic; 
signal wire_bram_asample : std_logic; 

-- wires for memory filler
signal wire_memtest_a    : std_logic_vector (AWSLAVE-1 downto 0); 
signal wire_memtest_di   : std_logic_vector (15 downto 0); 
signal wire_memtest_do   : std_logic_vector (15 downto 0); 
signal wire_memtest_ce   : std_logic;
signal wire_memtest_we   : std_logic_vector (0 downto 0);  
signal wire_memtest_clk  : std_logic;

-- wires for wishbone stubs
signal wb_stub_sel   : std_logic_vector(WBSTUBS - 1               downto 0);
signal wb_stub_stb   : std_logic_vector(WBSTUBS - 1               downto 0);
signal wb_stub_we    : std_logic_vector(WBSTUBS - 1               downto 0);
signal wb_stub_err   : std_logic_vector(WBSTUBS - 1               downto 0);
signal wb_stub_ack   : std_logic_vector(WBSTUBS - 1               downto 0);
signal wb_stub_adr   : std_logic_vector(AWSLAVE*WBSTUBS - 1       downto 0);
signal wb_stub_dat_i : std_logic_vector(FSMC_D_WIDTH*WBSTUBS - 1  downto 0);
signal wb_stub_dat_o : std_logic_vector(FSMC_D_WIDTH*WBSTUBS - 1  downto 0);


begin

  -- clock sources
	clk_src : entity work.clk_src port map (
		CLK_IN1  => CLK_IN_27MHZ,
  	CLK_OUT1 => clk_170mhz,
		CLK_OUT2 => clk_150mhz,
		CLK_OUT3 => clk_100mhz,
		LOCKED   => clk_locked
	);
  clk_wb <= clk_170mhz;


  -- connect stubs
  wb_stub_gen : for n in 0 to WBSTUBS-1 generate 
  begin
    wb_stub : entity work.wb_stub
      generic map (
        AW => 16,
        DW => 16
      )
      port map (
        clk_i => clk_wb,
        sel_i => wb_stub_sel(n),
        stb_i => wb_stub_stb(n),
        we_i  => wb_stub_we(n),
        err_o => wb_stub_err(n),
        ack_o => wb_stub_ack(n),
        adr_i => wb_stub_adr  ((n+1)*AWSLAVE-1      downto n*AWSLAVE),
        dat_o => wb_stub_dat_o((n+1)*FSMC_D_WIDTH-1 downto n*FSMC_D_WIDTH),
        dat_i => wb_stub_dat_i((n+1)*FSMC_D_WIDTH-1 downto n*FSMC_D_WIDTH)
      );
  end generate;

  -- FSMC to Wishbone adaptor
  fsmc2wb : entity work.fsmc2wb 
    generic map (
      AW => FSMC_A_WIDTH,
      DW => FSMC_D_WIDTH,
      AWSEL => 3,
      AWSLAVE => AWSLAVE,
      USENBL => '0'
    )
    port map (
      clk_i => clk_wb,
      err_o => STM_IO_MMU_INT,
      ack_o => STM_IO_ACK_INT,
      
      A   => FSMC_A,
      D   => FSMC_D,
      NCE => FSMC_NCE,
      NOE => FSMC_NOE,
      NWE => FSMC_NWE,
      NBL => FSMC_NBL,

      sel_o(7 downto 1)                           => wb_stub_sel,
      sel_o(0)                                    => wire_bram_ce,
      
      stb_o(7 downto 1)                           => wb_stub_stb,
      stb_o(0)                                    => DEV_NULL_BANK1,
      
      we_o(7 downto 1)                            => wb_stub_we,
      we_o(0)                                     => wire_bram_we(0),
      
      adr_o(AWSLAVE*8-1 downto AWSLAVE)           => wb_stub_adr,
      adr_o(AWSLAVE-1   downto 0)                 => wire_bram_a,
      
      dat_o(FSMC_D_WIDTH*8-1 downto FSMC_D_WIDTH) => wb_stub_dat_i,
      dat_o(FSMC_D_WIDTH-1   downto 0)            => wire_bram_di,
      
      err_i(7 downto 1)                           => wb_stub_err,
      err_i(0)                                    => '0',
      
      ack_i(7 downto 1)                           => wb_stub_ack,
      ack_i(0)                                    => '0',
      
      dat_i(FSMC_D_WIDTH*8-1 downto FSMC_D_WIDTH) => wb_stub_dat_o,
      dat_i(FSMC_D_WIDTH-1   downto 0)            => wire_bram_do
    );



  memtest_assist : entity work.memtest_assist
  generic map (
    AW => AWSLAVE
  )
  port map (
    clk_i     => clk_100mhz,

    BRAM_FILL => STM_IO_MUL_DV,
    BRAM_DBG  => STM_IO_MUL_RDY,
    
    BRAM_CLK => wire_memtest_clk, -- memory clock
    BRAM_A   => wire_memtest_a,   -- memory address
    BRAM_DI  => wire_memtest_di,  -- memory data in
    BRAM_DO  => wire_memtest_do,  -- memory data out
    BRAM_EN  => wire_memtest_ce,  -- memory enable
    BRAM_WE  => wire_memtest_we   -- memory write enable
  );


  bram_test : entity work.bram
    PORT MAP (
      -- port A connected to FSMC adapter
      addra => wire_bram_a,
      dina  => wire_bram_di,
      douta => wire_bram_do,
      wea   => wire_bram_we,
      ena   => wire_bram_ce,
      clka  => wire_bram_clk,

      -- port B connected to memtest assistant
      addrb => wire_memtest_a,
      dinb  => wire_memtest_do,
      doutb => wire_memtest_di,
      enb   => wire_memtest_ce,
      web   => wire_memtest_we,
      clkb  => wire_memtest_clk
    );
  wire_bram_clk <= clk_wb;  


  
  DEV_NULL_BANK0 <= STM_IO_OLD_FSMC_CLK;
  --DEV_NULL_BANK1 <= '1';

	-- raize ready flag
	STM_IO_FPGA_READY <= not clk_locked;

end Behavioral;

