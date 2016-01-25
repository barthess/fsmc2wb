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

entity mtrx_mul is
  Generic (
    WB_AW   : positive;
    WB_DW   : positive;
    BRAM_AW : positive;
    BRAM_DW : positive
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
  
  signal A_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal B_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal C_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal mul_nd  : std_logic := '0';
  signal mul_ce  : std_logic := '0';
  signal mul_rdy_reg : std_logic_vector(1 downto 0) := "00";
  signal mul_rdy : std_logic;
  signal input_iterated : std_logic;

  signal mtrx_m : std_logic_vector (4 downto 0) := (others => '0');
  signal mtrx_p : std_logic_vector (4 downto 0) := (others => '0');
  signal mtrx_n : std_logic_vector (4 downto 0) := (others => '0');
  signal adr_incr_rst : std_logic := '1';
  signal adr_incr_ce  : std_logic := '0';
  
  type state_t is (IDLE, PRELOAD, ACTIVE, FLUSH1, FLUSH2);
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


  -- multiplicator
  dmul : entity work.dmul
    port map (
      a             => bram_dat_i(1*BRAM_DW-1 downto 0*BRAM_DW),
      b             => bram_dat_i(2*BRAM_DW-1 downto 1*BRAM_DW),
      result        => bram_dat_o(3*BRAM_DW-1 downto 2*BRAM_DW),
      clk           => clk_i,
      ce            => mul_ce,
      operation_nd  => mul_nd,
      rdy           => mul_rdy
    );


  -- addres incrementer
  adr_calc : entity work.adr4mul
    generic map (
      WIDTH => 5
    )
    port map (
      clk_i => clk_i,
      rst_i => adr_incr_rst,
      ce_i  => adr_incr_ce,
      
      row_rdy_o => open,
      eoi_o => input_iterated,
      
      m_i => mtrx_m,
      p_i => mtrx_p,
      n_i => mtrx_n,
      
      a_adr_o  => A_adr,
      b_adr_o  => B_adr,
      a_tran_i => '0',
      b_tran_i => '0'
    );
  
  
  -- ready pin scanning
  process(clk_i) 
  begin
    if rising_edge(clk_i) then
      mul_rdy_reg <= mul_rdy_reg(0) & mul_rdy;
    end if;
  end process;
  
  
  -- result address increment
  process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if state /= IDLE then
        if (mul_rdy = '1') then
          C_adr <= C_adr + 1;
        end if;
      else
        C_adr <= (others => '0');
      end if;
    end if;
  end process;
  
  
  -- Main state machine
  process(clk_i)
  begin
    dat_o(WB_AW-1 downto BRAM_AW) <= (others => '0');
    
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        adr_incr_rst <= '1';
        if (stb_i = '1' and sel_i = '1' and we_i = '1') then
          state <= PRELOAD;
          mtrx_m <= dat_i(4 downto 0);
          mtrx_p <= dat_i(9 downto 5);
          mtrx_n <= dat_i(14 downto 10);
          adr_incr_rst <= '0';
          adr_incr_ce  <= '1';
          err_o <= '0';
          ack_o <= '1';
        else
          err_o <= '1';
          ack_o <= '0';
        end if;
        
      when PRELOAD =>
        state <= ACTIVE;
        
      when ACTIVE =>
        mul_nd <= '1';
        mul_ce <= '1';
        if (input_iterated = '1') then
          adr_incr_rst <= '1';
          adr_incr_ce <= '0';
          state <= FLUSH1;
        end if;

      when FLUSH1 =>
        mul_nd <= '0';
        state <= FLUSH2;
        
      when FLUSH2 =>
        if (mul_rdy_reg = "10") then
          mul_ce <= '0';
          state <= IDLE;
        end if;
        
      end case;
    end if;
  end process;

end beh;

