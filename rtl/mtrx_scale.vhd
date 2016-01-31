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
entity mtrx_scale is
  Generic (
    WB_AW   : positive := 16;
    WB_DW   : positive := 16;
    BRAM_AW : positive := 10;
    BRAM_DW : positive := 64;
    MTRX_AW : positive := 5  -- fake unused value
  );
  Port (
    -- external interrupt pin
    rdy_o : out std_logic;
    
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
    -- Note: there are no clocks for BRAMs. They are handle in higher level
    bram_adr_a_o : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_adr_b_o : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_adr_c_o : out std_logic_vector(BRAM_AW-1 downto 0);
    
    bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
    bram_ce_a_o  : out std_logic;
    bram_ce_b_o  : out std_logic;
    bram_ce_c_o  : out std_logic;
    bram_we_o    : out std_logic -- for C bram
  );
end mtrx_scale;


-----------------------------------------------------------------------------

architecture beh of mtrx_scale is
  
  -- operand and result addresses registers
  signal A_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal C_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  constant ZERO : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  
  signal result_buf : std_logic_vector(BRAM_DW-1 downto 0) := (others => '0');
  signal result_we : std_logic := '0';

  -- multiplicator control signals
  signal mul_nd : std_logic := '0';
  signal mul_ce : std_logic := '0';
  signal mul_rdy : std_logic; -- connected to accumulator nd

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE);
  signal state : state_t := IDLE;

begin
  
  bram_adr_a_o <= A_adr;
  bram_adr_b_o <= (others => '0');
  bram_adr_c_o <= C_adr;
  bram_we_o    <= result_we;
  bram_dat_c_o <= result_buf;

  rdy_o  <= '1' when (state = IDLE) else '0';

  --
  -- multiplicator
  --
  dmul : entity work.dmul
    port map (
      a      => bram_dat_a_i,
      b      => bram_dat_b_i,
      result => result_buf,
      clk    => clk_i,
      ce     => mul_ce,
      rdy    => mul_rdy,
      operation_nd => mul_nd
    );

  --
  -- Main state machine
  --
  main : process(clk_i)
  begin
    --dat_o(WB_AW-1 downto BRAM_AW) <= (others => '0');
    dat_o <= (others => '0');
    
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        bram_ce_a_o <= '0';
        bram_ce_b_o <= '0';
        bram_ce_c_o <= '0';

        if (stb_i = '1' and sel_i = '1' and we_i = '1') then
          err_o <= '0';
          ack_o <= '1';
          A_adr <= dat_i(9 downto 0);
          C_adr <= dat_i(9 downto 0);
          bram_ce_a_o <= '1';
          bram_ce_b_o <= '1';
          bram_ce_c_o <= '1';
          state <= PRELOAD;
        else
          err_o <= '1';
          ack_o <= '0';
        end if;
        
      when PRELOAD =>
        A_adr <= A_adr - 1;
        state <= ACTIVE;
        
      when ACTIVE =>
        mul_nd <= '1';
        mul_ce <= '1';
        if (mul_rdy = '1') then
          C_adr <= C_adr - 1;
          result_we <= '1';
          if (C_adr = ZERO) then
            mul_nd <= '0';
            mul_ce <= '0';
            result_we <= '0';
            state <= IDLE;
          end if;
        end if;
       
      end case;
    end if;
  end process;

end beh;

