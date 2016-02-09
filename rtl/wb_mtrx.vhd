library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use work.mtrx_math_const.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_mtrx is
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
  
  -- wishbone control signals
  sel_i : in  std_logic_vector(SLAVES-1 downto 0);
  stb_i : in  std_logic_vector(SLAVES-1 downto 0);
  we_i  : in  std_logic_vector(SLAVES-1 downto 0);
  err_o : out std_logic_vector(SLAVES-1 downto 0);
  ack_o : out std_logic_vector(SLAVES-1 downto 0);
  adr_i : in  std_logic_vector(SLAVES*WB_AW-1 downto 0);
  dat_o : out std_logic_vector(SLAVES*WB_DW-1 downto 0);
  dat_i : in  std_logic_vector(SLAVES*WB_DW-1 downto 0)
);
end wb_mtrx;

-----------------------------------------------------------------------------

architecture beh of wb_mtrx is
  
  constant BRAMs : integer := SLAVES-1;
  
  -- data latency on dot bar. Set it to 1 (BRAM latency) if no buffering used
  constant DAT_LAT : positive := 1; 
  
  -- wires for control interface connection to WB
  signal ctl_ack_o, ctl_err_o, ctl_stb_i, ctl_we_i, ctl_sel_i, ctl_clk_i : std_logic;
  signal ctl_dat_i, ctl_dat_o : std_logic_vector(WB_DW-1 downto 0);
  signal ctl_adr_i : std_logic_vector(WB_AW-1 downto 0);
  type math_ctl_reg_t is array (0 to 7) of std_logic_vector(WB_DW-1 downto 0);
  signal math_ctl_array : math_ctl_reg_t := (others => (others => '0'));
  constant CONTROL_REG : integer := 0;
  constant SIZES_REG   : integer := 1;
  constant RESERVED_REG: integer := 2;
  constant STATUS_REG  : integer := 3;
  constant SCALE_REG0  : integer := 4;
  constant SCALE_REG1  : integer := 5;
  constant SCALE_REG2  : integer := 6;
  constant SCALE_REG3  : integer := 7;
  
  type state_t is (IDLE, FETCH, DECODE, EXEC);
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

  signal dotbar_dat_a_select : std_logic_vector(2 downto 0);
  signal dotbar_dat_b_select : std_logic_vector(2 downto 0);
  signal dotbar_dat_select_stack : std_logic_vector(5 downto 0);
  signal dotbar_we_select    : std_logic_vector(2 downto 0);
  signal dotbar_adr_select   : std_logic_vector(2*BRAMS-1 downto 0) := (others => '1');
  signal dotbar_adr_stack : std_logic_vector(4*MUL_AW-1 downto 0);
  
  signal math_dat_a, math_dat_b, math_dat_c : std_logic_vector(MUL_DW-1 downto 0);
  signal math_adr_a, math_adr_b, math_adr_c : std_logic_vector(MUL_AW-1 downto 0);
  signal math_we, math_rdy, math_err : std_logic := '0';
  signal math_rst : std_logic := '1';
  signal math_scale_not_mul : std_logic := '0';
  signal math_sub_not_add : std_logic := '0';
  signal math_mov_type : std_logic_vector (1 downto 0) := "00";
  signal math_double_constant : std_logic_vector(MUL_DW-1 downto 0);
  signal math_hw_select : std_logic_vector(1 downto 0) := "00";
  signal math_m_size : std_logic_vector(4 downto 0);
  signal math_p_size : std_logic_vector(4 downto 0);
  signal math_n_size : std_logic_vector(4 downto 0);
  
begin
                      
  ----------------------------------------------------------------------------------
  -- multiplex data from BRAMs into dotbar
  ----------------------------------------------------------------------------------
  wire_bram2mul_clk <= (others => clk_mul_i);
  wire_bram2mul_en  <= (others =>'1');
  
  -- connect all BRAM dat_i together
  fork_bram_dat_c : entity work.fork
  generic map (
    ocnt => BRAMS,
    DW   => MUL_DW
  )
  port map (
    --clk_i => clk_mul_i,
    di => math_dat_c,
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
    --clk_i => clk_mul_i,
    A     => dotbar_we_select,
    di(0) => math_we,
    do    => wire_bram2mul_we
  );

  -- Addres router from math to brams
  dotbar_adr_stack <= "0000000000" & math_adr_c & math_adr_b & math_adr_a;
  adr_abc_router : entity work.bus_matrix
  generic map (
    AW   => 2, -- address width in bits
    ocnt => BRAMS, -- output ports count
    DW   => MUL_AW -- data bus width 
  )
  port map (
    --clk_i => clk_mul_i,
    A  => dotbar_adr_select,
    di => dotbar_adr_stack,
    do => wire_bram2mul_adr
  );

  -- connects BRAMs outputs to A and B inputs of math
  dotbar_dat_select_stack <= dotbar_dat_b_select & dotbar_dat_a_select;
  dat_ab_router : entity work.bus_matrix
  generic map (
    AW   => 3, -- address width in bits
    ocnt => 2, -- output ports count
    DW   => 64 -- data bus width 
  )
  port map (
    --clk_i => clk_mul_i,
    A  => dotbar_dat_select_stack,
    di => wire_bram2mul_dat_o,
    do(127 downto 64) => math_dat_b,
    do(63  downto 0)  => math_dat_a
  );
  

  ----------------------------------------------------------------------------------
  -- Matrix math instance
  ----------------------------------------------------------------------------------
  
  mtrx_math_inst : entity work.mtrx_math
  generic map (
    MTRX_AW => 5,
    BRAM_DW => MUL_DW
  )
  port map (
    clk_i => clk_mul_i,
    rst_i => math_rst,
    sel_i => math_hw_select,

    rdy_o => math_rdy,
    err_o => math_err,

    adr_a_o => math_adr_a,
    adr_b_o => math_adr_b,
    adr_c_o => math_adr_c,
    dat_a_i => math_dat_a,
    dat_b_i => math_dat_b,
    dat_c_o => math_dat_c,
    we_o    => math_we,
    m_size_i=> math_m_size,
    p_size_i=> math_p_size,
    n_size_i=> math_n_size,

    op_mov_i => math_mov_type,
    op_mul_i => math_scale_not_mul,
    op_add_i => math_sub_not_add,
    constant_i => math_double_constant
  );

  ----------------------------------------------------------------------------------
  -- Wishbone interconnect
  ----------------------------------------------------------------------------------
  -- generate and connect BRAMs to Matrix dotbar and to wishbone adaptors
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
  --
  --
  --
  math_double_constant <= math_ctl_array(SCALE_REG3) &
                          math_ctl_array(SCALE_REG2) &
                          math_ctl_array(SCALE_REG1) &
                          math_ctl_array(SCALE_REG0);

  --
  --
  --
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
    variable a_num, b_num, c_num : std_logic_vector(2 downto 0) := "000";
    variable dv : std_logic := '0'; -- data valid bit
    variable a, b, c : integer := 0;
    variable cmd_raw : natural range 0 to 15;
    variable hw_sel_v : std_logic_vector(1 downto 0); -- same as hw_sel_i
    variable hw_sel_i : natural range 0 to 3;         -- same as hw_sel_v
    constant DV_BIT : integer := 15;
  begin

    if rising_edge(ctl_clk_i) then
      ctl_ack_o <= '0';
      ctl_err_o <= '0';
      
      case state is
      when IDLE =>
        math_rst <= '1';
        if (ctl_stb_i = '1' and ctl_sel_i = '1') then
          if (ctl_adr_i > 7) then
            ctl_err_o <= '1';
          else
            ctl_ack_o <= '1';
            if (ctl_we_i = '1') then
              math_ctl_array(conv_integer(ctl_adr_i)) <= ctl_dat_i;
            else -- read request
              ctl_dat_o <= math_ctl_array(conv_integer(ctl_adr_i));
            end if;
          end if;
        end if;
        
        a_num := math_ctl_array(CONTROL_REG)(2  downto 0);
        b_num := math_ctl_array(CONTROL_REG)(5  downto 3);
        c_num := math_ctl_array(CONTROL_REG)(8  downto 6);
        cmd_raw := conv_integer(math_ctl_array(CONTROL_REG)(12 downto 9));
        dv    := math_ctl_array(CONTROL_REG)(DV_BIT);
        
        if dv = '1' then
          math_ctl_array(CONTROL_REG)(DV_BIT) <= '0';
          state <= FETCH;
        end if;
        
      when FETCH =>
        -- select apropriate BRAMS via dotbar
        dotbar_dat_a_select <= a_num;
        dotbar_dat_b_select <= b_num;
        dotbar_we_select    <= c_num;
        
        -- connect address buses
        a := conv_integer(a_num);
        b := conv_integer(b_num);
        c := conv_integer(c_num);
        dotbar_adr_select <= (others => '1');
        dotbar_adr_select((a+1)*2-1 downto a*2) <= "00";
        dotbar_adr_select((b+1)*2-1 downto b*2) <= "01";
        dotbar_adr_select((c+1)*2-1 downto c*2) <= "10";
        
        math_m_size <= math_ctl_array(SIZES_REG)(4 downto 0);
        math_p_size <= math_ctl_array(SIZES_REG)(9 downto 5);
        math_n_size <= math_ctl_array(SIZES_REG)(14 downto 10);

        state <= DECODE;

      when DECODE =>
        -- parse command
        case cmd_raw is
        when MATH_OP_MUL =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MUL, 2));
          hw_sel_i := MATH_HW_MUL;
          math_hw_select <= hw_sel_v;
          math_scale_not_mul <= '0'; -- differece between scale and mul
          state <= EXEC;
          
        when MATH_OP_SCALE =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MUL, 2));
          hw_sel_i := MATH_HW_MUL;
          math_hw_select <= hw_sel_v;
          math_scale_not_mul <= '1'; -- differece between scale and mul
          state <= EXEC;

        when MATH_OP_CPY =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
          hw_sel_i := MATH_HW_MOV;
          math_hw_select <= hw_sel_v;
          math_mov_type <= "00";
          state <= EXEC;

        when MATH_OP_EYE =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
          hw_sel_i := MATH_HW_MOV;
          math_hw_select <= hw_sel_v;
          math_mov_type <= "01";
          state <= EXEC;   
          
        when MATH_OP_TRN =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
          hw_sel_i := MATH_HW_MOV;
          math_hw_select <= hw_sel_v;
          math_mov_type <= "10";
          state <= EXEC;

        when MATH_OP_SET =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
          hw_sel_i := MATH_HW_MOV;
          math_hw_select <= hw_sel_v;
          math_mov_type <= "11";
          state <= EXEC;          

        when MATH_OP_ADD =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_ADD, 2));
          hw_sel_i := MATH_HW_ADD;
          math_hw_select <= hw_sel_v;
          math_sub_not_add <= '0';
          state <= EXEC;   
          
        when MATH_OP_SUB =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_ADD, 2));
          hw_sel_i := MATH_HW_ADD;
          math_hw_select <= hw_sel_v;
          math_sub_not_add <= '1';
          state <= EXEC;   

        when MATH_OP_DOT =>
          hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_DOT, 2));
          hw_sel_i := MATH_HW_DOT;
          math_hw_select <= hw_sel_v;
          state <= EXEC;   
          
        when others =>
          state <= IDLE;
          ctl_err_o <= '1';
          math_rst <= '1';
        end case;

      -- execute command if successfully recognized
      when EXEC =>
        math_rst <= '0';
        if (math_rdy = '1') or (math_err = '1') then
          if math_err = '1' then
            ctl_err_o <= '1';
            math_ctl_array(STATUS_REG) <= "00000000000000" & hw_sel_v;
          end if;
          math_rst <= '1';
          state <= IDLE;
        end if;
        
      end case;
    end if;
  end process;

end beh;

