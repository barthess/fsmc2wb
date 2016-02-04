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
entity mtrx_add is
  Generic (
    MTRX_AW : positive := 5;  -- 2**MTRX_AW = max matrix index
    BRAM_DW : positive := 64;
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
    rdy_o  : out std_logic := '0'; -- active high 1 cycle
    err_o  : out std_logic := '0';
    sub_not_add_i : in std_logic;
    
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
end mtrx_add;


-----------------------------------------------------------------------------

architecture beh of mtrx_add is
  
  -- operand and result addresses registers
  signal AB_adr : std_logic_vector(2*MTRX_AW-1 downto 0):= (others => '0');
  signal AB_ce  : std_logic := '0';
  signal C_adr  : std_logic_vector(2*MTRX_AW-1 downto 0):= (others => '0');
  signal C_ce   : std_logic := '0';
  signal m_size, n_size : std_logic_vector(MTRX_AW-1 downto 0):= (others => '0');
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;

  signal rdy_ab_iter : std_logic := '0';
  signal rdy_c_iter  : std_logic := '0';
  signal rst_ab_iter : std_logic := '0';
  signal rst_c_iter  : std_logic := '0';
  
  -- adder control signals
  signal nd_delay: std_logic_vector(DAT_LAT-1 downto 0);
  signal add_nd  : std_logic := '0';
  signal add_ce  : std_logic := '0';
  signal add_rdy : std_logic;

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE, FLUSH, HALT);
  signal state : state_t := IDLE;

begin
  
  bram_adr_a_o <= AB_adr;
  bram_adr_b_o <= AB_adr;
  bram_adr_c_o <= C_adr;
  bram_we_o    <= add_rdy;
  bram_ce_a_o  <= AB_ce;
  bram_ce_b_o  <= AB_ce;
  
  --
  -- address iterator for IN matrices
  --
  iter_ab : entity work.mtrx_iter_seq
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_ab_iter,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    end_o  => rdy_ab_iter,
    dv_o   => AB_ce,
    adr_o  => AB_adr
  );
  
  --
  -- address iterator for OUT matrix
  --
  iter_c : entity work.mtrx_iter_seq
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_c_iter,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    end_o  => rdy_c_iter,
    dv_o   => C_ce,
    adr_o  => C_adr
  );
  
  --
  -- adder
  --
  add_nd <= nd_delay(DAT_LAT-1);
  dadd : entity work.dadd
  port map (
    a      => bram_dat_a_i,
    b      => bram_dat_b_i,
    result => bram_dat_c_o,
    clk    => clk_i,
    ce     => add_ce,
    rdy    => add_rdy,
    operation(5 downto 1) => "00000",
    operation(0) => sub_not_add_i,
    operation_nd => add_nd
  );
  
  --
  -- Main state machine
  -- 
  main : process(clk_i)
    variable m_tmp, n_tmp : std_logic_vector(MTRX_AW-1 downto 0);
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state   <= IDLE;
        add_nd  <= '0';
        add_ce  <= '0';
        lat_i   <= DAT_LAT;
      else
        case state is
        when IDLE =>
          m_tmp := size_i(MTRX_AW-1   downto 0);
          n_tmp := size_i(2*MTRX_AW-1 downto MTRX_AW);
          if (size_i(15 downto 2*MTRX_AW) > 0) -- overflow
          then
            err_o <= '1';
            state <= HALT;
          else
            m_size <= m_tmp;
            n_size <= n_tmp;
            rst_ab_iter <= '0';
            lat_i <= lat_i - 1;
            state <= PRELOAD;
          end if;

        when PRELOAD =>
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state  <= ACTIVE;
            add_ce <= '1';
            add_nd <= '1';
          end if;

        when ACTIVE =>
          
          ту ду блеать:
          - подключить add_nd к лини задержки
          - на конец-то проверить весь этот зоопарк в симуляторе
          - для перехода между состояниями использовать сигналы итераторов через линии задержки, а не счетчики
          - добавить итераторам линию CE и воспользоваться этим в коде для перемножения матриц (определение конца операции)
          A_adr <= A_adr - 1;
          B_adr <= B_adr - 1;

          if (nd_track /= 0) then
            nd_track <= nd_track - 1;
          else
            add_nd <= '0';
          end if;
          
          if (add_rdy = '1') then
            C_adr <= C_adr - 1;
            if (C_adr = 0) then
              add_ce <= '0';
              state  <= HALT;
            end if;
          end if;

        when HALT =>
          state <= HALT;
        end case;
        
      end if; -- clk
    end if; -- rst
  end process;

end beh;

