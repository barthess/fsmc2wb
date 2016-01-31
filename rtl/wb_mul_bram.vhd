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
    MUL_AW  : positive := 10;
    MUL_DW  : positive := 64;
    BRAM_AW : positive := 12;
    SLAVES  : positive := 9   -- total wishbone slaves count (BRAMs + 1 control)
  );
  Port (
    dat_rdy_o : out std_logic; -- data ready external interrupt
    
    clk_mul_i : in  std_logic; -- high speed clock for multiplier
    clk_wb_i  : in  std_logic_vector(SLAVES-2 downto 0); -- slow wishbone clock
    
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
  
  constant BRAMs : integer := SLAVES-1;
  
  -- wires to connect BRAMs to wishbone adapters
  signal wire_bram2wb_clk    : std_logic_vector(BRAMs-1         downto 0);
  signal wire_bram2wb_adr    : std_logic_vector(BRAMs*BRAM_AW-1 downto 0);
  signal wire_bram2wb_dat_i  : std_logic_vector(BRAMs*WB_DW-1   downto 0);
  signal wire_bram2wb_dat_o  : std_logic_vector(BRAMs*WB_DW-1   downto 0);
  signal wire_bram2wb_we     : std_logic_vector(BRAMs-1         downto 0);
  signal wire_bram2wb_en     : std_logic_vector(BRAMs-1         downto 0);      
  
  -- wires connecting BRAMs to routers connected to multiplier
  signal wire_bram2mul_clk    : std_logic_vector(BRAMs-1        downto 0);
  signal wire_bram2mul_adr    : std_logic_vector(BRAMs*MUL_AW-1 downto 0);
  signal wire_bram2mul_dat_i  : std_logic_vector(BRAMs*MUL_DW-1 downto 0);
  signal wire_bram2mul_dat_o  : std_logic_vector(BRAMs*MUL_DW-1 downto 0);
  signal wire_bram2mul_we     : std_logic_vector(BRAMs-1        downto 0);
  signal wire_bram2mul_en     : std_logic_vector(BRAMs-1        downto 0);

  signal mul_dat_a_select : std_logic_vector(2 downto 0);
  signal mul_dat_b_select : std_logic_vector(2 downto 0);
  signal mul2bram_we_select : std_logic_vector(2 downto 0);  
  signal mul_adr_select : std_logic_vector(2*BRAMS-1 downto 0);-- select input for address bus matrix (8 muxers with 2-bit address)
  
  signal mul_a_dat : std_logic_vector(MUL_DW-1 downto 0);
  signal mul_b_dat : std_logic_vector(MUL_DW-1 downto 0);
  signal mul_c_dat : std_logic_vector(MUL_DW-1 downto 0);
    
  signal mul_adr_a : std_logic_vector(MUL_AW-1 downto 0);
  signal mul_adr_b : std_logic_vector(MUL_AW-1 downto 0);
  signal mul_adr_c : std_logic_vector(MUL_AW-1 downto 0);
  constant mul_adr_z : std_logic_vector(MUL_AW-1 downto 0) := (others => '0');
  
  signal mul2bram_we : std_logic;
  
begin

  -- hardcoded addresses for debug
  
  mul_dat_a_select <= "000";
  mul_dat_b_select <= "001";
  mul2bram_we_select <= "010";
  mul_adr_select <= "00" & "01" & "10" & "11" & 
                    "00" & "00" & "00" & "00";
  
  --
  -- connect all BRAMs input together
  --
  result_outputs : for n in 0 to BRAMs-1 generate 
  begin
    wire_bram2mul_dat_i((n+1)*MUL_DW-1 downto n*MUL_DW) <= mul_c_dat;
    wire_bram2mul_clk(n) <= clk_mul_i;
    wire_bram2mul_en(n) <= '1';
  end generate;
  
  -- 
  -- 
  --
  we_router : entity work.demuxer
  generic map (
    AW => 3, -- address width (select bits count)
    DW => 1,  -- data width 
    default => '0'
  )
  port map (
    A     => mul2bram_we_select,
    di(0) => mul2bram_we,
    do    => wire_bram2mul_we
  );

  --
  -- addres router from mul to brams
  -- 
  adr_abc_router : entity work.bus_matrix
  generic map (
    AW   => 2, -- address width in bits
    ocnt => BRAMS, -- output ports count
    DW   => MUL_AW -- data bus width 
  )
  port map (
    A  => mul_adr_select,
    di => mul_adr_a & mul_adr_b & mul_adr_c & mul_adr_z,
    do => wire_bram2mul_adr
  );

  --
  -- connects BRAMs outputs to A or B input of multiplier
  --
  dat_ab_router : entity work.bus_matrix
  generic map (
    AW   => 3, -- address width in bits
    ocnt => 2, -- output ports count
    DW   => 64 -- data bus width 
  )
  port map (
    A  => mul_dat_a_select & mul_dat_b_select,
    di => wire_bram2mul_dat_o,
    do(127 downto 64) => mul_a_dat,
    do(63 downto 0)   => mul_b_dat
  );
  

  --
  -- Connect multiplier to BRAMs and and to WB
  --
  mtrx_mul : entity work.mtrx_scale
  generic map (
    WB_AW   => WB_AW,
    WB_DW   => WB_DW,
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW,
    MTRX_AW => 5
  )
  port map (
    rdy_o => dat_rdy_o,
    
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
    
    bram_adr_a_o => mul_adr_a,
    bram_adr_b_o => mul_adr_b,
    bram_adr_c_o => mul_adr_c,
    bram_dat_a_i => mul_a_dat,
    bram_dat_b_i => mul_b_dat,
    bram_dat_c_o => mul_c_dat,
    bram_ce_a_o  => open,
    bram_ce_b_o  => open,
    bram_ce_c_o  => open,
    bram_we_o => mul2bram_we
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
        addra => wire_bram2wb_adr  ((n+1)*BRAM_AW-1 downto n*BRAM_AW),
        douta => wire_bram2wb_dat_o((n+1)*WB_DW-1   downto n*WB_DW),
        dina  => wire_bram2wb_dat_i((n+1)*WB_DW-1   downto n*WB_DW),
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

