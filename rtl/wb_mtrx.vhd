library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use work.mtrx_math_constants.all;

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
  rst_i : in std_logic;
  
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

  -- wires for control interface connection to WB
  signal ctl_ack_o, ctl_err_o, ctl_stb_i, ctl_we_i, ctl_sel_i, ctl_clk_i : std_logic;
  signal ctl_dat_i, ctl_dat_o : std_logic_vector(WB_DW-1 downto 0);
  signal ctl_adr_i : std_logic_vector(WB_AW-1 downto 0);
  constant CONTROL_REG : integer := 0;
  constant SIZES_REG   : integer := 1;
  constant RESERVED_REG: integer := 2;
  constant STATUS_REG  : integer := 3;
  constant SCALE_REG0  : integer := 4;
  constant SCALE_REG1  : integer := 5;
  constant SCALE_REG2  : integer := 6;
  constant SCALE_REG3  : integer := 7;
  constant ZERO_MAP_OFFSET : integer := 8;
  constant CTL_ARRAY_LEN : integer := ZERO_MAP_OFFSET+64;
  type math_ctl_reg_t is array (0 to CTL_ARRAY_LEN-1) of std_logic_vector(WB_DW-1 downto 0);
  signal math_ctl : math_ctl_reg_t := (others => (others => '0'));
  
  -- bitmap for zero element for faster copying from BRAM to STM32
  signal zero_map : std_logic_vector(32*32-1 downto 0);
  signal zero_map_dat : std_logic_vector(WB_DW-1 downto 0);
  signal zero_map_adr : std_logic_vector(5 downto 0);
  signal zero_dv : std_logic;
    
  -- state for math clock domain
  type state_t is (IDLE, EXEC, MATH_WB_SIGNAL);
  signal state : state_t := IDLE;

  -- state for wishbone clock domain
  type wb_state_t is (WB_IDLE, WB_FETCH, WB_DECODE, WB_EXEC, WB_WAIT_RDY);
  signal wb_state : wb_state_t := WB_IDLE;
  
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

  signal crossbar_dat_a_select  : std_logic_vector(2 downto 0);
  signal crossbar_dat_b_select  : std_logic_vector(2 downto 0);
  signal crossbar_dat_select_stack : std_logic_vector(5 downto 0);
  signal crossbar_we_select     : std_logic_vector(2 downto 0);
  signal crossbar_adr_select    : std_logic_vector(2*BRAMS-1 downto 0) := (others => '1');
  signal crossbar_adr_stack     : std_logic_vector(4*MUL_AW-1 downto 0);
  
  signal math_dat_a, math_dat_b, math_dat_c : std_logic_vector(MUL_DW-1 downto 0);
  signal math_adr_a, math_adr_b, math_adr_c : std_logic_vector(MUL_AW-1 downto 0);
  signal math_we, math_rdy, math_err : std_logic := '0';
  signal math_rst : std_logic := '1';
  signal math_scale_not_mul : std_logic := '0';
  signal math_sub_not_add : std_logic := '0';
  signal math_mov_type : std_logic_vector (1 downto 0) := "00";
  signal math_double_constant : std_logic_vector(MUL_DW-1 downto 0);
  signal math_hw_select : std_logic_vector(1 downto 0) := "00";
  signal math_dot_b_trn : std_logic := '0';
  signal math_m_size : std_logic_vector(4 downto 0);
  signal math_p_size : std_logic_vector(4 downto 0);
  signal math_n_size : std_logic_vector(4 downto 0);
  
  -- signals for clock domain crossing (Wishbone -> Math)
  signal crossbar_adr_select_wb   : std_logic_vector(2*BRAMS-1 downto 0) := (others => '1');
  signal crossbar_dat_a_select_wb : std_logic_vector(2 downto 0);
  signal crossbar_dat_b_select_wb : std_logic_vector(2 downto 0);
  signal crossbar_we_select_wb    : std_logic_vector(2 downto 0);
  signal math_hw_select_wb        : std_logic_vector(1 downto 0) := "00";
  signal math_dot_b_trn_wb        : std_logic := '0';
  signal math_mov_type_wb         : std_logic_vector(1 downto 0) := "00";
  signal math_scale_not_mul_wb    : std_logic := '0';
  signal math_sub_not_add_wb      : std_logic := '0';
  signal math_m_size_wb           : std_logic_vector(4 downto 0);
  signal math_p_size_wb           : std_logic_vector(4 downto 0);
  signal math_n_size_wb           : std_logic_vector(4 downto 0);
  signal math_rdy_wb, math_err_wb : std_logic := '0';
  signal data_valid_wb            : std_logic := '0';
  signal math_rst_wb              : std_logic := '1';
begin
                      
  ----------------------------------------------------------------------------------
  -- multiplex data from BRAMs into crossbar
  ----------------------------------------------------------------------------------
  wire_bram2mul_clk <= (others => clk_mul_i);
  wire_bram2mul_en  <= (others =>'1');
  
  -- connect all BRAM dat_i together
  fork_bram_dat_c : entity work.fork_reg(io)
  generic map (
    ocnt => BRAMS,
    DW   => MUL_DW
  )
  port map (
    clk_i => clk_mul_i,
    di => math_dat_c,
    do => wire_bram2mul_dat_i
  );
  
  -- Route WE line
  we_router : entity work.demuxer_reg(io)
  generic map (
    AW => 3, -- address width (select bits count)
    DW => 1,  -- data width 
    default => '0'
  )
  port map (
    clk_i => clk_mul_i,
    A     => crossbar_we_select,
    di(0) => math_we,
    do    => wire_bram2mul_we
  );

  -- Addres router from math to brams
  crossbar_adr_stack <= "0000000000" & math_adr_c & math_adr_b & math_adr_a;
  adr_abc_router : entity work.bus_matrix_reg(io)
  generic map (
    AW   => 2, -- address width in bits
    ocnt => BRAMS, -- output ports count
    DW   => MUL_AW -- data bus width 
  )
  port map (
    clk_i => clk_mul_i,
    A  => crossbar_adr_select,
    di => crossbar_adr_stack,
    do => wire_bram2mul_adr
  );

  -- connects BRAMs outputs to A and B inputs of math
  crossbar_dat_select_stack <= crossbar_dat_b_select & crossbar_dat_a_select;
  dat_ab_router : entity work.bus_matrix_reg(io)
  generic map (
    AW   => 3, -- address width in bits
    ocnt => 2, -- output ports count
    DW   => 64 -- data bus width 
  )
  port map (
    clk_i => clk_mul_i,
    A  => crossbar_dat_select_stack,
    di => wire_bram2mul_dat_o,
    do(127 downto 64) => math_dat_b,
    do(63  downto 0)  => math_dat_a
  );
  

  ----------------------------------------------------------------------------------
  -- Matrix math instance
  ----------------------------------------------------------------------------------
  mtrx_math : entity work.mtrx_math
  generic map (
    MTRX_AW => 5,
    BRAM_DW => MUL_DW,
    DAT_LAT => 10
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
    dot_tr_b_i => math_dot_b_trn,
    
    op_mov_i => math_mov_type,
    op_mul_i => math_scale_not_mul,
    op_add_i => math_sub_not_add,
    constant_i => math_double_constant
  );

  ----------------------------------------------------------------------------------
  -- Zero mapper
  ----------------------------------------------------------------------------------
  zero_mapper : entity work.zero_mapper
  port map (
    clk_i => clk_mul_i,
    rst_i => math_rst,
    ce_i  => math_we,
    dat_i => math_dat_c,
    dat_o => zero_map
  );
  
  zero2ctl : for n in 0 to 63 generate 
  begin
    math_ctl(ZERO_MAP_OFFSET + n) <= zero_map((n+1)*16-1 downto n*16);
  end generate;
  
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
  -- Math control logic
  ----------------------------------------------------------------------------------

  math_ctl_proc : process(clk_mul_i)
    -- delay need for slow WB part able to sample ERR and RDY lines
    constant DELAY : std_logic_vector(1 downto 0) := "10";
    variable cnt : std_logic_vector(1 downto 0) := DELAY;
  begin
    if rising_edge(clk_mul_i) then
      if math_rst_wb = '1' then
        state <= IDLE;
        math_rst <= '1';
        math_m_size           <= (others => '1');
        math_p_size           <= (others => '1');
        math_n_size           <= (others => '1');
        math_double_constant  <= (others => '0');
        math_hw_select        <= (others => '0');
        crossbar_adr_select   <= "1111111111100100";
        crossbar_dat_a_select <= (others => '0');
        crossbar_dat_b_select <= "001";
        crossbar_we_select    <= "010";
        math_mov_type         <= (others => '0');
        math_scale_not_mul    <= '0';
        math_sub_not_add      <= '0';
      else
        case state is
        -- data buffering from slow WB to fast MATH clock domain
        when IDLE =>
          math_m_size           <= math_ctl(SIZES_REG)(4 downto 0);
          math_p_size           <= math_ctl(SIZES_REG)(9 downto 5);
          math_n_size           <= math_ctl(SIZES_REG)(14 downto 10);
          math_double_constant  <= math_ctl(SCALE_REG3) &
                                   math_ctl(SCALE_REG2) &
                                   math_ctl(SCALE_REG1) &
                                   math_ctl(SCALE_REG0);
          math_hw_select        <= math_hw_select_wb;
          crossbar_adr_select   <= crossbar_adr_select_wb;
          crossbar_dat_a_select <= crossbar_dat_a_select_wb;
          crossbar_dat_b_select <= crossbar_dat_b_select_wb;
          crossbar_we_select    <= crossbar_we_select_wb;
          math_mov_type         <= math_mov_type_wb;
          math_scale_not_mul    <= math_scale_not_mul_wb;
          math_sub_not_add      <= math_sub_not_add_wb;
          math_dot_b_trn        <= math_dot_b_trn_wb;
          
          if data_valid_wb = '1' then
            state <= EXEC;
          end if;
          
        -- command execution
        when EXEC =>
          math_rst <= '0';
          if (math_rdy = '1') or (math_err = '1') then
            cnt := DELAY;
            math_rst <= '1';
            math_rdy_wb <= math_rdy;
            math_err_wb <= math_err;
            state <= MATH_WB_SIGNAL;
          end if;

        when MATH_WB_SIGNAL =>
          if (cnt /= "00") then
            cnt := cnt - 1;
          else
            math_rdy_wb <= '0';
            math_err_wb <= '0';
            state <= IDLE;
          end if;
        end case;

      end if; -- rst 
    end if; -- clk
  end process;


  ----------------------------------------------------------------------------------
  -- Math control logic
  ----------------------------------------------------------------------------------

  rdy_o  <= '1' when (wb_state = WB_IDLE) else '0';

  ack_o(SLAVES-1) <= ctl_ack_o;
  err_o(SLAVES-1) <= ctl_err_o;
  ctl_stb_i       <= stb_i(SLAVES-1);
  ctl_we_i        <= we_i(SLAVES-1);
  ctl_sel_i       <= sel_i(SLAVES-1);
  ctl_dat_i       <= dat_i(WB_DW*SLAVES-1 downto WB_DW*(SLAVES-1));
  ctl_adr_i       <= adr_i(WB_AW*SLAVES-1 downto WB_AW*(SLAVES-1));
  ctl_clk_i       <= clk_wb_i(SLAVES-1);
  dat_o(WB_DW*SLAVES-1 downto WB_DW*(SLAVES-1)) <= ctl_dat_o;
  
  control_logic : process(ctl_clk_i, rst_i)
    variable a_num, b_num, c_num : std_logic_vector(2 downto 0) := "000";
    variable dv : std_logic := '0'; -- data valid bit
    variable tr_flag : std_logic := '0';
    variable a, b, c : integer := 0;
    variable cmd_raw : natural range 0 to 15;
    variable hw_sel_v : std_logic_vector(1 downto 0); -- same as hw_sel_i
  begin
    if rst_i = '1' then
      wb_state <= WB_IDLE;
      math_rst_wb <= '1';
      data_valid_wb <= '0';
    else
      if rising_edge(ctl_clk_i) then
        ctl_ack_o <= '0';
        ctl_err_o <= '0';
        math_rst_wb <= '0';
        
        case wb_state is
        when WB_IDLE =>
          if (ctl_stb_i = '1' and ctl_sel_i = '1') then
            if (ctl_adr_i > CTL_ARRAY_LEN) then
              ctl_err_o <= '1';
            else
              ctl_ack_o <= '1';
              if (ctl_we_i = '1') then
                if (ctl_adr_i < ZERO_MAP_OFFSET) then
                  math_ctl(conv_integer(ctl_adr_i(2 downto 0))) <= ctl_dat_i;
                else
                  ctl_err_o <= '1';
                end if;
              else -- read request
                ctl_dat_o <= math_ctl(conv_integer(ctl_adr_i));
              end if;
            end if;
          end if;

          a_num   := math_ctl(CONTROL_REG)(2  downto 0);
          b_num   := math_ctl(CONTROL_REG)(5  downto 3);
          c_num   := math_ctl(CONTROL_REG)(8  downto 6);
          cmd_raw := conv_integer(math_ctl(CONTROL_REG)(12 downto 9));
          tr_flag := math_ctl(CONTROL_REG)(CMD_BIT_B_TR);
          dv      := math_ctl(CONTROL_REG)(CMD_BIT_DV);
          
          if dv = '1' then
            math_ctl(CONTROL_REG)(CMD_BIT_DV) <= '0';
            wb_state <= WB_FETCH;
          end if;

        when WB_FETCH =>
          -- select apropriate BRAMS via crossbar
          crossbar_dat_a_select_wb <= a_num;
          crossbar_dat_b_select_wb <= b_num;
          crossbar_we_select_wb    <= c_num;
          
          -- connect address buses
          a := conv_integer(a_num);
          b := conv_integer(b_num);
          c := conv_integer(c_num);
          crossbar_adr_select_wb <= (others => '1');
          crossbar_adr_select_wb((a+1)*2-1 downto a*2) <= "00";
          crossbar_adr_select_wb((b+1)*2-1 downto b*2) <= "01";
          crossbar_adr_select_wb((c+1)*2-1 downto c*2) <= "10";

          wb_state <= WB_DECODE;

        when WB_DECODE =>
          -- parse command
          case cmd_raw is
          when MATH_OP_MUL =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MUL, 2));
            math_hw_select_wb     <= hw_sel_v;
            math_scale_not_mul_wb <= '0'; -- differece between scale and mul
            wb_state <= WB_EXEC;
            
          when MATH_OP_SCALE =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MUL, 2));
            math_hw_select_wb     <= hw_sel_v;
            math_scale_not_mul_wb <= '1'; -- differece between scale and mul
            wb_state <= WB_EXEC;

          when MATH_OP_CPY =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
            math_hw_select_wb <= hw_sel_v;
            math_mov_type_wb  <= MOV_OP_CPY;
            wb_state <= WB_EXEC;

          when MATH_OP_DIA =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
            math_hw_select_wb <= hw_sel_v;
            math_mov_type_wb  <= MOV_OP_DIA;
            wb_state <= WB_EXEC;   
            
          when MATH_OP_TRN =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
            math_hw_select_wb <= hw_sel_v;
            math_mov_type_wb  <= MOV_OP_TRN;
            wb_state <= WB_EXEC;

          when MATH_OP_SET =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_MOV, 2));
            math_hw_select_wb <= hw_sel_v;
            math_mov_type_wb  <= MOV_OP_SET;
            wb_state <= WB_EXEC;          

          when MATH_OP_ADD =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_ADD, 2));
            math_hw_select_wb   <= hw_sel_v;
            math_sub_not_add_wb <= '0';
            wb_state <= WB_EXEC;   
            
          when MATH_OP_SUB =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_ADD, 2));
            math_hw_select_wb   <= hw_sel_v;
            math_sub_not_add_wb <= '1';
            wb_state <= WB_EXEC;   

          when MATH_OP_DOT =>
            hw_sel_v := std_logic_vector(to_unsigned(MATH_HW_DOT, 2));
            math_hw_select_wb <= hw_sel_v;
            math_dot_b_trn_wb <= tr_flag;
            wb_state <= WB_EXEC;
            
          when others =>
            wb_state <= WB_IDLE;
            ctl_err_o <= '1';
          end case;

        -- raise data valid flag for Math 
        when WB_EXEC =>
          data_valid_wb <= '1';
          wb_state <= WB_WAIT_RDY;

        when WB_WAIT_RDY =>
          data_valid_wb <= '0';
          if (math_rdy_wb = '1') or (math_err_wb = '1') then
            if math_err_wb = '1' then
              ctl_err_o <= '1';
              math_ctl(STATUS_REG) <= "00000000000000" & hw_sel_v;
            end if;
            wb_state <= WB_IDLE;
          end if;
        end case;
        
      end if; --rst
    end if; -- clk
  end process;

end beh;

