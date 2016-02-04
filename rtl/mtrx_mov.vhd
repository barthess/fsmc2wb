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
    size_i : in  std_logic_vector(15 downto 0); -- size of input operands
    err_o  : out std_logic := '0'; -- active high 1 clock
    rdy_o  : out std_logic := '0'; -- active high 1 clock
    -- operation select
    op_i : in std_logic_vector(1 downto 0);

    -- BRAM interface
    -- Note: there are no clocks for BRAMs. They are handle in higher level
    bram_adr_a_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
    bram_adr_c_o : out std_logic_vector(2*MTRX_AW-1 downto 0);

    constant_i   : in  std_logic_vector(BRAM_DW-1 downto 0); -- external constant for memset and eye
    bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
    bram_we_o    : out std_logic -- for C bram
  );
end mtrx_mov;


-----------------------------------------------------------------------------

architecture beh of mtrx_mov is
  
  -- operand and result addresses registers
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  constant OP_CPY : std_logic_vector (1 downto 0) := "00";
  constant OP_EYE : std_logic_vector (1 downto 0) := "01";
  constant OP_TRN : std_logic_vector (1 downto 0) := "10";
  constant OP_SET : std_logic_vector (1 downto 0) := "11";
  
  signal m_size, n_size : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;

  signal c_adr : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal c_adr_trn, c_adr_eye : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  
  signal rst_iter_eye, rst_iter_trn : std_logic := '1';
  signal rst_i_iter : std_logic := '1';
  signal rst_o_iter : std_logic := '1';
  signal rdy_i_iter : std_logic := '0';
  signal rdy_o_iter : std_logic := '0';
  signal rdy_iter_trn : std_logic := '0';
  signal rdy_iter_eye : std_logic := '0';
  
  signal sel_iter : std_logic_vector (0 downto 0);
  signal stb_iter_eye : std_logic := '0';

  -- signals for routing between data_a, constant, one64
  signal wire_tmp64 : std_logic_vector(BRAM_DW-1 downto 0);
  -- input data for operators
  signal op_dat : std_logic_vector(BRAM_DW-1 downto 0);

  constant ONE64 : std_logic_vector(BRAM_DW-1 downto 0) := x"3FF0000000000000"; -- 1.000000
  signal result_buf : std_logic_vector(BRAM_DW-1 downto 0) := (others => '0');
  signal result_we : std_logic := '0';

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;
  
begin
  
  -- switch iterator between transpose and eye
  sel_iter <= "0" when (op_i = OP_TRN) else "1";
  
  -- resolution function for 2 ready signals
  rdy_o_iter <= '1' when (rdy_iter_eye = '1' or rdy_iter_trn = '1') else '0';
  
  -- switch between iteratos
  rst_o_demuxer : entity work.demuxer
  generic map(
    AW => 1,
    DW => 1,
    default => '1'
  )
  port map(
    A     => sel_iter,
    di(0) => rst_o_iter,
    do(1) => rst_iter_eye,
    do(0) => rst_iter_trn
  );
  
  -- switch between iteratos
  c_adr_muxer : entity work.muxer
  generic map(
    AW => 1,
    DW => 2*MTRX_AW
  )
  port map(
    A  => sel_iter,
    di => c_adr_eye & c_adr_trn,
    do => c_adr
  );

  -- select data input for operation
  -- double BRAM must be connected only to TRN or CPY
  wire_tmp64 <= bram_dat_a_i when (op_i = OP_TRN or op_i = OP_CPY) else constant_i;
  
  -- connect one64 constant to data input 
  -- when eye strobe high
  op_dat <= wire_tmp64 when (stb_iter_eye = '0') else ONE64;
  
  -- sequential address generator for 
  -- A address
  -- connected directly to output without muxers
  iter_seq : entity work.mtrx_iter_seq
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_i_iter,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    rdy_o  => rdy_i_iter,
    adr_o  => bram_adr_a_o
  );

  -- transposed address generator for 
  -- C address
  -- output must be connected via muxer
  iter_trn : entity work.mtrx_iter_trn
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_iter_trn,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    rdy_o  => rdy_iter_trn,
    adr_o  => c_adr_trn
  );

  -- transposed address generator for 
  -- C address
  -- output must be connected via muxer
  -- Suitable for:
  -- CPY, EYE, SET
  iter_eye : entity work.mtrx_iter_eye
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_iter_eye,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    rdy_o  => rdy_iter_eye,
    eye_o  => stb_iter_eye,
    adr_o  => c_adr_eye
  );
  
  -- connect BRAM signals
  bram_adr_c_o <= c_adr;
  bram_we_o    <= result_we;
  bram_dat_c_o <= result_buf;


  --
  -- Main state machine
  --
  main : process(clk_i)
    variable m_tmp, n_tmp : std_logic_vector(MTRX_AW-1 downto 0);
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state <= IDLE;
        result_we <= '0';
        rdy_o <= '0';
        err_o <= '0';
        rst_i_iter <= '1';
        rst_o_iter <= '1';
      else        
        rdy_o <= '0';
        err_o <= '0';  
        
        case state is
        when IDLE =>
          m_tmp := size_i(MTRX_AW-1   downto 0);
          n_tmp := size_i(2*MTRX_AW-1 downto MTRX_AW);
          if (size_i(15 downto 2*MTRX_AW) > 0) -- overflow
          or ((n_tmp /= m_tmp) and (op_i = OP_EYE)) -- only square matices allowed for EYE
          then
            err_o <= '1';
            state <= HALT;
          else
            m_size <= m_tmp;
            n_size <= n_tmp;
            rst_i_iter <= '0';
            lat_i <= lat_i - 1;
            state <= PRELOAD;
          end if;

        when PRELOAD =>
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state <= ACTIVE;
            rst_o_iter <= '0';
            result_we <= '1';
            result_buf <= op_dat;
          end if;
         
        when ACTIVE =>
          if rdy_o_iter = '1' then
            rst_i_iter <= '1';
            rst_o_iter <= '1';
            result_we <= '0';
            rdy_o <= '1';
            state <= HALT;
          end if;

        when HALT =>
          state <= HALT;
          
        end case;
      end if; -- clk
    end if; -- rst
  end process;


end beh;






