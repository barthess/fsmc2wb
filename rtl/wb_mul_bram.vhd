library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_mul_bram is
  Generic (
    WB_AW   : positive := 16;
    WB_DW   : positive := 16;
    MUL_DW  : positive := 64;
    MUL_AW  : positive := 10;
    BRAM_AW : positive := 12; 
    SLAVES  : positive := 4   -- total wishbone slaves count (3 BRAMs + 1 control)
  );
  Port (
    dat_rdy_o : out std_logic; -- data ready interrupt
    
    clk_mul_i : in  std_logic;
    clk_wb_i  : in  std_logic_vector(SLAVES-2 downto 0);
    
    sel_i : in  std_logic_vector(SLAVES-1 downto 0);
    stb_i : in  std_logic_vector(SLAVES-1 downto 0);
    we_i  : in  std_logic_vector(SLAVES-1 downto 0);
    err_o : out std_logic_vector(SLAVES-1 downto 0);
    ack_o : out std_logic_vector(SLAVES-1 downto 0);
    adr_i : in  std_logic_vector(SLAVES*WB_AW-1 downto 0);
    dat_o : out std_logic_vector(SLAVES*WB_DW-1 downto 0);
    dat_i : in  std_logic_vector(SLAVES*WB_DW-1 downto 0)
  );
end wb_mul_bram;

-----------------------------------------------------------------------------

architecture beh of wb_mul_bram is
  
  -- wires connecting BRAMs to multiplier
  signal wire_bram2mul_clk    : std_logic_vector(3-1        downto 0);
  signal wire_bram2mul_adr    : std_logic_vector(3*MUL_AW-1 downto 0);
  signal wire_bram2mul_dat_i  : std_logic_vector(3*MUL_DW-1 downto 0);
  signal wire_bram2mul_dat_o  : std_logic_vector(3*MUL_DW-1 downto 0);
  signal wire_bram2mul_we     : std_logic_vector(3-1        downto 0);
  signal wire_bram2mul_en     : std_logic_vector(3-1        downto 0);
  
  -- wires to connect BRAMs to wishbone adapters
  signal wire_bram2wb_clk    : std_logic_vector(3-1           downto 0);
  signal wire_bram2wb_adr    : std_logic_vector(3*BRAM_AW-1   downto 0);
  signal wire_bram2wb_dat_i  : std_logic_vector(3*WB_DW-1     downto 0);
  signal wire_bram2wb_dat_o  : std_logic_vector(3*WB_DW-1     downto 0);
  signal wire_bram2wb_we     : std_logic_vector(3-1           downto 0);
  signal wire_bram2wb_en     : std_logic_vector(3-1           downto 0);      
  
  constant BRAMs : integer := SLAVES-1;
begin
  
  --
  -- Connect multiplier to BRAMs and and to WB
  --
  mtrx_mul : entity work.mtrx_mul
  generic map (
    WB_AW   => WB_AW,
    WB_DW   => WB_DW,
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW
  )
  port map (
    dat_rdy_o => dat_rdy_o,
    
    -- mul to WB interface
    clk_i => clk_mul_i,
    sel_i => sel_i(BRAMs),
    stb_i => stb_i(BRAMs),
    we_i  => we_i (BRAMs),
    err_o => err_o(BRAMs),
    ack_o => ack_o(BRAMs),
    adr_i => adr_i((BRAMs+1)*WB_AW-1 downto BRAMs*WB_AW),
    dat_o => dat_o((BRAMs+1)*WB_DW-1 downto BRAMs*WB_DW),
    dat_i => dat_i((BRAMs+1)*WB_DW-1 downto BRAMs*WB_DW),

    -- BRAM interface
    bram_clk_o => wire_bram2mul_clk,
    bram_adr_o => wire_bram2mul_adr,
    bram_dat_i => wire_bram2mul_dat_o,
    bram_dat_o => wire_bram2mul_dat_i,
    bram_we_o  => wire_bram2mul_we,
    bram_en_o  => wire_bram2mul_en
  );
  
  --
  -- generate and connect BRAMs to Multiplicator and wishbone adaptors
  --
  brams2mul : for n in 0 to BRAMs-1 generate 
  begin
    bram_mtrx : entity work.bram_mtrx
      port map (
        -- BRAM to FSMC via wishbone adapters
        clka  => wire_bram2wb_clk  (n),
        addra => wire_bram2wb_adr  ((n+1)*BRAM_AW-1   downto n*BRAM_AW),
        douta => wire_bram2wb_dat_o((n+1)*WB_DW-1     downto n*WB_DW),
        dina  => wire_bram2wb_dat_i((n+1)*WB_DW-1     downto n*WB_DW),
        wea(0)=> wire_bram2wb_we   (n),
        ena   => wire_bram2wb_en   (n),
        
        -- BRAM to Mul
        clkb  => wire_bram2mul_clk  (n),
        addrb => wire_bram2mul_adr  ((n+1)*MUL_AW-1 downto n*MUL_AW),
        doutb => wire_bram2mul_dat_o((n+1)*MUL_DW-1 downto n*MUL_DW),
        dinb  => wire_bram2mul_dat_i((n+1)*MUL_DW-1 downto n*MUL_DW),
        web(0)=> wire_bram2mul_we   (n),
        enb   => wire_bram2mul_en   (n)
      );
  end generate;

  
  --
  -- generate BRAM adapters and conntect them to WB
  --
  brams2wb : for n in 0 to BRAMs-1 generate 
  begin
    bram_adapter : entity work.wb_bram
      generic map (
        WB_AW   => WB_AW,
        BRAM_AW => BRAM_AW,
        DW      => WB_DW
      )
      port map (
        -- WB interface
        clk_i => clk_wb_i(n),
        sel_i => sel_i(n),
        stb_i => stb_i(n),
        we_i  => we_i (n),
        err_o => err_o(n),
        ack_o => ack_o(n),
        adr_i => adr_i((n+1)*WB_AW-1 downto n*WB_AW),
        dat_o => dat_o((n+1)*WB_DW-1 downto n*WB_DW),
        dat_i => dat_i((n+1)*WB_DW-1 downto n*WB_DW),

        -- BRAM interface
        bram_we_o  => wire_bram2wb_we   (n),
        bram_en_o  => wire_bram2wb_en   (n),
        bram_clk_o => wire_bram2wb_clk  (n),
        bram_adr_o => wire_bram2wb_adr  ((n+1)*BRAM_AW-1 downto n*BRAM_AW),
        bram_dat_i => wire_bram2wb_dat_o((n+1)*WB_DW-1   downto n*WB_DW),
        bram_dat_o => wire_bram2wb_dat_i((n+1)*WB_DW-1   downto n*WB_DW)
      );
  end generate;

end beh;

