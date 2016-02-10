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

entity mtrx_math is
Generic (
  MTRX_AW : positive := 5;
  BRAM_DW : positive := 64;
  DAT_LAT : positive range 1 to 15 := 1
);
Port (
  clk_i : in  std_logic;
  rst_i : in  std_logic;
  sel_i : in  std_logic_vector(1 downto 0); -- math block selector

  rdy_o : out std_logic; -- data ready external interrupt. Active high 1 clock cycle
  err_o : out std_logic; -- Active high until slave resetted

  adr_a_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  adr_b_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  adr_c_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
  dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0);
  dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
  we_o    : out std_logic; -- WE for C matrix

  m_size_i, p_size_i, n_size_i : in std_logic_vector(MTRX_AW-1 downto 0); -- operand sizes

  op_mov_i   : in std_logic_vector(1 downto 0); -- specify move operation
  op_mul_i   : in std_logic; -- specify Adamar multiplication or scale
  op_add_i   : in std_logic; -- specify addition or substraction
  constant_i : in std_logic_vector(BRAM_DW-1 downto 0) -- external constant for memset of scale
);
end mtrx_math;

-----------------------------------------------------------------------------

architecture beh of mtrx_math is

  -- wires with data from differnt matrix math
  constant BRAM_AW : positive := 2*MTRX_AW;
  signal math_dat_a, math_dat_b, math_dat_c : std_logic_vector(MATH_HW_TOTAL*BRAM_DW-1 downto 0);
  signal math_adr_a, math_adr_b, math_adr_c : std_logic_vector(MATH_HW_TOTAL*BRAM_AW-1 downto 0);
  signal math_we, math_rdy, math_err, math_rst : std_logic_vector(MATH_HW_TOTAL-1 downto 0) := (others => '0');
  signal math_m_size, math_p_size, math_n_size : std_logic_vector(MATH_HW_TOTAL*MTRX_AW-1 downto 0);
  signal math_constant : std_logic_vector(2*BRAM_DW-1 downto 0);

  -- control signals. Used to switch between direct/buffered connection
  signal math_scale_not_mul : std_logic := '0';
  signal math_sub_not_add : std_logic := '0';
  signal math_mov_type : std_logic_vector (1 downto 0) := "00";

begin
                      
  ----------------------------------------------------------------------------------
  -- multiplex data from different matrix operations into dot bar
  ----------------------------------------------------------------------------------

--  math_scale_not_mul <= op_mul_i;
--  math_sub_not_add   <= op_add_i;
--  math_mov_type      <= op_mov_i;

  op_mul_delay : entity work.delay
  generic map (
    LAT => DAT_LAT,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => op_mul_i,
    do(0) => math_scale_not_mul
  );

  op_add_delay : entity work.delay
  generic map (
    LAT => DAT_LAT,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => op_add_i,
    do(0) => math_sub_not_add
  );

  op_mov_delay : entity work.delay
  generic map (
    LAT => DAT_LAT,
    WIDTH => 2,
    default => '0'
  )
  port map (
    clk => clk_i,
    ce  => '1',
    di  => op_mov_i,
    do  => math_mov_type
  );


  -- fan out DAT bus A
  fork_dat_a : entity work.fork_reg(io)
  generic map (
    ocnt => MATH_HW_TOTAL,
    DW   => BRAM_DW
  )
  port map (
    clk_i => clk_i,
    di => dat_a_i,
    do => math_dat_a
  );
  
  -- fan out DAT bus B
  fork_dat_b : entity work.fork_reg(io)
  generic map (
    ocnt => MATH_HW_TOTAL,
    DW   => BRAM_DW
  )
  port map (
    clk_i => clk_i,
    di => dat_b_i,
    do => math_dat_b
  );
  
  -- Multiplex DAT bus C
  mux_dat_c : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => BRAM_DW
  )
  port map (
    clk_i => clk_i,
    A  => sel_i,
    do => dat_c_o,
    di => math_dat_c
  );

  -- Multiplex ADR for bus A
  mux_adr_a : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 2*MTRX_AW
  )
  port map (
    clk_i => clk_i,
    A  => sel_i,
    do => adr_a_o,
    di => math_adr_a
  );
  
  -- Multiplex ADR for bus B
  mux_adr_b : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 2*MTRX_AW
  )
  port map (
    clk_i => clk_i,
    A  => sel_i,
    do => adr_b_o,
    di => math_adr_b
  );
  
  -- Multiplex ADR for bus C
  mux_math_adr_c : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 2*MTRX_AW
  )
  port map (
    clk_i => clk_i,
    A  => sel_i,
    do => adr_c_o,
    di => math_adr_c
  );
  
  -- Multiplex WE
  mux_we : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 1
  )
  port map (
    clk_i => clk_i,
    A     => sel_i,
    do(0) => we_o,
    di    => math_we
  );

  -- Multiplex ERR
  mux_err : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 1
  )
  port map (
    clk_i => clk_i,
    A     => sel_i,
    do(0) => err_o,
    di    => math_err
  );

  -- Multiplex ERR
  mux_rdy : entity work.muxer_reg(io)
  generic map (
    AW => 2,
    DW => 1
  )
  port map (
    clk_i => clk_i,
    A     => sel_i,
    do(0) => rdy_o,
    di    => math_rdy
  );

  -- Demuxer for RST
  rst_demux : entity work.demuxer_reg(io)
  generic map (
    AW => 2, -- address width (select bits count)
    DW => 1,  -- data width 
    default => '1'
  )
  port map (
    clk_i => clk_i,
    A     => sel_i,
    di(0) => rst_i,
    do    => math_rst
  );

  -- fanout M size to all math
  fork_m_size : entity work.fork_reg(io)
  generic map (
    ocnt => MATH_HW_TOTAL,
    DW   => MTRX_AW
  )
  port map (
    clk_i => clk_i,
    di => m_size_i,
    do => math_m_size
  );

  -- fanout P size to all math
  fork_p_size : entity work.fork_reg(io)
  generic map (
    ocnt => MATH_HW_TOTAL,
    DW   => MTRX_AW
  )
  port map (
    clk_i => clk_i,
    di => p_size_i,
    do => math_p_size
  );

  -- fanout N size to all math
  fork_n_size : entity work.fork_reg(io)
  generic map (
    ocnt => MATH_HW_TOTAL,
    DW   => MTRX_AW
  )
  port map (
    clk_i => clk_i,
    di => n_size_i,
    do => math_n_size
  );

  -- fanout constant to mov and mul
  fork_constant : entity work.fork_reg(io)
  generic map (
    ocnt => 2,
    DW   => BRAM_DW
  )
  port map (
    clk_i => clk_i,
    di => constant_i,
    do => math_constant
  );


  ----------------------------------------------------------------------------------
  -- Instantiate matrix math
  ----------------------------------------------------------------------------------

  --
  -- MUL
  --
  mtrx_mul : entity work.mtrx_mul
  generic map (
    MTRX_AW => MTRX_AW,
    BRAM_DW => BRAM_DW,
    DAT_LAT => DAT_LAT
  )
  port map (
    rdy_o => math_rdy(MATH_HW_MUL),
    
    -- control interface
    clk_i  => clk_i,
    rst_i  => math_rst(MATH_HW_MUL),
    err_o  => math_err(MATH_HW_MUL),
    m_size_i => math_m_size((MATH_HW_MUL+1)*MTRX_AW-1 downto MATH_HW_MUL*MTRX_AW),
    p_size_i => math_p_size((MATH_HW_MUL+1)*MTRX_AW-1 downto MATH_HW_MUL*MTRX_AW),
    n_size_i => math_n_size((MATH_HW_MUL+1)*MTRX_AW-1 downto MATH_HW_MUL*MTRX_AW),

    scale_not_mul_i => math_scale_not_mul,
    scale_factor_i  => math_constant(BRAM_DW-1 downto 0),
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_HW_MUL+1)*BRAM_AW-1 downto MATH_HW_MUL*BRAM_AW),
    bram_adr_b_o => math_adr_b((MATH_HW_MUL+1)*BRAM_AW-1 downto MATH_HW_MUL*BRAM_AW),
    bram_adr_c_o => math_adr_c((MATH_HW_MUL+1)*BRAM_AW-1 downto MATH_HW_MUL*BRAM_AW),
    
    bram_dat_a_i => math_dat_a((MATH_HW_MUL+1)*BRAM_DW-1 downto MATH_HW_MUL*BRAM_DW),
    bram_dat_b_i => math_dat_b((MATH_HW_MUL+1)*BRAM_DW-1 downto MATH_HW_MUL*BRAM_DW),
    bram_dat_c_o => math_dat_c((MATH_HW_MUL+1)*BRAM_DW-1 downto MATH_HW_MUL*BRAM_DW),
    bram_we_o    => math_we(MATH_HW_MUL)
  );

  -- 
  -- MOV
  --
  mtrx_mov : entity work.mtrx_mov
  generic map (
    MTRX_AW => MTRX_AW,
    BRAM_DW => BRAM_DW,
    DAT_LAT => DAT_LAT
  )
  port map (
    rdy_o => math_rdy(MATH_HW_MOV),
    
    -- control interface
    clk_i  => clk_i,
    rst_i  => math_rst(MATH_HW_MOV),
    err_o  => math_err(MATH_HW_MOV),

    m_size_i => math_m_size((MATH_HW_MOV+1)*MTRX_AW-1 downto MATH_HW_MOV*MTRX_AW),
    p_size_i => math_p_size((MATH_HW_MOV+1)*MTRX_AW-1 downto MATH_HW_MOV*MTRX_AW),
    n_size_i => math_n_size((MATH_HW_MOV+1)*MTRX_AW-1 downto MATH_HW_MOV*MTRX_AW),
    
    op_i   => math_mov_type,
    constant_i => math_constant(2*BRAM_DW-1 downto BRAM_DW),
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_HW_MOV+1)*BRAM_AW-1 downto MATH_HW_MOV*BRAM_AW),
    bram_adr_b_o => math_adr_b((MATH_HW_MOV+1)*BRAM_AW-1 downto MATH_HW_MOV*BRAM_AW),
    bram_adr_c_o => math_adr_c((MATH_HW_MOV+1)*BRAM_AW-1 downto MATH_HW_MOV*BRAM_AW),
    
    bram_dat_a_i => math_dat_a((MATH_HW_MOV+1)*BRAM_DW-1 downto MATH_HW_MOV*BRAM_DW),
    bram_dat_b_i => math_dat_b((MATH_HW_MOV+1)*BRAM_DW-1 downto MATH_HW_MOV*BRAM_DW),
    bram_dat_c_o => math_dat_c((MATH_HW_MOV+1)*BRAM_DW-1 downto MATH_HW_MOV*BRAM_DW),
    bram_we_o    => math_we(MATH_HW_MOV)
  );
  
  --
  -- ADD
  --
  mtrx_add : entity work.mtrx_add
  generic map (
    MTRX_AW => 5,
    BRAM_DW => BRAM_DW,
    DAT_LAT => DAT_LAT
  )
  port map (
    rdy_o => math_rdy(MATH_HW_ADD),
    
    -- control interface
    clk_i  => clk_i,
    rst_i  => math_rst(MATH_HW_ADD),
    err_o  => math_err(MATH_HW_ADD),

    m_size_i => math_m_size((MATH_HW_ADD+1)*MTRX_AW-1 downto MATH_HW_ADD*MTRX_AW),
    p_size_i => math_p_size((MATH_HW_ADD+1)*MTRX_AW-1 downto MATH_HW_ADD*MTRX_AW),
    n_size_i => math_n_size((MATH_HW_ADD+1)*MTRX_AW-1 downto MATH_HW_ADD*MTRX_AW),
    
    sub_not_add_i => math_sub_not_add,
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_HW_ADD+1)*BRAM_AW-1 downto MATH_HW_ADD*BRAM_AW),
    bram_adr_b_o => math_adr_b((MATH_HW_ADD+1)*BRAM_AW-1 downto MATH_HW_ADD*BRAM_AW),
    bram_adr_c_o => math_adr_c((MATH_HW_ADD+1)*BRAM_AW-1 downto MATH_HW_ADD*BRAM_AW),
    
    bram_dat_a_i => math_dat_a((MATH_HW_ADD+1)*BRAM_DW-1 downto MATH_HW_ADD*BRAM_DW),
    bram_dat_b_i => math_dat_b((MATH_HW_ADD+1)*BRAM_DW-1 downto MATH_HW_ADD*BRAM_DW),
    bram_dat_c_o => math_dat_c((MATH_HW_ADD+1)*BRAM_DW-1 downto MATH_HW_ADD*BRAM_DW),
    bram_we_o    => math_we(MATH_HW_ADD)
  );
  
  --
  -- DOT
  -- 
  mtrx_dot : entity work.mtrx_dot
  generic map (
    MTRX_AW => MTRX_AW,
    BRAM_DW => BRAM_DW,
    DAT_LAT => DAT_LAT
  )
  port map (
    rdy_o => math_rdy(MATH_HW_DOT),
    
    -- control interface
    clk_i   => clk_i,
    rst_i   => math_rst(MATH_HW_DOT),
    err_o   => math_err(MATH_HW_DOT),

    m_size_i => math_m_size((MATH_HW_DOT+1)*MTRX_AW-1 downto MATH_HW_DOT*MTRX_AW),
    p_size_i => math_p_size((MATH_HW_DOT+1)*MTRX_AW-1 downto MATH_HW_DOT*MTRX_AW),
    n_size_i => math_n_size((MATH_HW_DOT+1)*MTRX_AW-1 downto MATH_HW_DOT*MTRX_AW),
    
    -- BRAM interface
    bram_adr_a_o => math_adr_a((MATH_HW_DOT+1)*BRAM_AW-1 downto MATH_HW_DOT*BRAM_AW),
    bram_adr_b_o => math_adr_b((MATH_HW_DOT+1)*BRAM_AW-1 downto MATH_HW_DOT*BRAM_AW),
    bram_adr_c_o => math_adr_c((MATH_HW_DOT+1)*BRAM_AW-1 downto MATH_HW_DOT*BRAM_AW),
    
    bram_dat_a_i => math_dat_a((MATH_HW_DOT+1)*BRAM_DW-1 downto MATH_HW_DOT*BRAM_DW),
    bram_dat_b_i => math_dat_b((MATH_HW_DOT+1)*BRAM_DW-1 downto MATH_HW_DOT*BRAM_DW),
    bram_dat_c_o => math_dat_c((MATH_HW_DOT+1)*BRAM_DW-1 downto MATH_HW_DOT*BRAM_DW),
    bram_we_o    => math_we(MATH_HW_DOT)
  );


end beh;

