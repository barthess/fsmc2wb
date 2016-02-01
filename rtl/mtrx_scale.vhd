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
--
--
entity mtrx_dot is
  Generic (
    BRAM_AW : positive := 10;
    BRAM_DW : positive := 64
  );
  Port (
    -- control interface
    rst_i : in  std_logic; -- active high. Must be used before every new calculation
    clk_i : in  std_logic;
    op_i  : in  std_logic_vector(15 downto 0); -- size of input operands
    rdy_o : out std_logic := '0'; -- active high 1 clock

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
end mtrx_dot;


-----------------------------------------------------------------------------

architecture beh of mtrx_dot is
  
  -- operand and result addresses registers
  constant ZERO : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal A_adr : std_logic_vector(BRAM_AW-1 downto 0) := ZERO;
  signal B_adr : std_logic_vector(BRAM_AW-1 downto 0) := ZERO;
  signal C_adr : std_logic_vector(BRAM_AW-1 downto 0) := ZERO;
  
  constant ZERO64 : std_logic_vector(BRAM_DW-1 downto 0) := (others => '0');
  signal result_buf : std_logic_vector(BRAM_DW-1 downto 0) := ZERO64;
  signal result_we : std_logic := '0';

  -- multiplicator control signals
  signal mul_nd : std_logic := '0';
  signal mul_ce : std_logic := '0';
  signal mul_rdy : std_logic;

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;

begin
  
  bram_adr_a_o <= A_adr;
  bram_adr_b_o <= B_adr;
  bram_adr_c_o <= C_adr;
  bram_we_o    <= result_we;
  bram_dat_c_o <= result_buf;
  bram_ce_a_o  <= '1';
  bram_ce_b_o  <= '1';
  bram_ce_c_o  <= '1';
  
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
  main : process(clk_i, rst_i)
  begin
    if (rst_i = '1') then
      state <= IDLE;
      result_we <= '0';
      rdy_o <= '0';
    else
      if rising_edge(clk_i) then
        
        rdy_o <= '0';
        
        case state is
        when IDLE =>
          A_adr <= op_i(9 downto 0);
          B_adr <= op_i(9 downto 0);
          C_adr <= op_i(9 downto 0);
          state <= PRELOAD;
          
        when PRELOAD =>
          A_adr <= A_adr - 1;
          B_adr <= B_adr - 1;
          state <= ACTIVE;
          
        when ACTIVE =>
          mul_nd <= '1';
          mul_ce <= '1';
          A_adr <= A_adr - 1;
          B_adr <= B_adr - 1;
          if (mul_rdy = '1') then
            C_adr <= C_adr - 1;
            result_we <= '1';
            if (C_adr = ZERO) then
              mul_nd <= '0';
              mul_ce <= '0';
              result_we <= '0';
              rdy_o <= '1';
              state <= HALT;
            end if;
          end if;
          
        when HALT =>
          state <= HALT;
          
        end case;
      end if; -- clk
    end if; -- rst
  end process;

end beh;

