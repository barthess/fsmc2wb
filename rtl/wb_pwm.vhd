library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity wb_pwm is

  generic (
    PWM_CHANNELS    : positive := 16;
    PWM_TX_INTERVAL : positive := 1024);  -- clk_gtp_tx cycles

  port (
    rst        : in std_logic;
    clk_gtp_tx : in std_logic;
    clk_gtp_rx : in std_logic;

    PWM_DATA_IN  : in  std_logic_vector(15 downto 0);
    PWM_EN_IN    : in  std_logic;
    PWM_DATA_OUT : out std_logic_vector(15 downto 0);
    PWM_EN_OUT   : out std_logic;

    -- Wishbone signals
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    err_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(15 downto 0);  -- uses only 3 downto 0
    dat_o : out std_logic_vector(15 downto 0);
    dat_i : in  std_logic_vector(15 downto 0));

end entity wb_pwm;

architecture beh of wb_pwm is

  type t_pwm_reg_tx is array (0 to PWM_CHANNELS-1) of std_logic_vector(15 downto 0);
  type t_pwm_reg_rx is array (0 to PWM_CHANNELS+2) of std_logic_vector(15 downto 0);
  signal pwm_reg_tx_wb  : t_pwm_reg_tx;  -- registers for sync between wishbone
  signal pwm_reg_tx_gtp : t_pwm_reg_tx;  -- and gtp clock domains, they contain
  signal pwm_reg_rx_wb  : t_pwm_reg_rx;  -- 16 pwm values (+3 odometer for rx)
  signal pwm_reg_rx_gtp : t_pwm_reg_rx;
  
  attribute mark_debug : string;
  attribute mark_debug of pwm_reg_rx_wb : signal is "TRUE";

  type t_pwm_trx_state is (idle, trx, pause);
  -- Pause state is needed because GTP tx interface is 8-bit wide
  -- and pwm data is 16-bit, so we need 32 cycles for 16 pwm channels
  -- so that GTP can handle it
  signal pwm_tx_state : t_pwm_trx_state;
  signal pwm_rx_state : t_pwm_trx_state;
  signal pwm_tx_cnt   : integer range 0 to PWM_TX_INTERVAL-1;
  signal pwm_rx_cnt   : integer range 0 to PWM_CHANNELS+2;

begin

  process (clk_i) is
    variable addr_int : natural;
  begin
    if rising_edge(clk_i) then
      if rst = '1' then
        err_o         <= '0';
        ack_o         <= '0';
        dat_o         <= (others => '0');
        pwm_reg_tx_wb <= (others => (others => '0'));
      else
        pwm_reg_rx_wb <= pwm_reg_rx_gtp;                    -- sync
        addr_int      := to_integer(unsigned(adr_i));
        if (sel_i = '1' and stb_i = '1') then
          -- Address map:
          -- 0:15  pwm tx
          -- 16:31 pwm rx
          -- 32    speed
          -- 33    ---
          -- 34:35 odometer
          if (we_i = '1' and addr_int <= PWM_CHANNELS-1) then
            -- write
            pwm_reg_tx_wb(addr_int) <= dat_i;
            ack_o                   <= '1';
            err_o                   <= '0';
          elsif (we_i = '0' and addr_int >= PWM_CHANNELS and addr_int <= PWM_CHANNELS*2+3) then
            -- read
            case addr_int is
              when PWM_CHANNELS to PWM_CHANNELS*2 =>        -- PWM_RX or speed
                dat_o <= pwm_reg_rx_wb(addr_int-PWM_CHANNELS);
              when PWM_CHANNELS*2+1 =>                      -- empty
                dat_o <= (others => '0');
              when PWM_CHANNELS*2+2 to PWM_CHANNELS*2+3 =>  -- odometer
                dat_o <= pwm_reg_rx_wb(addr_int-PWM_CHANNELS-1);
              when others => null;
            end case;
            ack_o <= '1';
            err_o <= '0';
          else
            ack_o <= '0';
            err_o <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- PWM TX (to MSI)
  -- Happens every time pwm_tx_cnt reaches PWM_TX_INTERVAL-1
  process (clk_gtp_tx) is
  begin
    if rising_edge(clk_gtp_tx) then
      if rst = '1' then
        pwm_tx_state <= idle;
        PWM_EN_OUT   <= '0';
        pwm_tx_cnt   <= 0;
      else
        pwm_reg_tx_gtp <= pwm_reg_tx_wb;  -- sync
        case pwm_tx_state is
          when idle =>
            if pwm_tx_cnt = PWM_TX_INTERVAL-1 then
              pwm_tx_state <= trx;
              pwm_tx_cnt   <= 0;
              PWM_DATA_OUT <= pwm_reg_tx_gtp(0);
              PWM_EN_OUT   <= '1';
            else
              pwm_tx_cnt <= pwm_tx_cnt + 1;
            end if;
          when trx =>
            pwm_tx_state <= pause;
            PWM_EN_OUT   <= '0';
          when pause =>
            pwm_tx_cnt <= pwm_tx_cnt + 1;
            if pwm_tx_cnt = PWM_CHANNELS-1 then
              pwm_tx_state <= idle;
            else
              pwm_tx_state <= trx;
              PWM_DATA_OUT <= pwm_reg_tx_gtp(pwm_tx_cnt + 1);
              PWM_EN_OUT   <= '1';
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- PWM RX (from MSI)
  -- Happens every time input PWM sequence arrives
  process (clk_gtp_rx) is
  begin
    if rising_edge(clk_gtp_rx) then
      if rst = '1' then
        pwm_reg_rx_gtp <= (others => (others => '0'));
        pwm_rx_state   <= idle;
        pwm_rx_cnt     <= 0;
      else
        case pwm_rx_state is
          when idle =>
            if PWM_EN_IN = '1' then
              pwm_rx_state      <= trx;
              pwm_reg_rx_gtp(0) <= PWM_DATA_IN;
              pwm_rx_cnt        <= 0;
            end if;
          when trx =>
            pwm_rx_state <= pause;
          when pause =>
            if pwm_rx_cnt = PWM_CHANNELS+2 then
              pwm_rx_state <= idle;
            else
              pwm_rx_state                   <= trx;
              pwm_reg_rx_gtp(pwm_rx_cnt + 1) <= PWM_DATA_IN;
              pwm_rx_cnt                     <= pwm_rx_cnt + 1;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

end architecture beh;
