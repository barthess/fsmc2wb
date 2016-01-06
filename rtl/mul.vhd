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

entity mul is
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
end mul;


-----------------------------------------------------------------------------

architecture beh of mul is
  
  signal op1_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal op2_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal res_adr : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal mul_nd  : std_logic := '0';
  signal mul_ce  : std_logic := '0';
  signal mul_rdy_reg : std_logic_vector(1 downto 0) := "00";
  signal mul_rdy : std_logic;
  
  type state_t is (IDLE, PREFETCH, ACTIVE);
  signal state : state_t := IDLE;

begin
  
  -- warning suppressor
  bram_dat_o(2*BRAM_DW-1 downto 0) <= bram_dat_i(3*BRAM_DW-1 downto 2*BRAM_DW) & bram_dat_i(3*BRAM_DW-1 downto 2*BRAM_DW);
  
  bram_adr_o(3*BRAM_AW-1 downto 2*BRAM_AW) <= res_adr;
  bram_adr_o(2*BRAM_AW-1 downto 1*BRAM_AW) <= op2_adr;
  bram_adr_o(1*BRAM_AW-1 downto 0*BRAM_AW) <= op1_adr;
  bram_clk_o <= (others => clk_i);
  bram_en_o  <= (others => '1');
  bram_we_o(0) <= '0';
  bram_we_o(1) <= '0';
  bram_we_o(2) <= mul_rdy;

  dat_rdy_o  <= '1' when (state = IDLE) else '0';

  mul : entity work.double_mul
    port map (
      a             => bram_dat_i(1*BRAM_DW-1 downto 0*BRAM_DW),
      b             => bram_dat_i(2*BRAM_DW-1 downto 1*BRAM_DW),
      result        => bram_dat_o(3*BRAM_DW-1 downto 2*BRAM_DW),
      clk           => clk_i,
      ce            => mul_ce,
      operation_nd  => mul_nd,
      rdy           => mul_rdy
    );

  -- ready pin scanning
  process(clk_i) 
  begin
    if rising_edge(clk_i) then
      mul_rdy_reg <= mul_rdy_reg(0) & mul_rdy;
    end if;
  end process;
  
  -- read address increment
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (state = IDLE) then
        op1_adr <= (others => '0');
        op2_adr <= (others => '0');
      else
        op1_adr <= op1_adr + 1;
        op2_adr <= op2_adr + 1;
      end if;
    end if;
  end process;
  
  -- write address increment
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (state = ACTIVE) then
        if (mul_rdy = '1') then
          res_adr <= res_adr + 1;
        end if;
      else
        res_adr <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Main state machine
  process(clk_i)
    variable i : std_logic_vector(BRAM_AW-1 downto 0);
    variable op_cnt : std_logic_vector(BRAM_AW-1 downto 0);
  begin
--    dat_o(WB_AW-1 downto BRAM_AW) <= (others => '0');
--    dat_o(BRAM_AW-1 downto 0) <= i;  -- warning suppressor
    dat_o <= x"BEEF";
    
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        if (stb_i = '1' and sel_i = '1' and we_i = '1') then
          if (adr_i > 0 or dat_i > 2**BRAM_AW) then
            op_cnt := (others => '0');
            err_o <= '1';
          else
            state <= PREFETCH;
            i := (others => '0');
            op_cnt := dat_i(BRAM_AW-1 downto 0);
            err_o <= '0';
            ack_o <= '1';
          end if;
        else
          err_o <= '0';
          op_cnt := (others => '0');
        end if;
      
      when PREFETCH =>
        mul_nd <= '1';
        mul_ce <= '1';
        i := i+1;
        state <= ACTIVE;

      when ACTIVE =>
        if (i < op_cnt) then
          i := i+1;
        else
          mul_nd <= '0';
        end if;

        if (mul_rdy_reg = "10") then
          state <= IDLE;
          mul_ce  <= '0';
        end if;

      end case;
    end if;
  end process;

end beh;




