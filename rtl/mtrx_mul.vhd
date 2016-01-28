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
entity mtrx_mul is
  Generic (
    WB_AW   : positive := 16;
    WB_DW   : positive := 16;
    BRAM_AW : positive := 10;
    BRAM_DW : positive := 64;
    MTRX_AW : positive := 5   -- 2**MTRX_AW is maximum allowable index of matrices
  );
  Port (
    -- external interrupt pin
    dat_rdy_o : out std_logic;
    
    -- control WB interface
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    err_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(WB_AW-1 downto 0);
    dat_o : out std_logic_vector(WB_DW-1 downto 0);
    dat_i : in  std_logic_vector(WB_DW-1 downto 0);

    -- BRAM interface
    bram_clk_o  : out std_logic_vector(3-1          downto 0);
    bram_adr_o  : out std_logic_vector(3*BRAM_AW-1  downto 0);
    bram_dat_i  : in  std_logic_vector(3*BRAM_DW-1  downto 0);
    bram_dat_o  : out std_logic_vector(3*BRAM_DW-1  downto 0);
    bram_we_o   : out std_logic_vector(3-1          downto 0);
    bram_en_o   : out std_logic_vector(3-1          downto 0)
  );
end mtrx_mul;


-----------------------------------------------------------------------------

architecture beh of mtrx_mul is
  
  -- operand and result addresses registers
  signal A_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal B_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal C_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  
  -- multiplicator control signals
  signal mul_nd : std_logic := '0';
  signal mul_ce : std_logic := '0';
  signal mul_rdy : std_logic; -- connected to accumulator nd

  -- matrices size registers
  signal mtrx_m : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  signal mtrx_p : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  signal mtrx_n : std_logic_vector (MTRX_AW-1 downto 0) := (others => '0');
  -- counter for detecting end of matrix multiplication. Its width looks 
  -- strange because it must be able to store multiplication of matrices sizes
  signal accum_rdy_cnt : std_logic_vector((MTRX_AW+1)*2 - 1 downto 0) := (others => '0');
  signal multiplication_finished : std_logic := '0';
  signal adr_incr_rst : std_logic := '1';
  signal adr_incr_end : std_logic := '0';
  signal adr_incr_dv  : std_logic := '0';

  -- accumulator control signals
  signal accum_rst : std_logic := '1';
  signal accum_cnt : STD_LOGIC_VECTOR (MTRX_AW-1 downto 0) := (others => '0');
  signal accum_dat_i : std_logic_vector(BRAM_DW-1 downto 0); -- to multiplicator output
  signal accum_rdy : std_logic := '0'; -- used to increment overall operation count
  
  -- state machine
  type state_t is (IDLE, WAIT_ADR_VALID, ACTIVE, FLUSH1, FLUSH2);
  signal state : state_t := IDLE;

begin
  
  -- warning suppressor
  bram_dat_o(2*BRAM_DW-1 downto 0) <= bram_dat_i(3*BRAM_DW-1 downto 2*BRAM_DW) & bram_dat_i(3*BRAM_DW-1 downto 2*BRAM_DW);
  
  bram_adr_o(3*BRAM_AW-1 downto 2*BRAM_AW) <= C_adr;
  bram_adr_o(2*BRAM_AW-1 downto 1*BRAM_AW) <= B_adr;
  bram_adr_o(1*BRAM_AW-1 downto 0*BRAM_AW) <= A_adr;
  bram_clk_o <= (others => clk_i);
  bram_en_o  <= (others => '1');
  bram_we_o(0) <= '0';
  bram_we_o(1) <= '0';
  bram_we_o(2) <= mul_rdy;

  dat_rdy_o  <= '1' when (state = IDLE) else '0';

  --
  -- addres incrementer
  --
  adr_calc : entity work.adr4mul
    generic map (
      WIDTH => 5
    )
    port map (
      clk_i => clk_i,
      rst_i => adr_incr_rst,
      
      row_rdy_o => open,
      end_o => adr_incr_end,
      dv_o  => adr_incr_dv,
      
      m_i => mtrx_m,
      p_i => mtrx_p,
      n_i => mtrx_n,
      
      a_adr_o  => A_adr,
      b_adr_o  => B_adr,
      a_tran_i => '0',
      b_tran_i => '0'
    );

  --
  -- multiplicator
  --
  dmul : entity work.dmul
    port map (
      a      => bram_dat_i(1*BRAM_DW-1 downto 0*BRAM_DW),
      b      => bram_dat_i(2*BRAM_DW-1 downto 1*BRAM_DW),
      result => accum_dat_i,
      clk    => clk_i,
      ce     => mul_ce,
      rdy    => mul_rdy,
      operation_nd => mul_nd
    );

  -- 
  -- data accumulator
  --
  accumulator : entity work.dadd_chain
    generic map (
      LEN => 5
    )
    port map (
      clk_i => clk_i,
      rst_i => accum_rst,
      nd_i  => mul_rdy,
      cnt_i => accum_cnt,
      dat_i => accum_dat_i,
      dat_o => bram_dat_o(3*BRAM_DW-1 downto 2*BRAM_DW),
      rdy_o => accum_rdy
    );

  --
  -- address increment for result matrix
  -- total operation tracker
  --
  op_tracker : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      multiplication_finished <= '0';
      
      if accum_rst = '0' then
        if (accum_rdy = '1') then
          if (C_adr = accum_rdy_cnt) then
            multiplication_finished <= '1';
          end if;
          C_adr <= C_adr + 1;
        end if;
      else
        C_adr <= (others => '0');
      end if;
    end if;
  end process;

  --
  -- Main state machine
  --
  main : process(clk_i)
    variable tmp_m, tmp_n : std_logic_vector(MTRX_AW downto 0);
  begin
    --dat_o(WB_AW-1 downto BRAM_AW) <= (others => '0');
    dat_o <= (others => '0');
    
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        adr_incr_rst <= '1';
        accum_rst    <= '1';
        
        if (stb_i = '1' and sel_i = '1' and we_i = '1') then
          err_o <= '0';
          ack_o <= '1';
          state <= WAIT_ADR_VALID;

          mtrx_m <= dat_i(4 downto 0);
          mtrx_p <= dat_i(9 downto 5);
          mtrx_n <= dat_i(14 downto 10);
          adr_incr_rst <= '0';
          
          tmp_m := ('0' & dat_i(4 downto 0)) + 1;
          tmp_n := ('0' & dat_i(14 downto 10)) + 1;
          accum_rdy_cnt <= tmp_m * tmp_n;
      
          accum_cnt <= dat_i(9 downto 5);
        else
          err_o <= '1';
          ack_o <= '0';
        end if;
        
      when WAIT_ADR_VALID =>
        accum_rst <= '0';
        if adr_incr_dv = '1' then
          state <= ACTIVE;
        end if;

      when ACTIVE =>
        mul_nd <= '1';
        mul_ce <= '1';
        if (adr_incr_end = '1') then
          adr_incr_rst <= '1';
          state <= FLUSH1;
        end if;

      when FLUSH1 =>
        mul_nd <= '0';
        state <= FLUSH2;

      when FLUSH2 =>
        if (multiplication_finished = '1') then
          mul_ce <= '0';
          state <= IDLE;
        end if;

      end case;
    end if;
  end process;

end beh;

