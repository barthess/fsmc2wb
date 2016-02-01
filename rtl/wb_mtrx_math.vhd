library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mtrx_math is
  Generic (
    WB_AW   : positive := 16;
    WB_DW   : positive := 16;
    MUL_AW  : positive := 10;
    MUL_DW  : positive := 64;
    BRAM_AW : positive := 12;
    SLAVES  : positive := 9   -- total wishbone slaves count (BRAMs + 1 control)
  );
  Port (
    rdy_o : out std_logic; -- data ready external interrupt. Active high when IDLE
    
    clk_mul_i : in std_logic; -- high speed clock for multiplier
    clk_wb_i  : in std_logic_vector(SLAVES-1 downto 0); -- slow wishbone clock
    
    sel_i : in  std_logic_vector(SLAVES-1 downto 0);
    stb_i : in  std_logic_vector(SLAVES-1 downto 0);
    we_i  : in  std_logic_vector(SLAVES-1 downto 0);
    err_o : out std_logic_vector(SLAVES-1 downto 0);
    ack_o : out std_logic_vector(SLAVES-1 downto 0);
    adr_i : in  std_logic_vector(SLAVES*WB_AW-1 downto 0);
    dat_o : out std_logic_vector(SLAVES*WB_DW-1 downto 0);
    dat_i : in  std_logic_vector(SLAVES*WB_DW-1 downto 0)
  );
end mtrx_math;

-----------------------------------------------------------------------------

architecture beh of mtrx_math is
  
  constant BRAMs : integer := SLAVES-1;
  
  constant MATHs      : integer := 4; -- number of bus master devices
  constant MATH_DOT   : integer := 0;
  constant MATH_TRN   : integer := 1;
  constant MATH_SUM   : integer := 2;
  constant MATH_CROSS : integer := 3;
  
  -- wires for control interface connection to WB
  signal ctl_ack_o, ctl_err_o, ctl_stb_i, ctl_we_i, ctl_sel_i, ctl_clk_i : std_logic;
  signal ctl_dat_i, ctl_dat_o : std_logic_vector(WB_DW-1 downto 0);
  signal ctl_adr_i : std_logic_vector(WB_AW-1 downto 0);
  type mat_ctl_reg_t is array (0 to 7) of std_logic_vector(WB_DW-1 downto 0);
  signal math_ctl_reg : mat_ctl_reg_t := (others => (others => '0'));
  type state_t is (IDLE, DECODE, EXEC);
  signal state : state_t := IDLE;
  
  -- wires to connect BRAMs to wishbone adapters
  signal wire_bram2wb_clk    : std_logic_vector(BRAMs-1         downto 0);
  signal wire_bram2wb_adr    : std_logic_vector(BRAMs*BRAM_AW-1 downto 0);
  signal wire_bram2wb_dat_i  : std_logic_vector(BRAMs*WB_DW-1   downto 0);
  signal wire_bram2wb_dat_o  : std_logic_vector(BRAMs*WB_DW-1   downto 0);
  signal wire_bram2wb_we     : std_logic_vector(BRAMs-1         downto 0);
  signal wire_bram2wb_en     : std_logic_vector(BRAMs-1         downto 0);      
  
  -- wires connecting BRAMs to routers connected to matrix math
  signal wire_bram2mul_clk    : std_logic_vector(BRAMs-1        downto 0);
  signal wire_bram2mul_adr    : std_logic_vector(BRAMs*MUL_AW-1 downto 0);
  signal wire_bram2mul_dat_i  : std_logic_vector(BRAMs*MUL_DW-1 downto 0);
  signal wire_bram2mul_dat_o  : std_logic_vector(BRAMs*MUL_DW-1 downto 0);
  signal wire_bram2mul_we     : std_logic_vector(BRAMs-1        downto 0);
  signal wire_bram2mul_en     : std_logic_vector(BRAMs-1        downto 0);

  signal crossbar_dat_a_select : std_logic_vector(2 downto 0);
  signal crossbar_dat_b_select : std_logic_vector(2 downto 0);
  signal crossbar_we_select    : std_logic_vector(2 downto 0);
  --type adr_sel_t is array (0 to BRAMS-1) of std_logic_vector(1 downto 0);
  --signal crossbar_adr_select : adr_sel_t := (others => (others => '0'));
  -- select input for address bus matrix (8 muxers with 2-bit address)
  signal crossbar_adr_select   : std_logic_vector(2*BRAMS-1 downto 0) := (others => '1');

  -- wires between BRAMs and matrix math
  signal crossbar_dat_a, crossbar_dat_b, crossbar_dat_c : std_logic_vector(MUL_DW-1 downto 0);
  signal crossbar_adr_a, crossbar_adr_b, crossbar_adr_c : std_logic_vector(MUL_AW-1 downto 0);

  -- wires with data from differnt matrix math
  signal math_dat_a, math_dat_b, math_dat_c : std_logic_vector(MATHs*MUL_DW-1 downto 0);
  signal math_adr_a, math_adr_b, math_adr_c : std_logic_vector(MATHs*MUL_AW-1 downto 0);
  signal math_we, math_rdy : std_logic_vector(MATHs-1 downto 0) := (others => '0');
  signal math_rst : std_logic_vector(MATHs-1 downto 0) := (others => '1');
  signal common_we : std_logic;
  -- multiplexer control register
  signal math_select : std_logic_vector(1 downto 0) := "00";
  -- math operation. Generally is matrix sizes. Single register for all.
  signal math_op : std_logic_vector(WB_DW-1 downto 0);
  
begin

  ----------------------------------------------------------------------------------
  -- multiplex data from different matrix operations into cross bar
  ----------------------------------------------------------------------------------
  -- ORed rdy and we
  common_we  <= '1' when (math_we  > 0) else '0';

  -- fan out data bus A
  fork_math_dat_a : entity work.fork
  generic map (
    ocnt => MATHs,
    DW   => MUL_DW
  )
  port map (
    di => crossbar_dat_a,
    do => math_dat_a
  );
  
  -- fan out data bus B
  fork_math_dat_b : entity work.fork
  generic map (
    ocnt => MATHs,
    DW   => MUL_DW
  )
  port map (
    di => crossbar_dat_b,
    do => math_dat_b
  );
  
  -- Multiplex data bus C
  mux_math_dat_c : entity work.muxer
  generic map (
    AW => 2,
    DW => MUL_DW
  )
  port map (
    A  => math_select,
    do => crossbar_dat_c,
    di => math_dat_c
  );
  
  -- Multiplex address for bus A
  mux_math_adr_a : entity work.muxer
  generic map (
    AW => 2,
    DW => MUL_AW
  )
  port map (
    A  => math_select,
    do => crossbar_adr_a,
    di => math_adr_a
  );
  
  -- Multiplex address for bus B
  mux_math_adr_b : entity work.muxer
  generic map (
    AW => 2,
    DW => MUL_AW
  )
  port map (
    A  => math_select,
    do => crossbar_adr_b,
    di => math_adr_b
  );
  
  -- Multiplex address for bus C
  mux_math_adr_c : entity work.muxer
  generic map (
    AW => 2,
    DW => MUL_AW
  )
  port map (
    A  => math_select,
    do => crossbar_adr_c,
    di => math_adr_c
  );
  
  
  ----------------------------------------------------------------------------------
  -- multiplex data from BRAMs into crossbar
  ----------------------------------------------------------------------------------
  wire_bram2mul_clk <= (others => clk_mul_i);
  wire_bram2mul_en <= (others =>'1');
  
  -- connect all BRAM dat_i together
  fork_bram_dat_c : entity work.fork
  generic map (
    ocnt => BRAMS,
    DW   => MUL_DW
  )
  port map (
    di => crossbar_dat_c,
    do => wire_bram2mul_dat_i
  );
  
  -- Route WE line
  we_router : entity work.demuxer
  generic map (
    AW => 3, -- address width (select bits count)
    DW => 1,  -- data width 
    default => '0'
  )
  port map (
    A     => crossbar_we_select,
    di(0) => common_we,
    do    => wire_bram2mul_we
  );

  -- Addres router from math to brams
  adr_abc_router : entity work.bus_matrix
  generic map (
    AW   => 2, -- address width in bits
    ocnt => BRAMS, -- output ports count
    DW   => MUL_AW -- data bus width 
  )
  port map (
    A  => crossbar_adr_select,
    di => "0000000000" & crossbar_adr_a & crossbar_adr_b & crossbar_adr_c,
    do => wire_bram2mul_adr
  );

  -- connects BRAMs outputs to A or B input of multiplier
  dat_ab_router : entity work.bus_matrix
  generic map (
    AW   => 3, -- address width in bits
    ocnt => 2, -- output ports count
    DW   => 64 -- data bus width 
  )
  port map (
    A  => crossbar_dat_b_select & crossbar_dat_a_select,
    di => wire_bram2mul_dat_o,
    do(127 downto 64) => crossbar_dat_b,
    do(63 downto 0)   => crossbar_dat_a
  );
  
  ----------------------------------------------------------------------------------
  -- Instantiate matrix math
  ----------------------------------------------------------------------------------
  -- dot product multiplier
  mtrx_dot : entity work.mtrx_dot
  generic map (
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW
  )
  port map (
    rdy_o => math_rdy(MATH_DOT),
    
    -- control interface
    clk_i => clk_mul_i,
    rst_i => math_rst(MATH_DOT),
    op_i  => math_op,
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_DOT+1)*MUL_AW-1 downto MATH_DOT*MUL_AW),
    bram_adr_b_o => math_adr_b((MATH_DOT+1)*MUL_AW-1 downto MATH_DOT*MUL_AW),
    bram_adr_c_o => math_adr_c((MATH_DOT+1)*MUL_AW-1 downto MATH_DOT*MUL_AW),
    bram_dat_a_i => math_dat_a((MATH_DOT+1)*MUL_DW-1 downto MATH_DOT*MUL_DW),
    bram_dat_b_i => math_dat_b((MATH_DOT+1)*MUL_DW-1 downto MATH_DOT*MUL_DW),
    bram_dat_c_o => math_dat_c((MATH_DOT+1)*MUL_DW-1 downto MATH_DOT*MUL_DW),
    bram_ce_a_o  => open,
    bram_ce_b_o  => open,
    bram_ce_c_o  => open,
    bram_we_o    => math_we(MATH_DOT)
  );
  
  -- additional test module (transposition)
  mtrx_trn : entity work.mtrx_dot
  generic map (
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW
  )
  port map (
    rdy_o => math_rdy(MATH_TRN),
    
    -- control interface
    clk_i => clk_mul_i,
    rst_i => math_rst(MATH_TRN),
    op_i  => math_op,
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_TRN+1)*MUL_AW-1 downto MATH_TRN*MUL_AW),
    bram_adr_b_o => math_adr_b((MATH_TRN+1)*MUL_AW-1 downto MATH_TRN*MUL_AW),
    bram_adr_c_o => math_adr_c((MATH_TRN+1)*MUL_AW-1 downto MATH_TRN*MUL_AW),
    bram_dat_a_i => math_dat_a((MATH_TRN+1)*MUL_DW-1 downto MATH_TRN*MUL_DW),
    bram_dat_b_i => math_dat_b((MATH_TRN+1)*MUL_DW-1 downto MATH_TRN*MUL_DW),
    bram_dat_c_o => math_dat_c((MATH_TRN+1)*MUL_DW-1 downto MATH_TRN*MUL_DW),
    bram_ce_a_o  => open,
    bram_ce_b_o  => open,
    bram_ce_c_o  => open,
    bram_we_o    => math_we(MATH_TRN)
  );
  
  -- additional test module (sum)
  mtrx_sum : entity work.mtrx_dot
  generic map (
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW
  )
  port map (
    rdy_o => math_rdy(MATH_SUM),
    
    -- control interface
    clk_i => clk_mul_i,
    rst_i => math_rst(MATH_SUM),
    op_i  => math_op,
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_SUM+1)*MUL_AW-1 downto MATH_SUM*MUL_AW),
    bram_adr_b_o => math_adr_b((MATH_SUM+1)*MUL_AW-1 downto MATH_SUM*MUL_AW),
    bram_adr_c_o => math_adr_c((MATH_SUM+1)*MUL_AW-1 downto MATH_SUM*MUL_AW),
    bram_dat_a_i => math_dat_a((MATH_SUM+1)*MUL_DW-1 downto MATH_SUM*MUL_DW),
    bram_dat_b_i => math_dat_b((MATH_SUM+1)*MUL_DW-1 downto MATH_SUM*MUL_DW),
    bram_dat_c_o => math_dat_c((MATH_SUM+1)*MUL_DW-1 downto MATH_SUM*MUL_DW),
    bram_ce_a_o  => open,
    bram_ce_b_o  => open,
    bram_ce_c_o  => open,
    bram_we_o    => math_we(MATH_SUM)
  );
  
  -- additional test module (cross product)
  mtrx_cross : entity work.mtrx_dot
  generic map (
    BRAM_AW => MUL_AW,
    BRAM_DW => MUL_DW
  )
  port map (
    rdy_o => math_rdy(MATH_CROSS),
    
    -- control interface
    clk_i => clk_mul_i,
    rst_i => math_rst(MATH_CROSS),
    op_i  => math_op,
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_CROSS+1)*MUL_AW-1 downto MATH_CROSS*MUL_AW),
    bram_adr_b_o => math_adr_b((MATH_CROSS+1)*MUL_AW-1 downto MATH_CROSS*MUL_AW),
    bram_adr_c_o => math_adr_c((MATH_CROSS+1)*MUL_AW-1 downto MATH_CROSS*MUL_AW),
    bram_dat_a_i => math_dat_a((MATH_CROSS+1)*MUL_DW-1 downto MATH_CROSS*MUL_DW),
    bram_dat_b_i => math_dat_b((MATH_CROSS+1)*MUL_DW-1 downto MATH_CROSS*MUL_DW),
    bram_dat_c_o => math_dat_c((MATH_CROSS+1)*MUL_DW-1 downto MATH_CROSS*MUL_DW),
    bram_ce_a_o  => open,
    bram_ce_b_o  => open,
    bram_ce_c_o  => open,
    bram_we_o    => math_we(MATH_CROSS)
  );
  
  ----------------------------------------------------------------------------------
  -- Wishbone interconnect
  ----------------------------------------------------------------------------------
  -- generate and connect BRAMs to Matrix crossbar and to wishbone adaptors
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

  -- generate BRAM to WB adapters and conntect them to WB
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


  ----------------------------------------------------------------------------------
  -- Wishbone control logic
  ----------------------------------------------------------------------------------
  ack_o(SLAVES-1) <= ctl_ack_o;
  err_o(SLAVES-1) <= ctl_err_o;
  ctl_stb_i       <= stb_i(SLAVES-1);
  ctl_we_i        <= we_i(SLAVES-1);
  ctl_sel_i       <= sel_i(SLAVES-1);
  ctl_dat_i       <= dat_i(WB_DW*SLAVES-1 downto WB_DW*(SLAVES-1));
  ctl_adr_i       <= adr_i(WB_AW*SLAVES-1 downto WB_AW*(SLAVES-1));
  ctl_clk_i       <= clk_wb_i(SLAVES-1);
  dat_o(WB_DW*SLAVES-1 downto WB_DW*(SLAVES-1)) <= ctl_dat_o;

  rdy_o  <= '1' when (state = IDLE) else '0';
  
  control_logic : process(ctl_clk_i)
    variable cmd, a_num, b_num, c_num : std_logic_vector(2 downto 0) := "000";
    variable dv : std_logic := '0'; -- data valid bit
    variable a, b, c : integer := 0;
  begin

    if rising_edge(ctl_clk_i) then
      ctl_ack_o <= '0';
      ctl_err_o <= '0';
      
      case state is
      when IDLE =>
        if (ctl_stb_i = '1' and ctl_sel_i = '1') then
          if (ctl_adr_i > x"0007") then
            ctl_err_o <= '1';
          else
            ctl_ack_o <= '1';
            if (ctl_we_i = '1') then
              math_ctl_reg(conv_integer(ctl_adr_i)) <= ctl_dat_i;
            else -- read request
              ctl_dat_o <= math_ctl_reg(conv_integer(ctl_adr_i));
            end if;  
          end if;
        end if;
        
        a_num := math_ctl_reg(0)(2  downto 0);
        b_num := math_ctl_reg(0)(5  downto 3);
        c_num := math_ctl_reg(0)(8  downto 6);
        cmd   := math_ctl_reg(0)(11 downto 9);
        dv    := math_ctl_reg(0)(12);
        
        if dv = '1' then
          if (cmd <= MATHs-1) then
            state <= DECODE;
            math_op <= math_ctl_reg(1);
          else
            math_ctl_reg(0)(12) <= '0';
            ctl_err_o <= '1';
          end if;
        end if;
        
      when DECODE =>
        -- select apropriate BRAMS via crossbar
        crossbar_dat_a_select <= a_num;
        crossbar_dat_b_select <= b_num;
        crossbar_we_select    <= c_num;
        
        -- connect address buses
        a := conv_integer(a_num);
        b := conv_integer(b_num);
        c := conv_integer(c_num);
        crossbar_adr_select <= (others => '1');
        crossbar_adr_select((a+1)*2-1 downto a*2) <= "00";
        crossbar_adr_select((b+1)*2-1 downto b*2) <= "01";
        crossbar_adr_select((c+1)*2-1 downto c*2) <= "10";
        
        -- connect data and address buses from math to crossbar
        math_select <= cmd(1 downto 0);
        
        -- release reset on selected math and wait ready interrupts
        math_rst(conv_integer(cmd)) <= '0';
        state <= EXEC;
        
      when EXEC =>
        if (math_rdy(conv_integer(cmd)) = '1') then
          math_rst(conv_integer(cmd)) <= '1';
          state <= IDLE;
        end if;
        
      end case;
    end if;
  end process;







end beh;

