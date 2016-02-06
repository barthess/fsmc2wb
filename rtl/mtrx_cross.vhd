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

--
-- multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
--
entity mtrx_cross is
Generic (
  BRAM_DW : positive := 64;
  -- 2**MTRX_AW is maximum allowable index of matrices
  -- need for correct adder chain instantiation
  MTRX_AW : positive := 5;
  -- Data latency. Consist of:
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
  err_o  : out std_logic; -- active high 1 clock
  rdy_o  : out std_logic; -- active high 1 clock

  -- BRAM interface
  -- Note: there are no clocks for BRAMs. They are handle in higher level
  bram_adr_a_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  bram_adr_b_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  bram_adr_c_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
  
  bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
  bram_dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0);
  bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
  bram_ce_a_o  : out std_logic;
  bram_ce_b_o  : out std_logic;
  bram_ce_c_o  : out std_logic;
  bram_we_o    : out std_logic -- for C bram
);
end mtrx_cross;


-----------------------------------------------------------------------------

architecture beh of mtrx_cross is

  -- multiplicator control signals
  signal mul_nd : std_logic := '0';
  signal mul_ce : std_logic := '0';
  signal mul_rdy : std_logic; -- connected to accumulator nd

  -- matrices size registers
  signal mtrx_m : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  signal mtrx_p : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  signal mtrx_n : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  
  signal bram_ce_ab  : std_logic := '0';
  signal ab_iter_rst : std_logic := '1';
  signal ab_iter_ce  : std_logic := '0';
  signal ab_iter_end : std_logic;
  signal c_iter_rst  : std_logic := '1';
  signal c_iter_ce   : std_logic := '0';
  signal c_iter_end  : std_logic;
  signal mul_nd_ce   : std_logic := '0';
  
  -- accumulator control signals
  signal accum_rst : std_logic := '1';
  signal accum_len : STD_LOGIC_VECTOR (MTRX_AW-1 downto 0) := (others => '0');
  signal accum_dat_i : std_logic_vector(BRAM_DW-1 downto 0); -- to multiplicator output
  signal accum_rdy : std_logic := '0'; -- used to increment overall operation count
  
  -- state machine
  type state_t is (IDLE, ADR_PRELOAD, DAT_PRELOAD, ACTIVE, FLUSH, HALT);
  signal state : state_t := IDLE;
  
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;
  
begin
  
  -- ce for input brams driven together
  bram_ce_a_o <= bram_ce_ab;
  bram_ce_b_o <= bram_ce_ab;
  
  --
  -- addres incrementer for input matrices
  --
  ab_iterator : entity work.mtrx_iter_cross
  generic map (
    WIDTH => 5
  )
  port map (
    clk_i => clk_i,
    rst_i => ab_iter_rst,
    ce_i  => ab_iter_ce,
    end_o => ab_iter_end,
    dv_o  => bram_ce_ab,
    
    m_i => mtrx_m,
    p_i => mtrx_p,
    n_i => mtrx_n,
    
    a_adr_o => bram_adr_a_o,
    b_adr_o => bram_adr_b_o
  );
  
  --
  -- output address iterator
  --
  c_iterator : entity work.mtrx_iter_seq
  generic map (
    MTRX_AW => 5
  )
  port map (
    clk_i => clk_i,
    rst_i => c_iter_rst,
    ce_i  => c_iter_ce,
    m_i   => mtrx_m,
    n_i   => mtrx_n,
    end_o => c_iter_end,
    dv_o  => bram_ce_c_o,
    adr_o => bram_adr_c_o
  );

  --
  -- delay line connecting data_valid signal from input address
  -- iterator to operation_nd and ce of the multiplier
  --
  add_nd_delay : entity work.delay
  generic map (
    LAT => DAT_LAT,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => bram_ce_ab,
    do(0) => mul_nd_ce
  );
  mul_ce <= mul_nd_ce;
  mul_nd <= mul_nd_ce;
  
  --
  -- multiplicator
  --
  dmul : entity work.dmul
  port map (
    a      => bram_dat_a_i,
    b      => bram_dat_b_i,
    result => accum_dat_i, -- connected directly to accumulator
    clk    => clk_i,
    ce     => mul_ce,
    rdy    => mul_rdy, -- connect to accumulator nd
    operation_nd => mul_nd
  );

  -- 
  -- data accumulator
  --
  accumulator : entity work.dadd_chain
  generic map (
    LEN => MTRX_AW
  )
  port map (
    clk_i => clk_i,
    rst_i => accum_rst,
    nd_i  => mul_rdy,
    cnt_i => accum_len,
    dat_i => accum_dat_i,
    dat_o => bram_dat_c_o,
    rdy_o => accum_rdy
  );

  -- bram WE and C iterator CE driven together
  bram_we_o <= accum_rdy;
  c_iter_ce <= accum_rdy;

  --
  -- Main state machine
  --
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        accum_rst   <= '1';
        ab_iter_rst <= '1';
        c_iter_rst  <= '1';
        state <= IDLE;
        lat_i <= DAT_LAT;
        lat_o <= DAT_LAT / 2;
      else
        case state is
        when IDLE =>
          accum_rst   <= '1';
          ab_iter_rst <= '1';
          c_iter_rst  <= '1';
          
          if size_i(15) = '1' then
            err_o <= '1';
            state <= HALT;
          else
            mtrx_m    <= size_i(4 downto 0);
            mtrx_p    <= size_i(9 downto 5);
            mtrx_n    <= size_i(14 downto 10);
            accum_len <= size_i(9 downto 5);
            state     <= ADR_PRELOAD;
          end if;
        
        when ADR_PRELOAD =>
          ab_iter_rst <= '0';
          c_iter_rst  <= '0';
          accum_rst   <= '0';
          ab_iter_ce  <= '1';
          if bram_ce_ab = '1' then
            lat_i <= lat_i - 1;
            state <= DAT_PRELOAD;
          end if;
        
        when DAT_PRELOAD => 
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state <= ACTIVE;
          end if;
          
         when ACTIVE =>
          if c_iter_end = '1' then
            ab_iter_rst <= '1';
            c_iter_rst  <= '1';
            ab_iter_ce  <= '0';
            state       <= FLUSH;
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

      end if; -- rst
    end if; -- clk
  end process;

end beh;

