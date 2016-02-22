library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.mtrx_math_constants.all;

--
--
--
entity mtrx_mov is
Generic (
  MTRX_AW : positive := 5; -- 2**MTRX_AW = max matrix index
  BRAM_DW : positive := 64;
  -- Data latency. Contains
  -- 1) address path to BRAM
  -- 2) BRAM data latency (generally 1 cycle)
  -- 3) data path from BRAM to device
  DAT_LAT : positive range 1 to 15 := 1
);
Port (
  -- control interface
  rst_i  : in  std_logic; -- active high. Must be used before every new calculation
  clk_i  : in  std_logic;
  m_size_i, p_size_i, n_size_i : in  std_logic_vector(MTRX_AW-1 downto 0);
  err_o  : out std_logic; -- active high 1 clock
  rdy_o  : out std_logic; -- active high 1 clock
  -- operation select
  op_i : in std_logic_vector(1 downto 0);

  -- BRAM interface
  -- Note: there are no clocks for BRAMs. They are handle in higher level
  bram_adr_a_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  bram_adr_b_o : out std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0'); -- unused
  bram_adr_c_o : out std_logic_vector(2*MTRX_AW-1 downto 0);

  constant_i   : in  std_logic_vector(BRAM_DW-1 downto 0); -- external constant for memset and dia
  bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
  bram_dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0) := (others => '0'); -- unused
  bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
  bram_ce_a_o  : out std_logic;
  bram_ce_c_o  : out std_logic;
  bram_we_o    : out std_logic -- for C bram
);
end mtrx_mov;


-----------------------------------------------------------------------------

architecture beh of mtrx_mov is
  
  -- operand and result addresses registers
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  signal transpose_en : std_logic;
  signal bram_ce_we_combined : std_logic := '0';
  
  signal m_size, n_size : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;

  signal rst_iter   : std_logic := '1'; -- single reset for all iterators
  signal ce_a_iter  : std_logic := '0';
  signal ce_c_iter  : std_logic := '0';
  signal rdy_a_iter : std_logic := '0';
  signal rdy_c_iter : std_logic := '0';
  signal dia_stb    : std_logic := '0';

  -- signals for routing between data_a, constant, one64
  signal wire_tmp64 : std_logic_vector(BRAM_DW-1 downto 0);
  -- input data for operators
  signal op_dat : std_logic_vector(BRAM_DW-1 downto 0);

  constant ONE64 : std_logic_vector(BRAM_DW-1 downto 0) := x"3FF0000000000000"; -- 1.000000

  -- state machine
  type state_t is (IDLE, ADR_PRELOAD, DAT_PRELOAD, ACTIVE, FLUSH, HALT);
  signal state : state_t := IDLE;
  
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;
  
begin
  
  -- switch iterator between transpose and dia
  transpose_en <= '1' when (op_i = MOV_OP_TRN) else '0';
  
  -- select data input for operation
  -- double BRAM must be connected only to TRN or CPY
  wire_tmp64 <= bram_dat_a_i when (op_i = MOV_OP_TRN or op_i = MOV_OP_CPY) else constant_i;
  
  -- connect one64 constant to data input 
  -- when dia strobe high
  op_dat <= ONE64 when (dia_stb = '1' and op_i = MOV_OP_DIA) else wire_tmp64;
  
  --
  -- Iterator for input and output addresses
  --
  bram_ce_c_o <= bram_ce_we_combined;
  bram_we_o   <= bram_ce_we_combined;
  iterator : entity work.mtrx_mov_iter
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    clk_i  => clk_i,
    rst_i  => rst_iter,
    m_size => m_size,
    n_size => n_size,

    transpose_en => transpose_en,

    adr_a_o   => bram_adr_a_o,
    adr_c_o   => bram_adr_c_o,
    valid_a_o => bram_ce_a_o,
    valid_c_o => bram_ce_we_combined,
    end_a_o   => open, -- rdy_a_iter,
    end_c_o   => rdy_c_iter,
    ce_a_i    => ce_a_iter,
    ce_c_i    => ce_c_iter,

    dia_stb_o => dia_stb
  );
  
  
  -- connect BRAM signals
  --bram_we_o    <= result_we;
  bram_dat_c_o <= op_dat;--result_buf;
  
  
  --
  -- Main state machine
  --
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state <= IDLE;
        rdy_o <= '0';
        err_o <= '0';
        rst_iter  <= '1';
        ce_a_iter <= '0';
        ce_c_iter <= '0';
        lat_i <= DAT_LAT;
        lat_o <= DAT_LAT / 2;
      else        
        rdy_o <= '0';
        err_o <= '0';  
        
        case state is
        when IDLE =>
          if (p_size_i > 0) -- error
          or ((m_size_i /= n_size_i) and (op_i = MOV_OP_DIA)) -- only square matices allowed for DIA
          then
            err_o <= '1';
            state <= HALT;
          else
            m_size <= m_size_i;
            n_size <= n_size_i;
            state  <= ADR_PRELOAD;
          end if;
          
        when ADR_PRELOAD =>
          rst_iter  <= '0';
          ce_a_iter <= '1';
          lat_i <= lat_i - 1;
          state <= DAT_PRELOAD;
          
        when DAT_PRELOAD =>
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state <= ACTIVE;
            ce_c_iter <= '1';
          end if;
         
        when ACTIVE =>
          if rdy_c_iter = '1' then
            rst_iter  <= '1';
            ce_a_iter <= '0';
            ce_c_iter <= '0';
            state     <= FLUSH;
          end if;

        when FLUSH =>
          lat_o <= lat_o - 1;
          if (lat_o = 0) then
            state <= HALT;
            rdy_o <= '1';
          end if;

        when HALT =>
          state <= HALT;
          
        end case;
      end if; -- clk
    end if; -- rst
  end process;


end beh;






